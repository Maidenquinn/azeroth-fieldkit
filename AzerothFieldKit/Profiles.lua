-- v0.5.0: opt-in, bounded HUD layout profile slots.
-- Only allowlisted UI preferences are captured; chat, game statistics,
-- native CVars, account data and network settings are excluded.
-- Apply is staged in SavedVariables: /reload makes native frame changes safe.
FieldKitProfiles={}
local P=FieldKitProfiles
local scalar={
 "windowsLocked","linkLeftCards","linkRightCards","cardOpacity","cardStyle",
 "runModeCard","statsFrame","gearFrame","meterFrame","takenFrame","lairFrame",
 "moneyFrame","effectsFrame","reviveFrame","nextBossCard","bossTimeline",
 "compactBar","playerBar","playerBuffs","bossFrame","meterTabs",
 "nativeWarnings","replaceTally","partyCards","partyMeter"
}
local tables={"frameAnchors","pos","collapsedWindows","cardSizes"}
local function Slot(value)
 local n=tonumber(value)
 if not n or n~=math.floor(n) or n<1 or n>3 then return nil end
 return n
end
local function Clone(source,depth,limit)
 if type(source)~="table" or depth>3 then return nil end
 local out={};local count=0
 for key,value in pairs(source) do
  if count>=limit then break end
  if (type(key)=="string" and string.len(key)<=128) or
    (type(key)=="number" and key==math.floor(key) and key>=1 and key<=8) then
   if type(value)=="number" and FieldKit.Number(value) then
    out[key]=value;count=count+1
   elseif type(value)=="boolean" or (type(value)=="string" and string.len(value)<=100) then
    out[key]=value;count=count+1
   elseif type(value)=="table" and depth<3 then
    local nested=Clone(value,depth+1,8)
    if nested then out[key]=nested;count=count+1 end
   end
  end
 end
 return out
end
local function Capture()
 local d=FieldKitDB
 if type(d)~="table" then return nil end
 local snap={values={},tables={}}
 for i=1,table.getn(scalar) do
  local k=scalar[i];local v=d[k]
  if type(v)=="boolean" or (type(v)=="number" and FieldKit.Number(v)) then
   snap.values[k]=v
  end
 end
 for i=1,table.getn(tables) do
  local k=tables[i]
  snap.tables[k]=Clone(d[k] or {},1,160) or {}
 end
 return snap
end
local function Say(message)
 if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99FieldKit|r: "..message)
 end
end
function P.Init()
 if type(FieldKitDB)~="table" then return end
 local store=FieldKitDB.interfaceProfiles
 if type(store)~="table" then FieldKitDB.interfaceProfiles={} return end
 for key,value in pairs(store) do
  local n=Slot(key)
  if not n or type(value)~="table" or type(value.values)~="table" or
    type(value.tables)~="table" then store[key]=nil end
 end
end
function P.Save(number)
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 FieldKitDB.interfaceProfiles[slot]=Capture()
 return true
end
function P.Load(number)
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 local saved=FieldKitDB.interfaceProfiles[slot]
 if not saved then return false end
 -- Make an independent undo snapshot for the current session.
 P.undo=Capture()
 for i=1,table.getn(scalar) do
  local key=scalar[i];local value=saved.values[key]
  if type(value)=="boolean" or (type(value)=="number" and FieldKit.Number(value)) then
   FieldKitDB[key]=value
  end
 end
 for i=1,table.getn(tables) do
  local key=tables[i]
  FieldKitDB[key]=Clone(saved.tables[key] or {},1,160) or {}
 end
 -- Revalidate all restored shapes against existing Config.lua constraints.
 -- Do not refresh live native frames: /reload safely applies them.
 FieldKit.InitializeSettings({})
 return true
end
function P.Undo()
 if not P.undo or not FieldKitDB then return false end
 local saved=P.undo;P.undo=nil
 for i=1,table.getn(scalar) do
  local key=scalar[i];local value=saved.values[key]
  if type(value)=="boolean" or (type(value)=="number" and FieldKit.Number(value)) then
   FieldKitDB[key]=value
  end
 end
 for i=1,table.getn(tables) do
  local key=tables[i];FieldKitDB[key]=Clone(saved.tables[key] or {},1,160) or {}
 end
 FieldKit.InitializeSettings({})
 return true
end
function P.Delete(number)
 local slot=Slot(number)
 if not slot or not FieldKitDB then return false end
 P.Init()
 if not FieldKitDB.interfaceProfiles[slot] then return false end
 FieldKitDB.interfaceProfiles[slot]=nil;return true
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
  Say("HUD profile slots: "..table.concat(labels,", ")..
   ". Usage: /fieldkit profile save|load|delete 1-3, undo")
  return
 end
 if message=="undo" then
  if P.Undo() then Say("Previous HUD settings restored. Use /reload to apply.")
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
 if op=="save" and P.Save(number) then Say("HUD profile "..number.." saved (chat and game data excluded).")
 elseif op=="load" and P.Load(number) then Say("HUD profile "..number.." loaded. Use /reload to apply. /fieldkit profile undo before reloading to revert.")
 elseif op=="delete" and P.Delete(number) then Say("HUD profile "..number.." deleted.")
 else Say("Slot "..number.." is empty.") end
end
