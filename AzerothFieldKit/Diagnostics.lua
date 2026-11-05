-- Opt-in, read-only runtime diagnostics. No persistence, network, native frame
-- changes, profiling claims or scanning of foreign addon objects.
-- Native 1.12 does not expose precise per-addon CPU accounting.
FieldKitDiagnostics={enabled=false,frames=0,dtTotal=0,dtMax=0,counts={}}
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
function D.Reset()
 D.frames=0;D.dtTotal=0;D.dtMax=0;D.counts={}
 for i=1,table.getn(buckets) do D.counts[buckets[i]]=0 end
end
D.Reset()
function D.Enable(value)
 D.Reset()
 D.enabled=value==true
 return D.enabled
end
function D.Tick(dt)
 if not D.enabled then return end
 if type(dt)~="number" or dt<0 or dt~=dt or dt>10 then return end
 D.frames=D.frames+1
 D.dtTotal=D.dtTotal+dt
 if dt>D.dtMax then D.dtMax=dt end
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
function D.Report()
 local data=D.Snapshot()
 Say("Diagnostics "..(D.enabled and "ON" or "OFF")..
  " (session only; counts are NOT addon CPU or FPS measurements)")
 Say("frames="..data.frames.." sampledSeconds="..string.format("%.1f",data.seconds)..
  " maxFrameDeltaMs="..string.format("%.1f",data.frameMax*1000))
 Say("snapshots="..data.counts.snapshot.." scan="..data.counts.scan..
  " layout="..data.counts.layout.." plates="..data.counts.plates)
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
function D.Command(command)
 if command=="on" then D.Enable(true);Say("Diagnostics enabled for this session. /fieldkit diag off to stop.")
 elseif command=="off" then D.Enable(false);Say("Diagnostics disabled and counters cleared.")
 elseif command=="reset" then D.Reset();Say("Diagnostics counters reset.")
 elseif command=="api" then D.ReportAPIs()
 elseif command=="" or command=="report" then D.Report()
 else Say("Usage: /fieldkit diag on | off | reset | report | api") end
end
