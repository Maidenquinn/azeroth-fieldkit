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
assert(s1.rename:IsShown())
click(s1.rename)
assert(s1.edit:IsShown() and not s1.summary:IsShown(),
 "rename editor should replace, never overlap, the summary")
assert(not s1.save:IsShown() and not s1.delete:IsShown())
assert(s1.commit:IsShown() and s1.abort:IsShown())
s1.edit:SetText("Donjons FR")
this=s1.edit;s1.edit.scripts.OnEnterPressed()
assert(FieldKitProfiles.Name(1)=="Donjons FR")
assert(not s1.edit:IsShown())
assert(s1.label.text=="Donjons FR")
assert(s1.summary:IsShown() and not s1.edit:IsShown())
assert(s1.save:IsShown() and not s1.commit:IsShown())
click(s1.rename)
s1.edit:SetText("Should not save")
click(s1.abort)
assert(FieldKitProfiles.Name(1)=="Donjons FR","Cancel must preserve existing name")
click(s1.rename)
s1.edit:SetText("")
click(s1.commit)
assert(s1.edit:IsShown(),"invalid input should keep edit open")
assert(FieldKitProfiles.Name(1)=="Donjons FR")
click(s1.abort)


FieldKitDB.cardOpacity=39
click(s1.save)
assert(FieldKitDB.interfaceProfiles[1].values.cardOpacity==current,"existing profile overwritten without confirmation")
click(s1.save)
assert(FieldKitDB.interfaceProfiles[1].values.cardOpacity==39)
FieldKitDB.cardOpacity=88
click(s1.loadButton)
assert(FieldKitDB.activeHudProfile==1 and FieldKitDB.cardOpacity==39,
 "UI profile load must apply the HUD immediately")
assert(row.cancel:IsShown())
click(row.cancel)
assert(FieldKitDB.profilePendingSlot==nil and FieldKitDB.cardOpacity==88)
assert(FieldKitDB.activeHudProfile==1)
click(s1.delete)
assert(FieldKitDB.interfaceProfiles[1],"first delete click must only ask for confirmation")
click(s1.delete)
assert(FieldKitDB.interfaceProfiles[1]==nil,"confirmed delete should remove profile")
click(s1.save)
assert(FieldKitProfiles.Rename(1,"Donjons FR"))
FieldKitDB.cardOpacity=76
click(s1.loadButton)
U.Refresh()
assert(FieldKitDB.cardOpacity==88 and FieldKitDB.activeHudProfile==1)
U.Select("layout");U.Select("profiles")
assert(FieldKitDB.activeHudProfile==1)
-- Reflow and language switching must not mutate current HUD.
local total=table.getn(objects)
FieldKit_SetLanguage("fr");U.Refresh();U.Reflow()
assert(FieldKitDB.cardOpacity==88 and FieldKitDB.activeHudProfile==1)
FieldKit_SetLanguage("en");U.Refresh()
assert(table.getn(objects)==total,"profile UI must reuse existing controls")
click(row.cancel)
assert(FieldKitDB.activeHudProfile==1)

-- Home quick switches are one click, and empty slots navigate to management.
U.Select("home")
assert(U.quickProfileButtons and table.getn(U.quickProfileButtons)==3)
U.Refresh()
assert(string.find(U.quickProfileButtons[1].fieldkitLabel.text,"Donjons FR",1,true),
 "home quick selector must display the custom profile name")

FieldKitDB.cardOpacity=24
click(U.quickProfileButtons[1])
assert(FieldKitDB.cardOpacity==88 and FieldKitDB.activeHudProfile==1)
click(U.quickProfileButtons[3])
assert(FieldKitDB.uiPage=="profiles")
-- Header controls remain available on every page, without reloading the UI.
assert(U.headerProfileButtons and table.getn(U.headerProfileButtons)==3)
assert(U.headerProfileLayer and U.headerProfileLayer:GetFrameLevel()>U.header:GetFrameLevel(),
 "native drag header must not intercept profile selector clicks")
for i=1,3 do
 assert(U.headerProfileButtons[i]:GetParent()==U.headerProfileLayer)
 assert(U.headerProfileButtons[i]:GetFrameLevel()>U.header:GetFrameLevel())
 assert(U.headerProfileButtons[i]:GetScript("OnClick"))
end
local _,parent,_,offx,offy=U.headerProfileLayer:GetPoint()
assert(parent==U.frame and offx==-34 and offy==-72,
 "header shortcuts must retain the visible fixed right anchor")

U.Select("look")
FieldKitDB.cardOpacity=31
click(U.headerProfileButtons[1])
assert(FieldKitDB.cardOpacity==88 and FieldKitDB.activeHudProfile==1)
assert(FieldKitDB.uiPage=="look","header switch should preserve current page")
click(U.headerProfileButtons[3])
assert(FieldKitDB.uiPage=="profiles","empty header slot should open manager")
FieldKit_SetLanguage("fr")
U.Refresh()
assert(FieldKit_L("Empty slot — save your current HUD to start.")~=
 "Empty slot — save your current HUD to start.")
assert(FieldKit_L("Saved · %d positions · opacity %d%%")~=
 "Saved · %d positions · opacity %d%%")
FieldKit_SetLanguage("en")
-- Language state must survive hover release and expose a visible selection.
U.Select("interface")
U.Refresh()
assert(U.languageRow.en.fieldkitSelected==true and
 U.languageRow.fr.fieldkitSelected==false)
assert(string.find(U.languageRow.en.fieldkitLabel.text,"✓",1,true),
 "English selection must be explicit")
this=U.languageRow.en
local leave=U.languageRow.en:GetScript("OnLeave")
leave()
assert(U.languageRow.en.fieldkitActive==true,
 "language button must remain highlighted after OnLeave")
click(U.languageRow.fr)
assert(U.languageRow.fr.fieldkitSelected==true and
 U.languageRow.en.fieldkitSelected==false)
assert(string.find(U.languageRow.fr.fieldkitLabel.text,"✓",1,true))
click(U.languageRow.en)
-- Reset HUD positions now resets chat placement and dimensions too, with Undo.
U.Select("interface")
FieldKitDB.chatWidth=650;FieldKitDB.chatHeight=260
FieldKitDB.chatAnchor={x=240,y=340}
U.ResetPositions()
assert(FieldKitDB.chatAnchor==nil and FieldKitDB.chatWidth==440
 and FieldKitDB.chatHeight==180)
U.UndoPositions()
assert(FieldKitDB.chatWidth==650 and FieldKitDB.chatHeight==260)
assert(FieldKitDB.chatAnchor.x==240 and FieldKitDB.chatAnchor.y==340)

