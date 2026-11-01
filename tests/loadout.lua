-- Actual tooltip readers and row geometry with explicit synthetic native data.
FieldKitDB={}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
local L,D=FieldKitLoadout,FieldKitTakenDetails
local tip=FieldKitLoadoutScan
assert(tip)
local function line(name,text,green)
 local fs=getglobal(name) or CreateFrame("FontString",name)
 fs:SetText(text);fs.GetTextColor=function() if green then return .1,1,.1 else return 1,1,1 end end
end
function tip:NumLines() return 3 end
function tip:SetAction(i)
 line("FieldKitLoadoutScanTextLeft1","Boule de feu",false)
 line("FieldKitLoadoutScanTextRight1","",false)
 line("FieldKitLoadoutScanTextLeft2","Description\nAméliorations : +4% de dégâts\nTalents : +50%\n|cff1eff00Vos bonus : +8% de dégâts, -16% de recharge|r",false)
 line("FieldKitLoadoutScanTextLeft3","",false)
end
function HasAction(slot) return slot==1 end
function GetActionTexture() return "Interface\\Icons\\Spell_Fire_FlameBolt" end
function tip:SetInventoryItem(unit,slot)
 line("FieldKitLoadoutScanTextLeft1","Example Ring III",false)
 line("FieldKitLoadoutScanTextRight1","",false)
 line("FieldKitLoadoutScanTextLeft2","+82% damage",true)
 line("FieldKitLoadoutScanTextLeft3","+4% critical strike",true)
end
function GetSpellName(i) if i==1 then return "Fireball","Rank 3" end end
function GetSpellTexture() return "Interface\\Icons\\Spell_Fire_FlameBolt" end
AZS_SPELLS={{key="fireball",spell=133,rank=7}}
L.scanAt=0;L.Update()
assert(L.spells[1].rank=="Rank 7" and L.spells[1].name=="Boule de feu")
assert(L.spells[1].bonuses[1]=="+8% de dégâts" and L.spells[1].bonuses[2]=="-16% de recharge")
assert(L.spells[1].upgrades[1]=="+4% de dégâts" and table.getn(L.spells)==1)
assert(L.frame==FieldKitGearFrame and not getglobal("FieldKitSpellsFrame"),"A separate spell window was created")
click(L.frame.loadoutTabs[2]);assert(L.frame.spellRows[1].bonus:GetText()=="+8% de dégâts\n-16% de recharge")
assert(L.items[11].bonuses[1]=="+82% damage" and not L.items[11].rank,"Jewelry rank was guessed")
assert(L.frame.fieldkitMinimumHeight>=60)
assert(L.IsStat("+12% critical") and not L.IsStat("Equip: Increases your chance to hit"))
assert(not L.IsStat("Réduit tous les dégâts subis de 10%") and not L.IsStat("Augmente vos points de vie max de 15%"))
assert(L.CompactBonus("Augmente votre chance de 72%.")=="+72% chance")
assert(L.CompactBonus("Réduit tous les dégâts subis de 10%")=="-10% dmg")
assert(L.spells[1].rankValue==7)
local r,g,b=L.RankColor(7);assert(r and g and b and r<.5)
assert(L.Icon("Saccager") and L.Icon("Rafale") and L.Icon("Blessures profondes"))
FieldKitDB.gearCollapsed=true;L.Render(L.frame);assert(not L.frame.spellRows[1]:IsShown())
FieldKitDB.gearCollapsed=false;L.Render(L.frame);click(L.frame.loadoutTabs[1])
local meter=FieldKitMeterFrame.rows[1]
FieldKit.UpdateMeterColumns(meter,{name="Fireball",dmg=100,dps=10,share=1},3,360)
assert(meter.fieldkitSpellIcon:IsShown() and meter.fieldkitIconInset==18)
FieldKit.UpdateMeterColumns(meter,{name="Unmapped ability",dmg=100,dps=10,share=1},3,360)
assert(not meter.fieldkitSpellIcon:IsShown() and meter.fieldkitIconInset==0)
-- The existing equipment card gains passive bonus text, preserving item names.
function GetInventoryItemLink() return "|cff0070dd|Hitem:1|h[Example Ring III]|h|r" end
function tip:SetInventoryItem(unit,slot)
 line("FieldKitLoadoutScanTextLeft1","Example Ring III",false)
 line("FieldKitLoadoutScanTextLeft2","Equip: Increases your chance to hit by fluff.",true)
 line("FieldKitLoadoutScanTextLeft3","+4% critical strike",true)
end
L.scanAt=0;L.Update();update(FieldKitFrame,.3)
assert(FieldKitGearFrame.slots[1].bonus:GetText()=="+4% critical strike")
assert(not string.find(FieldKitGearFrame.slots[1].bonus:GetText() or "","Equip",1,true))
assert(string.find(FieldKitGearFrame.slots[1].label:GetText() or "","Example Ring III",1,true),"Equipped jewelry still shows the slot label")
assert(FieldKitGearFrame.slots[1].value:GetText()=="")
assert(FieldKitGearFrame:GetHeight()>=174)
-- Prose-only green inventory lines must not flood the card.
function GetInventoryItemLink() return "|cff0070dd|Hitem:1|h[Médaillon de paix]|h|r" end
function tip:SetInventoryItem(unit,slot)
 line("FieldKitLoadoutScanTextLeft1","Médaillon de paix",false)
 line("FieldKitLoadoutScanTextLeft2","Réduit tous les dégâts subis de 10%.",true)
 line("FieldKitLoadoutScanTextLeft3","+12% critical strike",true)
end
L.scanAt=0;L.Update();update(FieldKitFrame,.3)
assert(string.find(FieldKitGearFrame.slots[1].label:GetText() or "","Médaillon de paix",1,true))
local medallion=FieldKitGearFrame.slots[1].bonus:GetText() or ""
assert(string.find(medallion,"+12% critical strike",1,true) and string.find(medallion,"-10% dmg",1,true))
assert(not string.find(medallion,"Réduit",1,true))
-- French Equip prose becomes a compact boost instead of vanishing.
function tip:SetInventoryItem(unit,slot)
 line("FieldKitLoadoutScanTextLeft1","Marque de l'Élu",false)
 line("FieldKitLoadoutScanTextLeft2","Equip: Augmente votre chance de 72%.",true)
end
function GetInventoryItemLink() return "|cff0070dd|Hitem:2|h[Marque de l'Élu]|h|r" end
L.scanAt=0;L.Update();update(FieldKitFrame,.3)
assert(FieldKitGearFrame.slots[1].bonus:GetText()=="+72% chance")
-- Next boss is inside Lairs, independent of the separate reminders option.
function AZS_GetLairs() return {{name="Guardian",state="asleep",x=1,y=1}} end
function AZS_GetUpcomingBosses() return {{name="Scheduled boss",left=65,index=2}} end
FieldKitDB.nextBossCard=false;AZS_UNITS={};update(FieldKitFrame,.3)
assert(string.find(FieldKitLairFrame.nextBoss:GetText(),"Scheduled boss",1,true))
assert(FieldKitLairFrame.fieldkitFooterHeight==28)
AZS_UNITS={{kind="boss",name="Live Boss",hp=50,hpm=100,state=0}};update(FieldKitFrame,.3)
assert(FieldKitLairFrame.bossBar:IsShown() and FieldKitLairFrame.nextBoss:GetText()=="Live Boss")
assert(FieldKitLairFrame.fieldkitFooterHeight==40)
-- Partial named melee observations need exact source text AND fresh native kind.
D.Reset();AZS_UNITS_UPDATED=GetTime();AZS_UNITS={{kind="normal",name="Wolf"},{kind="elite",name="Ogre"}}
D.Capture("Wolf hits you for 20.");D.Capture("Ogre critically hits you for 30.")
D.Capture("Unknown hits you for 999.");D.Capture("Wolf's Fireball hits you for 40.")
assert(D.buckets["mob melee"].Wolf==20 and D.buckets.elite.Ogre==30 and D.buckets["mob spell"].Wolf==40 and D.count==3)
D.Capture("Ogre's Smash hits you for 15.")
assert(D.buckets.elite.Ogre==45 and D.count==3)
AZS_UNITS[3]={kind="elite",name="Wolf"};D.Capture("Wolf hits you for 80.")
assert(D.buckets["mob melee"].Wolf==20,"Conflicting creature name was attributed")
local count=0;GameTooltip.AddLine=function(self,text) if string.find(text,"Wolf: 20",1,true) then count=count+1 end end
D.Show({takenSource="mob melee",takenDamage=100});assert(count==1)
local previous=FieldKitNative.serial;AZS_RUN.t=1;FieldKitNative.Watch()
D.Capture("Ogre hits you for 12.");assert(D.count==0 and FieldKitNative.serial>previous)
L.Update();assert(table.getn(L.spells)==0,"Stale native learned spells survived a run change")
print("Native loadout tooltips, ranks, icons, lair arrival, partial named taken and reset fixtures passed")
