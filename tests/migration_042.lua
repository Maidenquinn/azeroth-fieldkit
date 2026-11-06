-- Synthetic v0.4.2-style flat SavedVariables: no interfaceProfiles.
-- Run in the mocked Lua 5.1 client after VARIABLES_LOADED.
assert(type(FieldKitDB)=="table")
assert(FieldKitDB.interfaceProfiles==nil or type(FieldKitDB.interfaceProfiles)=="table")
assert(FieldKitDB.cardOpacity==37)
assert(FieldKitDB.moneyFrame==false)
assert(FieldKitDB.combatTextX==-217)
assert(FieldKitDB.chatWidth==560)
assert(FieldKitDB.language=="fr")
assert(FieldKitDB.frameAnchors.FieldKitLeftStack[3]==83)
assert(FieldKitDB.pos.FieldKitMoneyFrame[1]==-14)
assert(FieldKitDB.activeHudProfile==nil)
assert(FieldKitProfiles.Save(1))
assert(FieldKitDB.activeHudProfile==1)
FieldKitDB.cardOpacity=93
FieldKitDB.moneyFrame=true
FieldKitDB.combatTextX=11
FieldKitDB.chatWidth=400
FieldKitDB.frameAnchors.FieldKitLeftStack[3]=4
assert(FieldKitProfiles.Load(1))
assert(FieldKitDB.cardOpacity==37)
assert(FieldKitDB.moneyFrame==false)
assert(FieldKitDB.combatTextX==-217)
assert(FieldKitDB.chatWidth==560)
assert(FieldKitDB.frameAnchors.FieldKitLeftStack[3]==83)
assert(FieldKitDB.pos.FieldKitMoneyFrame[1]==-14)
