-- Own the native map geometry reversibly, never substitute a painted fake map.
FieldKitThemeMinimap={active=false,hidden={}}
-- Runtime-only switches for /fieldkit mapprobe (never saved): ring = edge placement of ring-style buttons through a SetPoint
-- interception (OFF by default: third-party buttons keep their native positioning), rim/proxies/follower = FieldKit parts.
FieldKitThemeMinimap.probe={ring=false,rim=true,proxies=true,follower=true}
local M=FieldKitThemeMinimap
local borderNames={"MinimapBorder","MinimapBorderTop","MinimapZoneTextButton","MinimapToggleButton","MinimapBackdrop"}
function M.Rotate(x,y)
 if FieldKit.GetCVar("rotateMinimap")~="1" then return x,y end
 local pos
 if type(AZS_GetPlayerPosition)=="function" then local ok,p=pcall(AZS_GetPlayerPosition);if ok then pos=p end end
 local angle=type(pos)=="table" and FieldKit.Number(pos.facing)
 angle=angle or (type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.pf))
 if not angle then return nil,nil end
 local c,s=math.cos(-angle),math.sin(-angle)
 return x*c-y*s,x*s+y*c
end
-- Third-party launcher buttons stay Minimap children, so their owners (e.g. a button manager that fades or hides
-- them) keep control of alpha/mouse. FieldKit only moves a duplicate-prone original off screen and remembers its anchors.
-- GetPoint may return the relative frame as a NAME on this client, so the parked spot is recognised by its offsets.
local function IsParked(f) local _,_,_,x,y=f:GetPoint();return x==-4000 and y==-4000 end
function M.Park(f)
 M.parked=M.parked or {}
 if not M.parked[f] then M.parked[f]=FieldKitThemeHUD.Points(f) end
 if not IsParked(f) then f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",-4000,-4000) end
end
function M.Unpark()
 for f,points in pairs(M.parked or {}) do
  if IsParked(f) then
   f:ClearAllPoints();for i=1,table.getn(points) do local a=points[i];f:SetPoint(a[1],a[2],a[3],a[4],a[5]) end
  end
 end
 M.parked={}
end
-- Buttons that follow the common minimap-button convention (one CENTER anchor on the Minimap at a native-sized
-- radius, e.g. cos/sin*80 while dragging) keep their angle but ride the edge of the visible opening. The owner's own
-- SetPoint calls are intercepted on that button instance, so the correction is applied in the same call (no frame-order
-- race with the owner's drag OnUpdate) and the owner's raw offsets are always known for an exact restoration.
local ringProxied={FieldKitMinimapButton=true,AzerothStatsMinimap=true,AzerothOneMinimapButton=true}
local function Edge(x,y)
 local half=M.ringHalf;if not half then return nil end
 local radius=math.sqrt(x*x+y*y)
 if radius<55 or radius>100 then return nil end
 local dx,dy=x/radius,y/radius
 -- Ride just INSIDE the visible opening (button centre 14 px in): never over the rim art or the labels under the map.
 local reach=1/math.max(math.abs(dx)/half[1],math.abs(dy)/half[2])-14
 return dx*reach,dy*reach
end
function M.Wrap(f)
 if f.fieldkitRingOriginal then return end
 local original=f.SetPoint;f.fieldkitRingOriginal=original
 M.wrapped=M.wrapped or {};table.insert(M.wrapped,f)
 f.SetPoint=function(self,point,rel,relPoint,x,y)
  if M.active and point=="CENTER" and rel==Minimap and relPoint=="CENTER" and type(x)=="number" and type(y)=="number" then
   local ax,ay=Edge(x,y)
   if ax then
    M.ring[self]={rx=x,ry=y,ax=ax,ay=ay}
    M.log=M.log or {};table.insert(M.log,string.format("%s raw %.1f,%.1f -> %.1f,%.1f",tostring(self:GetName()),x,y,ax,ay));if table.getn(M.log)>8 then table.remove(M.log,1) end
    return original(self,point,rel,relPoint,ax,ay)
   end
  end
  M.ring[self]=nil -- the owner placed it some other way: it is no longer ours to restore
  return original(self,point,rel,relPoint,x,y)
 end
end
function M.Ring(halfW,halfH)
 M.ring=M.ring or {}
 local changed=not M.ringHalf or M.ringHalf[1]~=halfW or M.ringHalf[2]~=halfH
 M.ringHalf={halfW,halfH}
 if not Minimap or not Minimap.GetChildren then return end
 M.alphaSeen=M.alphaSeen or {}
 for _,f in ipairs({Minimap:GetChildren()}) do
  local name=f.GetName and f:GetName()
  if name and f.GetAlpha then
   -- Evidence for "hidden icons come back on hover": who raises a hidden button's alpha, and when.
   local alpha=f:GetAlpha();local was=M.alphaSeen[f]
   if was and was==0 and alpha>0 then M.log=M.log or {};table.insert(M.log,string.format("%s alpha 0 -> %.2f (mouse over map: %s)",name,alpha,tostring(type(MouseIsOver)=="function" and MouseIsOver(Minimap) and true or false)));if table.getn(M.log)>8 then table.remove(M.log,1) end end
   M.alphaSeen[f]=alpha
  end
  if name and not ringProxied[name] and f.GetObjectType and f:GetObjectType()=="Button" and not string.find(name,"^FieldKit") and not f.fieldkitRingOriginal then
   local points=FieldKitThemeHUD.Points(f);local p=points[1]
   if table.getn(points)==1 and p[1]=="CENTER" and p[2]==Minimap and p[3]=="CENTER" and Edge(p[4],p[5]) then
    M.Wrap(f);f:ClearAllPoints();f:SetPoint("CENTER",Minimap,"CENTER",p[4],p[5]) -- goes through the wrapper: edge position, raw remembered
   end
  end
 end
 if changed then for f,r in pairs(M.ring) do local ax,ay=Edge(r.rx,r.ry);if ax then r.ax,r.ay=ax,ay;f.fieldkitRingOriginal(f,"CENTER",Minimap,"CENTER",ax,ay) end end end
end
function M.RingRestore()
 for _,f in ipairs(M.wrapped or {}) do f.SetPoint=nil;f.fieldkitRingOriginal=nil end
 for f,r in pairs(M.ring or {}) do f:ClearAllPoints();f:SetPoint("CENTER",Minimap,"CENTER",r.rx,r.ry) end
 M.ring={};M.wrapped={};M.ringHalf=nil
end
-- The frame that owns the map group: the identity card when the map has no art of its own, else the art frame.
function M.GroupOwner()
 local R=FieldKitReferenceHUD
 if R and R.active and R.layout and not R.layout.rects.mapArt and FieldKitThemeHUD.identity then return FieldKitThemeHUD.identity end
 return M.root
end
function M.Restore()
 if not M.active then return end
 M.Unpark();M.RingRestore()
 local old=M.before
 if old.scripts then for _,event in ipairs({"OnDragStart","OnDragStop","OnMouseDown","OnMouseUp"}) do Minimap:SetScript(event,old.scripts[event]) end end
 if old.movable~=nil then Minimap:SetMovable(old.movable) end
 if old.mouse~=nil then Minimap:EnableMouse(old.mouse) end
 for f,callback in pairs(M.launcherUpdates or {}) do f:SetScript("OnUpdate",callback~=false and callback or nil) end;M.launcherUpdates={}
 if Minimap and Minimap:GetParent()==M.root then
  local shown=Minimap:IsShown();Minimap:SetParent(old.parent);Minimap:ClearAllPoints()
  for i=1,table.getn(old.points) do local a=old.points[i];Minimap:SetPoint(a[1],a[2],a[3],a[4],a[5]) end
  Minimap:SetWidth(old.width);Minimap:SetHeight(old.height)
  if Minimap.SetMaskTexture then pcall(Minimap.SetMaskTexture,Minimap,old.mask) end
  if shown then Minimap:Hide();Minimap:Show() end
 end
 for f,alpha in pairs(M.hidden) do if f:GetAlpha()==0 then f:SetAlpha(alpha) end end
 for _,name in ipairs({"GameTimeFrame","MinimapZoomIn","MinimapZoomOut"}) do local f=getglobal(name);if f then FieldKitThemeHUD.RestoreOne(f) end end
 M.hidden={};M.active=false;M.before=nil
 if M.dragHandle then M.dragHandle:Hide() end
 for _,proxy in pairs(M.launcherProxies or {}) do proxy:Hide() end
 if M.rim then M.rim:Hide() end
 if M.root then M.root:Hide() end
 if M.zoomOut then M.zoomOut:Hide();M.zoomIn:Hide() end
end
function M.Apply(variant)
 if not Minimap or type(Minimap.SetMaskTexture)~="function" then M.reason="Square map unavailable";return false end
 if not M.active then
  local parent=Minimap:GetParent();local name=parent and parent:GetName()
  if name and name~="UIParent" and name~="MinimapCluster" and name~="MinimapBackdrop" then
   M.reason="Another addon owns the minimap";return false
  end
  if not Minimap.GetMaskTexture and type(GetMinimapShape)=="function" and GetMinimapShape()~="ROUND" then M.reason="Another addon owns the minimap";return false end
  local mask="Textures\\MinimapMask"
  if Minimap.GetMaskTexture then local ok,path=pcall(Minimap.GetMaskTexture,Minimap);if ok and type(path)=="string" then mask=path end end
  local points=FieldKitThemeHUD.Points(Minimap)
  M.before={parent=parent,points=points,width=Minimap:GetWidth(),height=Minimap:GetHeight(),mask=mask,scripts={},mouse=Minimap.IsMouseEnabled and Minimap:IsMouseEnabled(),movable=Minimap.IsMovable and Minimap:IsMovable()}
  for _,event in ipairs({"OnDragStart","OnDragStop","OnMouseDown","OnMouseUp"}) do M.before.scripts[event]=Minimap:GetScript(event) end
  -- FieldKit installs NO script on the native Minimap any more: the map is never moved on its own. The group is moved
  -- from the identity card / art frame, or from the dedicated handle (see FieldKitReferenceHUD.Map).
  if not M.root then
   M.root=CreateFrame("Frame","FieldKitThemeMap",UIParent);M.root:SetFrameStrata("MEDIUM")
   FieldKitTheme.Surface(M.root,"card",true);FieldKitZoneThemes.Bind(M.root)
   -- ROOT CAUSE of "the map leaves its frame": Bind made this container movable on its own, but on layouts without map art it
   -- only holds the native map INSIDE the identity card. A drag reaching it moved the map alone. A drag here now moves the
   -- owner of the whole group (never this container when it is not the owner).
   M.root:SetScript("OnDragStart",function()
    if not FieldKitZoneThemes.active or FieldKitDB.windowsLocked then return end
    local owner=M.GroupOwner();owner.azsMoving=true;M.dragOwner=owner;owner:StartMoving()
   end)
   local function Done() local owner=M.dragOwner or M.root;M.dragOwner=nil;FieldKitZoneThemes.Finish(owner) end
   M.root:SetScript("OnDragStop",Done);M.root:SetScript("OnMouseUp",Done);M.root:SetScript("OnHide",Done)
   for i,step in ipairs({-1,1}) do
    local delta=step
    local b=FieldKitTheme.Button(M.root,nil,step==1 and "+" or "-",0,0,22,22,function()
     if Minimap.SetZoom and Minimap.GetZoom then
      local count=Minimap.GetZoomLevels and Minimap:GetZoomLevels() or 6
      Minimap:SetZoom(math.max(0,math.min(count-1,Minimap:GetZoom()+delta)))
     end
    end)
    b:ClearAllPoints();b:SetPoint(i==1 and "BOTTOMLEFT" or "BOTTOMRIGHT",M.root,i==1 and "BOTTOMLEFT" or "BOTTOMRIGHT",i==1 and 5 or -5,5)
    b:SetFrameLevel(Minimap:GetFrameLevel()+12)
    if i==1 then M.zoomOut=b else M.zoomIn=b end
   end
  end
  local ok,result=pcall(Minimap.SetMaskTexture,Minimap,"Interface\\Buttons\\WHITE8X8")
  if not ok or result==false then M.reason="Square mask rejected";M.before=nil;return false end
  M.active=true;M.reason=nil
  for _,name in ipairs({"MinimapZoomIn","MinimapZoomOut"}) do local f=getglobal(name);if f then FieldKitThemeHUD.Save(f);f:SetParent(FieldKitThemeHUD.Hidden()) end end
  Minimap:SetParent(M.root)
  for i=1,table.getn(borderNames) do local f=getglobal(borderNames[i]);if f and f.SetAlpha then M.hidden[f]=f:GetAlpha();f:SetAlpha(0) end end
 end
 if FieldKitReferenceHUD and FieldKitReferenceHUD.active then return FieldKitReferenceHUD.Map() end
 if M.rim then M.rim:Hide() end
 local size=math.min(230,math.max(160,UIParent:GetWidth()*.13))
 local zone=FieldKitTheme.zone
 if not M.root.azsMoving then M.root:SetWidth(size+16);M.root:SetHeight(size+16) end
 if (variant=="complete" and zone=="elwynn") or (variant=="alternative" and zone=="naxx") then FieldKitZoneThemes.Place(M.root,"TOPLEFT",UIParent,"TOPLEFT",20,-18)
 elseif variant=="alternative" then FieldKitZoneThemes.Place(M.root,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-20,66)
 else FieldKitZoneThemes.Place(M.root,"TOPRIGHT",UIParent,"TOPRIGHT",-20,-38) end
 Minimap:ClearAllPoints();Minimap:SetPoint("CENTER",M.root,"CENTER",0,0);Minimap:SetWidth(size);Minimap:SetHeight(size)
 local clock=getglobal("GameTimeFrame")
 if clock then FieldKitThemeHUD.Anchor(clock,"TOPRIGHT",M.root,"TOPRIGHT",0,0);clock:SetScale(.75) end
 M.root:SetMovable(true)
 if M.probe.ring then M.Ring(size/2,size/2) else M.RingRestore() end
 FieldKitTheme.Update(M.root);M.root:Show();return true
end
