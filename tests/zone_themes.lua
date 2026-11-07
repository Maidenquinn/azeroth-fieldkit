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
C.Refresh();assert(TargetFrame:GetParent()==H.storage,"Hover must not create a second native target frame")
-- Native auras must stay reachable on the themed target (the native frame is hidden).
local oldBuff,oldDebuff=UnitBuff,UnitDebuff
UnitBuff=function(unit,i) if i<=2 then return "Interface\Icons\Spell_Nature_Regeneration",(i==2 and 3 or 1) end end
UnitDebuff=function(unit,i) if i==1 then return "Interface\Icons\Spell_Shadow_CurseOfTounges",2,"Curse" end end
C.Refresh();local auras=FieldKitThemeTarget.frame.auras
assert(auras.buff[2] and auras.buff[2]:IsShown() and auras.debuff[1]:IsShown() and not (auras.buff[3] and auras.buff[3]:IsShown()),"real buffs/debuffs must show")
local tipUnit;GameTooltip.SetUnitBuff=function(self,u,i) tipUnit=u..i end;GameTooltip.SetOwner=function() end;GameTooltip.Show=function() end
this=auras.buff[2];auras.buff[2].scripts.OnEnter();assert(tipUnit=="target2","aura tooltip must read the native buff")
UnitBuff=function() return nil end;UnitDebuff=function() return nil end
C.Refresh();assert(not auras.buff[1]:IsShown() and not auras.debuff[1]:IsShown(),"auras must clear when none remain")
UnitBuff,UnitDebuff=oldBuff,oldDebuff

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
   do local hole=d.mapHole or {0,0,d.map[3],d.map[3]};local side=math.max(hole[3],hole[4]);assert(Minimap:GetWidth()==side and Minimap:GetHeight()==side,"Map covers its measured opening, still square")end
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
assert(Minimap:GetWidth()==math.max(R.layout.mapHole[3],R.layout.mapHole[4]) and ActionButton1:GetWidth()==R.layout.actions[3]-8)
C.Set("zoneThemes",false)
print("Review feedback: persistent summaries, readable detail rows, clean selection and inset actions passed")

-- Complete cards keep authored backgrounds, collapse through the original dock,
-- and show an equipped item's real name without duplicating its slot label.
C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
assert(not R.frames.Damage.bodyWash or not R.frames.Damage.bodyWash:IsShown())
assert(R.frames.Accessories.rows[1].label.referenceFullText==long and R.frames.Accessories.rows[1].value:GetText()=="")
click(R.frames.Stats.collapse);assert(FieldKitDB.statsCollapsed and not R.frames.Stats:IsShown());assert(FieldKitCollapseDock:IsShown())
FieldKitDB.statsCollapsed=false;FieldKit.ApplyHUDProfileLive();C.Refresh();assert(R.frames.Stats:IsShown())
assert(R.tabs[1].underline:IsShown())
local oldlocked=FieldKitDB.windowsLocked;FieldKitDB.windowsLocked=false
local start=Minimap:GetScript("OnDragStart");assert(type(start)=="function");start();assert(H.identity.azsMoving and not M.root.azsMoving)
Minimap:GetScript("OnDragStop")();assert(not H.identity.azsMoving)
FieldKitDB.windowsLocked=oldlocked
C.Set("zoneThemes",false)
print("Complete cards: original textures, equipment names, collapse dock and grouped minimap dragging passed")

-- An endless boss may have a countdown without disclosing its name.
local nextBossGetter=AZS_GetUpcomingBosses
AZS_GetUpcomingBosses=function() return {} end
AZS_RUN.endl=1;AZS_RUN.nbn="";AZS_RUN.nb=37
local nextBoss=FieldKitNativeTools.NextBoss();assert(nextBoss and nextBoss.left==37 and nextBoss.name==FieldKit_L("Next boss"))
AZS_RUN.endl=nil;AZS_RUN.nbn=nil;AZS_RUN.nb=nil;AZS_GetUpcomingBosses=nextBossGetter
C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
for _,row in ipairs(R.frames.Accessories.rows) do if row:IsShown() then local _,size=row.label:GetFont();assert(size==16,"Equipment labels have a fixed font size") end end
assert(not string.find(R.frames.Damage.total:GetText(),"%? /s"))
C.Set("zoneThemes",false)
print("Endless unnamed boss countdown and fixed equipment typography passed")

-- Empty meter has no live sockets/tracks; six tabs use the same owned surface.
C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
local savedRead=FieldKitMeterLedger.Read
FieldKitMeterLedger.Read=function() return {},0,nil,true end
C.Refresh()
assert(R.frames.Damage.cleanBody:IsShown());assert(not R.frames.Damage.liveBody or not R.frames.Damage.liveBody:IsShown())
for _,row in ipairs(R.frames.Damage.rows) do assert(not row.icon:IsShown() and not row.bar:IsShown());assert(not row.trough or not row.trough:IsShown()) end
for _,tab in ipairs(R.tabs) do assert(tab.fieldkitArtOnly and tab.fieldkitSkin) end
local xs={579,662,745,828,911,994,1077}
for i,slot in ipairs({1,2,3,4,5,6,12}) do
 local b=getglobal("ActionButton"..slot);local _,_,_,x,y=b:GetPoint()
 assert(x==xs[i]-R.layout.rects.dock[1] and y==R.layout.rects.dock[2]-795)
 assert(b:GetWidth()==66 and b:GetHeight()==66)
end
FieldKitMeterLedger.Read=savedRead;C.Set("zoneThemes",false)
print("Empty combat state, consistent tab surfaces and measured Elwynn action sockets passed")

C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
FieldKitDB.meterFrame=true;FieldKitDB.lairFrame=true;FieldKitDB.statsFrame=true;FieldKitDB.effectsFrame=true;FieldKitDB.statsCollapsed=false;FieldKitDB.collapsedWindows={};C.Refresh()
for _,kind in ipairs({"Damage","Lairs","Stats","Effects"}) do
 local f=R.frames[kind];assert(f.cleanBody:IsShown());assert(not f.footerPatch or not f.footerPatch:IsShown());assert(not f.emptySocket or not f.emptySocket:IsShown())
end
assert(Minimap:GetWidth()==math.max(R.layout.mapHole[3],R.layout.mapHole[4]))
for _,tab in ipairs(R.tabs) do assert(tab.fieldkitArtOnly);for _,part in ipairs(tab.fieldkitSkin.parts) do assert(not part.texture:IsShown()) end end
C.Set("zoneThemes",false)
print("Clean card materials, flat meter tabs and bounded square minimap passed")

C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
FieldKitDB.windowsLocked=true
for _,kind in ipairs({"Damage","Stats","Lairs"}) do
 C.Open(kind)
 local f=getglobal(({Damage="FieldKitMeterFrame",Stats="FieldKitStatsFrame",Lairs="FieldKitLairFrame"})[kind])
 local handle=C.detailHandles[f];assert(handle and handle:IsShown())
 this=handle;handle:GetScript("OnDragStart")();assert(f.azsMoving,"Detail title remains movable with locked HUD")
 f:SetPoint("CENTER",UIParent,"CENTER",123,87);handle:GetScript("OnDragStop")();assert(not f.azsMoving)
 local a=C.Position(f);assert(a and a[3]==123 and a[4]==87)
 C.Open(kind);C.Open(kind);a=C.Position(f);assert(a and a[3]==123 and a[4]==87,"Reopening preserves the reader position")
 C.Open(kind)
end
local savedTaken=AZS_TAKEN;AZS_TAKEN={{source="mob melee",dmg=42}}
local oldLang=FieldKitDB.language;FieldKitDB.language="fr"
local taken=FieldKitMeterLedger.Read("taken");assert(taken[1].displayName==FieldKit_L("Monster melee"))
AZS_TAKEN=savedTaken;FieldKitDB.language=oldLang
local oldFriend=UnitIsFriend;UnitIsFriend=function() return true end
UnitExists=function(unit) return unit=="target" or (exists and exists(unit)) end
C.Refresh();assert(FieldKitThemeTarget.frame:IsShown() and TargetFrame:GetParent()==H.storage)
UnitIsFriend=oldFriend;UnitExists=exists;C.Set("zoneThemes",false)
print("Locked HUD readers remain movable and persistent; localized taken sources and single target surface passed")

-- alpha.13: in-card Equipment/Spells tabs, bounded scrolling lists, four guardians, buffs with native icon restoration.
local function Inside(f,zone,label)
 local a=R.CardRect(label,R.layout);local h=a[4]
 for _,r in ipairs(f.rows) do if r:IsShown() then
  local _,_,_,x,y=r:GetPoint();assert(-y+r:GetHeight()<=h-10,zone..": "..label.." row leaves the card ("..tostring(-y+r:GetHeight()).." > "..tostring(h-10)..")")
  assert(x+r:GetWidth()<=a[3]-8,zone..": "..label.." row crosses the right border")
 end end
 local last=nil
 for _,r in ipairs(f.rows) do if r:IsShown() then local _,_,_,_,y=r:GetPoint();if last then assert(-y>=last,zone..": "..label.." rows overlap") end;last=-y+r:GetHeight() end end
end
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 -- Tabs
 local oldItems,oldSpells=FieldKitLoadout.items,FieldKitLoadout.spells
 FieldKitLoadout.items={[2]={name="Amulet of Test",bonuses={}}}
 FieldKitLoadout.spells={}
 for i=1,8 do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={"+1%"},upgrades={}}) end
 FieldKitDB.loadoutTab=1;C.Refresh(true)
 local acc=R.frames.Accessories;assert(acc.cardTabs and acc.cardTabs[1]:IsShown() and acc.cardTabs[2]:IsShown(),zone..": two tabs inside the card")
 assert(acc.rows[1].label:GetText()=="Amulet of Test" and not C.open.Accessories,zone..": equipment tab content")
 click(acc.cardTabs[2]);assert(FieldKitDB.loadoutTab==2 and not C.open.Accessories,zone..": Spells replaces the content of the same card")
 assert(acc:IsShown() and acc.rows[1].label:GetText()=="Spell 1" and acc.rows[1].value:GetText()=="Rank 1" and acc.rows[1].entry.name=="Spell 1",zone..": spells listed with ranks and tooltip entries")
 assert(acc.pager:IsShown() and acc.pager:GetText()=="1-5 / 8",zone..": spells beyond the card scroll with a pager")
 Inside(acc,zone,"Accessories")
 this=acc;arg1=-1;acc.scripts.OnMouseWheel();assert(R.scroll.Accessories==1 and acc.rows[1].label:GetText()=="Spell 2",zone..": wheel scrolls the list")

 arg1=-100;acc.scripts.OnMouseWheel();assert(acc.rows[5].label:GetText()=="Spell 8" and acc.pager:GetText()=="4-8 / 8",zone..": scrolling is clamped")
 click(acc.cardTabs[1]);assert(FieldKitDB.loadoutTab==1 and acc.rows[1].label:GetText()=="Amulet of Test" and not acc.pager:IsShown(),zone..": back to Equipment")
 FieldKitLoadout.items,FieldKitLoadout.spells=oldItems,oldSpells
 -- Effects: 0,1,2,4,many
 local effects=FieldKitNativeTools.frames[1];local oldRows=effects.lastRows
 local oldFrame=BuffFrame;BuffFrame=CreateFrame("Frame","BuffFrame",UIParent);BuffFrame:Show()
 for _,count in ipairs({0,1,2,4,12}) do
  effects.lastRows={}
  for i=1,count do table.insert(effects.lastRows,{label="A very long effect name number "..i.." that must be fitted",value="3x · 12:34",icon="Interface\Icons\X",buffIndex=i}) end
  C.Refresh(true);local e=R.frames.Effects;Inside(e,zone,"Effects")
  if count==0 then assert(e.rows[1].label:GetText()==FieldKit_L("No active effect") and not e.rows[2]:IsShown() and not e.pager:IsShown() and BuffFrame:GetParent()==UIParent,zone..": exact empty effects state keeps native buffs")
  else
   assert(e.rows[1].buffIndex==1 and e.rows[1].icon:IsShown(),zone..": real buff row")
   assert(e.rows[2]:IsShown()==(count>=2),zone..": buff row count "..count)
   assert(e.pager:IsShown()==(count>2),zone..": pager only when the list exceeds the card")
   assert(BuffFrame:GetParent()==H.storage,zone..": duplicate native buff icons masked while the card lists them")
  end
 end
 this=R.frames.Effects;arg1=-1;R.frames.Effects.scripts.OnMouseWheel();assert(R.frames.Effects.rows[1].buffIndex==2,zone..": effects scroll")
 R.scroll.Effects=0
 C.Set("zoneThemeVariant","minimal");assert(BuffFrame:GetParent()==UIParent,zone..": native buffs restored when the card is not displayed")
 C.Set("zoneThemeVariant","complete");effects.lastRows={{label="Buff",value="",icon="Interface\Icons\X",buffIndex=1}};C.Refresh(true);assert(BuffFrame:GetParent()==H.storage,zone..": masked again when the card returns")
 C.Set("zoneThemes",false);assert(BuffFrame:GetParent()==UIParent,zone..": native buffs restored when the theme is off")
 BuffFrame=oldFrame;effects.lastRows=oldRows
 C.Set("zoneThemes",true)
 -- Lairs: 0..4 guardians and more than four
 local oldRead=FieldKitNative.Read;local lairs={}
 FieldKitNative.Read=function(name,...) if name=="AZS_GetLairs" then return lairs end return oldRead(name,unpack(arg)) end
 for _,count in ipairs({0,1,2,3,4,6}) do
  lairs={}
  for i=1,count do table.insert(lairs,{name="Guardian "..i,state=(i==1 and "awake" or (i==2 and "asleep" or "empty")),left=(i>2 and 30*i or nil),x=i*10,y=0}) end
  C.Refresh(true);local panel=R.frames.Lairs;Inside(panel,zone,"Lairs")
  if count==0 then assert(panel.rows[1].label:GetText()==FieldKit_L("No active lair") or panel.rows[1].label:GetText()=="?",zone..": empty lair state")
  else
   local shown=0;for _,r in ipairs(panel.rows) do if r:IsShown() then shown=shown+1 end end
   assert(shown==math.min(4,count),zone..": all guardians up to four are visible ("..count..")")
   assert(panel.rows[1].label:GetText()=="Guardian 1" and not string.find(panel.rows[math.min(4,count)].label:GetText(),"+"),zone..": no +N placeholder")
   for _,r in ipairs(panel.rows) do assert(not r.lamp or not r.lamp:IsShown(),zone..": no raw status squares") end
   assert(panel.pager:IsShown()==(count>4),zone..": pager only beyond four")
  end
 end
 R.scroll.Lairs=0;FieldKitNative.Read=oldRead
end
C.Set("zoneThemes",false)
print("Equipment/Spells tabs, bounded effects and lairs, native buff restoration passed (synthetic)")

-- alpha.14: portrait under the art rim, readable two-row damage navigation, centred boss/guardian card.
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local d=R.frames.Damage;local a=R.CardRect("Damage",R.layout)
 assert(table.getn(R.tabs)==6)
 local seen={}
 for i,b in ipairs(R.tabs) do
  assert(b:IsShown(),zone..": all six damage categories are reachable ("..i..")")
  local _,_,_,x,y=b:GetPoint();assert(x>=0 and x+b:GetWidth()<=a[3] and -y+b:GetHeight()<=a[4]-10,zone..": damage tab inside the card")
  for j=1,i-1 do local o=R.tabs[j];local _,_,_,ox,oy=o:GetPoint();assert(not (x<ox+o:GetWidth() and ox<x+b:GetWidth() and y==oy),zone..": damage tabs collide") end
  assert(b.fieldkitLabel:GetWidth()>=60,zone..": damage tab label has room")
 end
 click(R.tabs[3]);local _,index=FieldKitMeterSuite.View();assert(index==3 and R.tabs[3].underline:IsShown() and not R.tabs[1].underline:IsShown(),zone..": category changes immediately and the active tab is marked")
 click(R.tabs[1])
 local firstRow=nil;for _,r in ipairs(d.rows) do if r:IsShown() then local _,_,_,_,y=r:GetPoint();firstRow=-y;break end end
 local _,_,_,_,lowTab=R.tabs[6]:GetPoint();assert(firstRow>=-lowTab+R.tabs[6]:GetHeight(),zone..": first row does not overlap the tab rows")
 -- Portrait: owned by a frame beneath the art, over an opaque backing
 assert(R.portraitFrame and R.portraitBack and R.portraitFrame:GetFrameLevel()<=H.healthRoot:GetFrameLevel(),zone..": portrait is drawn under the art rim")
 -- Equipment / Spells tabs keep a visible active mark
 FieldKitDB.loadoutTab=1;C.Refresh(true);local acc=R.frames.Accessories
 assert(acc.cardTabs[1].underline:IsShown() and not acc.cardTabs[2].underline:IsShown() and acc.cardTabs[1].rule:IsShown() and acc.cardTabs[2].rule:IsShown(),zone..": active tab marked, inactive tab has a rule")
end
-- Boss and guardian cards
local oldUnits,oldPhase=AZS_UNITS,AZS_RUN.ph
AZS_RUN.ph="run"
local long="An extremely long boss name that cannot fit one line of the compact card"
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 AZS_UNITS={{kind="boss",id=1,name=long,hp=500,hpm=1000,state=0},{kind="guardian",id=5001,name="Brute gordunni",hp=6705,hpm=12200,state=1}}
 update(FieldKitFrame,.3)
 local b1,b2=getglobal("FieldKitBossFrame1Compact"),getglobal("FieldKitBossFrame2Compact")
 assert(b1:IsShown() and b1:GetWidth()==340 and b1:GetHeight()==66,zone..": themed boss card size")
 local p,rel=b1:GetPoint();assert(p=="TOP" and rel==getglobal("FieldKitBossFrame1"),zone..": boss card is centred on its plate")
 assert(b1.name.referenceFullText==long and b1.hp:GetText()~="" and b1.tag:GetText()==FieldKit_L("Boss"),zone..": full long name retained, type and HP shown")
 assert(b1.name:GetWidth()+b1.tag:GetWidth()+72<=b1:GetWidth(),zone..": name and tag do not collide")
 if b2 and b2:IsShown() then assert(b2.tag:GetText()==FieldKit_L("Guardian"),zone..": guardian is labelled differently");local _,_,_,_,y=getglobal("FieldKitBossFrame2"):GetPoint();assert(-y>=66,zone..": stacked boss cards do not overlap") end
 AZS_UNITS={};update(FieldKitFrame,.3);assert(not b1:IsShown(),zone..": boss card disappears with the real state")
 AZS_UNITS={{kind="boss",id=1,name="Back",hp=1,hpm=1,state=0}};update(FieldKitFrame,.3);assert(b1:IsShown(),zone..": boss card reappears")
end
AZS_UNITS,AZS_RUN.ph=oldUnits,oldPhase
C.Set("zoneThemes",false)
print("Portrait layering, damage navigation, tab marks and boss/guardian card passed (synthetic)")

-- alpha.15: map fills its opening (rim redrawn above), header tabs, portrait socket, lair names, empty damage state, tab hit areas.
for _,zone in ipairs({"elwynn","naxx"}) do
 for _,variant in ipairs({"complete","minimal","alternative"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant",variant);C.Set("zoneThemes",true);C.Refresh(true)
  local d=R.layout;local M=FieldKitThemeMinimap
  if d.mapHole then
   local side=math.max(d.mapHole[3],d.mapHole[4]);assert(Minimap:GetWidth()==side and Minimap:GetHeight()==side,zone.."/"..variant..": square map covers the opening")
   assert(M.rim and M.rim:IsShown() and not M.rim.mouseEnabled and M.rim:GetFrameLevel()>Minimap:GetFrameLevel(),zone.."/"..variant..": art rim redrawn above the map, never intercepting clicks")
   local any=false;for _,t in ipairs(M.rimTex) do if t:IsShown() then any=true end end;assert(any,zone.."/"..variant..": rim strip drawn")
  end
  if d.portraitHole then
   local side=math.max(d.portraitHole[3],d.portraitHole[4])+2;assert(R.portrait:GetWidth()==side and R.portrait:GetHeight()==side and R.portraitBack:GetWidth()==side,zone.."/"..variant..": portrait covers the whole socket undistorted")
  end
 end
 C.Set("zoneThemeVariant","complete");C.Refresh(true)
 -- header tabs
 local acc=R.frames.Accessories;local a=R.layout.rects.Accessories
 assert(not acc.title:IsShown() and acc.cardTabs[1]:IsShown() and acc.cardTabs[2]:IsShown(),zone..": equipment title replaced by header tabs")
 local _,_,_,x1,y1=acc.cardTabs[1]:GetPoint();local _,_,_,x2,y2=acc.cardTabs[2]:GetPoint()
 assert(y1==y2 and -y1<=12 and acc.cardTabs[1]:GetHeight()>=32 and x1+acc.cardTabs[1]:GetWidth()==x2 and x2+acc.cardTabs[2]:GetWidth()<=a[3]-30,zone..": header tabs are contiguous, in the header and clear of the collapse button")
 local _,_,_,_,ry=acc.rows[1]:GetPoint();assert(-ry==R.SocketY(zone,1) and -ry<=58,zone..": content starts in the recovered space, on the first socket")
 -- Lair names get the width that is left
 local lairs={};for i=1,4 do table.insert(lairs,{name="Anub'Rekhan the Very Long Named Guardian "..i,state=(i==1 and "awake" or "empty"),left=(i>1 and 60 or nil),x=i,y=0}) end
 local oldRead=FieldKitNative.Read;FieldKitNative.Read=function(name,...) if name=="AZS_GetLairs" then return lairs end return oldRead(name,unpack(arg)) end
 C.Refresh(true);local panel=R.frames.Lairs;local rowW=zone=="naxx" and R.layout.rects.Lairs[3]-110 or R.layout.rects.Lairs[3]-96
 for i=1,4 do local r=panel.rows[i];assert(r:IsShown() and r.label:GetWidth()+r.value:GetWidth()<=rowW,zone..": lair columns do not overlap");assert(r.label:GetWidth()>rowW*.4,zone..": name receives the available width") ;assert(r.label.referenceFullText and string.find(r.label.referenceFullText,"Anub"),zone..": full lair name kept for hover") end
 FieldKitNative.Read=oldRead
 -- Damage: empty state centred in the content area; six tabs reachable; layout not re-applied every refresh
 local dm=R.frames.Damage;local dr=R.CardRect("Damage",R.layout)
 for k=1,6 do local b=R.tabs[k];assert(b:IsShown() and b:GetHeight()>=24 and b:GetWidth()>=80,zone..": damage tab hit area "..k) end
 local seenLevel=R.tabs[1]:GetFrameLevel();local key=R.tabs[1].layoutKey;C.Refresh(true);assert(R.tabs[1].layoutKey==key and R.tabs[1]:GetFrameLevel()==seenLevel,zone..": tab layout is stable across refreshes")
 local r1=dm.rows[1];local _,_,_,rx,ry=r1:GetPoint();local top=zone=="naxx" and 146 or 98;local bottom=zone=="naxx" and dr[4]-30 or dr[4]-52
 if r1.label:GetText()==FieldKit_L("No combat data") then
  assert(rx==24 and -ry==top and r1:GetHeight()==bottom-top and r1.label:GetWidth()==dr[3]-48,zone..": empty state spans the content area (centred)")
 end
 FieldKitDB.language="en";C.Refresh(true);assert(R.frames.Accessories.cardTabs[1].fieldkitLabel:GetText()=="Equipment" and R.frames.Accessories.cardTabs[2].fieldkitLabel:GetText()=="Spells",zone..": English header tabs")
 FieldKitDB.language="fr";C.Refresh(true);assert(R.frames.Accessories.cardTabs[1].fieldkitLabel:GetText()=="Équipement" and R.frames.Accessories.cardTabs[2].fieldkitLabel:GetText()=="Sorts",zone..": French header tabs")
end
C.Set("zoneThemes",false)
assert(FieldKitThemeMinimap.rim==nil or not FieldKitThemeMinimap.rim:IsShown(),"rim hidden when the theme is off")
print("Map fill and rim, portrait socket, header tabs, lair columns, empty damage state and tab stability passed (synthetic)")

-- alpha.16: drag survives the 0.2 s refresh, icons centred in painted sockets, Damage foot never overlaps rows, third-party map buttons.
FieldKitDB.windowsLocked=false
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 for _,kind in ipairs({"Accessories","Damage","Lairs"}) do
  local f=R.frames[kind];this=f;f.scripts.OnDragStart();assert(f.azsMoving,zone.." "..kind..": drag starts")
  -- The mock does not fire OnHide, so count Hide calls: in the client every Hide of a bound card ends its drag (C.Bind OnHide -> C.Finish).
  local hides=0;f.Hide=function(self) hides=hides+1;self.shown=false end
  for tick=1,4 do NOW=NOW+.25;C.Refresh(true);assert(f.azsMoving and f:IsShown(),zone.." "..kind..": refresh must not end a card that is being dragged (tick "..tick..")") end
  assert(hides==0,zone.." "..kind..": the refresh must never Hide a card under the mouse ("..hides.." Hide calls)");f.Hide=nil
  f.GetLeft=function() return 321 end;f.GetTop=function() return 654 end
  f:ClearAllPoints();f:SetPoint("TOPLEFT",R.canvas,"BOTTOMLEFT",321,654);this=f;f.scripts.OnDragStop()
  local saved=C.Position(f);assert(saved and saved[3]==321 and saved[4]==654,zone.." "..kind..": released position saved even when the engine anchors to the canvas")
  C.Refresh(true);local _,rel,_,x,y=f:GetPoint();assert(rel==UIParent and x==321 and y==654,zone.." "..kind..": position kept after refresh")
  f.referenceRect=nil;f.referenceGeometryKey=nil;C.revision=C.revision+1;C.Refresh(true);_,rel,_,x,y=f:GetPoint();assert(x==321 and y==654,zone.." "..kind..": position restored after a re-layout / reload")
  f.GetLeft=nil;f.GetTop=nil;FieldKitDB.zoneThemePositions[C.currentLayout][f:GetName()]=nil;f.referenceRect=nil;C.revision=C.revision+1;C.Refresh(true)
 end
 -- icons centred in sockets
 local oldTex=GetInventoryItemTexture;GetInventoryItemTexture=function() return "Interface\Icons\X" end
 local oldItems=FieldKitLoadout.items;FieldKitLoadout.items={[2]={name="Amulet",bonuses={}}};FieldKitDB.loadoutTab=1;C.Refresh(true)
 local acc=R.frames.Accessories
 for i=1,5 do
  local r=acc.rows[i];local _,_,_,rx,ry=r:GetPoint();local _,_,_,ix,iy=r.icon:GetPoint();local size=r.icon:GetWidth()
  local sy=R.SocketY(zone,i);local sh=R.SocketH(zone);local _,sock=nil,nil
  assert(-ry==sy and r:GetHeight()==sh,zone..": row "..i.." sits on its socket")
  assert(r.icon:GetHeight()==size and size<=sh-2 and -iy==(sh-size)/2,zone..": icon "..i.." vertically centred")
  local socketCentre=({elwynn=32+14,naxx=32+19})[zone];assert(rx+ix+size/2==socketCentre,zone..": icon "..i.." horizontally centred")
 end
 GetInventoryItemTexture=oldTex;FieldKitLoadout.items=oldItems
 -- Damage: last row clear of the foot, scrolling, FR and EN
 local oldRead=FieldKitMeterLedger.Read
 for _,count in ipairs({0,1,4,6,8,12}) do
  for _,lang in ipairs({"fr","en"}) do
   FieldKitDB.language=lang
   FieldKitMeterLedger.Read=function() local lines={};for i=1,count do table.insert(lines,{name="Spell "..i,share=1/i,icon="Interface\Icons\X"}) end return lines,100,10,true end
   R.scroll.Damage=0;C.Refresh(true);local dm=R.frames.Damage;local dr=R.CardRect("Damage",R.layout)
   local capacity=6;local shown=0;local lowest=0
   for _,r in ipairs(dm.rows) do if r:IsShown() then shown=shown+1;local _,_,_,_,y=r:GetPoint();lowest=math.max(lowest,-y+r:GetHeight()) end end
   assert(shown==math.max(1,math.min(capacity,count)),zone..": Damage shows "..count.." spells in "..shown.." rows")
   local limit=zone=="naxx" and dr[4]-12 or dr[4]-48
   assert(lowest<=limit,zone..": Damage last row ("..lowest..") stays above the foot ("..limit..") with "..count.." spells ["..lang.."]")
   if zone=="elwynn" then assert(not dm.pager:IsShown() and (count>capacity)==(string.find(dm.more.fieldkitLabel:GetText(),"/",1,true)~=nil),zone..": scroll position is on the foot button only when scrolling is needed")
   else assert(dm.pager:IsShown()==(count>capacity),zone..": Damage pager only when scrolling is needed") end
   if zone=="elwynn" then assert(dm.more:IsShown() and dm.more:GetHeight()==28 and dm.more:GetWidth()==dr[3]-42,zone..": All spells button spans its full surface") end
   if count>capacity then this=dm;arg1=-100;dm.scripts.OnMouseWheel();assert(dm.rows[1].label:GetText()=="Spell "..(count-capacity+1),zone..": scrolling reaches the last spell") end
  end
 end
 FieldKitMeterLedger.Read=oldRead;FieldKitDB.language="fr"
end
-- Third-party minimap buttons: owner keeps control; gear rides the opening edge; everything restored.
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local M=FieldKitThemeMinimap
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap);gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local hidden=CreateFrame("Button","AzerothStatsMinimap",Minimap);hidden:SetAlpha(0)
 local shownOne=CreateFrame("Button","AzerothOneMinimapButton",Minimap);shownOne:SetAlpha(1)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear,hidden,shownOne end
 C.Refresh(true)
 local _,rel,_,gx,gy=gear:GetPoint();assert(rel==Minimap and gx>80,"AzerothHub gear is moved out to the edge of the opening, same angle")
 assert(hidden:GetAlpha()==0 and hidden:GetParent()==Minimap,"a button hidden by its owner keeps its alpha and parent")
 assert(M.launcherProxies[2] and not M.launcherProxies[2]:IsShown(),"no proxy for a button its owner hid")
 assert(M.launcherProxies[3] and M.launcherProxies[3]:IsShown(),"proxy shown for a button its owner left visible")
 assert(shownOne:GetAlpha()==1 and shownOne:GetParent()==Minimap,"visible third-party button is never re-parented or re-alpha'd")
 C.Set("zoneThemes",false)
 _,rel,_,gx,gy=gear:GetPoint();assert(rel==Minimap and gx==80 and gy==0,"gear anchor restored")
 assert(hidden:GetAlpha()==0,"FieldKit does not reactivate a button hidden by another addon")
 Minimap.GetChildren=oldChildren
end
print("Drag across refreshes (simulated), socket-centred icons, Damage foot clearance and third-party map buttons passed (synthetic)")

-- alpha.17: click stability, taller Damage card, neighbours, repeated theme transitions with third-party map buttons.
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 -- 30 alternations per tab group with the 0.2 s refresh running between press and release: nothing may be hidden
 local acc,dm=R.frames.Accessories,R.frames.Damage
 local watched={acc,dm,acc.cardTabs[1],acc.cardTabs[2]};for _,b in ipairs(R.tabs) do table.insert(watched,b) end;for _,r in ipairs(acc.rows) do table.insert(watched,r) end;for _,r in ipairs(dm.rows) do table.insert(watched,r) end
 local hides=0;local lastHidden;local counting=false;for _,f in ipairs(watched) do f.Hide=function(self) if counting and self.shown~=false then hides=hides+1;lastHidden=tostring(self:GetName() or self.kind) end;self.shown=false end end
 local snap={};for _,d in ipairs(R.diagButtons) do snap[d]={d.down,d.up,d.click} end
 for n=1,30 do
  local want=(math.mod(n,2)==1) and 2 or 1
  local b=acc.cardTabs[want];local before=b.fieldkitDiag.down
  b.scripts.OnMouseDown();NOW=NOW+.25;counting=true;C.Refresh(true);counting=false;b.scripts.OnMouseUp();click(b)
  assert(FieldKitDB.loadoutTab==want and acc.cardTabs[want].fieldkitSelected==true,zone..": Equipment/Spells click "..n.." was lost")
  local view=math.mod(n,6)+1;local t=R.tabs[view]
  t.scripts.OnMouseDown();NOW=NOW+.25;counting=true;C.Refresh(true);counting=false;t.scripts.OnMouseUp();click(t)
  local _,index=FieldKitMeterSuite.View();assert(index==view,zone..": Damage category click "..n.." was lost")
 end
 assert(hides==0,zone..": refreshes hid "..hides.." visible interactive frames between press and release (last: "..tostring(lastHidden)..")")
 for _,f in ipairs(watched) do f.Hide=nil end
 local lost=0;for d,was in pairs(snap) do local downs,clicks=d.down-was[1],d.click-was[3];if downs>0 and downs~=clicks then lost=lost+1 end end;assert(lost==0,zone..": click accounting shows presses without clicks")
 click(R.tabs[1])
 -- Damage card: taller, art contiguous, neighbours clear
 C.Refresh(true);local d0=R.layout.rects.Damage;local a=R.CardRect("Damage",R.layout)
 assert(a[4]>d0[4] and dm:GetHeight()==a[4],zone..": Damage card is taller")
 local pieces={};for _,t in ipairs(dm.referenceTiles) do if t:IsShown() then local _,_,_,_,y=t:GetPoint();table.insert(pieces,{-y,t:GetHeight()}) end end
 table.sort(pieces,function(p,q) return p[1]<q[1] end);local reach=0
 for _,p in ipairs(pieces) do assert(p[1]==reach,zone..": Damage art has a gap or overlap at "..tostring(p[1]).." (expected "..tostring(reach)..")");reach=p[1]+p[2] end
 assert(reach==a[4],zone..": stretched art ends exactly at the card bottom")
 local rects=R.layout.rects;local L=R.CardRect("Lairs",R.layout)
 if zone=="elwynn" then
  assert(L[2]+L[4]-7<a[2]+6,"Lairs bottom edge stays above the taller Damage card");assert(a[2]+a[4]-6<=rects.chat[2]+9,"Damage bottom edge stays above the chat")
 else
  assert(a[2]+1>rects.header[2]+rects.header[4]-8 or a[2]>rects.header[2]+rects.header[4]-8,"Damage stays below the header");assert(a[2]+a[4]-5<L[2]+2,"Damage bottom edge stays above the Lairs card")
 end
 -- Lairs: larger inner margins, four guardians, long names
 local lairs={};for i=1,4 do table.insert(lairs,{name="Anub'Rekhan the Very Long Named Guardian "..i,state="awake",x=i,y=0}) end
 local oldRead=FieldKitNative.Read;FieldKitNative.Read=function(name,...) if name=="AZS_GetLairs" then return lairs end return oldRead(name,unpack(arg)) end
 C.Refresh(true);local panel=R.frames.Lairs;local pr=R.CardRect("Lairs",R.layout)
 for i=1,4 do local r=panel.rows[i];local _,_,_,x,y=r:GetPoint();assert(r:IsShown() and x>=46 and x+r:GetWidth()<=pr[3]-44,zone..": lair "..i.." keeps side margins ("..x.." / "..(pr[3]-x-r:GetWidth())..")");assert(-y>=46 and -y+r:GetHeight()<=pr[4]-12,zone..": lair "..i.." keeps top/bottom margins") end
 FieldKitNative.Read=oldRead
end
-- Repeated transitions with a drag-style owner: active -> inactive -> active, reload-like re-apply, layout change
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local M=FieldKitThemeMinimap
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap)
 local parkedOne=CreateFrame("Button","AzerothStatsMinimap",Minimap);parkedOne:SetPoint("CENTER",Minimap,"CENTER",70,20)
 -- this client may return the relative frame as a name
 local rawGet=parkedOne.GetPoint;parkedOne.GetPoint=function(self) local p,rel,rp,x,y=rawGet(self);if type(rel)=="table" and rel.GetName then rel=rel:GetName() end;return p,rel,rp,x,y end
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear,parkedOne end
 local function Owner(angle) local a=math.rad(angle);gear:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80) end
 local lastAngle=40;Owner(lastAngle)
 for cycle=1,5 do
  C.Refresh(true)
  for step=1,6 do lastAngle=lastAngle+37;Owner(lastAngle) -- the owner places the button on every drag frame
   local _,_,_,gx,gy=gear:GetPoint();local radius=math.sqrt(gx*gx+gy*gy);assert(radius>85,"cycle "..cycle..": dragged gear is placed at the edge at once, not pulled to the centre ("..radius..")")
   local want=math.rad(lastAngle);assert(math.abs(math.atan2(gy,gx)-math.atan2(math.sin(want),math.cos(want)))<1e-6,"cycle "..cycle..": angle preserved") end
  C.Set("zoneThemes",false)
  local _,_,_,gx,gy=gear:GetPoint();local a=math.rad(lastAngle);assert(math.abs(gx-math.cos(a)*80)<1e-6 and math.abs(gy-math.sin(a)*80)<1e-6,"cycle "..cycle..": exact owner position after theme off")
  assert(rawget(gear,"SetPoint")==nil,"cycle "..cycle..": button method unwrapped")
  local _,_,_,px,py=parkedOne:GetPoint();assert(px==70 and py==20,"cycle "..cycle..": parked third-party button restored although the relative frame is returned by name")
  Owner(lastAngle+11);lastAngle=lastAngle+11 -- repositioned by hand while the theme is off
  C.Set("zoneThemes",true);C.Refresh(true)
  local _,_,_,gx2,gy2=gear:GetPoint();assert(gear:IsShown() and math.sqrt(gx2*gx2+gy2*gy2)>85,"cycle "..cycle..": gear present at the edge after reactivation")
  if cycle==3 then C.Set("zoneThemeVariant","minimal");C.Refresh(true);local _,_,_,mx,my=gear:GetPoint();assert(math.sqrt(mx*mx+my*my)>0,"gear survives a layout change");C.Set("zoneThemeVariant","complete");C.Refresh(true) end
 end
 C.Set("zoneThemes",false);Minimap.GetChildren=oldChildren
end
print("30-alternation click stability, taller Damage card, lair margins and repeated map-button transitions passed (synthetic)")
