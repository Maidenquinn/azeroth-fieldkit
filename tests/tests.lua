-- Run only in the mock client. These fixtures are never loaded by the game's TOC.
string.match=nil;string.gmatch=nil
function SetPortraitTexture() error("Forbidden target-bound portrait") end
-- Every tab callback must open exactly its own page, including after repeated use.
for i=1,table.getn(FieldKitPanel.tabs) do
 click(FieldKitPanel.tabs[i]);assert(FieldKitDB.panelTab==i)
 for j=1,table.getn(FieldKitPanel.tabs) do assert(FieldKitPanel.tabs[j].page:IsShown()==(i==j)) end
end
local namepaths={
 {"Brute gordunni","gordunni"},{"Tréant de Crochebois","warpwood"},
 {"Protecteur Écorce-de-fer","ironbark"},{"Zevrim Sabot-de-ronce","zevrim"}}
for i=1,table.getn(namepaths) do
 AZS_UNITS[1].name=namepaths[i][1]
 for _,target in ipairs({false,"Young Wolf","Another enemy",namepaths[i][1],false}) do
  TARGET=target or nil
  FieldKit_Portraits.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",5001)
  assert(FieldKitBossFrame1.portrait.texture=="Interface\\AddOns\\AzerothFieldKit\\Portraits\\"..namepaths[i][2])
 end
end
AZS_UNITS[2]={name=AZS_UNITS[1].name,id=5002}
FieldKit_Portraits.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",5001)
FieldKit_Portraits.Apply(FieldKitBossFrame2,AZS_UNITS[1].name,"guardian",5002)
assert(FieldKitBossFrame1.portrait.texture=="Interface\\AddOns\\AzerothFieldKit\\Portraits\\zevrim")
assert(FieldKitBossFrame2.portrait.texture==FieldKitBossFrame1.portrait.texture)
assert(FieldKitBossFrame1.mashPortraitIdentity~=FieldKitBossFrame2.mashPortraitIdentity)
AZS_UNITS[1].displayId=999
FieldKit_Portraits.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",5001)
assert(FieldKitBossFrame1.portrait.texture=="Interface\\Icons\\INV_Misc_QuestionMark")
AZS_UNITS[1].displayId=nil
AZS_UNITS[2]=nil;AZS_ZONE.zone="anotherzone";FieldKit_Portraits.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",5001)
assert(FieldKitBossFrame1.portrait.texture=="Interface\\Icons\\INV_Misc_QuestionMark")
AZS_ZONE.zone="feralas";AZS_UNITS[1].name="Brute gordunni"
assert(FieldKit_FormatHealth(6705,12200,1)=="6705 / 12200")
assert(FieldKit_FormatHealth(6705,12200,2)=="55%")
assert(FieldKit_FormatHealth(6705,12200,3)=="6705 / 12200 (55%)")
assert(FieldKit_FormatHealth(nil,0,3)=="0 / 0 (0%)")
-- Saved options must survive reopening and reinitialization.
FieldKitDB.playerHealthMode=3;FieldKitDB.targetHealthMode=2;FieldKitDB.combatTextX=-123
SlashCmdList.FieldKit("");SlashCmdList.FieldKit("")
assert(FieldKitDB.playerHealthMode==3 and FieldKitDB.targetHealthMode==2 and FieldKitDB.combatTextX==-123)
-- Collapse and expand all meter-style windows, then reload their persisted states.
for _,f in ipairs({FieldKitMeterFrame,FieldKitTakenFrame,FieldKitLairFrame}) do
 assert(f and f.mashCollapseButton)
 click(f.mashCollapseButton);assert(f.mashCollapsed and f.height==24)
 assert(FieldKitDB.collapsedWindows[f.name])
 click(f.mashCollapseButton);assert(not f.mashCollapsed and f.height>24)
end
-- Combat grouping uses skill + category, sums different amounts, and keeps crits apart.
FieldKitDB.combatText=true;FieldKitDB.combatTextGroup=true;FieldKitDB.combatTextMin=0;FieldKitDB.combatTextMax=5
fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Backstab hits Wolf for 100.")
fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Backstab hits Wolf for 200.")
fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Backstab crits Wolf for 400.")
update(FieldKitCombatText,.3)
local texts={}
for i=1,table.getn(FieldKitCombatText.children) do local s=FieldKitCombatText.children[i];if s:IsShown() then texts[s.text]=true end end
assert(texts["Backstab 300 x2"] and texts["Backstab 400"])
-- Burst saturation: bounds and nonoverlap, then a smooth rise and eventual fade/expiry.
FieldKitDB.combatTextGroup=false
for i=1,300 do fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Skill"..i.." hits Wolf for "..i..".") end
update(FieldKitCombatText,.1)
local visible={}
for i=1,table.getn(FieldKitCombatText.children) do local s=FieldKitCombatText.children[i];if s:IsShown() then table.insert(visible,s) end end
assert(table.getn(visible)==5)
table.sort(visible,function(a,b) return a.point[5]<b.point[5] end)
for i=2,5 do assert(visible[i].point[5]-visible[i-1].point[5]>=FieldKitDB.combatTextSpacing) end
local first=visible[1];local y=first.point[5];update(FieldKitCombatText,.2);assert(first.point[5]>y)
update(FieldKitCombatText,1);assert(first.alpha<1 and first.alpha>0)
update(FieldKitCombatText,1);for i=1,table.getn(FieldKitCombatText.children) do assert(not FieldKitCombatText.children[i]:IsShown()) end
-- Disabling clears pending work, so no stale message can reappear.
FieldKitDB.combatTextGroup=true;fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Backstab hits Wolf for 100.")
FieldKitDB.combatText=false;update(FieldKitCombatText,.1);FieldKitDB.combatText=true;update(FieldKitCombatText,.3)
for i=1,table.getn(FieldKitCombatText.children) do assert(not FieldKitCombatText.children[i]:IsShown()) end
-- Native healing totals establish a baseline, emit positive deltas only, and reset safely.
FieldKitDB.combatTextGroup=false;FieldKitDB.combatTextHealing=true
AZS_HEALING={{name="Renew",dmg=100}};AZS_HEALING_UPDATED=1;update(FieldKitCombatText,.1)
AZS_HEALING[1].dmg=170;AZS_HEALING_UPDATED=2;update(FieldKitCombatText,.1)
local found=false
for i=1,table.getn(FieldKitCombatText.children) do if FieldKitCombatText.children[i].text=="Heal: Renew 70" then found=true end end
assert(found)
FieldKitDB.combatText=true;FieldKitDB.combatTextGroup=false
fire(FieldKitCombatText,"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE","Wolf suffers 30 Shadow damage from your Garrote.")
fire(FieldKitCombatText,"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE","You suffer 13 Fire damage from Wolf's Burn.")
update(FieldKitCombatText,.1)
local dot,taken=false,false
for i=1,table.getn(FieldKitCombatText.children) do
 local s=FieldKitCombatText.children[i]
 if s:IsShown() and s.text=="Garrote 30" then dot=true end
 if s:IsShown() and s.text=="Burn 13" then taken=true end
end
assert(dot and taken)
for _,f in ipairs({FieldKitStatsFrame,FieldKitGearFrame}) do
 click(f.mashCollapseButton);assert(f.height==23)
 click(f.mashCollapseButton);assert(f.height>23)
end
click(FieldKitMeterFrame.mashCollapseButton)
FieldKitDB.statsCollapsed=true;FieldKitDB.gearCollapsed=true
FieldKitDB.pos.FieldKitMeterFrame={99999,-99999}
FieldKitDB.panelTab=4;FieldKitDB.bossHealthMode=3
-- A phase transition within a run must preserve the healing baseline.
FieldKitDB.combatText=true;FieldKitDB.combatTextGroup=false;FieldKitDB.combatTextHealing=true
AZS_HEALING={{name="Renew",dmg=200}};AZS_HEALING_UPDATED=3;update(FieldKitCombatText,.1)
AZS_RUN.ph="choosing";AZS_HEALING[1].dmg=210;AZS_HEALING_UPDATED=4;update(FieldKitCombatText,.1)
local transitionHeal=false
for i=1,table.getn(FieldKitCombatText.children) do if FieldKitCombatText.children[i].text=="Heal: Renew 10" then transitionHeal=true end end
assert(transitionHeal);AZS_RUN.ph="playing"
-- Regression from the user's screenshots: four lairs, including two separate Brutes.
AZS_RUN.ph="playing";AZS_ZONE.zone="feralas"
AZS_UNITS={
 {kind="guardian",id=687865983,name="Brute gordunni",hp=11501,hpm=12305,state=1},
 {kind="guardian",id=687865986,name="Brute gordunni",hp=12305,hpm=12305,state=0},
 {kind="guardian",id=704643200,name="Tréant de Crochebois",hp=100,hpm=100,state=0},
 {kind="guardian",id=721420417,name="Protecteur Écorce-de-fer",hp=100,hpm=100,state=0}}
for _,target in ipairs({false,"Young Wolf","Brute gordunni","Another enemy",false}) do
 TARGET=target or nil
 fire(FieldKitFrame,"PLAYER_TARGET_CHANGED")
 assert(FieldKitBossFrame1.portrait.texture=="Interface\\AddOns\\AzerothFieldKit\\Portraits\\gordunni")
 assert(string.find(FieldKitBossFrame1.mashPortraitReason,"instances=2",1,true))
end
-- Both awake guardians share the verified appearance but preserve their own instance ids/HP.
AZS_UNITS[2].state=1;AZS_UNITS[2].hp=9000
fire(FieldKitFrame,"PLAYER_TARGET_CHANGED")
assert(FieldKitBossFrame2.portrait.texture==FieldKitBossFrame1.portrait.texture)
assert(FieldKitBossFrame1.mashPortraitIdentity~=FieldKitBossFrame2.mashPortraitIdentity)
assert(FieldKitBossFrame1.bar.value==11501 and FieldKitBossFrame2.bar.value==9000)
-- Resolve every localized alias on every map, with duplicate instances and another target.
local zones,aliases=0,0
local entries={}
for zone,names in pairs(FieldKit_PortraitCatalog) do
 zones=zones+1;AZS_ZONE.zone=zone
 for name,data in pairs(names) do
  aliases=aliases+1;entries[data.entry]=true
  AZS_UNITS={{id=10001,name=name},{id=10002,name=name}}
  TARGET="Unrelated creature"
  FieldKit_Portraits.Apply(FieldKitBossFrame1,name,"boss",10001)
  FieldKit_Portraits.Apply(FieldKitBossFrame2,name,"boss",10002)
  assert(FieldKitBossFrame1.portrait.texture=="Interface\\AddOns\\AzerothFieldKit\\Portraits\\"..data.key)
  assert(FieldKitBossFrame2.portrait.texture==FieldKitBossFrame1.portrait.texture)
  assert(FieldKitBossFrame1.mashPortraitIdentity~=FieldKitBossFrame2.mashPortraitIdentity)
  TARGET=nil;FieldKit_Portraits.Apply(FieldKitBossFrame1,name,"boss",10001)
  assert(FieldKitBossFrame1.portrait.texture==FieldKitBossFrame2.portrait.texture)
 end
end
local count=0;for entry in pairs(entries) do count=count+1 end
assert(zones==12 and aliases==1063 and count==100)
assert(FieldKit_PortraitCatalogInfo.bosses==60 and FieldKit_PortraitCatalogInfo.guardians==40)
AZS_ZONE.zone="feralas"
