-- Temporary presentation isolation for explicit placement only. Never hide
-- UIParent, the world, or stop another addon's update/event scripts. Alpha and
-- mouse state are restored on exit; no native HUD setting or saved flag changes.
FieldKitPreviewVisibility={masked={},hideOthers=true}
local V=FieldKitPreviewVisibility

-- Preserve the editor, its placeholders, proxies and combat-area drag handles.
-- Other FieldKit frames are live displays and are always masked in placement.
function V.Keep(frame)
 local P=FieldKitPreview
 if FieldKitUI and frame==FieldKitUI.dock then return true end
 for _,f in pairs(P.frames) do if frame==f then return true end end
 for _,f in pairs(P.roots) do if frame==f then return true end end
 return frame==getglobal("FieldKitCombatAnchor1") or frame==getglobal("FieldKitCombatAnchor2")
end

function V.Restore(frame)
 local record=V.masked[frame];if not record then return end
 if record.alpha~=nil then pcall(frame.SetAlpha,frame,record.alpha) end
 if record.mouse~=nil then pcall(frame.EnableMouse,frame,record.mouse) end
 V.masked[frame]=nil
end

function V.Clear(othersOnly)
 local list={}
 for frame,record in pairs(V.masked) do
  if not othersOnly or record.other then table.insert(list,frame) end
 end
 for _,frame in ipairs(list) do V.Restore(frame) end
end

-- Capture each region once per session. Do not overwrite the original state
-- during repeated refreshes, even if another renderer calls Show or SetAlpha.
function V.Mask(frame,other,visual)
 if not frame or frame==UIParent or frame==WorldFrame or V.Keep(frame) then return end
 if not frame.SetAlpha or not frame.GetAlpha then return end
 local record=V.masked[frame]
 if not record then
  local ok,alpha=pcall(frame.GetAlpha,frame)
  if not ok or type(alpha)~="number" then return end
  record={alpha=visual and alpha or nil,other=other};V.masked[frame]=record
  if frame.IsMouseEnabled and frame.EnableMouse then
   local success,mouse=pcall(frame.IsMouseEnabled,frame)
   if success then record.mouse=mouse and true or false end
  end
 end
 -- A region first encountered as a child may later become a root. Capture
 -- its own alpha before promoting it to a visually masked record.
 if visual and record.alpha==nil then
  local ok,alpha=pcall(frame.GetAlpha,frame)
  if ok and type(alpha)=="number" then record.alpha=alpha end
 end
 if not other then record.other=false end
 if visual then pcall(frame.SetAlpha,frame,0) end
 if record.mouse~=nil then pcall(frame.EnableMouse,frame,false) end
 -- Invisible child buttons must not steal drags from a sample at the same place.
 -- Traversal is bounded; no foreign handlers, parents or methods are replaced.
 if frame.GetChildren and V.remaining>0 then
  local children={frame:GetChildren()}
  for i=1,math.min(table.getn(children),V.remaining) do
   V.remaining=V.remaining-1;V.Mask(children[i],other,false)
  end
 end
end

function V.Update()
 if FieldKitPreview.mode~="place" then V.Clear();return end
 V.remaining=4096
 -- Covers independent children such as target health, as well as group roots.
 for _,name in ipairs(FieldKitPreview.names) do V.Mask(getglobal(name),false,true) end
 for _,name in ipairs({"FieldKitLeftStack","FieldKitRightStack","FieldKitBossFrame2","FieldKitBossFrame3","FieldKitBossFrame4",
  "FieldKitPlayerBar","FieldKitLegacyCritFrame","FieldKitCombatText","FieldKitCompactBar","FieldKitMinimapButton"}) do
  V.Mask(getglobal(name),false,true)
 end
 if V.hideOthers then
  if UIParent.GetChildren then
   local roots={UIParent:GetChildren()}
   for i=1,math.min(1024,table.getn(roots)) do
    local f=roots[i];local name=f.GetName and f:GetName()
    V.Mask(f,not (name and string.find(name,"^FieldKit")),true)
   end
  end
  -- Some native labels are regions directly attached to UIParent, not frames.
  if UIParent.GetRegions then
   local regions={UIParent:GetRegions()}
   for i=1,math.min(256,table.getn(regions)) do V.Mask(regions[i],true,true) end
  end
 end
 if FieldKitUI and FieldKitUI.otherUI then
  FieldKit_Text(FieldKitUI.otherUI,V.hideOthers and "Show other interface elements" or "Hide other interface elements")
 end
end

function V.Toggle()
 V.hideOthers=not V.hideOthers
 if not V.hideOthers then V.Clear(true) end
 V.Update()
end
