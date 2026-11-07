-- Own the native map geometry reversibly, never substitute a painted fake map.
FieldKitThemeMinimap={active=false,hidden={}}
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
function M.Restore()
 if not M.active then return end
 local old=M.before
 if old.scripts then for _,event in ipairs({"OnDragStart","OnDragStop","OnMouseDown","OnMouseUp"}) do Minimap:SetScript(event,old.scripts[event]) end end
 if old.movable~=nil then Minimap:SetMovable(old.movable) end
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
  M.before={parent=parent,points=points,width=Minimap:GetWidth(),height=Minimap:GetHeight(),mask=mask,scripts={},movable=Minimap.IsMovable and Minimap:IsMovable()}
  for _,event in ipairs({"OnDragStart","OnDragStop","OnMouseDown","OnMouseUp"}) do M.before.scripts[event]=Minimap:GetScript(event) end
  local function StartMapDrag()
   if FieldKitDB.windowsLocked then return end
   local R=FieldKitReferenceHUD;local target=R and R.active and not R.layout.rects.mapArt and FieldKitThemeHUD.identity or M.root
   if target then M.dragTarget=target;target.azsMoving=true;target:StartMoving() end
  end
  local function FinishMapDrag() if M.dragTarget then FieldKitZoneThemes.Finish(M.dragTarget);M.dragTarget=nil end end
  Minimap:SetMovable(false);Minimap:RegisterForDrag("LeftButton")
  Minimap:SetScript("OnDragStart",StartMapDrag);Minimap:SetScript("OnDragStop",FinishMapDrag)
  Minimap:SetScript("OnMouseDown",function() if arg1=="LeftButton" and not FieldKitDB.windowsLocked then StartMapDrag() elseif M.before.scripts.OnMouseDown then M.before.scripts.OnMouseDown() end end)
  Minimap:SetScript("OnMouseUp",function() if M.dragTarget then FinishMapDrag() elseif M.before.scripts.OnMouseUp then M.before.scripts.OnMouseUp() end end)
  if not M.root then
   M.root=CreateFrame("Frame","FieldKitThemeMap",UIParent);M.root:SetFrameStrata("MEDIUM")
   FieldKitTheme.Surface(M.root,"card",true);FieldKitZoneThemes.Bind(M.root)
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
 local size=math.min(230,math.max(160,UIParent:GetWidth()*.13))
 local zone=FieldKitTheme.zone
 if not M.root.azsMoving then M.root:SetWidth(size+16);M.root:SetHeight(size+16) end
 if (variant=="complete" and zone=="elwynn") or (variant=="alternative" and zone=="naxx") then FieldKitZoneThemes.Place(M.root,"TOPLEFT",UIParent,"TOPLEFT",20,-18)
 elseif variant=="alternative" then FieldKitZoneThemes.Place(M.root,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-20,66)
 else FieldKitZoneThemes.Place(M.root,"TOPRIGHT",UIParent,"TOPRIGHT",-20,-38) end
 Minimap:ClearAllPoints();Minimap:SetPoint("CENTER",M.root,"CENTER",0,0);Minimap:SetWidth(size);Minimap:SetHeight(size)
 local clock=getglobal("GameTimeFrame")
 if clock then FieldKitThemeHUD.Anchor(clock,"TOPRIGHT",M.root,"TOPRIGHT",0,0);clock:SetScale(.75) end
 FieldKitTheme.Update(M.root);M.root:Show();return true
end
