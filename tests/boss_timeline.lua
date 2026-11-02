-- Chronicle schedule timeline: markers from native upcoming list, clock HUD hide.
FieldKitDB.bossTimeline=true
AZS_RUN={ph="playing",t=100}
function AZS_GetPhase() return "playing" end
function AZS_GetRunTime() return 100 end
function AZS_GetUpcomingBosses()
 return {
  {name="High Priestess Jeklik",at=240,left=140,index=1},
  {name="High Priest Venoxis",at=420,left=320,index=2,final=true},
 }
end
FieldKitBossTimeline.RestoreHud()
local hidden={}
function AZS_SetHudShown(part,shown) hidden[part]=shown;return true end
FieldKitBossTimeline.Update()
assert(FieldKitBossTimelineFrame:IsShown(),"timeline visible in run")
assert(hidden.clock==false,"native clock hidden while timeline on")
assert(FieldKitBossTimelineFrame.nextLabel and string.find(FieldKitBossTimelineFrame.nextLabel:GetText() or "","Jeklik",1,true),"next-boss name")
assert(FieldKitBossTimelineFrame.callout and FieldKitBossTimelineFrame.callout:GetText()=="2:20","next-boss countdown")
assert(FieldKitBossTimelineFrame.marks[1]:IsShown() and FieldKitBossTimelineFrame.marks[2]:IsShown(),"two schedule marks")
-- Endless AZS_RUN next-boss still surfaces after schedule entries are past
AZS_GetUpcomingBosses=function() return {{name="Old Boss",at=10,left=0,index=1,final=true}} end
AZS_GetRunTime=function() return 500 end
AZS_RUN={ph="playing",t=500,nbn="Marez Cowl",nb=77}
FieldKitBossTimeline.Update()
assert(string.find(FieldKitBossTimelineFrame.nextLabel:GetText() or "","Marez",1,true),"endless next boss name")
assert(FieldKitBossTimelineFrame.callout:GetText()=="1:17","endless next boss countdown")
FieldKitDB.bossTimeline=false
FieldKitBossTimeline.Update()
assert(not FieldKitBossTimelineFrame:IsShown())
assert(hidden.clock==true,"clock restored when disabled")
print("boss_timeline: schedule markers and clock handoff passed")
