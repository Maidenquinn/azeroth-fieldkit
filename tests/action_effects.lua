-- Actual optional compact-bar handlers: no slot changes until a player drag.
local calls={}
ClearCursor=function() table.insert(calls,"clear") end
PickupAction=function(id) table.insert(calls,"pickup:"..id) end
PlaceAction=function(id) table.insert(calls,"place:"..id) end
ActionButton1=CreateFrame("Button","ActionButton1",MainMenuBar);ActionButton1:SetID(1)
ActionButton2=CreateFrame("Button","ActionButton2",MainMenuBar);ActionButton2:SetID(2)
FieldKitDB={compactBar=true}
fire(FieldKitFrame,"VARIABLES_LOADED")
update(FieldKitFrame,.1)
assert(table.getn(calls)==0,"Automatic action-slot change")
local hover=ActionButton2
MouseIsOver=function(button) return button==hover end
this=ActionButton1;ActionButton1:GetScript("OnDragStart")()
this=ActionButton1;ActionButton1:GetScript("OnDragStop")()
assert(table.concat(calls,",")=="clear,pickup:1,place:2,place:1,clear")
calls={};hover=nil
this=ActionButton1;ActionButton1:GetScript("OnDragStart")()
this=ActionButton1;ActionButton1:GetScript("OnDragStop")()
assert(table.getn(calls)==0,"Drop outside changed a slot")

-- Native choices hide the action controls. FieldKit must not repair them back
-- into view or leave its own compact background/XP/docked money above cards.
HasAction=function(id) return id==1 end
local anchor=FieldKitDB.pos.FieldKitCompactBar
AZS_RUN.ph="choosing"
ActionButton1:Hide()
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSRUN")
assert(not FieldKitCompactBar:IsShown(),"Compact bar stayed above native choices")
assert(not FieldKitMoneyFrame:IsShown(),"Docked money stayed above native choices")
assert(not ActionButton1:IsShown(),"Choice packet resurrected a native action button")
update(FieldKitFrame,.3)
fire(FieldKitFrame,"PLAYER_MONEY")
assert(not FieldKitCompactBar:IsShown() and not FieldKitMoneyFrame:IsShown(),"Polling/money event undid choice suppression")
assert(not ActionButton1:IsShown(),"Repair loop resurrected a hidden choice button")
assert(FieldKitDB.compactBar and FieldKitDB.pos.FieldKitCompactBar==anchor,"Choice changed saved layout/preferences")
AZS_RUN.ph="playing"
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSRUN")
assert(FieldKitCompactBar:IsShown() and FieldKitMoneyFrame:IsShown(),"Compact HUD did not return after choices")
assert(ActionButton1:IsShown(),"Normal button repair did not resume")

-- Detached money must also yield to native choices; detachment stays saved.
FieldKitDB.moneyDetached=true
AZS_RUN.ph="choosing";update(FieldKitFrame,.3)
assert(not FieldKitCompactBar:IsShown() and not FieldKitMoneyFrame:IsShown())
assert(FieldKitDB.moneyDetached==true)
AZS_RUN.ph="playing";update(FieldKitFrame,.3)
FieldKitDB.moneyDetached=nil
-- Do not restore a compact bar that was already hidden before the choice.
FieldKitCompactBar:Hide()
AZS_RUN.ph="choosing";update(FieldKitFrame,.3)
AZS_RUN.ph="playing";update(FieldKitFrame,.3)
assert(not FieldKitCompactBar:IsShown(),"Choice forced an unrelated hidden bar visible")
local phaseAPI=AZS_GetPhase;AZS_GetPhase=nil
assert(not FieldKit.IsChoiceScreen(),"Missing phase API must not suppress the HUD")
AZS_GetPhase=function() error("phase unavailable") end
assert(not FieldKit.IsChoiceScreen(),"Failing phase API must not throw")
AZS_GetPhase=phaseAPI
assert(table.getn(calls)==0,"Visibility repair changed action slots")
