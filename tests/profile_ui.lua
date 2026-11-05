-- Native UI manager exercises actual click handlers and confirmation flows.
fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
local U=FieldKitUI
assert(U and U.frame and U.sections)
U.Select("profiles")
assert(FieldKitDB.uiPage=="profiles")
local row=U.profileView
assert(row and table.getn(row.slots)==3)
local s1=row.slots[1]
assert(not FieldKitDB.interfaceProfiles[1])
local current=FieldKitDB.cardOpacity
click(s1.save)
assert(FieldKitDB.interfaceProfiles[1] and FieldKitDB.interfaceProfiles[1].values.cardOpacity==current)
FieldKitDB.cardOpacity=39
click(s1.save)
assert(FieldKitDB.interfaceProfiles[1].values.cardOpacity==current,"existing profile overwritten without confirmation")
click(s1.save)
assert(FieldKitDB.interfaceProfiles[1].values.cardOpacity==39)
FieldKitDB.cardOpacity=88
click(s1.load)
assert(FieldKitDB.profilePendingSlot==1 and FieldKitDB.cardOpacity==88,
 "UI profile load must be staged")
assert(row.cancel:IsShown())
click(row.cancel)
assert(FieldKitDB.profilePendingSlot==nil and FieldKitDB.cardOpacity==88)
click(s1.delete)
assert(FieldKitDB.interfaceProfiles[1],"first delete click must only ask for confirmation")
click(s1.delete)
assert(FieldKitDB.interfaceProfiles[1]==nil,"confirmed delete should remove profile")
click(s1.save)
FieldKitDB.cardOpacity=76
click(s1.load)
U.Refresh()
assert(FieldKitDB.cardOpacity==76 and FieldKitDB.profilePendingSlot==1)
U.Select("layout");U.Select("profiles")
assert(FieldKitDB.profilePendingSlot==1)
-- Reflow and language switching must not mutate current HUD.
local total=table.getn(objects)
FieldKit_SetLanguage("fr");U.Refresh();U.Reflow()
assert(FieldKitDB.cardOpacity==76 and FieldKitDB.profilePendingSlot==1)
FieldKit_SetLanguage("en");U.Refresh()
assert(table.getn(objects)==total,"profile UI must reuse existing controls")
click(row.cancel)
assert(not FieldKitDB.profilePendingSlot)
