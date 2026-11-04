-- Default active HUD dragging requires no settings or arrangement mode.
FieldKitDB={linkLeftCards=true,linkRightCards=true,combatText=true}
fire(FieldKitFrame,"VARIABLES_LOADED");update(FieldKitFrame,.3)
assert(FieldKitDB.windowsLocked==false and not FieldKit.layoutEditing and not FieldKitUI.frame)
this=FieldKitMeterFrame;FieldKitMeterFrame:GetScript("OnDragStart")()
assert(FieldKitHudStack.root.azsMoving and not FieldKitUI.frame)
FieldKitHudStack.root:ClearAllPoints();FieldKitHudStack.root:SetPoint("TOPLEFT",UIParent,"TOPLEFT",14,-60)
SlashCmdList.FieldKit("lock")
assert(FieldKitDB.windowsLocked and not FieldKit.layoutEditing and not FieldKitUI.frame)
assert(not FieldKitHudStack.root.azsMoving and FieldKitDB.frameAnchors.FieldKitLeftStack[3]==14)
this=FieldKitMeterFrame;FieldKitMeterFrame:GetScript("OnDragStart")();assert(not FieldKitHudStack.root.azsMoving)
SlashCmdList.FieldKit("UNLOCK")
assert(not FieldKitDB.windowsLocked and not FieldKit.layoutEditing and not FieldKitUI.frame)
this=FieldKitMeterFrame;FieldKitMeterFrame:GetScript("OnDragStart")()
assert(FieldKitHudStack.root.azsMoving);FieldKitMeterFrame:GetScript("OnDragStop")()
local shortcut=FieldKitMinimapButton
this=shortcut;arg1="RightButton";shortcut:GetScript("OnClick")()
assert(FieldKitDB.windowsLocked and not FieldKitUI.frame)
this=shortcut;arg1="RightButton";shortcut:GetScript("OnClick")()
assert(not FieldKitDB.windowsLocked and not FieldKitUI.frame)
this=shortcut;arg1="LeftButton";shortcut:GetScript("OnClick")()
local U=FieldKitUI
assert(U.frame:IsShown() and not FieldKit.layoutEditing and not U.dock:IsShown())
local lock
for i=1,table.getn(U.controls) do
 local c=U.controls[i];if c.item and c.item.label=="Lock window positions" then lock=c end
end
assert(lock)
lock:SetChecked(true);click(lock);assert(FieldKitDB.windowsLocked and U.frame:IsShown())
this=FieldKitStatsFrame;FieldKitStatsFrame:GetScript("OnDragStart")();assert(not FieldKitCardLayout.root.azsMoving)
-- Explicit arrangement temporarily overrides the preference; Done restores it.
click(U.move);assert(FieldKit.layoutEditing and FieldKitDB.windowsLocked)
this=FieldKitStatsFrame;FieldKitStatsFrame:GetScript("OnDragStart")();assert(FieldKitCardLayout.root.azsMoving)
click(U.done);assert(U.frame:IsShown() and FieldKitDB.windowsLocked and not FieldKitCardLayout.root.azsMoving)
lock:SetChecked(false);click(lock)
U.frame:Hide();this=U.frame;U.frame:GetScript("OnHide")()
assert(not U.dock:IsShown() and not U.frame:IsShown() and not FieldKit.layoutEditing)
-- Independent dragging during ordinary play, then locking an active drag.
FieldKitDB.linkLeftCards=false;FieldKitHudStack.Apply()
this=FieldKitTakenFrame;FieldKitTakenFrame:GetScript("OnDragStart")()
assert(FieldKitTakenFrame.azsMoving and not U.frame:IsShown())
FieldKitTakenFrame:ClearAllPoints();FieldKitTakenFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",0,-30)
SlashCmdList.FieldKit("lock")
assert(not FieldKitTakenFrame.azsMoving and FieldKitDB.frameAnchors.FieldKitTakenFrame[3]==0)
assert(FieldKitDB.windowsLocked and not U.frame:IsShown() and not U.dock:IsShown())
SlashCmdList.FieldKit("unlock")
assert(not FieldKitDB.windowsLocked and not U.frame:IsShown() and not U.dock:IsShown())
-- Run-mode updates must not resize or hide a frame while it is being dragged.
local oldMouseButton=IsMouseButtonDown
IsMouseButtonDown=function(button) return button=="LeftButton" end
FieldKitDB.linkLeftCards=false;FieldKitHudStack.Apply()
FieldKitModeFrame:Show()
this=FieldKitModeFrame;FieldKitModeFrame:GetScript("OnDragStart")()
assert(FieldKitModeFrame.azsMoving)
local originalHeight=FieldKitModeFrame:GetHeight()
FieldKitRunMode.Update()
assert(FieldKitModeFrame.azsMoving and FieldKitModeFrame:GetHeight()==originalHeight)
-- Simulate a lost OnDragStop: the global watchdog ends the move on mouse release.
IsMouseButtonDown=function() return false end
update(FieldKitFrame,.05)
assert(not FieldKitModeFrame.azsMoving,"lost release must not leave Run mode stuck to the mouse")
IsMouseButtonDown=oldMouseButton
-- Global locking also finishes an explicit combat-area preview drag.
U.SetLayoutEditing(true,false)
this=FieldKitCombatAnchor1;FieldKitCombatAnchor1:GetScript("OnDragStart")()
SlashCmdList.FieldKit("lock")
assert(not FieldKitCombatAnchor1.fieldkitMoving and not FieldKitCombatAnchor1:IsShown())
assert(not FieldKit.layoutEditing and not U.frame:IsShown() and not U.dock:IsShown())
print("Default gameplay dragging, persistent lock preference and no-panel commands passed")
