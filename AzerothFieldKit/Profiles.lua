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
 "combatProfileActive","moneyDockRepair",
 "combatText","combatTextFontSize","combatTextCritSize",
 "combatTextFont","combatTextCritFont","combatTextOutline",
 "combatTextOpacity","combatTextMax","combatTextSpacing",
 "combatTextDuration","combatTextWindow","combatTextMin",
 "combatTextHealMin","combatTextX","combatTextY",
 "combatTextIncomingX","combatTextIncomingY","combatTextSplit",
 "combatTextNames","combatTextCounts","combatTextDirection",
 "combatTextIgnore","combatTextWorld",
 "combatTextGroup","combatTextHealing","combatTextOutgoing",
 "combatTextIncoming","hideGryphons","moneyDetached",
 "combatTextCounts","combatTextCritFont","combatTextHealing",
 "combatTextFont","combatTextOutgoing","combatTextIncoming"
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
 if kind=="number" then return FieldKit.Number(value) end
 if kind=="string" then return string.len(value)<=512 and value or nil end
 if kind=="boolean" then return value end
 if kind~="table" or depth>7 or budget.left<=0 then return nil end
 local copy={}
 for key,item in pairs(value) do
  if budget.left<=0 then break end
  local kt=type(key)
  if (kt=="string" and string.len(key)<=160) or
     (kt=="number" and key==math.floor(key) and key>=1 and key<=256) then
   budget.left=budget.left-1
   local result=Clone(item,depth+1,budget)
   if result~=nil then copy[key]=result end
  end
 end
 return copy
end
local function Copy(value)
 return Clone(value,1,{left=3200})
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
   if copy~=nil then snap.values[key]=copy
   else snap.nilValues[key]=true end
  else snap.nilValues[key]=true end
 end
 for i=1,table.getn(tableKeys) do
  local key=tableKeys[i];snap.tables[key]=Copy(d[key] or {}) or {}
 end
 return snap
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
 local baseline=Capture()
 for key,value in pairs(store) do
  local slot=Slot(key)
  if not slot or type(key)~="number" or not Valid(value) then
   store[key]=nil
  else Upgrade(value,baseline) end
 end
end
local function ApplySnapshot(snapshot)
 if not Valid(snapshot) then return false end
 local d=FieldKitDB;local list=PreferenceKeys()
 for i=1,table.getn(list) do
  local key=list[i]
  -- Explicit tombstones prevent nil/optional values leaking from the
  -- previous slot. A legacy snapshot is hydrated by Init beforehand.
  local value=snapshot.values[key]
  if value~=nil then d[key]=Copy(value)
  elseif snapshot.nilValues and snapshot.nilValues[key] then d[key]=nil end
 end
 for i=1,table.getn(tableKeys) do
  local key=tableKeys[i]
  d[key]=Copy(snapshot.tables[key] or {}) or {}
 end
 FieldKit.InitializeSettings({})
 if FieldKitCombat then FieldKitCombat.owner=nil;FieldKitCombat.Ensure() end
 return true
end
function P.SaveActive()
 if not FieldKitDB then return false end
 local active=Slot(FieldKitDB.activeHudProfile)
 if not active then return false end
 P.Init()
 if not FieldKitDB.interfaceProfiles[active] then return false end
 FieldKitDB.interfaceProfiles[active]=Capture()
 return true
end
function P.Save(number)
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 -- Save-as creates/updates the selected slot and makes it the active
 -- editing context. Do NOT overwrite the previous slot's stored snapshot.
 FieldKitDB.interfaceProfiles[slot]=Capture()
 FieldKitDB.activeHudProfile=slot
 return true
end
function P.Load(number)
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 if not FieldKitDB.interfaceProfiles[slot] or
  type(FieldKit.ApplyHUDProfileLive)~="function" or FieldKit.layoutEditing then return false end
 local sameSlot=FieldKitDB.activeHudProfile==slot
 local before=Capture()
 local previous=FieldKitDB.activeHudProfile
 -- Preserve all edits in the outgoing slot, even when the player never
 -- pressed the explicit Save current HUD button.
 if not sameSlot then P.SaveActive() end
 local ok=pcall(function()
  assert(ApplySnapshot(FieldKitDB.interfaceProfiles[slot]))
  assert(FieldKit.ApplyHUDProfileLive())
 end)
 if not ok then
  ApplySnapshot(before);pcall(FieldKit.ApplyHUDProfileLive)
  return false
 end
 P.undo=before;P.undoProfile=previous
 FieldKitDB.activeHudProfile=slot
 FieldKitDB.profilePendingSlot=nil
 return true
end
function P.Undo()
 if not FieldKitDB then return false end
 if P.undo then
  local before=P.undo
  local current=Capture()
  local oldActive=FieldKitDB.activeHudProfile
  P.SaveActive()
  local ok=pcall(function()
   assert(ApplySnapshot(before));assert(FieldKit.ApplyHUDProfileLive())
  end)
  if not ok then
   ApplySnapshot(current);pcall(FieldKit.ApplyHUDProfileLive)
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
 if not FieldKitDB then return false end
 P.Init()
 local slot=Slot(FieldKitDB.profilePendingSlot)
 FieldKitDB.profilePendingSlot=nil
 if not slot then return false end
 local saved=FieldKitDB.interfaceProfiles[slot]
 if not saved then return false end
 if not ApplySnapshot(saved) then return false end
 FieldKitDB.activeHudProfile=slot
 return true
end
function P.Delete(number)
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
 message=string.lower(message or "")
 P.Init()
 if message=="list" or message=="" then
  local labels={}
  for i=1,3 do
   table.insert(labels,tostring(i)..":"..
    (FieldKitDB.interfaceProfiles[i] and "saved" or "empty"))
  end
  Say("Profile slots: "..table.concat(labels,", ")..
   ". Usage: /fieldkit profile save|load|delete 1-3, undo")
  return
 end
 if message=="undo" then
  if P.Undo() then Say("Previous profile restored immediately.")
  else Say("No profile change to undo.") end
  return
 end
 local op,number
 for _,word in ipairs({"save","load","delete"}) do
  local prefix=word.." "
  if string.sub(message,1,string.len(prefix))==prefix then
   op=word;number=Slot(string.sub(message,string.len(prefix)+1))
  end
 end
 if not op or not number then Say("Usage: /fieldkit profile save|load|delete 1-3, list, undo");return end
 if op=="save" and P.Save(number) then Say("Profile "..number.." saved (settings only, not chat history or run data).")
 elseif op=="load" and P.Load(number) then Say("Profile "..number.." applied. Use /fieldkit profile undo to revert.")
 elseif op=="delete" and P.Delete(number) then Say("Profile "..number.." deleted.")
 else Say("Slot "..number.." is empty, or live switching is currently blocked.") end
end
