-- Real addon constructors/handlers with explicit synthetic native inputs.
-- No claim about packets delivered by the running game or rendered modals.
FieldKitDB={}
local writes,registrations,unregistrations=0,0,0
local top={}
function AZS_SetOnTopOfScreens(name,on) writes=writes+1;top[name]=on and true or nil end
function AZS_RegisterBannerHandler(handler) registrations=registrations+1;BANNER_HANDLER=handler end
function AZS_UnregisterBannerHandler(handler) unregistrations=unregistrations+1;if BANNER_HANDLER==handler then BANNER_HANDLER=nil end end
function AZS_GetRunTime() return AZS_RUN.t end
function AZS_GetTotems() return AZS_TOTEMS end
function AZS_GetSummonGroups() return SUMMONS end
function AZS_GetTimers() return TIMERS end
function AZS_GetRevive() return AZS_REVIVE end
function AZS_GetUpcomingBosses() return UPCOMING end
function AZS_GetStoredLevels() return AZS_RUN.sl or 0 end
function AZS_GetFlaggedLair() return AZS_LAIRS[1] end
AZS_TOTEMS={};AZS_PETS={};SUMMONS={};TIMERS={};AZS_TIMERS={};AZS_REVIVE={};UPCOMING={}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("");update(FieldKitFrame,.3)
local T,N=FieldKitNativeTools,FieldKitNative
assert(writes==0 and registrations==0)
assert(not FieldKitEffectsFrame:IsShown() and not FieldKitReviveFrame:IsShown() and not FieldKitEncounterFrame:IsShown())
local function control(label)
 for _,c in ipairs(FieldKitUI.controls) do if c.label==label or (c.item and c.item.label==label) then return c end end
 error(label)
end
local function toggle(label,value) local c=control(label);c:SetChecked(value);click(c) end
-- All three native meter modes preserve their own rates, columns and source.
function AZS_GetMeter() return {{name="Observed damage",dmg=900,dps=9,share=1}},900,9 end
function AZS_GetHealing() return {{name="Observed heal",dmg=400,dps=40,share=1}},400,40 end
function AZS_GetBossMeter() return {{name="Observed boss damage",dmg=800,dps=160,share=1}},800,160 end
local view=control("Local meter view")
click(view);click(view.choiceButtons[2]);update(FieldKitFrame,.3)
assert(FieldKitMeterFrame.title:GetText()=="Healing")
assert(FieldKitMeterFrame.rows[1].label:GetText()=="Observed heal" and FieldKitMeterFrame.rows[1].meterColumns[2]:GetText()=="40 hps")
local own=FieldKitMeterFrame.rows[1];this=own;own:GetScript("OnEnter")()
assert(FieldKitPartyDetails.data.mode==2 and FieldKitPartyDetails.captions[2]:GetText()=="HPS")
assert(FieldKitPartyDetails.frame.rows[1].meterColumns[2]:GetText()=="40 hps")
click(view);click(view.choiceButtons[3]);update(FieldKitFrame,.3)
assert(FieldKitMeterFrame.rows[1].label:GetText()=="Observed boss damage" and FieldKitMeterFrame.rows[1].meterColumns[2]:GetText()=="160 dps")
assert(not FieldKitPartyDetails.frame:IsShown(),"Pinned detail crossed meter meanings")
AZS_GetBossMeter=nil;update(FieldKitFrame,.3)
assert(FieldKitMeterFrame.total:GetText()=="Not provided" and FieldKitMeterFrame.rows[1].label:GetText()=="Meter data not provided")
click(view);click(view.choiceButtons[1])
-- Effects are native counts and supplied remaining time, not fabricated damage.
AZS_TOTEMS={{name="Observed magma",count=2,cap=3,remaining=15,icon="Interface\\Icons\\Spell_Fire_SelfDestruct"}}
SUMMONS={{name="Observed permanent pet",count=1,permanent=1,temporary=0}}
TIMERS={{name="Observed proc",remaining=5,ready=false},{name="Observed ready",remaining=0,ready=true}}
AZS_TIMERS={};toggle("Effects tracker",true);update(FieldKitFrame,.3)
assert(FieldKitEffectsFrame:IsShown() and FieldKitEffectsFrame.mashVisibleRows==4)
assert(FieldKitEffectsFrame.rows[1].value:GetText()=="2 / 3 · 0:15")
assert(FieldKitEffectsFrame.rows[2].value:GetText()=="1 · Permanent")
assert(FieldKitEffectsFrame.rows[3].value:GetText()=="0:05" and FieldKitEffectsFrame.rows[4].value:GetText()=="Ready")
local allocated=table.getn(objects)
for i=1,20 do update(FieldKitFrame,.2) end
assert(table.getn(objects)==allocated,"Native tools allocated frames during refresh")
AZS_RUN.ph="paused";update(FieldKitFrame,20)
assert(FieldKitEffectsFrame.rows[1].value:GetText()=="2 / 3 · 0:15","UI applied wall time to native remaining")
AZS_RUN.ph="playing"
FieldKitCardLayout.selected=13;FieldKitCardLayout.SetDimension("width",420);FieldKitCardLayout.SetDimension("height",200)
assert(FieldKitEffectsFrame:GetWidth()==420 and FieldKitEffectsFrame:GetHeight()==200)
SlashCmdList.FieldKit("lock");this=FieldKitEffectsFrame;FieldKitEffectsFrame:GetScript("OnDragStart")()
assert(not FieldKitEffectsFrame.azsMoving)
SlashCmdList.FieldKit("unlock");this=FieldKitEffectsFrame;FieldKitEffectsFrame:GetScript("OnDragStart")()
assert(FieldKitEffectsFrame.azsMoving);FieldKitEffectsFrame:GetScript("OnDragStop")()
click(FieldKitEffectsFrame.mashCollapseButton);update(FieldKitFrame,.3);assert(FieldKitEffectsFrame:GetHeight()==24)
click(FieldKitEffectsFrame.mashCollapseButton)
toggle("Track totems",false);update(FieldKitFrame,.3)
assert(FieldKitEffectsFrame.mashVisibleRows==3 and FieldKitEffectsFrame.rows[1].label:GetText()=="Observed permanent pet")
toggle("Track totems",true)
-- Overlay registration is opt-in, bounded to FieldKit frames, and reverses.
local overlay=control("Keep this window above card choices");overlay:SetChecked(true);click(overlay)
assert(top.FieldKitEffectsFrame and writes==1)
for i=1,10 do update(FieldKitFrame,.2) end
assert(writes==1,"Unchanged registry written on every tick")
assert(not FieldKit.SetFrameOnTop("UIParent",true) and not FieldKit.SetFrameOnTop("OtherAddonFrame",true))
toggle("Effects tracker",false);update(FieldKitFrame,.3);assert(not top.FieldKitEffectsFrame)
toggle("Effects tracker",true);update(FieldKitFrame,.3);assert(top.FieldKitEffectsFrame)
overlay:SetChecked(false);click(overlay);assert(not top.FieldKitEffectsFrame)
-- Revive data is local and explicit, and never hides the native HUD.
AZS_REVIVE={down=1,share=.4,by="Observed ally"};toggle("Co-op revive progress",true);update(FieldKitFrame,.3)
assert(FieldKitReviveFrame:IsShown() and FieldKitReviveFrame.rows[1].value:GetText()=="40%")
assert(FieldKitReviveFrame.rows[2].value:GetText()=="Observed ally")
AZS_REVIVE={down=0,reviving="Observed friend",rshare=.65};update(FieldKitFrame,.3)
assert(FieldKitReviveFrame.mashVisibleRows==1 and FieldKitReviveFrame.rows[1].value:GetText()=="65%")
AZS_REVIVE={};update(FieldKitFrame,.3);assert(not FieldKitReviveFrame:IsShown())
-- Native flag matches a lair id/index, not a same-name guess.
AZS_LAIRS={{index=1,id=7,name="Observed lair",state="asleep",left=0,x=10,y=20}}
AZS_GetLairs=function() return AZS_LAIRS end
toggle("Highlight the flagged lair",true);update(FieldKitFrame,.3)
assert(FieldKitLairFrame.rows[1].label:GetText()=="> Observed lair")
toggle("Highlight the flagged lair",false);update(FieldKitFrame,.3)
assert(FieldKitLairFrame.rows[1].label:GetText()=="Observed lair")
-- No calendar/bitmask guesses: accept literal names, otherwise display raw data.
AZS_ZONE.heroic=3;AZS_ZONE.affixes="bolstering,sanguine"
local affixes,known=FieldKitRunMode.Affixes();assert(known and affixes=="Active affixes: Bolstering, Sanguine")
AZS_ZONE.affixes=3;affixes,known=FieldKitRunMode.Affixes();assert(not known and affixes=="Affixes (raw): 3")
AZS_ZONE.affixes=nil;assert(FieldKitRunMode.Affixes()==nil)
-- Reminders and bounded deduped warnings only use observed arrival/messages.
UPCOMING={{index=1,name="Observed upcoming",left=8}};AZS_RUN.sl=3
toggle("Next boss reminder",true);toggle("Stored level-up reminder",true);toggle("Warn before the next boss",true)
update(FieldKitFrame,.3)
assert(FieldKitEncounterFrame.mashVisibleRows==2 and FieldKitEncounterFrame.rows[1].value:GetText()=="0:08")
assert(FieldKitEncounterFrame.rows[2].value:GetText()=="3" and table.getn(T.warnings)==1)
for i=1,10 do update(FieldKitFrame,.2) end
assert(table.getn(T.warnings)==1,"Arrival warning repeated")
toggle("Native mechanic warnings",true);assert(registrations==1)
T.Banner({id=1,kind="rune",boss=false,text="Rune pickup is not a location"})
assert(table.getn(T.warnings)==1)
for i=1,12 do T.Banner({id=i,kind="mechanic",boss=false,text="Observed warning "..i}) end
assert(table.getn(T.warnings)==3 and table.getn(T.recent)<=32)
local last=T.warnings[3];T.Banner({id=12,kind="mechanic",text="Observed warning 12"});assert(T.warnings[3]==last)
update(FieldKitFrame,5);assert(not FieldKitNativeWarnings:IsShown())
toggle("Native mechanic warnings",false);assert(unregistrations==1)
T.Push("Old native notice","banner:99");T.Warnings();assert(table.getn(T.warnings)==0,"Disabled native alerts leaked while arrivals stayed enabled")
local setter=AZS_SetOnTopOfScreens;AZS_SetOnTopOfScreens=function() error("unsupported") end
assert(not FieldKit.SetFrameOnTop("FieldKitEffectsFrame",true));AZS_SetOnTopOfScreens=nil
assert(not FieldKit.SetFrameOnTop("FieldKitEffectsFrame",true));AZS_SetOnTopOfScreens=setter

-- A clock regression rejects retained old effect data, then accepts a fresh packet.
AZS_RUN.t=1;UPCOMING={};update(FieldKitFrame,.3)
assert(not FieldKitEffectsFrame:IsShown(),"New run displayed old effect snapshot")
AZS_TOTEMS={{name="New observed totem",count=1,remaining=9}};fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSTOTEMS");update(FieldKitFrame,.3)
assert(FieldKitEffectsFrame.rows[1].label:GetText()=="New observed totem")
-- A packet already delivered in the boundary batch is not discarded.
AZS_RUN.t=100;update(FieldKitFrame,.3)
AZS_RUN.t=0;AZS_TOTEMS={{name="First fresh batch",count=1,remaining=8}}
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSTOTEMS");update(FieldKitFrame,.3)
assert(FieldKitEffectsFrame.rows[1].label:GetText()=="First fresh batch")
-- Optional APIs absent/throwing must not break the old client.
AZS_GetTotems=nil;AZS_GetSummonGroups=nil;AZS_GetTimers=nil;AZS_GetRevive=nil;AZS_GetUpcomingBosses=function() error("unavailable") end
update(FieldKitFrame,.3)
assert(FieldKitEffectsFrame.rows[1].label:GetText()=="Effects API unavailable")
FieldKit_SetLanguage("fr")
assert(FieldKit_L("Effects tracker")=="Suivi des effets" and FieldKit_L("Affixes (raw)")=="Affixes (bruts)")
AZS_RUN.ph=nil;update(FieldKitFrame,.3)
for _,f in ipairs(T.frames) do assert(not f:IsShown()) end
assert(not FieldKitNativeWarnings:IsShown())
print("Native tools: truthful meters/effects/revives, guarded overlays, affixes, reminders, alert bounds and old-client fallback passed")
