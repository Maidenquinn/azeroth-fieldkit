-- Live meter ledger: native meter snapshots + local hit/crit/kill books.
-- Reset uses AZS_CreateMeterCheckpoint when available; hit stats never invent totals.
FieldKitMeterLedger={}
local L=FieldKitMeterLedger
local BURST=1
local books,kills,burstWin,byId,byIcon={},{},{},{},{}
local lastBlow={}
local checkpoint,runKey,cursor,subscribed
local TAKEN_NAMES={
 ["boss melee"]="Boss melee",["boss spell"]="Boss spells",["elite"]="Elites",
 ["mob melee"]="Monster melee",["mob spell"]="Monster spells",["area"]="Ground effects"}

L.views={"damage","healing","boss","taken","party","kills"}
L.labels={"Damage","Healing","Boss damage","Damage taken","Party DPS","Kills"}

local function Text(s,limit)
 if type(s)~="string" then return nil end
 return FieldKitNative and FieldKitNative.Text and FieldKitNative.Text(s,limit or 160) or string.sub(s,1,limit or 160)
end

local function Num(v,lo,hi)
 local n=FieldKit.Number(v,nil,lo,hi);return n
end

local function Strip(msg)
 if type(msg)~="string" then return "" end
 msg=string.gsub(msg,"|c%x%x%x%x%x%x%x%x","")
 msg=string.gsub(msg,"|r","")
 msg=string.gsub(msg,"|H.-|h(.-)|h","%1")
 return msg
end

local function IconOf(name)
 if FieldKitLoadout and FieldKitLoadout.Icon then return FieldKitLoadout.Icon(name) end
 return nil
end

-- Collapse rank / locale rank suffixes so Consecration R39 and R40 share one book.
local function SpellBase(name)
 name=Text(name,120);if not name then return nil end
 name=string.gsub(name,"%s*%(%s*[Rr]an[kg]o?%s*%d+%s*%)%s*$","")
 name=string.gsub(name,"%s+R%d+%s*$","")
 name=string.gsub(name,"%s+$","")
 if name=="" then return nil end
 return name
end

local function Book(name)
 name=SpellBase(name);if not name then return nil end
 local b=books[name]
 if not b then b={hits=0,crits=0,amount=0,maxHit=0,maxCrit=0,burst=0};books[name]=b end
 return b,name
end

local function BurstAdd(name,amount,t)
 local w=burstWin[name]
 if not w or t-w.t0>BURST then burstWin[name]={t0=t,sum=amount};w=burstWin[name]
 else w.sum=w.sum+amount end
 local b=Book(name);if b and w.sum>(b.burst or 0) then b.burst=w.sum end
end

local function IndexSpell(key,spellId,icon)
 if not key then return end
 if spellId~=nil then byId[tostring(spellId)]=key end
 if type(icon)~="string" or icon=="" then icon=IconOf(key) end
 if type(icon)=="string" and icon~="" then byIcon[icon]=key end
end

local function RememberBlow(victim,spell,spellId,icon)
 victim=Text(victim,80);spell=Text(spell,120)
 if not victim or not spell or spell=="" then return end
 if type(icon)~="string" or icon=="" then icon=IconOf(spell) end
 lastBlow[victim]={name=spell,spellId=spellId,icon=icon}
end

function L.ClearHits()
 books={};kills={};burstWin={};byId={};byIcon={};lastBlow={};cursor=nil
end

function L.Reset()
 local prev=checkpoint
 L.ClearHits()
 if type(AZS_ReleaseMeterCheckpoint)=="function" and prev then pcall(AZS_ReleaseMeterCheckpoint,prev) end
 checkpoint=nil
 if type(AZS_GetMeterContext)~="function" or type(AZS_CreateMeterCheckpoint)~="function" then return false end
 local ok,ctx=pcall(AZS_GetMeterContext)
 if not ok or type(ctx)~="table" or type(ctx.runId)~="string" then return false end
 local ok2,cp=pcall(AZS_CreateMeterCheckpoint,ctx.runId)
 if ok2 and type(cp)=="table" and type(cp.checkpointId)=="string" then
  checkpoint=cp.checkpointId;return true
 end
 if ok2 and type(cp)=="string" then checkpoint=cp;return true end
 return false
end

local function RunKey()
 local zone=type(AZS_ZONE)=="table" and tostring(AZS_ZONE.zone or "") or ""
 local t=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or 0
 return zone..":"..tostring(math.floor((t or 0)/30))
end

function L.Boundary()
 local zone=type(AZS_ZONE)=="table" and tostring(AZS_ZONE.zone or "") or ""
 local key=RunKey()
 local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase() or nil
 if not phase or phase=="ready" then
  if runKey then L.ClearHits();checkpoint=nil;runKey=nil end
  return
 end
 if runKey~=key then
  local oldZone=runKey and string.sub(runKey,1,(string.find(runKey,":") or 1)-1) or ""
  if runKey and oldZone~=zone then L.ClearHits();checkpoint=nil end
  runKey=key
 end
end

function L.NoteHit(name,amount,crit,spellId,icon)
 amount=Num(amount,0);if not amount or amount<=0 then return end
 local b,key=Book(name);if not b then return end
 b.hits=b.hits+1;b.amount=b.amount+amount
 if crit then
  b.crits=b.crits+1
  if amount>b.maxCrit then b.maxCrit=amount end
 else
  if amount>b.maxHit then b.maxHit=amount end
 end
 BurstAdd(key,amount,GetTime())
 IndexSpell(key,spellId,icon)
end

function L.NoteKill(name,spellId,icon)
 local b,key=Book(name);if not key then return end
 kills[key]=(kills[key] or 0)+1
 IndexSpell(key,spellId,icon)
end

-- Same credit path as AZS Spell Meter: last damaging spell on that target.
function L.NoteDeath(victim)
 victim=Text(victim,80);if not victim then return end
 local blow=lastBlow[victim]
 if not blow or not blow.name then return end
 L.NoteKill(blow.name,blow.spellId,blow.icon)
 lastBlow[victim]=nil
end

function L.KillsFor(name,spellId,icon)
 local st=L.Stats(name,spellId,icon or IconOf(name))
 return st and (st.kills or 0) or 0
end

local function ResolveBook(name,spellId,icon)
 if spellId~=nil then
  local key=byId[tostring(spellId)];if key and books[key] then return books[key],key end
 end
 if type(icon)=="string" and icon~="" then
  local key=byIcon[icon];if key and books[key] then return books[key],key end
 end
 name=SpellBase(name);if not name then return nil end
 if books[name] then return books[name],name end
 return nil
end

function L.Stats(name,spellId,icon)
 local b,key=ResolveBook(name,spellId,icon)
 if not b then return nil end
 local hits=b.hits or 0
 local crits=b.crits or 0
 return {
  hits=hits,crits=crits,
  critPct=hits>0 and (100*crits/hits) or 0,
  maxHit=b.maxHit or 0,maxCrit=b.maxCrit or 0,
  avg=hits>0 and (b.amount/hits) or 0,
  burst=b.burst or 0,
  amount=b.amount or 0,
  kills=kills[key] or 0,
 }
end

-- Chat combat-log is the reliable hit/crit source (same as MaxHit / SpellMeter).
-- Combat-text has no kill kind; use it only for last-blow + icons when present.
local function IngestCombatEvent(e,countHits)
 if type(e)~="table" then return end
 if e.kind=="damage" then
  local name=type(e.abilityName)=="string" and e.abilityName~="" and e.abilityName or "Melee"
  if countHits then L.NoteHit(name,e.amount,e.critical and true or false,e.spellId,e.icon) end
  if type(e.targetName)=="string" then RememberBlow(e.targetName,name,e.spellId,e.icon) end
 end
end

function L.PollCombatText(countHits)
 if type(AZS_GetCombatTextEvents)~="function" then return end
 local ok,batch,err=pcall(AZS_GetCombatTextEvents,cursor)
 if not ok then return end
 if not batch and type(err)=="table" and err.code=="STREAM_CHANGED" then
  cursor=nil;ok,batch=pcall(AZS_GetCombatTextEvents,nil);if not ok or not batch then return end
 end
 if type(batch)~="table" then return end
 cursor=batch.cursor
 local events=batch.events
 if type(events)=="table" then
  for i=1,math.min(256,table.getn(events)) do IngestCombatEvent(events[i],countHits) end
 end
end

-- Extra minions that log as friendly NPCs rather than UnitName("pet").
local SUMMONS={
 ["Imp"]=true,["Felhunter"]=true,["Voidwalker"]=true,["Succubus"]=true,
 ["Felguard"]=true,["Infernal"]=true,["Inferno"]=true,["Doomguard"]=true,
 ["Dread Lord"]=true,["Pit Lord"]=true,["Wolf"]=true,["Raptor"]=true,
 ["Spirit Wolf"]=true,["Treant"]=true,["Water Elemental"]=true,
}

local function CleanOwner(owner)
 if not owner then return nil end
 owner=string.gsub(owner,"^%s+","")
 owner=string.gsub(owner," %(Critical%)$","")
 owner=string.gsub(owner,"%.$","")
 owner=string.gsub(owner,"%s+$","")
 owner=string.gsub(owner,"^Your ","")
 if owner=="" then return nil end
 return owner
end

local function IsMine(owner)
 owner=CleanOwner(owner)
 if not owner then return nil end
 if type(UnitExists)=="function" and UnitExists("pet") and type(UnitName)=="function" and owner==UnitName("pet") then
  return owner
 end
 if SUMMONS[owner] then return owner end
 return nil
end

local function Attribute(owner,spell)
 local mine=IsMine(owner)
 if mine and spell then return mine..": "..spell end
 return nil
end

function L.ParseChat(msg)
 msg=Strip(msg)
 if msg=="" or string.len(msg)>512 then return end
 local amount,spell,victim,crit,owner
 local _
 local periCrit=string.find(msg,"%(Critical%)") and true or false
 _,_,spell,victim,amount=string.find(msg,"^Your (.+) crits (.+) for ([%d,]+)")
 if amount then crit=true
 else
  _,_,spell,victim,amount=string.find(msg,"^Your (.+) hits (.+) for ([%d,]+)")
 end
 if not amount then
  _,_,spell,victim,amount=string.find(msg,"^Your (.+) critically hits (.+) for ([%d,]+)")
  if amount then crit=true end
 end
 if amount and spell then
  amount=string.gsub(amount,",","")
  L.NoteHit(spell,amount,crit and true or false,nil,IconOf(spell))
  RememberBlow(victim,spell,nil,IconOf(spell))
  return
 end
 -- DoT / periodic: "X suffers N ... damage from your Spell" (+ optional Critical).
 _,_,victim,amount,spell=string.find(msg,"^(.+) suffers ([%d,]+) .-damage from your (.+)$")
 if amount and spell then
  amount=string.gsub(amount,",","")
  spell=string.gsub(spell," %(Critical%)$","")
  spell=string.gsub(spell,"%.$","")
  L.NoteHit(spell,amount,periCrit,nil,IconOf(spell))
  RememberBlow(victim,spell,nil,IconOf(spell))
  return
 end
 -- Pet / summon DoT: "X suffers N ... damage from Pet's Spell"
 _,_,victim,amount,owner,spell=string.find(msg,"^(.+) suffers ([%d,]+) .-damage from (.+)'s (.+)$")
 if amount and owner and spell then
  spell=string.gsub(spell," %(Critical%)$","")
  spell=string.gsub(spell,"%.$","")
  local labeled=Attribute(owner,spell)
  if labeled then
   amount=string.gsub(amount,",","")
   L.NoteHit(labeled,amount,periCrit,nil,IconOf(spell) or IconOf(labeled))
   RememberBlow(victim,labeled,nil,IconOf(spell) or IconOf(labeled))
  end
  return
 end
 -- Pet / summon spell: "Imp's Firebolt hits/crits X for N"
 _,_,owner,spell,victim,amount=string.find(msg,"^(.+)'s (.+) crits (.+) for ([%d,]+)")
 if amount then crit=true
 else
  _,_,owner,spell,victim,amount=string.find(msg,"^(.+)'s (.+) hits (.+) for ([%d,]+)")
 end
 if amount and owner and spell then
  local labeled=Attribute(owner,spell)
  if labeled then
   amount=string.gsub(amount,",","")
   L.NoteHit(labeled,amount,crit and true or false,nil,IconOf(spell) or IconOf(labeled))
   RememberBlow(victim,labeled,nil,IconOf(spell) or IconOf(labeled))
  end
  return
 end
 -- Pet melee: "Wolf hits/crits X for N"
 _,_,owner,victim,amount=string.find(msg,"^(.+) crits (.+) for ([%d,]+)")
 if amount then crit=true
 else
  _,_,owner,victim,amount=string.find(msg,"^(.+) hits (.+) for ([%d,]+)")
 end
 if amount and owner then
  local mine=IsMine(owner)
  if mine then
   amount=string.gsub(amount,",","")
   local labeled=mine..": Melee"
   L.NoteHit(labeled,amount,crit and true or false,nil,IconOf("Melee") or IconOf(labeled))
   RememberBlow(victim,labeled,nil,IconOf("Melee") or IconOf(labeled))
  end
  return
 end
 _,_,spell=string.find(msg,"^Your (.+) kills ")
 if spell then L.NoteKill(spell,nil,IconOf(spell));return end
end

function L.ParseDeath(msg)
 msg=Strip(msg)
 if msg=="" then return end
 local _,_,name=string.find(msg,"^(.+) dies%.?$")
 if not name then _,_,name=string.find(msg,"^You have slain (.+)!") end
 if name then
  name=string.gsub(name,"!$","")
  L.NoteDeath(name)
 end
end

local function Snapshot(metric,scope,period,groupBy,ownerId,healPerspective)
 if type(AZS_GetMeterSnapshot)~="function" or type(AZS_GetMeterContext)~="function" then return nil end
 local ok,ctx=pcall(AZS_GetMeterContext)
 if not ok or type(ctx)~="table" or type(ctx.runId)~="string" then return nil end
 local q={apiVersion=1,runId=ctx.runId,metric=metric,scope=scope or "self",period=period or "run",groupBy=groupBy or "source",windowSeconds=0}
 if metric=="healing" then q.healingPerspective=healPerspective or "received" end
 if ownerId then q.ownerId=ownerId;q.scope=scope or "owner" end
 if checkpoint then q.checkpointId=checkpoint end
 local ok2,snap=pcall(AZS_GetMeterSnapshot,q)
 if not ok2 or type(snap)~="table" then return nil end
 if snap.status~="ready" and snap.status~="ready_empty" then return nil end
 return snap
end

local function SortKey()
 local db=FieldKitDB
 local key=db and db.meterSortKey or "dmg"
 if key~="name" and key~="kills" and key~="dmg" and key~="dps" and key~="share" then key="dmg" end
 return key,db and db.meterSortAsc and true or false
end

local function HiddenSet(view)
 local db=FieldKitDB
 if type(db)~="table" or type(db.meterHiddenRows)~="table" then return nil end
 local set=db.meterHiddenRows[view]
 return type(set)=="table" and set or nil
end

function L.ToggleHide(view,name)
 if type(view)~="string" or type(name)~="string" or name=="" then return end
 if not FieldKitDB then return end
 FieldKitDB.meterHiddenRows=FieldKitDB.meterHiddenRows or {}
 local set=FieldKitDB.meterHiddenRows[view]
 if type(set)~="table" then set={};FieldKitDB.meterHiddenRows[view]=set end
 if set[name] then set[name]=nil else set[name]=true end
end

function L.ClearHidden(view)
 if not FieldKitDB or type(FieldKitDB.meterHiddenRows)~="table" then return end
 if view then FieldKitDB.meterHiddenRows[view]=nil
 else FieldKitDB.meterHiddenRows={} end
end

local function SortLines(out)
 local key,asc=SortKey()
 table.sort(out,function(a,b)
  local av,bv
  if key=="name" then av=a.name or "";bv=b.name or "";if av==bv then return false end;if asc then return av<bv end;return av>bv end
  if key=="kills" then av=a.kills or 0;bv=b.kills or 0
  elseif key=="dps" then av=a.dps or 0;bv=b.dps or 0
  elseif key=="share" then av=a.share or 0;bv=b.share or 0
  else av=a.dmg or 0;bv=b.dmg or 0 end
  if av==bv then return (a.name or "")<(b.name or "") end
  if asc then return av<bv end
  return av>bv
 end)
end

local function FinishLines(view,out,total,rate,known,truncated)
 local hidden=HiddenSet(view)
 local shown={}
 if hidden then
  for i=1,table.getn(out) do
   local line=out[i]
   if not (line.name and hidden[line.name]) then table.insert(shown,line) end
  end
 else shown=out end
 SortLines(shown)
 return shown,total,rate,known,truncated
end

-- Native meters key each rank separately (ability:foo:r39). abilityKey / talentKey /
-- itemKey join ranks; fall back to stripping :rN[:pulse] from the sourceKey.
local function SourceFamily(src,sourceKey)
 if type(src)=="table" then
  if type(src.abilityKey)=="string" and src.abilityKey~="" then return "ability:"..src.abilityKey end
  if type(src.talentKey)=="string" and src.talentKey~="" then return "talent:"..src.talentKey end
  if type(src.itemKey)=="string" and src.itemKey~="" then return "item:"..src.itemKey end
 end
 if type(sourceKey)~="string" or sourceKey=="" then return sourceKey end
 local fam=string.gsub(sourceKey,":r%d+","")
 fam=string.gsub(fam,":pulse$","")
 fam=string.gsub(fam,":empowered$","")
 return fam
end

local function SourceIcon(src)
 if type(src)~="table" or type(src.icon)~="table" then return nil end
 if src.icon.status=="ready" and type(src.icon.path)=="string" then return src.icon.path end
 return nil
end

local function RowsFromSnap(snap)
 local out,total={},0
 if type(snap)~="table" then return out,0,nil,false end
 local sources=type(snap.sources)=="table" and snap.sources or {}
 local actors=type(snap.actors)=="table" and snap.actors or {}
 local rows=snap.rows
 if type(rows)~="table" then return out,0,nil,true end
 local nRows=table.getn(rows)
 local merged,order={},{}
 for i=1,math.min(512,nRows) do
  local row=rows[i]
  if type(row)=="table" then
   local amount=Num(row.displayAmount or row.periodAmount,0) or 0
   local src=row.sourceKey and sources[row.sourceKey] or nil
   local name
   if type(src)=="table" then name=Text(src.name,120) end
   if not name and row.ownerId and actors[row.ownerId] then name=Text(actors[row.ownerId].name,120) end
   if not name then name=Text(row.sourceKey or row.ownerId,120) or "?" end
   name=SpellBase(name) or name
   local rate=row.displayRate and Num(row.displayRate.value,0) or nil
   local proc=(row.nativeProc or row.procClassification=="proc") and 1 or 0
   local fam=SourceFamily(src,row.sourceKey) or ("row:"..tostring(i))
   -- Keep proc / non-proc as separate meter rows (blue proc bars), merge ranks only.
   local bucket=fam.."#"..(proc==1 and "p" or "n")
   local line=merged[bucket]
   if not line then
    line={name=name,dmg=0,dps=0,dpsKnown=false,share=nil,proc=proc,sourceKey=row.sourceKey,ownerId=row.ownerId,icon=SourceIcon(src) or IconOf(name),spellId=nil}
    merged[bucket]=line;table.insert(order,bucket)
   end
   line.dmg=line.dmg+amount
   if rate then line.dps=(line.dps or 0)+rate;line.dpsKnown=true end
   if amount>=(line._top or 0) then
    line._top=amount;line.name=name;line.sourceKey=row.sourceKey;line.ownerId=row.ownerId
    local ic=SourceIcon(src);if ic then line.icon=ic end
   end
   if proc==1 then line.proc=1 end
   total=total+amount
  end
 end
 for i=1,table.getn(order) do
  local line=merged[order[i]]
  if not line.dpsKnown then line.dps=nil else line.dps=line.dps end
  line._top=nil
  table.insert(out,line)
 end
 if type(snap.totals)=="table" then
  local t=Num(snap.totals.displayAmount or snap.totals.periodAmount,0)
  if t then total=t end
 end
 for i=1,table.getn(out) do if total and total>0 then out[i].share=out[i].dmg/total end end
 table.sort(out,function(a,b) return (a.dmg or 0)>(b.dmg or 0) end)
 return out,total,snap.totals and snap.totals.displayRate and Num(snap.totals.displayRate.value,0) or nil,true,nRows>512
end

local function AttachKillStats(lines)
 for i=1,table.getn(lines) do
  local line=lines[i]
  if type(line)=="table" and type(line.name)=="string" then
   local icon=line.icon or IconOf(line.name)
   line.icon=icon
   local st=L.Stats(line.name,line.spellId,icon)
   if st then
    line.kills=st.kills or 0
    line.hits=st.hits;line.crits=st.crits;line.critPct=st.critPct
    line.maxHit=st.maxHit;line.maxCrit=st.maxCrit;line.avg=st.avg;line.burst=st.burst
   else
    line.kills=line.kills or 0
   end
  end
 end
 return lines
end

local function RunSeconds()
 local t=type(AZS_GetRunTime)=="function" and tonumber(AZS_GetRunTime()) or nil
 if not t or t<1 then
  t=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or nil
 end
 if not t or t<1 then t=1 end
 return t
end

function L.Read(view)
 L.Boundary()
 view=view or "damage"
 local healPersp=(FieldKitDB and FieldKitDB.meterHealDone) and "performed" or "received"
 if view=="kills" then
  local out,total={},0
  local localized={};local snap=Snapshot("damage","self","run","source");if snap then local native=RowsFromSnap(snap);for _,row in ipairs(native) do if row.icon then if localized[row.icon] and localized[row.icon]~=row.name then localized[row.icon]=false else localized[row.icon]=row.name end end end end
  for name,count in pairs(kills) do
   table.insert(out,{name=name,displayName=localized[IconOf(name)] or FieldKit_L(name),dmg=count,dps=nil,share=nil,proc=0,kills=count,icon=IconOf(name)})
   total=total+count
  end
  for i=1,table.getn(out) do if total>0 then out[i].share=out[i].dmg/total end end
  return FinishLines(view,out,total,nil,true,false)
 end
 if view=="taken" then
  if type(AZS_TAKEN)~="table" then return {},nil,nil,false,false end
  local out,sum={},0
  local t=RunSeconds()
  for i=1,math.min(32,table.getn(AZS_TAKEN)) do
   local row=AZS_TAKEN[i]
   if type(row)=="table" then
    local src=row.source or row[1];local dmg=Num(row.dmg or row[2],0)
    if type(src)=="string" and dmg then
     -- Same as AZS Spell Meter: per-source DPS = amount / run clock.
     table.insert(out,{name=TAKEN_NAMES[src] or Text(src,80) or src,displayName=FieldKit_L(TAKEN_NAMES[src] or Text(src,80) or src),dmg=dmg,dps=dmg/t,source=src,share=nil})
     sum=sum+dmg
    end
   end
  end
  for i=1,table.getn(out) do if sum>0 then out[i].share=out[i].dmg/sum end end
  return FinishLines(view,out,sum,sum>0 and (sum/t) or 0,true,false)
 end
 if view=="party" then
  local ownerId=FieldKitDB and FieldKitDB.meterPartyOwner
  if type(ownerId)=="string" and ownerId~="" then
   local snap=Snapshot("damage","owner","run","source",ownerId)
   if snap then
    local lines,total,rate,known,truncated=RowsFromSnap(snap)
    return FinishLines(view,AttachKillStats(lines),total,rate,known,truncated)
   end
   return FinishLines(view,{},nil,nil,false,false)
  end
  local snap=Snapshot("damage","party","run","owner")
  if snap then
   local lines,total,rate,known,truncated=RowsFromSnap(snap)
   -- Keep ownerId on rows for party drill-down.
   if type(snap.rows)=="table" then
    for i=1,math.min(table.getn(lines),table.getn(snap.rows)) do
     local r=snap.rows[i]
     if type(r)=="table" then lines[i].ownerId=r.ownerId or r.id or r.key end
    end
   end
   return FinishLines(view,lines,total,rate,known,truncated)
  end
  if type(AZS_GetPartyMeter)=="function" then
   local ok,lines,total,dps=pcall(AZS_GetPartyMeter)
   if ok and type(lines)=="table" then
    local out={}
    for i=1,math.min(16,table.getn(lines)) do
     local row=lines[i]
     if type(row)=="table" and type(row.name)=="string" then
      table.insert(out,{name=Text(row.name,80),dmg=Num(row.dmg,0),dps=Num(row.dps,0),share=Num(row.share,0,1),proc=0,ownerId=row.ownerId or row.id})
     end
    end
    return FinishLines(view,out,Num(total,0),Num(dps,0),true,false)
   end
  end
  return {},nil,nil,false,false
 end
 local metric=view=="healing" and "healing" or "damage"
 local period=view=="boss" and "encounter" or "run"
 local snap=Snapshot(metric,"self",period,"source",nil,view=="healing" and healPersp or nil)
 if snap then
  local lines,total,rate,known,truncated=RowsFromSnap(snap)
  return FinishLines(view,AttachKillStats(lines),total,rate,known,truncated)
 end
 -- Legacy getters (same 512-row bound as the previous FieldKitMeters.Read).
 local map={damage="AZS_GetMeter",healing="AZS_GetHealing",boss="AZS_GetBossMeter"}
 local fn=getglobal(map[view] or "AZS_GetMeter")
 if type(fn)~="function" then return {},nil,nil,false,false end
 local ok,lines,total,rate=pcall(fn)
 if not ok or type(lines)~="table" then return {},nil,nil,false,false end
 local out={}
 local nLines=table.getn(lines)
 for i=1,math.min(512,nLines) do
  local row=lines[i]
  if type(row)=="table" and type(row.name)=="string" then
   table.insert(out,{name=Text(row.name,120),dmg=Num(row.dmg,0),dps=Num(row.dps,0),share=Num(row.share,0,1),proc=row.proc==1 and 1 or 0})
  end
 end
 return FinishLines(view,AttachKillStats(out),Num(total,0),Num(rate,0),true,nLines>512)
end

function L.AppendStats(name,spellId,icon,dmg)
 if not FieldKitDB or FieldKitDB.meterSpellTips==false then return false end
 if type(name)=="string" then
  name=string.gsub(name,"^%d+%.%s*","")
  name=string.gsub(name,"%s*%(.*%)$","")
  name=string.gsub(name,"^%s+","")
  name=string.gsub(name,"%s+$","")
 end
 local st=L.Stats(name,spellId,icon)
 if not st and not dmg then return false end
 GameTooltip:AddLine(" ")
 if dmg then GameTooltip:AddLine(FieldKit_L("Total")..": "..string.format("%d",math.floor(dmg+.5)),1,1,1) end
 if st then
  GameTooltip:AddLine(string.format(FieldKit_L("Hits: %d   Crits: %d (%.0f%%)"),st.hits,st.crits,st.critPct),.9,.9,.9)
  if st.maxHit>0 then GameTooltip:AddLine(FieldKit_L("Max hit")..": "..string.format("%d",st.maxHit),.85,.85,.85) end
  if st.maxCrit>0 then GameTooltip:AddLine(FieldKit_L("Max crit")..": "..string.format("%d",st.maxCrit),1,.55,.2) end
  if st.avg>0 then GameTooltip:AddLine(FieldKit_L("Average")..": "..string.format("%.0f",st.avg),.85,.85,.85) end
  if st.burst>0 then GameTooltip:AddLine(FieldKit_L("Burst (1s)")..": "..string.format("%d",st.burst),.7,.85,1) end
  if st.kills>0 then GameTooltip:AddLine(FieldKit_L("Kills")..": "..tostring(st.kills),.9,.75,.4) end
 else
  GameTooltip:AddLine(FieldKit_L("No hit sample yet for this spell"),.6,.6,.6)
 end
 return true
end

function L.ShowTip(row)
 local name=row and (row.fieldkitSpell or (row.label and row.label:GetText()))
 if type(name)~="string" or name=="" then return false end
 name=string.gsub(name,"^%d+%.%s*","")
 GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
 FieldKit_Text(GameTooltip,name,1,.82,0)
 local line=row.fieldkitLine
 local dmg=line and line.dmg
 local icon=(line and line.icon) or IconOf(name)
 local spellId=line and line.spellId
 L.AppendStats(name,spellId,icon,dmg)
 GameTooltip:Show()
 return true
end

-- Append Max Hit style lines onto native action / spell tooltips.
local function TipName()
 local fs=getglobal("GameTooltipTextLeft1")
 local t=fs and fs.GetText and fs:GetText()
 return type(t)=="string" and t~="" and t or nil
end

local function HookTooltipMethod(method)
 local orig=GameTooltip and GameTooltip[method]
 if type(orig)~="function" or GameTooltip["fieldkitHook_"..method] then return end
 GameTooltip["fieldkitHook_"..method]=true
 GameTooltip[method]=function(a1,a2,a3,a4,a5,a6)
  orig(a1,a2,a3,a4,a5,a6)
  if not FieldKitDB or FieldKitDB.meterSpellTips==false then return end
  local icon,spellId
  if method=="SetAction" and type(GetActionTexture)=="function" and a2 then
   local ok,tex=pcall(GetActionTexture,a2);if ok then icon=tex end
  end
  if L.AppendStats(TipName(),spellId,icon,nil) then GameTooltip:Show() end
 end
end

local tipHooks=CreateFrame("Frame","FieldKitMeterTipHooks")
tipHooks:RegisterEvent("PLAYER_LOGIN")
tipHooks:RegisterEvent("ADDON_LOADED")
tipHooks:SetScript("OnEvent",function()
 if event=="ADDON_LOADED" and arg1 and arg1~="AzerothFieldKit" then return end
 HookTooltipMethod("SetAction");HookTooltipMethod("SetSpell");HookTooltipMethod("SetTalent")
end)

-- Chat combat log always feeds hits/crits/last-blow (MaxHit / SpellMeter path).
-- Hostile death credits the last blow. CT only refreshes last-blow icons (no double hits).
local driver=CreateFrame("Frame","FieldKitMeterLedgerDriver")
local elapsed=0
driver:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
driver:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
driver:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
driver:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")
driver:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
driver:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
driver:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
driver:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_DEATH")
driver:SetScript("OnEvent",function()
 if not FieldKitDB or not FieldKitDB.meterFrame then return end
 if event=="CHAT_MSG_COMBAT_HOSTILE_DEATH" or event=="CHAT_MSG_COMBAT_HOSTILEPLAYER_DEATH" then
  L.ParseDeath(arg1);return
 end
 L.ParseChat(arg1)
end)
driver:SetScript("OnUpdate",function()
 if not FieldKitDB or not FieldKitDB.meterFrame then return end
 elapsed=elapsed+(arg1 or 0)
 if elapsed<.1 then return end;elapsed=0
 L.Boundary()
 -- false = do not NoteHit from CT (chat already counted); still updates lastBlow/icons.
 if type(AZS_GetCombatTextEvents)=="function" then L.PollCombatText(false) end
end)
