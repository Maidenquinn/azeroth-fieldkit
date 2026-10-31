-- Synthetic visual fixtures must never leak into live gameplay or sharing state.
FieldKitDB={meterFrame=false,takenFrame=false,partyMeter=false,partyCards=false,
 effectsFrame=false,reviveFrame=false,bossFrame=false,windowsLocked=true}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
local P,U=FieldKitPreview,FieldKitUI
local meter,taken,party=AZS_METER,AZS_TAKEN,FieldKitCoop.party
local writes=0
SetCVar=function() writes=writes+1 end
AZS_SetHudShown=function() writes=writes+1 end
SendAddonMessage=function() writes=writes+1 end
AZS_SetOnTopOfScreens=function() writes=writes+1 end
for i=1,table.getn(P.names) do
 P.Open(i);assert(P.mode=="inspect" and P.frames[i]:IsShown())
 assert(P.frames[i]~=getglobal(P.names[i]),"Preview reused a live frame")
 assert(not FieldKitDB.meterFrame and not FieldKitDB.partyCards and not FieldKitDB.bossFrame)
end
assert(AZS_METER==meter and AZS_TAKEN==taken and FieldKitCoop.party==party and writes==0)
P.Open(9);FieldKitDB.partyHealthMode=2;P.Refresh()
assert(P.frames[9].rows[1].value:GetText()=="55%")
FieldKitDB.partyHealthMode=3;P.Refresh();assert(P.frames[9].rows[1].value:GetText()=="6705 / 12200 (55%)")
P.Open(18);FieldKitDB.playerHealthMode=2;P.Refresh();assert(P.frames[18].hp:GetText()=="55%")
P.Open(19);FieldKitDB.targetHealthMode=3;P.Refresh();assert(P.frames[19].hp:GetText()=="6705 / 12200 (55%)")
P.Open(17);FieldKitDB.bossHealthMode=2;P.Refresh();assert(P.frames[17].hp:GetText()=="55%")
P.Open(2);FieldKitDB.meterValues=3;P.Refresh()
assert(P.frames[2].rows[1].meterColumns[1]:GetText()=="42000")
FieldKitDB.cardStyle=2;FieldKitDB.cardOpacity=18;FieldKitTheme.Refresh()
assert(FieldKitTheme.Style(P.frames[2])==2 and FieldKitTheme.Opacity(P.frames[2])==.18)
assert(FieldKitTheme.Opacity(P.inspector)==1)
FieldKit_SetLanguage("fr");P.Refresh();assert(P.frames[2].title:GetText()=="Aperçu")
FieldKit_SetLanguage("en");P.Refresh();assert(P.frames[2].title:GetText()=="Preview")
local allocated=table.getn(objects)
for i=1,30 do P.Refresh() end
assert(table.getn(objects)==allocated,"Preview refresh allocated frames")
-- A single explicit drag saves geometry under the live frame's name only.
FieldKitDB.linkLeftCards=false;FieldKitHudStack.Apply()
U.SetLayoutEditing(true,false);P.Start(false)
local f=P.frames[2];P.Drag(f,true);f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-2,-40);P.Drag(f,false)
assert(FieldKitDB.frameAnchors.FieldKitMeterFrame[3]==-2)
assert(not FieldKitDB.frameAnchors.FieldKitPreviewCard2)
assert(FieldKitDB.windowsLocked,"Arrangement changed the saved lock")
local anchor=FieldKitDB.frameAnchors.FieldKitMeterFrame
P.selected=3;P.Reset()
assert(FieldKitDB.frameAnchors.FieldKitMeterFrame==anchor,"Reset affected an unrelated window")
-- Disabled windows are selectable in global composition; linked examples don't overlap.
P.included[9]=true;FieldKitDB.linkLeftCards=true;U.SetLayoutEditing(true,false)
assert(P.frames[9]:IsShown() and P.frames[3]:IsShown())
local _,root,_,_,y=P.frames[3]:GetPoint(1)
assert(root==P.roots.FieldKitLeftStack and y<0)
U.SetLayoutEditing(false,true)
assert(not P.mode and not FieldKit.layoutEditing)
for _,v in pairs(P.frames) do assert(not v:IsShown()) end
assert(not FieldKitDB.meterFrame and not FieldKitDB.partyCards and writes==0)
-- Inspector selectors track resize selection without activating a module.
P.Open(2);click(P.inspector.choice);click(P.inspector.choice.choiceButtons[3])
assert(P.selected==3 and FieldKitCardLayout.selected==3)
for _,control in ipairs(U.controls) do
 if control.label=="Window to resize" then click(control);click(control.choiceButtons[5]) end
end
assert(P.selected==5)
click(P.inspector.choice);assert(P.inspector.choice.menu:IsShown())
P.Stop();assert(not P.inspector.choice.menu:IsShown())
-- Interrupted grouped drag commits only the group anchor.
P.selected=2;U.SetLayoutEditing(true,false);P.Start(false)
local group=P.roots.FieldKitLeftStack
P.Drag(P.frames[2],true);group:SetPoint("TOPLEFT",UIParent,"TOPLEFT",5,-22)
U.SetLayoutEditing(false,true)
assert(not group.moving and FieldKitDB.frameAnchors.FieldKitLeftStack[3]==5)
P.Open(14);P.inspector:Hide();P.inspector:GetScript("OnHide")()
assert(not P.mode and not P.inspector:IsShown())
-- Escape/close while dragging must stop, persist the deliberate move, then
-- hide every sample. Subsequent live native updates remain independent.
P.Open(3);P.included[3]=false;U.SetLayoutEditing(true,false)
assert(not P.frames[3]:IsShown());U.dock:Hide();U.dock:GetScript("OnHide")()
assert(not P.mode and not FieldKit.layoutEditing)
AZS_RUN.ph=nil;P.Open(8);U.frame:Hide();U.frame:GetScript("OnHide")();assert(not P.mode)
local oldW,oldH=UIParent.width,UIParent.height;UIParent.width=800;UIParent.height=600
U.frame:Show();P.Open(17);P.Refresh();assert(P.inspector:IsShown())
UIParent.width=oldW;UIParent.height=oldH;P.Stop()
assert(writes==0 and AZS_METER==meter and AZS_TAKEN==taken)
print("Context-free previews: isolation, settings, grouping, placement, scoped reset and cleanup passed")
