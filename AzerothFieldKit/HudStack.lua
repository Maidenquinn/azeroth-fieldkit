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
 root:SetWidth(1);root:SetHeight(1)
 if not FieldKitDB.pos.FieldKitLeftStack then FieldKitDB.pos.FieldKitLeftStack={x,y} end
 local defaults=meter.azsDefault or {0,0}
 makeMovable(root,defaults[1]-meter:GetWidth()/2,defaults[2]+meter:GetHeight()/2,true)
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
    local f=S.frames[i];f:SetWidth(f==S.frames[2] and FieldKit.MeterWidth(FieldKitDB.meterValues) or 220)
    if i==3 then
     f:ClearAllPoints();f:SetPoint("TOPLEFT",S.frames[2],S.frames[2]:IsShown() and "BOTTOMLEFT" or "TOPLEFT",0,-2)
    elseif FieldKitDB.pos[f:GetName()] then S.place(f) end
    FieldKitTheme.Update(f)
   end
  end
  FieldKitRunMode.Reflow(220);S.linked=false;return
 end
 S.linked=true
 local width=FieldKit.MeterWidth(FieldKitDB.meterValues);local height,shown=0,0
 for i=1,table.getn(S.frames) do
  local f=S.frames[i]
  if f:GetWidth()~=width then f:SetWidth(width);FieldKitTheme.Update(f) end
  if f:IsShown() then
   if shown>0 then height=height+6 end
   local point,relative,rp,x,y=f:GetPoint(1)
   if point~="TOPLEFT" or relative~=S.root or rp~="CENTER" or x~=0 or y~=-height then
    f:ClearAllPoints();f:SetPoint("TOPLEFT",S.root,"CENTER",0,-height)
   end
   height=height+f:GetHeight();shown=shown+1
  end
 end
 FieldKitRunMode.Reflow(width)
 S.width=width;S.height=height
 if not S.root.azsMoving then
  local p=FieldKitDB.pos.FieldKitLeftStack
  local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
  local x=math.max(-sw/2+12,math.min(sw/2-width-12,p[1]))
  local y=math.max(math.min(sh/2-12,-sh/2+height+12),math.min(sh/2-12,p[2]))
  local point,relative,rp,px,py=S.root:GetPoint(1)
  if point~="CENTER" or relative~=UIParent or rp~="CENTER" or px~=x or py~=y then
   S.root:ClearAllPoints();S.root:SetPoint("CENTER",UIParent,"CENTER",x,y)
  end
 end
end
