-- A common top-left anchor for the left HUD cards. Individual legacy positions
-- are retained for unlinking; only FieldKitLeftStack stores the linked position.
FieldKitHudStack={}
local S=FieldKitHudStack

function S.Initialize(frames,makeMovable,placeMovable)
 S.frames=frames;S.place=placeMovable
 local meter=frames[2]
 local previous=FieldKitDB.pos[meter:GetName()] or {0,0}
 local x,y=previous[1]-meter:GetWidth()/2,previous[2]+meter:GetHeight()/2
 local root=CreateFrame("Frame","FieldKitLeftStack",UIParent);S.root=root
 root.fieldkitTopLeftAnchor=true
 root.fieldkitMouseProxy=true
 root:SetWidth(1);root:SetHeight(1)
 if not FieldKitDB.pos.FieldKitLeftStack then FieldKitDB.pos.FieldKitLeftStack={x,y} end
 local defaults=meter.azsDefault or {0,0}
 makeMovable(root,defaults[1]-meter:GetWidth()/2,defaults[2]+meter:GetHeight()/2,true)
 root:EnableMouse(false)
 for i=1,table.getn(frames) do
  local f=frames[i];local start,stop=f:GetScript("OnDragStart"),f:GetScript("OnDragStop")
  f:SetScript("OnDragStart",function()
   if FieldKitDB.linkLeftCards then root:GetScript("OnDragStart")() elseif start then start() end
  end)
  f:SetScript("OnDragStop",function()
   if FieldKitDB.linkLeftCards then root:GetScript("OnDragStop")() elseif stop then stop() end
  end)
 end
end

function S.Apply()
 if not S.root then return end
 if not FieldKitDB.linkLeftCards then
  if S.linked then
   for i=1,table.getn(S.frames) do
    local f=S.frames[i];f:SetWidth(FieldKitCardLayout.Width(f,f==S.frames[2] and FieldKit.MeterWidth(FieldKitDB.meterValues) or 220))
    if FieldKitDB.pos[f:GetName()] then S.place(f) end
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    FieldKitTheme.Update(f)
   end
  end
  FieldKitRunMode.Reflow(S.frames[1]:GetWidth());S.linked=false;return
 end
 S.linked=true
 local width=FieldKit.MeterWidth(FieldKitDB.meterValues);local height,shown=0,0
 for i=1,table.getn(S.frames) do
  local f=S.frames[i]
  -- Clamp the complete group once; individual card clamps can move it twice.
  if f.SetClampedToScreen then f:SetClampedToScreen(false) end
  local ownWidth=FieldKitCardLayout.Width(f,width)
  if f:GetWidth()~=ownWidth then f:SetWidth(ownWidth);FieldKitTheme.Update(f) end
  if f:IsShown() then
   if shown>0 then height=height+6 end
   local point,relative,rp,x,y=f:GetPoint(1)
   if point~="TOPLEFT" or relative~=S.root or rp~="TOPLEFT" or x~=0 or y~=-height then
    f:ClearAllPoints();f:SetPoint("TOPLEFT",S.root,"TOPLEFT",0,-height)
   end
   height=height+f:GetHeight();shown=shown+1
  end
 end
 FieldKitRunMode.Reflow(S.frames[1]:GetWidth())
 for i=1,table.getn(S.frames) do
  if S.frames[i]:IsShown() then width=math.max(width,S.frames[i]:GetWidth()) end
 end
 S.width=width;S.height=height
 local changed=S.root:GetWidth()~=width or S.root:GetHeight()~=math.max(1,height)
 if changed then S.root:SetWidth(width);S.root:SetHeight(math.max(1,height)) end
 if not S.root.azsMoving then
  local p=FieldKitDB.pos.FieldKitLeftStack
  local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
  local anchor=FieldKitDB.frameAnchors.FieldKitLeftStack
  if changed or anchor~=S.appliedAnchor or p[1]~=S.legacyX or p[2]~=S.legacyY or sw~=S.screenWidth or sh~=S.screenHeight then
   S.place(S.root)
   S.appliedAnchor=anchor;S.legacyX=p[1];S.legacyY=p[2];S.screenWidth=sw;S.screenHeight=sh
  end
 end
end
