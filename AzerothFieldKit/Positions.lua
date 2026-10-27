-- Preserve native anchors after a drag. GetCenter() subtraction mixes coordinate
-- spaces on some UI scales; GetPoint() can be restored without that conversion.
FieldKitPositions={}
local P=FieldKitPositions
local points={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,
 BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
local fractions={TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1},LEFT={0,.5},CENTER={.5,.5},
 RIGHT={1,.5},BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0}}

function P.Valid(a)
 return type(a)=="table" and points[a[1]] and points[a[2]]
  and type(a[3])=="number" and type(a[4])=="number" and FieldKit.Number(a[3]) and FieldKit.Number(a[4])
  and math.abs(a[3])<=100000 and math.abs(a[4])<=100000
end

function P.Save(frame,topEdge)
 local point,relative,rp,x,y=frame:GetPoint(1)
 if relative and relative~=UIParent and relative~="UIParent" then return false end
 local a={point,rp or point,FieldKit.Number(x),FieldKit.Number(y)}
 if not P.Valid(a) then return false end
 if topEdge and fractions[point][2]==.5 then
  -- Stabilize a middle anchor as rows change; explicit top/bottom/right/left
  -- edge anchors retain their native semantics without any conversion.
  -- Only own height is needed: no screen-center/scale conversions.
  local f=fractions[point]
  local top=f[1]==1 and "TOPRIGHT" or (f[1]==.5 and "TOP" or "TOPLEFT")
  a={top,a[2],a[3],a[4]+(1-f[2])*frame:GetHeight()}
 end
 FieldKitDB.frameAnchors[frame:GetName()]=a
 return true
end

function P.Restore(frame)
 local a=FieldKitDB.frameAnchors[frame:GetName()]
 if not P.Valid(a) then return false end
 frame:ClearAllPoints();frame:SetPoint(a[1],UIParent,a[2],a[3],a[4]);return true
end
