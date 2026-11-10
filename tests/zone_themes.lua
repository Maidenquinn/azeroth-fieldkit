-- Synthetic behavioral acceptance only: does not certify the native renderer.
TARGET=nil
fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
assert(FieldKitZoneThemes.ui and table.getn(FieldKitZoneThemes.ui)==10,"Theme settings must be present in the real options journey")
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
 assert(not acc.pager:IsShown() and string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"1-7/8",1,true),zone..": the scroll position is in the Spells tab, not over the rows")
 Inside(acc,zone,"Accessories")
 this=acc;arg1=-1;acc.scripts.OnMouseWheel();assert(R.scroll.Accessories==1 and acc.rows[1].label:GetText()=="Spell 2",zone..": wheel scrolls the list")

 arg1=-100;acc.scripts.OnMouseWheel();assert(acc.rows[7].label:GetText()=="Spell 8" and string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"2-8/8",1,true) and not acc.pager:IsShown(),zone..": scrolling is clamped")
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
 local r1=dm.rows[1];local _,_,_,rx,ry=r1:GetPoint();local top=zone=="naxx" and 144 or 98;local bottom=zone=="naxx" and dr[4]-30 or dr[4]-52
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
 FieldKitThemeMinimap.probe.ring=true -- edge placement is an opt-in probe now
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

-- alpha.18: Spells indicator never over rows, for 0/1/5/6/7/12 spells in FR and EN.
for _,zone in ipairs({"elwynn","naxx"}) do
 C.Set("zoneThemeMode",zone);C.Set("zoneThemeVariant","complete");C.Set("zoneThemes",true)
 local oldSpells=FieldKitLoadout.spells
 for _,count in ipairs({0,1,5,6,7,12}) do for _,lang in ipairs({"fr","en"}) do
  FieldKitDB.language=lang;FieldKitLoadout.spells={};for i=1,count do table.insert(FieldKitLoadout.spells,{name="Spell "..i,rank="Rank "..i,rankValue=i,bonuses={},upgrades={}}) end
  FieldKitDB.loadoutTab=2;R.scroll.Accessories=0;C.Refresh(true);local acc=R.frames.Accessories
  assert(not acc.pager:IsShown(),zone..": no counter over the rows ("..count.." spells, "..lang..")")
  local label=acc.cardTabs[2].fieldkitLabel:GetText();assert((count>7)==(string.find(label,"/",1,true)~=nil),zone..": range in the tab only when scrolling is needed ("..count..")")
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
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap);gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
 local oldChildren=Minimap.GetChildren;Minimap.GetChildren=function() return gear end;C.Refresh(true)
 for _,angle in ipairs({0,90,180,270,45,225}) do local a=math.rad(angle);gear:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80)
  local _,_,_,gx,gy=gear:GetPoint();local hw,hh=R.layout.mapHole[3]/2,R.layout.mapHole[4]/2
  assert((gx*gx)/(hw*hw)+(gy*gy)/(hh*hh)<1.6 and math.abs(gx)<=hw and math.abs(gy)<=hh,"gear stays inside the opening at "..angle.." degrees ("..gx..","..gy..")") end
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
  local rows=2;local step=(zone=="naxx" and 35 or 36) -- seven permanent sockets on the Spells tab
  assert(acc:GetHeight()==base[4]+rows*step,zone..": card height for "..count.." spells")
  local shown=0;for i,r in ipairs(acc.rows) do if r:IsShown() then shown=shown+1;local _,_,_,_,y=r:GetPoint();assert(-y==R.SocketY(zone,i),zone..": row "..i.." sits on socket "..i.." ("..count..")") end end
  assert(shown==math.max(1,math.min(7,count)),zone..": visible spell rows for "..count)
  assert((count>7)==(string.find(acc.cardTabs[2].fieldkitLabel:GetText(),"/",1,true)~=nil),zone..": scroll only beyond seven")
  local reach=0;local pieces={};for _,t in ipairs(acc.referenceTiles) do if t:IsShown() then local _,_,_,_,y=t:GetPoint();table.insert(pieces,{-y,t:GetHeight()}) end end
  table.sort(pieces,function(p,q) return p[1]<q[1] end);for _,p in ipairs(pieces) do assert(p[1]==reach,zone..": art continuity at "..p[1].." expected "..reach.." ("..count..")");reach=reach+p[2] end
  assert(reach==acc:GetHeight(),zone..": art ends at the card bottom ("..count..")")
  NoOverlap(zone.." "..count.." spells")
  assert((R.shift.Stats or 0)>0 or (R.shiftX.Stats or 0)~=0,zone..": Stats gives way to the taller Equipment card "..count.." sh="..table.concat({tostring(R.shift.Accessories),tostring(R.shiftX.Accessories),tostring(R.shift.Stats),tostring(R.shiftX.Stats),tostring(R.shift.Effects),tostring(R.shiftX.Effects),tostring(R.shift.Lairs),tostring(R.shift.Damage)},",").." last="..tostring(R.lastMoved).." noRoom="..tostring(R.noRoom))
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
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap);gear:SetScript("OnClick",function() clicked=clicked+1 end);gear:SetScript("OnDragStart",function() dragged=dragged+1 end)
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
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap);gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
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
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap);gear:SetPoint("CENTER",Minimap,"CENTER",80,0)
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
 local gear=CreateFrame("Button","AzerothHubMinimapButton",Minimap);gear:SetScript("OnClick",function() end)
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
