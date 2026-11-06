-- Exhaustive profile separation: settings are isolated, native chat history and
-- in-game metrics are deliberately shared. Test real live selection + undo.
fire(FieldKitFrame,"VARIABLES_LOADED")
local P=FieldKitProfiles
assert(P and type(FieldKitDB.interfaceProfiles)=="table")
assert(not P.Load(1) and not P.Save(0) and not P.Save(4))
local d=FieldKitDB
d.frameAnchors.FieldKitLeftStack={"TOPLEFT","TOPLEFT",125,-80}
d.pos.FieldKitStatsFrame={-60,95}
d.cardSizes.FieldKitStatsFrame={width=420,height=180}
d.collapsedWindows.FieldKitStatsFrame=true
d.cardOpacity=65;d.linkLeftCards=true
d.chatWidth=530;d.chatHeight=170;d.chatFontFace=2;d.chatFontSize=15
d.chatBackgroundColor=3;d.chatStyle=true;d.chatOverrideText=false
d.chatAnchor={x=220,y=310}
d.partyDetailSync=true;d.hidePlates=true;d.combatTextWorld=true
d.bossWarningLead=12;d.language="en";d.cameraMax=31
d.worldMarkerSettings={enabled=true,aura=true,categories={boss=true,cache=false},scales={boss=105}}
d.combatEvents={crit={enabled=false,color={.1,.2,.3}}}
d.combatProfiles={balanced={combatEvents={crit={enabled=false}}}}
d.shownStats={hp=true};d.onTopWindows={FieldKitPartyDetailsFrame=true}
d.known.TestCreature="normal";d.chestsOpened=13
assert(P.Save(1))
assert(P.Rename(1,"Raid FR"))
assert(P.Name(1)=="Raid FR")
assert(not P.Rename(1,""))
assert(not P.Rename(1,string.rep("A",41)))
assert(not P.Rename(1,"Bad|cffffff"))
assert(not P.Rename(2,"Empty slot"))
assert(P.SaveActive() and P.Name(1)=="Raid FR")

assert(d.activeHudProfile==1)
assert(d.interfaceProfiles[1].values.chatWidth==530)
assert(d.interfaceProfiles[1].tables.chatAnchor.x==220)
assert(d.interfaceProfiles[1].tables.worldMarkerSettings.categories.cache==false)
assert(d.interfaceProfiles[1].tables.combatEvents.crit.color[2]==.2)
assert(d.interfaceProfiles[1].tables.frameAnchors.FieldKitLeftStack[3]==125)
assert(d.interfaceProfiles[1].values.partyDetailSync==true)

-- Save-as: slot 2 becomes the current editing context, preserving slot 1.
d.frameAnchors.FieldKitLeftStack={"TOPRIGHT","TOPRIGHT",-20,-20}
d.cardOpacity=95;d.linkLeftCards=false;d.chatWidth=670;d.chatHeight=330
d.chatFontFace=4;d.chatFontSize=19;d.chatBackgroundColor=5
d.chatStyle=false;d.chatOverrideText=true;d.chatAnchor={x=410,y=520}
d.partyDetailSync=false;d.hidePlates=false;d.combatTextWorld=false
d.bossWarningLead=21;d.language="fr";d.cameraMax=43
d.worldMarkerSettings={enabled=false,aura=false,categories={boss=false,cache=true},scales={boss=90}}
d.combatEvents={crit={enabled=true,color={.8,.7,.6}}}
d.combatProfiles={balanced={combatEvents={crit={enabled=true}}}}
d.shownStats={gold=true};d.onTopWindows={}
d.known.TestCreature="boss";d.chestsOpened=100
assert(P.Save(2) and d.activeHudProfile==2)
assert(P.Rename(2,"Exploration"))
assert(P.Name(1)=="Raid FR" and P.Name(2)=="Exploration")

assert(d.interfaceProfiles[1].values.chatWidth==530,"Saving another slot overwrote slot 1")
assert(d.interfaceProfiles[2].values.chatWidth==670)
assert(d.interfaceProfiles[2].values.chatStyle==false)
assert(P.Load(1),"switch to slot 1 must apply in-game")
assert(P.Name(1)=="Raid FR" and P.Name(2)=="Exploration")
assert(d.activeHudProfile==1 and d.chatWidth==530 and d.chatHeight==170)
assert(d.chatFontFace==2 and d.chatFontSize==15 and d.chatBackgroundColor==3)
assert(d.chatAnchor.x==220 and d.chatStyle and not d.chatOverrideText)
assert(d.cardOpacity==65 and d.linkLeftCards==true)
assert(d.partyDetailSync and d.hidePlates and d.combatTextWorld)
assert(d.bossWarningLead==12 and d.cameraMax==31 and d.language=="en")
assert(d.worldMarkerSettings.categories.boss and not d.worldMarkerSettings.categories.cache)
assert(d.combatEvents.crit.color[2]==.2)
assert(d.shownStats.hp and d.onTopWindows.FieldKitPartyDetailsFrame)
assert(d.known.TestCreature=="boss" and d.chestsOpened==100,
 "profile switch must not replace gameplay counters/classifications")

-- Change profile 1 without Save. Switching away must commit those edits only
-- to profile 1, not overwrite slot 2 or the global game state.
d.chatWidth=590;d.chatFontSize=16;d.bossWarningLead=13
d.worldMarkerSettings.categories.cache=true
assert(P.Load(2))
assert(d.chatWidth==670 and d.chatFontSize==19 and d.chatHeight==330)
assert(not d.chatStyle and d.chatOverrideText and d.chatBackgroundColor==5)
assert(d.chatAnchor.x==410 and d.cardOpacity==95 and not d.linkLeftCards)
assert(not d.partyDetailSync and not d.hidePlates and not d.combatTextWorld)
assert(d.bossWarningLead==21 and d.cameraMax==43 and d.language=="fr")
assert(not d.worldMarkerSettings.categories.boss and d.worldMarkerSettings.categories.cache)
assert(d.combatEvents.crit.color[2]==.7)
assert(d.shownStats.gold==true and not d.shownStats.hp)
assert(d.known.TestCreature=="boss" and d.chestsOpened==100)
assert(d.interfaceProfiles[1].values.chatWidth==590 and
 d.interfaceProfiles[1].values.chatFontSize==16)
assert(d.interfaceProfiles[2].values.chatWidth==670)
assert(P.Load(1))
assert(d.chatWidth==590 and d.chatFontSize==16 and d.bossWarningLead==13)
assert(d.worldMarkerSettings.categories.cache==true)
assert(P.Undo() and d.chatWidth==670 and d.language=="fr")
assert(d.activeHudProfile==2)
assert(not P.Undo())
assert(P.Save(3) and d.activeHudProfile==3)
assert(P.Delete(3) and not P.Load(3))
assert(not P.Save(999) and not P.Load(-1))

-- Nil/optional values must not leak between profiles (native gryphon toggle).
d.hideGryphons=nil;assert(P.Save(1))
d.hideGryphons=true;assert(P.Save(2))
assert(P.Load(1) and d.hideGryphons==nil)
assert(P.Load(2) and d.hideGryphons==true)

local messages={}
local old=DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage=function(self,text) table.insert(messages,text) end
SlashCmdList.FieldKit("profile list")
assert(string.find(messages[#messages],"2:saved",1,true))
SlashCmdList.FieldKit("profile load 1")
assert(d.activeHudProfile==1)
SlashCmdList.FieldKit("profile undo")
assert(d.activeHudProfile==2)
DEFAULT_CHAT_FRAME.AddMessage=old

-- Old alpha.2/alpha.4 snapshots with only four layout tables must be
-- upgraded in place using current preferences (never discarded).
local oldSlot={values={cardOpacity=51},tables={pos={FieldKitStatsFrame={33,44}},
 frameAnchors={},cardSizes={},collapsedWindows={}}}
d.interfaceProfiles[3]=oldSlot
local currentChat=d.chatWidth
P.Init()
assert(d.interfaceProfiles[3].schema==2 and P.Name(3)==nil)
assert(d.interfaceProfiles[3].values.chatWidth==currentChat)
assert(d.interfaceProfiles[3].values.cardOpacity==51)
assert(d.interfaceProfiles[3].tables.pos.FieldKitStatsFrame[1]==33)
d.interfaceProfiles[22]={values={},tables={}}
d.interfaceProfiles[1]="broken"
P.Init()
assert(d.interfaceProfiles[22]==nil and d.interfaceProfiles[1]==nil)
-- Already migrated slots must not trigger an unnecessary full live capture.
-- Capture calls FieldKit.Number for numeric settings, so an injected error
-- here detects accidental snapshot work in the common Init path.
local originalNumber=FieldKit.Number
FieldKit.Number=function() error("unexpected snapshot on migrated Init") end
assert(pcall(P.Init))
FieldKit.Number=originalNumber

-- An outgoing active slot missing from the store must fail closed rather
-- than discarding its unsaved changes during a profile switch.
assert(P.Save(1))
assert(P.Save(2))
d.interfaceProfiles[2]=nil
local retainedWidth=d.chatWidth
assert(not P.Load(1))
assert(d.activeHudProfile==2 and d.chatWidth==retainedWidth)
assert(P.Save(2))

-- A native apply failure must not leave the active slot pointing at
-- the attempted target, and must restore the live preferences.
assert(P.Save(1))
d.chatWidth=555
assert(P.Save(2))
local applyLive=FieldKit.ApplyHUDProfileLive
FieldKit.ApplyHUDProfileLive=function() error("injected native apply failure") end
local activeBefore=d.activeHudProfile
local widthBefore=d.chatWidth
assert(not P.Load(1))
assert(d.activeHudProfile==activeBefore)
assert(d.chatWidth==widthBefore)
FieldKit.ApplyHUDProfileLive=applyLive

-- Final unsaved change must be captured when the game writes SavedVariables.
assert(P.Save(2))
d.chatFontSize=18;d.chatBackgroundOpacity=55;d.lowHealthPct=44
fire(FieldKitFrame,"PLAYER_LOGOUT")
assert(d.interfaceProfiles[2].values.chatFontSize==18)
assert(d.interfaceProfiles[2].values.chatBackgroundOpacity==55)
assert(d.interfaceProfiles[2].values.lowHealthPct==44)
assert(d.known.TestCreature=="boss" and d.chestsOpened==100)

