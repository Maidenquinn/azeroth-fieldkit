-- Meter ledger hit book + suite view switching (no native snapshot required).
FieldKitDB.meterFrame=true;FieldKitDB.meterTabs=true;FieldKitDB.meterSpellTips=true
FieldKitMeterLedger.ClearHits()
FieldKitMeterLedger.NoteHit("Whirlwind",100,false,12,"Interface\\Icons\\Ability_Whirlwind")
FieldKitMeterLedger.NoteHit("Whirlwind",400,true,12,"Interface\\Icons\\Ability_Whirlwind")
FieldKitMeterLedger.NoteHit("Execute",200,false)
FieldKitMeterLedger.NoteKill("Execute")
local st=FieldKitMeterLedger.Stats("Whirlwind")
assert(st and st.hits==2 and st.crits==1 and st.maxCrit==400 and st.maxHit==100)
assert(math.abs(st.critPct-50)<0.01)
assert(FieldKitMeterLedger.Stats(nil,12) and FieldKitMeterLedger.Stats(nil,12).hits==2,"spellId index")
assert(FieldKitMeterLedger.Stats(nil,nil,"Interface\\Icons\\Ability_Whirlwind").maxCrit==400,"icon index")
local kills=FieldKitMeterLedger.Read("kills")
assert(kills[1] and kills[1].name=="Execute" and kills[1].dmg==1)
-- lastBlow + death (SpellMeter path), including French tip join by icon
FieldKitMeterLedger.ClearHits()
FieldKitMeterLedger.ParseChat("Your Execute hits Razzashi Raptor for 513.")
FieldKitMeterLedger.ParseDeath("Razzashi Raptor dies.")
assert(FieldKitMeterLedger.KillsFor("Execute")==1,"death credits last blow")
assert(FieldKitMeterLedger.Stats("Execute").hits==1 and FieldKitMeterLedger.Stats("Execute").maxHit==513)
FieldKitMeterLedger.ParseChat("Your Execute crits Razzashi Raptor for 1171.")
local tip=FieldKitMeterLedger.Stats("Execute")
assert(tip.hits==2 and tip.crits==1 and tip.maxCrit==1171 and tip.critPct==50)
FieldKitMeterSuite.SetView("kills")
assert(FieldKitDB.meterViewKey=="kills")
FieldKitMeterSuite.SetView("damage")
assert(FieldKitDB.meterViewKey=="damage")
FieldKitMeterSuite.SetDetached("healing",true)
assert(FieldKitDB.meterDetach_healing==true)
FieldKitMeterSuite.SetDetached("healing",false)
assert(not FieldKitDB.meterDetach_healing)
FieldKitMeterLedger.Reset()
st=FieldKitMeterLedger.Stats("Whirlwind")
assert(not st,"reset clears hit books")
-- Taken DPS = amount / run clock (SpellMeter parity)
AZS_GetRunTime=function() return 100 end
AZS_TAKEN={{source="mob melee",dmg=1000},{source="elite",dmg=500}}
local taken,sum,tdps=FieldKitMeterLedger.Read("taken")
assert(sum==1500 and tdps==15,"taken total dps")
assert(taken[1].dps==10 and taken[2].dps==5,"per-source taken dps")
AZS_GetRunTime=nil;AZS_TAKEN=nil
-- Column sort + hide row (total unchanged)
FieldKitDB.meterHiddenRows={}
FieldKitDB.meterSortKey="name";FieldKitDB.meterSortAsc=true
FieldKitMeterLedger.ClearHits()
FieldKitMeterLedger.NoteKill("Zebra");FieldKitMeterLedger.NoteKill("Alpha")
local sorted=FieldKitMeterLedger.Read("kills")
assert(sorted[1].name=="Alpha" and sorted[2].name=="Zebra","sort by name asc")
local totalBefore=2
FieldKitMeterLedger.ToggleHide("kills","Alpha")
local shown,totalAfter=FieldKitMeterLedger.Read("kills")
assert(table.getn(shown)==1 and shown[1].name=="Zebra","hidden row omitted")
assert(totalAfter==totalBefore,"hide keeps total")
FieldKitMeterLedger.ClearHidden("kills")
FieldKitDB.meterSortKey="dmg";FieldKitDB.meterSortAsc=false
-- Healing perspective flag reaches snapshot query
FieldKitDB.meterHealDone=true
local seenPersp
AZS_GetMeterContext=function() return {runId="r1"} end
AZS_GetMeterSnapshot=function(q)
 seenPersp=q.healingPerspective
 return {status="ready",rows={},sources={},actors={},totals={displayAmount=0}}
end
FieldKitMeterLedger.Read("healing")
assert(seenPersp=="performed","heal done perspective")
FieldKitDB.meterHealDone=false
FieldKitMeterLedger.Read("healing")
assert(seenPersp=="received","heal received perspective")
AZS_GetMeterContext=nil;AZS_GetMeterSnapshot=nil
-- Party drill-down owner scope
FieldKitDB.meterPartyOwner="ally-1"
local seenScope,seenOwner
AZS_GetMeterContext=function() return {runId="r1"} end
AZS_GetMeterSnapshot=function(q)
 seenScope=q.scope;seenOwner=q.ownerId
 return {status="ready",rows={},sources={},actors={},totals={displayAmount=0}}
end
FieldKitMeterLedger.Read("party")
assert(seenScope=="owner" and seenOwner=="ally-1","party owner drill")
FieldKitDB.meterPartyOwner=nil
AZS_GetMeterContext=nil;AZS_GetMeterSnapshot=nil
-- Pet / DoT combat-log parsing
FieldKitMeterLedger.ClearHits()
FieldKitMeterLedger.ParseChat("Razzashi Raptor suffers 40 Nature damage from your Serpent Sting. (Critical)")
assert(FieldKitMeterLedger.Stats("Serpent Sting").hits==1 and FieldKitMeterLedger.Stats("Serpent Sting").crits==1,"dot crit")
FieldKitMeterLedger.ParseChat("Imp's Firebolt hits Razzashi Raptor for 88.")
assert(FieldKitMeterLedger.Stats("Imp: Firebolt") and FieldKitMeterLedger.Stats("Imp: Firebolt").maxHit==88,"pet spell")
FieldKitMeterLedger.ParseChat("Wolf crits Razzashi Raptor for 120.")
assert(FieldKitMeterLedger.Stats("Wolf: Melee").maxCrit==120,"pet melee")
FieldKitMeterLedger.ParseChat("Razzashi Raptor suffers 15 Fire damage from Imp's Firebolt.")
assert(FieldKitMeterLedger.Stats("Imp: Firebolt").hits==2,"pet dot")
-- Ranked ability names collapse into one hit book
FieldKitMeterLedger.ClearHits()
FieldKitMeterLedger.NoteHit("Consécration (Rang 39)",100,false,3901)
FieldKitMeterLedger.NoteHit("Consécration (Rang 40)",200,true,4001)
assert(FieldKitMeterLedger.Stats("Consécration").hits==2 and FieldKitMeterLedger.Stats("Consécration").crits==1,"rank book merge")
assert(FieldKitMeterLedger.Stats("Consécration (Rank 40)").amount==300,"rank suffix resolve")
-- Snapshot source rows merge by abilityKey across ranks
AZS_GetMeterContext=function() return {runId="r1"} end
AZS_GetMeterSnapshot=function()
 return {
  status="ready",
  sources={
   ["ability:consecration:r39"]={name="Consécration",abilityKey="consecration",rank=39},
   ["ability:consecration:r40"]={name="Consécration",abilityKey="consecration",rank=40},
   ["ability:other:r1"]={name="Other",abilityKey="other",rank=1},
  },
  actors={},
  rows={
   {sourceKey="ability:consecration:r39",displayAmount=100,displayRate={value=10}},
   {sourceKey="ability:consecration:r40",displayAmount=250,displayRate={value=25}},
   {sourceKey="ability:other:r1",displayAmount=50,displayRate={value=5}},
  },
  totals={displayAmount=400,displayRate={value=40}},
 }
end
local lines,total=FieldKitMeterLedger.Read("damage")
assert(total==400 and table.getn(lines)==2,"rank snapshot merge count")
assert(lines[1].name=="Consécration" and lines[1].dmg==350 and lines[1].dps==35,"consecration ranks summed")
assert(lines[2].name=="Other" and lines[2].dmg==50,"other untouched")
AZS_GetMeterContext=nil;AZS_GetMeterSnapshot=nil
print("meter_suite: hit ledger and view keys passed")
