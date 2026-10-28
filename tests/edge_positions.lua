-- Replay native drop anchors, including adversarial center/scale coordinates.
-- This validates our persistence path, not the native client's clamp algorithm.
FieldKitDB={meterValues=3,linkLeftCards=true,linkRightCards=false,runModeCard=true}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
AZS_RUN.ph="playing";AZS_ZONE.heroic=2;update(FieldKitFrame,.3)
local stats=FieldKitStatsFrame
local center,screenCenter=stats.GetCenter,UIParent.GetCenter
function stats:GetCenter() error("Drag persistence must not read GetCenter") end
function UIParent:GetCenter() error("Drag persistence must not subtract viewport centers") end
FieldKit.layoutEditing=true
local edges={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
for i=1,table.getn(edges) do
 local edge=edges[i]
 this=stats;stats:GetScript("OnDragStart")()
 -- Native StartMoving/StopMoving supplies this anchor at a flush edge.
 stats:ClearAllPoints();stats:SetPoint(edge,UIParent,edge,0,0)
 stats:GetScript("OnDragStop")()
 local p,relative,rp,x,y=stats:GetPoint()
 assert(p==edge and relative==UIParent and rp==edge and x==0 and y==0)
 local saved=FieldKitDB.frameAnchors.FieldKitStatsFrame
 assert(saved[1]==edge and saved[2]==edge and saved[3]==0 and saved[4]==0)
 FieldKitUI.context.positions()
 local a,b,c,dx,dy=stats:GetPoint()
 assert(a==edge and b==UIParent and c==edge and dx==0 and dy==0,"Restoring moved a native edge anchor")
end
stats.GetCenter=center;UIParent.GetCenter=screenCenter

-- The proxy covers the actual group, permits a zero right inset and never eats input.
local S=FieldKitHudStack
assert(S.root:GetWidth()==S.width and S.root:GetHeight()==S.height and S.root.clamped)
assert(not S.root.mouseEnabled)
this=FieldKitLairFrame;FieldKitLairFrame:GetScript("OnDragStart")()
S.root:ClearAllPoints();S.root:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",0,-30)
FieldKitLairFrame:GetScript("OnDragStop")();FieldKit.layoutEditing=false;S.Apply()
local point,relative,rp,x,y=S.root:GetPoint()
assert(point=="TOPRIGHT" and relative==UIParent and rp=="TOPRIGHT" and x==0 and y==-30)
local record=FieldKitDB.frameAnchors.FieldKitLeftStack
assert(record[1]=="TOPRIGHT" and record[3]==0)
for i=1,table.getn(S.frames) do assert(S.frames[i].clamped==false) end
FieldKitDB.meterValues=1;S.Apply()
local a,b,c,dx,dy=S.root:GetPoint()
assert(a=="TOPRIGHT" and b==UIParent and c=="TOPRIGHT" and dx==0 and dy==-30,"Resize lost native right pinning")

-- Reset/Undo includes native anchor records, while older numeric positions survive.
local prior=FieldKitDB.pos.FieldKitStatsFrame
FieldKitUI.ResetPositions();assert(FieldKitDB.frameAnchors.FieldKitStatsFrame==nil)
FieldKitUI.UndoPositions()
local restored=FieldKitDB.frameAnchors.FieldKitStatsFrame
assert(restored[1]=="BOTTOMRIGHT" and restored[3]==0 and restored[4]==0)
assert(FieldKitDB.pos.FieldKitStatsFrame[1]==prior[1])
local _,_,_,rx,ry=stats:GetPoint();assert(rx==0 and ry==0)

assert(not FieldKitPositions.Valid({"BAD","TOP",0,0}))
assert(not FieldKitPositions.Valid({"TOP","TOP",0/0,0}))
assert(not FieldKitPositions.Valid({"TOP","TOP","12",0}))
