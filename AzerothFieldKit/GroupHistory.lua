-- Short per-member action history built ONLY from the party combat-log chat events the client sends to addons, and a runtime
-- probe that reports what this client really delivers. Nothing is inferred: an entry exists only when a message was received
-- and matched one of the client's OWN localized format strings (so FR/EN follow the client). Memory is bounded: at most
-- `partyHistoryCount` entries per current member, nothing kept for people who left the group, and the events are registered
-- only while the option is on.
FieldKitGroupHistory={log={},formats=nil,stats={received=0,matched=0,unmatched=0,ignored=0}}
local H=FieldKitGroupHistory

-- kind: what the message says; roles: the logical argument order of the ENGLISH format (a localized positional format such
-- as %2$s is mapped back through its index). group: "combat" or "buffs" (the two independent options).
local CANDIDATES={
 {"SPELLLOGOTHEROTHER","damage","combat",{"caster","spell","target","amount"}},
 {"SPELLLOGCRITOTHEROTHER","damage","combat",{"caster","spell","target","amount"},crit=true},
 {"SPELLLOGSCHOOLOTHEROTHER","damage","combat",{"caster","spell","target","amount","school"}},
 {"SPELLLOGCRITSCHOOLOTHEROTHER","damage","combat",{"caster","spell","target","amount","school"},crit=true},
 {"PERIODICAURADAMAGEOTHEROTHER","periodic","combat",{"target","amount","school","caster","spell"}},
 {"HEALEDOTHEROTHER","heal","combat",{"caster","spell","target","amount"}},
 {"HEALEDCRITOTHEROTHER","heal","combat",{"caster","spell","target","amount"},crit=true},
 {"PERIODICAURAHEALOTHEROTHER","hot","combat",{"target","amount","caster","spell"}},
 {"SPELLCASTOTHERSTART","cast","combat",{"caster","spell"}},
 {"SPELLPERFORMOTHERSTART","cast","combat",{"caster","spell"}},
 {"SPELLINTERRUPTOTHEROTHER","interrupt","combat",{"caster","target","spell"}},
 {"AURAADDEDOTHERHELPFUL","buff","buffs",{"target","spell"}},
 {"AURAREMOVEDOTHER","fade","buffs",{"spell","target"}},
}
H.candidates=CANDIDATES
H.events={"CHAT_MSG_SPELL_PARTY_DAMAGE","CHAT_MSG_SPELL_PARTY_BUFF","CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE","CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS","CHAT_MSG_SPELL_AURA_GONE_PARTY"}

-- Client format string -> Lua pattern + the logical index of each capture. Handles %s, %d, %% and positional %1$s forms.
function H.Compile(format)
 if type(format)~="string" or format=="" then return nil end
 local pattern,order="^",{};local i,n,sequence=1,string.len(format),0
 while i<=n do
  local _,e,index,kind=string.find(format,"^%%(%d+)%$([sd])",i)
  if not e then _,e,kind=string.find(format,"^%%([sd])",i);index=nil end
  if e then
   sequence=sequence+1;table.insert(order,tonumber(index) or sequence)
   pattern=pattern..(kind=="d" and "(%d+)" or "(.-)");i=e+1
  elseif string.sub(format,i,i+1)=="%%" then pattern=pattern.."%%";i=i+2
  else
   local c=string.sub(format,i,i)
   if string.find(c,"[%^%$%(%)%%%.%[%]%*%+%-%?]") then pattern=pattern.."%"..c else pattern=pattern..c end
   i=i+1
  end
 end
 return pattern.."$",order
end
function H.Build()
 local list={}
 for _,c in ipairs(CANDIDATES) do
  local text=getglobal and getglobal(c[1])
  local pattern,order=H.Compile(text)
  if pattern then table.insert(list,{name=c[1],kind=c[2],group=c[3],roles=c[4],crit=c.crit,pattern=pattern,order=order,length=string.len(text)}) end
 end
 -- The more specific (longer) format is tried first.
 table.sort(list,function(a,b) if a.length~=b.length then return a.length>b.length end return a.name<b.name end)
 H.formats=list;return list
end

function H.Count() return math.floor(FieldKit.Number(FieldKitDB and FieldKitDB.partyHistoryCount,5,1,20)) end
-- Current members only (never pets, never someone who left).
function H.Members()
 local names={}
 local me=type(UnitName)=="function" and UnitName("player");if me then names[me]=true end
 for i=1,4 do if UnitExists("party"..i) then local n=UnitName("party"..i);if n then names[n]=true end end end
 return names
end
function H.Allowed(group)
 if not FieldKitDB or not FieldKitDB.partyHistory then return false end
 if group=="buffs" then return FieldKitDB.partyHistoryBuffs~=false end
 return FieldKitDB.partyHistoryCombat~=false
end

function H.Parse(message)
 for _,f in ipairs(H.formats or H.Build()) do
  local caps={string.find(message,f.pattern)}
  if caps[1] then
   local role={}
   for k=1,table.getn(f.order) do role[f.roles[f.order[k]] or ("x"..k)]=caps[2+k] end
   return f,role
  end
 end
 return nil
end

function H.Record(name,entry)
 local list=H.log[name]
 if not list then list={};H.log[name]=list end
 table.insert(list,entry)
 local cap=H.Count()
 while table.getn(list)>cap do table.remove(list,1) end
end

function H.Handle(event,message)
 H.stats.received=H.stats.received+1
 if type(message)~="string" then H.stats.ignored=H.stats.ignored+1;return false end
 local f,role=H.Parse(message)
 if not f then H.stats.unmatched=H.stats.unmatched+1;return false end
 if not H.Allowed(f.group) then H.stats.ignored=H.stats.ignored+1;return false end
 local who=(f.kind=="buff" or f.kind=="fade") and role.target or role.caster
 if not who or not H.Members()[who] then H.stats.ignored=H.stats.ignored+1;return false end
 local stamp=type(date)=="function" and date("%H:%M:%S") or nil
 H.Record(who,{kind=f.kind,spell=role.spell,target=role.target,amount=tonumber(role.amount),crit=f.crit,school=role.school,at=GetTime(),stamp=stamp})
 H.stats.matched=H.stats.matched+1;return true
end

-- Spell icon, only when the spell is in the LOCAL spellbook (the client gives no icon API for another player's spells).
function H.Icon(spell)
 if not spell or type(GetSpellName)~="function" or type(GetSpellTexture)~="function" then return nil end
 local now=GetTime()
 if not H.icons or (H.icons[spell]==nil and now>(H.iconScan or 0)) then
  H.icons=H.icons or {};H.iconScan=now+30
  for i=1,300 do
   local name=GetSpellName(i,"spell");if not name then break end
   local texture=GetSpellTexture(i,"spell");if texture and H.icons[name]==nil then H.icons[name]=texture end
  end
  if H.icons[spell]==nil then H.icons[spell]=false end
 end
 return H.icons[spell] or nil
end

function H.Recent(name,limit)
 local list=H.log[name] or {};local out={}
 for i=table.getn(list),math.max(1,table.getn(list)-(limit or H.Count())+1),-1 do table.insert(out,list[i]) end
 return out
end
-- Drop memory of everyone who is no longer in the group.
function H.Prune()
 local members=H.Members()
 for name in pairs(H.log) do if not members[name] then H.log[name]=nil end end
end
function H.Clear() H.log={};H.icons=nil end

local COLORS={damage={1,.55,.35},periodic={.9,.5,.5},heal={.4,.95,.5},hot={.5,.9,.6},cast={.85,.85,.6},interrupt={1,.85,.3},buff={.5,.8,1},fade={.6,.6,.7}}
function H.Line(e)
 local text=(e.stamp and (e.stamp.."  ") or "")..(e.spell or "?")
 if e.kind=="fade" then text=text.." ("..FieldKit_L("faded")..")" end
 if e.target and e.kind~="buff" and e.kind~="fade" then text=text.." > "..e.target end
 if e.amount then text=text.."  "..e.amount..(e.crit and "!" or "") end
 local c=COLORS[e.kind] or {.8,.8,.8}
 return text,c[1],c[2],c[3]
end
function H.Tooltip(tip,name)
 if not FieldKitDB.partyHistory then return end
 local recent=H.Recent(name,FieldKitDB.partyHistoryCount)
 if table.getn(recent)==0 then tip:AddLine(FieldKit_L("No action received yet"),.6,.6,.6);return end
 for _,e in ipairs(recent) do local text,r,g,b=H.Line(e);tip:AddLine(text,r,g,b) end
end

-- Event registration only while the option is on; nothing runs otherwise.
function H.Sync()
 local want=FieldKitDB and FieldKitDB.partyHistory and true or false
 if not H.frame then
  H.frame=CreateFrame("Frame","FieldKitGroupHistoryFrame")
  H.frame:SetScript("OnEvent",function() H.Handle(event,arg1) end)
 end
 if want and not H.registered then for _,e in ipairs(H.events) do H.frame:RegisterEvent(e) end;H.registered=true
 elseif not want and H.registered then for _,e in ipairs(H.events) do H.frame:UnregisterEvent(e) end;H.registered=false;H.Clear() end
 if want then H.Prune() end
end

-- ---------------------------------------------------------------------------------------------------------------------
-- /fieldkit groupprobe [api|events [seconds]|items [notify]|reset] : what THIS client really exposes. Read-only.
local function Say(text) DEFAULT_CHAT_FRAME:AddMessage("groupprobe: "..text) end
local function Has(name) return type(getglobal(name))=="function" end
function H.ProbeApi()
 local fns={"GetSpellName","GetSpellTexture","GetSpellCooldown","GetItemInfo","GetInventoryItemLink","GetInventoryItemTexture","GetInventoryItemCount","GetInventoryItemCooldown","GetInventoryItemQuality","GetContainerItemLink","UnitIsDead","UnitIsGhost","UnitIsDeadOrGhost","UnitIsConnected","UnitIsVisible","UnitInRange","UnitLevel","UnitClass","UnitPowerType","CheckInteractDistance","CanInspect","NotifyInspect","ClearInspectPlayer","SetPortraitTexture","GetNumPartyMembers","UnitBuff","UnitDebuff","date","time"}
 local missing,present={},{}
 for _,n in ipairs(fns) do if Has(n) then table.insert(present,n) else table.insert(missing,n) end end
 Say("functions present: "..table.concat(present,", "))
 Say("functions MISSING: "..(table.getn(missing)>0 and table.concat(missing,", ") or "none"))
 local good,bad={},{}
 for _,c in ipairs(CANDIDATES) do if type(getglobal(c[1]))=="string" then table.insert(good,c[1]) else table.insert(bad,c[1]) end end
 Say("message formats provided by the client ("..table.getn(good).."/"..table.getn(CANDIDATES).."): "..table.concat(good,", "))
 if table.getn(bad)>0 then Say("message formats NOT provided (those kinds cannot be parsed): "..table.concat(bad,", ")) end
 for _,unit in ipairs({"player","party1","party2","party3","party4"}) do
  if UnitExists(unit) then
   local function V(f,...) if type(f)~="function" then return "n/a" end local ok,r=pcall(f,unpack(arg));return ok and tostring(r) or "error" end
   Say(unit.." "..tostring(UnitName(unit)).." hp="..V(UnitHealth,unit).."/"..V(UnitHealthMax,unit).." power="..V(UnitMana,unit).."/"..V(UnitManaMax,unit).." type="..V(UnitPowerType,unit).." level="..V(UnitLevel,unit).." dead="..V(UnitIsDead,unit).." ghost="..V(UnitIsGhost,unit).." deadOrGhost="..V(UnitIsDeadOrGhost,unit).." connected="..V(UnitIsConnected,unit).." visible="..V(UnitIsVisible,unit).." inRange="..V(UnitInRange,unit).." interact="..V(CheckInteractDistance,unit,1))
  end
 end
end
function H.ProbeItems(notify)
 for _,unit in ipairs({"player","party1","party2","party3","party4"}) do
  if UnitExists(unit) then
   local found,total={},0
   for slot=1,19 do
    local link=type(GetInventoryItemLink)=="function" and GetInventoryItemLink(unit,slot)
    local texture=type(GetInventoryItemTexture)=="function" and GetInventoryItemTexture(unit,slot)
    if link or texture then total=total+1;if table.getn(found)<3 then table.insert(found,slot..":"..(link and "link" or "")..(texture and " tex" or "")) end end
   end
   Say(unit.." equipped slots readable without inspect: "..total.."/19  can-inspect="..tostring(type(CanInspect)=="function" and CanInspect(unit)).." sample "..table.concat(found,"; "))
   if notify and unit~="player" and type(NotifyInspect)=="function" and type(CanInspect)=="function" and CanInspect(unit) then H.notifyUnit=unit;H.notifyAt=GetTime()+1.5;pcall(NotifyInspect,unit) end
  end
 end
 Say("item USE events: this client's list contains no per-item use event for other players (only UNIT_INVENTORY_CHANGED, BAG_UPDATE*, CHAT_MSG_LOOT); item use is NOT detectable and is not claimed.")
end
function H.ProbeEvents(seconds)
 H.probe={until_=GetTime()+seconds,counts={},samples={}}
 if not H.probeFrame then
  H.probeFrame=CreateFrame("Frame","FieldKitGroupProbeFrame")
  H.probeFrame:SetScript("OnEvent",function()
   local p=H.probe;if not p then return end
   p.counts[event]=(p.counts[event] or 0)+1
   if not p.samples[event] then p.samples[event]={} end
   if table.getn(p.samples[event])<3 then table.insert(p.samples[event],"arg1="..string.sub(tostring(arg1),1,110).." arg2="..string.sub(tostring(arg2),1,30).." arg3="..string.sub(tostring(arg3),1,30)) end
  end)
  H.probeFrame:SetScript("OnUpdate",function()
   if H.notifyAt and GetTime()>=H.notifyAt then local u=H.notifyUnit;H.notifyAt=nil;H.ProbeItems(false);Say("(re-read after NotifyInspect "..tostring(u)..")") end
   local p=H.probe;if p and GetTime()>=p.until_ then H.ProbeReport() end
  end)
 end
 local list={}
 for _,e in ipairs(H.events) do table.insert(list,e) end
 for _,e in ipairs({"CHAT_MSG_COMBAT_PARTY_HITS","CHAT_MSG_COMBAT_PARTY_MISSES","CHAT_MSG_SPELL_PET_DAMAGE","UNIT_INVENTORY_CHANGED","BAG_UPDATE","CHAT_MSG_LOOT","PARTY_MEMBERS_CHANGED","UNIT_AURA","UNIT_SPELLCAST_START"}) do table.insert(list,e) end
 H.probe.registered=list
 for _,e in ipairs(list) do H.probeFrame:RegisterEvent(e) end
 Say("listening for "..seconds.." s to "..table.getn(list).." events; play with the group, then read the report.")
end
function H.ProbeReport()
 local p=H.probe;if not p then return end
 for _,e in ipairs(p.registered) do H.probeFrame:UnregisterEvent(e) end
 H.probe=nil
 local any=false
 for _,e in ipairs(p.registered) do
  local n=p.counts[e] or 0
  Say(string.format("%-46s %d event(s)",e,n));if n>0 then any=true;for _,s in ipairs(p.samples[e]) do Say("    "..s) end end
 end
 if not any then Say("no event received: either nothing happened in the group, or this client does not deliver them to addons.") end
end
function H.Probe(arg)
 local _,_,sub,rest=string.find(arg or "","^groupprobe%s*(%a*)%s*(%d*)")
 if sub=="events" then H.ProbeEvents(tonumber(rest) or 30)
 elseif sub=="items" then H.ProbeItems(string.find(arg,"notify",1,true) and true or false)
 elseif sub=="reset" then H.Clear();Say("history cleared")
 elseif sub=="stats" then Say(string.format("history received=%d matched=%d unmatched=%d ignored=%d",H.stats.received,H.stats.matched,H.stats.unmatched,H.stats.ignored))
 else H.ProbeApi() end
 if sub~="events" and sub~="stats" and sub~="reset" then Say("usage: /fieldkit groupprobe [api | events [seconds] | items [notify] | stats | reset]") end
end
