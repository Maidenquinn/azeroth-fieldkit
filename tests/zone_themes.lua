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

-- Independent sizes must survive a layout/profile roundtrip without scaling
-- unrelated controls, tearing a combined map frame, or moving a dragged anchor.
C.Set("zoneThemeMode","naxx");C.Set("zoneThemeVariant","minimal");C.Set("zoneThemes",true)
local R=FieldKitReferenceHUD
local setHeaderWidth=H.header.SetWidth
H.header.SetWidth=function(self,width) assert(width==R.layout.rects.header[3],"Reference refresh must not first install fallback geometry");setHeaderWidth(self,width) end
C.Refresh();H.header.SetWidth=setHeaderWidth
ActionButton1:SetAlpha(0);C.Refresh();assert(ActionButton1:GetAlpha()==1,"Rejouer must not leave owned native actions transparent")
FieldKitDB.zoneThemePositions[C.currentLayout]=nil
C.SetElementScale("FieldKitThemeDock",65)
assert(H.dock:GetScale()==.65 and H.header:GetScale()==1)
assert(H.healthRoot:GetParent()==H.dock and H.healthRoot:GetScale()==1)
assert(H.xpRoot:GetParent()==H.dock and H.counterRoot:GetParent()==H.dock)
C.SetElementScale("FieldKitThemeMap",75);assert(M.root:GetScale()==.75 and M.zoomIn:GetParent()==M.root)
H.dock:SetPoint("BOTTOM",UIParent,"BOTTOM",100,80);assert(C.Remember(H.dock))
C.SetElementScale("FieldKitThemeDock",50)
local pos=FieldKitDB.zoneThemePositions[C.currentLayout].FieldKitThemeDock
assert(math.abs(pos[3]-130)<.0001 and math.abs(pos[4]-104)<.0001)
FieldKitProfiles.Save(1)
C.Set("zoneThemeVariant","complete");assert(C.ElementScale("FieldKitThemeDock")==1)
C.Set("zoneThemeMode","elwynn");assert(C.ElementScale("FieldKitThemeDock")==1)
C.SetElementScale("FieldKitThemeIdentity",70)
assert(M.root:GetParent()==H.identity and M.root:GetScale()==1,"The map inside the identity artwork must inherit that frame's size")
assert(FieldKitProfiles.Load(1));assert(C.ElementScale("FieldKitThemeDock")==.5 and C.ElementScale("FieldKitThemeMap")==.75)
local normalized=C.NormalizeScales({junk={FieldKitThemeDock=70},[C.currentLayout]={UIParent=20,FieldKitThemeDock=1000,FieldKitThemeHeader=0/0}})
assert(normalized.junk==nil and normalized[C.currentLayout].UIParent==nil and normalized[C.currentLayout].FieldKitThemeDock==130 and normalized[C.currentLayout].FieldKitThemeHeader==nil)
local before=table.getn(objects);for i=1,30 do C.SetElementScale("FieldKitThemeDock",50+math.mod(i,17)*5) end;assert(table.getn(objects)==before)
local probe=T.Label(UIParent,nil,0,0,85,24,17,T.text)
local setFont=probe.SetFont;local fontWrites=0
probe.SetFont=function(self,path,size,flags) fontWrites=fontWrites+1;return setFont(self,path,size,flags) end
local probeText="Équipement particulièrement long"
probe:SetText(probeText);R.Fit(probe,17,12);local initialWrites=fontWrites
for i=1,20 do probe:SetText(probeText);T.Font(probe,17,T.text);R.Fit(probe,17,12) end
assert(fontWrites==initialWrites,"Unchanged fitted labels must not rebuild their font every refresh")
assert(probe.referenceFullText==probeText and probe:GetStringWidth()<=probe:GetWidth())

-- Stress the actual six renderers with long localized names and large native
-- counters. Assert bounded text and disjoint columns, not a screenshot score.
local long="Équipement extraordinaire de Généralissime Mograine à très longue désignation"
local read=FieldKitMeterLedger.Read
FieldKitMeterLedger.Read=function() local lines={};for i=1,4 do lines[i]={name=long,share=.25,icon="Interface\\Icons\\Spell_Frost_FrostBolt02"} end;return lines,123456789012,987654321,true end
FieldKitLoadout.items[2]={name=long,bonuses={}}
AZS_RUN.kills=123456789012;AZS_RUN.gold=987654321012;AZS_RUN.chest=999999999
for _,zone in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"minimal","complete","alternative"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant",variant);C.Set("zoneThemes",true)
 for i=table.getn(R.layout.navButtons)+1,7 do assert(not H.buttons[i].fieldkitLabel:IsShown(),"A hidden nav button must not leave a reparented label visible") end
 for _,label in ipairs(R.counts) do assert(label:GetStringWidth()<=label:GetWidth(),zone..variant.." counter overflow");assert(label.referenceFullText and string.len(label.referenceFullText)>0) end
 if variant=="complete" then
  for kind,f in pairs(R.frames) do if f:IsShown() then
   assert(f.title:GetStringWidth()<=f.title:GetWidth())
   for _,r in ipairs(f.rows) do if r:IsShown() then
    assert(r.label:GetStringWidth()<=r.label:GetWidth());assert(r.value:GetStringWidth()<=r.value:GetWidth())
    assert(r.label:GetWidth()+r.value:GetWidth()<=r:GetWidth()+1,zone..kind.." Summary columns overlap: "..r.label:GetWidth().."+"..r.value:GetWidth()..">"..r:GetWidth())
   end end
  end end
  assert(R.frames.Accessories.rows[1].entry.name==long,"Fitting must retain full source data")
 end
end end
FieldKitMeterLedger.Read=read
C.Set("zoneThemes",false)
assert(next(C.bossBefore)==nil)
print("Element sizes: independent geometry, grouped art, saved anchors, profiles, bounded allocation and long-text fixtures passed (synthetic)")

-- Review feedback: opening a detail must keep summaries, empty state must not
-- inherit a lair lamp, and selected chrome must never add a cyan side stripe.
C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
C.Open("Stats");assert(R.frames.Damage:IsShown() and R.frames.Lairs:IsShown(),"A detail must not hide the summary HUD")
assert(FieldKitStatsFrame:GetHeight()>=32+25*table.getn(FieldKitStatsFrame.rows),"Statistics require readable row spacing")
C.Open("Stats")
local chrome=T.Button(UIParent,nil,"Test",0,0,200,30,function() end)
T.State(chrome,true);assert(not chrome.fieldkitSkin.selected:IsShown(),"No side stripe on selected controls")
local row=R.frames.Lairs.rows[1];if row.lamp then assert(not row.lamp:IsShown(),"Elwynn empty state must not inherit Naxx lamps") end
assert(Minimap:GetWidth()==270 and ActionButton1:GetWidth()==R.layout.actions[3]-8)
C.Set("zoneThemes",false)
print("Review feedback: persistent summaries, readable detail rows, clean selection and inset actions passed")
