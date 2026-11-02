-- CreedUI layout language, FieldKit Chronicle materials only.
-- Large run clock + explicit next-boss countdown (replaces the native clock HUD).
FieldKitBossTimeline={}
local B=FieldKitBossTimeline
local T=FieldKitTheme
local MAX_MARKS=10
local MAX_TICKS=14
local ROOT_H=92
local PAD=56
local MARK=16
local MARK_FINAL=20
local RAIL_H=10

local root,marks,ticks,rail,fill,callout,clockText,elapsedText,titleText,nextLabel
local hudClockHidden

local function Clock(sec)
 sec=math.max(0,math.floor((sec or 0)+.5))
 local m=math.floor(sec/60)
 return string.format("%d:%02d",m,sec-m*60)
end

local function PhaseOk()
 local ph=type(AZS_GetPhase)=="function" and AZS_GetPhase() or nil
 return ph=="playing" or ph=="paused" or ph=="dead" or ph=="victory"
end

local function RunNow()
 if type(AZS_GetRunTime)=="function" then
  local ok,t=pcall(AZS_GetRunTime)
  t=ok and tonumber(t) or nil
  if t and t>=0 then return t end
 end
 return type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or 0
end

local function ZoneTitle()
 if type(AZS_ZONE)=="table" then
  if type(AZS_ZONE.zname)=="string" and AZS_ZONE.zname~="" then return AZS_ZONE.zname end
  if type(AZS_ZONE.zone)=="string" and AZS_ZONE.zone~="" then return AZS_ZONE.zone end
 end
 return FieldKit_L("Schedule")
end

local function ReadSchedule()
 local out,n={},0
 local function push(at,name,final,state)
  if not at or at<0 or type(name)~="string" or name=="" then return end
  n=n+1;out[n]={at=at,name=name,final=final and true or false,state=state}
 end
 if type(AZS_SCHEDULE)=="table" then
  for i=1,math.min(32,table.getn(AZS_SCHEDULE)) do
   local e=AZS_SCHEDULE[i]
   if type(e)=="table" then
    push(tonumber(e.at or e[2]),type(e.name or e[3])=="string" and (e.name or e[3]) or nil,
     (e.final or e[4])==1 or (e.final or e[4])==true,e.state or e[5])
   end
  end
 end
 if type(AZS_GetUpcomingBosses)=="function" then
  local ok,list=pcall(AZS_GetUpcomingBosses)
  if ok and type(list)=="table" then
   for i=1,math.min(32,table.getn(list)) do
    local e=list[i]
    if type(e)=="table" then
     local at=tonumber(e.at)
     if not at and tonumber(e.left) then at=RunNow()+tonumber(e.left) end
     push(at,e.name,e.final,nil)
    end
   end
  end
 end
 -- Endless / rolling next boss (native clock source) even when a past schedule exists.
 if type(AZS_RUN)=="table" and type(AZS_RUN.nbn)=="string" and AZS_RUN.nbn~="" then
  local left=tonumber(AZS_RUN.nb)
  if left and left>=0 then push(RunNow()+left,AZS_RUN.nbn,false,"due") end
 end
 -- Deduplicate same name+at (±2s).
 local uniq,u={},0
 for i=1,n do
  local e=out[i];local skip
  for j=1,u do
   local p=uniq[j]
   if p.name==e.name and math.abs(p.at-e.at)<2 then skip=true;break end
  end
  if not skip then u=u+1;uniq[u]=e end
 end
 out,n=uniq,u
 for i=2,n do
  local e=out[i];local j=i-1
  while j>=1 and out[j].at>e.at do out[j+1]=out[j];j=j-1 end
  out[j+1]=e
 end
 local anyFinal=false
 for i=1,n do if out[i].final then anyFinal=true;break end end
 if n>0 and not anyFinal then out[n].final=true end
 return out,n
end

local function SyncClockHud(hide)
 if hide then
  if not hudClockHidden then
   if FieldKit.SetHudShown then FieldKit.SetHudShown("clock",false) end
   hudClockHidden=true
  end
 elseif hudClockHidden then
  if FieldKit.SetHudShown then FieldKit.SetHudShown("clock",true) end
  hudClockHidden=nil
 end
end

local function MakeMark(parent)
 local m=CreateFrame("Frame",nil,parent)
 m:SetWidth(MARK);m:SetHeight(MARK)
 local glow=m:CreateTexture(nil,"BACKGROUND")
 glow:SetTexture(T.media.."ChronicleSeal.tga")
 glow:SetVertexColor(.85,.71,.42,.35)
 glow:SetPoint("CENTER",m,"CENTER",0,0);glow:SetWidth(MARK+10);glow:SetHeight(MARK+10);m.glow=glow
 local gem=m:CreateTexture(nil,"ARTWORK")
 gem:SetTexture(T.media.."ChronicleSeal.tga")
 gem:SetAllPoints(m);m.gem=gem
 m:EnableMouse(true)
 m:SetScript("OnEnter",function()
  if not this.bossName then return end
  GameTooltip:SetOwner(this,"ANCHOR_BOTTOM")
  GameTooltip:SetText(this.bossName,1,.85,.55)
  if this.bossAt then GameTooltip:AddLine(FieldKit_L("Arrives at").." "..Clock(this.bossAt),.8,.8,.8) end
  if this.bossLeft and this.bossLeft>=0 then GameTooltip:AddLine(FieldKit_L("In").." "..Clock(this.bossLeft),.7,.85,1) end
  GameTooltip:Show()
 end)
 m:SetScript("OnLeave",function() GameTooltip:Hide() end)
 m:Hide()
 return m
end

function B.Ensure()
 if root then return root end
 root=CreateFrame("Frame","FieldKitBossTimelineFrame",UIParent)
 root:SetWidth(560);root:SetHeight(ROOT_H);root:SetFrameStrata("MEDIUM");root:SetFrameLevel(20)
 root:SetClampedToScreen(true);root:EnableMouse(true)
 T.Surface(root,"window",true)

 titleText=root:CreateFontString(nil,"OVERLAY","GameFontNormal")
 titleText:SetPoint("TOP",root,"TOP",0,-8)
 titleText:SetWidth(360);titleText:SetJustifyH("CENTER")
 T.Font(titleText,16,T.gold,true)

 elapsedText=root:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 elapsedText:SetPoint("TOPLEFT",root,"TOPLEFT",14,-28);T.Font(elapsedText,14,T.text)

 clockText=root:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 clockText:SetPoint("TOPRIGHT",root,"TOPRIGHT",-14,-28);T.Font(clockText,14,T.text)

 rail=CreateFrame("Frame",nil,root)
 rail:SetPoint("TOPLEFT",root,"TOPLEFT",PAD,-32)
 rail:SetPoint("TOPRIGHT",root,"TOPRIGHT",-PAD,-32)
 rail:SetHeight(RAIL_H)
 local railBg=rail:CreateTexture(nil,"BACKGROUND")
 railBg:SetAllPoints(rail);railBg:SetTexture("Interface\\Buttons\\WHITE8X8")
 railBg:SetVertexColor(.03,.035,.04,.95)
 local railMetal=rail:CreateTexture(nil,"BORDER")
 railMetal:SetAllPoints(rail)
 railMetal:SetTexture(T.media.."ChronicleGrain.tga");railMetal:SetVertexColor(.7,.55,.32,.55)
 local edgeT=rail:CreateTexture(nil,"ARTWORK")
 edgeT:SetTexture(T.gold[1],T.gold[2],T.gold[3])
 edgeT:SetPoint("BOTTOMLEFT",rail,"TOPLEFT",0,0);edgeT:SetPoint("BOTTOMRIGHT",rail,"TOPRIGHT",0,0);edgeT:SetHeight(2);edgeT:SetAlpha(.75)
 local edgeB=rail:CreateTexture(nil,"ARTWORK")
 edgeB:SetTexture(T.bronze[1],T.bronze[2],T.bronze[3])
 edgeB:SetPoint("TOPLEFT",rail,"BOTTOMLEFT",0,0);edgeB:SetPoint("TOPRIGHT",rail,"BOTTOMRIGHT",0,0);edgeB:SetHeight(2);edgeB:SetAlpha(.85)

 fill=CreateFrame("StatusBar",nil,rail)
 fill:SetAllPoints(rail)
 fill:SetMinMaxValues(0,1);fill:SetValue(0)
 fill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 fill:SetStatusBarColor(.78,.32,.22,1)
 local fillGrain=fill:CreateTexture(nil,"OVERLAY")
 fillGrain:SetAllPoints(fill);fillGrain:SetTexture(T.media.."ChronicleGrain.tga");fillGrain:SetAlpha(.4)

 ticks={}
 for i=1,MAX_TICKS do
  local tick=rail:CreateTexture(nil,"OVERLAY")
  tick:SetTexture(T.bronze[1],T.bronze[2],T.bronze[3])
  tick:SetWidth(1);tick:SetHeight(RAIL_H);tick:SetAlpha(.55);tick:Hide()
  ticks[i]=tick
 end

 -- No separate playhead: the fill edge is the "now" cue (avoids looking like a boss mark).

 -- Native-style next-boss line: name left, large countdown right.
 nextLabel=root:CreateFontString(nil,"OVERLAY","GameFontNormal")
 nextLabel:SetPoint("BOTTOMLEFT",root,"BOTTOMLEFT",16,12)
 nextLabel:SetWidth(340);nextLabel:SetJustifyH("LEFT")
 T.Font(nextLabel,14,T.gold,true)

 callout=root:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 callout:SetPoint("BOTTOMRIGHT",root,"BOTTOMRIGHT",-16,10)
 callout:SetJustifyH("RIGHT");T.Font(callout,20,{.95,.55,.32})
 root.callout=callout;root.nextLabel=nextLabel
 root.clockText=clockText;root.titleText=titleText;root.elapsedText=elapsedText
 marks={}
 for i=1,MAX_MARKS do marks[i]=MakeMark(root) end
 root.marks=marks

 root:SetMovable(true);root:RegisterForDrag("LeftButton")
 root:SetScript("OnDragStart",function()
  if FieldKitDB and FieldKitDB.windowsLocked and not FieldKit.layoutEditing then return end
  this:StartMoving()
 end)
 root:SetScript("OnDragStop",function()
  this:StopMovingOrSizing()
  if FieldKitDB then
   FieldKitDB.pos=FieldKitDB.pos or {}
   local x,y=this:GetCenter();local ux,uy=UIParent:GetCenter()
   if x and ux then FieldKitDB.pos.FieldKitBossTimelineFrame={x-ux,y-uy} end
  end
 end)
 if FieldKitDB and FieldKitDB.pos and FieldKitDB.pos.FieldKitBossTimelineFrame then
  root:ClearAllPoints()
  root:SetPoint("CENTER",UIParent,"CENTER",FieldKitDB.pos.FieldKitBossTimelineFrame[1] or 0,FieldKitDB.pos.FieldKitBossTimelineFrame[2] or 0)
 else
  root:ClearAllPoints();root:SetPoint("TOP",UIParent,"TOP",0,-6)
 end
 root:Hide()
 return root
end

local function QuietHud()
 return FieldKit.layoutEditing or (FieldKitPreview and FieldKitPreview.mode)
end

function B.Update()
 local db=FieldKitDB
 if not db or not db.bossTimeline then
  if not QuietHud() then SyncClockHud(false) end
  if root then root:Hide() end
  return
 end
 B.Ensure()
 local editing=FieldKit.layoutEditing
 if FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen() then
  if not QuietHud() then SyncClockHud(false) end
  root:Hide();return
 end
 if not PhaseOk() and not editing then
  if not QuietHud() then SyncClockHud(false) end
  root:Hide();return
 end
 local now=RunNow()
 local sched,n=ReadSchedule()
 local total=0
 for i=1,n do if sched[i].at>total then total=sched[i].at end end
 if total<=0 then total=math.max(now,1) end
 -- Keep the rail meaningful after the planned schedule while endless bosses continue.
 if now>total then total=now end
 local width=math.floor(FieldKit.Number(db.bossTimelineWidth,560,360,780))
 if root:GetWidth()~=width then root:SetWidth(width);T.Update(root) end
 if root:GetHeight()~=ROOT_H then root:SetHeight(ROOT_H);T.Update(root) end
 local barW=width-2*PAD
 local frac=math.min(1,math.max(0,now/math.max(total,1)))
 fill:SetValue(frac)
 fill:SetStatusBarColor(.72+.1*frac,.28+.08*frac,.18,1)
 elapsedText:SetText(Clock(now))
 clockText:SetText(Clock(total))
 titleText:SetText(ZoneTitle())

 local tickN=math.min(MAX_TICKS,math.max(4,math.floor(barW/40)))
 for i=1,tickN do
  local tick=ticks[i]
  local x=barW*(i/(tickN+1))
  tick:ClearAllPoints();tick:SetPoint("CENTER",rail,"LEFT",x,0);tick:Show()
 end
 for i=tickN+1,MAX_TICKS do ticks[i]:Hide() end

 local nextLeft,nextName
 local shown=0
 for i=1,n do
  local e=sched[i]
  local due=e.at>now+0.05
  local alive=e.state=="up"
  if due and (not nextLeft or e.at-now<nextLeft) then nextLeft=e.at-now;nextName=e.name end
  -- Past bosses stay off the rail; only upcoming / live marks remain.
  if not due and not alive then
   -- skip
  elseif shown<MAX_MARKS then
   local x=PAD+barW*math.min(1,math.max(0,e.at/math.max(total,1)))
   shown=shown+1
   local m=marks[shown]
   local size=e.final and MARK_FINAL or MARK
   m:SetWidth(size);m:SetHeight(size)
   if m.glow then m.glow:SetWidth(size+10);m.glow:SetHeight(size+10) end
   m:ClearAllPoints();m:SetPoint("CENTER",root,"TOPLEFT",x,-32-RAIL_H/2)
   if alive then
    m.gem:SetVertexColor(1,.48,.28,1);if m.glow then m.glow:SetVertexColor(1,.4,.2,.5) end
   else
    m.gem:SetVertexColor(1,.82,.48,1);if m.glow then m.glow:SetVertexColor(.85,.71,.42,.35) end
   end
   m.bossName=e.name;m.bossAt=e.at;m.bossLeft=e.at-now
   m:Show()
  end
 end
 for i=shown+1,MAX_MARKS do marks[i]:Hide() end

 if nextName and nextLeft then
  nextLabel:SetText(string.format(FieldKit_L("Next: %s"),nextName))
  callout:SetText(Clock(nextLeft))
 elseif editing and n==0 then
  FieldKit_Text(nextLabel,"Boss schedule timeline");callout:SetText("")
 else
  nextLabel:SetText("");callout:SetText("")
 end
 if not editing then SyncClockHud(true) end
 root:Show()
end

function B.RestoreHud()
 SyncClockHud(false)
end
