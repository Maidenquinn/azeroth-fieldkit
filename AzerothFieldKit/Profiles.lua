-- v0.5.0-alpha.5: separate EVERY declared FieldKit display preference by
-- HUD profile, without duplicating messages, run telemetry or UI-navigation
-- state. Flat FieldKitDB stays the live renderer contract.
FieldKitProfiles={}
local P=FieldKitProfiles
local extra={
 "language","cardStyle","cardOpacity","meterView","meterValues",
 "bossWarningLead","bossStyle","minimapAngle","playerBarX","playerBarY",
 "cameraMax","hideDamage","showCrits","groupCrits","hideGryphons",
 "moneyDetached","meterSortKey","meterSortAsc","meterHealDone",
 "meterPartyOwner","meterKeepTakenFrame","meterSpellTips",
 "meterDetach_damage","meterDetach_healing","meterDetach_boss",
 "meterDetach_taken","meterDetach_party","meterDetach_kills",
 "meterViewKey","loadoutTab","statsCollapsed","gearCollapsed",
 "combatProfileActive",
 "combatText","combatTextFontSize","combatTextCritSize",
 "combatTextFont","combatTextCritFont","combatTextOutline",
 "combatTextOpacity","combatTextMax","combatTextSpacing",
 "combatTextDuration","combatTextWindow","combatTextMin",
 "combatTextHealMin","combatTextX","combatTextY",
 "combatTextIncomingX","combatTextIncomingY","combatTextSplit",
 "combatTextNames","combatTextCounts","combatTextDirection",
 "combatTextIgnore","combatTextWorld",
 "combatTextGroup","combatTextHealing","combatTextOutgoing",
 "combatTextIncoming"
}
local tableKeys={
 "frameAnchors","pos","collapsedWindows","cardSizes","onTopWindows",
 "shownStats","meterHiddenRows","combatEvents","combatProfiles",
 "worldMarkerSettings","chatAnchor"
}
local keys,seen={},{}
local function Include(key)
 if type(key)~="string" or seen[key] then return end
 seen[key]=true;table.insert(keys,key)
end
for key in pairs(FieldKit.ProfilePreferenceDefaults or {}) do Include(key) end
for i=1,table.getn(extra) do Include(extra[i]) end
-- Optional combat defaults are present when the game finishes loading; keep
-- this read-time check in case later builds add new combat preferences.
local function PreferenceKeys()
 if FieldKitCombat and type(FieldKitCombat.defaults)=="table" then
  for key in pairs(FieldKitCombat.defaults) do Include(key) end
 end
 return keys
end
local function Slot(value)
 local n=tonumber(value)
 return n and n==math.floor(n) and n>=1 and n<=3 and n or nil
end
local function Clone(value,depth,budget)
 local kind=type(value)
 if kind=="number" then
  local n=FieldKit.Number(value)
  if n==nil then budget.invalid=true end
  return n
 end
 if kind=="string" then
  if string.len(value)>512 then budget.invalid=true;return nil end
  return value
 end
 if kind=="boolean" then return value end
 if kind~="table" or depth>7 or budget.left<=0 then
  budget.invalid=true
  return nil
 end
 local copy={}
 for key,item in pairs(value) do
  if budget.left<=0 then budget.invalid=true;break end
  local kt=type(key)
  if (kt=="string" and string.len(key)<=160) or
     (kt=="number" and key==math.floor(key) and key>=1 and key<=256) then
   budget.left=budget.left-1
   local result=Clone(item,depth+1,budget)
   if result~=nil then copy[key]=result end
  else
   budget.invalid=true
  end
 end
 return copy
end
local function Copy(value)
 local budget={left=3200,invalid=false}
 local result=Clone(value,1,budget)
 if budget.invalid then return nil end
 return result
end
local function Capture()
 local d=FieldKitDB
 if type(d)~="table" then return nil end
 local snap={values={},nilValues={},tables={},schema=2}
 local list=PreferenceKeys()
 for i=1,table.getn(list) do
  local key=list[i];local value=d[key]
  if type(value)=="boolean" or type(value)=="number" or type(value)=="string" then
   local copy=Copy(value)
   if copy==nil then return nil end
   snap.values[key]=copy
  elseif value==nil then snap.nilValues[key]=true
  else return nil end
 end
 for i=1,table.getn(tableKeys) do
  local key=tableKeys[i]
  if d[key]~=nil and type(d[key])~="table" then return nil end
  local copied=Copy(d[key] or {})
  if copied==nil then return nil end
  snap.tables[key]=copied
 end
 return snap
end
-- User-defined names belong to the slot metadata, never to the live
-- settings snapshot. Reject invalid UTF-8-unaware byte/control input rather
-- than truncate a multibyte name in the middle of a glyph.
local function CleanName(name)
 if type(name)~="string" then return nil end
 name=string.gsub(name,"^%s+","")
 name=string.gsub(name,"%s+$","")
 if string.len(name)<1 or string.len(name)>40 then return nil end
 if string.find(name,"[%c]") or string.find(name,"|",1,true) then return nil end
 return name
end
function P.Name(number)
 local slot=Slot(number)
 local saved=slot and FieldKitDB and FieldKitDB.interfaceProfiles and
  FieldKitDB.interfaceProfiles[slot]
 return saved and CleanName(saved.name) or nil
end
function P.Rename(number,name)
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 local saved=FieldKitDB.interfaceProfiles[slot]
 local clean=CleanName(name)
 if not saved or not clean then return false end
 saved.name=clean
 return true
end
local function Say(message)
 if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99FieldKit|r: "..message)
 end
end
local function Valid(snapshot)
 return type(snapshot)=="table" and type(snapshot.values)=="table"
  and type(snapshot.tables)=="table"
end
local function Upgrade(snapshot,baseline)
 -- Alpha.1 through alpha.4 saved only 25 keys and four tables. Hydrate
 -- missing preferences from the unchanged live settings, never from a new
 -- hardcoded preset, and preserve each slot's old layout.
 if not Valid(snapshot) then return end
 if type(snapshot.nilValues)~="table" then snapshot.nilValues={} end
 local list=PreferenceKeys()
 for i=1,table.getn(list) do
  local key=list[i]
  if snapshot.values[key]==nil and not snapshot.nilValues[key] then
   snapshot.values[key]=Copy(baseline.values[key])
   if snapshot.values[key]==nil then snapshot.nilValues[key]=true end
  end
 end
 for i=1,table.getn(tableKeys) do
  local key=tableKeys[i]
  if type(snapshot.tables[key])~="table" then
   snapshot.tables[key]=Copy(baseline.tables[key]) or {}
  end
 end
 snapshot.schema=2
end
function P.Init()
 if type(FieldKitDB)~="table" then return end
 local store=FieldKitDB.interfaceProfiles
 if type(store)~="table" then FieldKitDB.interfaceProfiles={} return end
 -- Most calls operate on already migrated slots. Avoid repeatedly
 -- cloning the entire live configuration for these hot-path checks.
 local baseline
 for key,value in pairs(store) do
  local slot=Slot(key)
  if not slot or type(key)~="number" or not Valid(value) then
   store[key]=nil
  elseif value.schema~=2 or type(value.nilValues)~="table" then
   if not baseline then baseline=Capture() end
   if baseline then Upgrade(value,baseline) end
  end
 end
end
local function ApplySnapshot(snapshot)
 if not Valid(snapshot) then return false end
 local d=FieldKitDB;local list=PreferenceKeys()
 -- Stage and validate every copy before mutating the live database.
 -- An oversized/corrupted saved slot must never partially overwrite it.
 local stagedValues,stagedTables={},{}
 for i=1,table.getn(list) do
  local key=list[i]
  local value=snapshot.values[key]
  if value~=nil then
   local copy=Copy(value)
   if copy==nil then return false end
   stagedValues[key]=copy
  elseif not (snapshot.nilValues and snapshot.nilValues[key]) then
   return false
  end
 end
 for i=1,table.getn(tableKeys) do
  local key=tableKeys[i]
  if type(snapshot.tables[key])~="table" then return false end
  local copy=Copy(snapshot.tables[key])
  if copy==nil then return false end
  stagedTables[key]=copy
 end
 for i=1,table.getn(list) do
  local key=list[i]
  d[key]=stagedValues[key]
 end
 for i=1,table.getn(tableKeys) do
  local key=tableKeys[i]
  d[key]=stagedTables[key]
 end
 FieldKit.InitializeSettings({})
 if FieldKitCombat then FieldKitCombat.owner=nil;FieldKitCombat.Ensure() end
 return true
end
-- A preview changes only the live renderer temporarily. It never writes a
-- profile slot, active profile ID, or undo history until explicitly accepted.
function P.Preview(number)
 local slot=Slot(number)
 if not slot or not FieldKitDB or FieldKit.layoutEditing or
  type(FieldKit.ApplyHUDProfileLive)~="function" then return false end
 if P.preview then return false end
 P.Init()
 local saved=FieldKitDB.interfaceProfiles[slot]
 if not saved then return false end
 local before=Capture()
 if not before then return false end
 local ok=pcall(function()
  assert(ApplySnapshot(saved))
  assert(FieldKit.ApplyHUDProfileLive())
 end)
 if not ok then
  local restoredOK,restored=pcall(ApplySnapshot,before)
  if restoredOK and restored then pcall(FieldKit.ApplyHUDProfileLive) end
  return false
 end
 P.preview={before=before,slot=slot,active=FieldKitDB.activeHudProfile}
 return true
end
function P.CancelPreview()
 if not P.preview then return false end
 local state=P.preview
 local ok=pcall(function()
  assert(ApplySnapshot(state.before))
  assert(FieldKit.ApplyHUDProfileLive())
 end)
 if not ok then return false end
 P.preview=nil
 return true
end
function P.AcceptPreview()
 local state=P.preview
 if not state or not FieldKitDB then return false end
 -- Restore the original live settings first, then use the normal guarded
 -- switch, which preserves outgoing unsaved edits and undo semantics.
 if not P.CancelPreview() then return false end
 return P.Load(state.slot)
end
function P.SaveActive()
 if P.preview then return false end
 if not FieldKitDB then return false end
 local active=Slot(FieldKitDB.activeHudProfile)
 if not active then return false end
 P.Init()
 if not FieldKitDB.interfaceProfiles[active] then return false end
 local old=FieldKitDB.interfaceProfiles[active]
 local updated=Capture()
 if not updated then return false end
 updated.name=old.name
 FieldKitDB.interfaceProfiles[active]=updated
 return true
end
function P.Save(number)
 if P.preview then return false end
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 -- Save-as creates/updates the selected slot and makes it the active
 -- editing context. Do NOT overwrite the previous slot's stored snapshot.
 local old=FieldKitDB.interfaceProfiles[slot]
 local updated=Capture()
 if not updated then return false end
 updated.name=old and old.name or nil
 FieldKitDB.interfaceProfiles[slot]=updated
 FieldKitDB.activeHudProfile=slot
 return true
end
function P.Load(number)
 if P.preview then return false end
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 if not FieldKitDB.interfaceProfiles[slot] or
  type(FieldKit.ApplyHUDProfileLive)~="function" or FieldKit.layoutEditing then return false end
 local sameSlot=FieldKitDB.activeHudProfile==slot
 local before=Capture()
 if not before then return false end
 local previous=FieldKitDB.activeHudProfile
 -- Preserve all edits in the outgoing slot, even when the player never
 -- pressed the explicit Save current HUD button.
 -- Never proceed if autosave fails: otherwise the outgoing edits can be lost.
 if not sameSlot and Slot(previous) and not P.SaveActive() then return false end
 local ok=pcall(function()
  assert(ApplySnapshot(FieldKitDB.interfaceProfiles[slot]))
  assert(FieldKit.ApplyHUDProfileLive())
 end)
 if not ok then
  -- Restore both live preferences and profile metadata on a failed switch.
  -- The outgoing slot may have been autosaved before the failed apply.
  local rollbackOK,restored=pcall(ApplySnapshot,before)
  if rollbackOK and restored then pcall(FieldKit.ApplyHUDProfileLive) end
  FieldKitDB.activeHudProfile=previous
  return false
 end
 P.undo=before;P.undoProfile=previous
 FieldKitDB.activeHudProfile=slot
 FieldKitDB.profilePendingSlot=nil
 return true
end
function P.Undo()
 if P.preview then return false end
 if not FieldKitDB then return false end
 if P.undo then
  local before=P.undo
  local current=Capture()
  if not current then return false end
  local oldActive=FieldKitDB.activeHudProfile
  if Slot(oldActive) and not P.SaveActive() then return false end
  local ok=pcall(function()
   assert(ApplySnapshot(before));assert(FieldKit.ApplyHUDProfileLive())
  end)
  if not ok then
   local rollbackOK,restored=pcall(ApplySnapshot,current)
   if rollbackOK and restored then pcall(FieldKit.ApplyHUDProfileLive) end
   FieldKitDB.activeHudProfile=oldActive
   return false
  end
  FieldKitDB.activeHudProfile=P.undoProfile
  P.undo=nil;P.undoProfile=nil
  return true
 end
 if FieldKitDB.profilePendingSlot then
  FieldKitDB.profilePendingSlot=nil;return true
 end
 return false
end
function P.ActivatePending()
 if P.preview then return false end
 if not FieldKitDB then return false end
 P.Init()
 local slot=Slot(FieldKitDB.profilePendingSlot)
 FieldKitDB.profilePendingSlot=nil
 if not slot then return false end
 local saved=FieldKitDB.interfaceProfiles[slot]
 if not saved then return false end
 local before=Capture()
 if not before then return false end
 local ok,applied=pcall(ApplySnapshot,saved)
 if not ok or not applied then
  pcall(ApplySnapshot,before)
  return false
 end
 FieldKitDB.activeHudProfile=slot
 return true
end
function P.Delete(number)
 if P.preview then return false end
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 if not FieldKitDB.interfaceProfiles[slot] then return false end
 FieldKitDB.interfaceProfiles[slot]=nil
 if FieldKitDB.profilePendingSlot==slot then FieldKitDB.profilePendingSlot=nil end
 if FieldKitDB.activeHudProfile==slot then FieldKitDB.activeHudProfile=nil end
 return true
end
function P.Command(message)
 if not FieldKitDB then return end
 message=message or ""
 local lower=string.lower(message)
 P.Init()
 if lower=="list" or lower=="" then
  local labels={}
  for i=1,3 do
   table.insert(labels,tostring(i)..":"..
    (FieldKitDB.interfaceProfiles[i] and "saved" or "empty"))
  end
  Say("Profile slots: "..table.concat(labels,", ")..
   ". Usage: /fieldkit profile save|load|delete 1-3, undo")
  return
 end
 if string.sub(lower,1,5)=="name " then
  local rest=string.sub(message,6)
  local n=Slot(string.sub(rest,1,1))
  local tail=string.sub(rest,3)
  if string.sub(rest,2,2)~=" " then n=nil end
  if n and P.Rename(n,tail) then Say("Profile "..n.." renamed.")
  else Say("Usage: /fieldkit profile name 1-3 short name (max 40 bytes).") end
  return
 end
 if lower=="undo" then
  if P.Undo() then Say("Previous profile restored immediately.")
  else Say("No profile change to undo.") end
  return
 end
 local op,number
 for _,word in ipairs({"save","load","delete"}) do
  local prefix=word.." "
  if string.sub(lower,1,string.len(prefix))==prefix then
   op=word;number=Slot(string.sub(message,string.len(prefix)+1))
  end
 end
 if not op or not number then Say("Usage: /fieldkit profile save|load|delete 1-3, list, undo");return end
 if op=="save" and P.Save(number) then Say("Profile "..number.." saved (settings only, not chat history or run data).")
 elseif op=="load" and P.Load(number) then Say("Profile "..number.." applied. Use /fieldkit profile undo to revert.")
 elseif op=="delete" and P.Delete(number) then Say("Profile "..number.." deleted.")
 else Say("Slot "..number.." is empty, or live switching is currently blocked.") end
end
