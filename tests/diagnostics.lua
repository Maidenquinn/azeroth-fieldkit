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
assert(D.enabled and table.getn(messages)==1)
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
assert(table.getn(messages)>=3)
SlashCmdList.FieldKit("diag report")
assert(table.getn(messages)>=6)
assert(string.find(messages[table.getn(messages)],"snapshots=",1,true))
-- Compatibility probe is passive even when the native chat is absent.
local originalChat=ChatFrame1
local state=D.Compatibility()
assert(type(state.issues)=="table" and state.linked==true)
local before=FieldKitDB.chatStyle
ChatFrame1=nil
local absent=D.Compatibility()
assert(not absent.chat and table.getn(absent.issues)>=1)
ChatFrame1=originalChat
SlashCmdList.FieldKit("diag compat")
assert(string.find(messages[table.getn(messages)],"does not detect all addon conflicts",1,true))
assert(FieldKitDB.chatStyle==before and FieldKitDB.diagnostics==nil)
SlashCmdList.FieldKit("diag reset")
assert(D.enabled and D.frames==0 and D.counts.scan==0)
SlashCmdList.FieldKit("diag off")
assert(not D.enabled and D.frames==0)
update(FieldKitFrame,.2)
assert(D.frames==0)
DEFAULT_CHAT_FRAME.AddMessage=original

-- ===== alpha.50 (P1-0): performance counters. OFF = nothing installed; ON = fixed wrappers; temporary; no allocation per call =====
do
 local D=FieldKitDiagnostics
 local lines={}
 local old=DEFAULT_CHAT_FRAME.AddMessage
 DEFAULT_CHAT_FRAME.AddMessage=function(self,text) table.insert(lines,text) end
 local function KeyCount(t) local n=0;for _ in pairs(t) do n=n+1 end return n end
 assert(not D.enabled and not D.installed and table.getn(D.wrapped)==0,"diagnostics start OFF with nothing installed")
 -- 1) OFF: the measured functions are the very same ones, whatever happens
 local names={{"FieldKitZoneThemes","Refresh"},{"FieldKitZoneThemes","Suspend"},{"FieldKitZoneThemes","Set"},{"FieldKitZoneThemes","ApplyOpacity"},{"FieldKitTheme","Refresh"},{"FieldKitTheme","State"},{"FieldKitReferenceHUD","Update"},{"FieldKitThemeHUD","Update"},{"FieldKitThemeMinimap","Apply"},{"FieldKitHudStack","Apply"}}
 local original={}
 for i,n in ipairs(names) do original[i]=getglobal(n[1])[n[2]];assert(type(original[i])=="function",n[1].."."..n[2].." exists") end
 for i=1,30 do update(FieldKitFrame,.05) end
 for i,n in ipairs(names) do assert(getglobal(n[1])[n[2]]==original[i],n[1].."."..n[2].." untouched while OFF") end
 assert(D.frames==0 and KeyCount(D.ops)==0 and D.counts.scan==0,"nothing counted while OFF ("..D.frames..","..KeyCount(D.ops)..","..tostring(D.counts.scan)..")")
 local savedKeys=KeyCount(FieldKitDB)
 local frames0=table.getn(objects)
 -- 2) ON: wrappers installed, nothing created per measurement, nothing persisted
 SlashCmdList.FieldKit("diag on")
 assert(D.enabled and D.installed and table.getn(D.wrapped)>=25,"wrappers installed ("..table.getn(D.wrapped)..")")
 assert(FieldKitZoneThemes.Refresh~=original[1] and FieldKitTheme.State~=original[6],"measured functions are wrapped while ON")
 assert(table.getn(objects)==frames0,"enabling creates no frame / texture")
 local op0=table.getn(D.opOrder)
 local spikeRows={D.spikes[1],D.spikes[2],D.spikes[3],D.spikes[4],D.spikes[5]}
 for i=1,40 do update(FieldKitFrame,.05);FieldKitZoneThemes.ApplyOpacity();FieldKitZoneThemes.Refresh();FieldKitZoneThemes.Refresh(true) end
 assert(table.getn(objects)==frames0,"measuring creates no frame / texture")
 assert(table.getn(D.opOrder)==op0,"measuring creates no new counter")
 -- 3) counters
 local tick,forced=D.ops["C.Refresh(tick/unforced)"],D.ops["C.Refresh(forced)"]
 assert(tick and forced and tick.calls>=40 and forced.calls>=40,"unforced and forced refreshes are counted apart ("..tostring(tick and tick.calls)..","..tostring(forced and forced.calls)..")")
 assert(D.ops["C.ApplyOpacity(fast path)"].calls>=40,"the opacity fast path is counted")
 assert(D.ops["C.Tick(per frame)"].calls>=40,"the per-frame theme tick is counted")
 assert(tick.total>=0 and tick.max>=0 and tick.zero<=tick.calls)
 -- 4) durations: a stub that takes 250 ms of game time, average and maximum
 local stubCalls=0;local realSave=FieldKitProfiles.Save
 SlashCmdList.FieldKit("diag off")
 FieldKitProfiles.Save=function(a,b) stubCalls=stubCalls+1;NOW=NOW+(stubCalls==2 and .5 or .25);return "ok",a,b end
 SlashCmdList.FieldKit("diag on")
 local r1,r2,r3=FieldKitProfiles.Save(7,8);FieldKitProfiles.Save(7,8)
 assert(r1=="ok" and r2==7,"the wrapper forwards arguments and the first two results (the measured functions return at most one)")
 local save=D.ops["Profiles.Save"]
 assert(save and save.calls==2 and math.abs(save.max-.5)<1e-9 and math.abs(save.total-.75)<1e-9,"count, total and maximum duration ("..tostring(save and save.calls)..","..tostring(save and save.total)..")")
 -- the worst-frame line names the operations that ran in that frame, even when the clock is frame-cached
 D.Tick(.4)
 assert(string.find(D.spikes[1][3],"Profiles.Save",1,true),"worst frame lists what ran in it ("..tostring(D.spikes[1][3])..")")
 -- 5) frame variations: cumulative thresholds, five worst frames kept sorted, no new table
 D.Reset()
 for _,dt in ipairs({.01,.06,.12,.3,1.5,.02,.07}) do D.Tick(dt) end
 assert(D.hist[1]==5 and D.hist[2]==3 and D.hist[3]==2 and D.hist[4]==1,"histogram ("..D.hist[1]..","..D.hist[2]..","..D.hist[3]..","..D.hist[4]..")")
 assert(D.spikes[1][1]==1.5 and D.spikes[2][1]==.3 and D.spikes[3][1]==.12 and D.spikes[4][1]==.07 and D.spikes[5][1]==.06,"worst frames sorted")
 local mem=D.mem;for i=1,3 do D.Tick(.5) end
 assert(D.mem==mem,"memory samples reuse one table")
 -- 6) report: copyable, bounded, ends with the historic counters
 FieldKitProfiles.Save(1,2)
 local report=D.Lines()
 assert(string.find(report[1],"FIELDKIT-DIAG v1",1,true) and string.find(report[1],"NOT native CPU or FPS",1,true))
 assert(string.find(report[table.getn(report)],"snapshots=",1,true) and string.find(report[table.getn(report)],"END FIELDKIT-DIAG",1,true),"last line is the counters + end marker")
 local joined=table.concat(report,"\n")
 for _,key in ipairs({"state:","time:","worst frames","luaMemoryKB","operations","Profiles.Save","frames>50ms"}) do assert(string.find(joined,key,1,true),"report has "..key) end
 for _,l in ipairs(report) do assert(string.len(l)<=480,"line short enough to copy") end
 -- 7) status, reset, off
 lines={}
 SlashCmdList.FieldKit("diag status")
 assert(table.getn(lines)==1 and string.find(lines[1],"Diagnostics ON",1,true),"status ON")
 SlashCmdList.FieldKit("diag reset")
 assert(D.enabled and D.frames==0 and D.hist[1]==0 and D.spikes[1][1]==0 and D.ops["Profiles.Save"].calls==0 and D.mem.start==nil,"reset clears counters and keeps wrappers")
 assert(D.installed,"reset does not remove the wrappers")
 local wrapperRef=FieldKitZoneThemes.ApplyOpacity
 SlashCmdList.FieldKit("diag off")
 assert(not D.enabled and not D.installed and table.getn(D.wrapped)==0,"off removes everything")
 assert(FieldKitZoneThemes.ApplyOpacity~=wrapperRef and FieldKitTheme.State==original[6] and FieldKitZoneThemes.Refresh==original[1],"original functions restored")
 assert(FieldKitProfiles.Save~=nil)
 FieldKitProfiles.Save=realSave
 lines={}
 SlashCmdList.FieldKit("diag status")
 assert(string.find(lines[1],"Diagnostics OFF",1,true),"status OFF")
 -- a wrapper still referenced after OFF is a plain pass-through that counts nothing
 local before=KeyCount(D.ops)
 wrapperRef();assert(KeyCount(D.ops)==before and D.lastOp==nil,"a stale wrapper counts and records nothing")
 for i,n in ipairs(names) do assert(getglobal(n[1])[n[2]]==original[i],n[1].."."..n[2].." restored") end
 -- 8) repeated on/off cycles never accumulate (counters, frames) and never persist
 for i=1,60 do SlashCmdList.FieldKit("diag on");update(FieldKitFrame,.05);SlashCmdList.FieldKit("diag off") end
 assert(table.getn(D.opOrder)==0,"no leftover counters after OFF")
 SlashCmdList.FieldKit("diag on");assert(table.getn(D.opOrder)<=D.targetCount+4,"counter list is bounded after 60 cycles ("..table.getn(D.opOrder)..")");SlashCmdList.FieldKit("diag off")
 assert(table.getn(objects)==frames0,"no frame or texture created by 60 on/off cycles")
 assert(KeyCount(FieldKitDB)==savedKeys and FieldKitDB.diagnostics==nil,"nothing written to the SavedVariables")
 -- 9) a replaced function is never clobbered by the restore
 SlashCmdList.FieldKit("diag on")
 local theirs=function() return "theirs" end
 FieldKitHudStack.Apply=theirs
 SlashCmdList.FieldKit("diag off")
 assert(FieldKitHudStack.Apply==theirs and D.replaced>=0,"a function replaced by someone else while ON is left alone")
 FieldKitHudStack.Apply=original[10]
 -- 10) isolation tests: one module paused on demand, temporary, restored by skip off / diag off
 lines={}
 SlashCmdList.FieldKit("diag skip loadout");assert(string.find(lines[1],"need /fieldkit diag on",1,true),"isolation needs the diagnostics")
 
 local realLoadout=FieldKitLoadout.Update
 SlashCmdList.FieldKit("diag on")
 local wrapped=FieldKitLoadout.Update
 SlashCmdList.FieldKit("diag skip loadout")
 assert(FieldKitLoadout.Update~=wrapped and D.skipped.loadout,"loadout paused")
 local calls=0;local sawScan=FieldKitLoadout.Scan
 FieldKitLoadout.Update();assert(table.getn(D.SkippedNames())==1 and D.SkippedNames()[1]=="loadout")
 assert(string.find(table.concat(D.Lines(),string.char(10)),"PAUSED modules = loadout",1,true),"the report states what is paused")
 SlashCmdList.FieldKit("diag skip chat");assert(D.skipped.chat and table.getn(D.SkippedNames())==2,"two modules paused")
 SlashCmdList.FieldKit("diag skip nonsense");assert(string.find(lines[table.getn(lines)],"Isolation modules:",1,true),"unknown module lists the choices")
 SlashCmdList.FieldKit("diag skip off")
 assert(FieldKitLoadout.Update==wrapped and table.getn(D.SkippedNames())==0,"skip off restores")
 SlashCmdList.FieldKit("diag skip hudstack");SlashCmdList.FieldKit("diag off")
 assert(FieldKitHudStack.Apply==original[10] and FieldKitLoadout.Update==realLoadout and table.getn(D.SkippedNames())==0,"diag off also restores paused modules")
 SlashCmdList.FieldKit("diag compat") -- unchanged commands still answer
 SlashCmdList.FieldKit("diag bogus");assert(string.find(lines[table.getn(lines)],"Usage:",1,true) and string.find(lines[table.getn(lines)],"status",1,true),"usage lists status")
 DEFAULT_CHAT_FRAME.AddMessage=old
end
print("Performance counters: OFF installs nothing, ON wraps a fixed list, durations / histogram / reset / off / cycles, nothing persisted passed (synthetic)")
