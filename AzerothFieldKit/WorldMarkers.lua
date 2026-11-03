-- FieldKit 0.139.2 visual world markers (opt-in).
FieldKitWorldMarkers = FieldKitWorldMarkers or {}
local M = FieldKitWorldMarkers
local A = FieldKitWorldAnchors
local active, icons = false, {}
local wantedEnabled=true
local pool = {}
local groundRings = {}
local groundPool = {}
local auraEnabled=true
local auraPulse=true
local auraIntensity=0.55
local reviveRingEnabled=true
local auraClock=0
local auraUpdateElapsed=0
local AURA_UPDATE_INTERVAL=0.05
local categoryRange={boss=130,finalBoss=130,elite=130,guardian=130,cache=130,guardianLair=130,downedPartyMember=130}
local auraColors={
 boss={1,0.12,0.08},finalBoss={1,0.08,0.05},elite={1,0.42,0.12},
 guardian={0.15,0.55,1},cache={1,0.74,0.12},guardianLair={1,0.52,0.16},downedPartyMember={0.20,0.85,1}
}
local auraTexture="Interface\\AddOns\\AzerothFieldKit\\media\\WorldMarkers\\aura"
local function updateAura(f)
 if not f.auraTexture then return end
 if not auraEnabled then f.auraTexture:Hide();return end
 local c=auraColors[f.markerKind] or {0.7,0.3,1}
 local pulse=auraPulse and (0.55+0.45*(0.5+0.5*math.sin(auraClock*3.4906585))) or 1
 f.auraTexture:SetVertexColor(c[1],c[2],c[3],auraIntensity*pulse)
 f.auraTexture:Show()
end
local ticker=CreateFrame("Frame")
ticker:SetScript("OnUpdate",function()
 if not active or not auraEnabled or not auraPulse then return end
 auraUpdateElapsed=auraUpdateElapsed+(arg1 or 0)
 if auraUpdateElapsed<AURA_UPDATE_INTERVAL then return end
 auraClock=auraClock+auraUpdateElapsed
 auraUpdateElapsed=0
 -- Keep the phase continuous: 2*pi / 3.4906585 is approximately 1.8s.
 if auraClock>3600 then auraClock=auraClock-math.floor(auraClock/1.8)*1.8 end
 for _,f in pairs(icons) do if f:IsShown() then updateAura(f) end end
end)
-- Recognizable in-game artwork, cropped to remove the square icon edges.
-- Lair/spawn hints are deliberately hidden unless explicitly enabled.
local base = "Interface\\AddOns\\AzerothFieldKit\\media\\WorldMarkers\\"
local styles = {
 boss={base.."boss", 32}, finalBoss={base.."finalBoss", 38},
 elite={base.."elite", 22}, guardian={base.."guardian", 27},
 cache={base.."cache", 30}, guardianLair={base.."spawn", 23},
 downedPartyMember={base.."revive", 118}
}
local showLairHints=false
local showReviveNames=true
local showReviveDistance=true
local downedList={}
local downedTimer=0
local downedSnapshotAge=0
local DOWNED_SNAPSHOT_TTL=2.5
local categoryEnabled={boss=true,finalBoss=true,elite=true,guardian=true,cache=true,guardianLair=true,downedPartyMember=true}
local categoryScale={boss=100,finalBoss=100,elite=100,guardian=100,cache=100,guardianLair=100,downedPartyMember=100}
local function db()
 if type(FieldKitDB)~="table" then return nil end
 if type(FieldKitDB.worldMarkerSettings)~="table" then FieldKitDB.worldMarkerSettings={} end
 return FieldKitDB.worldMarkerSettings
end
local function save()
 local d=db();if not d then return end
 d.enabled=wantedEnabled;d.aura=auraEnabled;d.pulse=auraPulse;d.intensity=auraIntensity
 d.reviveRing=reviveRingEnabled;d.hints=showLairHints;d.reviveNames=showReviveNames;d.reviveDistance=showReviveDistance;d.categories=categoryEnabled;d.scales=categoryScale;d.ranges=categoryRange
end
local function loadSettings()
 local d=db();if not d then return end
 wantedEnabled=d.enabled~=false
 if type(d.aura)=="boolean" then auraEnabled=d.aura end
 if type(d.pulse)=="boolean" then auraPulse=d.pulse end
 if type(d.intensity)=="number" then auraIntensity=math.max(0,math.min(1,d.intensity)) end
 if type(d.reviveRing)=="boolean" then reviveRingEnabled=d.reviveRing end
 if type(d.hints)=="boolean" then showLairHints=d.hints end
 if type(d.reviveNames)=="boolean" then showReviveNames=d.reviveNames end
 if type(d.reviveDistance)=="boolean" then showReviveDistance=d.reviveDistance end
 if type(d.categories)=="table" then
  for k in pairs(categoryEnabled) do if type(d.categories[k])=="boolean" then categoryEnabled[k]=d.categories[k] end end
 end
 if type(d.ranges)=="table" then
  for k in pairs(categoryRange) do if type(d.ranges[k])=="number" then categoryRange[k]=math.max(10,math.min(250,d.ranges[k])) end end
 end
 if type(d.scales)=="table" then
  for k in pairs(categoryScale) do if type(d.scales[k])=="number" then categoryScale[k]=math.max(60,math.min(150,d.scales[k])) end end
 end
end

local function updateDowned()
 if type(AZS_GetDownedPartyMembers)~="function" then downedList={};downedSnapshotAge=0;return end
 local ok,list=pcall(AZS_GetDownedPartyMembers)
 if ok and type(list)=="table" then
  local nextList={}
  for i=1,table.getn(list) do
   local d=list[i]
   if type(d)=="table" and type(d.id)=="string" then nextList[d.id]=d end
  end
  downedList=nextList
  downedSnapshotAge=0
 end
 -- A transient NOT_READY must not leave a ghost revive marker indefinitely.
 -- The OnUpdate ticker clears observations if the API remains unavailable.
end
local function newIcon()
 local f=table.remove(pool)
 if f then return f end
 f=CreateFrame("Frame",nil,WorldFrame)
 f:SetFrameStrata("HIGH")
 local glow=f:CreateTexture(nil,"BACKGROUND")
 glow:SetTexture(auraTexture)
 glow:SetBlendMode("ADD")
 glow:SetPoint("CENTER",f,"CENTER",0,0)
 f.auraTexture=glow
 local tex=f:CreateTexture(nil,"ARTWORK")
 tex:SetAllPoints(f)
 tex:SetBlendMode("BLEND")
 f.iconTexture=tex
 local name=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 name:SetPoint("TOP",f,"BOTTOM",0,-8)
 name:SetTextColor(0.6,0.9,1)
 f.reviveLabel=name
 -- Hover hints only for spawn markers; all other markers remain click-through.
 f:SetScript("OnEnter",function()
  if this.markerKind=="guardianLair" and showLairHints and GameTooltip then
   GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
   GameTooltip:SetText(FieldKit_L and FieldKit_L("Spawn point") or "Spawn point",1,.8,.3)
   GameTooltip:AddLine(FieldKit_L and FieldKit_L("Guardian lair location; appearance does not guarantee a spawn is imminent.") or "Guardian lair location; appearance does not guarantee a spawn is imminent.",.9,.9,.9,1)
   GameTooltip:Show()
  end
 end)
 f:SetScript("OnLeave",function() if GameTooltip and GameTooltip:IsOwned(this) then GameTooltip:Hide() end end)
 return f
end
local function acquireGroundRing()
 local f=table.remove(groundPool)
 if f then return f end
 f=CreateFrame("Frame",nil,WorldFrame)
 f:SetFrameStrata("MEDIUM")
 local tex=f:CreateTexture(nil,"ARTWORK")
 tex:SetAllPoints(f)
 tex:SetTexture("Interface\\AddOns\\AzerothFieldKit\\media\\WorldMarkers\\reviveRing")
 tex:SetBlendMode("ADD")
 f.texture=tex
 f:EnableMouse(false)
 return f
end
local function recycle(id)
 local f=icons[id]
 if f then f:Hide();icons[id]=nil;table.insert(pool,f) end
 local ring=groundRings[id]
 if ring then ring:Hide();groundRings[id]=nil;table.insert(groundPool,ring) end
end
local function clear()
 for id in pairs(icons) do recycle(id) end
end
local function onFrame(entries,reason)
 if reason=="cleared" then clear();return end
 if not active or not entries then return end
 local requests,frames,seen,groundPairs={}, {}, {}, {}
 local requestKinds={}
 for i=1,table.getn(entries) do
  local e=entries[i];local s=styles[e.kind]
  if s and categoryEnabled[e.kind]~=false and (e.kind~="guardianLair" or showLairHints) and (e.state=="alive" or e.state=="present" or e.kind=="guardianLair") and table.getn(requests)<128 then
   seen[e.anchorId]=true
   local f=icons[e.anchorId]
   if not f then f=newIcon();icons[e.anchorId]=f end
   local sz=s[2]*(categoryScale[e.kind] or 100)/100
   f:SetWidth(sz);f:SetHeight(sz);f.iconTexture:SetTexture(s[1])
   f.markerKind=e.kind
   f.reviveLabel:SetText("")
   f:EnableMouse(e.kind=="guardianLair" and showLairHints)
   f.auraTexture:SetWidth(sz*1.6);f.auraTexture:SetHeight(sz*1.6)
   updateAura(f)
   local req={anchorId=e.anchorId,attachment=(e.kind=="cache" or e.kind=="guardianLair") and "position" or "overhead"}
   if req.attachment=="position" then req.offset={z=2} end
   table.insert(requests,req);table.insert(frames,f);table.insert(requestKinds,e.kind)
  end
 end
 -- Downed friends may not yet be in the world-anchor catalogue; use the dedicated API.
 if categoryEnabled.downedPartyMember~=false then
  for id,d in pairs(downedList) do
   if d.positionAvailable and d.anchorStatus=="ready" and type(d.anchorId)=="string" and table.getn(requests)<128 then
    local key="revive:"..id
    seen[key]=true
    local f=icons[key]
    if not f then f=newIcon();icons[key]=f end
    local sz=styles.downedPartyMember[2]*(categoryScale.downedPartyMember or 100)/100
    f:SetWidth(sz);f:SetHeight(sz);f.iconTexture:SetTexture(styles.downedPartyMember[1]);f.markerKind="downedPartyMember"
    f.auraTexture:SetWidth(sz*1.6);f.auraTexture:SetHeight(sz*1.6);updateAura(f)
    local label=""
    if showReviveNames then label=d.name or "" end
    if showReviveDistance and type(AZS_GetPlayerPosition)=="function" then
     local ok,p=pcall(AZS_GetPlayerPosition)
     if ok and type(p)=="table" and p.spaceId==d.spaceId and type(p.x)=="number" and type(p.y)=="number" then
      local dx=d.x-p.x;local dy=d.y-p.y
      label=label.." ("..math.floor(math.sqrt(dx*dx+dy*dy)+0.5).." yd)"
     end
    end
    f.reviveLabel:SetText(label)
    f:EnableMouse(false)
    table.insert(requests,{anchorId=d.anchorId,attachment="position",offset={z=3}})
    table.insert(frames,f);table.insert(requestKinds,"downedPartyMember")
    -- Project a second point at ground level. The ring is a screen-space
    -- indicator, not a 3D decal; its position follows the native projection.
    if reviveRingEnabled and table.getn(requests)<128 then
     local ring=groundRings[key]
     if not ring then ring=acquireGroundRing();groundRings[key]=ring end
     local rs=math.max(50,math.floor(sz*1.1))
     ring:SetWidth(rs);ring:SetHeight(math.max(20,math.floor(rs*0.46)))
     table.insert(requests,{anchorId=d.anchorId,attachment="position",offset={z=0}})
     table.insert(frames,ring);table.insert(requestKinds,"downedPartyMember")
     groundPairs[ring]=true
    end
   end
  end
 end
 for id in pairs(icons) do if not seen[id] then recycle(id) end end
 -- Rings are independent pooled frames: disabling the ring must recycle it
 -- even when its corresponding angel remains visible.
 for id,ring in pairs(groundRings) do
  if not groundPairs[ring] then
   ring:Hide();groundRings[id]=nil;table.insert(groundPool,ring)
  end
 end
 if table.getn(requests)==0 then return end
 local projected=nil
 if A and type(A.Project)=="function" then projected=A.Project(requests) end
 if not projected or type(projected.entries)~="table" then
  for i=1,table.getn(frames) do frames[i]:Hide() end
  return
 end
 for i=1,table.getn(frames) do
  local f=frames[i];local e=projected.entries[i]
  if e and e.state=="onScreen" and type(e.x)=="number" and type(e.y)=="number"
     and e.x==e.x and e.y==e.y and math.abs(e.x)<100000000 and math.abs(e.y)<100000000 then
   if not e.playerDistance or e.playerDistance<=(categoryRange[requestKinds[i]] or 130) then
    f:ClearAllPoints();f:SetPoint("CENTER",WorldFrame,"BOTTOMLEFT",e.x,e.y+(groundPairs[f] and 0 or (f.markerKind=="downedPartyMember" and 52 or 8)));f:Show()
   else f:Hide() end
  else f:Hide() end
 end
end
function M.Enable()
 if active then return true end
 if not A or not A.Available or not A.Available() then return false end
 if not A.Enable() then return false end
 active=true;wantedEnabled=true;updateDowned();save();A.Subscribe("fieldkit-world-markers",onFrame)
 A.Refresh()
 return true
end
function M.Disable() active=false;wantedEnabled=false;save();if A then A.Unsubscribe("fieldkit-world-markers") end;clear() end
function M.IsEnabled() return active end
function M.SetLairHints(value) showLairHints=not not value;save();clear();return showLairHints end
function M.GetLairHints() return showLairHints end
function M.SetAura(value) auraEnabled=not not value;save();for _,f in pairs(icons) do updateAura(f) end;return auraEnabled end
function M.SetAuraPulse(value) auraPulse=not not value;save();for _,f in pairs(icons) do updateAura(f) end;return auraPulse end
function M.SetAuraIntensity(value)
 value=tonumber(value)
 if not value then return auraIntensity end
 auraIntensity=math.max(0,math.min(1,value));save()
 for _,f in pairs(icons) do updateAura(f) end
 return auraIntensity
end
function M.GetReviveNames() return showReviveNames end
function M.SetReviveNames(v) showReviveNames=not not v;save() end
function M.GetReviveDistance() return showReviveDistance end
function M.SetReviveDistance(v) showReviveDistance=not not v;save() end
local reviveTicker=CreateFrame("Frame")
reviveTicker:SetScript("OnUpdate",function()
 if not active then return end
 downedTimer=downedTimer+(arg1 or 0)
 downedSnapshotAge=downedSnapshotAge+(arg1 or 0)
 if downedTimer>=0.4 then
  downedTimer=downedTimer-math.floor(downedTimer/0.4)*0.4
  updateDowned()
  if downedSnapshotAge>DOWNED_SNAPSHOT_TTL then downedList={} end
 end
end)
function M.SetReviveRing(value)
 reviveRingEnabled=not not value;save()
 if not reviveRingEnabled then
  for id,ring in pairs(groundRings) do
   ring:Hide();groundRings[id]=nil;table.insert(groundPool,ring)
  end
 end
 return reviveRingEnabled
end
function M.GetReviveRing() return reviveRingEnabled end
function M.GetAura() return auraEnabled end
function M.GetAuraPulse() return auraPulse end
function M.GetAuraIntensity() return auraIntensity end
function M.GetCategoryEnabled(kind) return categoryEnabled[kind]~=false end
function M.SetCategoryEnabled(kind,value)
 if categoryEnabled[kind]==nil then return end
 categoryEnabled[kind]=not not value;save();clear()
end
function M.GetCategoryScale(kind) return categoryScale[kind] or 100 end
function M.SetCategoryScale(kind,value)
 if categoryScale[kind]==nil then return end
 categoryScale[kind]=math.max(60,math.min(150,tonumber(value) or 100));save()
end
function M.GetCategoryRange(kind) return categoryRange[kind] or 130 end
function M.SetCategoryRange(kind,value)
 if categoryRange[kind]==nil then return nil end
 local n=tonumber(value)
 if not n then return categoryRange[kind] end
 categoryRange[kind]=math.max(10,math.min(250,n));save()
 return categoryRange[kind]
end
function M.GetTexture(kind) local style=styles[kind];return style and style[1] end
function M.GetAuraTexture() return auraTexture end
load()
local function report(msg)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffc7a6ffFieldKit Markers:|r "..msg) end
end
SLASH_FIELDKITMARKERS1="/fkmarkers"
SlashCmdList["FIELDKITMARKERS"]=function(msg)
 msg=string.lower(msg or "")
 if msg=="on" then report(M.Enable() and "enabled" or "API unavailable")
 elseif msg=="off" then M.Disable();report("disabled")
 elseif msg=="aura on" then M.SetAura(true);report("aura enabled")
 elseif msg=="aura off" then M.SetAura(false);report("aura disabled")
 elseif msg=="aura pulse on" then M.SetAuraPulse(true);report("aura pulse enabled")
 elseif msg=="aura pulse off" then M.SetAuraPulse(false);report("aura pulse disabled")
 elseif string.find(msg,"^aura intensity ") then
  local v=tonumber(string.sub(msg,16))
  if v then report("aura intensity="..math.floor(M.SetAuraIntensity(v/100)*100).."%") else report("usage: /fkmarkers aura intensity 35") end
 elseif string.find(msg,"^range ") then
  local kind,amount=string.match(msg,"^range%s+(%S+)%s+(%d+)$")
  local aliases={finalboss="finalBoss",guardianlair="guardianLair",downedpartymember="downedPartyMember"}
  kind=aliases[kind] or kind
  if kind and amount and categoryRange[kind] then
   report(kind.." range="..M.SetCategoryRange(kind,amount).." yd")
  else report("usage: /fkmarkers range boss 100 | kinds: boss finalBoss elite guardian cache guardianLair downedPartyMember") end
 elseif msg=="hints on" then M.SetLairHints(true);report("lair spawn hints enabled (experimental)")
 elseif msg=="hints off" then M.SetLairHints(false);report("lair spawn hints disabled")
 else report("enabled="..tostring(active).." lair hints="..tostring(showLairHints).." pool="..table.getn(pool).." aura="..tostring(auraEnabled).." pulse="..tostring(auraPulse).." | /fkmarkers aura on/off") end
end

-- Restore saved marker preference after the game API becomes available. Explicit off persists.
local autoStart=CreateFrame("Frame")
local elapsed=0
autoStart:RegisterEvent("PLAYER_ENTERING_WORLD")
autoStart:SetScript("OnEvent",function() elapsed=0 end)
autoStart:SetScript("OnUpdate",function()
 if active or not wantedEnabled then return end
 elapsed=elapsed+(arg1 or 0)
 if elapsed<1 then return end
 elapsed=0
 M.Enable()
end)
