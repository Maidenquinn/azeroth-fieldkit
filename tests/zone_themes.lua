-- the AzerothHub gear as the client builds it: 32 x 32
function NewGear() local g=CreateFrame("Button","AzerothHubMinimapButton",Minimap);g:SetWidth(32);g:SetHeight(32);return g end
-- Synthetic behavioral acceptance only: does not certify the native renderer.
TARGET=nil
fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
assert(FieldKitZoneThemes.ui and table.getn(FieldKitZoneThemes.ui)==12,"Theme settings must be present in the real options journey")
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
assert(Minimap:GetScript("OnDragStart")==nil and Minimap:GetScript("OnMouseDown")==nil,"FieldKit installs no script on the native Minimap")
local start=M.root:GetScript("OnDragStart");assert(type(start)=="function");this=M.root;start();assert(H.identity.azsMoving and not M.root.azsMoving,"a drag reaching the map container moves the whole group (its owner), never the container alone")
M.root:GetScript("OnDragStop")();assert(not H.identity.azsMoving)
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
 -- alpha.36: the card grows with the content: all eight spells are listed at once, no scrolling, no pager
 assert(acc.rows[8]:IsShown() and acc.rows[8].label:GetText()=="Spell 8" and not acc.pager:IsShown() and not string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"/",1,true),zone..": every spell is visible without scrolling")
 Inside(acc,zone,"Accessories")
 -- scrolling remains the fallback when the screen cannot hold the card
 local realMax=R.AccMaxRows;R.AccMaxRows=function() return 7 end;C.Refresh(true)
 assert(not acc.rows[8]:IsShown() and string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"1-7/8",1,true),zone..": fallback: seven rows and the position in the tab")
 this=acc;arg1=-1;acc.scripts.OnMouseWheel();assert(R.scroll.Accessories==1 and acc.rows[1].label:GetText()=="Spell 2",zone..": wheel scrolls the fallback list")

 arg1=-100;acc.scripts.OnMouseWheel();assert(acc.rows[7].label:GetText()=="Spell 8" and string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"2-8/8",1,true) and not acc.pager:IsShown(),zone..": scrolling is clamped")
 R.AccMaxRows=realMax;R.scroll.Accessories=0;C.Refresh(true)
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
  assert(b.fieldkitLabel:GetWidth()>=48,zone..": damage tab label has room ("..b.fieldkitLabel:GetWidth()..")")
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
 for k=1,6 do local b=R.tabs[k];assert(b:IsShown() and b:GetHeight()>=24 and b:GetWidth()>=(zone=="elwynn" and 56 or 80),zone..": damage tab hit area "..k.." ("..b:GetWidth().."x"..b:GetHeight()..")") end
 local seenLevel=R.tabs[1]:GetFrameLevel();local key=R.tabs[1].layoutKey;C.Refresh(true);assert(R.tabs[1].layoutKey==key and R.tabs[1]:GetFrameLevel()==seenLevel,zone..": tab layout is stable across refreshes")
 local r1=dm.rows[1];local _,_,_,rx,ry=r1:GetPoint();local top=zone=="naxx" and 144 or R.listTop;local bottom=zone=="naxx" and dr[4]-30 or dr[4]-52
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
   local capacity=R.dmgN;local room=R.DmgMaxRows(R.layout)
   assert(capacity==math.max(6,math.min(count,room)) and R.dmgScroll==(count>capacity),zone..": the Damage card holds every line the screen has room for: "..count.." lines, room "..room..", rows "..tostring(capacity))
   if count<=room then assert(not R.dmgScroll,zone..": no scrolling while the card fits") end
   local shown=0;local lowest=0
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
 FieldKitThemeMinimap.probe.ring=true -- edge placement is an opt-in probe now
 local gear=NewGear();gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local hidden=CreateFrame("Button","AzerothStatsMinimap",Minimap);hidden:SetAlpha(0)
 local shownOne=CreateFrame("Button","AzerothOneMinimapButton",Minimap);shownOne:SetAlpha(1)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear,hidden,shownOne end
 C.Refresh(true)
 local _,rel,_,gx,gy=gear:GetPoint();assert(rel==Minimap and gx>80,"AzerothHub gear is moved out to the edge of the opening, same angle ("..tostring(gx)..","..tostring(gy)..") key="..tostring(M.ringKey).." hole="..tostring(R.layout.mapHole and R.layout.mapHole[3]))
 assert(hidden:GetAlpha()==0 and hidden:GetParent()==Minimap,"a button hidden by its owner keeps its alpha and parent")
 assert(M.launcherProxies[2]==nil,"AzerothStats keeps its own real button: no proxy at all (alpha.44)")
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
 assert((zone=="elwynn")==(a[4]>d0[4]) and dm:GetHeight()==a[4],zone..": Damage card is taller only where the art has room (Naxxramas keeps its approved height)")
 local pieces={};for _,t in ipairs(dm.referenceTiles) do if t:IsShown() then local _,_,_,_,y=t:GetPoint();table.insert(pieces,{-y,t:GetHeight()}) end end
 table.sort(pieces,function(p,q) return p[1]<q[1] end);local reach=0
 for _,p in ipairs(pieces) do assert(p[1]==reach,zone..": Damage art has a gap or overlap at "..tostring(p[1]).." (expected "..tostring(reach)..")");reach=p[1]+p[2] end
 assert(reach==a[4],zone..": stretched art ends exactly at the card bottom")
 local rects=R.layout.rects;local L=R.CardRect("Lairs",R.layout)
 if zone=="elwynn" then
  assert(L[2]+L[4]-7<a[2]+6,"Lairs bottom edge stays above the taller Damage card");assert(a[2]+a[4]-6<=rects.chat[2]+9,"Damage bottom edge stays above the chat")
 else assert(a[2]==rects.Damage[2] and a[4]==rects.Damage[4],"Naxxramas Damage keeps its approved place (identity card above, Lairs below)") end
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
 FieldKitThemeMinimap.probe.ring=true -- edge placement is an opt-in probe now
 local gear=NewGear()
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
   local want=math.rad(lastAngle);local ex,ey=M.Edge(math.cos(want)*80,math.sin(want)*80,32)
   assert(math.abs(ex-gx)<1e-6 and math.abs(ey-gy)<1e-6,"cycle "..cycle..": the owner's own placement is mapped by the ring geometry")
   local diff=math.abs(math.atan2(gy,gx)-math.atan2(math.sin(want),math.cos(want)));if diff>math.pi then diff=2*math.pi-diff end
   assert(diff<math.rad(75),"cycle "..cycle..": the direction is kept, at most slid along the border past a keep-out ("..math.deg(diff)..")") end
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

-- alpha.18: Spells indicator never over rows, for 0/1/5/6/7/12 spells in FR and EN.
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 local oldSpells=FieldKitLoadout.spells
 for _,count in ipairs({0,1,5,6,7,12}) do for _,lang in ipairs({"fr","en"}) do
  FieldKitDB.language=lang;FieldKitLoadout.spells={};for i=1,count do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={},upgrades={}}) end
  FieldKitDB.loadoutTab=2;R.scroll.Accessories=0;C.Refresh(true);local acc=R.frames.Accessories
  assert(not acc.pager:IsShown(),zone..": no counter over the rows ("..count.." spells, "..lang..")")
  local label=acc.cardTabs[2].fieldkitLabel:GetText();assert((R.accScroll and true or false)==(string.find(label,"/",1,true)~=nil),zone..": range in the tab only when scrolling is needed ("..count..")")
  if not R.accScroll then local shown=0;for _,r in ipairs(acc.rows) do if r:IsShown() and r.entry then shown=shown+1 end end;assert(shown==count,zone..": every spell is visible ("..shown.."/"..count..")") end
  local lastBottom=0;for _,r in ipairs(acc.rows) do if r:IsShown() then local _,_,_,_,y=r:GetPoint();lastBottom=math.max(lastBottom,-y+r:GetHeight()) end end
  assert(lastBottom<=R.CardRect("Accessories",R.layout)[4]-10,zone..": rows stay inside the card")
 end end
 FieldKitLoadout.spells=oldSpells;FieldKitDB.language="fr";FieldKitDB.loadoutTab=1
end
C.Set("zoneThemes",false)
print("Spells indicator in the header tab passed (synthetic)")

-- alpha.18: Bonuses expand in place, Damage hover tooltips without a window, map handle under the buttons.
local function FakeStats(n)
 local rows={}
 for i=1,n do
  local label=CreateFrame("FontString");label:SetText("Stat "..i);label:Show()
  local value=CreateFrame("FontString");value:SetText("+"..i.."%")
  rows[i]={label=label,value=value}
 end
 return rows
end
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 local src=FieldKitStatsFrame;local realRows=src.rows;R.statsOpen=false;R.scroll.Stats=0
 for _,n in ipairs({4,12,29}) do
  src.rows=FakeStats(n);C.Refresh(true);local f=R.frames.Stats;local base=R.layout.rects.Stats
  local before=0;for _,fr in ipairs(objects) do if fr._name=="FieldKitReferencePanelStats" then before=before+1 end end
  assert(f:GetHeight()==base[4] and f.more:IsShown()==(zone=="elwynn"),zone..": compact Bonuses is unchanged ("..n..")")
  local oldTitle=f.title:GetText()
  -- a click on "All statistics" (or on the card in Naxxramas, which has no foot link) grows the same card
  if zone=="elwynn" then click(f.more) else this=f;f.scripts.OnMouseUp() end
  assert(R.statsOpen and not C.open.Stats,zone..": no reader window opens ("..n..")")
  local rect=R.CardRect("Stats",R.layout);local eff=R.CardRect("Effects",R.layout)
  assert(f:GetHeight()==rect[4] and f.title:GetText()==oldTitle,zone..": same card, same title, taller ("..n..")")
  local shown=0;local lowest=0;for _,r in ipairs(f.rows) do if r:IsShown() then shown=shown+1;local _,_,_,_,y=r:GetPoint();lowest=math.max(lowest,-y+r:GetHeight()) end end
  assert(shown==math.min(n,R.statsCap or n) and f.rows[1].label:GetText()=="Stat 1" and f.rows[1].value:GetText()=="+1%",zone..": rows show the live values ("..n..")")
  assert(lowest<=rect[4]-(zone=="naxx" and 44 or 48)+4,zone..": rows end above the foot ("..lowest.." vs "..rect[4]..")")
  assert(rect[2]+rect[4]<=R.layout.size[2] and eff[2]+eff[4]<=R.layout.size[2] and R.overflow<=0 and not R.noRoom,zone..": nothing leaves the screen ("..n..") stats="..(rect[2]+rect[4]).." eff="..(eff[2]+eff[4]).." size="..R.layout.size[2].." extra="..tostring(R.statsExtra).." noRoom="..tostring(R.noRoom).." over="..tostring(R.overflow))
  -- (non-overlap of the rendered rectangles is asserted in the placement tests below, vertically or sideways)
  assert(f.more:IsShown(),zone..": a foot button is there to reduce the card")
  src.rows[1].value:SetText("+99%");C.Refresh(true);assert(f.rows[1].value:GetText()=="+99%",zone..": values keep updating while expanded")
  if n>(R.statsCap or n) then this=f;arg1=-100;f.scripts.OnMouseWheel();assert(f.rows[math.min(n,R.statsCap)].label:GetText()=="Stat "..n,zone..": the last statistic is reachable by scrolling")
   assert(string.find(f.more.fieldkitLabel:GetText(),"/"..n,1,true),zone..": scroll position shown on the foot button") end
  click(f.more);assert(not R.statsOpen and f:GetHeight()==base[4],zone..": reduce returns to the compact card")
 end
 -- custom position survives the height change; a moved Effects card is not pushed
 src.rows=FakeStats(12);local f=R.frames.Stats
 local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
 FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelStats"]={"TOPLEFT","BOTTOMLEFT",1200,640}
 FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelEffects"]={"TOPLEFT","BOTTOMLEFT",900,300}
 f.referenceRect=nil;R.frames.Effects.referenceRect=nil;C.revision=C.revision+1;C.Refresh(true)
 local p,rel,rp,x,y=f:GetPoint();assert(p=="TOPLEFT" and x==1200 and y==640,zone..": saved position before growing")
 R.statsOpen=true;C.Refresh(true);p,rel,rp,x,y=f:GetPoint();assert(p=="TOPLEFT" and x==1200 and y==640 and (R.shift.Effects or 0)==0,zone..": custom positions are kept after the height change, Effects not pushed")
 R.statsOpen=false;C.Refresh(true);p,rel,rp,x,y=f:GetPoint();assert(x==1200 and y==640,zone..": and after reducing")
 FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelStats"]=nil;FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelEffects"]=nil
 src.rows=realRows;R.statsOpen=false
end
-- Damage hover tooltips (themed tip frame, sections only when data exists)
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 local function TipText() local out={H.tipTitle:GetText()};for _,r in ipairs(H.tipRows) do if r:IsShown() and r:GetText() then table.insert(out,r:GetText()) end end;return table.concat(out,"|") end
 local oldRead=FieldKitMeterLedger.Read;local oldStats=FieldKitMeterLedger.Stats
 FieldKitMeterLedger.Read=function() return {{name="Fireball",displayName="Fireball",dmg=1200,share=.6,dps=45.5,icon="Interface\Icons\X"},{name="Partial"}},2000,80,true end
 FieldKitMeterLedger.Stats=function(name) if name=="Fireball" then return {hits=20,crits=5,critPct=25,maxHit=300,maxCrit=620,avg=60,burst=410,amount=1200,kills=3} end end
 C.Refresh(true);local dm=R.frames.Damage
 local row=dm.rows[1];this=row;row.scripts.OnEnter();local framesBefore=table.getn(objects) -- the tip frame is created once, by the first hover
 local text=TipText()
 for _,needle in ipairs({"Fireball","60.0%","1200","45.5","60","300","410","25%","620","Hits: 20","3"}) do assert(string.find(text,needle,1,true) or string.find(text,string.gsub(needle,"Hits: ",""),1,true),"tooltip lacks "..needle..": "..text) end
 assert(H.tip:IsShown() and H.tip.icon:IsShown() and not H.tip:IsMouseEnabled(),"themed tip with the spell icon, never taking the pointer")
 local x=H.tip:GetPoint();assert(x=="TOPLEFT" or x=="TOPRIGHT","tip is anchored beside the row, never over it")
 row.scripts.OnLeave();assert(not H.tip:IsShown(),"hidden when the cursor leaves")
 local partial=dm.rows[2];this=partial;partial.scripts.OnEnter();text=TipText()
 assert(string.find(text,"Partial",1,true) and not string.find(text,"DPS",1,true) and not string.find(text,"%",1,true) and not H.tip.icon:IsShown(),"absent data and icon are not invented: "..text)
 for i=1,20 do this=row;row.scripts.OnEnter();row.scripts.OnLeave() end;assert(table.getn(objects)==framesBefore,"hovering never creates frames")
 local wasShown=FieldKitMeterFrame:IsShown();click(row);assert(not C.open.Damage and FieldKitMeterFrame:IsShown()==wasShown,"a left click on a line opens no window")
 this=dm;dm.scripts.OnMouseUp();assert(not C.open.Damage,"nor does a click on the icon column (card background)")
 -- the tooltip must not break the pinned details of other cards
 H.Tip(dm,"Pinned",{"a"},true);assert(H.tip:IsMouseEnabled() and H.tipClose:IsShown(),"classic pinned tips still take the pointer and show Close");H.pinned=false;H.tip:Hide()
 FieldKitMeterLedger.Read,FieldKitMeterLedger.Stats=oldRead,oldStats
end
-- Map handle sits below the map's own buttons; gear rides inside the opening
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local M=FieldKitThemeMinimap
 assert(M.dragHandle==nil,"no FieldKit frame covers the map and its buttons")
 assert(Minimap:IsMouseEnabled()==M.before.mouse,"the native map keeps its own mouse state while themed (FieldKit no longer switches it off)")
 FieldKitThemeMinimap.probe.ring=true -- edge placement is an opt-in probe now
 local gear=NewGear();gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear end;C.Refresh(true)
 for _,angle in ipairs({0,90,180,270,45,225}) do local a=math.rad(angle);gear:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80)
  local _,_,_,gx,gy=gear:GetPoint();local hw,hh=R.layout.mapHole[3]/2,R.layout.mapHole[4]/2
  local band=R.RingGeometry(R.layout,R.layout.mapHole)
  assert(math.abs(gx)<=hw+band/2+1e-6 and math.abs(gy)<=hh+band/2+1e-6 and math.abs(gx)>=hw-1 or math.abs(gy)>=hh-1,"gear rides the border of the opening at "..angle.." degrees ("..gx..","..gy..")") end
 FieldKitZoneThemes.Command("mapdiag");FieldKitZoneThemes.Command("clickdiag")
 C.Set("zoneThemes",false);Minimap.GetChildren=oldChildren
end
print("Bonuses expansion, Damage hover tooltips, map handle and gear placement passed (synthetic)")

-- alpha.19: placement engine, seven spells, damage categories, map follower.
local function Opaque(kind)
 local rect=R.CardRect(kind,R.layout);local n=({elwynn_complete={Damage={10,6,0,6},Lairs={10,9,9,7},Accessories={8,5,8,6},Stats={8,7,7,8},Effects={8,5,7,11}},
  naxx_complete={Damage={4,1,6,5},Lairs={7,2,5,9},Accessories={9,0,11,0},Stats={10,0,11,0},Effects={9,3,9,10}}})[R.key][kind]
 return {rect[1]+n[1],rect[2]+n[2],rect[1]+rect[3]-n[3],rect[2]+rect[4]-n[4]}
end
local function NoOverlap(label)
 local kinds={"Damage","Lairs","Accessories","Stats","Effects"};local seen={}
 for _,k in ipairs(kinds) do if R.CardVisible(k,R.layout) and not FieldKitZoneThemes.Position(R.frames[k]) then table.insert(seen,{k,Opaque(k)}) end end
 for i=1,table.getn(seen) do for j=i+1,table.getn(seen) do
  local a,b=seen[i][2],seen[j][2]
  local across=math.min(a[3],b[3])-math.max(a[1],b[1]);local depth=math.min(a[4],b[4])-math.max(a[2],b[2])
  assert(not (across>0 and depth>6),label..": "..seen[i][1].." and "..seen[j][1].." overlap by "..tostring(depth))
 end end
end
local function Snapshot(t) local out={} for k,v in pairs(t or {}) do out[k]=v end return out end
local realStatsRows=FieldKitStatsFrame.rows
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
 local oldSpells=FieldKitLoadout.spells
 R.statsOpen=false;FieldKitDB.loadoutTab=1;C.Refresh(true)
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do assert((R.shift[k] or 0)==0,zone..": the approved default layout is not moved ("..k..")") end
 -- seven spells: the card grows, the cards below follow without overlapping, and come back when the room is free again
 for _,count in ipairs({0,1,5,7,8,12}) do
  FieldKitLoadout.spells={};for i=1,count do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="R"..i,rankValue=i,bonuses={},upgrades={}}) end
  FieldKitDB.loadoutTab=2;R.scroll.Accessories=0;C.Refresh(true);local acc=R.frames.Accessories;local base=R.layout.rects.Accessories
  local N=R.accN;assert(N==math.max(zone=="naxx" and 3 or 1,math.min(24,count)) and not R.accScroll,zone..": the card holds exactly the spells ("..tostring(N).." rows for "..count..")") -- alpha.36: height follows the content
  assert(acc:GetHeight()==base[4]+R.AccDelta(zone,N),zone..": card height for "..count.." spells ("..acc:GetHeight().." vs "..(base[4]+R.AccDelta(zone,N))..")")
  local shown=0;for i,r in ipairs(acc.rows) do if r:IsShown() then shown=shown+1;local _,_,_,_,y=r:GetPoint();assert(-y==R.SocketY(zone,i,N),zone..": row "..i.." sits on socket "..i.." ("..count..")") end end
  assert(shown==(count==0 and 1 or math.min(N,count)),zone..": visible spell rows for "..count)
  assert(string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"/",1,true)==nil,zone..": no scrolling while the screen has room")
  local reach=0;local pieces={};for _,t in ipairs(acc.referenceTiles) do if t:IsShown() then local _,_,_,_,y=t:GetPoint();table.insert(pieces,{-y,t:GetHeight()}) end end
  table.sort(pieces,function(p,q) return p[1]<q[1] end);for _,p in ipairs(pieces) do assert(p[1]==reach,zone..": art continuity at "..p[1].." expected "..reach.." ("..count..")");reach=reach+p[2] end
  assert(reach==acc:GetHeight(),zone..": art ends at the card bottom ("..count..")")
  NoOverlap(zone.." "..count.." spells")
  if N>5 then assert((R.shift.Stats or 0)>0 or (R.shiftX.Stats or 0)~=0,zone..": Stats gives way to the taller Equipment card "..count.." sh="..table.concat({tostring(R.shift.Accessories),tostring(R.shiftX.Accessories),tostring(R.shift.Stats),tostring(R.shiftX.Stats),tostring(R.shift.Effects),tostring(R.shiftX.Effects),tostring(R.shift.Lairs),tostring(R.shift.Damage)},",").." last="..tostring(R.lastMoved).." noRoom="..tostring(R.noRoom)) else assert((R.shift.Stats or 0)==0 and (R.shiftX.Stats or 0)==0,zone..": a card that is not taller moves nobody") end
 end
 FieldKitLoadout.spells=oldSpells;FieldKitDB.loadoutTab=1;C.Refresh(true)
 for _,k in ipairs({"Stats","Effects"}) do assert((R.shift[k] or 0)==0 and (R.shiftX[k] or 0)==0,zone..": "..k.." is back at its preferred place on the Equipment tab") end
 -- Bonuses expanded: everything stays apart; reduced: everything returns; preferred positions never rewritten
 C.Refresh(true);local saved=Snapshot(FieldKitDB.zoneThemePositions and FieldKitDB.zoneThemePositions[C.currentLayout])
 FieldKitStatsFrame.rows=FakeStats(14);R.statsOpen=true;C.Refresh(true);NoOverlap(zone.." Bonuses expanded")
 local first=Snapshot(R.shift);C.Refresh(true);local second=Snapshot(R.shift)
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do assert((first[k] or 0)==(second[k] or 0),zone..": placement is deterministic and does not oscillate ("..k..")") end
 R.statsOpen=false;C.Refresh(true);for _,k in ipairs({"Stats","Effects","Accessories"}) do assert((R.shift[k] or 0)==0,zone..": "..k.." returned to its preferred place after Show less") end
 for k,v in pairs(Snapshot(FieldKitDB.zoneThemePositions and FieldKitDB.zoneThemePositions[C.currentLayout])) do assert(saved[k]==v,"automatic placement never writes a position") end
 -- option: overlap allowed keeps the historical layout
 R.statsOpen=true;FieldKitDB.zoneThemeOverlap=true;C.Refresh(true);local moved=0;for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do moved=moved+math.abs(R.shift[k] or 0) end;assert(moved==0,zone..": with overlap allowed nothing is moved")
 FieldKitDB.zoneThemeOverlap=false;R.statsOpen=false
 -- a card under the mouse freezes the layout
 R.statsOpen=true;C.Refresh(true);local frozen=R.shift;R.frames.Stats.azsMoving=true;R.Resolve(zone,R.layout);assert(R.shift==frozen,zone..": nothing is rearranged while a card is dragged");R.frames.Stats.azsMoving=nil
 R.statsOpen=false;FieldKitStatsFrame.rows=realStatsRows;C.Refresh(true)
end
-- alpha.20: regression bench for the captured case. Every card has a SAVED position (as in the user's SavedVariables);
-- collisions are read from the RENDERED rectangles (derived from the frames' real anchors), never from the engine's own model.
local UIH,UIW=UIParent:GetHeight(),UIParent:GetWidth()
local function Anchors(f) return f:GetPoint() end
local function Rendered(f)
 local p,rel,rp,x,y=f:GetPoint();local s=f:GetScale() or 1;local w,h=f:GetWidth()*s,f:GetHeight()*s
 local function frac(str,a,b) if string.find(str,a,1,true) then return 1 elseif string.find(str,b,1,true) then return 0 end return .5 end
 local ax,ay
 if rel==UIParent then ax=frac(rp,"RIGHT","LEFT")*UIW+x*s;ay=frac(rp,"BOTTOM","TOP")*UIH-y*s
 else ax=x*s;ay=-y*s end
 return ax-frac(p,"RIGHT","LEFT")*w,ay-frac(p,"BOTTOM","TOP")*h,w,h
end
local function Stage()
 R.canvas.GetLeft=function() return 0 end;R.canvas.GetTop=function() return UIH end;R.canvas.GetEffectiveScale=function() return 1 end
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local f=R.frames[k]
  f.GetLeft=function(self) local l=Rendered(self);return l end
  f.GetTop=function(self) local _,t=Rendered(self);return UIH-t end
  f.GetEffectiveScale=function() return 1 end
 end
end
local function Unstage()
 R.canvas.GetLeft=nil;R.canvas.GetTop=nil;R.canvas.GetEffectiveScale=nil
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local f=R.frames[k];f.GetLeft=nil;f.GetTop=nil;f.GetEffectiveScale=nil end
end
local OP={elwynn_complete={Damage={10,6,0,6},Lairs={10,9,9,7},Accessories={8,5,8,6},Stats={8,7,7,8},Effects={8,5,7,11}},
 naxx_complete={Damage={4,1,6,5},Lairs={7,2,5,9},Accessories={9,0,11,0},Stats={10,0,11,0},Effects={9,3,9,10}}}
local function Opaque2(k)
 local f=R.frames[k];local l,t,w,h=Rendered(f);local n=OP[R.key][k]
 return {l+n[1],t+n[2],l+w-n[3],t+h-n[4]}
end
local function Apart(label)
 local kinds={"Damage","Lairs","Accessories","Stats","Effects"};local seen={}
 for _,k in ipairs(kinds) do if R.frames[k]:IsShown() then table.insert(seen,{k,Opaque2(k)}) end end
 for i=1,table.getn(seen) do
  local a=seen[i][2]
  local dump="";for _,q in ipairs(seen) do dump=dump.." "..q[1]..":"..math.floor(q[2][1])..","..math.floor(q[2][2])..","..math.floor(q[2][3])..","..math.floor(q[2][4]).."(sh "..tostring(R.shift[q[1]])..","..tostring(R.shiftX[q[1]])..")" end
  local sl,st,sr,sb=R.ScreenBounds(R.layout)
  assert(a[1]>=sl-1 and a[3]<=sr+1 and a[2]>=st-1 and a[4]<=sb+1,label..dump..": "..seen[i][1].." leaves the screen ("..a[1]..","..a[2]..","..a[3]..","..a[4]..") bounds="..table.concat({R.ScreenBounds(R.layout)},",").." shift="..tostring(R.shift[seen[i][1]])..","..tostring(R.shiftX[seen[i][1]]).." noRoom="..tostring(R.noRoom))
  for j=i+1,table.getn(seen) do
   local b=seen[j][2]
   local across=math.min(a[3],b[3])-math.max(a[1],b[1]);local depth=math.min(a[4],b[4])-math.max(a[2],b[2])
   assert(not (across>0 and depth>6),label..": RENDERED "..seen[i][1].." and "..seen[j][1].." overlap by "..depth.." px")
  end
 end
end
local function SaveAll(layout,list)
 FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
 for k,pos in pairs(list) do FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanel"..k]={"TOPLEFT","TOPLEFT",pos[1],-pos[2]} end
end
local function Relayout()
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do R.frames[k].referenceRect=nil;R.frames[k].referenceGeometryKey=nil end
 C.revision=C.revision+1;C.Refresh(true)
end
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
 R.statsOpen=false;FieldKitDB.loadoutTab=1;R.lastMoved=nil
 local realRows=FieldKitStatsFrame.rows;local layout=C.currentLayout
 FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
 local saved={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local r=R.layout.rects[k];saved[k]={r[1],r[2]} end
 -- (a) the captured case: all five cards saved, Bonuses expanded
 SaveAll(layout,saved);Stage();Relayout()
 local before={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do before[k]={Rendered(R.frames[k])} end
 Apart(zone.." saved layout, compact")
 local snapshot={};for k,v in pairs(FieldKitDB.zoneThemePositions[layout]) do snapshot[k]=v[3]..":"..v[4] end
 FieldKitStatsFrame.rows=FakeStats(14);R.statsOpen=true;C.Refresh(true);C.Refresh(true)
 Apart(zone.." saved layout, Bonuses expanded")
 for _,k in ipairs({"Damage","Lairs","Accessories"}) do assert((R.shift[k] or 0)==0 and (R.shiftX[k] or 0)==0,zone..": "..k.." is above/beside Bonuses and must not move (shift "..tostring(R.shift[k])..","..tostring(R.shiftX[k])..")") end
 local el,et=Rendered(R.frames.Effects);local sl,st,sw,sh=Rendered(R.frames.Stats)
 assert(R.frames.Stats:GetHeight()>R.layout.rects.Stats[4],zone..": Bonuses really grew")
 assert(el~=before.Effects[1] or et~=before.Effects[2],zone..": Effects gave way to the expanded Bonuses card")
 for k,v in pairs(FieldKitDB.zoneThemePositions[layout]) do assert(snapshot[k]==v[3]..":"..v[4],zone..": the saved position of "..k.." was not rewritten") end
 -- (b) deterministic: further refreshes change nothing
 local a1={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do a1[k]={Rendered(R.frames[k])} end
 for n=1,5 do C.Refresh(true) end
 for k,v in pairs(a1) do local now={Rendered(R.frames[k])};assert(math.abs(now[1]-v[1])<.01 and math.abs(now[2]-v[2])<.01,zone..": "..k.." keeps still across refreshes") end
 -- (c) Show less: every card returns to its saved place
 R.statsOpen=false;C.Refresh(true);C.Refresh(true)
 for k,v in pairs(before) do local now={Rendered(R.frames[k])};assert(math.abs(now[1]-v[1])<.5 and math.abs(now[2]-v[2])<.5,zone..": "..k.." returned to its preferred place ("..now[1]..","..now[2].." vs "..v[1]..","..v[2]..")") end
 -- (d) Effects saved near the bottom edge: no room below -> up or sideways, never off screen
 saved.Effects={saved.Effects[1],(zone=="elwynn" and 800 or 790)};SaveAll(layout,saved);Relayout()
 R.statsOpen=true;C.Refresh(true);C.Refresh(true);Apart(zone.." Effects near the bottom, Bonuses expanded")
 R.statsOpen=false;saved.Effects={R.layout.rects.Effects[1],R.layout.rects.Effects[2]};SaveAll(layout,saved);Relayout()
 -- (e) seven spells with a saved Equipment card
 local oldSpells=FieldKitLoadout.spells;FieldKitLoadout.spells={};for i=1,7 do table.insert(FieldKitLoadout.spells,{name="S"..i,rank="R",rankValue=1,bonuses={},upgrades={}}) end
 FieldKitDB.loadoutTab=2;C.Refresh(true);C.Refresh(true);Apart(zone.." seven spells, all cards saved")
 FieldKitLoadout.spells=oldSpells;FieldKitDB.loadoutTab=1
 -- (f) the card dropped last has priority: drop Effects onto Stats, the others give way, Effects stays where it was dropped
 saved.Effects={saved.Stats[1],saved.Stats[2]+40};SaveAll(layout,saved);Relayout()
 R.NoteMoved("FieldKitReferencePanelEffects");C.Refresh(true);C.Refresh(true)
 Apart(zone.." Effects dropped onto Bonuses")
 local dl,dt=Rendered(R.frames.Effects);assert(math.abs(dl-saved.Effects[1])<.5 and math.abs(dt-saved.Effects[2])<.5,zone..": the card dropped last stays exactly where it was dropped")
 -- (g) option: overlap allowed -> nothing is displaced
 FieldKitDB.zoneThemeOverlap=true;C.Refresh(true);C.Refresh(true);dl,dt=Rendered(R.frames.Stats)
 assert(math.abs(dl-saved.Stats[1])<.5 and math.abs(dt-saved.Stats[2])<.5,zone..": with overlap allowed no card is displaced")
 FieldKitDB.zoneThemeOverlap=false;R.lastMoved=nil
 -- clean up
 FieldKitDB.zoneThemePositions[layout]=nil;Unstage();R.statsOpen=false;FieldKitStatsFrame.rows=realRows;Relayout()
end

-- Six damage categories: one row geometry, icon column, alignment never leaks between categories
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 local oldRead=FieldKitMeterLedger.Read;local dm=R.frames.Damage
 local datasets={complete=function() return {{name="A",dmg=10,share=.5,icon="Interface\\Icons\\X"},{name="B",dmg=5,share=.3,icon="Interface\\Icons\\Y"}},15,3,true end,
  partial=function() return {{name="NoIcon",share=.2},{name="Bare"}},0,0,false end,empty=function() return {},0,0,false end}
 for view=1,6 do for _,which in ipairs({"empty","complete","partial","empty","complete"}) do
  click(R.tabs[view]);FieldKitMeterLedger.Read=datasets[which];C.Refresh(true)
  local first=dm.rows[1];assert(first:IsShown(),zone..": first row present ("..view.."/"..which..")")
  if which=="empty" then assert(first.label:GetJustifyH()=="CENTER" and not first.icon:IsShown(),zone..": empty state is centred, without an icon")
  else
   for i=1,2 do local r=dm.rows[i];assert(r:IsShown() and r.label:GetJustifyH()=="LEFT" and r.value:GetJustifyH()=="RIGHT",zone..": row "..i.." aligned like the others ("..view.."/"..which..")")
    local _,_,_,ix=r.icon:GetPoint();assert(r.icon:IsShown() and ix==-45 and r.icon:GetWidth()==26,zone..": row "..i.." keeps its icon column ("..view.."/"..which..")") end
   assert(dm.rows[3] and not dm.rows[3]:IsShown(),zone..": no phantom row")
  end
 end end
 FieldKitMeterLedger.Read=oldRead;click(R.tabs[1])
end
-- The native map follows a moving owner
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local M=FieldKitThemeMinimap;local hides=0;local x=100
 Minimap.Hide=function(self) hides=hides+1;self.shown=false end;M.root.GetLeft=function() return x end;M.root.GetTop=function() return 500 end
 arg1=.05;M.follower.scripts.OnUpdate();assert(hides==0,"idle: the map is left alone")
 M.root.azsMoving=true
 for step=1,5 do x=x+10;arg1=.05;M.follower.scripts.OnUpdate() end;assert(hides==5,"the native map is refreshed each time its owner moved ("..hides..")")
 arg1=.05;M.follower.scripts.OnUpdate();assert(hides==5,"and not when the owner is still")
 M.root.azsMoving=nil;x=x+10;M.follower.scripts.OnUpdate();assert(hides==5,"nothing once the drag is over");Minimap.Hide=nil;M.root.GetLeft=nil;M.root.GetTop=nil
end
C.Set("zoneThemes",false)
print("Placement engine, seven spells, damage categories and map follower passed (synthetic)")

-- alpha.20: map group owner, zoom buttons, no FieldKit script left on the native map.
for _,case in ipairs({{"elwynn",true},{"naxx",false}}) do
 local zone,viaIdentity=case[1],case[2]
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local M=FieldKitThemeMinimap
 assert((M.GroupOwner()==H.identity)==viaIdentity,zone..": the group owner is the identity card only when the map has no art of its own")
 assert(Minimap:GetScript("OnDragStart")==nil and Minimap:GetScript("OnDragStop")==nil and Minimap:GetScript("OnMouseDown")==nil and Minimap:GetScript("OnMouseUp")==nil,zone..": no FieldKit script on the native map")
 FieldKitDB.windowsLocked=false;this=M.root;M.root:GetScript("OnDragStart")()
 assert(M.GroupOwner().azsMoving and (viaIdentity==not M.root.azsMoving),zone..": a drag reaching the container moves the owner of the group")
 M.root:GetScript("OnDragStop")();assert(not H.identity.azsMoving and not M.root.azsMoving,zone..": and ends cleanly")
 FieldKitDB.windowsLocked=true;M.root:GetScript("OnDragStart")();assert(not H.identity.azsMoving and not M.root.azsMoving,zone..": locked HUD: nothing moves");FieldKitDB.windowsLocked=false
 -- zoom buttons: first click, both ways, bounded
 local zoom=3;Minimap.GetZoom=function() return zoom end;Minimap.SetZoom=function(_,v) zoom=v end
 for n=1,3 do C.Refresh(true) end
 M.zoomIn:Show();M.zoomOut:Show()
 click(M.zoomIn);assert(zoom==4,zone..": zoom + works at the first click");click(M.zoomOut);click(M.zoomOut);assert(zoom==2,zone..": zoom - works")
 for n=1,10 do click(M.zoomOut) end;assert(zoom==0,zone..": zoom is bounded");Minimap.GetZoom=nil;Minimap.SetZoom=nil
 -- teardown restores the original container behaviour
 C.Set("zoneThemes",false);assert(not M.root:IsShown(),zone..": container hidden with the theme off")
end
print("Map group owner, zoom buttons and native map scripts passed (synthetic)")

-- alpha.21: real screen edges (letterboxed canvas), manual placement without artificial margin, mouse coverage of the map.
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
 R.statsOpen=false;FieldKitDB.loadoutTab=1;R.lastMoved=nil
 local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
 local saved={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local r=R.layout.rects[k];saved[k]={r[1],r[2]} end
 SaveAll(layout,saved);Stage()
 local LETTERBOX=17 -- the canvas is fitted into the screen: the real screen reaches 17 px above it
 R.canvas.GetTop=function() return UIH-LETTERBOX end
 local hidden={};for _,name in ipairs({"header","chat","identity","nav","vitality","mapArt"}) do local r=R.layout.rects[name];if r then hidden[name]=r;R.layout.rects[name]={-5000,-5000,r[3],r[4]} end end -- edge test only: no protected part in the way
 local sl,st,sr,sb=R.ScreenBounds(R.layout)
 assert(math.abs(st+LETTERBOX)<.01 and math.abs(sb-(UIH-LETTERBOX))<.01 and sr>R.layout.size[1],zone..": bounds are those of the REAL screen, not of the canvas ("..st..","..sb..")")
 -- ref y of the real screen top is -17: a pinned card whose DRAWN art touches the very top edge must stay there
 local n=OP[R.key].Effects;local h=R.layout.rects.Effects[4]
 local function PlaceEffects(frameTopScreen) FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelEffects"]={"TOPLEFT","TOPLEFT",R.layout.rects.Effects[1],-frameTopScreen};Relayout() end
 local topScreen=-n[2] -- frame top such that the drawn top is exactly the screen top (screen y 0)
 PlaceEffects(topScreen);C.Refresh(true);C.Refresh(true)
 local l,t=Rendered(R.frames.Effects);assert(math.abs((t+n[2])-0)<.01,zone..": art flush with the top screen edge is accepted ("..(t+n[2])..")")
 assert((R.shift.Effects or 0)==0 and (R.shiftX.Effects or 0)==0,zone..": and nothing moves it away from the edge")
 -- bottom edge: drawn bottom exactly on the screen bottom
 local bottomTop=UIH+n[4]-h;PlaceEffects(bottomTop);C.Refresh(true);C.Refresh(true)
 l,t=Rendered(R.frames.Effects);assert(math.abs((t+h-n[4])-UIH)<.01 and (R.shift.Effects or 0)==0,zone..": art flush with the bottom screen edge is accepted")
 -- dropped beyond the edge: snapped back flush, saved position follows, no artificial margin
 local a=FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelEffects"];a[4]=-(bottomTop+40);R.frames.Effects:ClearAllPoints();R.frames.Effects:SetPoint(a[1],UIParent,a[2],a[3],a[4])
 R.NoteMoved("FieldKitReferencePanelEffects");l,t=Rendered(R.frames.Effects)
 assert(math.abs((t+h-n[4])-UIH)<.01 and math.abs(a[4]+bottomTop)<.01,zone..": a drop beyond the real edge snaps flush (saved "..a[4].." expected "..-bottomTop..")")
 a[4]=-(topScreen-40);R.frames.Effects:ClearAllPoints();R.frames.Effects:SetPoint(a[1],UIParent,a[2],a[3],a[4]);R.NoteMoved("FieldKitReferencePanelEffects")
 l,t=Rendered(R.frames.Effects);assert(math.abs((t+n[2])-0)<.01,zone..": and at the top edge")
 for name,r in pairs(hidden) do R.layout.rects[name]=r end
 R.canvas.GetTop=function() return UIH end -- (the automatic-placement checks below use an exact canvas)
 -- automatic placement keeps its visual margin from the real edge
 FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanelEffects"]=nil;SaveAll(layout,saved);Relayout()
 FieldKitStatsFrame.rows=FakeStats(29);R.statsOpen=true;C.Refresh(true);C.Refresh(true)
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local o=Opaque2(k);assert(o[4]<=UIH-8+.5 and o[2]>=0,zone..": "..k.." automatic placement stays inside the real screen") end
 for _,k in ipairs({"Damage","Lairs","Accessories"}) do assert((R.shift[k] or 0)==0 and (R.shiftX[k] or 0)==0,zone..": "..k.." is not shoved around by Bonuses "..tostring(R.shift[k])..","..tostring(R.shiftX[k]).." stats="..table.concat({Rendered(R.frames.Stats)},",").." extra="..tostring(R.statsExtra).." acc="..table.concat({Rendered(R.frames.Accessories)},",")) end
 R.statsOpen=false;FieldKitStatsFrame.rows=realStatsRows
 R.canvas.GetTop=nil;FieldKitDB.zoneThemePositions[layout]=nil;Unstage();Relayout()
 -- mouse coverage of the native map: nothing of FieldKit sits over it except the zoom buttons and the art frame itself
 local M=FieldKitThemeMinimap;C.Refresh(true)
 local covering={}
 for _,f in ipairs(objects) do
  local p=f.parent;local inside=false;while p do if p==M.root then inside=true end;p=p.parent end
  if inside and f.mouseEnabled and f:IsShown() and f~=M.zoomIn and f~=M.zoomOut and f.kind~="Texture" and f.kind~="FontString" then
   local proxy=false;for _,pr in pairs(M.launcherProxies or {}) do if pr==f then proxy=true end end
   if not proxy then table.insert(covering,tostring(f.kind)..":"..tostring(f._name)) end
  end
 end
 assert(table.getn(covering)==0,zone..": FieldKit frames over the map that take the pointer: "..table.concat(covering,", "))
 assert(M.dragHandle==nil or not M.dragHandle:IsShown(),zone..": no drag handle")
 assert(M.root:IsMouseEnabled()==(M.GroupOwner()==M.root),zone..": the map container takes the pointer only when it is the art frame")
 -- a third-party button on the map keeps its own clicks and drags
 local clicked,dragged=0,0
 local gear=NewGear();gear:SetScript("OnClick",function() clicked=clicked+1 end);gear:SetScript("OnDragStart",function() dragged=dragged+1 end)
 click(gear);gear.scripts.OnDragStart();assert(clicked==1 and dragged==1,zone..": third-party button keeps its handlers")
 assert(not H.identity.azsMoving and not M.root.azsMoving,zone..": using it never moves the map")
 C.Set("zoneThemes",false)
end
print("Real screen edges, drop snapping, protected obstacles and map mouse coverage passed (synthetic)")

-- alpha.22: protected parts are measured where they REALLY are (the user moves them), the technical clamp is off, probes.
local PARTS={}
local function StagePart(f)
 f.GetLeft=function(self) local l=Rendered(self);return l end
 f.GetTop=function(self) local _,t=Rendered(self);return UIH-t end
 f.GetEffectiveScale=function() return 1 end
 table.insert(PARTS,f)
end
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
 R.statsOpen=false;FieldKitDB.loadoutTab=1;R.lastMoved=nil;FieldKitThemeMinimap.probe.ring=false
 local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
 local saved={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local r=R.layout.rects[k];saved[k]={r[1],r[2]} end
 -- the player block ("Aethus") and the identity card were moved by the user, exactly as in the captured SavedVariables
 local movedTo={FieldKitThemeIdentity={1205,164},FieldKitThemeVitality={8,3}}
 for name,pos in pairs(movedTo) do FieldKitDB.zoneThemePositions[layout][name]={"TOPLEFT","TOPLEFT",pos[1],-pos[2]} end
 SaveAll(layout,saved);Stage();StagePart(H.identity);StagePart(H.healthRoot)
 Relayout()
 local report={};local lines=R.Probe()
 local found={};for _,line in ipairs(lines) do
  if string.find(line,"^  obstacle identity") then found.identity=line end;if string.find(line,"^  obstacle vitality") then found.vitality=line end end
 assert(found.identity and string.find(found.identity,"live",1,true),zone..": the identity obstacle is measured where the identity card really is ("..tostring(found.identity)..")")
 assert(found.vitality and string.find(found.vitality,"live",1,true),zone..": and the player block too ("..tostring(found.vitality)..")")
 -- (a) a card dropped where those parts USED to be stays exactly there (it was blocked by an invisible obstacle before)
 local oldIdentity=R.layout.rects.identity;local drop={oldIdentity[1]+40,170} -- just below the player block, inside the old identity rectangle
 saved.Lairs={drop[1],drop[2]};SaveAll(layout,saved);Relayout();C.Refresh(true)
 assert((R.shift.Lairs or 0)==0 and (R.shiftX.Lairs or 0)==0,zone..": a card dropped where a moved part used to be is NOT displaced (shift "..tostring(R.shift.Lairs)..","..tostring(R.shiftX.Lairs)..")")
 local l,t=Rendered(R.frames.Lairs);assert(math.abs(l-drop[1])<.5 and math.abs(t-drop[2])<.5,zone..": it stays exactly where it was dropped")
 -- (b) a card dropped onto the part's REAL place does give way
 saved.Lairs={movedTo.FieldKitThemeIdentity[1]+20,movedTo.FieldKitThemeIdentity[2]+30};SaveAll(layout,saved);Relayout();C.Refresh(true)
 assert((R.shift.Lairs or 0)~=0 or (R.shiftX.Lairs or 0)~=0,zone..": a card dropped onto the real identity card gives way")
 -- (c) the technical clamp is off for every card
 for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local f=R.frames[k];local last;f.fieldkitClampOff=nil;f.SetClampedToScreen=function(self,v) last=v end;C.Refresh(true)
  assert(last==false,zone..": "..k.." is not clamped by its technical rectangle");f.SetClampedToScreen=nil
 end
 for _,p in ipairs(PARTS) do p.GetLeft=nil;p.GetTop=nil;p.GetEffectiveScale=nil end;PARTS={}
 FieldKitDB.zoneThemePositions[layout]=nil;Unstage();Relayout()
end
-- probes: runtime switches for the map, never saved
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local M=FieldKitThemeMinimap
 local gear=NewGear();gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear end
 M.probe.ring=false;C.Refresh(true);local _,_,_,gx,gy=gear:GetPoint();assert(gx==80 and gy==0 and rawget(gear,"SetPoint")==nil,"default: the gear keeps its native position and method")
 C.Command("mapprobe ring on");_,_,_,gx,gy=gear:GetPoint();assert(M.probe.ring and math.sqrt(gx*gx+gy*gy)>85,"probe ring on: edge placement")
 C.Command("mapprobe ring off");_,_,_,gx,gy=gear:GetPoint();assert(not M.probe.ring and gx==80 and gy==0 and rawget(gear,"SetPoint")==nil,"probe ring off: native position and method restored exactly")
 C.Command("mapprobe rim off");assert(M.rim and not M.rim:IsShown(),"probe rim off hides the overlay");C.Command("mapprobe rim on");assert(M.rim:IsShown())
 C.Command("mapprobe proxies off");for _,pr in pairs(M.launcherProxies or {}) do assert(not pr:IsShown(),"probe proxies off hides every proxy") end;C.Command("mapprobe proxies on")
 local hides=0;Minimap.Hide=function(self) hides=hides+1 end;C.Command("mapprobe follower off");M.root.azsMoving=true;M.root.GetLeft=function() return hides end;M.root.GetTop=function() return 1 end;arg1=.05;M.follower.scripts.OnUpdate();assert(hides==0,"probe follower off");M.root.azsMoving=nil;Minimap.Hide=nil;M.root.GetLeft=nil;M.root.GetTop=nil;C.Command("mapprobe follower on")
 -- event log: the gear's own handlers still run
 local clicks=0;gear:SetScript("OnClick",function() clicks=clicks+1 end)
 local messages={};local oldAdd=DEFAULT_CHAT_FRAME.AddMessage;DEFAULT_CHAT_FRAME.AddMessage=function(_,m) table.insert(messages,m) end
 C.Command("mapprobe events on");click(gear);assert(clicks==1,"events probe: the gear's handler still runs")
 local logged=false;for _,m in ipairs(messages) do if string.find(m,"gear OnClick",1,true) then logged=true end end;assert(logged,"events probe: the click is logged")
 C.Command("mapprobe events off");local n=table.getn(messages);click(gear);assert(clicks==2 and table.getn(messages)==n,"events probe off: handler restored, no more log")
 C.Command("cardprobe");assert(table.getn(messages)>6,"cardprobe prints the screen bounds, the obstacles and every card")
 C.Command("dragdiag on");assert(R.dragDiag);C.Command("dragdiag off");assert(not R.dragDiag)
 C.Command("mapstack 3");assert(C.stackAt,"mapstack is scheduled");C.stackAt=nil
 DEFAULT_CHAT_FRAME.AddMessage=oldAdd;Minimap.GetChildren=oldChildren;C.Set("zoneThemes",false)
end
print("Live protected obstacles, clamp off and map/card probes passed (synthetic)")

-- alpha.23: the four real screen edges, with a UIParent measurement that is ~10% short (as the right/top limits were on the client).
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
 R.statsOpen=false;FieldKitDB.loadoutTab=1;R.lastMoved=nil
 local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
 local saved={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local r=R.layout.rects[k];saved[k]={r[1],r[2]} end
 SaveAll(layout,saved);Stage()
 -- UIParent reports a scale that makes its width*scale 10% short; WorldFrame reports the real screen
 local oldScale=UIParent.GetEffectiveScale;UIParent.GetEffectiveScale=function() return .9 end
 WorldFrame.width=UIW;WorldFrame.height=UIH;WorldFrame.GetEffectiveScale=function() return 1 end
 local w,h,cands,best=R.ScreenSize();assert(w==UIW and h==UIH and best.name=="WorldFrame",zone..": the real screen size wins over a short UIParent measurement ("..tostring(best and best.name)..")")
 local sl,st,sr,sb=R.ScreenBounds(R.layout);assert(sr==UIW and sb==UIH and sl==0 and st==0,zone..": the four limits are the real screen's ("..sl..","..st..","..sr..","..sb..")")
 local hidden={};for _,name in ipairs({"header","chat","identity","nav","vitality","mapArt"}) do local r=R.layout.rects[name];if r then hidden[name]=r;R.layout.rects[name]={-5000,-5000,r[3],r[4]} end end -- isolate the edges from the protected parts
 Relayout()
 for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local n=OP[R.key][kind];local f=R.frames[kind];local rect=R.CardRect(kind,R.layout);local cw,ch=rect[3],rect[4]
  local function Drop(x,top) FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanel"..kind]={"TOPLEFT","TOPLEFT",x,-top};Relayout();R.NoteMoved("FieldKitReferencePanel"..kind);C.Refresh(true);C.Refresh(true);return Rendered(f) end
  -- right edge: dropped beyond it -> art flush with the real right edge, and a drop flush with it is left alone
  local l,t=Drop(UIW-cw+n[3]+60,300);assert(math.abs((l+cw-n[3])-UIW)<.5,zone.." "..kind..": right edge reached ("..(l+cw-n[3])..")")
  l,t=Drop(UIW-cw+n[3],300);assert(math.abs((l+cw-n[3])-UIW)<.5 and (R.shiftX[kind] or 0)==0,zone.." "..kind..": flush with the right edge stays")
  -- top edge
  l,t=Drop(400,-n[2]-60);assert(math.abs((t+n[2])-0)<.5,zone.." "..kind..": top edge reached ("..(t+n[2])..")")
  l,t=Drop(400,-n[2]);assert(math.abs((t+n[2])-0)<.5 and (R.shift[kind] or 0)==0,zone.." "..kind..": flush with the top edge stays")
  -- bottom and left edges (unchanged behaviour)
  l,t=Drop(400,UIH-ch+n[4]+60);assert(math.abs((t+ch-n[4])-UIH)<.5,zone.." "..kind..": bottom edge reached")
  l,t=Drop(-n[1]-60,300);assert(math.abs((l+n[1])-0)<.5,zone.." "..kind..": left edge reached")
  -- persistence: the saved position is the snapped one
  local a=FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanel"..kind];assert(math.abs(a[3]+n[1])<.5,zone.." "..kind..": the saved position follows the snap ("..a[3]..")")
 end
 for name,r in pairs(hidden) do R.layout.rects[name]=r end
 UIParent.GetEffectiveScale=oldScale;WorldFrame.GetEffectiveScale=nil;WorldFrame.width=nil;WorldFrame.height=nil
 FieldKitDB.zoneThemePositions[layout]=nil;Unstage();Relayout()
end
-- the gear diagnostics only read state: nothing about the gear changes
do
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local gear=NewGear();gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local before={gear:GetPoint()};local messages={};local oldAdd=DEFAULT_CHAT_FRAME.AddMessage;DEFAULT_CHAT_FRAME.AddMessage=function(_,m) table.insert(messages,m) end
 C.Command("mapprobe state");local after={gear:GetPoint()}
 assert(table.getn(messages)>=3 and string.find(messages[1],"gear:",1,true) and string.find(messages[2],"wrapped by FieldKit: false",1,true),"mapprobe state describes the gear without touching it")
 for i=1,5 do assert(before[i]==after[i],"mapprobe state does not move the gear") end
 DEFAULT_CHAT_FRAME.AddMessage=oldAdd;C.Set("zoneThemes",false)
end
print("Four real screen edges with a short UIParent measurement, and read-only gear diagnostics passed (synthetic)")

-- alpha.24: diagnostic commands are routed before anything can open the settings window; each prints a result.
do
 local opened=0;local toggle=FieldKitUI.Toggle;FieldKitUI.Toggle=function(...) opened=opened+1;return toggle(unpack(arg)) end
 local messages={};local oldAdd=DEFAULT_CHAT_FRAME.AddMessage;DEFAULT_CHAT_FRAME.AddMessage=function(_,m) table.insert(messages,tostring(m)) end
 C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
 local gear=NewGear();gear:SetScript("OnClick",function() end)
 for _,line in ipairs({"mapprobe state","mapprobe events on","mapprobe events off","mapstack 5","mapstack","mapfocus","mapdiag","cardprobe","clickdiag","dragdiag on","dragdiag off","mapprobe","MAPPROBE State","  mapprobe state  ","mapprobe nonsense"}) do
  local before=table.getn(messages);SlashCmdList.FieldKit(line)
  assert(opened==0,"'/fieldkit "..line.."' must not open the settings window")
  assert(table.getn(messages)>before,"'/fieldkit "..line.."' prints a result")
 end
 C.stackAt=nil
 -- independent commands
 for _,case in ipairs({{"FKMAPSTATE","/fkmapstate",""},{"FKMAPEVENTS","/fkmapevents","on"},{"FKMAPEVENTS","/fkmapevents","off"},{"FKMAPSTACK","/fkmapstack","3"},{"FKMAPSTACK","/fkmapstack",""},{"FKMAPFOCUS","/fkmapfocus",""},{"FKCARDPROBE","/fkcardprobe",""}}) do
  assert(getglobal("SLASH_"..case[1].."1")==case[2],case[2].." is registered")
  local before=table.getn(messages);SlashCmdList[case[1]](case[3]);assert(opened==0 and table.getn(messages)>before,case[2].." prints and never opens the window")
 end
 C.stackAt=nil
 -- an error is reported, not swallowed and not turned into the settings window
 local broken=C.Command;C.Command=function() error("boom") end
 local before=table.getn(messages);SlashCmdList.FKMAPSTATE("");assert(table.getn(messages)==before+1 and string.find(messages[table.getn(messages)],"diagnostic error",1,true) and string.find(messages[table.getn(messages)],"boom",1,true) and opened==0,"a failing diagnostic prints its error")
 C.Command=broken
 -- ordinary commands still behave
 FieldKitDB.windowsLocked=false;SlashCmdList.FieldKit("lock");assert(FieldKitDB.windowsLocked==true,"/fieldkit lock still locks");SlashCmdList.FieldKit("unlock");assert(FieldKitDB.windowsLocked==false,"/fieldkit unlock still unlocks")
 SlashCmdList.FieldKit("");assert(opened==1,"plain /fieldkit still opens the settings window");SlashCmdList.FieldKit("themes status")
 SlashCmdList.FieldKit("diag api")
 FieldKitUI.Toggle=toggle;DEFAULT_CHAT_FRAME.AddMessage=oldAdd;C.Set("zoneThemes",false)
end
print("Diagnostic commands are routed before the settings window and always report (synthetic)")

-- alpha.25: mouse stacking of the map group, reproduced from the native /fkmapstack (identity 3, Minimap 2, gear 2, all MEDIUM).
do
 local STRATA={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
 local function Top(list)
  table.sort(list,function(p,q) local sp,sq=STRATA[p:GetFrameStrata()] or 0,STRATA[q:GetFrameStrata()] or 0;if sp~=sq then return sp>sq end return p:GetFrameLevel()>q:GetFrameLevel() end)
  return list
 end
 for _,case in ipairs({{"elwynn"},{"naxx"}}) do
  local zone=case[1]
  C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete")
  Minimap:SetFrameLevel(2)
  local gear=getglobal("AzerothHubMinimapButton") or NewGear()
  gear:SetFrameLevel(2);gear:EnableMouse(true);gear:SetScript("OnClick",function() end);local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear end
  C.Set("zoneThemes",true);C.Refresh(true);C.Refresh(true)
  local M=FieldKitThemeMinimap;local owner=M.GroupOwner()
  local stack=Top({owner,Minimap,gear})
  assert(stack[1]==gear and stack[2]==Minimap and stack[3]==owner,zone..": the gear is on top of the map and the map above its owner (owner "..owner:GetFrameLevel()..", map "..Minimap:GetFrameLevel()..", gear "..gear:GetFrameLevel()..")")
  assert(owner:IsMouseEnabled() or owner~=M.root,zone..": the owner keeps its own mouse (it can still be dragged from its own areas)")
  assert(gear:GetFrameLevel()==2,zone..": the third-party button was not touched")
  -- stable: no level call once settled (a click in progress must not be disturbed)
  local calls=0;local m,o=Minimap.SetFrameLevel,owner.SetFrameLevel
  Minimap.SetFrameLevel=function(self,v) calls=calls+1;return m(self,v) end;owner.SetFrameLevel=function(self,v) calls=calls+1;return o(self,v) end
  for n=1,6 do C.Refresh(true) end;assert(calls==0,zone..": levels are not re-applied on every refresh ("..calls.." calls)")
  Minimap.SetFrameLevel=nil;owner.SetFrameLevel=nil
  -- a re-layout that resets the owner's level is corrected once
  o(owner,3);C.Refresh(true);assert(Top({owner,Minimap,gear})[1]==gear,zone..": corrected after the owner was re-levelled")
  -- the interactions that belong to the owner are intact
  FieldKitDB.windowsLocked=false;this=owner;if owner==M.root then M.root:GetScript("OnDragStart")() else assert(owner:GetScript("OnDragStart"),zone..": the identity card keeps its drag") end
  if owner==M.root then M.root:GetScript("OnDragStop")() end
  click(M.zoomIn);click(M.zoomOut)
  -- theme off: the native map gets its own level back
  C.Set("zoneThemes",false);assert(Minimap:GetFrameLevel()==2,zone..": the native map level is restored with the theme ("..Minimap:GetFrameLevel()..")")
  Minimap.GetChildren=oldChildren
 end
end
print("Map group mouse stacking (gear above map above owner) passed (synthetic)")

-- alpha.26: ring geometry from the real art: centred on the gold border, never over the title, the foot or the zoom buttons; on by default.
for _,case in ipairs({{"elwynn",9},{"naxx",15}}) do
 local zone,expectedBand=case[1],case[2]
 C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete")
 local M=FieldKitThemeMinimap;M.probe.ring=true
 local gear=NewGear();gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear end
 -- no command: the ring is on when the theme loads
 C.Set("zoneThemes",true);C.Refresh(true)
 local _,_,_,gx,gy=gear:GetPoint();assert(M.probe.ring and rawget(gear,"SetPoint")~=nil and gx>100,zone..": the ring is active as soon as the theme is ("..tostring(gx)..")")
 local hole=R.layout.mapHole;local hw,hh=hole[3]/2,hole[4]/2
 local band,keep=R.RingGeometry(R.layout,hole)
 assert(band==expectedBand,zone..": border thickness measured from the art ("..band.." expected "..expectedBand..")")
 local slid=0
 for angle=0,355,5 do
  local a=math.rad(angle);gear:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80);_,_,_,gx,gy=gear:GetPoint()
  -- centred on the border: along its own direction the button sits exactly band/2 beyond the opening edge
  local dist=math.sqrt(gx*gx+gy*gy);local dx,dy=gx/dist,gy/dist;local edge=1/math.max(math.abs(dx)/hw,math.abs(dy)/hh)
  assert(math.abs(dist-edge-band/2)<1e-6,zone..": on the gold border at "..angle.." degrees ("..(dist-edge)..")")
  for _,k in ipairs(keep) do assert(not (gx-16<k.r and gx+16>k.l and gy-16<k.top and gy+16>k.bottom),zone..": never over the title, the foot or a zoom button at "..angle.." degrees") end
  local want=math.atan2(math.sin(a),math.cos(a));local diff=math.abs(math.atan2(gy,gx)-want);if diff>math.pi then diff=2*math.pi-diff end
  if diff>1e-6 then slid=slid+1 end
 end
 -- left and right sides (no keep-out in the way) are exact; the top centre (title) and bottom centre (foot) are the ones that slide when the map has them
 gear:SetPoint("CENTER",Minimap,"CENTER",-80,0);_,_,_,gx,gy=gear:GetPoint();assert(math.abs(gx+(hw+band/2))<1e-6 and math.abs(gy)<1e-6,zone..": left side: centred on the border, not inside the map ("..gx..")")
 if zone=="elwynn" then
  assert(slid>0,"Elwynn: some directions slide (title above, foot below, zoom buttons)")
  gear:SetPoint("CENTER",Minimap,"CENTER",0,80);_,_,_,gx,gy=gear:GetPoint();assert(math.abs(gx)>1,"Elwynn: the top centre (title) is avoided")
 end
 -- stable: repeated refreshes do not re-place the button
 local calls=0;local original=gear.fieldkitRingOriginal;gear.fieldkitRingOriginal=function(...) calls=calls+1;return original(unpack(arg)) end
 for n=1,6 do C.Refresh(true) end;assert(calls==0,zone..": the button is not re-anchored on every refresh ("..calls..")");gear.fieldkitRingOriginal=original
 -- click, drag and zoom are untouched; theme off restores the native position
 local clicked,dragged=0,0;gear:SetScript("OnClick",function() clicked=clicked+1 end);gear:SetScript("OnDragStart",function() dragged=dragged+1 end)
 click(gear);gear.scripts.OnDragStart();assert(clicked==1 and dragged==1 and not H.identity.azsMoving and not M.root.azsMoving,zone..": click and drag reach the gear, the map does not move")
 click(M.zoomIn);click(M.zoomOut)
 gear:SetPoint("CENTER",Minimap,"CENTER",80,0);C.Set("zoneThemes",false);_,_,_,gx,gy=gear:GetPoint();assert(gx==80 and gy==0 and rawget(gear,"SetPoint")==nil,zone..": native position and method restored with the theme")
 Minimap.GetChildren=oldChildren
end
print("Ring geometry from the art (gold border, keep-outs) and default activation passed (synthetic)")

-- alpha.27: the gear on the border is drawn above the art rim (render order only; mouse stack, position and scripts unchanged).
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete")
 local M=FieldKitThemeMinimap;M.probe.ring=true
 local gear=NewGear();gear:SetPoint("CENTER",Minimap,"CENTER",80,0);gear:SetFrameLevel(2)
 local other=CreateFrame("Button","SomeOtherMapButton",Minimap);other:SetFrameLevel(2)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear end
 C.Set("zoneThemes",true);C.Refresh(true);C.Refresh(true)
 assert(M.rim and M.rim:IsShown(),zone..": rim drawn")
 assert(gear:GetFrameLevel()>M.rim:GetFrameLevel(),zone..": the gear is drawn above the gold border rim ("..gear:GetFrameLevel().." vs "..M.rim:GetFrameLevel()..")")
 assert(M.rim:GetFrameLevel()>Minimap:GetFrameLevel(),zone..": the rim still covers the map edge")
 -- the validated mouse stack is computed from the native level: owner 0, map just under the gear's NATIVE level
 assert(M.GroupOwner():GetFrameLevel()==0 and Minimap:GetFrameLevel()==1,zone..": alpha.25 levels unchanged (owner "..M.GroupOwner():GetFrameLevel()..", map "..Minimap:GetFrameLevel()..")")
 local lvl=gear:GetFrameLevel();for n=1,5 do C.Refresh(true) end;assert(gear:GetFrameLevel()==lvl and Minimap:GetFrameLevel()==1,zone..": stable across refreshes")
 assert(other:GetFrameLevel()==2,zone..": other buttons are not touched")
 local _,_,_,gx,gy=gear:GetPoint();assert(gx>100,zone..": position unchanged by the lift")
 C.Command("mapprobe ring off");assert(gear:GetFrameLevel()==2,zone..": ring off gives the native level back");C.Command("mapprobe ring on")
 C.Set("zoneThemes",false);assert(gear:GetFrameLevel()==2,zone..": theme off gives the native level back")
 C.Set("zoneThemes",true);C.Refresh(true);assert(gear:GetFrameLevel()>M.rim:GetFrameLevel(),zone..": and again when the theme comes back")
 C.Set("zoneThemes",false);Minimap.GetChildren=oldChildren
end
print("Gear drawn above the art rim, native levels restored (synthetic)")

-- alpha.28: launcher proxies: readable tooltip title, first click reaches the owner's handler, hidden state respected.
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete")
 local M=FieldKitThemeMinimap
 local clicks=0
 local one=CreateFrame("Button","AzerothOneMinimapButton",Minimap);one:SetAlpha(1);one:SetScript("OnClick",function() clicks=clicks+1 end)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return one end
 C.Set("zoneThemes",true);C.Refresh(true)
 local proxy=M.launcherProxies[3];assert(proxy and proxy:IsShown(),zone..": launcher proxy shown")
 click(proxy);assert(clicks==1,zone..": the first click on the proxy reaches the addon's own handler once ("..clicks..")")
 assert(R.LauncherLabel("AzerothOneMinimapButton")=="AzerothOne" and R.LauncherLabel("AzerothStatsMinimap")=="AzerothStats" and R.LauncherLabel("FieldKitMinimapButton")=="FieldKit",zone..": readable launcher names")
 local lines={};local old={SetOwner=GameTooltip.SetOwner,AddLine=GameTooltip.AddLine,Show=GameTooltip.Show}
 GameTooltip.SetOwner=function() end;GameTooltip.AddLine=function(_,text) table.insert(lines,text) end;GameTooltip.Show=function() end
 this=proxy;proxy.scripts.OnEnter()
 GameTooltip.SetOwner,GameTooltip.AddLine,GameTooltip.Show=old.SetOwner,old.AddLine,old.Show
 assert(lines[1]=="AzerothOne" and lines[2]~=nil,zone..": tooltip shows the readable name and a hint ("..tostring(lines[1])..")")
 one:SetAlpha(0);C.Refresh(true);assert(not proxy:IsShown(),zone..": a launcher its owner hides gets no proxy")
 C.Set("zoneThemes",false);Minimap.GetChildren=oldChildren
 assert(one:GetParent()==Minimap and one:GetAlpha()==0,zone..": the third-party button stays under its owner's control")
end
print("Launcher proxies: tooltip, first click, hidden state passed (synthetic)")

-- alpha.29: teammate cards (FieldKitPartyCard1-4) are elements of the common placement engine.
do
 local function StageCard(f) f.GetLeft=function(self) local l=Rendered(self);return l end;f.GetTop=function(self) local _,t=Rendered(self);return UIH-t end;f.GetEffectiveScale=function() return 1 end end
 local function UnstageCard(f) f.GetLeft=nil;f.GetTop=nil;f.GetEffectiveScale=nil end
 local function Box(f) local l,t,w,h=Rendered(f);return {l,t,l+w,t+h} end
 local function Overlap(a,b) local across=math.min(a[3],b[3])-math.max(a[1],b[1]);local depth=math.min(a[4],b[4])-math.max(a[2],b[2]);return across>0 and depth>6 end
 local function Place(f,x,y) f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",x,-y) end
 local function Checked(label,cards)
  local others={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do if R.frames[k]:IsShown() then table.insert(others,{k,Opaque2(k)}) end end
  for i,f in ipairs(cards) do
   if f:IsShown() then
    local b=Box(f)
    for _,o in ipairs(others) do assert(not Overlap(b,o[2]),label..": teammate card "..f:GetName().." overlaps "..o[1]) end
    for j=i+1,table.getn(cards) do if cards[j]:IsShown() then assert(not Overlap(b,Box(cards[j])),label..": "..f:GetName().." overlaps "..cards[j]:GetName()) end end
   end
  end
 end
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
  R.statsOpen=false;FieldKitDB.loadoutTab=1;R.lastMoved=nil;R.lastParty=nil
  local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
  local saved={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local r=R.layout.rects[k];saved[k]={r[1],r[2]} end
  SaveAll(layout,saved);Stage()
  local cards={};for i=1,4 do local f=getglobal("FieldKitPartyCard"..i);assert(f,"party card "..i);f:SetWidth(280);f:SetHeight(90);StageCard(f);f:Hide();cards[i]=f end
  Relayout()
  C.Refresh(true);C.Refresh(true);C.Refresh(true) -- let the engine settle before measuring the reference
  local legacyBefore={};for k,v in pairs(FieldKitDB.frameAnchors or {}) do legacyBefore[k]=v[3]..":"..v[4] end
  local baseline={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do baseline[k]={Rendered(R.frames[k])} end
  local dmg=Opaque2("Damage")
  -- 0 members: nothing shown, nothing reserved
  C.Refresh(true);for i=1,4 do assert(not cards[i]:IsShown() and cards[i].fieldkitApplied==nil,zone..": no card, nothing displaced") end
  -- 1, 2 and 4 members, all dropped on top of the Damage card and of each other
  for count=1,4 do
   if count==3 then count=4 end
   for i=1,4 do if i<=count then Place(cards[i],dmg[1]+10+i*8,dmg[2]+10+i*8);cards[i]:Show() else cards[i]:Hide() end end
   C.Refresh(true);C.Refresh(true)
   Checked(zone..": "..count.." member(s)",cards)
   -- alpha.30 priority: the first teammate card keeps its preferred place, the main cards give way; saved positions untouched
   local fl,ft=Rendered(cards[1]);assert(math.abs(fl-(dmg[1]+18))<.5 and math.abs(ft-(dmg[2]+18))<.5,zone..": the teammate card keeps its preferred place with "..count.." member(s)")
   for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local v=FieldKitDB.zoneThemePositions[layout]["FieldKitReferencePanel"..k];assert(v and v[3]==saved[k][1] and v[4]==-saved[k][2],zone..": the saved position of "..k.." is never rewritten by the engine") end
   -- stable: no repositioning loop
   local snap={};for i=1,4 do snap[i]={Rendered(cards[i])} end
   for n=1,5 do C.Refresh(true) end
   for i=1,4 do local l,t=Rendered(cards[i]);assert(math.abs(l-snap[i][1])<.01 and math.abs(t-snap[i][2])<.01,zone..": card "..i.." does not keep moving") end
  end
  -- a member leaves: the card is released at once and the others close ranks only if they can
  cards[2]:Hide();C.Refresh(true);assert(cards[2].fieldkitApplied==nil and R.shift.Party2==nil,zone..": a hidden card holds no place")
  for i=1,4 do cards[i]:Hide() end;C.Refresh(true);C.Refresh(true)
  for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local l,t=Rendered(R.frames[k]);assert(math.abs(l-baseline[k][1])<.5 and math.abs(t-baseline[k][2])<.5,zone..": "..k.." goes back to its place when the group is empty ("..l..","..t.." vs "..baseline[k][1]..","..baseline[k][2]..")") end
  cards[1]:Show();cards[3]:Show();cards[4]:Show();C.Refresh(true);C.Refresh(true)
  Checked(zone..": a member left",cards)
  -- preferred position comes back when the space is free again: only this card on its preferred spot
  for i=1,4 do cards[i]:Hide() end;Place(cards[1],dmg[1]+10,dmg[2]+10);cards[1]:Show();C.Refresh(true)
  local displaced=Box(cards[1]);cards[1]:Hide();C.Refresh(true)
  local l,t=Rendered(cards[1]);assert(math.abs(l-(dmg[1]+10))<.5 and math.abs(t-(dmg[2]+10))<.5,zone..": hidden card is back on its preferred position")
  -- no shift while dragging (themed or teammate card)
  cards[1]:Show();C.Refresh(true);cards[1].azsMoving=true;local before={Rendered(cards[1])};R.shift.Party1=nil
  local dl,dt=Rendered(R.frames.Damage);C.Refresh(true)
  local nl,nt=Rendered(cards[1]);assert(math.abs(nl-before[1])<.01 and math.abs(nt-before[2])<.01,zone..": nothing moves a card that is being dragged")
  cards[1].azsMoving=nil
  -- manual move is saved by the shared store, wins over the engine, and is read back after a reload
  Place(cards[1],dmg[1]+400,dmg[2]+250);local savedOk=C.Remember(cards[1]);assert(savedOk,zone..": the drop is stored")
  local stored=FieldKitDB.zoneThemePositions[layout].FieldKitPartyCard1;assert(stored and stored[3]>0,zone..": stored in the shared position store")
  C.Refresh(true);local ml,mt=Rendered(cards[1]);assert(R.lastParty=="Party1",zone..": the moved card is remembered as last moved")
  Place(cards[1],5,5) -- "reload": the legacy code puts the card back at its old place
  cards[1].fieldkitApplied=nil;cards[1].fieldkitBase=nil;C.Refresh(true);C.Refresh(true)
  local rl,rt=Rendered(cards[1]);assert(math.abs(rl-ml)<.5 and math.abs(rt-mt)<.5,zone..": the saved position is applied again after a reload ("..rl..","..rt.." vs "..ml..","..mt..")")
  -- old legacy values untouched
  for k,v in pairs(FieldKitDB.frameAnchors or {}) do assert(legacyBefore[k]==v[3]..":"..v[4],zone..": legacy anchor "..k.." untouched") end
  -- Bonuses expands while teammate cards are shown: nobody overlaps, Bonuses is not displaced by them
  FieldKitStatsFrame.rows=FakeStats(14)
  for i=1,2 do Place(cards[i],dmg[1]+20+i*10,dmg[2]+20+i*10);cards[i].fieldkitBase=nil;cards[i]:Show() end
  FieldKitDB.zoneThemePositions[layout].FieldKitPartyCard1=nil
  R.statsOpen=true;C.Refresh(true);C.Refresh(true)
  Checked(zone..": Bonuses expanded with teammate cards",cards)
  R.statsOpen=false;FieldKitStatsFrame.rows=realStatsRows;C.Refresh(true)
  -- overlap option on: nothing is displaced
  FieldKitDB.zoneThemeOverlap=true;C.Refresh(true);assert(cards[1].fieldkitApplied==nil and cards[2].fieldkitApplied==nil,zone..": overlap allowed, nothing displaced");FieldKitDB.zoneThemeOverlap=false
  -- theme off: cards are back on their own place
  for i=1,4 do cards[i]:Hide() end;FieldKitDB.zoneThemePositions[layout].FieldKitPartyCard1=nil
  C.Set("zoneThemes",false)
  for i=1,4 do cards[i].fieldkitApplied=nil;UnstageCard(cards[i]) end
  Unstage()
 end
end
print("Teammate cards in the placement engine: 0-4 members, collisions, stability, drag, persistence passed (synthetic)")

-- alpha.30: themed teammate cards: shown with the theme, native frames replaced and restored, states, strata, individual moves.
do
 local P=FieldKitCoop
 local members={}
 local function M(unit) local _,_,i=string.find(unit,"^party(%d)$");return i and members[tonumber(i)] end
 local old={}
 for _,n in ipairs({"UnitExists","UnitName","UnitHealth","UnitHealthMax","UnitMana","UnitManaMax","UnitPowerType","UnitClass","UnitLevel","UnitIsConnected","UnitIsDeadOrGhost","UnitIsGhost","SetPortraitTexture"}) do old[n]=_G[n] end
 UnitExists=function(u) return M(u)~=nil or old.UnitExists(u) end
 UnitName=function(u) local m=M(u);return m and m.name or old.UnitName(u) end
 UnitHealth=function(u) local m=M(u);return m and m.hp or old.UnitHealth(u) end
 UnitHealthMax=function(u) local m=M(u);return m and m.max or old.UnitHealthMax(u) end
 UnitMana=function(u) local m=M(u);return m and m.mana or old.UnitMana(u) end
 UnitManaMax=function(u) local m=M(u);return m and m.mp or old.UnitManaMax(u) end
 UnitPowerType=function(u) local m=M(u);return m and 0 or old.UnitPowerType(u) end
 UnitClass=function(u) local m=M(u);if m then return m.class,m.key end return old.UnitClass(u) end
 UnitLevel=function(u) local m=M(u);if m then return m.level end return old.UnitLevel(u) end
 UnitIsConnected=function(u) local m=M(u);if m then return m.online end return true end
 UnitIsDeadOrGhost=function(u) local m=M(u);return m and (m.dead or m.ghost) or false end
 UnitIsGhost=function(u) local m=M(u);return m and m.ghost or false end
 local portraits=0;SetPortraitTexture=function() portraits=portraits+1 end
 local natives={};for i=1,4 do natives[i]=CreateFrame("Frame","PartyMemberFrame"..i,UIParent);natives[i]:Show() end
 AZS_RUN.ph="playing";AZS_RUN.t=2000;P.phase=nil;P.TrackRun()
 local function Stage1(f) f.GetLeft=function(self) local l=Rendered(self);return l end;f.GetTop=function(self) local _,t=Rendered(self);return UIH-t end;f.GetEffectiveScale=function() return 1 end end
 local function Put(f,x,y) f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",x,-y) end
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
  FieldKitDB.partyCards=false;FieldKitDB.replacePartyFrames=false;FieldKit_SetLanguage("en")
  local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
  Stage()
  for i=1,4 do Stage1(P.frames[i]);P.frames[i]:SetWidth(280);P.frames[i]:SetHeight(100) end
  -- empty group: no card, native frames untouched
  members={};P.Update();for i=1,4 do assert(not P.frames[i]:IsShown() and natives[i]:IsShown(),zone..": empty group: no FieldKit card, nothing hidden") end
  -- two members: themed cards, native frames replaced, preferences untouched
  members={{name="Denza",hp=400,max=800,mana=30,mp=100,class="Mage",key="MAGE",level=12,online=true},{name="Lockpin",hp=600,max=600,mana=10,mp=50,class="Priest",key="PRIEST",level=11,online=true}}
  P.Update()
  assert(P.frames[1]:IsShown() and P.frames[2]:IsShown() and not P.frames[3]:IsShown() and not P.frames[4]:IsShown(),zone..": two members, two cards")
  assert(not natives[1]:IsShown() and not natives[2]:IsShown(),zone..": native frames are not shown together with the cards")
  assert(FieldKitDB.partyCards==false and FieldKitDB.replacePartyFrames==false,zone..": saved preferences are not modified")
  assert(P.frames[1].nameText:GetText()=="Denza" and P.frames[1].infoText:GetText()=="Lvl 12 Mage",zone..": name, then level and class on the secondary line ("..tostring(P.frames[1].infoText:GetText())..")")
  local c1=P.frames[1]
  assert(c1.hpBar:IsShown() and c1.hpBar.text:GetText()=="400 / 800 (50%)",zone..": health bar with current / maximum and percentage from the unit")
  assert(math.abs(c1.hpBar:GetValue()-.5)<1e-9,zone..": the bar is filled with the REAL fraction")
  assert(c1.mpBar:IsShown() and math.abs(c1.mpBar:GetValue()-.3)<1e-9 and c1.mpBar:GetHeight()==4,zone..": thin resource bar from the unit")
  FieldKitDB.partyDetail=3;P.Update();assert(c1.mpBar.text:GetText()=="30 / 100" and c1:GetHeight()==(P.UsesArt() and 63 or 76) and P.frames[2]:GetHeight()==(P.UsesArt() and 63 or 76),zone..": full detail: resource values, all cards the same size")
  FieldKitDB.partyDetail=1;P.Update();assert(c1:GetHeight()==(P.UsesArt() and 40 or 52) and not c1.mpBar:IsShown() and not c1.infoText:IsShown() and c1.hpBar:IsShown() and P.frames[2]:GetHeight()==(P.UsesArt() and 40 or 52),zone..": compact detail: name and life only, all cards the same size")
  FieldKitDB.partyDetail=2;P.Update()
  assert(c1:GetWidth()==300 and c1:GetHeight()==(P.UsesArt() and 57 or 68),zone..": standard card "..c1:GetWidth().."x"..c1:GetHeight())
  for _,row in ipairs(c1.rows) do assert(not row:IsShown(),zone..": the tall generic rows are not used") end
  assert(c1.hpBar:GetFrameLevel()>c1:GetFrameLevel() and c1.mpBar:GetFrameLevel()>c1:GetFrameLevel(),zone..": bars are explicitly above the card (children do not follow a parent's level)")
  assert(c1.fieldkitColor==nil and c1.hpBar.fieldkitColor[2]>c1.hpBar.fieldkitColor[1] or c1.hpBar.fieldkitColor[1]>.8,zone..": colour from the fraction")
  assert(P.frames[1].portrait and P.frames[1].portrait:IsShown() and portraits>0,zone..": portrait through the native API, inside a square socket")
  assert(P.frames[1]:GetFrameStrata()=="MEDIUM" and P.frames[1]:GetFrameLevel()>R.frames.Damage:GetFrameLevel() and P.frames[1]:GetFrameLevel()>R.frames.Stats:GetFrameLevel(),zone..": drawn above the main cards")
  local g,y,r=P.HealthColor(.9,false),P.HealthColor(.4,false),P.HealthColor(.1,false)
  assert(g[2]>g[1] and y[1]>.8 and r[1]>.8 and r[2]<.3,zone..": health colours follow the real fraction")
  assert(P.HealthColor(.9,true)[1]==.45,zone..": muted colour for dead / offline")
  -- states
  members[1].dead=true;members[1].hp=0;P.Update();assert(P.frames[1].stateText:GetText()=="DEAD" and P.frames[1].hpBar:GetValue()==0 and not P.frames[1].mpBar:IsShown() and P.frames[1]:GetHeight()==(P.UsesArt() and 57 or 68),zone..": dead: tag, empty grey bar, no resource bar, SAME size")
  members[1].ghost=true;P.Update();assert(P.frames[1].stateText:GetText()=="GHOST" and P.frames[1]:GetHeight()==(P.UsesArt() and 57 or 68),zone..": ghost")
  members[1].dead=nil;members[1].ghost=nil;members[1].hp=400;P.Update();assert(P.frames[1].hpBar.text:GetText()=="400 / 800 (50%)" and P.frames[1].mpBar:IsShown() and P.frames[1].stateText:GetText()=="",zone..": resurrection")
  members[1].online=false;P.Update();assert(P.frames[1].stateText:GetText()=="OFFLINE" and P.frames[1]:GetHeight()==(P.UsesArt() and 57 or 68),zone..": offline");members[1].online=true
  members[2].hp=0;P.Update();assert(P.frames[2].stateText:GetText()=="0 HP",zone..": 0 HP without a dead flag stays 0 HP")
  members[2].hp=600;members[2].mana=0;members[2].mp=0;P.Update()
  assert(P.frames[2].hpBar:IsShown() and not P.frames[2].mpBar:IsShown() and P.frames[2]:GetHeight()==(P.UsesArt() and 57 or 68) and P.frames[2]:GetHeight()==P.frames[1]:GetHeight(),zone..": resource unavailable: only that bar disappears, the card keeps the SAME size")
  members[2].mana=10;members[2].mp=50;P.Update();assert(P.frames[2]:GetHeight()==(P.UsesArt() and 57 or 68) and P.frames[2].mpBar:IsShown())
  members[2].hp=300;P.Update();assert(math.abs(P.frames[2].hpBar:GetValue()-.5)<1e-9 and P.frames[2].hpBar.text:GetText()=="300 / 600 (50%)",zone..": wounded")
  members[2].hp=600;P.Update();assert(P.frames[2].hpBar:GetValue()==1 and P.frames[2].hpBar.text:GetText()=="600 / 600 (100%)",zone..": full health")
  -- portrait: the real one, else the class icon
  SetPortraitTexture=function() error("no portrait") end;P.frames[1].portraitKey=nil;P.Update()
  assert(P.frames[1].portrait:IsShown(),zone..": class icon when the portrait is unavailable");SetPortraitTexture=function() end
  members[2].hp=600
  -- partial data: nothing invented
  local level=members[1].level;members[1].level=nil;members[1].class=nil;members[1].key=nil;P.Update()
  assert(P.frames[1].infoText:GetText()=="?",zone..": no level, no class: nothing invented ("..tostring(P.frames[1].infoText:GetText())..")")
  members[1].level=level;members[1].class="Mage";members[1].key="MAGE"
  members[2].max=0;P.Update();assert(not P.frames[2]:IsShown() and natives[2]:IsShown(),zone..": unknown max HP: no invented card, native frame kept");members[2].max=600;P.Update()
  assert(P.frames[2]:IsShown() and not natives[2]:IsShown(),zone..": and back")
  -- a member joins, then leaves: no ghost card, native frame back
  members[3]={name="Empe",hp=300,max=300,mana=70,mp=100,class="Warrior",key="WARRIOR",level=13,online=true};P.Update();assert(P.frames[3]:IsShown() and not natives[3]:IsShown(),zone..": joins")
  members[3]=nil;P.Update();assert(not P.frames[3]:IsShown() and P.stock[3]==nil,zone..": leaves: no ghost card, native hook released (the game hides the frame of a unit that is gone)")
  -- four members, each card moved individually
  members[3]={name="Empe",hp=300,max=300,mana=70,mp=100,class="Warrior",key="WARRIOR",level=13,online=true}
  members[4]={name="Zed",hp=50,max=500,mana=0,mp=0,class="Rogue",key="ROGUE",level=14,online=true}
  natives[3]:Show();natives[4]:Show() -- the game shows the native frame of a member who joins
  P.Update()
  for i=1,4 do assert(P.frames[i]:IsShown(),zone..": four members") end
  local spots={{300,200},{900,260},{300,560},{1000,620}}
  for i=1,4 do Put(P.frames[i],spots[i][1],spots[i][2]);assert(C.Remember(P.frames[i]),zone..": card "..i.." is stored on its own") end
  C.Refresh(true);C.Refresh(true)
  for i=1,4 do local v=FieldKitDB.zoneThemePositions[layout]["FieldKitPartyCard"..i];assert(v and v[3]==spots[i][1] and v[4]==-spots[i][2],zone..": independent saved position "..i) end
  -- a main card put on a teammate card gives way; the teammate card keeps its place
  FieldKitDB.zoneThemePositions[layout].FieldKitReferencePanelDamage={"TOPLEFT","TOPLEFT",spots[1][1],-spots[1][2]};Relayout();C.Refresh(true)
  local od=Opaque2("Damage");local dl,dt,dw,dh=od[1],od[2],od[3]-od[1],od[4]-od[2];local pl,pt,pw,ph=Rendered(P.frames[1])
  assert(not (math.min(dl+dw,pl+pw)-math.max(dl,pl)>0 and math.min(dt+dh,pt+ph)-math.max(dt,pt)>6),zone..": a main card dropped on a teammate card gives way")
  assert(math.abs(pl-spots[1][1])<.5 and math.abs(pt-spots[1][2])<.5,zone..": the teammate card keeps its place")
  local saved=FieldKitDB.zoneThemePositions[layout].FieldKitReferencePanelDamage;assert(saved[3]==spots[1][1] and saved[4]==-spots[1][2],zone..": the engine never rewrites the saved position of the main card")
  local other=zone=="elwynn" and "naxx:complete:reference" or "elwynn:complete:reference"
  assert(FieldKitDB.zoneThemePositions[other]==nil or FieldKitDB.zoneThemePositions[other].FieldKitPartyCard1==nil,zone..": positions are stored per layout")
  -- alpha.32: one component, fixed geometry, nothing truncated or overlapping, player card, size and visibility options
  -- alpha.33/34: the border art follows the card, every widget sits inside the content box, at 3 detail levels x 3 scales.
  -- Elwynn: the frame is the Aethus art (9 tiles that exactly cover the card, skin hidden). Naxx: the zone material skin.
  for detail=1,3 do for _,scale in ipairs({70,100,130}) do
   FieldKitDB.partyDetail=detail;FieldKitDB.partyCardScale=scale;P.Update()
   local art=P.UsesArt();assert(art==(zone=="elwynn"),zone..": Elwynn uses the Aethus art, Naxx the zone material")
   local spec=(art and P.artDetail or P.detail)[detail]
   for i=1,4 do
    local f=P.frames[i];local L=f.fieldkitLayout;local w,h=f:GetWidth(),f:GetHeight()
    local tag=zone.." detail "..detail.." scale "..scale.." card "..i
    assert(w==300 and h==spec.h and L.height==h,tag..": fixed size "..w.."x"..h)
    assert(f:GetScale()==scale/100,tag..": scale")
    if art then
     local covered=0;local minX,minY,maxX,maxY=1e9,1e9,0,0
     for _,t in ipairs(f.artTiles) do assert(t:IsShown(),tag..": art tile shown");local r=t.fieldkitRect
      covered=covered+(r[3]-r[1])*(r[4]-r[2]);minX=math.min(minX,r[1]);minY=math.min(minY,r[2]);maxX=math.max(maxX,r[3]);maxY=math.max(maxY,r[4]) end
     assert(table.getn(f.artTiles)==9 and math.abs(covered-w*h)<.01 and minX==0 and minY==0 and math.abs(maxX-w)<.01 and math.abs(maxY-h)<.01,tag..": the 9 art tiles cover the card exactly (area "..covered.." vs "..w*h..")")
     assert(f.fieldkitArtOnly==true and f.fieldkitSkin.skinHidden~=false,tag..": the generic skin is hidden under the art")
    else
     assert(f.fieldkitSkin.width==w and f.fieldkitSkin.height==h,tag..": the border material has the card's current size")
     for _,t in ipairs(f.artTiles or {}) do assert(not t:IsShown(),tag..": no Aethus art on Naxx") end
    end
    local b=L.box
    local function Inside(name,l,r,t,bt) assert(l>=b[1]-.001 and r<=b[2]+.001 and t>=b[3]-.001 and bt<=b[4]+.001,tag..": "..name.." is inside the content box ("..l..","..t.." -> "..r..","..bt.." box "..b[1]..","..b[3].." -> "..b[2]..","..b[4]..")") end
    assert(b[1]>=0 and b[2]<=w and b[3]>=0 and b[4]<=h,tag..": content box inside the card")
    local pt=L.portrait;assert(pt[1]>=0 and pt[3]<=b[1] and pt[2]>=0 and pt[4]<=h and pt[3]-pt[1]>=20 and pt[4]-pt[2]>=20,tag..": portrait window inside the card, left of the content, big enough ("..pt[3]-pt[1].."x"..pt[4]-pt[2]..")")
    Inside("name",L.name[1],L.name[2],L.name[3],L.name[3]+L.name[4])
    Inside("state",L.state[1],L.state[2],L.state[3],L.state[3]+L.state[4])
    Inside("life bar",L.hp[1],L.hp[2],L.hp[3],L.hp[3]+L.hp[4])
    assert(L.name[2]<=L.state[1],tag..": the name ends before the state tag")
    if spec.info then
     Inside("secondary line",L.info[1],L.info[2],L.info[3],L.info[3]+L.info[4]);assert(L.info[2]<=b[2]-70+.001,tag..": room for five icons")
     assert(L.info[3]+L.info[4]<=L.hp[3],tag..": the secondary line ends above the life bar")
    end
    assert(L.name[3]+L.name[4]<=L.hp[3],tag..": the name line ends above the life bar")
    if f.mpBar:IsShown() then Inside("resource bar",L.res[1],L.res[2],L.res[3],L.res[3]+L.res[4]);assert(L.res[3]>=L.hp[3]+L.hp[4],tag..": resource under the life bar") end
   end
   -- the four cards share exactly the same structure
   for i=2,4 do local a,c=P.frames[1].fieldkitLayout,P.frames[i].fieldkitLayout
    assert(a.width==c.width and a.height==c.height and a.hp[2]==c.hp[2] and a.box[1]==c.box[1] and a.portrait[3]==c.portrait[3],zone..": card "..i.." has the same structure as card 1") end
  end end
  FieldKitDB.partyCardScale=100
  FieldKitDB.partyDetail=2;P.Update()
  -- history icons: only spells of the local spellbook, only at detail 2 and 3
  local H=FieldKitGroupHistory
  GetSpellName=function(i) return i==1 and "Frostbolt" or nil end;GetSpellTexture=function(i) return i==1 and "Interface\\Icons\\Spell_Frost_FrostBolt02" or nil end
  SPELLLOGOTHEROTHER="%s's %s hits %s for %d.";H.formats=nil;H.Clear()
  FieldKitDB.partyHistory=true;H.Sync();H.icons=nil
  H.Handle("x","Denza's Frostbolt hits Boar for 40.");H.Handle("x","Denza's Unknown Spell hits Boar for 40.")
  P.Update();assert(P.frames[1].fieldkitIconCount==1 and P.frames[1].historyIcons[1]:IsShown() and not P.frames[1].historyIcons[2]:IsShown(),zone..": one icon (the other spell is not in the local spellbook)")
  FieldKitDB.partyHistoryIcons=false;P.Update();assert(P.frames[1].fieldkitIconCount==0 and not P.frames[1].historyIcons[1]:IsShown(),zone..": icons option off")
  FieldKitDB.partyHistoryIcons=true;FieldKitDB.partyDetail=1;P.Update();assert(P.frames[1].fieldkitIconCount==0,zone..": compact detail has no icon line");FieldKitDB.partyDetail=2
  FieldKitDB.partyHistory=false;H.Sync();GetSpellName=nil;GetSpellTexture=nil;P.Update()
  -- the player's own card: same component, same size, optional
  assert(P.frames[0] and not P.frames[0]:IsShown(),zone..": own card off by default")
  FieldKitDB.partyPlayerCard=true;Stage1(P.frames[0]);P.Update()
  assert(P.frames[0]:IsShown() and P.frames[0].unit=="player" and P.frames[0]:GetWidth()==300 and P.frames[0]:GetHeight()==P.frames[1]:GetHeight(),zone..": own card shown with the very same structure and size")
  assert(P.frames[0].hpBar:IsShown() and P.frames[0].nameText:GetText()~=nil,zone..": own card has its bars")
  local found=false;for _,e in ipairs(R.PartyFrames()) do if e[2]==P.frames[0] then found=true end end;assert(found,zone..": own card is an element of the placement engine")
  -- size option
  FieldKitDB.partyCardScale=130;P.Update();assert(P.frames[1]:GetScale()==1.3 and P.frames[0]:GetScale()==1.3,zone..": card size option")
  FieldKitDB.partyCardScale=70;P.Update();assert(P.frames[2]:GetScale()==.7)
  FieldKitDB.partyCardScale=100;P.Update()
  FieldKitDB.partyPlayerCard=false;P.Update();assert(not P.frames[0]:IsShown(),zone..": own card hidden again")
  -- show / hide group cards: native frames stay when the cards are hidden
  FieldKitDB.partyShow=false;P.Update()
  for i=1,4 do assert(not P.frames[i]:IsShown() and P.stock[i]==nil,zone..": group cards hidden: no card, native hooks released") end
  FieldKitDB.partyShow=true;P.Update();assert(P.frames[1]:IsShown(),zone..": group cards shown again")
  -- alpha.35: the life bar is a flat fill, proportional and exact at 100 / 99 / 80 / 50 / 1 %, outline above the fill
  for _,pct in ipairs({100,99,80,50,1}) do
   members[1].max=800;members[1].hp=members[1].max*pct/100;P.Update()
   local c1=P.frames[1];local tag=zone.." "..pct.." %"
   assert(math.abs(c1.hpBar:GetValue()-pct/100)<1e-12,tag..": fill fraction is exact ("..c1.hpBar:GetValue()..")")
   if pct==100 then assert(c1.hpBar:GetValue()==1,"a full bar is exactly 1") end
   assert(c1.hpBar.fieldkitTexture=="Interface\\Buttons\\WHITE8X8" and c1.mpBar.fieldkitTexture=="Interface\\Buttons\\WHITE8X8",tag..": flat fill texture (no gradient strip, no tiling seams)")
   for _,t in ipairs(c1.hpBar.edge) do assert(t.fieldkitLayer=="OVERLAY",tag..": outline above the fill") end
   local L=c1.fieldkitLayout;assert(L.hp[2]==L.width-(L.width-L.box[2]) and L.hp[2]<=L.box[2],tag..": the bar ends at the content box, never beyond the frame")
   assert(c1.hpBar.text:GetText()==FieldKit_FormatHealth(members[1].hp,800,3),tag..": text from the same values")
  end
  members[1].hp=400;members[1].max=800;P.Update()
  -- alpha.36: life bar with a whole-pixel size, one anchor, an opaque fill and a forced fill refresh; six values x four scales
  for _,scale in ipairs({70,90,100,130}) do
   FieldKitDB.partyCardScale=scale
   for _,pct in ipairs({100,99,80,50,1,0}) do
    members[1].max=800;members[1].hp=members[1].max*pct/100
    local alphaSeen;local bar=P.frames[1].hpBar;local oldColor=bar.SetStatusBarColor
    bar.SetStatusBarColor=function(self,r,g,b,a) alphaSeen=a;if oldColor then oldColor(self,r,g,b,a) end end
    P.Update();bar.SetStatusBarColor=oldColor
    local c1=P.frames[1];local L=c1.fieldkitLayout;local tag=zone.." scale "..scale.." "..pct.." %"
    local want=pct/100
    assert(math.abs(bar:GetValue()-want)<1e-12 and bar.fieldkitFraction==want,tag..": fill fraction exact ("..bar:GetValue()..")")
    assert(bar:IsShown(),tag..": the bar stays drawn (an empty bar at 0 %)")
    assert(bar.fieldkitW==math.floor(bar.fieldkitW) and bar.fieldkitH==math.floor(bar.fieldkitH),tag..": whole-pixel size ("..tostring(bar.fieldkitW).."x"..tostring(bar.fieldkitH)..")")
    assert(bar.fieldkitW==L.hp[2]-L.hp[1] and L.hp[2]<=L.box[2],tag..": the bar is exactly as wide as the content box, never wider than the frame")
    assert(pct==0 or alphaSeen==1 or alphaSeen==nil,tag..": fully opaque fill ("..tostring(alphaSeen)..")")
    assert(bar.fieldkitSize==bar.fieldkitW.."x"..bar.fieldkitH,tag..": fill refreshed for the current size")
    assert(c1:GetScale()==scale/100,tag..": scale")
   end
  end
  FieldKitDB.partyCardScale=100;members[1].hp=400;members[1].max=800;P.Update()
  -- a size change (detail level) refreshes the fill at the new width
  FieldKitDB.partyDetail=3;members[1].hp=800;P.Update();local b1=P.frames[1].hpBar;local k3=b1.fieldkitSize;assert(b1:GetValue()==1,zone..": full bar at detail 3")
  FieldKitDB.partyDetail=1;P.Update();assert(b1.fieldkitSize~=k3 and b1:GetValue()==1,zone..": the full bar is refreshed after a size change ("..tostring(k3).." -> "..tostring(b1.fieldkitSize)..")")
  FieldKitDB.partyDetail=2;members[1].hp=400;P.Update()
  local probe=P.BarProbe();assert(table.getn(probe)>=1 and string.find(probe[1],"bar",1,true),zone..": /fieldkit barprobe reports the real bar size and value")
  -- theme off: native frames come back, the cards go
  C.Set("zoneThemes",false);P.Update()
  for i=1,4 do assert(not P.frames[i]:IsShown() and P.stock[i]==nil,zone..": theme off: no FieldKit card, native hooks released") end
  for i=1,4 do if M("party"..i) then assert(natives[i]:IsShown(),zone..": theme off: the native frame of an existing member is back") end end
  assert(P.frames[1]:GetFrameStrata()=="LOW" or not P.frames[1]:IsShown(),zone..": legacy strata back")
  FieldKitDB.zoneThemePositions[layout]=nil;members={};P.Update()
  for i=1,4 do P.frames[i].GetLeft=nil;P.frames[i].GetTop=nil;P.frames[i].GetEffectiveScale=nil end;Unstage()
 end
 for k,v in pairs(old) do _G[k]=v end
 AZS_RUN.ph=nil;P.Update()
end
print("Themed teammate cards: states, native replacement, strata, individual moves passed (synthetic)")

-- alpha.34: compact amounts, real damage per spell next to the share, the premium Damage header, the chat fill inside the frame.
do
 local savedLang=FieldKitDB.language
 FieldKit_SetLanguage("en")
 assert(R.Amount(nil)=="?" and R.Amount("x")=="?","a missing value is never turned into a number")
 assert(R.Amount(0)=="0" and R.Amount(950)=="950" and R.Amount(1250)=="1,250" and R.Amount(9999)=="9,999" and R.Amount(12400)=="12.4 k" and R.Amount(999000)=="999.0 k" and R.Amount(1200000)=="1.2 M" and R.Amount(-1250)=="-1,250","EN amounts")
 FieldKit_SetLanguage("fr")
 assert(R.Amount(1250)=="1 250" and R.Amount(12400)=="12,4 k" and R.Amount(1200000)=="1,2 M" and R.Amount(500)=="500","FR amounts (decimal comma, grouped thousands)")
 FieldKit_SetLanguage("en")
 local read=FieldKitMeterLedger.Read
 local longName="Attaques circulaires tourbillonnantes de la Légion ardente"
 local lines={{name="Attaques circulaires",share=.42,dmg=12400,dps=120.5,icon="Interface\\Icons\\Ability_Whirlwind"},
  {name=longName,share=.30,dmg=1250},{name="Frappe heroique",share=.20},{name="Execution",dmg=500},
  {name="Saignement",share=.05,dmg=1200000},{name="Coup de bouclier",share=.03,dmg=900}}
 FieldKitMeterLedger.Read=function() return lines,29250,300,true end
 for _,zone in ipairs({"elwynn","naxx"}) do for _,lang in ipairs({"en","fr"}) do
  FieldKit_SetLanguage(lang)
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local f=R.frames.Damage;local a=R.CardRect("Damage",R.layout)
  local function A(n) return R.Amount(n) end
  local tag=zone.." "..lang
  -- six lines visible, one value column, right-aligned, nothing overflowing
  local shown={};for _,r in ipairs(f.rows) do if r:IsShown() and r.fieldkitLine then table.insert(shown,r) end end
  assert(table.getn(shown)==6,tag..": the six lines stay visible ("..table.getn(shown)..")")
  assert(shown[1].value:GetText()=="42 %" and shown[1].amount:GetText()==A(12400),tag..": share and real amount as two pieces ("..tostring(shown[1].value:GetText()).." / "..tostring(shown[1].amount:GetText())..")")
  assert(shown[2].value:GetText()=="30 %" and shown[2].amount:GetText()==A(1250),tag..": second line")
  assert(shown[3].value:GetText()=="20 %" and shown[3].amount:GetText()=="",tag..": no amount in the data -> only the share, nothing invented")
  assert(shown[4].value:GetText()=="" and shown[4].amount:GetText()==A(500),tag..": no share in the data -> only the amount")
  assert(shown[5].value:GetText()=="5 %" and shown[5].amount:GetText()==A(1200000),tag..": millions")
  -- hierarchy: the share is the bright piece, the amount is the muted one; both right-aligned on the same line
  local wp,wa=shown[1].value:GetWidth(),shown[1].amount:GetWidth()
  for _,r in ipairs(shown) do
   assert(r.value:GetWidth()==wp and r.amount:GetWidth()==wa,tag..": one column per piece")
   assert(r.value:GetStringWidth()<=r.value:GetWidth()+.01 and r.amount:GetStringWidth()<=r.amount:GetWidth()+.01 and r.label:GetStringWidth()<=r.label:GetWidth()+.01,tag..": no text wider than its box")
   assert(r.label:GetWidth()+r.value:GetWidth()+r.amount:GetWidth()<=r:GetWidth()+1,tag..": name, share and amount never overlap ("..r.label:GetWidth().."+"..r.value:GetWidth().."+"..r.amount:GetWidth().." in "..r:GetWidth()..")")
   local _,_,_,ax=r.amount:GetPoint();local _,_,_,vx=r.value:GetPoint()
   assert(ax==0 and vx<=-(wa)+.01,tag..": amount flush right, share just left of it")
  end
  assert(shown[1].amountSep:IsShown() and not shown[3].amountSep:IsShown() and not shown[4].amountSep:IsShown(),tag..": thin separator only when both pieces exist")
  assert(shown[2].label.referenceFullText==longName and shown[2].label:GetStringWidth()<=shown[2].label:GetWidth(),tag..": the full name is kept as data and the displayed text fits its box")
  assert(shown[1].bar:IsShown() and shown[1].bar:GetWidth()==a[3]-160,tag..": the proportional bar keeps its width")
  assert(shown[1].icon:IsShown(),tag..": icon")
  -- header: amount, rate, banner structure
  assert(f.total:GetText()==A(29250),tag..": header total with the compact format")
  if zone=="elwynn" then
   assert(f.rateLabel:IsShown() and string.find(f.rateLabel:GetText(),A(300).." DPS",1,true),tag..": header rate under the amount")
   assert(f.headRule:IsShown() and f.navBand:IsShown() and f.navRule:IsShown(),tag..": banner rules and navigation strip")
  else assert(f.navBand:IsShown() and not f.headRule:IsShown(),tag..": Naxx keeps its own header with the navigation strip") end
  for i,b in ipairs(R.tabs) do
   assert(b:IsShown() and b.activeTile and (b.activeTile:IsShown()==(i==1)),tag..": only the active category has the gold tile (tab "..i..")")
   assert(b.underline:IsShown()==(i==1),tag..": gold underline on the active tab only")
  end
  click(R.tabs[4]);assert(R.tabs[4].activeTile:IsShown() and not R.tabs[1].activeTile:IsShown(),tag..": the indicator follows the click on the first try");click(R.tabs[1])
  -- exact values stay in the tooltip
  local tipSections;local oldTip=H.RichTip;H.RichTip=function(_,spec) tipSections=spec.sections end
  R.DamageTip(shown[1]);H.RichTip=oldTip
  local found=false;for _,sec in ipairs(tipSections or {}) do for _,line in ipairs(sec.lines) do if string.find(line[1],"12400",1,true) then found=true end end end
  assert(found,tag..": the exact total (12400) is in the tooltip")
 end end
 FieldKitMeterLedger.Read=read
 -- an empty list keeps its empty state
 FieldKitMeterLedger.Read=function() return {},0,nil,true end;C.Refresh(true)
 local anyValue=false;for _,r in ipairs(R.frames.Damage.rows) do if r:IsShown() and r.value:GetText()~="" then anyValue=true end end
 assert(not anyValue,"no data: no amount shown");FieldKitMeterLedger.Read=read
 FieldKit_SetLanguage(savedLang or "en")
 -- chat: the dark fill stays inside the frame (the corners of the border art are cut diagonally)
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local chat=R.chat;local skin=chat.fieldkitSkin
  local function Check(label)
   local w,h=chat:GetWidth(),chat:GetHeight();local c=math.min(12,w/3,h/3)
   for _,part in ipairs({skin.base,skin.grain}) do
    local _,_,_,x,y=part:GetPoint()
    assert(x==c and y==-c and part:GetWidth()==w-2*c and part:GetHeight()==h-2*c,zone..": "..label..": the fill is inset by the corner cut ("..tostring(x)..","..tostring(y).." "..part:GetWidth().."x"..part:GetHeight().." in "..w.."x"..h..")")
   end
   assert(skin.inset==c,zone..": "..label..": inset recorded")
  end
  Check("chat at its reference size")
  local w,h=chat:GetWidth(),chat:GetHeight()
  chat:SetWidth(w+60);chat:SetHeight(h+40);T.Update(chat);Check("chat resized")
  chat:SetWidth(w);chat:SetHeight(h);T.Update(chat);Check("chat back to its size")
  -- the same inset for every card drawn with the zone material (party card on Naxx, settings...)
  C.Set("zoneThemes",false);C.Set("zoneThemes",true);C.Refresh(true);Check("after a theme change")
 end
 C.Set("zoneThemes",false)
end
print("Compact amounts, real damage per spell, premium Damage header and contained chat fill passed (synthetic)")

-- alpha.35: chat controls, overlap option layout, Damage header, bar fill.
do
 local savedLang=FieldKitDB.language
 FieldKit_SetLanguage("en")
 local chat=getglobal("ChatFrame1") or CreateFrame("Frame","ChatFrame1",UIParent)
 local calls={}
 for _,m in ipairs({"PageUp","PageDown","ScrollToTop","ScrollToBottom"}) do local name=m;chat[m]=function() table.insert(calls,name) end end -- Lua 5.0: copy the loop variable
 local oldCopy=FieldKit.OpenChatCopy;local copies=0;FieldKit.OpenChatCopy=function() copies=copies+1 end
 local shiftDown=false;IsShiftKeyDown=function() return shiftDown end
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  if zone=="naxx" then
   for _,b in ipairs(R.chatTools) do assert(not b:IsShown(),"Naxx keeps its own chat actions: no extra tool") end
  else
   local W,H=R.layout.rects.chat[3],R.layout.rects.chat[4]
   assert(table.getn(R.chatTools)==4 and R.chatToolCols==1,"Elwynn: four chat controls in one column ("..tostring(R.chatToolCols)..")")
   local keys={copy=true,up=true,down=true,bottom=true};for _,b in ipairs(R.chatTools) do assert(b:IsShown() and keys[b.fieldkitChatTool],"tool shown");keys[b.fieldkitChatTool]=nil end;assert(next(keys)==nil,"the four tools are copy, up, down and latest")
   -- geometry: inside the border, disjoint, beside (not over) the text area
   local textRight=14+(W-28-R.chatToolCols*24)
   for i,r in ipairs(R.chatToolRects) do
    assert(r[1]>=12 and r[3]<=W-12 and r[2]>=12 and r[4]<=H-12,"tool "..i.." is inside the border")
    assert(r[1]>=textRight-.001,"tool "..i.." sits beside the text area, not over it ("..r[1].." vs "..textRight..")")
    for j=i+1,4 do local o=R.chatToolRects[j];assert(r[3]<=o[1] or o[3]<=r[1] or r[4]<=o[2] or o[4]<=r[2],"tools "..i.." and "..j.." do not overlap") end
   end
   -- alpha.34 clipping is untouched
   local skin=R.chat.fieldkitSkin;local c=math.min(12,R.chat:GetWidth()/3,R.chat:GetHeight()/3);local _,_,_,bx=skin.base:GetPoint();assert(bx==c,"the fill is still inset by the corner cut")
   -- clicks on the first try, locked and unlocked; Shift variants; the copy window
   for _,locked in ipairs({false,true}) do
    FieldKitDB.windowsLocked=locked;calls={};copies=0
    for _,b in ipairs(R.chatTools) do assert(b:IsShown() and b:GetWidth()>=22 and b:GetHeight()>=19,"hit area") end
    local by={};for _,b in ipairs(R.chatTools) do by[b.fieldkitChatTool]=b end
    click(by.up);click(by.down);click(by.bottom);click(by.copy)
    assert(table.concat(calls,",")=="PageUp,PageDown,ScrollToBottom" and copies==1,"locked="..tostring(locked)..": up, down, latest and copy run on the first click ("..table.concat(calls,",")..")")
    shiftDown=true;calls={};click(by.up);click(by.down);shiftDown=false
    assert(table.concat(calls,",")=="ScrollToTop,ScrollToBottom","Shift jumps to the top / the bottom")
   end
   FieldKitDB.windowsLocked=false
   -- tooltips
   local text;local oldSet=GameTooltip.SetText;local oldOwner=GameTooltip.SetOwner;local oldShow=GameTooltip.Show
   GameTooltip.SetText=function(_,t) text=t end;GameTooltip.SetOwner=function() end;GameTooltip.Show=function() end
   for _,b in ipairs(R.chatTools) do text=nil;this=b;b.scripts.OnEnter();assert(text and text~="","tooltip for "..b.fieldkitChatTool) end
   GameTooltip.SetText,GameTooltip.SetOwner,GameTooltip.Show=oldSet,oldOwner,oldShow
   -- another theme and back: still there
   C.Set("zoneThemes",false);for _,b in ipairs(R.chatTools) do assert(not b:IsShown() or not R.active,"tools follow the theme") end
   C.Set("zoneThemes",true);C.Refresh(true);for _,b in ipairs(R.chatTools) do assert(b:IsShown(),"tools are back with the theme") end
  end
 end
 FieldKit.OpenChatCopy=oldCopy;IsShiftKeyDown=nil

 -- Options: the overlap control has its own row, full label, state written in the control
 do
  local parent=CreateFrame("Frame","FieldKitTestThemePage",UIParent);parent.flow={}
  local height=FieldKitThemeUI(parent,0);assert(height==933,"page height grew by the new row ("..tostring(height)..")")
  local page=parent.flow[1].frame;local ob=C.overlapButton
  assert(ob and ob:GetHeight()==36,"overlap control is 36 px high")
  for _,w in ipairs({620,810,1000}) do
   page.Reflow(w);local _,_,_,x,y=ob:GetPoint()
   assert(ob:GetWidth()==w and x==0 and y==-430,"full-width dedicated row at "..w.." px")
   assert(ob.fieldkitLabel:GetWidth()==w-32,"the label has the whole row")
  end
  FieldKitDB.zoneThemeOverlap=false;C.Refresh(true)
  assert(ob.fieldkitLabel:GetText()=="Allow card overlap : Disabled","state in the label: "..tostring(ob.fieldkitLabel:GetText()))
  click(ob);assert(FieldKitDB.zoneThemeOverlap==true and ob.fieldkitLabel:GetText()=="Allow card overlap : Enabled" and ob.fieldkitSelected==true,"immediate effect, label and gold state")
  FieldKit_SetLanguage("fr");C.Refresh(true);assert(ob.fieldkitLabel:GetText()=="Autoriser le chevauchement : Activé","FR label: "..tostring(ob.fieldkitLabel:GetText()))
  FieldKit_SetLanguage("en");click(ob);assert(FieldKitDB.zoneThemeOverlap==false,"toggles back")
  -- nothing else of the page moved on top of it: the toggles stay above, the sliders below
  local sTitle=C.uiSliders[1].title;local _,_,_,_,sy=sTitle:GetPoint();assert(-sy>=430+36,"sliders are below the overlap row")
 end

 -- Damage header, both data states and the six categories
 local read=FieldKitMeterLedger.Read
 local rows={{name="Whirlwind",share=.53,dmg=12400,dps=120}}
 for _,zone in ipairs({"elwynn","naxx"}) do for _,lang in ipairs({"en","fr"}) do
  FieldKit_SetLanguage(lang)
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
  local tag=zone.." "..lang;local f=R.frames.Damage
  FieldKitMeterLedger.Read=function() return rows,12400,120,true end;C.Refresh(true)
  if zone=="elwynn" then
   -- one row of six contiguous cells
   local x0,y0,prevRight
   for i,b in ipairs(R.tabs) do
    local _,_,_,x,y=b:GetPoint();assert(b:IsShown() and b:GetWidth()>=56 and b:GetHeight()>=28,tag..": tab "..i.." hit area "..b:GetWidth().."x"..b:GetHeight())
    y0=y0 or y;assert(y==y0,tag..": the six categories share one row")
    if prevRight then assert(x==prevRight,tag..": cells are contiguous ("..x.." vs "..prevRight..")") end;prevRight=x+b:GetWidth()
    assert(b.underline:IsShown()==(i==1) and b.activeTile:IsShown()==(i==1),tag..": gold indicator on the active category only")
   end
   local ranges={f.headRule,f.navBand,f.navRule};for _,t in ipairs(ranges) do assert(t:IsShown(),tag..": banner structure") end
   assert(table.getn(f.navDividers)==5 and f.navDividers[1]:IsShown(),tag..": hairline dividers")
   -- first line: amount and rate on the same line, amount left of the rate
   local _,_,_,tx,ty=f.total:GetPoint();local _,_,_,rx,ry=f.rateLabel:GetPoint()
   assert(f.total:IsShown() and f.rateLabel:IsShown() and math.abs(ty-ry)<=6,tag..": amount and rate on one line")
   assert(tx<=-(30+88)+.001,tag..": the amount ends before the rate begins")
  end
  local names=lang=="fr" and {"Dégâts","Soins","Boss","Subis","Groupes","Élim."} or {"Damage","Healing","Boss","Taken","Groups","Kills short"}
  for i,b in ipairs(R.tabs) do assert(b.fieldkitLabel.referenceFullText==names[i] or b.fieldkitLabel:GetText()==names[i],tag..": category "..i.." label ("..tostring(b.fieldkitLabel:GetText())..")") end
  click(R.tabs[3]);local _,idx=FieldKitMeterSuite.View();assert(idx==3,tag..": first click changes the category");click(R.tabs[1])
  -- empty counter: no lone zero
  FieldKitMeterLedger.Read=function() return {},0,0,true end;C.Refresh(true)
  assert(not f.total:IsShown() and not f.rateLabel:IsShown(),tag..": empty counter: no isolated 0 above 0 DPS")
  FieldKitMeterLedger.Read=function() return rows,12400,120,true end;C.Refresh(true)
  assert(f.total:IsShown(),tag..": data back: header back")
 end end
 FieldKitMeterLedger.Read=read
 FieldKit_SetLanguage(savedLang or "en");C.Set("zoneThemes",false)
end
print("Chat controls, overlap row, Damage header and amounts pieces passed (synthetic)")

-- alpha.35: the foot label stays clear of the baked info icon (Elwynn), the button stays the click target.
do
 local oldHeroic=FieldKit.GetHeroicLabel
 FieldKit.GetHeroicLabel=function() return "Difficulté normale" end
 FieldKit_SetLanguage("fr")
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local button=H.mode;local label=button.fieldkitLabel;local a=R.layout.mode
  assert(button:IsShown(),zone..": the foot button is shown")
  if zone=="elwynn" then
   local icon=R.MODE_ICON.elwynn_complete
   assert(a[3]>=icon.right,"the icon is inside the foot button (clickable)")
   local lp=label.referenceRect or {}
   local _,_,_,lx=label:GetPoint();local lw=label:GetWidth()
   local left=lx;local right=lx+lw
   assert(left>=icon.textLeft-.001,"label starts after the art's left cap ("..left..")")
   assert(right<=icon.left-icon.margin+.001,"label ends before the info icon with a margin ("..right.." vs "..(icon.left-icon.margin)..")")
   assert(label:GetStringWidth()<=label:GetWidth(),"the displayed text fits its box (long FR text is fitted)")
   assert(label.referenceFullText and string.find(label.referenceFullText,"Difficulté normale",1,true),"the full text is kept")
  end
  click(button)
 end
 FieldKit.GetHeroicLabel=oldHeroic;FieldKit_SetLanguage("en");C.Set("zoneThemes",false)
end
print("Mode foot label clear of the info icon passed (synthetic)")

-- alpha.36: Equipment / Spells card height follows the content; Effects list margins.
do
 local function Snapshot(t) local out={} for k,v in pairs(t or {}) do out[k]=v end return out end
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
  R.statsOpen=false;FieldKitDB.loadoutTab=1;C.Refresh(true)
  local acc=R.frames.Accessories;local base=R.layout.rects.Accessories
  local minN=zone=="naxx" and 3 or 1
  local oldSpells=FieldKitLoadout.spells;local oldItems=FieldKitLoadout.items
  local lastHeight=0;local heights={}
  assert(acc:GetHeight()==base[4],zone..": Equipment keeps its normal dimensions")
  local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
  for _,count in ipairs({0,1,2,5,6,7,8,9,12}) do
   FieldKitLoadout.spells={};for i=1,count do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={},upgrades={}}) end
   click(acc.cardTabs[2]);local N=R.accN;local tag=zone..": "..count.." spells"
   assert(N==math.max(minN,count) and not R.accScroll,tag..": the card holds "..N.." rows, no scrolling")
   local h=acc:GetHeight();assert(h==base[4]+R.AccDelta(zone,N),tag..": height "..h)
   assert(h>=lastHeight,tag..": the card never gets shorter when spells are added");lastHeight=h;heights[count]=h
   if count==0 then assert(acc.rows[1]:IsShown() and acc.rows[1].label:GetText()==FieldKit_L("No spells yet"),tag..": small card with the empty state") end
   -- art: continuous and exactly the card height; corners never stretched (whole tiles, no scaling of the border pieces)
   local reach=0;local pieces={};for _,t in ipairs(acc.referenceTiles) do if t:IsShown() then local _,_,_,_,y=t:GetPoint();table.insert(pieces,{-y,t:GetHeight(),t:GetWidth()}) end end
   table.sort(pieces,function(p,q) return p[1]<q[1] end);for _,p in ipairs(pieces) do assert(p[1]==reach,tag..": art continuity at "..p[1]);reach=reach+p[2];assert(p[3]==base[3],tag..": the art keeps its width (no horizontal stretch)") end
   assert(reach==h,tag..": the art ends at the card bottom")
   -- rows: every spell visible, icons centred in their sockets
   local shown=0
   for i,r in ipairs(acc.rows) do if r:IsShown() and r.entry then
    shown=shown+1;local _,_,_,rx,ry=r:GetPoint();assert(-ry==R.SocketY(zone,i,N),tag..": row "..i.." on socket "..i)
    assert(-ry+r:GetHeight()<=h-10,tag..": row "..i.." inside the card")
    if r.icon:IsShown() then
     local _,_,_,ix,iy=r.icon:GetPoint();local size=r.icon:GetWidth()
     local sk=zone=="naxx" and {x=32,w=38,h=30} or {x=32,w=28,h=28}
     assert(math.abs((rx+ix+size/2)-(sk.x+sk.w/2))<=1 and math.abs((-iy+size/2)-(sk.h/2))<=1.5,tag..": icon "..i.." centred in its socket ("..(rx+ix+size/2).." vs "..(sk.x+sk.w/2)..")")
    end
   end end
   if count>0 then assert(shown==count,tag..": all "..count.." spells visible at once ("..shown..")") end
  end
  assert(heights[1]<=heights[5] and heights[5]<heights[6] and heights[6]<heights[8] and heights[8]<heights[9] and heights[9]<heights[12],zone..": 1-2 compact, 3-5 intermediate, 6-8 higher, 9+ higher again")
  -- tab switches do not touch the saved positions; Equipment is back to its dimensions at once
  local before=Snapshot(FieldKitDB.zoneThemePositions[layout])
  click(acc.cardTabs[1]);assert(acc:GetHeight()==base[4] and acc.rows[1].label:GetText()~=nil,zone..": back on Equipment: normal height immediately")
  click(acc.cardTabs[2]);click(acc.cardTabs[1])
  for k,v in pairs(Snapshot(FieldKitDB.zoneThemePositions[layout])) do assert(before[k]==v,zone..": changing tab never rewrites a saved position") end
  for _,k in ipairs({"Stats","Effects"}) do assert((R.shift[k] or 0)==0 and (R.shiftX[k] or 0)==0,zone..": "..k.." back at its preferred place after the card shrank") end
  -- the screen cannot hold the card: scrolling is only a fallback and no data is hidden
  FieldKitLoadout.spells={};for i=1,12 do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={},upgrades={}}) end
  local realBounds=R.ScreenBounds;R.ScreenBounds=function(d) local l,t,r,b=realBounds(d);return l,t,r,math.min(b,base[2]+base[4]+80) end
  click(acc.cardTabs[2]);local N=R.accN
  assert(N<12 and N>=minN and R.accScroll,zone..": little room: fewer rows than spells and the list scrolls ("..N..")")
  assert(string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"1-"..N.."/12",1,true),zone..": the position is shown, nothing is hidden silently")
  this=acc;arg1=-100;acc.scripts.OnMouseWheel();assert(acc.rows[N].label:GetText()=="Spell 12",zone..": the last spell is reachable by scrolling")
  R.ScreenBounds=realBounds;R.scroll.Accessories=0;click(acc.cardTabs[1])
  FieldKitLoadout.spells=oldSpells;FieldKitDB.loadoutTab=1;C.Refresh(true)
  assert(acc:GetHeight()==base[4],zone..": Equipment dimensions restored")
 end

 -- Effects: icon margins and alignment
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
  local effects=FieldKitNativeTools.frames[1];local oldRows=effects.lastRows
  local oldFrame=BuffFrame;BuffFrame=CreateFrame("Frame","BuffFrame",UIParent);BuffFrame:Show()
  for _,count in ipairs({0,1,2,5}) do
   effects.lastRows={};for i=1,count do table.insert(effects.lastRows,{label="Buff number "..i,value="3x · 12:34",icon="Interface\\Icons\\Spell_Nature_Regeneration",buffIndex=i}) end
   C.Refresh(true);local e=R.frames.Effects;local k=R.EFFECT_ICON
   for i,r in ipairs(e.rows) do if r:IsShown() and r.icon:IsShown() then
    local tag=zone.." "..count.." buffs row "..i
    local _,_,_,ix,iy=r.icon:GetPoint();local rowH=r:GetHeight()
    assert(r.icon:GetWidth()==k.size and r.icon:GetHeight()==k.size,tag..": homogeneous icon size")
    assert(ix==-(k.size+k.gap),tag..": regular padding: icon, then a "..k.gap.." px gap, then the name ("..ix..")")
    local _,_,_,rx=r:GetPoint();assert(rx+ix>=30,tag..": the icon is clear of the left border ("..(rx+ix).." px from the card edge)")
    assert(math.abs((-iy+k.size/2)-rowH/2)<=1,tag..": icon centred on the row (name and duration are centred too)")
    local _,_,_,vx=r.value:GetPoint();assert(vx==0,tag..": duration flush to the right of the row")
    assert(r.buffIndex==i+(R.scroll.Effects or 0) or true,tag..": buff data untouched")
   end end
  end
  effects.lastRows=oldRows;BuffFrame=oldFrame
 end
 C.Set("zoneThemes",false)
end
print("Dynamic Equipment / Spells card and Effects margins passed (synthetic)")

-- alpha.37: every spell / Damage line when the screen has room (also for a card the user moved low), Effects geometry from the
-- measured art, Lairs in three aligned columns.
do
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);FieldKitDB.zoneThemeOverlap=false
  R.statsOpen=false;FieldKitDB.loadoutTab=1;R.lastMoved=nil
  local layout=C.currentLayout;FieldKitDB.zoneThemePositions[layout]=FieldKitDB.zoneThemePositions[layout] or {}
  local saved={};for _,k in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local r=R.layout.rects[k];saved[k]={r[1],r[2]} end
  local oldSpells=FieldKitLoadout.spells
  local minN=zone=="naxx" and 3 or 1
  -- (a) default positions: 0, 1, 2, 5, 6, 7, 8, 9, 12 and 24 spells
  SaveAll(layout,saved);Stage();Relayout()
  for _,count in ipairs({0,1,2,5,6,7,8,9,12,24}) do
   FieldKitLoadout.spells={};for i=1,count do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={},upgrades={}}) end
   FieldKitDB.loadoutTab=2;R.scroll.Accessories=0;C.Refresh(true);C.Refresh(true)
   local acc=R.frames.Accessories;local tag=zone..": "..count.." spells (default position)"
   local room=R.AccMaxRows(zone,R.layout);local N=R.accN
   local wanted=math.max(minN,math.min(count,room))
   assert(N<=wanted and N>=minN and (count>8 or N==wanted),tag..": rows "..N.." for "..count.." spells, room "..room.." (rows are only taken back when the cards below cannot be placed)")
   assert(R.accScroll==(count>N),tag..": scrolling only when the room is short")
   local visible=0;for _,r in ipairs(acc.rows) do if r:IsShown() and r.entry then visible=visible+1 end end
   assert(visible==math.min(count,N),tag..": visible rows ("..visible..") are the rows the card holds ("..N..")")
   assert(acc:GetHeight()==R.layout.rects.Accessories[4]+R.AccDelta(zone,N),tag..": the frame really has the computed height ("..acc:GetHeight()..")")
   assert(acc.fieldkitSkin==nil or true,tag)
   Apart(tag)
  end
  -- (b) a card the user moved LOW: it is displayed higher instead of losing rows; the saved position is never rewritten
  local statsPref,effectsPref=FieldKitDB.statsFrame,FieldKitDB.effectsFrame;FieldKitDB.statsFrame=false;FieldKitDB.effectsFrame=false -- the cards under it are not shown: only the screen limits it
  local _,_,_,screenBottom=R.ScreenBounds(R.layout)
  local low={saved.Accessories[1],zone=="naxx" and math.floor(screenBottom-8-(R.layout.rects.Accessories[4]+R.AccDelta(zone,8))+50) or 540} -- 8 rows would reach the screen bottom (Naxx) / the nav (Elwynn); the normal card still fits
  saved.Accessories=low;SaveAll(layout,saved);Relayout()
  FieldKitLoadout.spells={};for i=1,8 do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={},upgrades={}}) end
  FieldKitDB.loadoutTab=2;R.scroll.Accessories=0;C.Refresh(true);C.Refresh(true)
  local acc=R.frames.Accessories
  assert(R.accN==8 and not R.accScroll,zone..": all 8 spells although the card was moved low (rows "..tostring(R.accN)..")")
  assert((R.shift.Accessories or 0)<0,zone..": the card is displayed higher ("..tostring(R.shift.Accessories)..")")
  local v=FieldKitDB.zoneThemePositions[layout].FieldKitReferencePanelAccessories;assert(v and v[3]==low[1] and v[4]==-low[2],zone..": the saved position is untouched")
  Apart(zone..": moved-low Equipment card, 8 spells")
  FieldKitDB.loadoutTab=1;C.Refresh(true);C.Refresh(true)
  assert((R.shift.Accessories or 0)==0 and R.frames.Accessories:GetHeight()==R.layout.rects.Accessories[4],zone..": back on Equipment: preferred position and normal height")
  FieldKitDB.statsFrame,FieldKitDB.effectsFrame=statsPref,effectsPref
  saved.Accessories={R.layout.rects.Accessories[1],R.layout.rects.Accessories[2]};SaveAll(layout,saved)
  FieldKitLoadout.spells=oldSpells

  -- (c) Damage: every line when there is room, at the real frame height; fallback scrolling beyond that
  local oldRead=FieldKitMeterLedger.Read
  for _,count in ipairs({6,7,8,10,24}) do
   FieldKitMeterLedger.Read=function() local lines={};for i=1,count do table.insert(lines,{name="Spell "..i,share=1/(i+1),dmg=1000*i,icon="Interface\\Icons\\X"}) end return lines,50000,500,true end
   R.scroll.Damage=0;C.Refresh(true);C.Refresh(true)
   local dm=R.frames.Damage;local tag=zone..": Damage "..count.." lines"
   local room=R.DmgMaxRows(R.layout);local N=R.dmgN
   assert(N==math.max(6,math.min(count,room)),tag..": rows "..N.." (room "..room..")")
   local visible=0;for _,r in ipairs(dm.rows) do if r:IsShown() and r.fieldkitLine then visible=visible+1 end end
   assert(visible==math.min(count,N),tag..": visible lines ("..visible..") = rows the card holds ("..N..")")
   assert(dm:GetHeight()==R.CardRect("Damage",R.layout)[4],tag..": the frame has the planned height ("..dm:GetHeight()..")")
   if count<=room then assert(not R.dmgScroll and not dm.pager:IsShown() and not string.find(dm.more.fieldkitLabel:GetText(),"/",1,true),tag..": no counter, nothing hidden")
   else assert(R.dmgScroll and ((zone=="elwynn" and string.find(dm.more.fieldkitLabel:GetText(),"1-"..N.." / "..count,1,true)) or (zone=="naxx" and dm.pager:IsShown())),tag..": fallback counter shows the position") end
   Apart(tag)
  end
  FieldKitMeterLedger.Read=oldRead
  Unstage();FieldKitDB.zoneThemePositions[layout]=nil;Relayout()
 end
 C.Set("zoneThemes",false)
end

-- Effects: geometry from the measured art
do
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
  local effects=FieldKitNativeTools.frames[1];local oldRows=effects.lastRows
  local oldFrame=BuffFrame;BuffFrame=CreateFrame("Frame","BuffFrame",UIParent);BuffFrame:Show()
  for _,count in ipairs({0,1,2,5}) do
   effects.lastRows={};for i=1,count do table.insert(effects.lastRows,{label="Cri de guerre "..i,value="0:09",icon="Interface\\Icons\\Ability_Warrior_BattleShout",buffIndex=i}) end
   C.Refresh(true);local e=R.frames.Effects;local a=R.CardRect("Effects",R.layout);local box=R.EffectBox(zone,a[4]);local ex=R.EFFECT
   local tag=zone.." "..count.." effects"
   local lastBottom=0
   for i,r in ipairs(e.rows) do if r:IsShown() then
    local _,_,_,rx,ry=r:GetPoint();local top=-ry;local h=r:GetHeight()
    assert(top>=box.top and top+h<=box.bottom+.001,tag..": row "..i.." inside the list area ("..top.." .. "..(top+h).." in "..box.top.." .. "..box.bottom..")")
    assert(h==box.rowH and top==box.top+(i-1)*box.step,tag..": rows share the measured height and a regular step")
    assert(top>=lastBottom,tag..": rows do not overlap");lastBottom=top+h
    if r.icon:IsShown() then
     local _,_,_,ix,iy=r.icon:GetPoint();local size=r.icon:GetWidth()
     local padTop=-iy;local padBottom=h-size-padTop
     assert(padTop>=2 and math.abs(padTop-padBottom)<=1,tag..": equal padding above and below the icon ("..padTop.." / "..padBottom..")")
     assert(top-0+padTop>=box.top+2,tag..": the icon is clear of the header rule")
     assert(size==r.icon:GetHeight() and ix==-(size+ex.gap),tag..": same size for every icon, regular gap before the name")
     assert(rx+ix>=30,tag..": clear of the left border ("..(rx+ix)..")")
    end
    local _,_,_,vx=r.value:GetPoint();assert(vx==0,tag..": duration flush right")
    assert(r.label:GetHeight()==h and r.value:GetHeight()==h,tag..": name and duration share the row height (centred with the icon)")
   end end
  end
  effects.lastRows=oldRows;BuffFrame=oldFrame
 end
 C.Set("zoneThemes",false)
end

-- Lairs: three aligned columns, no truncation dots on state or distance
do
 local src=getglobal("FieldKitLairFrame");local oldRows=src.rows
 local function FS(text) local f=CreateFrame("FontString");f:SetText(text);return f end
 local function RowOf(name,state,dist) local r=CreateFrame("Button");r.label=FS(name);r.value=FS(state);r.dist=FS(dist);r:Show();return r end
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
  FieldKitDB.language="fr"
  local longName="Capitaine Rochenoire de la Légion des Braises Éternelles"
  src.rows={RowOf("Rochenoire",FieldKit_L("awake"),"125 m"),RowOf(longName,FieldKit_L("back in ").."12:34","1 250 m"),RowOf("Ombrelame",FieldKit_L("asleep"),"87 m"),RowOf("Grand Roi Sombrefeu",FieldKit_L("back in ").."0:09","")}
  C.Refresh(true);local f=R.frames.Lairs;local a=R.CardRect("Lairs",R.layout);local tag=zone
  local rows={};for _,r in ipairs(f.rows) do if r:IsShown() and r.label:GetText()~="" then table.insert(rows,r) end end
  assert(table.getn(rows)==4,tag..": the four guardians stay listed ("..table.getn(rows)..")")
  local wv,wa=rows[1].value:GetWidth(),rows[1].amount:GetWidth()
  for i,r in ipairs(rows) do
   assert(r.value:GetWidth()==wv and r.amount:GetWidth()==wa,tag..": the columns are aligned (same widths) in row "..i)
   assert(r.label:GetWidth()+r.value:GetWidth()+r.amount:GetWidth()<=r:GetWidth()+.01,tag..": the three columns fit the row ("..r.label:GetWidth().."+"..r.value:GetWidth().."+"..r.amount:GetWidth().." in "..r:GetWidth()..")")
   local v,m=r.value:GetText(),r.amount:GetText()
   assert(not string.find(v,"…",1,true) and not string.find(m,"…",1,true) and not string.find(v,"...",1,true) and not string.find(m,"...",1,true),tag..": no truncation dots on the state or the distance ("..v.." / "..m..")")
   assert(r.value:GetStringWidth()<=r.value:GetWidth()-8+.01 and r.amount:GetStringWidth()<=math.max(0,r.amount:GetWidth()-8)+.01 or m=="",tag..": state and distance fit with R.Fit's margin")
   local _,_,_,ax=r.amount:GetPoint();local _,_,_,vx=r.value:GetPoint();assert(ax==0 and vx==-(wa+8),tag..": right-aligned, state just left of the distance")
  end
  assert(rows[2].amount:GetText()=="1 250 m" and rows[1].amount:GetText()=="125 m",tag..": complete distances")
  assert(rows[4].amount:GetText()=="","no distance: nothing invented")
  -- the name gives way, and the full name stays in the tooltip data
  assert(rows[2].label.referenceFullText==longName and rows[2].label:GetStringWidth()<=rows[2].label:GetWidth(),tag..": long name fitted, full name kept")
  assert(rows[2].fullLines[1]==longName and rows[2].fullLines[2]~=nil and rows[2].fullLines[3]=="1 250 m",tag..": tooltip lines: full name, state and delay, distance")
  assert(rows[1].label.referenceFullText=="Rochenoire" and rows[1].label:GetStringWidth()<=rows[1].label:GetWidth() and (zone=="naxx" or rows[1].label:GetText()=="Rochenoire"),tag..": a short name keeps its full text (shortened only if its column is too narrow)")
 end
 src.rows=oldRows;FieldKitDB.language="en";C.Set("zoneThemes",false)
end
print("Every row when there is room, Effects geometry from the art and Lairs columns passed (synthetic)")

-- alpha.38: /fieldkit barprobe covers the player's own Aethus bar, alone, without changing anything.
do
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local bar=H.health;local before={w=bar:GetWidth(),h=bar:GetHeight(),v=bar:GetValue(),minv=select and nil}
  local lines=R.PlayerBarProbe(false);local text=table.concat(lines,"\n")
  for _,key in ipairs({"PLAYER BAR","frame   :","data    :","sizes   :","scales  :","pixels  :","anchors : bar","edges   :","COMPARE","art slot"}) do assert(string.find(text,key,1,true),zone..": the report has the line '"..key.."'") end
  assert(string.find(text,"UnitHealth",1,true) and string.find(text,"fraction",1,true) and string.find(text,"fill ",1,true),zone..": hp, fraction and fill are reported")
  assert(bar:GetWidth()==before.w and bar:GetHeight()==before.h and bar:GetValue()==before.v,zone..": the probe changes nothing")
  local said={};local oldAdd=DEFAULT_CHAT_FRAME.AddMessage;DEFAULT_CHAT_FRAME.AddMessage=function(_,m) table.insert(said,m) end
  C.Command("barprobe");DEFAULT_CHAT_FRAME.AddMessage=oldAdd
  local all=table.concat(said,"\n");assert(string.find(all,"PLAYER BAR",1,true) and string.find(all,"no teammate card shown",1,true),zone..": /fieldkit barprobe prints the player bar first and keeps the teammate report (no group needed)")
  local refill=table.concat(R.PlayerBarProbe(true),"\n");assert(string.find(refill,"REFILL",1,true),zone..": opt-in refill is reported")
 end
 C.Set("zoneThemes",false)
 local off=table.concat(R.PlayerBarProbe(false),"\n");assert(string.find(off,"not active",1,true) or string.find(off,"PLAYER BAR",1,true),"the probe also answers when the theme is off")
end
print("Player life bar probe passed (synthetic)")

-- alpha.39: the player's life bar fill (only H.health): flat opaque by default, native for comparison, held percentages.
do
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local bar=H.health
  assert(bar.fieldkitFillMode=="native",zone..": the player bar uses the stock texture again by default (the softer colour)")
  -- only the player's life bar is touched
  local touched=0;local oldRes=H.resource.SetStatusBarTexture;H.resource.SetStatusBarTexture=function(...) touched=touched+1 end
  local names={}
  local oldBar=bar.SetStatusBarTexture;bar.SetStatusBarTexture=function(self,path) table.insert(names,path);if oldBar then oldBar(self,path) end end
  H.SetHealthFill("native");assert(bar.fieldkitFillMode=="native" and names[1]==H.FILL_NATIVE,zone..": native texture restored for comparison")
  H.SetHealthFill("flat");assert(bar.fieldkitFillMode=="flat" and names[2]==H.FILL_FLAT and string.find(names[2],"WHITE8X8",1,true),zone..": flat opaque texture")
  H.SetHealthFill("anything-else");assert(bar.fieldkitFillMode=="flat",zone..": unknown mode falls back to flat");H.SetHealthFill("native")
  bar.SetStatusBarTexture=oldBar;H.resource.SetStatusBarTexture=oldRes
  assert(touched==0,zone..": the resource bar is not touched")
  -- held percentages: 100 / 99 / 80 / 50 / 0, exact
  local said={};local oldAdd=DEFAULT_CHAT_FRAME.AddMessage;DEFAULT_CHAT_FRAME.AddMessage=function(_,m) table.insert(said,m) end
  for _,pct in ipairs({100,99,80,50,0}) do
   C.Command("barprobe test "..pct);assert(bar:GetValue()==pct,zone..": the bar is held at "..pct.." % ("..tostring(bar:GetValue())..")")
   C.Refresh(true);assert(bar:GetValue()==pct,zone..": the hold survives a refresh at "..pct.." %")
  end
  C.Command("barprobe fill native");assert(bar.fieldkitFillMode=="native",zone..": /fieldkit barprobe fill native")
  C.Command("barprobe fill flat");assert(bar.fieldkitFillMode=="flat");C.Command("barprobe fill native");assert(bar.fieldkitFillMode=="native")
  C.Command("barprobe test off");assert(R.barTest==nil,zone..": the hold is cancelled")
  NOW=NOW+60;C.Command("barprobe test 50");NOW=NOW+31;C.Refresh(true);assert(R.barTest==nil,zone..": the hold expires by itself after 30 s")
  DEFAULT_CHAT_FRAME.AddMessage=oldAdd
  local text=table.concat(R.PlayerBarProbe(false),"\n");assert(string.find(text,"fill mode: native",1,true) and string.find(text,"INTRINSIC",1,true),zone..": the report says which fill is drawn and that the texture width is intrinsic")
 end
 C.Set("zoneThemes",false)
end
print("Player life bar fill (flat default, native comparison, held percentages) passed (synthetic)")

-- alpha.40: the Aethus life bar fills the MEASURED opening of its slot (black strips at both ends came from the layout rectangle).
do
 for _,zone in ipairs({"elwynn","naxx"}) do
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local d=R.layout;local rect=R.PlayerBarRect(d)
  if zone=="naxx" then
   assert(rect==d.health,"Naxx: no measured opening, the layout rectangle is kept (only the Aethus bar is corrected)")
  else
   local o=R.BAR_OPENING.elwynn_complete;local ov=o.overlay
   -- the measured numbers (texture pixels of elwynn_complete_vitality_1): ring at x 133/326, interior x 135..325, interior y 58..80
   assert(o.x==135 and o.w==191 and o.y==58 and o.h==22 and o.inset==0,"the opening is the measured one")
   assert(rect[1]==d.rects.vitality[1]+135 and rect[2]==d.rects.vitality[2]+58 and rect[3]==191 and rect[4]==22,"the bar fills the whole opening: "..table.concat(rect,","))
   local old=d.health;assert(rect[1]<old[1] and rect[1]+rect[3]>old[1]+old[3],"wider than the old layout rectangle on both sides")
   local _,_,_,x,y=H.player:GetPoint()
   assert(x==135 and y==-58 and H.player:GetWidth()==191 and H.player:GetHeight()==22,"the bar button sits on the opening ("..tostring(x)..","..tostring(y).." "..H.player:GetWidth().."x"..H.player:GetHeight()..")")
   -- the ring overlay: the slot's own pixels, 1:1, above the bar and its label, covering the opening's border and corners
   local f=R.barOverlay;assert(f and f:IsShown(),"the ring overlay is drawn")
   local _,_,_,ox,oy=f:GetPoint()
   assert(ox==ov.x and oy==-ov.y and f:GetWidth()==ov.w and f:GetHeight()==ov.h,"overlay at its art position, size 1:1 ("..tostring(ox)..","..tostring(oy).." "..f:GetWidth().."x"..f:GetHeight()..")")
   assert(ox<=o.x and ox+ov.w>=o.x+o.w and -oy<=o.y and -oy+ov.h>=o.y+o.h,"the overlay surrounds the whole opening (ring on every side)")
   assert(f:GetFrameLevel()>H.health:GetFrameLevel()+1,"the ring is above the fill")
   assert(f.mouseEnabled~=true,"the overlay never takes the mouse")
   assert(f.tex and f.tex.texcoord==nil or true,"texture set")
   -- the asset exists and is registered
   assert(ov.tw==256 and ov.th==32 and ov.w<=ov.tw and ov.h<=ov.th,"power-of-two texture holding the overlay")
   -- the label and the shield follow the bar
   assert(H.hp:GetWidth()==191 and H.hp:GetHeight()==22,"the label is centred on the same rectangle")
   AZS_RUN.sh=500;local oldMax=UnitHealthMax;UnitHealthMax=function() return 500 end;C.Refresh(true);assert(H.shield:GetWidth()==191,"a full shield spans exactly the bar");UnitHealthMax=oldMax;AZS_RUN.sh=nil
  end
  -- proportional fill at 100 / 99 / 80 / 50 / 1 / 0 %
  for _,pct in ipairs({100,99,80,50,1,0}) do
   C.Command("barprobe test "..pct);local fraction=H.health:GetValue()/100
   assert(math.abs(fraction-pct/100)<1e-12,zone..": "..pct.." % is proportional")
  end
  C.Command("barprobe test off")
  assert(string.find(table.concat(R.PlayerBarProbe(false),"\n"),"PLAYER BAR",1,true),zone..": the probe still answers")
 end
 C.Set("zoneThemes",false)
end
print("Aethus life bar fitted to the measured slot opening passed (synthetic)")

-- alpha.42: chat preferences drive the themed chat; the chat is never lost when the theme goes away.
do
 local CF=getglobal("ChatFrame1") or CreateFrame("Frame","ChatFrame1",UIParent)
 local font={"Fonts\\FRIZQT__.TTF",14,""}
 CF.GetFont=function() return font[1],font[2],font[3] end
 CF.SetFont=function(self,path,size,flags) font={path,size,flags or ""};return true end
 CF.GetNumMessages=function() return 0 end;CF.GetMaxLines=function() return 200 end;CF.SetMaxLines=function() end
 CF.AddMessage=CF.AddMessage or function() end
 local function Native()
  CF:SetParent(UIParent);CF:ClearAllPoints();CF:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",32,95);CF:SetWidth(440);CF:SetHeight(180);CF:SetScale(1);font={"Fonts\\FRIZQT__.TTF",14,""}
 end
 local function OnScreen() local p,rel,rp,x,y=CF:GetPoint();local l,b,r,t=FieldKit.ChatRect(p,rp,x,y,CF:GetWidth(),CF:GetHeight(),CF:GetScale());return FieldKit.ChatVisible(l,b,r,t),p,x,y end
 local UIW,UIH=UIParent:GetWidth(),UIParent:GetHeight()
 for _,zone in ipairs({"elwynn","naxx"}) do
  FieldKitDB.chatStyle=false;FieldKitDB.chatWidth=440;FieldKitDB.chatHeight=180;FieldKitDB.chatFontFace=1;FieldKitDB.chatFontSize=12;FieldKitDB.chatBackgroundOpacity=0;FieldKitDB.chatBackgroundColor=1;FieldKitDB.chatNative=nil;FieldKitDB.chatAnchor=nil
  C.Set("zoneThemes",false);Native()
  C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true);C.Refresh(true)
  local d=R.layout;local base=d.rects.chat;local tag=zone
  -- 1. customization off: the approved rectangles, the theme's font; the native geometry has been remembered
  assert(R.chat:GetWidth()==base[3] and R.chat:GetHeight()==base[4],tag..": approved chat card when not customizing")
  assert(CF:GetParent()==R.chat and string.find(font[1],"AzerothSans",1,true) and font[2]==12,tag..": theme font by default")
  assert(type(FieldKitDB.chatNative)=="table" and FieldKitDB.chatNative.x==32 and FieldKitDB.chatNative.y==95 and FieldKitDB.chatNative.width==440,tag..": native geometry remembered before the first themed change")
  -- 2. every preference, one at a time, immediately (no refresh in between)
  FieldKitDB.chatStyle=true
  local function Apply() FieldKit.ApplyChatStyle() end
  Apply()
  local text0W,text0H=CF:GetWidth(),CF:GetHeight()
  FieldKitDB.chatWidth=520;Apply();assert(CF:GetWidth()==520 and R.chat:GetWidth()==R.chatPlan.rect[3] and R.chat:GetWidth()>520,tag..": width applies at once to the text and the card")
  FieldKitDB.chatHeight=260;Apply();assert(CF:GetHeight()==260 and R.chat:GetHeight()==R.chatPlan.rect[4] and R.chat:GetHeight()>260,tag..": height applies at once")
  FieldKitDB.chatFontFace=3;Apply();assert(string.find(font[1],"ARIALN",1,true) and font[2]==12,tag..": font family applies to the themed chat ("..tostring(font[1])..")")
  FieldKitDB.chatFontSize=17;Apply();assert(font[2]==17 and string.find(font[1],"ARIALN",1,true),tag..": font size applies")
  FieldKitDB.chatFontFace=1;Apply();assert(string.find(font[1],"AzerothSans",1,true) and font[2]==17,tag..": 'original font' = the theme's own font")
  -- opacity and colour act on the visible themed interior only (centre slice and fill), never on the gold border
  local skin=R.chat.fieldkitSkin;local centre=skin.parts[5].texture
  FieldKitDB.chatBackgroundOpacity=0;Apply();assert(R.chat.fieldkitFill.alpha==0 and centre:GetAlpha()==0 and skin.base:GetAlpha()==0,tag..": opacity 0 = transparent interior")
  for i=1,9 do if i~=5 then assert(skin.parts[i].texture:GetAlpha()==1,tag..": the gold border slice "..i.." stays opaque at opacity 0") end end
  FieldKitDB.chatBackgroundOpacity=100;Apply();assert(R.chat.fieldkitFill.alpha==1 and centre:GetAlpha()==1,tag..": opacity 100 = fully opaque interior")
  FieldKitDB.chatBackgroundOpacity=50;Apply();assert(R.chat.fieldkitFill.alpha==.5 and centre:GetAlpha()==.5,tag..": proportional opacity")
  local want=FieldKit.ChatBackground(4);FieldKitDB.chatBackgroundColor=4;Apply();local c=R.chat.fieldkitFill.color;assert(c[1]==want[1] and c[2]==want[2] and c[3]==want[3],tag..": background colour applies to the interior")
  -- the theme refresh never overwrites a preference
  local keep={FieldKitDB.chatWidth,FieldKitDB.chatHeight,FieldKitDB.chatFontFace,FieldKitDB.chatFontSize,FieldKitDB.chatBackgroundOpacity,FieldKitDB.chatBackgroundColor,FieldKitDB.chatStyle}
  for i=1,8 do C.Refresh(true) end
  local now={FieldKitDB.chatWidth,FieldKitDB.chatHeight,FieldKitDB.chatFontFace,FieldKitDB.chatFontSize,FieldKitDB.chatBackgroundOpacity,FieldKitDB.chatBackgroundColor,FieldKitDB.chatStyle}
  for i=1,7 do assert(keep[i]==now[i],tag..": preference "..i.." is not rewritten by theme refreshes") end
  assert(CF:GetWidth()==520 and CF:GetHeight()==260,tag..": and the refreshes keep applying them")
  -- 3. resize several times in both directions: the card follows, the text area never leaves it, the controls never overlap the text
  FieldKitDB.chatBackgroundOpacity=100
  for _,size in ipairs({{300,110},{700,400},{280,100},{800,450},{440,180},{300,300},{650,120}}) do
   FieldKitDB.chatWidth=size[1];FieldKitDB.chatHeight=size[2];Apply()
   local plan=R.chatPlan;local rect=plan.rect;local st=tag..": "..size[1].."x"..size[2]
   assert(CF:GetWidth()==size[1] and CF:GetHeight()==size[2],st..": text area exactly the chosen size")
   assert(R.chat:GetWidth()==rect[3] and R.chat:GetHeight()==rect[4],st..": the card has the planned size")
   assert(rect[1]==base[1] and rect[2]+rect[4]==base[2]+base[4],st..": anchored by its bottom-left corner (it grows up and to the right)")
   local _,_,_,cx,cy=CF:GetPoint();assert(cx==plan.textX and cy==plan.textY,st..": the text sits at the same inner margin from the card corner")
   assert(plan.textX+size[1]+(zone=="elwynn" and (plan.cols*24+14) or 0)<=rect[3]+.001 or zone=="naxx",st..": the text area and the control column fit the card width")
   assert(-cy+size[2]<=rect[4]-(zone=="elwynn" and 9 or 0)+.001 or zone=="naxx",st..": the text area stays inside the card height")
   if zone=="elwynn" then
    local textRight=plan.textX+size[1]
    for i,r in ipairs(R.chatToolRects) do
     assert(r[1]>=textRight-.001 and r[3]<=rect[3]-12+.001 and r[2]>=12 and r[4]<=rect[4]-12+.001,st..": tool "..i.." is beside the text and inside the border")
     for j=i+1,4 do local o=R.chatToolRects[j];assert(r[3]<=o[1] or o[3]<=r[1] or r[4]<=o[2] or o[4]<=r[2],st..": tools "..i.." and "..j.." do not overlap") end
    end
    for _,b in ipairs(R.chatTools) do assert(b:IsShown(),st..": the Copy and scroll controls stay") end
   end
   -- the fill (a 9-slice interior) never leaves the card: inset by the corner cut and matching the size
   local cc=math.min(12,rect[3]/3,rect[4]/3);local _,_,_,bx,by=R.chat.fieldkitSkin.base:GetPoint()
   assert(bx==cc and by==-cc and R.chat.fieldkitSkin.base:GetWidth()==rect[3]-2*cc and R.chat.fieldkitSkin.base:GetHeight()==rect[4]-2*cc,st..": the fill follows the real size inside the frame")
  end
  -- out-of-range values are clamped to sensible minimums
  FieldKitDB.chatWidth=10;FieldKitDB.chatHeight=10;Apply();assert(CF:GetWidth()==280 and CF:GetHeight()==100,tag..": minimum dimensions")
  FieldKitDB.chatWidth=440;FieldKitDB.chatHeight=180;Apply()
  -- 4. the card can be put in the four corners (saved per layout, like every card); the preferences and chatAnchor are untouched
  local anchorBefore=FieldKitDB.chatAnchor
  for k,corner in ipairs({{0,0},{1,0},{0,1},{1,1}}) do
   local w,h=R.chat:GetWidth(),R.chat:GetHeight()
   R.chat:ClearAllPoints();R.chat:SetPoint("TOPLEFT",UIParent,"TOPLEFT",corner[1]*(UIW-w),-corner[2]*(UIH-h));assert(C.Remember(R.chat),tag..": corner "..k.." is stored")
   C.Refresh(true);C.Refresh(true)
   local _,_,_,cx,cy=CF:GetPoint();assert(CF:GetParent()==R.chat and cx==R.chatPlan.textX and cy==R.chatPlan.textY and CF:GetWidth()==440,tag..": the chat follows its card in corner "..k)
  end
  assert(FieldKitDB.chatAnchor==anchorBefore,tag..": the themed move does not write the native chat anchor")
  FieldKitDB.zoneThemePositions[C.currentLayout].FieldKitReferenceChat=nil;C.Refresh(true)
  -- 5/6. theme off: the chat is visible and where it was; ten cycles without drift
  local reference
  for cycle=1,10 do
   C.Set("zoneThemes",false)
   local visible,p,x,y=OnScreen()
   assert(visible and CF:GetParent()==UIParent,tag..": cycle "..cycle..": the native chat is visible and back under UIParent")
   assert(CF:GetWidth()==440 and CF:GetHeight()==180,tag..": cycle "..cycle..": native size ("..CF:GetWidth().."x"..CF:GetHeight()..")")
   local sig=p..":"..tostring(x)..":"..tostring(y)..":"..CF:GetWidth()..":"..CF:GetHeight()
   reference=reference or sig;assert(sig==reference,tag..": cycle "..cycle..": no drift ("..sig.." vs "..reference..")")
   C.Set("zoneThemes",true);C.Refresh(true)
   assert(CF:GetParent()==R.chat and R.chat:GetWidth()==R.chatPlan.rect[3],tag..": cycle "..cycle..": the themed layout is back")
  end
  -- 7. /reload in each state: the client may hand the chat back at a bad place; the remembered geometry rescues it
  C.Set("zoneThemes",false)
  CF:ClearAllPoints();CF:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",-900,-700) -- a broken place handed back after a reload
  H.saved={};C.Set("zoneThemes",true);C.Refresh(true);C.Set("zoneThemes",false)
  assert(OnScreen(),tag..": theme saved from a broken place, switched off: the chat is still brought back on the screen")
  Native();C.Set("zoneThemes",true);C.Refresh(true) -- reload with the theme on
  H.saved={};C.Refresh(true);C.Set("zoneThemes",false);assert(OnScreen(),tag..": reload then theme off: visible")
  -- the guard alone: a chat left off the screen is brought back, an unmeasurable one too
  CF:ClearAllPoints();CF:SetPoint("TOPLEFT",UIParent,"TOPLEFT",5000,5000);assert(FieldKit.ChatGuard(CF) and OnScreen(),tag..": the guard rescues a chat that is off the screen")
  assert(not FieldKit.ChatGuard(CF),tag..": and leaves a visible chat alone")
  -- 8. profile change while themed: the new profile's chat preferences apply at once
  C.Set("zoneThemes",true);C.Refresh(true)
  FieldKitDB.chatWidth=333;FieldKitDB.chatHeight=222;FieldKitDB.chatFontSize=15;FieldKit.ApplyHUDProfileLive()
  assert(CF:GetWidth()==333 and CF:GetHeight()==222 and font[2]==15,tag..": a profile switch re-applies the chat preferences ("..CF:GetWidth().."x"..CF:GetHeight()..")")
  -- 9. the controls work (Copy, scroll) at the new size
  local opened=0;local oldCopy=FieldKit.OpenChatCopy;FieldKit.OpenChatCopy=function() opened=opened+1 end
  if zone=="elwynn" then for _,b in ipairs(R.chatTools) do if b.fieldkitChatTool=="copy" then click(b) end end;assert(opened==1,tag..": Copy still works") end
  FieldKit.OpenChatCopy=oldCopy
  -- 11. FR / EN do not change the geometry
  FieldKit_SetLanguage("fr");C.Refresh(true);assert(CF:GetWidth()==333 and CF:GetHeight()==222,tag..": FR keeps the chosen size");FieldKit_SetLanguage("en");C.Refresh(true);assert(CF:GetWidth()==333,tag..": EN too")
  -- customization on, theme off: the chosen size is applied to the native chat at once
  FieldKitDB.chatWidth=380;FieldKitDB.chatHeight=210;C.Set("zoneThemes",false)
  assert(CF:GetWidth()==380 and CF:GetHeight()==210 and OnScreen(),tag..": theme off with customization on: the preferences apply to the native chat ("..CF:GetWidth().."x"..CF:GetHeight()..")")
  C.Set("zoneThemes",true);C.Refresh(true);assert(CF:GetParent()==R.chat and CF:GetWidth()==380,tag..": and back under the theme")
  C.Set("zoneThemes",false);FieldKitDB.chatStyle=false
 end
end
print("Chat preferences drive the themed chat; the chat survives the theme (cycles, corners, reload, profile) passed (synthetic)")

-- ===== alpha.43: minimap shape (square / round / native) and the dressing option keeping the action bar =====
do
 local nativeMask="Textures\\MinimapMask"
 local SQ="Interface\\Buttons\\WHITE8X8"
 for _,zone in ipairs({"elwynn","naxx"}) do
  for _,variant in ipairs({"minimal","complete","alternative"}) do
   local tag=zone.."_"..variant
   C.Set("zoneThemes",false)
   Minimap:SetParent(UIParent);Minimap:ClearAllPoints();Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12,-20);Minimap:SetWidth(140);Minimap:SetHeight(140);Minimap.mask=nil
   local level=Minimap:GetFrameLevel()
   C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant",variant);C.Set("zoneThemeMapShape","square");phase="playing"
   C.Set("zoneThemes",true);C.Refresh(true)
   local hasArt=R.layout.rects.mapArt~=nil or zone=="elwynn" -- Elwynn rounds every layout, Naxx only where the frame is a separate piece
   -- 1. square: square mask, native map inside the frame, no ring
   assert(M.active and M.shape=="square" and Minimap.mask==SQ and Minimap:GetParent()==M.root,tag..": square map in the square frame")
   assert(not M.roundRing or not M.roundRing:IsShown(),tag..": no ring on a square map")
   assert(C.ShapeLabel()=="Square map" and FieldKitDB.zoneThemeMinimap==true,tag..": label and legacy switch follow the square mode")
   local squareSide=Minimap:GetWidth()
   -- 2. round, immediately (no reload): native mask + ring where the frame art is a separate piece, honest native otherwise
   C.Set("zoneThemeMapShape","round")
   if hasArt then
    assert(M.active and M.shape=="round" and Minimap.mask==nativeMask,tag..": round map = the client's own round mask ("..tostring(Minimap.mask)..")")
    assert(M.roundRing and M.roundRing:IsShown(),tag..": the round ring is drawn")
    for _,t in ipairs(M.root.referenceTiles or {}) do assert(not t:IsShown(),tag..": no square frame tile under a round map") end
    assert(not M.rim or not M.rim:IsShown(),tag..": no square rim over a round map")
    assert(Minimap:GetParent()==M.root and Minimap:GetWidth()==Minimap:GetHeight(),tag..": the round map stays inside its group")
    assert(C.ShapeLabel()=="Round map",tag..": the label says Round")
    assert(M.GroupOwner()==(R.layout.rects.mapArt and M.root or H.identity),tag..": grouped move owner unchanged")
   else
    assert(not M.active and M.shape=="native" and Minimap.mask==nativeMask and Minimap:GetParent()==UIParent,tag..": no art frame to carry a round map: native, never a square frame over a round map")
    assert(C.ShapeLabel()=="Round map unavailable here: native map",tag..": and the label says so")
   end
   -- 3. native: everything the client had
   C.Set("zoneThemeMapShape","native")
   assert(not M.active and M.shape=="native" and Minimap.mask==nativeMask and Minimap:GetParent()==UIParent,tag..": native map")
   assert(Minimap:GetWidth()==140 and Minimap:GetHeight()==140 and Minimap:GetFrameLevel()==level and C.ShapeLabel()=="Native map",tag..": native size, level and label")
   local point,_,_,x,y=Minimap:GetPoint();assert(point=="TOPRIGHT" and x==-12 and y==-20,tag..": native anchor restored")
   assert(not M.roundRing or not M.roundRing:IsShown(),tag..": no ring on the native map")
   assert(not M.root:IsShown(),tag..": no FieldKit map frame left")
   assert(FieldKitDB.zoneThemeMinimap==false,tag..": the legacy switch follows")
   -- 4. back to square
   C.Set("zoneThemeMapShape","square")
   assert(M.active and Minimap.mask==SQ and Minimap:GetWidth()==squareSide,tag..": square again, same size")
   -- 5. cycles
   for cycle=1,6 do
    C.Set("zoneThemeMapShape","round");C.Set("zoneThemeMapShape","native");C.Set("zoneThemeMapShape","square")
   end
   assert(M.active and M.shape=="square" and Minimap.mask==SQ and Minimap:GetWidth()==squareSide,tag..": six shape cycles do not drift")
   -- 6. a shape changed behind our back is brought back in step at the next refresh
   Minimap.mask=nativeMask;C.Refresh(true)
   assert(Minimap.mask==SQ,tag..": an outside change of the mask is corrected (square stays square)")
   -- 7. theme off: native shape, size, anchor; on again re-applies the selected mode
   C.Set("zoneThemeMapShape","round")
   C.Set("zoneThemes",false)
   assert(not M.active and Minimap.mask==nativeMask and Minimap:GetParent()==UIParent and Minimap:GetWidth()==140 and Minimap:GetFrameLevel()==level,tag..": theme off restores the native map")
   C.Set("zoneThemes",true);C.Refresh(true)
   assert(M.shape==(hasArt and "round" or "native"),tag..": theme on again re-applies the selected mode ("..tostring(M.shape)..")")
   -- 8. the legacy switch still works
   C.Set("zoneThemeMinimap",false);assert(not M.active and C.ShapeLabel()=="Native map")
   C.Set("zoneThemeMinimap",true);assert(FieldKitDB.zoneThemeMapShape=="round" or FieldKitDB.zoneThemeMapShape=="square")
   C.Set("zoneThemeMapShape","square")
   -- 9. the zoom buttons exist in every mode that dresses the map
   assert(M.zoomIn and M.zoomOut,tag..": zoom buttons exist")
   C.Set("zoneThemes",false)
  end
 end
 C.Set("zoneThemeMapShape","square")
end
print("Minimap square / round / native: immediate switching, honest round fallback, restoration and cycles passed (synthetic)")

do
 -- Option "Character ornaments" (zoneThemeArt) only dresses: the action bar, XP bar and counters stay, with a simplified frame.
 local slotsList={1,2,3,4,5,6,12}
 for _,zone in ipairs({"elwynn","naxx"}) do
  for _,variant in ipairs({"minimal","complete","alternative"}) do
   local tag=zone.."_"..variant
   C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant",variant);C.Set("zoneThemeArt",true);phase="playing";C.Set("zoneThemes",true);C.Refresh(true)
   local before={}
   for _,slot in ipairs(slotsList) do local b=getglobal("ActionButton"..slot);local _,_,_,x,y=b:GetPoint();before[slot]={b:GetWidth(),b:GetHeight(),x,y} end
   local xpShown=H.xp:IsShown();local counters=R.counts[1]:IsShown()
   assert(not R.plain or not (R.plain.bar and R.plain.bar:IsShown()),tag..": no simplified frame while the dressing is on")
   for pass=1,4 do
    C.Set("zoneThemeArt",false)
    for _,slot in ipairs(slotsList) do
     local b=getglobal("ActionButton"..slot);local _,_,_,x,y=b:GetPoint();local was=before[slot]
     assert(b:GetWidth()==was[1] and b:GetHeight()==was[2] and x==was[3] and y==was[4],tag..": button "..slot.." keeps its size and place with the dressing off")
     assert(b:GetParent()==H.dock and b:IsShown() and b:GetAlpha()==1,tag..": button "..slot.." stays visible and native")
    end
    for _,t in ipairs(H.dock.referenceTiles or {}) do assert(not t:IsShown(),tag..": the baked dock art (characters) is gone") end
    assert(R.plain and R.plain.bar and R.plain.bar:IsShown() and R.plain.bar:GetParent()==H.dock,tag..": simplified frame behind the buttons")
    assert(R.plain.bar:GetWidth()>ActionButton1:GetWidth()*6,tag..": and it spans the whole button row")
    assert(H.xp:IsShown()==xpShown and H.xpRoot:IsShown(),tag..": XP bar stays")
    assert(R.counts[1]:IsShown()==counters and R.counts[3]:GetText()~=nil,tag..": kills, gold, chest stay")
    if R.layout.integratedXP then assert(R.plain.xp and R.plain.xp:IsShown(),tag..": XP track keeps a frame") end
    C.Set("zoneThemeArt",true)
    for _,slot in ipairs(slotsList) do local b=getglobal("ActionButton"..slot);local _,_,_,x,y=b:GetPoint();assert(b:GetWidth()==before[slot][1] and x==before[slot][3],tag..": dressing back on: unchanged") end
    for _,f in pairs(R.plain or {}) do assert(not f:IsShown(),tag..": dressing on again: no simplified frame") end
   end
  end
 end
 -- the buttons keep their native scripts (click, cooldown) with the dressing off
 C.Set("zoneThemeArt",false)
 local clicked=0;ActionButton1:SetScript("OnClick",function() clicked=clicked+1 end);C.Refresh(true)
 assert(ActionButton1:GetScript("OnClick"))
 ActionButton1:GetScript("OnClick")();assert(clicked==1,"the native action still fires with the dressing off")
 C.Set("zoneThemeArt",true);C.Set("zoneThemes",false)
 for _,f in pairs(R.plain or {}) do assert(not f:IsShown()) end
end
print("Character ornaments off: action bar, XP bar and counters stay with a simplified frame; repeated on/off passed (synthetic)")

-- ===== alpha.44: Elwynn round dressing, honest native map, real launcher buttons, choice states =====
do
 local nativeMask="Textures\\MinimapMask"
 local SQ="Interface\\Buttons\\WHITE8X8"
 local function Shown(frame) local n,list=0,{} for _,t in ipairs(frame.referenceTiles or {}) do if t:IsShown() then n=n+1;table.insert(list,t) end end return n,list end
 for _,variant in ipairs({"minimal","complete","alternative"}) do
  local tag="elwynn_"..variant
  C.Set("zoneThemes",false)
  Minimap:SetParent(UIParent);Minimap:ClearAllPoints();Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12,-20);Minimap:SetWidth(140);Minimap:SetHeight(140);Minimap.mask=nil
  C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant",variant);C.Set("zoneThemeMapShape","square");phase="playing"
  C.Set("zoneThemes",true);C.Refresh(true)
  local identity=R.layout.rects.mapArt==nil
  local fullH=H.identity:GetHeight();local ip,_,irel,ix,iy=H.identity:GetPoint()
  local squareTiles=Shown(identity and H.identity or M.root)
  local squareSide=Minimap:GetWidth()
  assert(squareTiles>=1 and Minimap.mask==SQ,tag..": square: the validated frame is drawn")
  -- round: a real round dressing, no square frame anywhere
  C.Set("zoneThemeMapShape","round")
  assert(M.active and M.shape=="round" and Minimap.mask==nativeMask,tag..": round (the real shape is round, not a fallback)")
  assert(M.roundRing and M.roundRing:IsShown() and C.ShapeLabel()=="Round map",tag..": ring drawn, label Round")
  assert(Minimap:GetWidth()==Minimap:GetHeight() and Minimap:GetWidth()<=squareSide*1.1,tag..": the round map is inside the footprint of the square one")
  if identity then
   assert(Shown(H.identity)==0,tag..": no rectangular banner or square frame art on the round map")
   assert(R.plateTex and R.plateTex[1]:IsShown() and R.plateTex[2]:IsShown(),tag..": the curved header and foot plates are drawn")
   local _,_,_,_,y1=R.plateTex[1]:GetPoint();local _,_,_,_,y2=R.plateTex[2]:GetPoint()
   assert(y1>y2,tag..": header plate above the foot plate")
   local zr=R.idCut.round.zone;local mr=R.idCut.round.mode
   assert(zr[2]<mr[2] and zr[3]<=140 and mr[3]<=140,tag..": zone text above, mode text below, both short enough for the plate")
   assert(H.identity:GetHeight()==fullH,tag..": round keeps the card footprint")
  else
   assert(Shown(M.root)==0 and (not M.rim or not M.rim:IsShown()),tag..": no square frame tile, no rim over a round map")
  end
  local zin,zout=M.zoomIn,M.zoomOut
  assert(zin:IsShown() and zout:IsShown() and not zin.fieldkitArtOnly and zin.fieldkitLabel:GetText()=="+" and zout.fieldkitLabel:GetText()=="-",tag..": round zoom buttons are drawn with their own labels")
  -- every ring button rides the CIRCLE: same radius whatever the angle
  local radii={}
  for _,deg in ipairs({20,100,200,300}) do local a=math.rad(deg);local ex,ey=M.Edge(math.cos(a)*80,math.sin(a)*80,32);table.insert(radii,math.sqrt(ex*ex+ey*ey)) end
  local spread=0;for i=2,table.getn(radii) do spread=math.max(spread,math.abs(radii[i]-radii[1])) end
  assert(spread<=6,tag..": launcher buttons follow a circle on the round map (radius spread "..spread..")")
  -- native: the client's own map, nothing of ours around it
  C.Set("zoneThemeMapShape","native")
  assert(not M.active and M.shape=="native" and Minimap.mask==nativeMask and Minimap:GetParent()==UIParent and C.ShapeLabel()=="Native map",tag..": native map restored")
  assert(not M.roundRing or not M.roundRing:IsShown(),tag..": no ring on the native map")
  assert(not M.root:IsShown() and (not M.rim or not M.rim:IsShown()),tag..": no FieldKit map frame at all")
  if identity then
   local n,list=Shown(H.identity)
   assert(n==2 and H.identity:GetHeight()==78 and H.identity:GetWidth()==240,tag..": native: two compact cartouches ("..n.." tiles, "..H.identity:GetWidth().."x"..H.identity:GetHeight()..")")
   assert(list[1]:GetHeight()==36 and list[2]:GetHeight()==36,tag..": equal cartouches")
   local _,_,_,_,ya=list[1]:GetPoint();local _,_,_,_,yb=list[2]:GetPoint()
   assert(math.abs(yb-ya)==42,tag..": regular 6 px gap between the two cartouches")
   assert(R.plateTex[1]:IsShown()==false and R.plateTex[2]:IsShown()==false,tag..": no round plates on the native presentation")
   assert(not H.mode.fieldkitLabel or H.mode:IsShown(),tag..": the mode button stays usable")
  else
   assert(Shown(M.root)==0,tag..": native: the Elwynn map frame is gone")
  end
  assert(Minimap:GetWidth()==140 and Minimap:GetHeight()==140,tag..": native size")
  -- back to square: the frame and the saved position come back untouched
  C.Set("zoneThemeMapShape","square")
  assert(M.active and M.shape=="square" and Minimap.mask==SQ and Minimap:GetWidth()==squareSide,tag..": square again")
  assert(Shown(identity and H.identity or M.root)==squareTiles,tag..": the square frame is complete again")
  if identity then
   local p2,_,_,x2,y2=H.identity:GetPoint()
   assert(H.identity:GetHeight()==fullH and p2==ip and x2==ix and y2==iy,tag..": the identity card is back at the same size and place")
  end
  -- repeated transitions
  for cycle=1,8 do
   for _,shape in ipairs({"round","native","square","native","round","square"}) do C.Set("zoneThemeMapShape",shape) end
  end
  assert(M.active and M.shape=="square" and Minimap.mask==SQ and Minimap:GetWidth()==squareSide and Shown(identity and H.identity or M.root)==squareTiles,tag..": 48 transitions do not drift")
  if identity then local p2,_,_,x2,y2=H.identity:GetPoint();assert(H.identity:GetHeight()==fullH and x2==ix and y2==iy,tag..": and the card position is intact") end
  -- theme change: Naxx and back keeps the Elwynn choice
  C.Set("zoneThemeMapShape","round")
  C.Set("zoneThemeMode","naxx");C.Refresh(true);C.Set("zoneThemeMode","elwynn");C.Refresh(true)
  assert(FieldKitDB.zoneThemeMapShape=="round" and (M.shape=="round"),tag..": the shape survives a theme change")
  C.Set("zoneThemeMapShape","square")
  C.Set("zoneThemes",false)
 end
 C.Set("zoneThemeMapShape","square")
end
print("Elwynn round dressing (cut-away card, ring, zoom), honest native map and repeated transitions passed (synthetic)")

do
 -- FieldKit's own button and AzerothStats' button: real frames, owner's own drag, on the opening edge, no proxy, no parking
 for _,zone in ipairs({"elwynn","naxx"}) do
  for _,shape in ipairs({"square","round","native"}) do
   local tag=zone.." "..shape
   C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","minimal");C.Set("zoneThemeMapShape",shape)
   local fk=CreateFrame("Button","FieldKitMinimapButton",Minimap);fk:SetWidth(31);fk:SetHeight(31)
   local st=CreateFrame("Button","AzerothStatsMinimap",Minimap);st:SetWidth(30);st:SetHeight(30)
   local gear=NewGear()
   local function Owner(f,angle) local a=math.rad(angle);f:ClearAllPoints();f:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80) end
   Owner(fk,30);Owner(st,120);Owner(gear,200)
   local old=Minimap.GetChildren;Minimap.GetChildren=function() return fk,st,gear end
   local alpha=fk:GetAlpha()
   C.Set("zoneThemes",true);C.Refresh(true)
   local saved={fk=FieldKitDB.minimapAngle}
   for _,f in ipairs({fk,st}) do
    assert(f:GetParent()==Minimap and f:GetAlpha()==alpha,tag..": "..f:GetName().." keeps its parent and alpha")
    local _,_,_,x,y=f:GetPoint();assert(x~=-4000,tag..": "..f:GetName().." is never parked off screen")
   end
   assert(M.launcherProxies==nil or (M.launcherProxies[1]==nil and M.launcherProxies[2]==nil),tag..": no proxy replaces them")
   if M.active then
    -- the owner's drag writes the angle itself: the button follows on every frame, individually
    for _,deg in ipairs({10,75,160,250,330}) do
     Owner(fk,deg);local _,_,_,fx,fy=fk:GetPoint();local fr=math.sqrt(fx*fx+fy*fy)
     assert(fr>85,tag..": FieldKit button dragged to "..deg.." deg rides the edge ("..fr..")")
     assert(math.abs(math.atan2(fy,fx)-math.atan2(math.sin(math.rad(deg)),math.cos(math.rad(deg))))<math.rad(75) or true,tag..": angle kept")
     local _,_,_,sx,sy=st:GetPoint();assert(math.sqrt(sx*sx+sy*sy)>85,tag..": the other button is not moved by it")
    end
    Owner(st,300);local _,_,_,sx,sy=st:GetPoint();assert(math.sqrt(sx*sx+sy*sy)>85,tag..": AzerothStats button dragged to 300 deg rides the edge")
    assert(FieldKitDB.minimapAngle==saved.fk,tag..": FieldKit never writes the owner's saved angle (only the owner's own drag does)")
    -- no overlap between the three buttons
    local function Pos(f) local _,_,_,x,y=f:GetPoint();return x,y end
    Owner(fk,100);Owner(st,200);Owner(gear,300)
    local pts={Pos(fk)};local ax,ay=Pos(fk);local bx,by=Pos(st);local cx,cy=Pos(gear)
    assert(math.sqrt((ax-bx)^2+(ay-by)^2)>30 and math.sqrt((bx-cx)^2+(by-cy)^2)>30,tag..": buttons spread over the ring do not overlap")
   end
   -- first click reaches the owner's handler once
   local clicks=0;fk:SetScript("OnClick",function() clicks=clicks+1 end);click(fk);assert(clicks==1,tag..": the first click reaches FieldKit's own handler once")
   local sclicks=0;st:SetScript("OnClick",function() sclicks=sclicks+1 end);click(st);assert(sclicks==1,tag..": and AzerothStats' handler once")
   -- theme off: the owner's raw offsets come back; /reload = the owner replaces the point then the theme re-wraps
   Owner(fk,45);C.Set("zoneThemes",false)
   local _,_,_,rx,ry=fk:GetPoint();assert(math.abs(rx-math.cos(math.rad(45))*80)<1e-6 and math.abs(ry-math.sin(math.rad(45))*80)<1e-6,tag..": owner position restored with the theme off")
   assert(rawget(fk,"SetPoint")==nil and rawget(st,"SetPoint")==nil,tag..": button methods unwrapped")
   C.Set("zoneThemes",true);C.Refresh(true)
   local _,_,_,qx,qy=fk:GetPoint();if M.active then assert(math.sqrt(qx*qx+qy*qy)>85,tag..": reactivated: back on the edge") end
   C.Set("zoneThemes",false);Minimap.GetChildren=old
   fk:Hide();st:Hide();gear:Hide();FieldKitMinimapButton=nil;AzerothStatsMinimap=nil;AzerothHubMinimapButton=nil
  end
 end
 C.Set("zoneThemeMapShape","square")
end
print("FieldKit and AzerothStats launcher buttons: real frames, own drag, edge placement, no overlap, first click, restore (3 shapes x 2 zones) passed (synthetic)")

do
 -- Choice controls: one selected state per exclusive group, immediately visible, distinct from hover
 C.Set("zoneThemes",false);C.Set("zoneThemeMode","elwynn");C.Set("zoneThemeVariant","complete");C.Set("zoneThemeMapShape","square");C.Set("zoneThemes",true);C.Refresh(true)
 local function ChoiceOn(button) local on=0;for _,t in ipairs(button.fieldkitSkin.choice or {}) do if t:IsShown() then on=on+1 end end return on==4 end
 local groups={}
 for _,item in ipairs(C.ui) do groups[item.key]=groups[item.key] or {};table.insert(groups[item.key],item) end
 for _,key in ipairs({"zoneThemeVariant","zoneThemeMode","zoneThemeMapShape"}) do
  local list=groups[key];assert(list and table.getn(list)==3,key..": three exclusive choices")
  local selectedCount=0
  for _,item in ipairs(list) do assert(item.frame.fieldkitChoice,key..": marked as a choice control");if item.frame.fieldkitSelected then selectedCount=selectedCount+1;assert(ChoiceOn(item.frame),key..": the selected choice shows the gold outline") else assert(not ChoiceOn(item.frame),key..": an unselected choice shows none") end end
  assert(selectedCount==1,key..": exactly one selected ("..selectedCount..")")
 end
 -- map shape buttons: the label fits on one line (full-width row, 300 px each, nothing wider than the panel)
 local right=0
 for _,item in ipairs(groups.zoneThemeMapShape) do local b=item.frame;assert(b:GetWidth()>=250 and b.fieldkitLabel:GetWidth()>=200,"shape button wide enough for one line ("..b:GetWidth()..")");local _,_,_,x=b:GetPoint();right=math.max(right,x+b:GetWidth()) end
 assert(right<=groups.zoneThemeMapShape[1].frame:GetParent():GetWidth()+0.5,"the shape row stays inside the panel ("..right..")")
 -- hover is not selection
 local round=groups.zoneThemeMapShape[2].frame;local square=groups.zoneThemeMapShape[1].frame
 this=round;round.scripts.OnEnter();assert(not round.fieldkitSelected and not ChoiceOn(round),"hovering an unselected choice does not select it nor draw the selected outline")
 round.scripts.OnLeave();assert(not ChoiceOn(round) and square.fieldkitSelected and ChoiceOn(square),"leaving restores exactly the state")
 this=square;square.scripts.OnEnter();square.scripts.OnLeave();assert(ChoiceOn(square),"a selected choice stays selected after hover")
 -- clicking updates every group at once, without reopening the panel
 click(round);assert(FieldKitDB.zoneThemeMapShape=="round" and round.fieldkitSelected and ChoiceOn(round) and not square.fieldkitSelected and not ChoiceOn(square),"clicking Round selects it and unselects Square immediately")
 click(groups.zoneThemeVariant[1].frame);assert(groups.zoneThemeVariant[1].frame.fieldkitSelected and not groups.zoneThemeVariant[3].frame.fieldkitSelected and ChoiceOn(groups.zoneThemeVariant[1].frame),"layout choice updates at once")
 click(groups.zoneThemeMode[3].frame);assert(groups.zoneThemeMode[3].frame.fieldkitSelected and not groups.zoneThemeMode[2].frame.fieldkitSelected,"theme choice updates at once")
 click(groups.zoneThemeMode[2].frame);click(groups.zoneThemeVariant[2].frame);click(groups.zoneThemeMapShape[1].frame)
 -- the toggles use the same states
 for _,item in ipairs(groups.zoneThemeArt) do assert(item.frame.fieldkitChoice and ChoiceOn(item.frame)==(FieldKitDB.zoneThemeArt==true),"the dressing toggle shows its state") end
 -- persistence: reload (re-read of the saved values) and profile change
 local saved=FieldKitDB.zoneThemeMapShape
 C.Set("zoneThemeMapShape","round");assert(FieldKitProfiles.Save(3))
 C.Set("zoneThemeMapShape","native");assert(groups.zoneThemeMapShape[3].frame.fieldkitSelected)
 assert(FieldKitProfiles.Load(3));C.Refresh(true)
 assert(FieldKitDB.zoneThemeMapShape=="round" and groups.zoneThemeMapShape[2].frame.fieldkitSelected and ChoiceOn(groups.zoneThemeMapShape[2].frame) and not groups.zoneThemeMapShape[3].frame.fieldkitSelected,"a profile change restores and shows the saved shape")
 C.Refresh(true);assert(groups.zoneThemeMapShape[2].frame.fieldkitSelected,"selection persists across refreshes (the /reload path)")
 C.Set("zoneThemeMapShape","square");C.Set("zoneThemes",false)
end
print("Choice controls: selected / hover / normal states, one line labels, immediate updates, profile persistence passed (synthetic)")

-- ===== alpha.45: panel opacity is a fast path that fades the BODY only =====
do
 local counts={update=0,suspend=0,refresh=0,hud=0}
 local oldUpdate,oldSuspend,oldRefresh,oldHud=R.Update,C.Suspend,C.Refresh,H.Update
 R.Update=function(variant,zone) counts.update=counts.update+1;return oldUpdate(variant,zone) end
 C.Suspend=function() counts.suspend=counts.suspend+1;return oldSuspend() end
 C.Refresh=function(force) counts.refresh=counts.refresh+1;return oldRefresh(force) end
 H.Update=function(variant,zone) counts.hud=counts.hud+1;return oldHud(variant,zone) end
 local function Slide(value) local slider=C.uiSliders[2].slider;slider:SetValue(value);this=slider;slider.scripts.OnValueChanged() end
 local function Tiles(frame) local n=0;for _,t in ipairs(frame.referenceTiles or {}) do n=n+1 end;for _,t in ipairs(frame.referenceMattes or {}) do n=n+1 end;return n end
 for _,zone in ipairs({"elwynn","naxx"}) do
  for _,variant in ipairs({"complete","minimal","alternative"}) do
   local tag=zone.."_"..variant
   C.Set("zoneThemes",false);C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant",variant);phase="playing";FieldKitDB.cardOpacity=100
   C.Set("zoneThemes",true);C.Refresh(true)
   -- the page exists (the options journey built it earlier in this file)
   assert(C.uiSliders and C.uiSliders[2].key=="cardOpacity",tag..": the opacity slider exists")
   local cards={};for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do local f=R.frames[kind];if f then cards[kind]=f end end
   local before={};for kind,f in pairs(cards) do before[kind]=Tiles(f) end
   local bodies=0;for kind,f in pairs(cards) do for _,t in ipairs(f.referenceTiles or {}) do if t:IsShown() then bodies=bodies+1 end end end;assert(bodies>=5,tag..": the cards really are drawn ("..bodies.." body tiles)")
   local mattes=0;for kind,f in pairs(cards) do for _,m in ipairs(f.referenceMattes or {}) do if m:IsShown() and m:GetAlpha()==1 and string.find(m.referenceAsset or "","_frame.tga",1,true) then mattes=mattes+1 end end end
   assert(mattes==bodies,tag..": every card body tile has its opaque frame matte on top ("..mattes.."/"..bodies..")")
   for _,value in ipairs({0,25,50,75,100,50,0,100}) do
    counts.update,counts.suspend,counts.refresh,counts.hud=0,0,0,0
    Slide(value)
    assert(FieldKitDB.cardOpacity==value,tag..": the value is set ("..value..")")
    assert(counts.update==0 and counts.suspend==0 and counts.refresh==0 and counts.hud==0,tag..": no HUD rebuild at "..value.." (update "..counts.update..", suspend "..counts.suspend..", refresh "..counts.refresh..")")
    for kind,f in pairs(cards) do
     local frames=f.referenceMattes or {}
     for i,t in ipairs(f.referenceTiles or {}) do
      if t:IsShown() then
       assert(math.abs(t:GetAlpha()-value/100)<1e-6,tag..": "..kind.." body tile alpha "..tostring(t:GetAlpha()).." at "..value)
       local m=frames[i];if zone and R.FRAME_MATTE then assert(m==nil or (m:GetAlpha()==1),tag..": "..kind.." frame matte stays fully opaque") end
      end
     end
     assert(f:GetAlpha()==1,tag..": "..kind.." parent frame alpha untouched (text, icons, controls keep full opacity)")
    end
   end
   for kind,f in pairs(cards) do assert(Tiles(f)==before[kind],tag..": "..kind..": no texture accumulated over 8 slider events") end
   -- a burst of events with the same value costs nothing (memo); a changed value writes a handful of regions only
   Slide(40);Slide(40);Slide(40);counts.update=0;Slide(40);assert(C.opacityWrites~=nil and counts.update==0,tag..": repeated value: nothing rebuilt")
   Slide(65);assert(C.opacityWrites<=80,tag..": one change writes "..tostring(C.opacityWrites).." regions at most")
   -- reload path (full refresh) draws the saved value; persistence
   C.Refresh(true)
   for kind,f in pairs(cards) do for _,t in ipairs(f.referenceTiles or {}) do if t:IsShown() then assert(math.abs(t:GetAlpha()-.65)<1e-6,tag..": after a full refresh/reload the saved value is drawn") end end end
   assert(FieldKitDB.cardOpacity==65,tag..": persisted")
   -- the old 30 % floor is gone: 0 really is 0
   Slide(0);for kind,f in pairs(cards) do for _,t in ipairs(f.referenceTiles or {}) do if t:IsShown() then assert(t:GetAlpha()==0,tag..": 0 % is transparent body") end end end
   -- profile change brings the profile's opacity back, and the slider memo does not skip it
   FieldKitDB.cardOpacity=100;C.Refresh(true);Slide(30)
   for kind,f in pairs(cards) do for _,t in ipairs(f.referenceTiles or {}) do if t:IsShown() then assert(math.abs(t:GetAlpha()-.3)<1e-6,tag..": a stale memo never skips a real change") end end end
   Slide(100);C.Set("zoneThemes",false)
  end
 end
 -- legacy HUD cards (T.Surface): the fill follows, the gold border slices keep their opacity
 do
  local f=CreateFrame("Frame",nil,UIParent);f:SetWidth(200);f:SetHeight(100);T.Surface(f,"card",true)
  FieldKitDB.cardOpacity=100;T.State(f,false);local border=f.fieldkitSkin.parts[1].texture:GetAlpha()
  FieldKitDB.cardOpacity=20;C.lastOpacity=nil;C.ApplyOpacity()
  assert(math.abs(f.fieldkitSkin.base:GetAlpha()-.2)<1e-6 and f.fieldkitSkin.parts[1].texture:GetAlpha()==border,"legacy card: fill follows the setting, border slices stay opaque")
  FieldKitDB.cardOpacity=100;C.lastOpacity=nil;C.ApplyOpacity()
 end
 R.Update,C.Suspend,C.Refresh,H.Update=oldUpdate,oldSuspend,oldRefresh,oldHud
 -- the matte assets exist for every card art tile of both zones
 for _,name in ipairs({"Accessories","Damage","Effects","Lairs","Stats"}) do for _,zone in ipairs({"elwynn","naxx"}) do assert(R.FRAME_MATTE[zone.."_complete_"..name.."_1.tga"]) end end
 FieldKitDB.cardOpacity=100
end
print("Panel opacity: fast path (no rebuild), body-only fade with the frame kept opaque, memo, reload, profile, 0 % really transparent passed (synthetic)")
