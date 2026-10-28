-- External global editing never requires a visible settings panel. Only owned
-- HUD frames are affected; grouping and per-window preferences remain intact.
FieldKitDB={linkLeftCards=true,linkRightCards=true,combatText=true}
fire(FieldKitFrame,"VARIABLES_LOADED")
assert(not FieldKit.layoutEditing and not FieldKitUI.frame)
SlashCmdList.FieldKit("lock");assert(not FieldKitUI.frame)
SlashCmdList.FieldKit("unlock")
local U=FieldKitUI
assert(FieldKit.layoutEditing and not U.frame:IsShown() and U.dock:IsShown())
assert(FieldKitCombatAnchor1:IsShown())
local width=FieldKitMeterFrame:GetWidth()
-- A moving group must stop and save its native anchor when the global lock is issued.
this=FieldKitMeterFrame;FieldKitMeterFrame:GetScript("OnDragStart")()
assert(FieldKitHudStack.root.azsMoving)
FieldKitHudStack.root:ClearAllPoints();FieldKitHudStack.root:SetPoint("TOPLEFT",UIParent,"TOPLEFT",14,-60)
SlashCmdList.FieldKit("lock")
assert(not FieldKit.layoutEditing and not U.frame:IsShown() and not U.dock:IsShown())
assert(not FieldKitHudStack.root.azsMoving and FieldKitDB.frameAnchors.FieldKitLeftStack[3]==14)
assert(FieldKitDB.linkLeftCards and FieldKitDB.linkRightCards and FieldKitMeterFrame:GetWidth()==width)
assert(not FieldKitCombatAnchor1:IsShown())
this=FieldKitMeterFrame;FieldKitMeterFrame:GetScript("OnDragStart")();assert(not FieldKitHudStack.root.azsMoving)

-- External Done locks without unexpectedly opening settings.
SlashCmdList.FieldKit("UNLOCK");click(U.done)
assert(not FieldKit.layoutEditing and not U.frame:IsShown())
-- Right-click toggles global state; left-click is still an explicit settings action.
local shortcut=FieldKitMinimapButton
this=shortcut;arg1="RightButton";shortcut:GetScript("OnClick")()
assert(FieldKit.layoutEditing and not U.frame:IsShown())
this=shortcut;arg1="RightButton";shortcut:GetScript("OnClick")()
assert(not FieldKit.layoutEditing and not U.frame:IsShown())
SlashCmdList.FieldKit("unlock")
this=shortcut;arg1="LeftButton";shortcut:GetScript("OnClick")()
assert(not FieldKit.layoutEditing and U.frame:IsShown())
click(U.move);click(U.done);assert(U.frame:IsShown(),"Settings-driven placement lost its return journey")

SlashCmdList.FieldKit("unlock");click(U.sizes)
assert(U.frame:IsShown() and FieldKitDB.uiPage=="windows" and not FieldKit.layoutEditing)
SlashCmdList.FieldKit("unlock")
this=FieldKitCombatAnchor1;FieldKitCombatAnchor1:GetScript("OnDragStart")()
assert(FieldKitCombatAnchor1.fieldkitMoving)
SlashCmdList.FieldKit("lock")
assert(not FieldKitCombatAnchor1.fieldkitMoving and not FieldKitCombatAnchor1:IsShown())

-- Independent cards stop individually; Escape locks without opening settings.
FieldKitDB.linkLeftCards=false;FieldKitHudStack.Apply()
SlashCmdList.FieldKit("unlock")
this=FieldKitTakenFrame;FieldKitTakenFrame:GetScript("OnDragStart")()
FieldKitTakenFrame:ClearAllPoints();FieldKitTakenFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",0,-30)
U.dock:Hide();this=U.dock;U.dock:GetScript("OnHide")()
assert(not FieldKit.layoutEditing and not U.frame:IsShown() and not FieldKitTakenFrame.azsMoving)
assert(FieldKitDB.frameAnchors.FieldKitTakenFrame[3]==0)
assert(FieldKitDB.windowsUnlocked==nil,"The edit mode should not persist across reloads")
print("Global lock commands, minimap toggle, active-drag stopping and settings return fixtures passed")
