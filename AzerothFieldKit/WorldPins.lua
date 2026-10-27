-- Native world coordinates, as also used by Cadoky's LuckyOdds:
-- https://github.com/cadoky/LuckyOdds (consulted 2026-10-22).
-- Independent implementation for MASH; no LuckyOdds dependency.
-- World x points north, world y points west. A guardian marker denotes its LAIR.
local chests,guardians={},{}
local yards={[0]=466.6667,400,333.3333,266.6667,200,133.3333}
local rotationMissing=false
local function Rotating()
 if rotationMissing or type(GetCVar)~="function" then return false end
 local ok,v=pcall(GetCVar,"rotateMinimap")
 if not ok or v==nil then rotationMissing=true;return false end
 return v=="1" or v==1 or v==true
end
local function Square()
 if type(GetMinimapShape)=="function" then
  local ok,s=pcall(GetMinimapShape)
  if ok and s then return s=="SQUARE" end
 end
 return DFRL~=nil
end
local function NewPin(list,i,kind)
 local p=CreateFrame("Frame","MASH"..kind.."Pin"..i,Minimap)
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
  GameTooltip:SetOwner(this,"ANCHOR_LEFT");MASH_Text(GameTooltip,this.title or "MASH",1,.82,0)
  if this.detail then GameTooltip:AddLine(this.detail,1,1,1,1) end
  if this.dist then GameTooltip:AddLine(math.floor(this.dist+.5)..MASH_L(" yd"),1,1,1) end
  if this.edge then GameTooltip:AddLine(MASH_L("Direction only: beyond minimap range"),1,.8,.3) end
  GameTooltip:Show()
 end)
 p:SetScript("OnLeave",function() GameTooltip:Hide() end)
 p:Hide();list[i]=p;return p
end
local function Hide(list)
 for i=1,table.getn(list) do list[i]:Hide() end
end
local function Place(p,e,px,py,scale,square)
 local x,y=tonumber(e.x),tonumber(e.y)
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
local function Clock(sec)
 sec=math.ceil(sec)
 return math.floor(sec/60)..":"..string.format("%02d",math.mod(sec,60))
end
function MASH_UpdateWorldPins()
 Hide(chests);Hide(guardians)
 if not MASHDB or not Minimap or not Minimap:IsShown() or type(AZS_GetPhase)~="function" or not AZS_GetPhase() or type(AZS_RUN)~="table" then return end
 local px,py=tonumber(AZS_RUN.px),tonumber(AZS_RUN.py)
 if not px or not py or Rotating() then return end
 local span=yards[Minimap:GetZoom() or 0]
 if not span then return end
 local scale,square=Minimap:GetWidth()/span,Square()
 if MASHDB.chestPins and type(AZS_CHESTS)=="table" then
  for i=1,math.min(128,table.getn(AZS_CHESTS)) do
   local p=chests[i] or NewPin(chests,i,"Chest")
   p.title=MASH_L("Battleground Cache");p.detail=nil
   Place(p,AZS_CHESTS[i],px,py,scale,square)
  end
 end
 if MASHDB.guardianPins==nil then MASHDB.guardianPins=true end
 if MASHDB.guardianPins and type(AZS_LAIRS)=="table" then
  for i=1,math.min(128,table.getn(AZS_LAIRS)) do
   local l=AZS_LAIRS[i]
   local up=l.state=="asleep" or l.state=="awake"
   local left=tonumber(l.left) or -1
   if up or left>=0 then
    local p=guardians[i] or NewPin(guardians,i,"Guardian")
    p.title=l.name or MASH_L("Guardian")
    if up then
     p.icon:Show();p.timer:Hide()
     if l.state=="awake" then p.icon:SetVertexColor(1,.25,.25) else p.icon:SetVertexColor(1,1,1) end
     p.detail=l.state=="awake" and MASH_L("Lair: guardian fighting (not its moving position)") or MASH_L("Lair: guardian asleep")
    else
     -- Native countdown is extrapolated only up to 1.5 seconds, then waits for fresh data.
     if left>0 and type(AZS_LAIRS_UPDATED)=="number" then left=math.max(0,left-math.min(1.5,math.max(0,GetTime()-AZS_LAIRS_UPDATED))) end
     p.icon:Hide();MASH_Text(p.timer,left>0 and Clock(left) or "?");p.timer:SetTextColor(1,.6,.15);p.timer:Show()
     p.detail=left>0 and (MASH_L("Lair empty; return in ")..Clock(left)) or MASH_L("Awaiting native return confirmation")
    end
    Place(p,l,px,py,scale,square)
   end
  end
 end
end
