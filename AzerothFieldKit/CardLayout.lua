-- Only FieldKit-owned HUD geometry is changed here. Dimensions are preferences,
-- not game/world coordinates. Row height has a readability floor; no data rows
-- are discarded to satisfy a smaller requested height. Defaults remain automatic.
FieldKitCardLayout={selected=1}
local C=FieldKitCardLayout
C.names={"FieldKitModeFrame","FieldKitMeterFrame","FieldKitTakenFrame","FieldKitLairFrame",
 "FieldKitGearFrame","FieldKitStatsFrame","FieldKitMoneyFrame"}
C.labels={"Run mode","Damage","Damage taken","Lairs","Accessories","Statistics","Gold and chest price"}

function C.ValidName(name)
 for i=1,table.getn(C.names) do if C.names[i]==name then return true end end
 return false
end

function C.MinimumWidth(name)
 if name=="FieldKitMeterFrame" then return FieldKit.MeterWidth(FieldKitDB.meterValues) end
 return name=="FieldKitMoneyFrame" and 320 or 220
end

function C.Width(frame,fallback)
 local size=FieldKitDB.cardSizes[frame:GetName()]
 return math.max(C.MinimumWidth(frame:GetName()),size and size.width or fallback)
end

-- Expand row spacing rather than stretching fonts, icons, or native artwork.
-- The caller supplies its current number of data rows on every content refresh.
function C.Rows(frame,natural,count,kind,collapsed)
 local name=frame:GetName();local size=FieldKitDB.cardSizes[name]
 frame.fieldkitNaturalHeight=natural;frame.fieldkitRowCount=count;frame.fieldkitRowKind=kind
 local padding=kind=="bar" and 28 or 14
 local minimum=padding+math.max(count,1)*(kind=="gear" and 16 or 14)
 frame.fieldkitMinimumHeight=minimum
 local height=size and size.height and math.max(minimum,size.height) or natural
 frame.fieldkitExpandedHeight=height
 frame:SetWidth(C.Width(frame,frame:GetWidth()))
 frame:SetHeight(collapsed and (kind=="bar" and 24 or 23) or height)
 local step=math.min(32,(height-padding)/math.max(count,1))
 local rows=frame.rows or frame.slots or {}
 for i=1,table.getn(rows) do
  local row=rows[i]
  if kind=="bar" then
   row:ClearAllPoints();row:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-22-step*(i-1))
   row:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-22-step*(i-1));row:SetHeight(math.max(12,step-2))
  elseif kind=="stats" then
   row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",frame,"TOPLEFT",9,-8-step*(i-1))
   row.value:ClearAllPoints();row.value:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-27,-8-step*(i-1))
   row.label:SetWidth((frame:GetWidth()-44)*.64);row.value:SetWidth((frame:GetWidth()-44)*.34)
   row.label:SetHeight(14);row.value:SetHeight(14);row.value:SetJustifyH("RIGHT")
  else
   row:ClearAllPoints();row:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-8-step*(i-1))
   row:SetPoint("RIGHT",frame,"RIGHT",i==1 and -26 or -6,0);row:SetHeight(math.max(14,step-2))
  end
 end
 FieldKitTheme.Update(frame)
 return height
end

function C.Money(frame)
 local size=FieldKitDB.cardSizes.FieldKitMoneyFrame
 if size then frame:SetWidth(C.Width(frame,frame:GetWidth())) end
 frame:SetHeight(size and size.height or 22)
 FieldKitTheme.Update(frame)
end

-- Same drag operation for a right-side group, without assigning gear's handlers
-- to stats forever. Unlinking restores each card's own saved native anchor.
function C.Initialize(makeMovable,place)
 C.place=place
 local stats,gear=FieldKitStatsFrame,FieldKitGearFrame
 local previous=FieldKitDB.pos.FieldKitRightStack or FieldKitDB.frameAnchors.FieldKitRightStack
 local root=CreateFrame("Frame","FieldKitRightStack",UIParent);C.root=root
 root.fieldkitTopLeftAnchor=true;root.fieldkitMouseProxy=true
 root:SetWidth(math.max(stats:GetWidth(),gear:GetWidth()));root:SetHeight(stats:GetHeight()+gear:GetHeight()+6)
 makeMovable(root,stats.azsDefault[1]-110,stats.azsDefault[2]+stats:GetHeight()/2+gear:GetHeight()+6,true)
 -- First migration keeps the stats card's visible position, even if the player
 -- had already pinned it to an edge. Only own-frame sizes enter this conversion.
 if not previous then
  local p,r,rp,x,y=stats:GetPoint(1)
  local fractions={TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1},LEFT={0,.5},CENTER={.5,.5},
   RIGHT={1,.5},BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0}}
  if fractions[p] and (r==UIParent or r=="UIParent" or not r) then
   root:ClearAllPoints();root:SetPoint(p,UIParent,rp or p,x+(root:GetWidth()-stats:GetWidth())*fractions[p][1],
    y+(root:GetHeight()-stats:GetHeight())*fractions[p][2])
   FieldKitPositions.Save(root,true);FieldKitPositions.Restore(root)
  end
 end
 root:EnableMouse(false)
 C.Bind(gear);C.Bind(stats)
 C.ApplyRight()
end

function C.Bind(frame)
 local start,stop=frame:GetScript("OnDragStart"),frame:GetScript("OnDragStop")
 frame:SetScript("OnDragStart",function()
  if FieldKitDB.linkRightCards then C.root:GetScript("OnDragStart")() else start() end
 end)
 frame:SetScript("OnDragStop",function()
  if FieldKitDB.linkRightCards then C.root:GetScript("OnDragStop")() else stop() end
 end)
end

function C.ApplyRight()
 if not C.root then return end
 local frames={FieldKitGearFrame,FieldKitStatsFrame}
 if not FieldKitDB.linkRightCards then
  if C.linked then
   for i=1,2 do C.place(frames[i]);frames[i]:SetClampedToScreen(true) end
  end
  C.linked=false;return
 end
 C.linked=true
 local height,width,shown=0,1,0
 for i=1,2 do
  local f=frames[i];f:SetClampedToScreen(false)
  if f:IsShown() then
   if shown>0 then height=height+6 end
   local p,r,rp,x,y=f:GetPoint(1)
   if p~="TOPLEFT" or r~=C.root or rp~="TOPLEFT" or x~=0 or y~=-height then
    f:ClearAllPoints();f:SetPoint("TOPLEFT",C.root,"TOPLEFT",0,-height)
   end
   width=math.max(width,f:GetWidth());height=height+f:GetHeight();shown=shown+1
  end
 end
 local changed=C.root:GetWidth()~=width or C.root:GetHeight()~=math.max(1,height)
 C.root:SetWidth(width);C.root:SetHeight(math.max(1,height))
 local anchor=FieldKitDB.frameAnchors.FieldKitRightStack
 if not C.root.azsMoving and (changed or anchor~=C.anchor or C.sw~=UIParent:GetWidth() or C.sh~=UIParent:GetHeight()) then
  C.place(C.root);C.anchor=anchor;C.sw=UIParent:GetWidth();C.sh=UIParent:GetHeight()
 end
end

function C.Refresh()
 if FieldKit_RefreshInterfaceLanguage then FieldKit_RefreshInterfaceLanguage() end
 C.ApplyRight()
end

function C.Frame() return getglobal(C.names[C.selected]) end

function C.UpdateDock()
 local ui=FieldKitUI
 if not ui or not ui.groupLeft then return end
 FieldKit_Text(ui.groupLeft,FieldKitDB.linkLeftCards and "Left: grouped" or "Left: independent")
 FieldKit_Text(ui.groupRight,FieldKitDB.linkRightCards and "Right: grouped" or "Right: independent")
end

function C.SetDimension(key,value)
 local name=C.names[C.selected];local size=FieldKitDB.cardSizes[name] or {}
 size[key]=value;FieldKitDB.cardSizes[name]=size;C.Refresh()
end

-- One selector owns both sliders: no duplicate controls per card, no frame
-- recreation on selection, and no settings write while merely refreshing UI.
function C.Options()
 return {
  {kind="choice",label="Window to resize",values=C.labels,
   get=function() return C.selected end,set=function(v) C.selected=v end},
  {kind="check",label="Automatic size for this window",tip="Clear this window's custom dimensions. Height always keeps enough room for every visible row.",
   get=function() return FieldKitDB.cardSizes[C.names[C.selected]]==nil end,
   set=function(v)
    local f=C.Frame()
    if v then FieldKitDB.cardSizes[C.names[C.selected]]=nil
    else FieldKitDB.cardSizes[C.names[C.selected]]={width=f:GetWidth(),height=f.fieldkitExpandedHeight or f:GetHeight()} end
    if v then f:SetWidth(C.MinimumWidth(f:GetName())) end
    C.Refresh()
   end},
  {kind="slider",label="Window width",min=220,max=800,step=1,
   get=function() return C.Frame():GetWidth() end,
   format=function(v) return FieldKit_L("Window width")..": "..v.." px" end,
   set=function(v) C.SetDimension("width",math.max(C.MinimumWidth(C.names[C.selected]),v)) end},
  {kind="slider",label="Window height",min=22,max=800,step=1,
   get=function() local f=C.Frame();return f.fieldkitExpandedHeight or f:GetHeight() end,
   format=function(v) return FieldKit_L("Window height")..": "..v.." px" end,
   set=function(v)
    local f=C.Frame();C.SetDimension("height",math.max(f.fieldkitMinimumHeight or 22,v))
   end},
 }
end
