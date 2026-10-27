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
