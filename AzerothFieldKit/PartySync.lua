-- Optional, request-driven PARTY-only sharing. This is not a native peer-detail
-- API. Both players must opt in; transport delivery must be verified in this
-- custom client. Payloads contain own meter data only, never chat or game saves.
FieldKitPartySync={sequence=0,queue={},pending={},cache={},batches={},replied={},requested={},seen=0,rx=0,tx=0,completed=0}
local S=FieldKitPartySync

function S.Clear()
 S.queue={};S.pending={};S.cache={};S.batches={};S.replied={};S.requested={};S.incoming={}
end

function S.Watch()
 local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase()
 local time=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.t,nil,0)
 local active=FieldKitDB and FieldKitDB.partyDetailSync and phase
 if not S.initialized or (not active and S.active) or (active and not S.active) or (time and S.time and time+1<S.time) then S.Clear() end
 S.initialized=true
 S.active=active;S.time=time
 return active
end

function S.Encode(value)
 return (string.gsub(value,".",function(c)
  local b=string.byte(c)
  if b<32 or b>126 or c=="%" or c=="," or c==";" or c=="|" or c==":" then return string.format("%%%02X",b) end
  return c
 end))
end

function S.Decode(value)
 if type(value)~="string" or string.len(value)>480 then return nil end
 local text=string.gsub(value,"%%(%x%x)",function(h) return string.char(tonumber(h,16)) end)
 if string.len(text)>160 or string.find(text,"[%c|]") then return nil end
 return text
end

function S.Split(value,separator,limit)
 local result={};local pos=1
 while true do
  local at=string.find(value,separator,pos,true)
  table.insert(result,string.sub(value,pos,at and at-1 or -1))
  if table.getn(result)>limit then return nil end
  if not at then return result end
  pos=at+string.len(separator)
 end
end

function S.Number(value)
 if value=="" then return nil end
 local n=FieldKit.Number(value)
 if n and n>=0 then return n end
end

function S.Peer(name)
 if type(name)~="string" or name==UnitName("player") then return false end
 local roster=FieldKitCoop.Roster();return roster[name]==true
end

function S.Value(value)
 local n=FieldKit.Number(value)
 return n and n>=0 and string.format("%.15g",n) or ""
end

-- Snapshot once per accepted request. The entire response is validated before
-- display. A size/source cap is explicit, not passed off as the complete meter.
function S.Snapshot()
 if type(AZS_GetMeter)~="function" then return nil end
 local ok,lines,total,dps=pcall(AZS_GetMeter)
 if not ok or type(lines)~="table" then return nil end
 local records={};local size=0;local partial=table.getn(lines)>128
 for i=1,math.min(128,table.getn(lines)) do
  local line=lines[i]
  if type(line)=="table" and type(line.name)=="string" and string.len(line.name)<=160 and not string.find(line.name,"[%c|]") then
   local record=S.Encode(line.name)..","..S.Value(line.dmg)..","..S.Value(line.dps)..","..S.Value(line.share)..","..(line.proc==1 and "1" or "0")
   if size+string.len(record)>11000 then partial=true;break end
   table.insert(records,record);size=size+string.len(record)+1
  else partial=true end
 end
 local header=S.Value(S.time)..","..S.Value(total)..","..S.Value(dps)..","..table.getn(records)..","..(partial and "1" or "0")
 return header..";"..table.concat(records,";")
end

function S.Parse(body)
 if string.len(body)>12000 then return nil end
 local records=S.Split(body,";",130);if not records then return nil end
 local h=S.Split(records[1],",",5);if not h or table.getn(h)~=5 then return nil end
 local time,count=S.Number(h[1]),S.Number(h[4])
 if not time or not count or count~=math.floor(count) or count>128 or (h[5]~="0" and h[5]~="1") then return nil end
 if not S.time or math.abs(time-S.time)>30 then return nil end
 if (count==0 and (table.getn(records)~=2 or records[2]~="")) or (count>0 and table.getn(records)~=count+1) then return nil end
 local data={rows={},damage=S.Number(h[2]),dps=S.Number(h[3]),time=time,truncated=h[5]=="1",shared=true,received=GetTime()}
 if (h[2]~="" and not data.damage) or (h[3]~="" and not data.dps) then return nil end
 for i=1,count do
  local fields=S.Split(records[i+1],",",5);if not fields or table.getn(fields)~=5 then return nil end
  local name=S.Decode(fields[1]);if not name or name=="" then return nil end
  local damage,dps,share=S.Number(fields[2]),S.Number(fields[3]),S.Number(fields[4])
  if (fields[2]~="" and not damage) or (fields[3]~="" and not dps) or (fields[4]~="" and (not share or share>1)) or (fields[5]~="0" and fields[5]~="1") then return nil end
  table.insert(data.rows,{name=name,dmg=damage,dps=dps,share=share,proc=tonumber(fields[5])})
 end
 table.sort(data.rows,function(a,b) return (a.dmg or 0)>(b.dmg or 0) end)
 return data
end

function S.Request(name)
 if not S.Watch() or not S.Peer(name) then return end
 if not FieldKit.PartyTransportAvailable() then S.reason="unavailable";return end
 local now=GetTime()
 if S.pending[name] and now-S.pending[name].at<=20 then return end
 if S.requested[name] and now-S.requested[name]<10 then return end
 if table.getn(S.queue)>=80 then return end
 S.sequence=S.sequence+1
 local id=string.format("%.0f-%d",now*1000,S.sequence)
 local payload="Q:"..id..":"..S.Encode(name)..":"..S.Value(S.time)
 if string.len(payload)>230 then return end
 S.requested[name]=now;S.pending[name]={id=id,at=now};S.batches[name]=nil
 table.insert(S.queue,payload)
end

function S.Get(name)
 if not S.Watch() or not S.Peer(name) then return nil end
 local cached=S.cache[name]
 if cached and GetTime()-cached.received<=20 then
  if GetTime()-cached.received>=10 then S.Request(name) end
  return cached
 end
 S.cache[name]=nil;S.Request(name)
end

function S.Respond(sender,fields)
 if table.getn(fields)~=4 or S.Decode(fields[3])~=UnitName("player") then return end
 local time=S.Number(fields[4]);if not time or not S.time or math.abs(time-S.time)>30 then return end
 local now=GetTime();if S.replied[sender] and now-S.replied[sender]<10 then return end
 local body=S.Snapshot();if not body then return end
 local chunkSize=math.min(190,218-string.len(fields[2]))
 local count=math.ceil(string.len(body)/chunkSize)
 if count>64 or table.getn(S.queue)+count>80 then return end
 S.replied[sender]=now
 for i=1,count do table.insert(S.queue,"R:"..fields[2]..":"..i..":"..count..":"..string.sub(body,(i-1)*chunkSize+1,i*chunkSize)) end
end

function S.Receive(prefix,payload,channel,sender)
 if prefix~="AFKDETAIL1" or not S.Watch() then return end
 S.seen=S.seen+1
 S.metadata=(channel=="PARTY" and "PARTY" or (channel==nil and "nil" or "other")).."/"..(S.Peer(sender) and "roster" or "unknown sender")
 if channel~="PARTY" or not S.Peer(sender) then return end
 if type(payload)~="string" or string.len(payload)>230 or string.find(payload,"[^ -~]") then return end
 local now=GetTime();local rate=S.incoming[sender]
 if not rate or now-rate.at>=1 then rate={at=now,count=0};S.incoming[sender]=rate end
 rate.count=rate.count+1;if rate.count>24 then return end
 local fields=S.Split(payload,":",5);if not fields or not fields[2] or not string.find(fields[2],"^%d+%-%d+$") or string.len(fields[2])>36 then return end
 S.rx=S.rx+1
 if fields[1]=="Q" then S.Respond(sender,fields);return end
 local pending=S.pending[sender]
 if fields[1]~="R" or table.getn(fields)~=5 or not pending or pending.id~=fields[2] or now-pending.at>20 then return end
 local index,count=S.Number(fields[3]),S.Number(fields[4])
 if not index or not count or count<1 or count>64 or index<1 or index>count or index~=math.floor(index) or count~=math.floor(count) then return end
 local batch=S.batches[sender]
 if not batch then batch={count=count,parts={},received=0,bytes=0};S.batches[sender]=batch end
 if count~=batch.count then return end
 if batch.parts[index] then return end
 batch.parts[index]=fields[5];batch.received=batch.received+1;batch.bytes=batch.bytes+string.len(fields[5])
 if batch.bytes>12000 then S.batches[sender]=nil;S.pending[sender]=nil;return end
 if batch.received==count then
  local data=S.Parse(table.concat(batch.parts))
  if data then S.cache[sender]=data;S.completed=S.completed+1 end
  S.batches[sender]=nil;S.pending[sender]=nil
 end
end

function S.Tick()
 if not S.Watch() then return end
 local now=GetTime()
 for name,pending in pairs(S.pending) do
  if not S.Peer(name) or now-pending.at>20 then S.pending[name]=nil;S.batches[name]=nil end
 end
 for name in pairs(S.cache) do if not S.Peer(name) then S.cache[name]=nil end end
 for _,map in ipairs({S.requested,S.replied,S.incoming}) do
  for name in pairs(map) do if not S.Peer(name) then map[name]=nil end end
 end
 if table.getn(S.queue)==0 then return end
 local ok,reason=FieldKit.SendPartyDetail(S.queue[1])
 S.reason=reason
 if reason~="throttled" then table.remove(S.queue,1) end
 if ok then S.tx=S.tx+1 end
end

function S.Diagnostic()
 S.Watch();local cached=0
 for name,data in pairs(S.cache) do if S.Peer(name) and GetTime()-data.received<=20 then cached=cached+1 end end
 DEFAULT_CHAT_FRAME:AddMessage("FieldKit sync: enabled="..tostring(FieldKitDB and FieldKitDB.partyDetailSync).." api="..tostring(FieldKit.PartyTransportAvailable()).." txAccepted="..S.tx.." seen="..S.seen.." rx="..S.rx.." complete="..S.completed.." cached="..cached.." queue="..table.getn(S.queue).." status="..tostring(S.reason).." metadata="..tostring(S.metadata).." (txAccepted is NOT delivery confirmation)")
end
