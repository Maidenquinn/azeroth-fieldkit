-- Azeroth Survivors 0.139.2: optional, read-only world-anchor infrastructure.
-- No UI is created by this module. Consumers register their own render callbacks.
FieldKitWorldAnchors = FieldKitWorldAnchors or {}
local M = FieldKitWorldAnchors
local entries, ordered = {}, {}
local worldId, streamId, catalogId = nil, nil, nil
local retryDelay, generation = 0, 0
local enabled, registered = false, false
local consumers = {}
local query = {kinds={"elite","guardian","boss","finalBoss","cache","guardianLair","downedPartyMember"}}
local function Clear()
 entries, ordered = {}, {}
 worldId, streamId, catalogId = nil, nil, nil
 generation = generation + 1
 for _,fn in pairs(consumers) do pcall(fn, nil, "cleared") end
end
local function Capable()
 return type(AZS_GetWorldAnchorCapabilities)=="function" and type(AZS_GetWorldAnchors)=="function"
  and type(AZS_ProjectWorldAnchors)=="function" and type(AZS_RegisterWorldAnchorFrameHandler)=="function"
  and type(AZS_UnregisterWorldAnchorFrameHandler)=="function"
end
function M.Available()
 if not Capable() then return false end
 local ok,c=pcall(AZS_GetWorldAnchorCapabilities)
 return ok and type(c)=="table" and c.apiVersion==1 and c.frameHandler==true
end
function M.Snapshot() return ordered,generation end
function M.Get(id) return entries[id] end
function M.Subscribe(key,fn) if type(key)=="string" and type(fn)=="function" then consumers[key]=fn end end
function M.Unsubscribe(key) consumers[key]=nil end
-- One catalog must be collected in one invocation; no partial state is published.
function M.Refresh()
 if not enabled or not M.Available() then return false,"UNAVAILABLE" end
 local nextCursor, collected, list = nil, {}, {}
 local first, last, count = nil,nil,0
 repeat
  count=count+1
  if count>64 then return false,"PAGE_LIMIT" end
  local ok,page,err=pcall(AZS_GetWorldAnchors,query,nextCursor,256)
  if not ok or type(page)~="table" then
   local code=type(err)=="table" and err.code or "NOT_READY"
   if code=="STREAM_CHANGED" then Clear() end
   return false,code
  end
  if type(page.entries)~="table" then return false,"BAD_PAGE" end
  if not first then first=page end
  if first.catalogId~=page.catalogId or first.streamId~=page.streamId or first.worldId~=page.worldId then return false,"CATALOG_CHANGED" end
  for i=1,table.getn(page.entries) do
   local e=page.entries[i]
   if type(e)=="table" and type(e.anchorId)=="string" and not collected[e.anchorId] then
    collected[e.anchorId]=e;table.insert(list,e)
   end
  end
  last=page
  if page.hasMore and (type(page.nextCursor)~="string" or page.nextCursor==nextCursor) then return false,"BAD_CURSOR" end
  nextCursor=page.nextCursor
 until not last.hasMore
 if worldId and (worldId~=first.worldId or streamId~=first.streamId) then Clear() end
 entries,ordered=collected,list
 worldId,streamId,catalogId=first.worldId,first.streamId,first.catalogId
 generation=generation+1
 return true
end
-- Projection is only valid in the native post-camera callback.
function M.Project(requests)
 if not enabled or type(requests)~="table" or table.getn(requests)>256 then return nil,"INVALID_REQUEST" end
 if type(AZS_ProjectWorldAnchors)~="function" then return nil,"UNAVAILABLE" end
 local ok,result,err=pcall(AZS_ProjectWorldAnchors,requests)
 if not ok or type(result)~="table" then return nil,err or "NOT_READY" end
 if result.worldId~=worldId or result.streamId~=streamId then Clear();return nil,"STREAM_CHANGED" end
 if result.frameCurrent~=true then return nil,"NOT_CURRENT" end
 return result
end
local function Frame()
 if not enabled then return end
 for _,fn in pairs(consumers) do pcall(fn,ordered,"frame") end
end
function M.Enable()
 if enabled then return true end
 if not M.Available() then return false end
 enabled=true
 local ok=pcall(AZS_RegisterWorldAnchorFrameHandler,Frame)
 if not ok then enabled=false;return false end
 registered=true
 return true
end
function M.Disable()
 enabled=false
 if registered and type(AZS_UnregisterWorldAnchorFrameHandler)=="function" then pcall(AZS_UnregisterWorldAnchorFrameHandler,Frame) end
 registered=false;Clear()
end
function M.IsEnabled() return enabled end
-- Lightweight scheduler; never discover the catalog in a generic OnUpdate callback.
local ticker=CreateFrame("Frame")
ticker:SetScript("OnUpdate",function()
 if enabled then
  local dt=arg1 or 0
  retryDelay=math.max(0,retryDelay-dt)
  if retryDelay<=0 then
   local ok,err=M.Refresh()
   retryDelay=ok and 0.5 or 0.5
   if err=="STREAM_CHANGED" then retryDelay=0.1 end
  end
 end
end)

-- Chat commands compatible with WoW 1.12 (the global print() is not present).
local function Report(message)
 if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
  DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0FieldKit Anchors:|r "..tostring(message))
 end
end
SLASH_FIELDKITANCHORS1 = "/fkanchors"
SlashCmdList["FIELDKITANCHORS"] = function(msg)
 msg = string.lower(msg or "")
 if msg == "on" or msg == "enable" then
  Report(M.Enable() and "enabled" or "API unavailable")
 elseif msg == "off" or msg == "disable" then
  M.Disable(); Report("disabled")
 elseif msg == "refresh" then
  local ok,err=M.Refresh()
  Report(ok and ("catalog refreshed: "..table.getn(ordered).." anchors") or ("refresh failed: "..tostring(err)))
 else
  Report("enabled="..tostring(M.IsEnabled()).." API="..tostring(M.Available()).." anchors="..table.getn(ordered).." generation="..generation)
 end
end
