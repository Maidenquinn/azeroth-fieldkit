-- Own the native map geometry reversibly, never substitute a painted fake map.
FieldKitThemeMinimap={active=false,hidden={}}
-- Runtime-only switches for /fieldkit mapprobe (never saved): ring = edge placement of ring-style buttons through a SetPoint
-- interception (ON by default since the mouse stacking fix: gear and other ring buttons ride the gold border), rim/proxies/follower = FieldKit parts.
FieldKitThemeMinimap.probe={ring=true,rim=true,proxies=true,follower=true}
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
-- Only AzerothOne's launcher is still proxied. FieldKit's own button and AzerothStats' button keep their real frames: both place
-- themselves with the standard "CENTER on the Minimap at radius 80, angle from the cursor" drag and save their own angle (DB.minimapAngle,
-- A.db.settings.miniAngle), so the ring interception below moves them to the opening edge while the owner's drag keeps working.
local ringProxied={AzerothOneMinimapButton=true}
-- Ring placement from the REAL geometry: the point where the pointer's direction crosses the border of the map opening, plus half
-- the thickness of the decorative border there (the button is centred ON the gold border: half over the map, half over the frame).
-- geometry = {holeHalfWidth,holeHalfHeight,borderThickness,keepOutRectangles}; a keep-out rectangle (title, foot, zoom buttons) is
-- never covered: the button slides along the border, nearest allowed direction first (counter-clockwise on a tie).
local function Edge(x,y,size)
 local geometry=M.ringHalf;if not geometry then return nil end
 local radius=math.sqrt(x*x+y*y)
 if radius<55 or radius>100 then return nil end
 local half=(size or 32)/2;local theta=math.atan2(y,x)
 local function Place(t)
  local dx,dy=math.cos(t),math.sin(t)
  local reach=(M.ringCircle and geometry[1] or 1/math.max(math.abs(dx)/geometry[1],math.abs(dy)/geometry[2]))+(geometry[3] or 0)/2 -- round map: the border is a circle
  return dx*reach,dy*reach
 end
 local function Blocked(px,py)
  for _,k in ipairs(geometry[4] or {}) do if px-half<k.r and px+half>k.l and py-half<k.top and py+half>k.bottom then return true end end
  return false
 end
 local px,py=Place(theta)
 if not Blocked(px,py) then return px,py end
 local step=math.pi/180
 for n=1,180 do for _,sign in ipairs({1,-1}) do local qx,qy=Place(theta+sign*n*step);if not Blocked(qx,qy) then return qx,qy end end end
 return px,py
end
M.Edge=Edge -- exposed for the tests and the diagnostics
function M.Wrap(f)
 if f.fieldkitRingOriginal then return end
 local original=f.SetPoint;f.fieldkitRingOriginal=original
 M.wrapped=M.wrapped or {};table.insert(M.wrapped,f)
 f.SetPoint=function(self,point,rel,relPoint,x,y)
  if M.active and point=="CENTER" and rel==Minimap and relPoint=="CENTER" and type(x)=="number" and type(y)=="number" then
   local ax,ay=Edge(x,y,self.GetWidth and self:GetWidth())
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
function M.Ring(halfW,halfH,band,keep)
 M.ring=M.ring or {}
 local key=halfW..":"..halfH..":"..tostring(band)..":"..tostring(M.ringCircle)
 for _,k in ipairs(keep or {}) do key=key..":"..k.l..","..k.r..","..k.top..","..k.bottom end
 local changed=M.ringKey~=key
 M.ringKey=key;M.ringHalf={halfW,halfH,band or 0,keep or {}}
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
  if name and not ringProxied[name] and f.GetObjectType and f:GetObjectType()=="Button" and (name=="FieldKitMinimapButton" or not string.find(name,"^FieldKit")) and not f.fieldkitRingOriginal then
   local points=FieldKitThemeHUD.Points(f);local p=points[1]
   if table.getn(points)==1 and p[1]=="CENTER" and p[2]==Minimap and p[3]=="CENTER" and Edge(p[4],p[5],f.GetWidth and f:GetWidth()) then
    M.Wrap(f);f:ClearAllPoints();f:SetPoint("CENTER",Minimap,"CENTER",p[4],p[5]) -- goes through the wrapper: edge position, raw remembered
   end
  end
 end
 if changed then for f,r in pairs(M.ring) do local ax,ay=Edge(r.rx,r.ry,f.GetWidth and f:GetWidth());if ax then r.ax,r.ay=ax,ay;f.fieldkitRingOriginal(f,"CENTER",Minimap,"CENTER",ax,ay) end end end
 M.Lift()
end
-- Render order only: the art rim (a frame redrawn over the map edge) sits at map level + 2, i.e. ABOVE a map button at the native
-- level 2, so the gold border cut the AzerothHub gear. A button FieldKit placed on the border is lifted just above the rim; its
-- native level is remembered (M.Layers keeps computing the mouse stack from it, so the validated order is unchanged) and put back
-- with the theme. Nothing else changes: no position, no script, no other frame.
function M.Lift()
 local top=(M.shape=="round" and M.roundRing and M.roundRing:IsShown()) and M.roundRing or M.rim
 if not top or not top.GetFrameLevel then return end
 M.lifted=M.lifted or {}
 local want=top:GetFrameLevel()+1
 for f in pairs(M.ring or {}) do
  if f.GetFrameLevel and f.SetFrameLevel then
   if M.lifted[f]==nil then M.lifted[f]=f:GetFrameLevel() end
   if f:GetFrameLevel()~=want then f:SetFrameLevel(want) end
  end
 end
end
function M.RingRestore()
 for f,base in pairs(M.lifted or {}) do if f.SetFrameLevel then f:SetFrameLevel(base) end end
 M.lifted={}
 for _,f in ipairs(M.wrapped or {}) do f.SetPoint=nil;f.fieldkitRingOriginal=nil end
 for f,r in pairs(M.ring or {}) do f:ClearAllPoints();f:SetPoint("CENTER",Minimap,"CENTER",r.rx,r.ry) end
 M.ring={};M.wrapped={};M.ringHalf=nil;M.ringKey=nil
end
-- The frame that owns the map group: the identity card when the map has no art of its own, else the art frame.
function M.GroupOwner()
 local R=FieldKitReferenceHUD
 if R and R.active and R.layout and not R.layout.rects.mapArt and FieldKitThemeHUD.identity then return FieldKitThemeHUD.identity end
 return M.root
end
-- Mouse stacking of the map group. Measured on the client: the group owner (identity card or art frame) is at canvas level + 2 = 3
-- while the native map and its buttons keep their own level 2 (this client does not re-level a reparented subtree), so in the
-- same strata the owner is ABOVE the map and takes every press meant for the map and its buttons. Fix: owner at the bottom, the
-- native map just above it, below its own buttons (the lowest mouse-taking child decides). Levels only; it is applied again only
-- when a level changed (a click in progress must not be disturbed), and the map's original level is put back with the theme.
function M.Layers()
 if not Minimap or not Minimap.SetFrameLevel then return end
 local owner=M.GroupOwner()
 local lowest
 if Minimap.GetChildren then
  for _,child in ipairs({Minimap:GetChildren()}) do
   if child.GetFrameLevel and child.IsMouseEnabled and child:IsMouseEnabled() then local l=M.lifted and M.lifted[child] or child:GetFrameLevel();if not lowest or l<lowest then lowest=l end end
  end
 end
 local key=table.concat({Minimap:GetFrameLevel(),owner:GetFrameLevel(),tostring(lowest)},":")
 if M.layerKey==key then return end
 owner:SetFrameLevel(0)
 local want=lowest and math.max(1,lowest-1) or 1
 if Minimap:GetFrameLevel()~=want then Minimap:SetFrameLevel(want) end
 M.layerKey=table.concat({Minimap:GetFrameLevel(),owner:GetFrameLevel(),tostring(lowest)},":")
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
 if old.level and Minimap.SetFrameLevel then Minimap:SetFrameLevel(old.level) end
 M.layerKey=nil;M.maskShape=nil
 if M.roundRing then M.roundRing:Hide() end
 M.hidden={};M.active=false;M.before=nil
 if M.dragHandle then M.dragHandle:Hide() end
 for _,proxy in pairs(M.launcherProxies or {}) do proxy:Hide() end
 if M.rim then M.rim:Hide() end
 if M.root then M.root:Hide() end
 if M.zoomOut then M.zoomOut:Hide();M.zoomIn:Hide() end
end
-- Map shape. Three explicit modes (setting zoneThemeMapShape, kept in step with the legacy zoneThemeMinimap switch):
--  square = square native map (mask replaced) inside the square Elwynn/Naxx frame;
--  round  = native round map (the client's own mask) with a round ring, only where the frame art is a separate piece (a square
--           frame can never surround a round map, and the identity-card layouts bake a square opening into the card);
--  native = the native map exactly as the client draws it, no FieldKit shape dressing.
-- M.shape is the mode really applied; a round request that this layout cannot honour is applied as native (never a square frame
-- over a round map) and M.shapeNote says why, so the settings label shows the truth.
function M.Requested()
 local db=FieldKitDB or {}
 if db.zoneThemeMinimap==false or db.zoneThemeMapShape=="native" then return "native" end
 if db.zoneThemeMapShape=="round" then return "round" end
 return "square"
end
function M.Effective()
 local want=M.Requested();M.shapeNote=nil
 if want=="round" then
  local R=FieldKitReferenceHUD
  -- Elwynn has a round dressing on every layout (a ring; on the identity-card layout the square map frame is cut away, only the
  -- zone and mode banners stay). Naxx has none yet: only where its map frame is a separate piece.
  local ok=R and R.active and R.layout and R.layout.rects and (R.layout.rects.mapArt~=nil or FieldKitTheme.zone=="elwynn")
  if not ok then M.shapeNote="round-unavailable";return "native" end
 end
 return want
end
local SQUARE_MASK="Interface\\Buttons\\WHITE8X8"
-- The mask is (re)asserted whenever the requested shape differs from what the client reports, so a shape changed behind our back
-- (another setting, another addon) is brought back in step at the next refresh instead of leaving a round map in a square frame.
function M.SetMask(shape)
 if not M.before then return false end
 local want=shape=="square" and SQUARE_MASK or M.before.mask
 if M.maskShape==shape and Minimap.GetMaskTexture then
  local ok,path=pcall(Minimap.GetMaskTexture,Minimap)
  if ok and type(path)=="string" and string.lower(path)~=string.lower(want) then M.maskShape=nil end
 end
 if M.maskShape==shape then return true end
 local ok,result=pcall(Minimap.SetMaskTexture,Minimap,want)
 if not ok or result==false then return false end
 M.maskShape=shape
 if Minimap:IsShown() then Minimap:Hide();Minimap:Show() end
 return true
end
function M.Apply(variant)
 local shape=M.Effective();M.shape=shape
 if shape=="native" then if M.active then M.Restore() end;M.reason=M.shapeNote or "Native map";return false end
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
  M.before={parent=parent,points=points,width=Minimap:GetWidth(),height=Minimap:GetHeight(),mask=mask,level=Minimap.GetFrameLevel and Minimap:GetFrameLevel(),scripts={},mouse=Minimap.IsMouseEnabled and Minimap:IsMouseEnabled(),movable=Minimap.IsMovable and Minimap:IsMovable()}
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
  M.maskShape=nil
  if not M.SetMask(shape) then M.reason="Square mask rejected";M.before=nil;return false end
  M.active=true;M.reason=nil
  for _,name in ipairs({"MinimapZoomIn","MinimapZoomOut"}) do local f=getglobal(name);if f then FieldKitThemeHUD.Save(f);f:SetParent(FieldKitThemeHUD.Hidden()) end end
  Minimap:SetParent(M.root)
  for i=1,table.getn(borderNames) do local f=getglobal(borderNames[i]);if f and f.SetAlpha then M.hidden[f]=f:GetAlpha();f:SetAlpha(0) end end
 end
 if not M.SetMask(shape) then M.Restore();M.reason="Square mask rejected";return false end
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
 M.root:SetMovable(true);M.Layers()
 if M.probe.ring then M.Ring(size/2,size/2) else M.RingRestore() end
 FieldKitTheme.Update(M.root);M.root:Show();return true
end
