-- A common top-left anchor for the left HUD cards. Individual legacy positions
-- are retained for unlinking; only FieldKitLeftStack stores the linked position.
FieldKitHudStack={}
local S=FieldKitHudStack

function S.Initialize(frames,makeMovable,placeMovable)
 S.frames=frames;S.place=placeMovable;S.finishers={};S.watchdogs={}
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
  -- Benilla can keep a native StartMoving() active even after mouse release,
  -- especially on cards anchored to an invisible linked stack. Never call
  -- StartMoving() for linked HUD cards: move the stack from cursor deltas.
  -- Individual cards retain their original native handlers when unlinked.
  local dragging=false
  local cursorX,cursorY,rootPoint
  local function MoveGroup()
   if not dragging or not rootPoint then return end
   local cx,cy=GetCursorPosition()
   if type(cx)~="number" or type(cy)~="number" then return end
   local scale=(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
   if type(scale)~="number" or scale<=0 then scale=1 end
   local dx=(cx-cursorX)/scale
   local dy=(cy-cursorY)/scale
   root:ClearAllPoints()
   root:SetPoint(rootPoint[1],UIParent,rootPoint[2],rootPoint[3]+dx,rootPoint[4]+dy)
  end
  local function FinishCardDrag()
   if dragging then
    MoveGroup()
    dragging=false
    f.fieldkitHudDragging=nil
    root.azsMoving=nil
    if FieldKitPositions.Save(root,true) then FieldKitPositions.Restore(root) end
    rootPoint=nil
    S.Apply()
   elseif not FieldKitDB.linkLeftCards and stop then stop() end
  end
  local function BeginCardDrag()
   if FieldKitDB.linkLeftCards then
    if dragging or (FieldKitDB.windowsLocked and not FieldKit.layoutEditing) then return end
    local p,relative,rp,x,y=root:GetPoint(1)
    if type(p)~="string" or (relative and relative~=UIParent and relative~="UIParent") then return end
    local cx,cy=GetCursorPosition()
    if type(cx)~="number" or type(cy)~="number" then return end
    cursorX,cursorY=cx,cy
    rootPoint={p,rp or p,tonumber(x) or 0,tonumber(y) or 0}
    dragging=true
    f.fieldkitHudDragging=true
    root.azsMoving=true -- prevents automatic re-anchoring mid-drag
    -- Deliberately do NOT call StartMoving() on root or card.
   elseif start then start() end
  end
  -- RegisterForDrag consumes native mouse-up events on the 1.12-derived
  -- client, while IsMouseButtonDown does not exist on original 1.12.
  -- Use a paired mouse-down/up lifecycle on the clicked card itself.
  f:RegisterForDrag()
  -- Script aliases retained for existing unit fixtures and explicit calls;
  -- RegisterForDrag() with no buttons prevents the native drag event path.
  f:SetScript("OnDragStart",BeginCardDrag)
  f:SetScript("OnDragStop",FinishCardDrag)
  f:SetScript("OnMouseDown",function()
   if type(arg1)=="string" and arg1~="LeftButton" then return end
   BeginCardDrag()
  end)
  S.finishers[i]=FinishCardDrag
  -- Run Mode uses child row frames for its dynamic text/tooltip. They can
  -- receive the release instead of their parent, so delegate both edges.
  if i==1 and f.rows then
   for j=1,table.getn(f.rows) do
    local row=f.rows[j]
    row:RegisterForDrag()
    row:SetScript("OnMouseDown",function()
     if type(arg1)=="string" and arg1~="LeftButton" then return end
     BeginCardDrag()
    end)
    row:SetScript("OnMouseUp",function()
     if type(arg1)=="string" and arg1~="LeftButton" then return end
     FinishCardDrag()
    end)
   end
  end
  f:SetScript("OnMouseUp",function()
   if type(arg1)=="string" and arg1~="LeftButton" then return end
   FinishCardDrag()
  end)
  local oldHide=f:GetScript("OnHide")
  f:SetScript("OnHide",function()
   FinishCardDrag()
   if oldHide then oldHide() end
  end)
  local watchdog=CreateFrame("Frame",nil,UIParent)
  S.watchdogs[i]=watchdog
  watchdog:SetScript("OnUpdate",function()
   if not dragging then return end
   if type(IsMouseButtonDown)=="function" and not IsMouseButtonDown("LeftButton") then
    FinishCardDrag()
   else
    MoveGroup()
   end
  end)
 end
end

function S.FinishDragging()
 if not S.finishers then return end
 for i=1,table.getn(S.finishers) do S.finishers[i]() end
end

function S.Apply()
 if FieldKitZoneThemes and FieldKitZoneThemes.active and not FieldKit.layoutEditing then return end
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
  -- Do not re-anchor a card while native mouse capture owns its drag.
  if f.fieldkitHudDragging then return end
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
