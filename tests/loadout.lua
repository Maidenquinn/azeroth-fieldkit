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
function tip:SetSpell(i,book)
 line("FieldKitLoadoutScanTextLeft1","Fireball",false)
 line("FieldKitLoadoutScanTextRight1","Rank 3",false)
 line("FieldKitLoadoutScanTextLeft2","+8% damage",true)
 line("FieldKitLoadoutScanTextLeft3","-16% cooldown",true)
end
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
assert(L.spells[1].rank=="Rank 7" and L.spells[1].bonuses[1]=="+8% damage")
assert(L.frame:IsShown() and L.frame.rows[1].bonus:GetText()=="+8% damage · -16% cooldown")
assert(L.items[11].bonuses[1]=="+82% damage" and not L.items[11].rank,"Jewelry rank was guessed")
assert(L.frame.fieldkitMinimumHeight>=60)
L.frame.mashCollapsed=true;L.Update();assert(not L.frame.rows[1]:IsShown())
L.frame.mashCollapsed=false;L.Update()
local meter=FieldKitMeterFrame.rows[1]
FieldKit.UpdateMeterColumns(meter,{name="Fireball",dmg=100,dps=10,share=1},3,360)
assert(meter.fieldkitSpellIcon:IsShown() and meter.fieldkitIconInset==18)
FieldKit.UpdateMeterColumns(meter,{name="Unmapped ability",dmg=100,dps=10,share=1},3,360)
assert(not meter.fieldkitSpellIcon:IsShown() and meter.fieldkitIconInset==0)
-- The existing equipment card gains passive bonus text, preserving item names.
function GetInventoryItemLink() return "|cff0070dd|Hitem:1|h[Example Ring III]|h|r" end
update(FieldKitFrame,.3)
assert(FieldKitGearFrame.slots[1].bonus:GetText()=="+82% damage · +4% critical strike")
assert(FieldKitGearFrame:GetHeight()>=174)
-- Next boss is inside Lairs, independent of the separate reminders option.
function AZS_GetLairs() return {{name="Guardian",state="asleep",x=1,y=1}} end
function AZS_GetUpcomingBosses() return {{name="Scheduled boss",left=65,index=2}} end
FieldKitDB.nextBossCard=false;update(FieldKitFrame,.3)
assert(string.find(FieldKitLairFrame.nextBoss:GetText(),"Scheduled boss",1,true))
assert(FieldKitLairFrame.fieldkitFooterHeight==20)
-- Partial named melee observations need exact source text AND fresh native kind.
D.Reset();AZS_UNITS_UPDATED=GetTime();AZS_UNITS={{kind="normal",name="Wolf"},{kind="elite",name="Ogre"}}
D.Capture("Wolf hits you for 20.");D.Capture("Ogre critically hits you for 30.")
D.Capture("Unknown hits you for 999.");D.Capture("Wolf's Fireball hits you for 999.")
assert(D.buckets["mob melee"].Wolf==20 and D.buckets.elite.Ogre==30 and D.count==2)
AZS_UNITS[3]={kind="elite",name="Wolf"};D.Capture("Wolf hits you for 80.")
assert(D.buckets["mob melee"].Wolf==20,"Conflicting creature name was attributed")
local count=0;GameTooltip.AddLine=function(self,text) if string.find(text,"Wolf: 20",1,true) then count=count+1 end end
D.Show({takenSource="mob melee",takenDamage=100});assert(count==1)
local previous=FieldKitNative.serial;AZS_RUN.t=1;FieldKitNative.Watch()
D.Capture("Ogre hits you for 12.");assert(D.count==0 and FieldKitNative.serial>previous)
L.Update();assert(L.spells[1].rank=="Rank 3","Stale native rank survived a run change")
print("Native loadout tooltips, ranks, icons, lair arrival, partial named taken and reset fixtures passed")
