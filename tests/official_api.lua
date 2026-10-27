-- Behavioral checks derived from the supplied official addon_docs.md contract.
-- Counters measure mock invocations, never FPS or real-client performance.
FieldKitDB={compactBar=true,bossFrame=true,chestPins=true,guardianPins=true,replaceTally=true}
AZS_RUN={ph="playing",t=100,px=100,py=200,gold=50,chest=20,ck=3,sh=20}
AZS_UNITS={{kind="boss",id=7,name="Brute gordunni",hp=90,hpm=100,state=0}}
AZS_UNITS_UPDATED=1
AZS_LAIRS={{name="Guardian",state="empty",left=180,x=110,y=180}}
AZS_LAIRS_UPDATED=NOW
local lairs,pins,debuffs,meter=0,0,0,0
local rate=10
local lines={{name="Observed spell",dmg=100,dps=10,share=1}}
AZS_METER_UPDATED=1
AZS_GetMeter=function() meter=meter+1;return lines,100,rate end
AZS_GetLairs=function() lairs=lairs+1;return AZS_LAIRS end
AZS_GetDebuffs=function() debuffs=debuffs+1;return {{icon="Interface\\Icons\\Spell_Shadow_ShadowWordPain",stacks=1,remaining=9}} end
local originalPins=FieldKit_UpdateWorldPins
FieldKit_UpdateWorldPins=function() pins=pins+1;originalPins() end
fire(FieldKitFrame,"VARIABLES_LOADED")
lairs=0;pins=0;debuffs=0;meter=0
for i=1,20 do update(FieldKitFrame,.05) end
assert(lairs==5 and pins==5 and meter==5,"Snapshot jobs must run at 5 Hz")
assert(debuffs==20,"Debuff countdowns must retain the faster 20 Hz refresh")
OFFICIAL_API_BATCHES=pins
-- The summary DPS belongs to the native getter, not only the damage-list stamp.
assert(string.find(FieldKitMeterFrame.total:GetText(),"10 dps",1,true))
rate=5;update(FieldKitFrame,.2)
assert(string.find(FieldKitMeterFrame.total:GetText(),"5 dps",1,true))
-- A paused/choosing run must not consume lair time using wall-clock time.
for _,phase in ipairs({"paused","choosing"}) do
 AZS_RUN.ph=phase;NOW=NOW+30;FieldKit_UpdateWorldPins()
 assert(FieldKitGuardianPin1.timer:GetText()=="3:00")
end
AZS_RUN.ph="playing";AZS_LAIRS[1].left=179;AZS_LAIRS_UPDATED=NOW
FieldKit_UpdateWorldPins();assert(FieldKitGuardianPin1.timer:GetText()=="2:59")
-- Native parser has already filled the table before the addon's listener runs.
AZS_STATS={crit=.37};AZS_STATS_UPDATED=NOW
arg2="crit=0.01";fire(FieldKitFrame,"CHAT_MSG_ADDON","AZS")
assert(FieldKitDB.lastStats==AZS_STATS and FieldKitDB.lastStats.crit==.37)
-- Retained tables outside a run must not keep the previous run's HUD visible.
AZS_RUN.ph=nil;update(FieldKitFrame,.2)
for _,f in ipairs({FieldKitStatsFrame,FieldKitGearFrame,FieldKitMoneyFrame,FieldKitMeterFrame,FieldKitLairFrame,FieldKitBossFrame1}) do
 assert(not f:IsShown(),"Out-of-run stale native data remained visible")
end
assert(not FieldKitGuardianPin1:IsShown())
assert(not FieldKitPlayerBar.shield:IsShown(),"Retained native shield shown outside a run")
update(FieldKitFrame,.05)
assert(not FieldKitMoneyFrame:IsShown(),"Compact docking revived stale out-of-run money")
AZS_RUN.ph="playing";AZS_RUN.ck=7;AZS_RUN.gold=3
fire(FieldKitFrame,"PLAYER_MONEY")
assert(FieldKitDB.chestsOpened==7,"Native cache count must override spending inference")
update(FieldKitFrame,.2);assert(FieldKitMoneyFrame:IsShown() and FieldKitStatsFrame:IsShown())
-- Appearance work is cached only with an official numeric stamp; texture identity
-- remains independent from the target and invalidates on stamp/table/language changes.
local reads=0
local values={id=7,name="Brute gordunni",displayId=nil}
local row=setmetatable({},{__index=function(_,key) reads=reads+1;return values[key] end})
AZS_ZONE.zone="feralas";AZS_UNITS={row};AZS_UNITS_UPDATED=10
local p=FieldKit_Portraits
p.Apply(FieldKitBossFrame1,values.name,"boss",7)
local first=reads;assert(first>0)
TARGET="Unrelated wolf"
for i=1,100 do p.Apply(FieldKitBossFrame1,values.name,"boss",7) end
assert(reads==first,"Unchanged portrait rescanned native units")
assert(string.find(FieldKitBossFrame1.mashPortraitPath,"gordunni",1,true))
FieldKitDB.language="fr";p.Apply(FieldKitBossFrame1,values.name,"boss",7)
assert(reads>first);first=reads
values.displayId=999;AZS_UNITS_UPDATED=11;p.Apply(FieldKitBossFrame1,values.name,"boss",7)
assert(FieldKitBossFrame1.mashPortraitPath=="Interface\\Icons\\INV_Misc_QuestionMark")
AZS_UNITS={{id=7,name=values.name}} -- replacement pointer, same timestamp
p.Apply(FieldKitBossFrame1,values.name,"boss",7)
assert(string.find(FieldKitBossFrame1.mashPortraitPath,"gordunni",1,true))
-- Missing stamps keep the legacy uncached behavior, including in-place changes.
AZS_UNITS_UPDATED=nil;AZS_UNITS[1].displayId=999
p.Apply(FieldKitBossFrame1,values.name,"boss",7)
assert(FieldKitBossFrame1.mashPortraitPath=="Interface\\Icons\\INV_Misc_QuestionMark")
AZS_UNITS[1].displayId=nil;p.Apply(FieldKitBossFrame1,values.name,"boss",7)
assert(string.find(FieldKitBossFrame1.mashPortraitPath,"gordunni",1,true))
