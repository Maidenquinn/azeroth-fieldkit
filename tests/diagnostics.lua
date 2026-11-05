-- Opt-in diagnostics must not change game state or persist data.
fire(FieldKitFrame,"VARIABLES_LOADED")
local D=FieldKitDiagnostics
assert(D and not D.enabled)
local baseline=D.Snapshot()
assert(baseline.frames==0 and baseline.counts.scan==0)
update(FieldKitFrame,.05)
assert(D.Snapshot().frames==0,"disabled diagnostics should record nothing")
assert(FieldKitDB.diagnostics==nil,"diagnostics must not persist")
local messages={}
local original=DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage=function(self,text) table.insert(messages,text) end
SlashCmdList.FieldKit("diag on")
assert(D.enabled and #messages==1)
for i=1,12 do update(FieldKitFrame,.05) end
local active=D.Snapshot()
assert(active.frames==12 and active.seconds>.5)
assert(active.counts.scan>0 and active.counts.snapshot>0)
assert(active.counts.layout>0)
assert(active.counts.plates>=0)
D.Mark("undefined");assert(D.counts.undefined==nil,"diagnostics may record only fixed names")
D.Tick(-1);D.Tick(0/0);D.Tick(9999)
assert(D.frames==12,"invalid frame delta was recorded")
local a,b,missing=D.Capabilities()
assert(type(a)=="number" and b==12 and type(missing)=="table")
assert(a+b-a==b)
assert(FieldKitDB.diagnostics==nil)
local oldPhase=AZS_GetPhase
AZS_GetPhase=nil
local p,total=D.Capabilities()
assert(total==b and p<=a)
AZS_GetPhase=oldPhase
SlashCmdList.FieldKit("diag api")
assert(#messages>=3)
SlashCmdList.FieldKit("diag report")
assert(#messages>=6)
assert(string.find(messages[#messages],"snapshots=",1,true))
SlashCmdList.FieldKit("diag reset")
assert(D.enabled and D.frames==0 and D.counts.scan==0)
SlashCmdList.FieldKit("diag off")
assert(not D.enabled and D.frames==0)
update(FieldKitFrame,.2)
assert(D.frames==0)
DEFAULT_CHAT_FRAME.AddMessage=original
