-- Runtime boundary: validate data and centralize the few native setting writes.
-- This module runs first. It performs no I/O, networking or native writes at load.
-- FieldKit is an addon-owned namespace; AZS_* tables remain owned by the client.
FieldKit = { version = "0.2.3", folder = "AzerothFieldKit" }

-- The only outbound capability: explicitly opted-in meter sharing, one fixed
-- addon prefix, PARTY distribution, printable 230-byte packets, max 4 per second.
-- A successful call means queued by the API, never proof of peer delivery.
function FieldKit.PartyTransportAvailable() return type(SendAddonMessage)=="function" end
function FieldKit.SendPartyDetail(payload)
 if not FieldKitDB or not FieldKitDB.partyDetailSync then return false,"disabled" end
 if type(AZS_GetPhase)~="function" or not AZS_GetPhase() then return false,"no run" end
 local peer=false;for i=1,4 do if UnitExists("party"..i) then peer=true end end
 if not peer then return false,"no party" end
 if not FieldKit.PartyTransportAvailable() then return false,"unavailable" end
 if type(payload)~="string" or string.len(payload)>230 or not string.find(payload,"^[QR]:") or string.find(payload,"[^ -~]") then return false,"invalid" end
 local now=FieldKit.Number(GetTime())
 if not now then return false,"clock" end
 if FieldKit.partyDetailSentAt and now-FieldKit.partyDetailSentAt<.25 then return false,"throttled" end
 FieldKit.partyDetailSentAt=now
 local ok=pcall(SendAddonMessage,"AFKDETAIL1",payload,"PARTY")
 return ok,ok and "queued" or "api error"
end

-- Return a finite numeric value, optionally clamped. Strings are parsed as numbers,
-- never evaluated as Lua. A missing/invalid value returns the caller's fallback.
function FieldKit.Number(value, fallback, minimum, maximum)
 local n=tonumber(value)
 if not n or n~=n or n>1e12 or n< -1e12 then return fallback end
 if minimum then n=math.max(minimum,n) end
 if maximum then n=math.min(maximum,n) end
 return n
end

-- Catch missing CVars in custom clients. Reading an unknown CVar may throw.
function FieldKit.GetCVar(key)
 if type(GetCVar)~="function" then return nil end
 local ok,value=pcall(GetCVar,key)
 if ok then return value end
end

-- Only display CVars may be written. Camera range is clamped at its call site;
-- damage switches only accept 0/1. There is no arbitrary CVar slash command.
local displayCVars={cameraDistanceMaxFactor=true,CombatDamage=true,PetMeleeDamage=true,PetSpellDamage=true}
function FieldKit.SetCVar(key,value)
 if not displayCVars[key] or type(SetCVar)~="function" then return false end
 local n=FieldKit.Number(value)
 if not n then return false end
 if key=="cameraDistanceMaxFactor" then
  if n<1 or n>50/15+.001 then return false end
 elseif n~=0 and n~=1 then return false end
 return pcall(SetCVar,key,tostring(value))
end

-- Restrict native HUD changes to the three existing visual replacement sections.
-- Callers must keep their corresponding DB.hud*Hidden flag for restoration.
function FieldKit.SetHudShown(part,shown)
 if part~="bosses" and part~="tally" and part~="meter" then return false end
 if type(shown)~="boolean" or type(AZS_SetHudShown)~="function" then return false end
 return pcall(AZS_SetHudShown,part,shown)
end

-- Bound persisted name learning. At capacity retain old knowledge and ignore new
-- names; never evict a boss classification just because more enemies appeared.
function FieldKit.RememberClassification(cache,name,class)
 if type(name)~="string" or string.len(name)>160 then return end
 if cache[name]==nil then
  local count=0;for _ in pairs(cache) do count=count+1;if count>=2048 then return end end
 end
 cache[name]=class
end
