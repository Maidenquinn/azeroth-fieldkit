-- FieldKit scrolling text: native chat events + native healing totals, Lua 5.0.
-- Independent implementation; MSBT was consulted for configuration concepts.
FieldKitCombat={}
local C=FieldKitCombat
C.fonts={{"Friz Quadrata","Fonts\\FRIZQT__.TTF"},{"Arial Narrow","Fonts\\ARIALN.TTF"},{"Morpheus","Fonts\\MORPHEUS.TTF"},{"Skurri","Fonts\\SKURRI.TTF"}}
C.defs={
 {"out","Dégâts infligés",{1,.85,.3}}, {"crit","Critiques infligés",{1,.5,.05}},
 {"incoming","Dégâts reçus",{1,.25,.25}}, {"incomingCrit","Critiques reçus",{1,.1,.5}},
 {"heal","Soins reçus",{.3,1,.4}}, {"outPeriodic","Dégâts périodiques infligés",{1,.85,.3}},
 {"incomingPeriodic","Dégâts périodiques reçus",{1,.25,.25}},
 {"miss","Ratés",{.65,.75,1},"Raté"}, {"dodge","Esquives",{.3,.7,1},"Esquive"},
 {"parry","Parades",{.4,.8,1},"Parade"}, {"block","Blocages complets",{.6,.8,1},"Blocage"},
 {"resist","Résistances complètes",{.7,.5,1},"Résisté"}, {"absorb","Absorptions complètes",{.85,.6,1},"Absorbé"},
 {"immune","Immunités",{.8,.5,1},"Insensible"}, {"evade","Évitements",{.6,.7,1},"Évitement"}}
C.byKind={};for i=1,table.getn(C.defs) do C.byKind[C.defs[i][1]]=C.defs[i] end
C.defaults={combatText=false,combatTextGroup=true,combatTextHealing=true,combatTextOutgoing=true,combatTextIncoming=true,
 combatTextFontSize=16,combatTextCritSize=20,combatTextFont=1,combatTextCritFont=0,combatTextOutline=2,combatTextOpacity=100,
 combatTextMax=5,combatTextSpacing=27,combatTextDuration=18,combatTextWindow=25,combatTextMin=0,combatTextHealMin=5,
 combatTextX=180,combatTextY=-45,combatTextIncomingX=-180,combatTextIncomingY=-45,combatTextSplit=true,
 combatTextNames=true,combatTextCounts=true,combatTextDirection=1,combatTextIgnore="",
 -- AS 0.138+: pin numbers to the hit spot via AZS_GetCombatTextEvents / Project / Register.
 combatTextWorld=false}
-- Read and clamp one numeric combat option, tolerating invalid saved values.
function C.Number(key,default,min,max)
 local n=FieldKitDB and tonumber(FieldKitDB[key]) or default
 if not n or n~=n then n=default end
 return math.max(min,math.min(max,n))
end
-- Initialize combat defaults once per DB table; no frames are recreated here.
function C.Ensure()
 if type(FieldKitDB)~="table" then return false end
 if C.owner==FieldKitDB and type(FieldKitDB.combatEvents)=="table" then return true end
 for k,v in pairs(C.defaults) do if FieldKitDB[k]==nil then FieldKitDB[k]=v end end
 if type(FieldKitDB.combatEvents)~="table" then FieldKitDB.combatEvents={} end
 for i=1,table.getn(C.defs) do
  local d=C.defs[i];local e=FieldKitDB.combatEvents[d[1]]
  if type(e)~="table" then e={};FieldKitDB.combatEvents[d[1]]=e end
  if e.enabled==nil then e.enabled=true end
 end
 C.owner=FieldKitDB;return true
end
-- Read or initialize one category override.
function C.Event(kind)
 if not C.Ensure() then return nil end
 if type(FieldKitDB.combatEvents[kind])~="table" then FieldKitDB.combatEvents[kind]={enabled=true} end
 return FieldKitDB.combatEvents[kind]
end
-- Resolve and clamp an RGB override against its category default.
function C.Color(kind)
 local d=C.byKind[kind];if not d then return 1,1,1 end
 local e=C.Event(kind);local c=e and e.color
 local r={}
 for i=1,3 do
  local v=type(c)=="table" and tonumber(c[i]) or d[3][i]
  if not v or v~=v then v=d[3][i] end
  r[i]=math.max(0,math.min(1,v))
 end
 return r[1],r[2],r[3]
end
-- Bound a UTF-8 text field without cutting an accented character in half.
-- Truncate UTF-8 safely for bounded labels/lists.
function C.LimitText(text,limit)
 if type(text)~="string" then return "" end
 limit=tonumber(limit) or 0
 local last=math.min(string.len(text),math.max(0,math.floor(limit)));if last<=0 then return "" end
 local first=last
 while first>1 and string.byte(text,first)>=128 and string.byte(text,first)<192 do first=first-1 end
 local lead=string.byte(text,first)
 local width=lead>=240 and 4 or (lead>=224 and 3 or (lead>=192 and 2 or 1))
 if first+width-1>last then last=first-1 end
 return string.sub(text,1,last)
end
local f=CreateFrame("Frame","FieldKitCombatText",UIParent)
f:SetWidth(320);f:SetHeight(320);f:SetFrameStrata("HIGH");f:SetPoint("CENTER",UIParent,"CENTER",0,0)
local slots,pending={},{}
local serial=0
local ignoredText,ignored=nil,{}
for i=1,10 do
 local fs=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
 fs:SetWidth(320);fs:SetJustifyH("CENTER");fs:Hide();slots[i]={fs=fs,active=false}
end
-- Cache up to 32 exact ability-name exclusions; healing prefixes are not part of the name.
local function Ignored(label)
 local text=FieldKitDB.combatTextIgnore or ""
 if type(text)~="string" then text="" end
 text=C.LimitText(text,2000)
 if text~=ignoredText then
  ignoredText=text;ignored={};local at,n=1,0
  while n<32 do
   local a,b,line=string.find(text,"([^\r\n]+)",at);if not a then break end
   line=string.gsub(string.gsub(line,"^%s+",""),"%s+$","")
   if line~="" then ignored[string.lower(line)]=true;n=n+1 end
   at=b+1
  end
 end
 local name=string.gsub(label,"^Heal: ","")
 return ignored[string.lower(name)]
end
-- Apply category, direction and ability filters before allocating visible text.
local function Allowed(v)
 if not C.Ensure() or not FieldKitDB.combatText then return false end
 local e=C.Event(v.kind);if not e or not e.enabled then return false end
 if v.kind=="heal" then if not FieldKitDB.combatTextHealing then return false end
 elseif v.incoming then if not FieldKitDB.combatTextIncoming then return false end
 elseif not FieldKitDB.combatTextOutgoing then return false end
 if Ignored(v.filterName or v.label) then return false end
 return true
end
-- Reuse one of at most ten display slots; oldest visible text is replaced at saturation.
local function Emit(v)
 if not v.preview and not Allowed(v) then return end
 local limit=math.floor(C.Number("combatTextMax",5,1,10));local slot
 for i=1,limit do if not slots[i].active then slot=slots[i];break end end
 if not slot then
  slot=slots[1];for i=2,limit do if slots[i].serial<slot.serial then slot=slots[i] end end
 end
 serial=serial+1;slot.serial=serial;slot.active=true;slot.start=GetTime();slot.y=0;slot.value=v
end
-- Merge same-skill/category events in a short window; cap pending groups at 64.
-- Optional `anchor` (AS 0.138+) keeps the number over the hit / death spot.
local function Queue(label,amount,kind,incoming,filterName,generated,anchor)
 local v={label=label,amount=amount,kind=kind,incoming=incoming,filterName=filterName,generated=generated,count=1,start=GetTime(),anchor=anchor}
 if not Allowed(v) then return end
 if amount then
  if amount<=0 then return end
  local threshold=kind=="heal" and C.Number("combatTextHealMin",5,0,1000000) or C.Number("combatTextMin",0,0,1000000)
  if amount<threshold then return end
 end
 -- World-anchored hits never merge: each float stays above its own target.
 if anchor and FieldKitDB.combatTextWorld then Emit(v);return end
 local key=kind..":"..tostring(incoming)..":"..label;local old=pending[key]
 if old then
  if FieldKitDB.combatTextGroup and v.start-old.start<C.Number("combatTextWindow",25,5,75)/100 then
   if amount then old.amount=old.amount+amount end;old.count=old.count+1;return
  end
  Emit(old);pending[key]=nil
 end
 if not FieldKitDB.combatTextGroup then Emit(v);return end
 local count=0;for k in pairs(pending) do count=count+1 end
 if count>=64 then return end
 pending[key]=v
end
-- Parse a finite comma-formatted combat amount as data.
local function Amount(n) return n and FieldKit.Number((string.gsub(n,",",""))) end
-- AS 0.138 world-anchored combat text (opt-in): official Addon API "version 1".
-- Outgoing hits only; incoming damage and healing stay on chat / AZS_HEALING.
local worldCursor,worldHandler,worldCaps=nil,false,nil
local function WorldReady()
 if not FieldKitDB or not FieldKitDB.combatText or not FieldKitDB.combatTextWorld then return false end
 if type(AZS_GetCombatTextEvents)~="function" or type(AZS_ProjectCombatTextAnchors)~="function" then return false end
 if type(AZS_GetCombatTextCapabilities)=="function" then
  if worldCaps==nil then
   local ok,caps=pcall(AZS_GetCombatTextCapabilities)
   worldCaps=ok and type(caps)=="table" and caps or false
  end
  if worldCaps==false then return false end
 end
 return true
end
local function FiniteNumber(n)
 return type(n)=="number" and n==n and n>-100000000 and n<100000000
end
local function PlaceWorld(fs,x,y,rise)
 if not FiniteNumber(x) or not FiniteNumber(y) then return false end
 local parent=WorldFrame or UIParent
 fs:ClearAllPoints()
 fs:SetPoint("CENTER",parent,"BOTTOMLEFT",x,y+(rise or 0))
 return true
end
local function StyleSlot(s,v,size,now,lifetime)
 local critical=v.kind=="crit" or v.kind=="incomingCrit"
 local e=C.Event(v.kind)
 local override=tonumber(e.size)
 if override and override>=10 and override<=40 then size=override end
 local font=C.Number("combatTextFont",1,1,4)
 if critical and C.Number("combatTextCritFont",0,0,4)>0 then font=C.Number("combatTextCritFont",0,0,4) end
 local path=C.fonts[math.floor(font)][2];local outlines={"","OUTLINE","THICKOUTLINE"};local outline=outlines[math.floor(C.Number("combatTextOutline",2,1,3))]
 local style=path..size..outline
 if s.style~=style then
  local ok,result=pcall(s.fs.SetFont,s.fs,path,size,outline)
  if not ok or result==false then s.fs:SetFont(C.fonts[1][2],size,"OUTLINE") end
  s.fs:SetHeight(size+8);s.style=style
 end
 local text=v.label
 if v.previewKind then text=FieldKit_L("[Preview]").." "..FieldKit_L(C.byKind[v.previewKind][4] or C.byKind[v.previewKind][2]) end
 if v.generated then text=FieldKit_L(text) end
 if v.kind=="heal" then
  local _,_,name=string.find(v.label,"^Heal: (.*)$")
  if name then text=FieldKit_L("Heal: ")..name end
 end
 if C.byKind[v.kind] and C.byKind[v.kind][4] and not v.preview then
  local outcome=C.byKind[v.kind][4]
  local at=string.len(v.label)-string.len(outcome)+1
  if at>0 and string.sub(v.label,at)==outcome then text=string.sub(v.label,1,at-1)..FieldKit_L(outcome)..string.sub(v.label,at+string.len(outcome)) end
 end
 if v.amount then
  if not FieldKitDB.combatTextNames and not v.preview then text="" end
  text=text..(text~="" and " " or "")..string.format("%d",v.amount)
 end
 if FieldKitDB.combatTextCounts and v.count>1 then text=text.." x"..v.count end
 if s.text~=text then s.fs:SetText(text);s.text=text end
 local r,g,b=C.Color(v.kind)
 if s.r~=r or s.g~=g or s.b~=b then s.fs:SetTextColor(r,g,b);s.r=r;s.g=g;s.b=b end
 local age=now-s.start
 s.fs:SetAlpha(C.Number("combatTextOpacity",100,10,100)/100*math.min(1,math.max(0,(lifetime-age)/(lifetime/3))))
 return size
end
local function IngestWorldEvent(e)
 if type(e)~="table" then return end
 local presented=tonumber(e.presentedAt)
 if presented and GetTime()-presented>3 then return end
 local anchor=e.anchorStatus=="ready" and e.anchorId or nil
 if type(anchor)~="string" or anchor=="" then anchor=nil end
 if e.kind=="miss" then
  local result=type(e.result)=="table" and e.result or nil
  local key=result and result.key
  if type(key)~="string" or not C.byKind[key] then key="miss" end
  local spell=type(e.abilityName)=="string" and e.abilityName~="" and e.abilityName or nil
  local text=result and type(result.text)=="string" and result.text~="" and result.text or (C.byKind[key] and C.byKind[key][4]) or key
  if spell then text=spell..": "..text end
  text="> "..text
  Queue(text,nil,key,false,spell,false,anchor)
  return
 end
 if e.kind~="damage" then return end
 local amount=tonumber(e.amount);if not amount or amount<=0 then return end
 local spell=type(e.abilityName)=="string" and e.abilityName~="" and e.abilityName or "Hit"
 local crit=e.critical and true or false
 local kind=e.periodic and "outPeriodic" or (crit and "crit" or "out")
 Queue(spell,amount,kind,false,spell,false,anchor)
end
local function PollWorldCombat()
 if not WorldReady() then return false end
 local ok,batch,err=pcall(AZS_GetCombatTextEvents,worldCursor)
 if not ok then return false end
 if not batch and type(err)=="table" and err.code=="STREAM_CHANGED" then
  worldCursor=nil;C.Clear()
  ok,batch=pcall(AZS_GetCombatTextEvents,nil)
  if not ok or not batch then return false end
 end
 if type(batch)~="table" then return false end
 worldCursor=batch.cursor
 local events=batch.events
 if type(events)=="table" then
  for i=1,math.min(256,table.getn(events)) do IngestWorldEvent(events[i]) end
 end
 if batch.hasMore then
  local guard=0
  while batch.hasMore and guard<4 do
   guard=guard+1
   ok,batch=pcall(AZS_GetCombatTextEvents,worldCursor)
   if not ok or type(batch)~="table" then break end
   worldCursor=batch.cursor
   events=batch.events
   if type(events)=="table" then
    for i=1,math.min(256,table.getn(events)) do IngestWorldEvent(events[i]) end
   end
  end
 end
 return true
end
local function ProjectWorldSlots()
 if not WorldReady() or type(AZS_ProjectCombatTextAnchors)~="function" then return end
 local now=GetTime();local lifetime=C.Number("combatTextDuration",18,6,50)/10
 local ids,map={},{}
 for i=1,10 do
  local s=slots[i]
  if s and s.active and s.value and type(s.value.anchor)=="string" then
   table.insert(ids,s.value.anchor);map[table.getn(ids)]=s
  end
 end
 if table.getn(ids)==0 then return end
 local ok,projection=pcall(AZS_ProjectCombatTextAnchors,ids,"follow")
 if not ok or type(projection)~="table" or type(projection.entries)~="table" then
  for i=1,table.getn(map) do if map[i] then map[i].fs:Hide() end end
  return
 end
 for i=1,math.min(table.getn(ids),table.getn(projection.entries)) do
  local point,s=projection.entries[i],map[i]
  if s and s.active and s.value then
   local size=C.Number(s.value.kind=="crit" and "combatTextCritSize" or "combatTextFontSize",s.value.kind=="crit" and 20 or 16,10,40)
   if type(point)=="table" and point.state=="onScreen" and type(point.x)=="number" and type(point.y)=="number" then
    -- 0.139.2 exposes both player and camera distances. Camera distance
    -- controls legibility; player distance is used only as a safety cull.
    local playerYards=tonumber(point.playerDistance)
    local cameraYards=tonumber(point.cameraDistance)
    if (playerYards and (not FiniteNumber(playerYards) or playerYards>130))
       or not FiniteNumber(point.x) or not FiniteNumber(point.y) then
     s.fs:Hide()
    else
     -- Gentle scaling, bounded to avoid giant text near the camera.
     if cameraYards and FiniteNumber(cameraYards) and cameraYards>0 then
      local factor=math.sqrt(28/math.max(cameraYards,8))
      factor=math.max(0.75,math.min(1.25,factor))
      size=math.max(10,math.min(40,math.floor(size*factor+0.5)))
     end
     StyleSlot(s,s.value,size,now,lifetime)
     local rise=(now-s.start)*18
     if PlaceWorld(s.fs,point.x,point.y,rise) then s.fs:Show() else s.fs:Hide() end
    end
   else
    s.fs:Hide()
   end
  end
 end
end
local function EnsureWorldHandler()
 if worldHandler or type(AZS_RegisterCombatTextFrameHandler)~="function" then return end
 local ok=pcall(AZS_RegisterCombatTextFrameHandler,function()
  if not WorldReady() then return end
  PollWorldCombat()
  -- Flush grouped pending immediately for anchored hits (already Emit'd) and layout.
  local now=GetTime();local lifetime=C.Number("combatTextDuration",18,6,50)/10
  for i=1,10 do
   local s=slots[i]
   if s and s.active then
    if now-s.start>=lifetime or (not s.value.preview and not Allowed(s.value)) then s.active=false;s.fs:Hide() end
   end
  end
  ProjectWorldSlots()
 end)
 worldHandler=ok and true or false
end
local avoidance={
 {"dodge",{" was dodged"," is dodged","^you dodge ","%. .- dodges%.?$","%. you dodge%.?$"}},
 {"parry",{" was parried"," is parried","^you parry ","%. .- parries%.?$","%. you parry%.?$"}},
 {"block",{" was blocked"," is blocked","^you block "," blocks your ","%. you block%.?$"}},
 {"resist",{" was resisted"," is resisted","^you resist "," resists your ","%. resisted%.?$"}},
 {"absorb",{" was absorbed"," is absorbed","^you absorb "," absorbs your ","%. absorbed%.?$"}},
 {"immune",{" is immune"," are immune","%. immune%.?$"}},
 {"evade",{" was evaded"," is evaded","%. .- evades%.?$","%. evaded%.?$"}},
 {"miss",{"^you miss ","^your .- misses ","^your .- missed "," misses you"," missed you","%. miss%.?$"}}}
-- Recognize only full avoidance templates; partial blocks/resists stay in their damage event.
local function Outcome(msg)
 local lower=string.lower(msg)
 for i=1,table.getn(avoidance) do
  local patterns=avoidance[i][2]
  for j=1,table.getn(patterns) do if string.find(lower,patterns[j]) then return avoidance[i][1] end end
 end
end
-- Parse bounded legacy combat text; unrecognized messages do not generate invented events.
-- World API covers outgoing damage/misses only: skip those chat lines when live, keep
-- incoming damage, incoming avoidance, and let Healing() own heal floats.
local function Capture(msg,ev)
 if type(msg)~="string" or string.len(msg)>4096 then return end
 if not C.Ensure() or not FieldKitDB.combatText or type(msg)~="string" then return end
 local native=WorldReady()
 local _,_,amount,label=string.find(msg,"^.- suffers ([%d,]+) .- damage from your (.-)%.")
 if amount then if not native then Queue(label,Amount(amount),"outPeriodic",false) end;return end
 local _,_,taken=string.find(msg,"^You suffer ([%d,]+) .- damage from ")
 if taken then
  local _,_,spell=string.find(msg," from .-'s (.-)%.")
  Queue(spell or "Taken",Amount(taken),"incomingPeriodic",true,nil,not spell);return
 end
 local _,_,a=string.find(msg," for ([%d,]+)")
 if a then
  local _,_,skill=string.find(msg,"^Your (.-) hits ")
  local crit=string.find(msg," crits ") or string.find(msg," critically hits ") or string.find(msg,"^You crit ") or string.find(msg,"^You critically hit ")
  if not skill then _,_,skill=string.find(msg,"^Your (.-) crits ") end
  if not skill then _,_,skill=string.find(msg,"^Your (.-) critically hits ") end
  local kind=crit and "crit" or "out";local incoming=false;local generated=false
  if string.find(msg,"hits you") or string.find(msg,"crits you") or string.find(msg,"critically hits you") then
   local _,_,sourceSkill=string.find(msg,"^.-'s (.-) hits you")
   if not sourceSkill then _,_,sourceSkill=string.find(msg,"^.-'s (.-) crits you") end
   if not sourceSkill then _,_,sourceSkill=string.find(msg,"^.-'s (.-) critically hits you") end
   skill=sourceSkill or "Taken";generated=not sourceSkill;kind=crit and "incomingCrit" or "incoming";incoming=true
  elseif not skill then
   generated=true
   if string.find(msg,"^You hit ") then skill="Hit"
   elseif string.find(msg,"^You crit ") or string.find(msg,"^You critically hit ") then skill="Crit" end
  end
  if skill then
   if native and not incoming then return end
   Queue(skill,Amount(a),kind,incoming,nil,generated);return
  end
 end
 -- Full avoidance only. Partial blocked/resisted amounts are already in the damage hit.
 local kind=not a and Outcome(msg)
 if kind then
  local incoming=ev=="CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" or ev=="CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE"
  if string.find(msg,"^You dodge") or string.find(msg,"^You parry") or string.find(msg,"^You block") or string.find(msg,"^You resist") or string.find(msg,"you are immune") then incoming=true end
  local _,_,skill=string.find(msg,"^Your (.-) was ")
  if not skill then _,_,skill=string.find(msg,"^Your (.-) is ") end
  if not skill then _,_,skill=string.find(msg,"^Your (.-) misses ") end
  if not skill then _,_,skill=string.find(msg,"^Your (.-) missed ") end
  if native and not incoming then return end
  local text=C.byKind[kind][4]
  if skill then text=skill..": "..text end
  if incoming then text="< "..text else text="> "..text end
  Queue(text,nil,kind,incoming,skill);return
 end
end
-- Names verified in the installed executable; no modern combat-log dependency.
local events={"CHAT_MSG_SPELL_SELF_DAMAGE","CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
 "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE","CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE","CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
 "CHAT_MSG_COMBAT_SELF_MISSES","CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES"}
for i=1,table.getn(events) do f:RegisterEvent(events[i]) end
f:SetScript("OnEvent",function() Capture(arg1,event) end)
local healing,phase,lastRun,healStamp,healZone={},nil,nil,nil,nil
-- Baseline cumulative native healing; emit only observed positive deltas and reset between runs.
local function Healing()
 local ph=type(AZS_GetPhase)=="function" and AZS_GetPhase() or nil
 local rt=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t)
 local zone=type(AZS_ZONE)=="table" and AZS_ZONE.zone
 local reset=zone~=healZone or not ph or (ph=="ready" and phase~="ready") or (rt and lastRun and rt<lastRun-1)
 if reset then
  if healZone~=nil then C.Clear() end
  healing={};healStamp=nil
 end
 healZone=zone;phase=ph;lastRun=rt
 if type(AZS_HEALING)~="table" or not ph then return end
 if healStamp==AZS_HEALING_UPDATED and healStamp~=nil then return end
 healStamp=AZS_HEALING_UPDATED
 local current={}
 for i=1,math.min(128,table.getn(AZS_HEALING)) do
  local row=AZS_HEALING[i];local name=row.name or row[1];local total=FieldKit.Number(row.dmg or row[2])
  if type(name)=="string" and total then current[name]=(current[name] or 0)+total end
 end
 for name,total in pairs(current) do
  if healing[name] and total>healing[name] then Queue("Heal: "..name,total-healing[name],"heal",true) end
 end
 healing=current
end
-- Clear pending groups and hide the fixed slot pool.
function C.Clear()
 pending={};for i=1,10 do slots[i].active=false;slots[i].fs:Hide() end
end
-- Reset the world combat-text cursor after a stream change or explicit clear-all.
function C.ResetWorldCursor()
 worldCursor=nil
end
-- Change filters/grouping/limits while preserving user fonts, colors and positions.
function C.Preset(name)
 if not C.Ensure() then return end
 FieldKitDB.combatText=true;FieldKitDB.combatTextGroup=true
 FieldKitDB.combatTextIncoming=true;FieldKitDB.combatTextOutgoing=true;FieldKitDB.combatTextHealing=name~="quiet"
 FieldKitDB.combatTextMax=name=="quiet" and 3 or 5;FieldKitDB.combatTextHealMin=name=="all" and 0 or 5
 FieldKitDB.combatTextMin=name=="quiet" and 25 or 0
 for i=1,table.getn(C.defs) do
  local kind=C.defs[i][1];C.Event(kind).enabled=name=="all" or i<=7 or kind=="dodge" or kind=="parry"
 end
 C.Clear()
end
-- Persistent independent combat-text presets. Active settings remain in the legacy
-- flat DB so every existing renderer and editor continues to work unchanged.
local function CopyTable(value)
 if type(value)~="table" then return value end
 local result={};for k,v in pairs(value) do result[k]=CopyTable(v) end;return result
end
local function CaptureProfile()
 local result={}
 for key in pairs(C.defaults) do result[key]=CopyTable(FieldKitDB[key]) end
 result.combatEvents=CopyTable(FieldKitDB.combatEvents)
 return result
end
local function ApplyProfile(profile)
 if type(profile)~="table" then return end
 for key in pairs(C.defaults) do if profile[key]~=nil then FieldKitDB[key]=CopyTable(profile[key]) end end
 FieldKitDB.combatEvents=CopyTable(profile.combatEvents or {})
 C.owner=nil;C.Ensure();C.Clear()
end
local function ValidProfile(name)
 return name=="balanced" or name=="quiet" or name=="all"
end
local function DefaultProfile(name,base)
 local old=CaptureProfile()
 ApplyProfile(base)
 if name~="balanced" then C.Preset(name) end
 local result=CaptureProfile()
 ApplyProfile(old)
 return result
end
function C.ActiveProfile()
 local name=FieldKitDB and FieldKitDB.combatProfileActive
 if ValidProfile(name) then return name end
 return "balanced"
end
function C.InitProfiles()
 if not C.Ensure() then return end
 local existing=FieldKitDB.combatProfiles
 if type(existing)~="table" then existing={} end
 local original=CaptureProfile()
 -- Migration: keep the player's current flat settings as Balanced.
 if type(existing.balanced)~="table" then existing.balanced=CopyTable(original) end
 if type(existing.quiet)~="table" then existing.quiet=DefaultProfile("quiet",original) end
 if type(existing.all)~="table" then existing.all=DefaultProfile("all",original) end
 -- Repair only missing or invalid fields; retain every valid customized value.
 for _,name in ipairs({"balanced","quiet","all"}) do
  local profile=existing[name]
  for key,value in pairs(C.defaults) do
   if type(profile[key])~=type(value) then profile[key]=CopyTable(value) end
  end
  if type(profile.combatEvents)~="table" then profile.combatEvents={} end
  for i=1,table.getn(C.defs) do
   local kind=C.defs[i][1]
   if type(profile.combatEvents[kind])~="table" then profile.combatEvents[kind]={enabled=true} end
  end
 end
 FieldKitDB.combatProfiles=existing
 if not ValidProfile(FieldKitDB.combatProfileActive) then FieldKitDB.combatProfileActive="balanced" end
end
function C.SelectProfile(name)
 if not ValidProfile(name) or not C.Ensure() then return end
 C.InitProfiles()
 local current=C.ActiveProfile()
 FieldKitDB.combatProfiles[current]=CaptureProfile()
 if name~=current then
  ApplyProfile(FieldKitDB.combatProfiles[name])
  FieldKitDB.combatProfileActive=name
 end
end
function C.SaveActiveProfile()
 if not C.Ensure() then return end
 C.InitProfiles()
 FieldKitDB.combatProfiles[C.ActiveProfile()]=CaptureProfile()
end
function C.ResetActiveProfile()
 if not C.Ensure() then return end
 C.InitProfiles()
 local name=C.ActiveProfile()
 -- Restore factory values for this profile only. Other profiles stay untouched.
 local old=CaptureProfile()
 local base={}
 for key,value in pairs(C.defaults) do base[key]=CopyTable(value) end
 base.combatEvents={}
 ApplyProfile(base)
 local fresh=CaptureProfile()
 ApplyProfile(old)
 local replacement=DefaultProfile(name,fresh)
 FieldKitDB.combatProfiles[name]=CopyTable(replacement)
 ApplyProfile(replacement)
end
-- Persist the active profile on logout even if the editor was never reopened.
local profileSaver=CreateFrame("Frame")
profileSaver:RegisterEvent("PLAYER_LOGOUT")
profileSaver:SetScript("OnEvent",function()
 if FieldKitDB and type(FieldKitDB.combatProfiles)=="table" then C.SaveActiveProfile() end
end)
-- C5: route synthetic on-screen samples through the SAME renderer as live text.
-- Samples bypass combat ingestion, persistence, and statistics. They are
-- explicitly marked preview and are never submitted to the grouping queue.
function C.PreviewEmit(kind,amount,label)
 if not C.Ensure() then return end
 local def=C.byKind[kind]
 if not def then return end
 local event=C.Event(kind)
 if not event or not event.enabled then return end
 if kind=="heal" and not FieldKitDB.combatTextHealing then return end
 local incoming=kind=="incoming" or kind=="incomingCrit" or kind=="incomingPeriodic"
 if incoming and not FieldKitDB.combatTextIncoming then return end
 if not incoming and kind~="heal" and not FieldKitDB.combatTextOutgoing then return end
 Emit({label=label or def[4] or def[2],amount=amount,kind=kind,
       incoming=incoming,count=1,preview=true})
end
-- Create clearly marked, non-recorded sample messages for the editor.
function C.Preview(kind)
 if not C.Ensure() then return end
 C.Clear()
 local kinds=kind and {kind} or {"out","crit","incoming","heal"}
 for i=1,table.getn(kinds) do
  local k=kinds[i];local incoming=k=="incoming" or k=="heal" or k=="incomingCrit"
  Emit({label=FieldKit_L("[Preview]").." "..FieldKit_L(C.byKind[k][4] or C.byKind[k][2]),amount=i<=4 and not C.byKind[k][4] and 123 or nil,kind=k,incoming=incoming,count=1,preview=true,previewKind=k})
 end
end
local anchors={}
-- Hide both drag handles on settings close.
function C.HideAnchors()
 for i=1,table.getn(anchors) do
  local a=anchors[i]
  if a.fieldkitMoving then
   local previous=this;this=a;a:GetScript("OnDragStop")();this=previous
  end
  a:Hide()
 end
end
-- Create at most two handles; explicit dragging persists center-relative area offsets.
function C.ShowAnchors()
 if not C.Ensure() then return end
 if not anchors[1] then
  for i=1,2 do
   local a=CreateFrame("Frame","FieldKitCombatAnchor"..i,UIParent);a:SetWidth(280);a:SetHeight(32);a:SetFrameStrata("DIALOG")
   a:SetMovable(true);a:EnableMouse(true);a:RegisterForDrag("LeftButton");a.index=i
   local bg=a:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(a);bg:SetTexture(0,0,0,.7)
   local text=a:CreateFontString(nil,"OVERLAY","GameFontNormal");text:SetPoint("CENTER",a,"CENTER",0,0)
   FieldKit_Text(text,i==1 and "Dégâts infligés : déplacer" or "Dégâts reçus / soins : déplacer")
   a:SetScript("OnDragStart",function() this.fieldkitMoving=true;this:StartMoving() end)
   a:SetScript("OnDragStop",function()
    this.fieldkitMoving=nil
    this:StopMovingOrSizing();local x,y=this:GetCenter();local ux,uy=UIParent:GetCenter()
    if x and y and ux and uy then
     local prefix=this.index==1 and "combatText" or "combatTextIncoming"
     FieldKitDB[prefix.."X"]=math.floor(x-ux+.5);FieldKitDB[prefix.."Y"]=math.floor(y-uy+.5)
    end
   end)
   anchors[i]=a
  end
 end
 for i=1,2 do
  local prefix=i==1 and "combatText" or "combatTextIncoming"
  anchors[i]:ClearAllPoints();anchors[i]:SetPoint("CENTER",UIParent,"CENTER",C.Number(prefix.."X",i==1 and 180 or -180,-2000,2000),C.Number(prefix.."Y",-45,-2000,2000))
  if i==1 or FieldKitDB.combatTextSplit then anchors[i]:Show() else anchors[i]:Hide() end
 end
end
local elapsed=0
f:SetScript("OnUpdate",function()
 if not C.Ensure() then return end
 local now=GetTime();elapsed=elapsed+(arg1 or 0)
 if elapsed>=.05 then
  elapsed=0
  if FieldKitDB.combatText then
   if FieldKitDB.combatTextWorld then
    EnsureWorldHandler()
    if not worldHandler then PollWorldCombat() end
   end
   Healing()
  else pending={} end
  local queued=false;for _ in pairs(pending) do queued=true;break end
  if FieldKitDB.combatText and queued then
   local due={};for key,v in pairs(pending) do if now-v.start>=C.Number("combatTextWindow",25,5,75)/100 then table.insert(due,key) end end
   table.sort(due,function(a,b) if pending[a].start==pending[b].start then return a<b end;return pending[a].start<pending[b].start end)
   for i=1,table.getn(due) do Emit(pending[due[i]]);pending[due[i]]=nil end
  end
 end
 local live=false
 for i=1,10 do if slots[i] and slots[i].active then live=true;break end end
 if not live then return end
 local lifetime=C.Number("combatTextDuration",18,6,50)/10;local visible={}
 for i=1,10 do
  local s=slots[i]
  if s.active then
   if now-s.start>=lifetime or i>C.Number("combatTextMax",5,1,10) or (not s.value.preview and not Allowed(s.value)) then s.active=false;s.fs:Hide()
   else table.insert(visible,s) end
  end
 end
 table.sort(visible,function(a,b) return a.serial>b.serial end)
 local previous={out=-1000,incoming=-1000};local previousSize={out=0,incoming=0}
 for i=1,table.getn(visible) do
  local s=visible[i];local v=s.value
  if type(v.anchor)=="string" and FieldKitDB.combatTextWorld and worldHandler then
   local size=C.Number(v.kind=="crit" and "combatTextCritSize" or "combatTextFontSize",v.kind=="crit" and 20 or 16,10,40)
   StyleSlot(s,v,size,now,lifetime)
  else
   local critical=v.kind=="crit" or v.kind=="incomingCrit"
   local size=critical and C.Number("combatTextCritSize",20,10,40) or C.Number("combatTextFontSize",16,10,32)
   local area=v.incoming and FieldKitDB.combatTextSplit and "incoming" or "out"
   local spacing=math.max(C.Number("combatTextSpacing",27,18,60),(size+previousSize[area])/2+6)
   s.y=math.max((now-s.start)*18,previous[area]+spacing);previous[area]=s.y;previousSize[area]=size
   StyleSlot(s,v,size,now,lifetime)
   local prefix=area=="incoming" and "combatTextIncoming" or "combatText"
   local sign=FieldKitDB.combatTextDirection==2 and -1 or 1
   s.fs:ClearAllPoints();s.fs:SetPoint("CENTER",UIParent,"CENTER",C.Number(prefix.."X",area=="incoming" and -180 or 180,-2000,2000),C.Number(prefix.."Y",-45,-2000,2000)+sign*s.y)
   s.fs:Show()
  end
 end
 if FieldKitDB.combatTextWorld and not worldHandler then ProjectWorldSlots() end
end)
SLASH_FieldKitCOMBAT1="/fieldkitcombat"
SlashCmdList["FieldKitCOMBAT"]=function() if SlashCmdList.FieldKit then SlashCmdList.FieldKit("combat") end end


