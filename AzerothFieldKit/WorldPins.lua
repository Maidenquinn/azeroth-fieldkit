-- Native world coordinates, as also used by Cadoky's LuckyOdds:
-- https://github.com/cadoky/LuckyOdds (consulted 2026-10-22).
-- Independent implementation for FieldKit; no LuckyOdds dependency.
-- World x points north, world y points west. A guardian marker denotes its LAIR.
local chests,guardians={},{}
local yards={[0]=466.6667,400,333.3333,266.6667,200,133.3333}
local rotationMissing=false
-- Detect rotation safely; unsupported rotateMinimap is cached as absent.
local function Rotating()
 if rotationMissing or type(GetCVar)~="function" then return false end
 local ok,v=pcall(GetCVar,"rotateMinimap")
 if not ok or v==nil then rotationMissing=true;return false end
 return v=="1" or v==1 or v==true
end
-- Use the optional native shape API; no dependency on another UI addon.
local function Square()
 if type(GetMinimapShape)=="function" then
  local ok,s=pcall(GetMinimapShape)
  if ok and s then return s=="SQUARE" end
 end
 return false -- Unknown shapes use the native round-map assumption.
end
-- Allocate one reusable native chest/lair icon and local tooltip.
local function NewPin(list,i,kind)
 local p=CreateFrame("Frame","FieldKit"..kind.."Pin"..i,Minimap)
 p:SetWidth(16);p:SetHeight(16);p:SetFrameLevel(Minimap:GetFrameLevel()+5)
 p.icon=p:CreateTexture(nil,"OVERLAY");p.icon:SetAllPoints(p)
 if kind=="Chest" then
  p.icon:SetTexture("Interface\\Icons\\INV_Box_02");p.icon:SetTexCoord(.08,.92,.08,.92)
 else
  p.icon:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
  p.timer=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  p.timer:SetPoint("CENTER",p,"CENTER",0,0)
 end
 p:EnableMouse(1)
 p:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_LEFT");FieldKit_Text(GameTooltip,this.title or "FieldKit",1,.82,0)
  if this.detail then GameTooltip:AddLine(this.detail,1,1,1,1) end
  if this.dist then GameTooltip:AddLine(math.floor(this.dist+.5)..FieldKit_L(" yd"),1,1,1) end
  if this.edge then GameTooltip:AddLine(FieldKit_L("Direction only: beyond minimap range"),1,.8,.3) end
  GameTooltip:Show()
 end)
 p:SetScript("OnLeave",function() GameTooltip:Hide() end)
 p:Hide();list[i]=p;return p
end
-- Hide the pool first so missing native entries cannot leave stale markers.
local function Hide(list)
 for i=1,table.getn(list) do list[i]:Hide() end
end
-- Project finite native world coordinates, clamping out-of-range pins to the edge.
local function Place(p,e,px,py,scale,square)
 local x,y=FieldKit.Number(e.x),FieldKit.Number(e.y)
 if not x or not y then return false end
 local east,north=py-y,x-px
 local ox,oy=east*scale,north*scale
 local reach=square and math.max(math.abs(ox),math.abs(oy)) or math.sqrt(ox*ox+oy*oy)
 local edge=Minimap:GetWidth()/2-9
 if edge<=0 then return false end
 p.edge=reach>edge
 if p.edge then ox=ox/reach*edge;oy=oy/reach*edge end
 p.dist=math.sqrt(east*east+north*north)
 p:SetAlpha(p.edge and .65 or 1)
 p:ClearAllPoints();p:SetPoint("CENTER",Minimap,"CENTER",ox,oy);p:Show()
 return true
end
-- Format an observed countdown; this does not schedule or predict a spawn.
local function Clock(sec)
 sec=math.ceil(sec)
 return math.floor(sec/60)..":"..string.format("%02d",math.mod(sec,60))
end
-- Refresh at most 128 chest and 128 guardian-lair pins; both options are independent.
function FieldKit_UpdateWorldPins()
 Hide(chests);Hide(guardians)
 if not FieldKitDB or not Minimap or not Minimap:IsShown() or type(AZS_GetPhase)~="function" or not AZS_GetPhase() or type(AZS_RUN)~="table" then return end
 local px,py=FieldKit.Number(AZS_RUN.px),FieldKit.Number(AZS_RUN.py)
 if not px or not py or Rotating() then return end
 local span=yards[Minimap:GetZoom() or 0]
 if not span then return end
 local scale,square=Minimap:GetWidth()/span,Square()
 if FieldKitDB.chestPins and type(AZS_CHESTS)=="table" then
  for i=1,math.min(128,table.getn(AZS_CHESTS)) do
   local p=chests[i] or NewPin(chests,i,"Chest")
   p.title=FieldKit_L("Battleground Cache");p.detail=nil
   Place(p,AZS_CHESTS[i],px,py,scale,square)
  end
 end
 if FieldKitDB.guardianPins==nil then FieldKitDB.guardianPins=false end
 if FieldKitDB.guardianPins and type(AZS_LAIRS)=="table" then
  for i=1,math.min(128,table.getn(AZS_LAIRS)) do
   local l=AZS_LAIRS[i]
   local up=l.state=="asleep" or l.state=="awake"
   local left=tonumber(l.left) or -1
   if up or left>=0 then
    local p=guardians[i] or NewPin(guardians,i,"Guardian")
    p.title=l.name or FieldKit_L("Guardian")
    if up then
     p.icon:Show();p.timer:Hide()
     if l.state=="awake" then p.icon:SetVertexColor(1,.25,.25) else p.icon:SetVertexColor(1,1,1) end
     p.detail=l.state=="awake" and FieldKit_L("Lair: guardian fighting (not its moving position)") or FieldKit_L("Lair: guardian asleep")
    else
     -- AZSLAIRS supplies the countdown once/second when changing. Do not subtract
     -- wall-clock time: the official run clock stops while choosing or paused.
     p.icon:Hide();FieldKit_Text(p.timer,left>0 and Clock(left) or "?");p.timer:SetTextColor(1,.6,.15);p.timer:Show()
     p.detail=left>0 and (FieldKit_L("Lair empty; return in ")..Clock(left)) or FieldKit_L("Awaiting native return confirmation")
    end
    Place(p,l,px,py,scale,square)
   end
  end
 end
end
