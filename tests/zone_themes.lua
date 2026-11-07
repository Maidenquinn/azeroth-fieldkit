-- Synthetic behavioral acceptance only: does not certify the native renderer.
TARGET=nil
fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
assert(FieldKitZoneThemes.ui and table.getn(FieldKitZoneThemes.ui)==9,"Theme settings must be present in the real options journey")
local C,H,M,T=FieldKitZoneThemes,FieldKitThemeHUD,FieldKitThemeMinimap,FieldKitTheme
assert(not C.active and not FieldKitDB.zoneThemes)
FieldKit.zoneThemeReady=false;FieldKitDB.zoneThemes=true;FieldKitDB.zoneThemeMode="naxx"
C.Refresh();assert(not C.active,"Do not capture native frames during legacy HUD construction")
FieldKit.zoneThemeReady=true;FieldKitDB.zoneThemes=false
function Minimap:SetMaskTexture(path) self.mask=path end
function Minimap:GetMaskTexture() return self.mask or "Textures\\MinimapMask" end
Minimap:SetParent(UIParent);Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12,-20)
Minimap:SetWidth(140);Minimap:SetHeight(140)
PlayerFrame=CreateFrame("Button","PlayerFrame",UIParent);PlayerFrame:SetAlpha(.8)
local repaint=0;local nativeShow=PlayerFrame.Show
function PlayerFrame:Show() repaint=repaint+1;nativeShow(self) end
local clicks=0;PlayerFrame:SetScript("OnClick",function() assert(this==PlayerFrame);clicks=clicks+1 end)
local nativePoint=FieldKitEncounterFrame.SetPoint
FieldKitEncounterFrame.point={"CENTER","UIParent","CENTER",430,-180}
function FieldKitEncounterFrame:SetPoint(p,r,rp,x,y)
 assert(type(r)~="string","Native SetPoint rejects relative frame names")
 nativePoint(self,p,r,rp,x,y)
end
local originalParent={}
for _,slot in ipairs({1,2,3,4,5,6,12}) do
 local b=getglobal("ActionButton"..slot);if not b then b=CreateFrame("Button","ActionButton"..slot,MainMenuBar) end
 b:SetPoint("CENTER",MainMenuBar,"CENTER",slot*2,0);originalParent[slot]=b:GetParent()
end
local state={clock=true,tally=false,build=true,banners=true,bosses=true,meter=true,levels=true}
local top={};function AZS_IsOnTopOfScreens(name) return top[name]==true end
function AZS_SetOnTopOfScreens(name,value) top[name]=value end
local phase="ready";function AZS_GetPhase() return phase end
function Minimap:SetZoom(value) self.zoom=value end
function Minimap:GetZoom() return self.zoom or 0 end
function Minimap:GetZoomLevels() return 6 end
local openedLevels=0
function AZS_GetStoredLevels() return 2 end
function AZS_OpenStoredLevels() openedLevels=openedLevels+1 end
function AZS_IsHudShown(key) return state[key] end
function AZS_SetHudShown(key,shown) state[key]=shown end
function UnitMana() return 35 end
function UnitManaMax() return 100 end
function UnitPowerType() return 1 end
AZS_ZONE={zone="naxx",heroic=3};AZS_RUN={t=60,ph="playing",kills=43,gold=10,chest=25,sh=20}
local anchors=FieldKitDB.frameAnchors
SlashCmdList.FieldKit("themes naxx")
assert(C.active and T.zone=="naxx" and M.active)
FieldKitPreview.Start(false);C.Refresh();assert(not C.active and not M.active,"Preview must release live ownership")
FieldKitPreview.Stop();C.Refresh();assert(C.active and M.active,"Live ownership must resume after preview")
assert(state.banners==false and state.meter==false and state.levels==false)
FieldKitUI.frame:Hide();C.Refresh();assert(state.banners==true);assert(FieldKitReferenceHUD.stored:IsShown());click(FieldKitReferenceHUD.stored);assert(openedLevels==1)
C.ToggleNativeMeter();assert(state.meter==true);C.ToggleNativeMeter();assert(state.meter==false)
FieldKitUI.frame:Show();C.Refresh();assert(state.banners==false)
phase="choosing";C.Refresh();assert(not H.dock:IsShown() and state.banners==true)
FieldKitUI.frame:Hide()
phase="ready";C.Refresh()
for i=1,8 do click(M.zoomIn) end;assert(Minimap:GetZoom()==5)
for i=1,8 do click(M.zoomOut) end;assert(Minimap:GetZoom()==0)
assert(Minimap:GetWidth()==Minimap:GetHeight() and Minimap:GetParent()==M.root)
assert(FieldKitDB.frameAnchors==anchors)
assert(state.clock==false and state.tally==false and state.build==false and state.bosses==false)
C.NativeRestore();assert(state.clock==true and state.build==true and state.tally==false)
C.Refresh();assert(state.clock==false and state.build==false)
assert(PlayerFrame:GetAlpha()==0)
click(H.player);assert(clicks==1)
for _,slot in ipairs({1,2,3,4,5,6,12}) do assert(getglobal("ActionButton"..slot):GetParent()==H.dock) end
H.ModeTip(H.mode,false);for _,label in ipairs(H.tipRows) do label.GetStringHeight=false end
H.ModeTip(H.mode,true);assert(H.tip:IsShown() and H.pinned);H.HideTip();assert(H.tip:IsShown())
C.Set("zoneThemeVariant","minimal");assert(FieldKitMeterFrame:GetAlpha()==0)
C.Open("Damage");assert(FieldKitMeterFrame:GetAlpha()>0 and FieldKitMeterFrame:IsShown())
C.Open("Damage");assert(FieldKitMeterFrame:GetAlpha()==0)
local exists=UnitExists
UnitExists=function(unit) return unit=="target" or (exists and exists(unit)) end
TargetFrame:SetParent(UIParent);TargetFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",250,-30)
local targetClicks=0;TargetFrame:SetScript("OnClick",function() assert(this==TargetFrame);targetClicks=targetClicks+1 end)
C.Refresh();assert(FieldKitThemeTarget.frame:IsShown() and TargetFrame:GetParent()==H.storage)
click(FieldKitThemeTarget.frame);assert(targetClicks==1)
FieldKitThemeTarget.frame._mouseIsOver=true;this=FieldKitThemeTarget.frame;this.scripts.OnEnter()
C.Refresh();assert(TargetFrame:GetParent()==UIParent)
FieldKitThemeTarget.frame._mouseIsOver=false;NOW=NOW+1;C.Refresh();assert(TargetFrame:GetParent()==H.storage)
-- Selecting the displayed boss removes the duplicate target summary while
-- keeping its native cast on the visible boss and restoring ownership afterward.
local boss=getglobal("FieldKitBossFrame1Compact")
local bossShown=boss:IsShown();local bossName=boss.name:GetText();boss.name:SetText(UnitName("target"));boss:Show()
TargetFrameSpellBar=CreateFrame("StatusBar","TargetFrameSpellBar",TargetFrame)
C.Refresh();assert(not FieldKitThemeTarget.frame:IsShown() and TargetFrameSpellBar:GetParent()==boss)
boss.name:SetText(bossName);if not bossShown then boss:Hide() end
UnitExists=function(unit) return unit~="target" and exists and exists(unit) end
C.Refresh();assert(not FieldKitThemeTarget.frame:IsShown() and TargetFrame:GetParent()==UIParent and TargetFrameSpellBar:GetParent()==TargetFrame)
local count=table.getn(objects)
for i=1,120 do C.Refresh() end
assert(table.getn(objects)==count,"HUD refresh must reuse all allocated surfaces")
H.dock:SetPoint("TOPLEFT",UIParent,"TOPLEFT",83,-65)
assert(C.Remember(H.dock));assert(not FieldKitDB.frameAnchors.FieldKitThemeDock)
local scoped=FieldKitDB.zoneThemePositions[C.currentLayout].FieldKitThemeDock
assert(scoped[3]==83 and scoped[4]==-65)
FieldKitProfiles.Save(1)
C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","alternative")
assert(T.zone=="elwynn" and H.zone:GetText()=="Naxxramas","Manual skin must never falsify the actual native zone")
assert(FieldKitProfiles.Load(1));local dp,dr,drp,dx,dy=H.dock:GetPoint();assert(dp=="TOPLEFT" and dx==83 and dy==-65)
assert(FieldKitDB.zoneThemeMode=="naxx" and FieldKitDB.zoneThemeVariant=="minimal")
C.Set("zoneThemes",false)
assert(not C.active and not M.active and T.zone=="classic")
assert(not top.FieldKitPanel and state.banners==true)
assert(Minimap:GetParent()==UIParent and Minimap:GetWidth()==140 and Minimap:GetHeight()==140)
assert(Minimap:GetMaskTexture()=="Textures\\MinimapMask")
assert(state.clock==true and state.tally==false and state.build==true and state.bosses==true and state.meter==true and state.levels==true)
assert(PlayerFrame:GetAlpha()==.8)
assert(repaint>0,"Restoring a shown native frame must invalidate Benilla visibility cache")
for _,slot in ipairs({1,2,3,4,5,6,12}) do assert(getglobal("ActionButton"..slot):GetParent()==originalParent[slot]) end
C.Set("zoneThemeMode","auto");C.Set("zoneThemes",true)
AZS_ZONE.zone="feralas";C.Refresh();assert(not C.active)
AZS_ZONE.zone="elwynn";C.Refresh();assert(C.active and T.zone=="elwynn")
local foreign=CreateFrame("Frame","OtherAddonMap",UIParent)
M.Restore();Minimap:SetParent(foreign);assert(not M.Apply("complete"));assert(Minimap:GetParent()==foreign)
C.Set("zoneThemes",false)
local malformed=C.NormalizePositions({bad={UIParent={"TOP","TOP",1,1}},["naxx:minimal"]={UIParent={"TOP","TOP",1,1},FieldKitThemeDock={"TOP","TOP",1,2,junk={3}}}})
assert(malformed.bad==nil and malformed["naxx:minimal"].UIParent==nil and malformed["naxx:minimal"].FieldKitThemeDock.junk==nil)
print("Zone themes: native ownership restoration, map guard, profile roundtrip, routes, unknown-zone fallback and bounded frame pools passed (synthetic)")

-- Regression: six concept geometries keep one independent live HP source,
-- close the secondary popup, preserve all details and never reuse hidden HP.
AZS_ZONE.zone="elwynn";Minimap:SetParent(UIParent)
for _,zone in ipairs({"elwynn","naxx"}) do
 for _,variant in ipairs({"minimal","complete","alternative"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant",variant);C.Set("zoneThemes",true)
  assert(H.healthRoot:IsShown() and H.health:IsShown() and H.hp:GetText()~="")
  assert(H.health:GetParent()==H.player and H.player:GetParent()==H.healthRoot)
  assert(FieldKitPlayerBar:GetParent()==H.storage)
  assert(H.xpRoot:IsShown() and H.xp:IsShown())
  if FieldKitReferenceHUD.active then local r=FieldKitReferenceHUD.layout.rects.dock;assert(H.dock:GetWidth()==r[3] and H.dock:GetHeight()==r[4]) else assert(H.dock:GetHeight()==88 and H.dock:GetWidth()==500) end
  assert(not H.micro:IsShown(),"Native menus must be collapsed by default")
  if FieldKitReferenceHUD.active then
   local d=FieldKitReferenceHUD.layout
   assert(Minimap:GetWidth()==d.map[3] and Minimap:GetHeight()==d.map[3])
   assert(H.counterRoot.mouseEnabled==false,"Invisible count canvas must never intercept gameplay input")
  else
   local p=M.root:GetPoint();assert(p)
  end
  C.Open("Stats");assert(FieldKitStatsFrame:GetAlpha()>0 and H.back:IsShown());click(H.back);assert(not H.back:IsShown())
  phase="choosing";C.Refresh();assert(not H.healthRoot:IsShown());phase="playing";C.Refresh();assert(H.healthRoot:IsShown() and H.health:IsShown())
 end
end
-- A preference/profile switch during a native choice must not capture the
-- temporary zero alpha as the live HUD's original presentation.
phase="choosing";C.Refresh();FieldKitScreenLayers.ApplyChoice()
C.Set("zoneThemeMode","auto");C.Set("zoneThemeVariant","alternative")
phase="playing";C.Refresh();C.Refresh()
assert(H.dock:GetAlpha()==1 and H.identity:GetAlpha()==1 and H.healthRoot:GetAlpha()==1,"Choice-to-theme transition must restore visible component opacity")
assert(H.xpRoot:GetAlpha()==1 and FieldKitReferenceHUD.canvas:GetAlpha()==1)
C.Set("zoneThemeArt",false);assert(not H.sculpture:IsShown() and H.health:IsShown() and H.xp:IsShown())
for _,t in ipairs(H.dock.referenceTiles or {}) do assert(not t:IsShown(),"Disabled ornament material must actually disappear") end
C.Set("zoneThemeArt",true);assert(H.health:IsShown() and H.xp:IsShown())
C.Set("zoneThemeMinimap",false);assert(not M.active);C.Set("zoneThemeMinimap",true);assert(M.active)
C.Set("zoneThemes",false);assert(not H.healthRoot:IsShown() and not H.xpRoot:IsShown() and not H.health:IsShown() and not H.xp:IsShown(),"Native cached gauges must be explicitly hidden on stop")
for _,f in pairs(H.summaries or {}) do assert(not f:IsShown()) end
print("Six concept layouts: live HP, XP, map corners, art fallback, choice restoration and detail routes passed (synthetic)")
