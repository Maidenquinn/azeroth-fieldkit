-- HUD profile slots are opt-in and must never capture private chat or gameplay.
fire(FieldKitFrame,"VARIABLES_LOADED")
local P=FieldKitProfiles
assert(P and type(FieldKitDB.interfaceProfiles)=="table")
assert(not P.Load(1) and not P.Save(0) and not P.Save(4))
FieldKitDB.frameAnchors.FieldKitLeftStack={"TOPLEFT","TOPLEFT",125,-80}
FieldKitDB.pos.FieldKitStatsFrame={-60,95}
FieldKitDB.cardSizes.FieldKitStatsFrame={width=420,height=180}
FieldKitDB.collapsedWindows.FieldKitStatsFrame=true
FieldKitDB.cardOpacity=65
FieldKitDB.linkLeftCards=true
FieldKitDB.chatWidth=530
FieldKitDB.chatStyle=true
FieldKitDB.partyDetailSync=true
FieldKitDB.known.TestCreature="normal"
FieldKitDB.chestsOpened=13
assert(P.Save(1))
assert(FieldKitDB.interfaceProfiles[1].tables.frameAnchors.FieldKitLeftStack[3]==125)
assert(FieldKitDB.interfaceProfiles[1].tables.pos.FieldKitStatsFrame[1]==-60)
assert(FieldKitDB.interfaceProfiles[1].tables.cardSizes.FieldKitStatsFrame.width==420)
assert(FieldKitDB.interfaceProfiles[1].values.cardOpacity==65)
assert(FieldKitDB.interfaceProfiles[1].values.chatWidth==nil)
FieldKitDB.cardOpacity=95
FieldKitDB.linkLeftCards=false
FieldKitDB.frameAnchors.FieldKitLeftStack={"TOPRIGHT","TOPRIGHT",-20,-20}
FieldKitDB.pos.FieldKitStatsFrame={-10,-10}
FieldKitDB.cardSizes.FieldKitStatsFrame.width=300
FieldKitDB.chatWidth=670
FieldKitDB.partyDetailSync=false
FieldKitDB.known.TestCreature="boss"
FieldKitDB.chestsOpened=100
-- Alpha.3: selecting a profile immediately applies the captured FieldKit HUD.
assert(P.Load(1),"live HUD profile load must succeed")
assert(FieldKitDB.profilePendingSlot==nil and FieldKitDB.activeHudProfile==1)
assert(FieldKitDB.cardOpacity==65 and FieldKitDB.linkLeftCards)
assert(FieldKitDB.frameAnchors.FieldKitLeftStack[3]==125)
assert(FieldKitDB.pos.FieldKitStatsFrame[1]==-60)
assert(FieldKitDB.cardSizes.FieldKitStatsFrame.width==420)
assert(FieldKitDB.chatWidth==670 and FieldKitDB.partyDetailSync==false)
assert(FieldKitDB.known.TestCreature=="boss" and FieldKitDB.chestsOpened==100)
-- Undo immediately restores the precise previous settings without a reload.
assert(P.Undo())
assert(FieldKitDB.cardOpacity==95 and not FieldKitDB.linkLeftCards)
assert(FieldKitDB.frameAnchors.FieldKitLeftStack[1]=="TOPRIGHT")
assert(FieldKitDB.cardSizes.FieldKitStatsFrame.width==300)
assert(FieldKitDB.chatWidth==670 and FieldKitDB.chestsOpened==100)
assert(not P.Undo())
-- A second live switch remains available in the same play session.
assert(P.Load(1) and FieldKitDB.cardOpacity==65)
assert(P.Delete(1) and not P.Load(1))
assert(P.Save(2) and P.Save(3) and not P.Save(999))
local messages={}
local original=DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage=function(self,text) table.insert(messages,text) end
SlashCmdList.FieldKit("profile list")
assert(string.find(messages[#messages],"2:saved",1,true))
SlashCmdList.FieldKit("profile save 1")
assert(FieldKitDB.interfaceProfiles[1])
SlashCmdList.FieldKit("profile load 1")
assert(string.find(messages[#messages],"applied",1,true))
assert(FieldKitDB.activeHudProfile==1)
SlashCmdList.FieldKit("profile undo")
assert(FieldKitDB.profilePendingSlot==nil and FieldKitDB.activeHudProfile~=1)
SlashCmdList.FieldKit("profile delete 1")
assert(not FieldKitDB.interfaceProfiles[1])
DEFAULT_CHAT_FRAME.AddMessage=original
-- Invalid saved slot contents must not crash or create unbounded keys.
FieldKitDB.interfaceProfiles[22]={values={},tables={}}
FieldKitDB.interfaceProfiles[1]="broken"
P.Init()
assert(FieldKitDB.interfaceProfiles[22]==nil and FieldKitDB.interfaceProfiles[1]==nil)
