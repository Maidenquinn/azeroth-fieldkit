-- Opt-in, read-only runtime diagnostics. No persistence, network, native frame
-- changes, profiling claims or scanning of foreign addon objects.
-- Native 1.12 does not expose precise per-addon CPU accounting.
-- Performance counters (alpha.50): while diagnostics are OFF nothing is installed and nothing runs: the hot paths are the very same
-- functions as without this file. /fieldkit diag on installs thin counting/timing wrappers around a FIXED list of functions
-- (targets below) and /fieldkit diag off puts the original functions back. Everything is session-only memory, preallocated at
-- enable time (no frame, no texture, no table per measurement) and never written to the SavedVariables.
FieldKitDiagnostics={enabled=false,frames=0,dtTotal=0,dtMax=0,counts={},ops={},opOrder={},wrapped={},hist={0,0,0,0},spikes={},mem={}}
local D=FieldKitDiagnostics
local buckets={"snapshot","scan","layout","plates"}
local apis={
 "AZS_GetPhase","AZS_GetRunTime","AZS_GetMeter","AZS_GetHealing",
 "AZS_GetBossMeter","AZS_GetUpcomingBosses","AZS_GetCombatTextEvents",
 "AZS_GetWorldAnchorCapabilities","AZS_GetWorldAnchors",
 "AZS_ProjectWorldAnchors","AZS_GetPartyMeter",
 "AZS_SetOnTopOfScreens"
}
local function Say(message)
 if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99FieldKit|r: "..message)
 end
end
-- Frame-delta thresholds (seconds) for the client time-variation histogram; cumulative: a 300 ms frame counts in the first three.
local THRESHOLDS={.05,.1,.25,1}
-- Functions measured while diagnostics are ON: {global table, field, label, alternative label, picker, count-only}. The picker
-- chooses the alternative label from the first argument (forced refresh, active suspension). Inclusive times: a call that
-- contains another measured call (C.Set contains C.Suspend and C.Refresh) includes its time.
local function PickForced(a1) return a1 and true or false end
local function PickActive() return FieldKitZoneThemes and FieldKitZoneThemes.active and true or false end
local targets={
 {"FieldKitZoneThemes","Refresh","C.Refresh(tick/unforced)","C.Refresh(forced)",PickForced},
 {"FieldKitZoneThemes","Suspend","C.Suspend(idle)","C.Suspend(FULL teardown)",PickActive},
 {"FieldKitZoneThemes","Set","C.Set(setting change)"},
 {"FieldKitZoneThemes","ApplyOpacity","C.ApplyOpacity(fast path)"},
 {"FieldKitZoneThemes","SetElementScale","C.SetElementScale"},
 {"FieldKitZoneThemes","NativeReplace","C.NativeReplace"},
 {"FieldKitZoneThemes","Tick","C.Tick(per frame)",nil,nil,true},
 {"FieldKitTheme","Refresh","T.Refresh(repaint ALL surfaces)"},
 {"FieldKitTheme","SetZone","T.SetZone"},
 {"FieldKitTheme","RefreshOpacity","T.RefreshOpacity"},
 {"FieldKitTheme","State","T.State(per surface)",nil,nil,true},
 {"FieldKitTheme","Update","T.Update(per surface)",nil,nil,true},
 {"FieldKitReferenceHUD","Update","R.Update"},
 {"FieldKitReferenceHUD","Map","R.Map"},
 {"FieldKitReferenceHUD","ApplyOpacity","R.ApplyOpacity"},
 {"FieldKitReferenceHUD","Stop","R.Stop"},
 {"FieldKitThemeHUD","Update","H.Update"},
 {"FieldKitThemeHUD","Restore","H.Restore"},
 {"FieldKitThemeMinimap","Apply","M.Apply"},
 {"FieldKitThemeMinimap","Ring","M.Ring"},
 {"FieldKitThemeMinimap","Restore","M.Restore"},
 {"FieldKitThemeTarget","Update","ThemeTarget.Update"},
 {"FieldKitHudStack","Apply","HudStack.Apply"},
 {"FieldKitCardLayout","ApplyRight","CardLayout.ApplyRight"},
 {"FieldKitLoadout","Update","Loadout.Update"},
 {"FieldKitLoadout","Scan","Loadout.Scan(spell book + action bar walk)"},
 {"FieldKitLoadout","Tooltip","Loadout.Tooltip(one tooltip scan)"},
 {"FieldKitLoadout","Render","Loadout.Render(card rows)"},
 {"FieldKitLoadout","refresh","Loadout.refresh(card redraw)"},
 {"FieldKit","SyncChat","FieldKit.SyncChat"},
 {"FieldKit","ApplyChatStyle","FieldKit.ApplyChatStyle"},
 {"FieldKitReferenceHUD","ChatSync","R.ChatSync(forces a theme refresh)"},
 {"FieldKitCardLayout","Rows","CardLayout.Rows"},
 {"FieldKitRunMode","Update","RunMode.Update"},
 {"FieldKitCoop","Update","Coop.Update"},
 {"FieldKitNativeTools","Update","NativeTools.Update"},
 {"FieldKitScreenLayers","Update","ScreenLayers.Update"},
 {"FieldKitPartySync","Tick","PartySync.Tick"},
 {"FieldKitProfiles","Load","Profiles.Load"},
 {"FieldKitProfiles","Save","Profiles.Save"},
}
D.targetCount=table.getn(targets)
local function NewOp(label,quiet)
 local op={label=label,calls=0,total=0,max=0,zero=0,fc=0,lastFrame=-1,quiet=quiet}
 D.ops[label]=op;table.insert(D.opOrder,op)
 return op
end
-- Memory: gcinfo() is the 1.12 / Lua 5.0 call; Lua 5.1 only for the mock. Absent -> memory lines are omitted, never invented.
local function MemFunction()
 if type(gcinfo)=="function" then return gcinfo end
 if type(collectgarbage)=="function" then
  local ok,value=pcall(collectgarbage,"count")
  if ok and type(value)=="number" then return function() return collectgarbage("count") end end
 end
 return nil
end
local function SampleMemory()
 local fn=D.memFn;if not fn then return end
 local m=D.mem;local kb=fn()
 if type(kb)~="number" then return end
 if not m.start then m.start=kb;m.min=kb;m.max=kb end
 m.last=kb;if kb>m.max then m.max=kb end;if kb<m.min then m.min=kb end;m.samples=(m.samples or 0)+1
end
function D.Reset()
 D.frames=0;D.dtTotal=0;D.dtMax=0;D.counts={}
 for i=1,table.getn(buckets) do D.counts[buckets[i]]=0 end
 for i=1,4 do D.hist[i]=0 end
 for i=1,5 do local x=D.spikes[i];if not x then x={0,0,"-"};D.spikes[i]=x end;x[1]=0;x[2]=0;x[3]="-" end
 for i=1,table.getn(D.opOrder) do local op=D.opOrder[i];op.calls=0;op.total=0;op.max=0;op.zero=0;op.fc=0;op.lastFrame=-1 end
 D.mem.start=nil;D.mem.last=nil;D.mem.max=nil;D.mem.min=nil;D.mem.samples=0;D.memTimer=0;D.lastOp=nil
 D.replaced=0
end
D.Reset()
-- Install / remove the wrappers. Fixed argument forwarding (no vararg table in Lua 5.0); a wrapper that is still in a call chain
-- after /fieldkit diag off (someone wrapped it again) behaves as a plain pass-through.
function D.Install()
 if D.installed then return end
 D.installed=true
 if type(debugprofilestop)=="function" then D.clockName="debugprofilestop";D.now=function() return debugprofilestop()/1000 end
 else D.clockName="GetTime";D.now=GetTime end
 D.memFn=MemFunction()
 D.ops={};D.opOrder={} -- a fresh list at every enable: repeated on/off never accumulates entries
 for i=1,table.getn(targets) do
  local spec=targets[i];local owner=getglobal(spec[1]);local field=spec[2]
  local orig=type(owner)=="table" and owner[field]
  if type(orig)=="function" then
   local op=NewOp(spec[3],spec[6]);local alt=spec[4] and NewOp(spec[4]) or nil;local pick=spec[5];local wrapper
   if spec[6] then
    wrapper=function(a1,a2,a3,a4,a5) if D.enabled then op.calls=op.calls+1 end;return orig(a1,a2,a3,a4,a5) end
   else
    wrapper=function(a1,a2,a3,a4,a5)
     if not D.enabled then return orig(a1,a2,a3,a4,a5) end
     local o=op;if pick and pick(a1) then o=alt end
     local t0=D.now()
     local r1,r2,r3,r4=orig(a1,a2,a3,a4,a5)
     local dt=D.now()-t0
     o.calls=o.calls+1;o.total=o.total+dt;if dt>o.max then o.max=dt end;if dt<=0 then o.zero=o.zero+1 end
     D.lastOp=o.label
     -- which operations ran during this frame (the client clock may be frame-cached, then durations are 0 and only the frame
     -- delta of the NEXT tick shows what a frame cost): stamp with the frame index, counted per frame
     if o.lastFrame==D.frames then o.fc=o.fc+1 else o.lastFrame=D.frames;o.fc=1 end
     return r1,r2,r3,r4
    end
   end
   owner[field]=wrapper
   table.insert(D.wrapped,{owner,field,orig,wrapper})
  end
 end
 D.Reset()
 SampleMemory()
end
function D.Uninstall()
 for i=1,table.getn(D.wrapped) do
  local w=D.wrapped[i]
  if w[1][w[2]]==w[4] then w[1][w[2]]=w[3] else D.replaced=D.replaced+1 end
 end
 D.wrapped={};D.installed=false;D.ops={};D.opOrder={}
end
-- Isolation tests (temporary, never saved): `/fieldkit diag skip <name>` replaces ONE periodic module by a no-op so that a
-- microfreeze can be attributed by elimination in the real client; `/fieldkit diag skip off` (or `diag off`) puts everything back.
-- The paused module simply does not run: nothing is persisted, and the game is unaffected beyond that module's display.
local isolation={
 loadout={{"FieldKitLoadout","Update"}},
 hudstack={{"FieldKitHudStack","Apply"}},
 cardright={{"FieldKitCardLayout","ApplyRight"}},
 nativetools={{"FieldKitNativeTools","Update"}},
 screenlayers={{"FieldKitScreenLayers","Update"}},
 runmode={{"FieldKitRunMode","Update"}},
 coop={{"FieldKitCoop","Update"}},
 partysync={{"FieldKitPartySync","Tick"}},
 themetick={{"FieldKitZoneThemes","Tick"}},
 chat={{"FieldKit","SyncChat"},{"FieldKit","ApplyChatStyle"}},
}
D.isolation=isolation
D.skipped={}
local function NoOp() end
function D.Skip(name)
 local group=isolation[name];if not group then return false end
 if D.skipped[name] then return true end
 local entries={}
 for i=1,table.getn(group) do
  local owner=getglobal(group[i][1]);local field=group[i][2]
  if type(owner)=="table" and type(owner[field])=="function" then
   table.insert(entries,{owner,field,owner[field]});owner[field]=NoOp
  end
 end
 D.skipped[name]=entries
 return true
end
function D.Unskip()
 for name,entries in pairs(D.skipped) do
  for i=1,table.getn(entries) do local e=entries[i];if e[1][e[2]]==NoOp then e[1][e[2]]=e[3] end end
 end
 D.skipped={}
end
function D.SkippedNames()
 local list={};for name in pairs(D.skipped) do table.insert(list,name) end;table.sort(list)
 return list
end
function D.Enable(value)
 D.enabled=value==true
 if D.enabled then D.Install() else D.Unskip();D.Uninstall();D.Reset() end
 return D.enabled
end
local SPIKE_MIN=.03
-- Names of the (non count-only) operations that ran during frame number `frame`; built only for a worst-frame candidate.
local function Blame(frame)
 local parts={};local n=0
 for i=1,table.getn(D.opOrder) do
  local op=D.opOrder[i]
  if not op.quiet and op.lastFrame==frame and n<9 then n=n+1;parts[n]=op.label.."x"..op.fc end
 end
 if n==0 then return "-" end
 return table.concat(parts,", ")
end
function D.Tick(dt)
 if not D.enabled then return end
 if type(dt)~="number" or dt<0 or dt~=dt or dt>10 then return end
 local previous=D.frames
 D.frames=D.frames+1
 D.dtTotal=D.dtTotal+dt
 if dt>D.dtMax then D.dtMax=dt end
 for i=1,4 do if dt>THRESHOLDS[i] then D.hist[i]=D.hist[i]+1 end end
 local spikes=D.spikes
 if dt>=SPIKE_MIN and dt>spikes[5][1] then
  -- keep the five worst frame deltas (>= 30 ms), sorted; the slot is reused. The text lists the measured operations that ran
  -- since the previous tick: a hint about what the frame contained, not proof of what made it slow.
  local x=spikes[5];x[1],x[2],x[3]=dt,D.dtTotal,Blame(previous)
  local i=5
  while i>1 and spikes[i][1]>spikes[i-1][1] do spikes[i],spikes[i-1]=spikes[i-1],spikes[i];i=i-1 end
 end
 D.memTimer=D.memTimer+dt
 if D.memTimer>=1 then D.memTimer=0;SampleMemory() end
end
function D.Mark(name)
 if not D.enabled or type(name)~="string" then return end
 if D.counts[name]~=nil then D.counts[name]=D.counts[name]+1 end
end
function D.Capabilities()
 -- Only fixed allowlisted symbols; absence is normal on older game builds.
 local present=0;local absent={}
 for i=1,table.getn(apis) do
  if type(getglobal(apis[i]))=="function" then present=present+1
  else table.insert(absent,apis[i]) end
 end
 return present,table.getn(apis),absent
end
function D.Snapshot()
 local result={enabled=D.enabled,frames=D.frames,seconds=D.dtTotal,
  frameMax=D.dtMax,counts={}}
 for i=1,table.getn(buckets) do
  local name=buckets[i]
  result.counts[name]=D.counts[name]
 end
 return result
end
local function Ms(seconds) return string.format("%.2f",seconds*1000) end
-- Plain, copyable lines (one fact per line, key=value). The LAST line carries the historic bucket counters.
function D.Lines()
 local out={}
 local data=D.Snapshot()
 local secs=data.seconds
 table.insert(out,"FIELDKIT-DIAG v1 "..tostring(FieldKit and FieldKit.version).." "..(D.enabled and "ON" or "OFF").." clock="..tostring(D.clockName or "-").." (session only; counts and times are NOT native CPU or FPS measurements)")
 local db=FieldKitDB or {}
 local T,M=FieldKitTheme,FieldKitThemeMinimap
 local icons=0;if M and M.ring then for _ in pairs(M.ring) do icons=icons+1 end end
 local paused=D.SkippedNames()
 table.insert(out,"isolation: "..(table.getn(paused)>0 and ("PAUSED modules = "..table.concat(paused,",")) or "none"))
 table.insert(out,"state: theme="..tostring(db.zoneThemes).." mode="..tostring(db.zoneThemeMode).." variant="..tostring(db.zoneThemeVariant).." layout="..tostring(FieldKitZoneThemes and FieldKitZoneThemes.currentLayout).." mapShape="..tostring(M and M.shape).." hudScale="..tostring(db.zoneThemeScale).." opacity="..tostring(db.cardOpacity).." surfaces="..tostring(T and T.surfaces and table.getn(T.surfaces)).." ringIcons="..icons)
 local fps=secs>0 and data.frames/secs or 0
 local cur=type(GetFramerate)=="function" and GetFramerate() or nil
 table.insert(out,"time: sampled="..string.format("%.1f",secs).."s frames="..data.frames.." avgFps="..string.format("%.1f",fps).." nowFps="..(cur and string.format("%.1f",cur) or "n/a").." maxFrameMs="..string.format("%.1f",data.frameMax*1000).." frames>50ms="..D.hist[1].." >100ms="..D.hist[2].." >250ms="..D.hist[3].." >1s="..D.hist[4])
 local worst={}
 for i=1,5 do local x=D.spikes[i];if x[1]>0 then table.insert(worst,string.format("%.0fms@%.1fs[%s]",x[1]*1000,x[2],x[3])) end end
 table.insert(out,"worst frames (>=30ms; [operations that ran in that frame]):")
 if table.getn(worst)==0 then table.insert(out,"  none") end
 for i=1,table.getn(worst) do table.insert(out,"  "..worst[i]) end
 local m=D.mem
 if m.start then table.insert(out,"luaMemoryKB: start="..string.format("%.0f",m.start).." now="..string.format("%.0f",m.last).." min="..string.format("%.0f",m.min).." max="..string.format("%.0f",m.max).." delta="..string.format("%+.0f",m.last-m.start).." samples="..m.samples)
 else table.insert(out,"luaMemoryKB: not available") end
 local rows={}
 for i=1,table.getn(D.opOrder) do local op=D.opOrder[i];if op.calls>0 then table.insert(rows,op) end end
 table.sort(rows,function(a,b) return a.total>b.total end)
 table.insert(out,"operations (inclusive, sorted by total ms): calls | per second | avg ms | max ms | total ms | zero-duration calls (timer resolution)")
 for i=1,table.getn(rows) do
  local op=rows[i]
  table.insert(out,"  "..op.label..": "..op.calls.." | "..string.format("%.2f",secs>0 and op.calls/secs or 0).."/s | "..Ms(op.total/op.calls).." | "..Ms(op.max).." | "..Ms(op.total).." | zero="..op.zero)
 end
 if table.getn(rows)==0 then table.insert(out,"  (no measured operation yet)") end
 local timed,zeros=0,0
 for i=1,table.getn(D.opOrder) do local op=D.opOrder[i];if not op.quiet then timed=timed+op.calls;zeros=zeros+op.zero end end
 if timed>=20 and zeros==timed then table.insert(out,"note: every timed call lasted 0 on this clock (frame-cached): read the 'worst frames' lines, not the per-call times") end
 table.insert(out,"snapshots="..data.counts.snapshot.." scan="..data.counts.scan.." layout="..data.counts.layout.." plates="..data.counts.plates.." | END FIELDKIT-DIAG")
 return out
end
function D.Report()
 local lines=D.Lines()
 for i=1,table.getn(lines) do Say(lines[i]) end
end
function D.Status()
 if D.enabled then
  Say("Diagnostics ON - "..table.getn(D.wrapped).."/"..D.targetCount.." functions measured - frames="..D.frames.." sampled="..string.format("%.1f",D.dtTotal).."s - clock="..tostring(D.clockName).." - /fieldkit diag report")
 else
  Say("Diagnostics OFF - no function wrapped, no counter running - /fieldkit diag on")
 end
end
function D.ReportAPIs()
 local present,total,absent=D.Capabilities()
 Say("Native API availability "..present.."/"..total..
  " (presence only, not proof of correct behavior)")
 if table.getn(absent)>0 then
  -- Two bounded lines; no raw foreign values, names or user data.
  local half=math.floor((table.getn(absent)+1)/2)
  local left={};local right={}
  for i=1,table.getn(absent) do
   if i<=half then table.insert(left,absent[i])
   else table.insert(right,absent[i]) end
  end
  Say("Unavailable: "..table.concat(left,", "))
  if table.getn(right)>0 then Say("Unavailable: "..table.concat(right,", ")) end
 end
end
-- Passive sanity checks for the actual native chat and FieldKit layout.
-- No hooks, reparenting, scanning of other addons or API side effects.
function D.Compatibility()
 local native=getglobal("ChatFrame1")
 local chatPresent=type(native)=="table" or type(native)=="userdata"
 local chatWrite=chatPresent and type(native.AddMessage)=="function"
 local chatRead=chatPresent and type(native.GetNumMessages)=="function"
 local hud=FieldKitHudStack and FieldKitHudStack.root
 local linked=FieldKitDB and FieldKitDB.linkLeftCards==true
 local rootUsable=not linked or (hud and type(hud.GetPoint)=="function")
 local issues={}
 if not chatPresent then table.insert(issues,"ChatFrame1 unavailable") end
 if chatPresent and not chatWrite then table.insert(issues,"ChatFrame1:AddMessage unavailable") end
 if chatPresent and not chatRead then table.insert(issues,"ChatFrame1:GetNumMessages unavailable") end
 if not rootUsable then table.insert(issues,"linked left HUD root unavailable") end
 return {chat=chatPresent and true or false,write=chatWrite and true or false,
  read=chatRead and true or false,linked=linked and true or false,
  root=rootUsable and true or false,issues=issues}
end
function D.ReportCompatibility()
 local state=D.Compatibility()
 Say("Compatibility: native chat="..(state.chat and "present" or "missing")..
  ", message API="..(state.write and "present" or "missing")..
  ", readable count="..(state.read and "present" or "missing")..
  ", linked HUD root="..(state.root and "ready" or "missing"))
 if table.getn(state.issues)>0 then
  for i=1,table.getn(state.issues) do Say("Check: "..state.issues[i]) end
 end
 Say("Passive capability check only; does not detect all addon conflicts.")
end
function D.Command(command)
 if command=="on" then D.Enable(true);Say("Diagnostics enabled for this session ("..table.getn(D.wrapped).." functions measured). /fieldkit diag report | reset | status | off")
 elseif command=="off" then D.Enable(false);Say("Diagnostics disabled, original functions restored, counters cleared.")
 elseif command=="status" then D.Status()
 elseif command=="skip" or string.sub(command,1,5)=="skip " then
  local name=string.sub(command,6)
  if not D.enabled then Say("Isolation tests need /fieldkit diag on first.")
  elseif name=="off" then D.Unskip();Say("Isolation off: every module runs again.")
  elseif D.Skip(name) then Say("Isolation: '"..name.."' is PAUSED (its display stops updating) until /fieldkit diag skip off or diag off.")
  else
   local names={};for key in pairs(isolation) do table.insert(names,key) end;table.sort(names)
   Say("Isolation modules: "..table.concat(names,", ").." | /fieldkit diag skip <name> | skip off")
  end
 elseif command=="reset" then D.Reset();Say("Diagnostics counters reset.")
 elseif command=="api" then D.ReportAPIs()
 elseif command=="compat" then D.ReportCompatibility()
 elseif command=="" or command=="report" then D.Report()
 else Say("Usage: /fieldkit diag on | off | status | reset | report | skip <module> | api | compat") end
end
