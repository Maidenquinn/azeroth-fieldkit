-- Tabbed combat meter with optional detached windows, reset, and spell hit tips.
-- Builds on FieldKitMeterFrame / FieldKitTakenFrame without removing them.
FieldKitMeterSuite={}
local S=FieldKitMeterSuite
local L=FieldKitMeterLedger
local ROWS=8
local views=L.views
local detached={}

local function DB() return FieldKitDB end

function S.View()
 local v=DB() and DB().meterViewKey
 if type(v)=="string" then
  for i=1,table.getn(views) do if views[i]==v then return v,i end end
 end
 local mode=FieldKitMeters and FieldKitMeters.Mode and FieldKitMeters.Mode() or 1
 return views[mode] or "damage",mode
end

function S.SetView(key)
 if not DB() then return end
 for i=1,table.getn(views) do
  if views[i]==key then
   if DB().meterViewKey~=key then
    DB().meterPartyOwner=nil
    if L.ClearHidden then L.ClearHidden(DB().meterViewKey) end
   end
   DB().meterViewKey=key;DB().meterView=math.min(i,3)
   if FieldKitPartyDetails then FieldKitPartyDetails.Close() end
   S.Update(true);return
  end
 end
end

function S.SetSort(key)
 if not DB() or type(key)~="string" then return end
 if DB().meterSortKey==key then DB().meterSortAsc=not DB().meterSortAsc
 else DB().meterSortKey=key;DB().meterSortAsc=false end
 S.Update(true)
end

function S.SetHealDone(on)
 if not DB() then return end
 local next=on and true or false
 if (DB().meterHealDone and true or false)~=next then
  if L.ClearHidden then L.ClearHidden("healing") end
 end
 DB().meterHealDone=next
 S.Update(true)
end

function S.DrillParty(ownerId)
 if not DB() then return end
 if type(ownerId)~="string" or ownerId=="" then return end
 if L.ClearHidden then L.ClearHidden("party") end
 DB().meterPartyOwner=ownerId
 S.Update(true)
end

function S.PartyBack()
 if not DB() then return end
 if L.ClearHidden then L.ClearHidden("party") end
 DB().meterPartyOwner=nil
 S.Update(true)
end

function S.DetachKey(view)
 return "meterDetach_"..view
end

function S.IsDetached(view)
 return DB() and DB()[S.DetachKey(view)] and true or false
end

function S.SetDetached(view,on)
 if not DB() then return end
 DB()[S.DetachKey(view)]=on and true or nil
 S.EnsureDetach(view)
 S.Update(true)
end

local function Short(n)
 if not n then return "?" end
 n=math.floor(n+.5)
 if n>=1000000 then return string.format("%.1fM",n/1000000) end
 if n>=1000 then return string.format("%.1fk",n/1000) end
 return tostring(n)
end

local function SyncSubChrome(frame,view)
 local sub=frame.fieldkitSubChrome
 if not sub then return 0 end
 local heal=view=="healing"
 local drilled=view=="party" and DB() and type(DB().meterPartyOwner)=="string" and DB().meterPartyOwner~=""
 if not heal and not drilled then sub:Hide();return 0 end
 sub:Show()
 if heal then
  sub.recv:Show();sub.done:Show();sub.back:Hide()
  local on=DB() and DB().meterHealDone
  if on then sub.done:SetBackdropColor(.45,.28,.08,.85);sub.recv:SetBackdropColor(0,0,0,.55)
  else sub.recv:SetBackdropColor(.45,.28,.08,.85);sub.done:SetBackdropColor(0,0,0,.55) end
 else
  sub.recv:Hide();sub.done:Hide();sub.back:Show()
  sub.back:SetBackdropColor(.45,.28,.08,.85)
 end
 return 16
end

local function Paint(frame,view,force)
 if not frame then return end
 local lines,total,rate,known=L.Read(view)
 FieldKit_Text(frame.title,FieldKit_L(L.labels[1]))
 for i=1,table.getn(views) do if views[i]==view then FieldKit_Text(frame.title,FieldKit_L(L.labels[i]));break end end
 if view=="party" and DB() and type(DB().meterPartyOwner)=="string" and DB().meterPartyOwner~="" then
  FieldKit_Text(frame.title,"Party spells")
 end
 frame.fieldkitMeterView=view
 local base=FieldKit.MeterWidth and FieldKit.MeterWidth(DB().meterValues) or 220
 if frame.fieldkitTabs then base=math.max(base,320) end
 -- Extra room so kill counts never crowd spell names / damage digits.
 if view=="damage" or view=="boss" then base=math.max(base,340) end
 local width=FieldKitCardLayout and FieldKitCardLayout.Width(frame,base) or base
 if frame:GetWidth()~=width then frame:SetWidth(width);if FieldKitTheme then FieldKitTheme.Update(frame) end end
 local rateLabel=view=="healing" and "hps" or (view=="kills" and "" or "dps")
 if known then
  local right=Short(total)
  if rate and rateLabel~="" then right=right.."  ("..Short(rate).." "..FieldKit_L(rateLabel)..")" end
  frame.total:SetText(right)
 else FieldKit_Text(frame.total,"Not provided") end
 local top=lines[1] and lines[1].dmg or 1
 local n=math.min(table.getn(lines),table.getn(frame.rows))
 local mode=DB().meterValues or 3
 local showKills=false
 if view=="damage" or view=="boss" then
  for i=1,n do if (lines[i].kills or 0)>0 then showKills=true;break end end
 end
 local subH=SyncSubChrome(frame,view)
 local headerH=frame.fieldkitHeaderHeight or 0
 if frame.fieldkitColHeader then
  if view=="kills" then
   frame.fieldkitColHeader:Hide();headerH=0
  else
   frame.fieldkitColHeader:ClearAllPoints()
   frame.fieldkitColHeader:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-22-subH)
   frame.fieldkitColHeader:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-22-subH)
   FieldKit.UpdateMeterHeaders(frame.fieldkitColHeader,mode,width,showKills,rateLabel~="" and rateLabel or nil)
   headerH=frame.fieldkitHeaderHeight or 14
  end
 end
 local y0=22+subH+headerH
 for i=1,n do
  local line,row=lines[i],frame.rows[i]
  row.fieldkitLine=line;row.fieldkitSpell=line.name;row.fieldkitMeterView=view
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-y0-15*(i-1))
  row:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-y0-15*(i-1))
  row:SetValue((line.dmg or 0)/math.max(top or 0,1))
  if view=="taken" then row:SetStatusBarColor(.75,.1,.1,.55)
  elseif view=="healing" then row:SetStatusBarColor(.2,.7,.2,.55)
  elseif view=="party" then row:SetStatusBarColor(.25,.45,.9,.55)
  elseif line.proc==1 then row:SetStatusBarColor(.25,.45,.9,.55)
  else row:SetStatusBarColor(.8,.55,.2,.55) end
  row.label:SetText(line.name)
  if view=="kills" then
   row.value:Show();row.value:SetText(tostring(line.dmg or 0))
   if row.meterColumns then for j=1,3 do row.meterColumns[j]:Hide() end end
   if row.killColumn then row.killColumn:Hide() end
  else
   FieldKit.UpdateMeterColumns(row,line,mode,width,rateLabel~="" and rateLabel or nil)
  end
  row:Show()
 end
 for i=n+1,table.getn(frame.rows) do frame.rows[i]:Hide();frame.rows[i].fieldkitSpell=nil;frame.rows[i].fieldkitMeterView=nil end
 if n==0 then
  local row=frame.rows[1]
  row.fieldkitSpell=nil;row.fieldkitLine=nil;row.fieldkitMeterView=view
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-y0)
  row:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-y0)
  row:SetValue(0)
  FieldKit_Text(row.label,known and "No data yet" or "Meter data not provided")
  if row.meterColumns then for j=1,3 do row.meterColumns[j]:Hide() end end
  if row.killColumn then row.killColumn:Hide() end
  row.value:Hide();row.value:SetText("");row:Show();n=1
 end
 -- Fit like FieldKit FitRows without depending on locals.
 frame.mashVisibleRows=n
 local height=28+subH+headerH+(frame.fieldkitFooterHeight or 22)+15*math.max(n,1)
 frame.mashExpandHeight=height
 if frame.mashCollapsed then
  frame:SetHeight(24);frame.total:Hide()
  if frame.fieldkitColHeader then frame.fieldkitColHeader:Hide() end
 else frame:SetHeight(height);frame.total:Show() end
 if FieldKitCardLayout and FieldKitCardLayout.Rows then
  frame.mashExpandHeight=FieldKitCardLayout.Rows(frame,height,n,"bar",frame.mashCollapsed)
 end
 frame:Show()
end

function S.BindSpellTip(row)
 if row.fieldkitSpellTipBound then return end
 row.fieldkitSpellTipBound=true
 row:EnableMouse(true)
 local prevEnter,prevLeave=row:GetScript("OnEnter"),row:GetScript("OnLeave")
 local prevUp=row:GetScript("OnMouseUp")
 row:SetScript("OnEnter",function()
  if prevEnter then prevEnter() end
  -- Tip after PartyDetails open so Max Hit stats stay on GameTooltip.
  local tipped=false
  if DB() and DB().meterSpellTips~=false and this.fieldkitSpell then tipped=L.ShowTip(this) end
  if not tipped then
   GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
   if this.fieldkitSpell then FieldKit_Text(GameTooltip,this.fieldkitSpell,1,.82,0) end
  end
  if this.fieldkitLine and this.fieldkitLine.name then
   GameTooltip:AddLine(" ",.5,.5,.5)
   local view=this.fieldkitMeterView or S.View()
   if view=="party" and not (DB() and DB().meterPartyOwner) and this.fieldkitLine.ownerId then
    GameTooltip:AddLine(FieldKit_L("Left-click: ally spell breakdown."),.7,.85,1,true)
   end
   GameTooltip:AddLine(FieldKit_L("Right-click: hide row (total unchanged)."),.55,.5,.42,true)
  end
  GameTooltip:Show()
 end)
 row:SetScript("OnLeave",function()
  GameTooltip:Hide()
  if prevLeave then prevLeave() end
 end)
 row:SetScript("OnMouseUp",function()
  if prevUp then prevUp() end
  local view=this.fieldkitMeterView or S.View()
  local line=this.fieldkitLine
  if arg1=="RightButton" then
   if line and line.name and L.ToggleHide then
    L.ToggleHide(view,line.name);S.Update(true)
   end
   return
  end
  if arg1=="LeftButton" and view=="party" and line and line.ownerId and not (DB() and DB().meterPartyOwner) then
   S.DrillParty(line.ownerId)
  end
 end)
end

local function MakeSortHeader(parent,key,justify)
 local b=CreateFrame("Button",nil,parent)
 b:SetHeight(12)
 local t=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 t:SetAllPoints(b);t:SetJustifyH(justify or "LEFT")
 if key=="kills" then t:SetTextColor(1,.82,.45) else t:SetTextColor(.75,.75,.78) end
 b.text=t;b.sortKey=key
 b:SetScript("OnClick",function() S.SetSort(this.sortKey) end)
 b:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_TOP")
  GameTooltip:SetText(FieldKit_L("Click to sort by this column."),1,1,1)
  GameTooltip:Show()
 end)
 b:SetScript("OnLeave",function() GameTooltip:Hide() end)
 return b
end

local function EnsureChrome(frame)
 if frame.fieldkitMeterChrome then return end
 frame.fieldkitMeterChrome=true
 frame.fieldkitFooterHeight=22
 frame.fieldkitHeaderHeight=14
 local header=CreateFrame("Frame",frame:GetName().."ColHeader",frame)
 header:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-22)
 header:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-22)
 header:SetHeight(12)
 header.spell=MakeSortHeader(header,"name","LEFT")
 header.cols={MakeSortHeader(header,"dmg","RIGHT"),MakeSortHeader(header,"dps","RIGHT"),MakeSortHeader(header,"share","RIGHT")}
 header.kills=MakeSortHeader(header,"kills","RIGHT")
 frame.fieldkitColHeader=header
 -- Healing received/done + party back strip (above column headers when needed).
 local sub=CreateFrame("Frame",frame:GetName().."SubChrome",frame)
 sub:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-20)
 sub:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-20)
 sub:SetHeight(16);sub:Hide();frame.fieldkitSubChrome=sub
 local function SubBtn(label,w)
  local b=CreateFrame("Button",nil,sub)
  b:SetWidth(w or 44);b:SetHeight(14)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
  b:SetBackdropColor(0,0,0,.55);b:SetBackdropBorderColor(.5,.5,.5,.8)
  local t=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");t:SetAllPoints(b);FieldKit_Text(t,label);b.label=t
  return b
 end
 local recv=SubBtn("Recv",40);recv:SetPoint("LEFT",sub,"LEFT",0,0)
 recv:SetScript("OnClick",function() S.SetHealDone(false) end)
 local done=SubBtn("HealDone",44);done:SetPoint("LEFT",recv,"RIGHT",3,0)
 done:SetScript("OnClick",function() S.SetHealDone(true) end)
 local back=SubBtn("PartyBack",44);back:SetPoint("LEFT",sub,"LEFT",0,0)
 back:SetScript("OnClick",function() S.PartyBack() end)
 sub.recv,sub.done,sub.back=recv,done,back
 local tabs=CreateFrame("Frame",frame:GetName().."Tabs",frame)
 tabs:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",4,3)
 tabs:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-50,3)
 tabs:SetHeight(18);frame.fieldkitTabs=tabs;tabs.buttons={}
 local labels={"Dmg","Heal","Boss","Taken","Party","Kills"}
 for i=1,table.getn(views) do
  local key=views[i]
  local fullLabel=L.labels[i] or labels[i]
  local b=CreateFrame("Button",nil,tabs)
  b:SetWidth(36);b:SetHeight(16);b:SetPoint("LEFT",tabs,"LEFT",(i-1)*38,0)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
  b:SetBackdropColor(0,0,0,.55);b:SetBackdropBorderColor(.5,.5,.5,.8)
  local t=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");t:SetAllPoints(b);t:SetText(FieldKit_L(labels[i]))
  b.fieldkitLabel=t;b.fieldkitView=key;b.fieldkitFullLabel=fullLabel
  b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  b:SetScript("OnClick",function()
   if arg1=="RightButton" then S.SetDetached(this.fieldkitView,not S.IsDetached(this.fieldkitView))
   else S.SetView(this.fieldkitView) end
  end)
  b:SetScript("OnEnter",function()
   GameTooltip:SetOwner(this,"ANCHOR_TOP")
   GameTooltip:SetText(FieldKit_L(this.fieldkitFullLabel),1,.85,.55)
   GameTooltip:AddLine(FieldKit_L("Left-click: switch tab. Right-click: detach / reattach window."),.8,.8,.8,true)
   GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function() GameTooltip:Hide() end)
  tabs.buttons[i]=b
 end
 local reset=CreateFrame("Button",frame:GetName().."Reset",frame)
 reset:SetWidth(44);reset:SetHeight(16);reset:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-4,3)
 reset:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
 reset:SetBackdropColor(.25,.08,.08,.7);reset:SetBackdropBorderColor(.7,.3,.2,.9)
 local rt=reset:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");rt:SetAllPoints(reset);FieldKit_Text(rt,"Reset")
 reset:SetScript("OnClick",function()
  local ok=L.Reset()
  if L.ClearHidden then L.ClearHidden() end
  if DB() then DB().meterPartyOwner=nil end
  if DEFAULT_CHAT_FRAME then
   DEFAULT_CHAT_FRAME:AddMessage("|cffd2a24aFieldKit:|r "..(ok and FieldKit_L("Meter reset (checkpoint).") or FieldKit_L("Meter hit stats cleared.")))
  end
  S.Update(true)
 end)
 frame.fieldkitReset=reset
 local pop=CreateFrame("Button",frame:GetName().."Detach",frame)
 pop:SetWidth(16);pop:SetHeight(16);pop:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-22,-4)
 pop:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});pop:SetBackdropColor(.2,.2,.25,.8)
 local pt=pop:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");pt:SetAllPoints(pop);pt:SetText("⧉")
 pop:SetScript("OnClick",function()
  local view=S.View();S.SetDetached(view,not S.IsDetached(view))
 end)
 frame.fieldkitDetach=pop
end

local function TintTabs(frame,active)
 if not frame.fieldkitTabs then return end
 for i=1,table.getn(frame.fieldkitTabs.buttons) do
  local b=frame.fieldkitTabs.buttons[i]
  if b.fieldkitView==active then b:SetBackdropColor(.45,.28,.08,.85)
  else b:SetBackdropColor(0,0,0,.55) end
 end
end

function S.EnsureDetach(view)
 if not S.IsDetached(view) then
  local f=detached[view];if f then f:Hide() end;return
 end
 if detached[view] then return end
 -- Reuse CreateBarWindow via existing meter factory pattern: clone taken/meter sizing.
 local name="FieldKitMeter"..string.upper(string.sub(view,1,1))..string.sub(view,2).."Frame"
 -- Avoid invalid global names with underscores only.
 name="FieldKitMeterExtra_"..view
 local f=CreateFrame("Frame",name,UIParent)
 f:SetWidth(220);f:SetHeight(28+15*ROWS);f:SetFrameStrata("LOW")
 f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 f:SetBackdropColor(0,0,0,.6);f:SetBackdropBorderColor(.5,.5,.5,.8)
 if FieldKitTheme and FieldKitTheme.Surface then FieldKitTheme.Surface(f,"card",true) end
 f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",9,-7)
 f.total=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-7)
 f.rows={};f.fieldkitFooterHeight=0
 for i=1,ROWS do
  local row=CreateFrame("StatusBar",nil,f)
  row:SetHeight(13);row:SetPoint("TOPLEFT",f,"TOPLEFT",6,-22-15*(i-1));row:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-22-15*(i-1))
  row:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");row:SetMinMaxValues(0,1)
  row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.label:SetPoint("LEFT",row,"LEFT",3,0);row.label:SetJustifyH("LEFT")
  row.value=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.value:SetPoint("RIGHT",row,"RIGHT",-3,0)
  row.label:SetPoint("RIGHT",row.value,"LEFT",-4,0)
  S.BindSpellTip(row);row:Hide();f.rows[i]=row
 end
 if FieldKit.CreateMeterColumns then FieldKit.CreateMeterColumns(f) end
 for i=1,ROWS do S.BindSpellTip(f.rows[i]) end
 f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function() this:StartMoving() end)
 f:SetScript("OnDragStop",function()
  this:StopMovingOrSizing()
  if DB() then
   DB().pos=DB().pos or {}
   local x,y=this:GetCenter();local ux,uy=UIParent:GetCenter()
   if x and ux then DB().pos[name]={x-ux,y-uy} end
  end
 end)
 local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
 close:SetWidth(22);close:SetHeight(22);close:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
 close:SetScript("OnClick",function() S.SetDetached(view,false) end)
 detached[view]=f
 if DB() and DB().pos and DB().pos[name] then
  f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",DB().pos[name][1] or 0,DB().pos[name][2] or 0)
 else
  f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",120,-40+20*table.getn(detached))
 end
end

function S.HookMeter(meterFrame)
 if not meterFrame or meterFrame.fieldkitSuiteHooked then return end
 meterFrame.fieldkitSuiteHooked=true
 EnsureChrome(meterFrame)
 for i=1,table.getn(meterFrame.rows) do S.BindSpellTip(meterFrame.rows[i]) end
end

function S.Update(force)
 local db=DB();if not db then return end
 local meter=getglobal("FieldKitMeterFrame")
 local taken=getglobal("FieldKitTakenFrame")
 if meter then S.HookMeter(meter) end
 if not db.meterFrame then
  if meter then meter:Hide() end
  for _,f in pairs(detached) do f:Hide() end
  return
 end
 local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase() or nil
 if not phase then
  if meter then meter:Hide() end
  for _,f in pairs(detached) do f:Hide() end
  return
 end
 local view=S.View()
 TintTabs(meter,view)
 -- Primary window shows the selected tab unless that view is detached.
 if S.IsDetached(view) then
  S.EnsureDetach(view);Paint(detached[view],view,force)
  -- Keep main window on another non-detached view (prefer damage).
  local fallback="damage"
  for i=1,table.getn(views) do
   if not S.IsDetached(views[i]) then fallback=views[i];break end
  end
  if fallback~=view then Paint(meter,fallback,force);TintTabs(meter,fallback)
  elseif meter then meter:Hide() end
 else
  Paint(meter,view,force)
 end
 -- Refresh every detached window.
 for i=1,table.getn(views) do
  local v=views[i]
  if S.IsDetached(v) then S.EnsureDetach(v);Paint(detached[v],v,force)
  elseif detached[v] then detached[v]:Hide() end
 end
 -- Classic taken card stays available; hide it only while the Taken tab/detach
 -- already shows the same data, unless the user asked to keep both.
 if taken then
  local onTaken=view=="taken" or S.IsDetached("taken")
  if not db.takenFrame or (onTaken and not db.meterKeepTakenFrame) then taken:Hide() end
 end
 if FieldKitHudStack then FieldKitHudStack.Apply() end
 if FieldKitCardLayout then FieldKitCardLayout.ApplyRight() end
end
