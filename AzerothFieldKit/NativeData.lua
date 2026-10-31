-- Optional native APIs are read through a fixed list. No native data is mutated.
-- A run boundary invalidates retained snapshots until a fresh table/stamp/packet.
FieldKitNative={generation={},barriers={},serial=0}
local N=FieldKitNative
local reads={["AZS_GetPhase"]=true,["AZS_GetRunTime"]=true,["AZS_GetTotems"]=true,["AZS_GetSummonGroups"]=true,
 ["AZS_GetTimers"]=true,["AZS_GetRevive"]=true,["AZS_GetUpcomingBosses"]=true,["AZS_GetStoredLevels"]=true,
 ["AZS_GetFlaggedLair"]=true,["AZS_GetMeter"]=true,["AZS_GetHealing"]=true,["AZS_GetBossMeter"]=true}
local sources={AZSTOTEMS="AZS_TOTEMS",AZSPETS="AZS_PETS",AZSTIMERS="AZS_TIMERS",AZSREVIVE="AZS_REVIVE"}
function N.Read(name)
 if not reads[name] then return nil end
 local fn=getglobal(name);if type(fn)~="function" then return nil end
 local ok,a,b,c=pcall(fn);if ok then return a,b,c end
end
function N.Has(name) return reads[name] and type(getglobal(name))=="function" end
function N.Active()
 local phase=N.Read("AZS_GetPhase")
 return phase=="playing" or phase=="paused" or phase=="choosing"
end
function N.Text(value,limit)
 if type(value)~="string" then return "?" end
 -- Native text is display-only. Remove control bytes and WoW markup pipes.
 value=string.gsub(value,"[%c|]","")
 local last=math.min(string.len(value),limit or 160)
 local first=last
 while first>0 and string.byte(value,first)>=128 and string.byte(value,first)<192 do first=first-1 end
 if first>0 then
  local b=string.byte(value,first);local width=b>=240 and 4 or (b>=224 and 3 or (b>=192 and 2 or 1))
  if first+width-1>last then last=first-1 end
 end
 return string.sub(value,1,last)
end
function N.Time()
 local time=FieldKit.Number(N.Read("AZS_GetRunTime"),nil,0)
 if time then return time end
 return type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.t,nil,0) or nil
end
function N.Clock(value)
 local n=FieldKit.Number(value,nil,0);if not n then return "?" end
 return string.format("%d:%02d",math.floor(n/60),math.mod(math.floor(n),60))
end
function N.Watch()
 local phase=N.Read("AZS_GetPhase")
 local time=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.t,nil,0)
 local zone=type(AZS_ZONE)=="table" and AZS_ZONE.zone
 if N.initialized and ((time and N.time and time+1<N.time) or zone~=N.zone or
   (phase=="ready" and N.phase~="ready") or (not N.Active() and N.wasActive)) then
  N.serial=N.serial+1;N.barriers=N.lastSnapshots or {}
 end
 N.lastSnapshots={}
 for prefix,source in pairs(sources) do
  if type(getglobal(source))=="table" then N.lastSnapshots[prefix]={getglobal(source),getglobal(source.."_UPDATED"),N.generation[prefix] or 0} end
 end
 N.initialized=true;N.phase=phase;N.time=time;N.zone=zone;N.wasActive=N.Active()
end
function N.Packet(prefix)
 if sources[prefix] then N.generation[prefix]=(N.generation[prefix] or 0)+1 end
end
function N.Fresh(prefix)
 local barrier=N.barriers[prefix];if not barrier then return true end
 local source=sources[prefix]
 return getglobal(source)~=barrier[1] or getglobal(source.."_UPDATED")~=barrier[2] or (N.generation[prefix] or 0)~=barrier[3]
end

-- One data adapter for local Damage / Healing / Boss views. Native rates retain
-- their own time base; never calculate boss DPS or healing from the run's DPS.
FieldKitMeters={}
local M=FieldKitMeters
M.getters={"AZS_GetMeter","AZS_GetHealing","AZS_GetBossMeter"}
M.labels={"Damage","Healing","Boss damage"}
function M.Mode() return math.floor(FieldKit.Number(FieldKitDB and FieldKitDB.meterView,1,1,3)) end
function M.Read(mode)
 mode=mode or M.Mode()
 local lines,total,rate=N.Read(M.getters[mode] or M.getters[1])
 if type(lines)~="table" then return {},nil,nil,false,false end
 local out={}
 for i=1,math.min(512,table.getn(lines)) do
  local row=lines[i]
  if type(row)=="table" and type(row.name)=="string" then
   table.insert(out,{name=N.Text(row.name),dmg=FieldKit.Number(row.dmg,nil,0),dps=FieldKit.Number(row.dps,nil,0),
    share=FieldKit.Number(row.share,nil,0,1),proc=row.proc==1 and 1 or 0})
  end
 end
 table.sort(out,function(a,b) return (a.dmg or 0)>(b.dmg or 0) end)
 return out,FieldKit.Number(total,nil,0),FieldKit.Number(rate,nil,0),true,table.getn(lines)>512
end
