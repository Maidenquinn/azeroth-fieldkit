-- The new API covers level-up/jewelry screens, not every native modal.
-- Register only named FieldKit HUD frames, only while explicitly opted in/shown.
FieldKitScreenLayers={registered={}}
local S=FieldKitScreenLayers
function S.Update()
 if not FieldKitDB then return end
 local names={}
 for _,name in ipairs(FieldKitCardLayout.names) do table.insert(names,name) end
 table.insert(names,"FieldKitPartyDetailsFrame")
 for _,name in ipairs(names) do
  local frame=getglobal(name)
  local enabled=FieldKitDB.onTopWindows[name] and frame and frame:IsShown() and FieldKitNative.Active()
  if name=="FieldKitPartyDetailsFrame" then enabled=enabled and FieldKitPartyDetails.pinned end
  if enabled and not S.registered[name] then
   if FieldKit.SetFrameOnTop(name,true) then S.registered[name]=true end
  elseif not enabled and S.registered[name] then
   if FieldKit.SetFrameOnTop(name,false) then S.registered[name]=nil end
  end
 end
end
