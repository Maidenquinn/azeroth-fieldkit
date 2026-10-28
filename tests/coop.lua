-- Native co-op payloads and roster tokens, no invented combat messages.
local members={
 {name="Denza",hp=400,max=800,mana=30,mp=100,class="Mage",key="MAGE",power=0,online=true},
 {name="Lockpin",hp=0,max=600,mana=0,mp=100,class="Priest",key="PRIEST",power=0,online=true},
 {name="Empe",hp=300,max=300,mana=70,mp=100,class="Warrior",key="WARRIOR",power=1,online=false},
}
local function member(unit)
 local _,_,i=string.find(unit,"^party(%d)$");return i and members[tonumber(i)]
end
function UnitExists(unit) return unit=="player" or member(unit)~=nil end
function UnitName(unit) local m=member(unit);return m and m.name or (unit=="player" and "Maiden" or nil) end
function UnitHealth(unit) local m=member(unit);return m and m.hp or 200 end
function UnitHealthMax(unit) local m=member(unit);return m and m.max or 200 end
function UnitMana(unit) local m=member(unit);return m and m.mana or 0 end
function UnitManaMax(unit) local m=member(unit);return m and m.mp or 100 end
function UnitPowerType(unit) local m=member(unit);return m and m.power or 1 end
function UnitClass(unit) local m=member(unit);return m and m.class or "Warrior",m and m.key or "WARRIOR" end
function UnitIsConnected(unit) local m=member(unit);if m then return m.online end;return true end
local originals={};local shows=0
for i=1,4 do
 local f=CreateFrame("Frame","PartyMemberFrame"..i,UIParent)
 originals[i]=function() shows=shows+1 end;f:SetScript("OnShow",originals[i])
end
FieldKitDB={partyCards=false,partyMeter=true,meterValues=3}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
local P,U=FieldKitCoop,FieldKitUI
local function control(label)
 for i=1,table.getn(U.controls) do local c=U.controls[i];if c.label==label or (c.item and c.item.label==label) then return c end end
 error(label)
end
local function rows(frame,text)
 for i=1,table.getn(frame.rows) do if frame.rows[i]:IsShown() and frame.rows[i].label:GetText()==text then return frame.rows[i] end end
end

-- Missing by-source packet, authoritative counter present: never show a fake 0.
AZS_TAKEN={};AZS_RUN.taken=500;update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="500")
assert(rows(FieldKitTakenFrame,"Unattributed (native total)").value:GetText()=="500  100%")
AZS_RUN.taken=650;update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="650","Unchanged source stamp cached a stale total")
AZS_TAKEN={{source="mob melee",dmg=200},{source="boss spell",dmg=100}}
AZS_RUN.taken=500;update(FieldKitFrame,.3)
assert(rows(FieldKitTakenFrame,"Monster melee").value:GetText()=="200  40%")
assert(rows(FieldKitTakenFrame,"Unattributed (native total)").value:GetText()=="200  40%")
AZS_RUN.taken=0;update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="300","A lagging total erased a received source list")
AZS_TAKEN={};AZS_RUN.taken=nil;update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="Not provided")
assert(rows(FieldKitTakenFrame,"Damage data not provided"))
AZS_RUN.taken=0;update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="0" and rows(FieldKitTakenFrame,"No damage taken yet"))
AZS_TAKEN={{source="mob melee",dmg="bad"},false,{source="x",dmg=0/0}}
local list,total,known=P.Taken();assert(table.getn(list)==0 and total==0 and known)

-- No stale snapshot inherited at initialization. Exact peer DPS comes from API.
assert(P.meter.rows[1].label:GetText()=="Waiting for group data")
AZS_PARTY={
 {name="Denza",dmg=500,dps=50,share=.5},
 {name="Maiden",dmg=300,dps=30,share=.3},
 {name="Empe",dmg=100,dps=10,share=.1},
 {name="Lockpin",dmg=100,dps=10,share=.1},
 {name="Unknown former peer",dmg=999999,dps=999999,share=1},
 {name="Denza",dmg=9999,dps=9999,share=1},
}
function AZS_GetPartyMeter() return AZS_PARTY,123,456 end
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSPARTY");AZS_PARTY_UPDATED=NOW;update(FieldKitFrame,.3)
assert(table.getn(P.party)==4 and P.partyTotal==1000 and P.partyDps==100)
assert(P.meter.rows[1].label:GetText()=="Denza")
assert(P.meter.rows[1].meterColumns[1]:GetText()=="500" and P.meter.rows[1].meterColumns[2]:GetText()=="50 dps")
assert(P.meter.rows[1].meterColumns[3]:GetText()=="50%")
assert(PartyMemberFrame1:IsShown() and not P.frames[1]:IsShown(),"Replacement was not opt-in")

local cards=control("Co-op teammate cards");cards:SetChecked(true);click(cards)
assert(PartyMemberFrame1:IsShown() and P.frames[1]:IsShown(),"Passive cards hid native interactions by default")
FieldKitDB.replacePartyFrames=true;P.Update()
assert(not PartyMemberFrame1:IsShown())
assert(P.frames[1].title:GetText()=="Denza")
assert(P.frames[1].rows[1].value:GetText()=="400 / 800 (50%)")
assert(P.frames[1].rows[2].label:GetText()=="Mana" and P.frames[1].rows[2].value:GetText()=="30 / 100")
assert(P.frames[1].rows[3].value:GetText()=="500 | 50 dps")
assert(P.frames[2].rows[4].value:GetText()=="0 HP")
assert(P.frames[3].rows[4].value:GetText()=="Offline")
members[3].online=nil;update(FieldKitFrame,.3)
assert(P.frames[3].rows[4].value:GetText()=="Offline","Vanilla nil-false connection flag was not recognised")
local hook=PartyMemberFrame1:GetScript("OnShow")
PartyMemberFrame1:Show();this=PartyMemberFrame1;hook()
assert(shows==1 and not PartyMemberFrame1:IsShown(),"Original OnShow was lost or native frame resurfaced")

-- Move/size one peer without moving another or the left HUD stack.
U.SetLayoutEditing(true,false)
local first=P.frames[1];local second=P.frames[2];local prior=FieldKitDB.frameAnchors.FieldKitPartyCard1
this=second;second:GetScript("OnDragStart")()
second:ClearAllPoints();second:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",0,-90);second:GetScript("OnDragStop")()
assert(FieldKitDB.frameAnchors.FieldKitPartyCard2[3]==0)
assert(FieldKitDB.frameAnchors.FieldKitPartyCard1==prior)
U.SetLayoutEditing(false,true)
FieldKitCardLayout.selected=9;FieldKitCardLayout.SetDimension("width",440);FieldKitCardLayout.SetDimension("height",150)
assert(first:GetWidth()==440 and first:GetHeight()==150 and second:GetWidth()==280)
local format=control("Teammate health format");click(format);click(format.choiceButtons[2])
assert(first.rows[1].value:GetText()=="50%")
members[1].hp=200;update(FieldKitFrame,.3);assert(first.rows[1].value:GetText()=="25%")

-- Unknown max HP keeps native frame available; no replacement pretends it knows.
members[1].max=0;update(FieldKitFrame,.3)
assert(PartyMemberFrame1:IsShown() and not first:IsShown())
members[1].max=800
cards:SetChecked(false);click(cards)
for i=1,3 do assert(not P.frames[i]:IsShown() and getglobal("PartyMemberFrame"..i):IsShown());assert(getglobal("PartyMemberFrame"..i):GetScript("OnShow")==originals[i]) end

-- A roster change without a new party packet cannot retain former DPS values.
members[3]=nil;update(FieldKitFrame,.3)
assert(P.partyTotal==nil and P.meter.rows[1].label:GetText()=="Waiting for group data")
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSPARTY");update(FieldKitFrame,.3)
assert(P.partyTotal==900 and table.getn(P.party)==3)
AZS_RUN.t=1;fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSRUN");update(FieldKitFrame,.3)
assert(P.partyTotal==nil and P.meter.rows[1].label:GetText()=="Waiting for group data")
AZS_TAKEN={{source="mob melee",dmg=123}};AZS_RUN.taken=123;update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="123")
AZS_RUN.t=50;update(FieldKitFrame,.3)
AZS_RUN.t=0;AZS_RUN.taken=0;fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSRUN");update(FieldKitFrame,.3)
assert(FieldKitTakenFrame.total:GetText()=="0","New run inherited the previous run's source totals")
AZS_PARTY={{name="Denza",dmg=7,share=1}};fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSPARTY");update(FieldKitFrame,.3)
assert(P.partyTotal==7 and P.partyDps==nil and P.meter.rows[1].meterColumns[2]:GetText()=="? dps")
members={};update(FieldKitFrame,.3);assert(not P.meter:IsShown())
AZS_RUN.ph=nil;update(FieldKitFrame,.3)
for i=1,4 do assert(not P.frames[i]:IsShown()) end
FieldKit_SetLanguage("fr");assert(FieldKit_L("Unattributed (native total)")=="Non attribués (total natif)")
print("Co-op native taken fallback, party DPS, opt-in frames, native restoration and freshness fixtures passed")
