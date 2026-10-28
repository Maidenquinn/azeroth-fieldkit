-- One opaque, reusable hover card. AZSPARTY exposes only top/topdps for peers;
-- the full spell table belongs to the local player. Never substitute our spells
-- for an ally's or convert top DPS into an invented damage amount.
FieldKitPartyDetails={offset=0,pool=10}
local D=FieldKitPartyDetails
local T=FieldKitTheme

function D.Data(name)
 local peer=FieldKitCoop.MemberDamage(name)
 if not peer then return nil end
 local result={name=name,rows={},damage=peer.dmg,dps=peer.dps,own=name==UnitName("player")}
 if not result.own then
  if peer.top then table.insert(result.rows,{name=peer.top,dps=peer.topdps}) end
  return result
 end
 if type(AZS_GetMeter)~="function" then result.unavailable=true;return result end
 local ok,lines,total,dps=pcall(AZS_GetMeter)
 if not ok or type(lines)~="table" then result.unavailable=true;return result end
 local sum=0
 for i=1,math.min(512,table.getn(lines)) do
  local line=lines[i]
  if type(line)=="table" and type(line.name)=="string" then
   local damage=FieldKit.Number(line.dmg,nil,0)
   table.insert(result.rows,{name=string.sub(line.name,1,160),dmg=damage,
    dps=FieldKit.Number(line.dps,nil,0),share=FieldKit.Number(line.share,nil,0,1),proc=line.proc==1 and 1 or 0})
   sum=sum+(damage or 0)
  end
 end
 result.damage=FieldKit.Number(total,sum,0);result.dps=FieldKit.Number(dps,nil,0)
 result.truncated=table.getn(lines)>512
 table.sort(result.rows,function(a,b) return (a.dmg or 0)>(b.dmg or 0) end)
 return result
end

function D.DelayClose() D.deadline=GetTime()+.18 end

function D.Close()
 if D.frame then D.frame:Hide() end
 D.owner=nil;D.member=nil;D.data=nil;D.overOwner=false;D.overPopup=false;D.deadline=nil
end

-- Preserve the theme's hover callbacks on buttons; crossing the eight-pixel
-- gap to the card or hovering pagination must not close it under the cursor.
function D.BindHover(frame)
 local enter,leave=frame:GetScript("OnEnter"),frame:GetScript("OnLeave")
 frame:SetScript("OnEnter",function()
  if enter then enter() end
  D.overPopup=true;D.deadline=nil
 end)
 frame:SetScript("OnLeave",function()
  if leave then leave() end
  D.overPopup=false;D.DelayClose()
 end)
end

function D.Page(delta)
 if not D.data then return end
 D.offset=math.max(0,math.min(math.max(0,table.getn(D.data.rows)-D.visible),D.offset+delta))
 D.Render()
end

function D.Build()
 if D.frame then return end
 local frame=CreateFrame("Frame","FieldKitPartyDetailsFrame",UIParent);D.frame=frame
 frame:SetWidth(560);frame:SetHeight(400);frame:SetFrameStrata("TOOLTIP");frame:SetFrameLevel(220)
 frame:SetClampedToScreen(true);frame:EnableMouse(true);T.Surface(frame,"card")
 D.title=T.Label(frame,nil,16,10,480,26,18,T.gold,true)
 D.summary=T.Label(frame,nil,16,40,520,22,12,T.text)
 D.hint=T.Label(frame,nil,16,64,520,36,11,T.muted)
 D.header=CreateFrame("Frame",nil,frame);D.header:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-106);D.header:SetHeight(18)
 D.spell=T.Label(D.header,"Spell",3,0,260,18,11,T.muted)
 local captions={"Damage","DPS","%"};local offsets={131,45,3};local widths={92,78,34}
 for i=1,3 do
  local label=D.header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  label:SetPoint("RIGHT",D.header,"RIGHT",-offsets[i],0);label:SetWidth(widths[i]);label:SetHeight(18)
  label:SetJustifyH("RIGHT");T.Font(label,11,T.muted);FieldKit_Text(label,captions[i])
 end
 frame.rows={}
 for i=1,D.pool do
  local row=CreateFrame("StatusBar",nil,frame);frame.rows[i]=row
  row:SetMinMaxValues(0,1);row:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  row:SetHeight(20);row:EnableMouse(false)
  row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.label:SetJustifyH("LEFT");T.Font(row.label,12,T.text)
  row.value=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.value:Hide()
 end
 FieldKit.CreateMeterColumns(frame)
 for i=1,D.pool do for j=1,3 do T.Font(frame.rows[i].meterColumns[j],12,T.text) end end
 D.footer=T.Label(frame,nil,16,0,390,24,11,T.muted)
 D.previous=T.Button(frame,nil,"<",0,0,30,24,function() D.Page(-D.visible) end)
 D.next=T.Button(frame,nil,">",0,0,30,24,function() D.Page(D.visible) end)
 D.BindHover(D.previous);D.BindHover(D.next)
 local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
 close:SetWidth(26);close:SetHeight(26);close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4)
 close:SetScript("OnClick",D.Close);D.BindHover(close)
 D.BindHover(frame)
 if frame.EnableMouseWheel then
  frame:EnableMouseWheel(true);frame:SetScript("OnMouseWheel",function() D.Page(-(arg1 or 0)*3) end)
 end
 frame:SetScript("OnUpdate",function()
  if D.deadline and GetTime()>=D.deadline and not D.overOwner and not D.overPopup then D.Close() end
 end)
 frame:SetScript("OnHide",function() D.member=nil;D.data=nil;D.owner=nil end)
 if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"FieldKitPartyDetailsFrame") end
 frame:Hide()
end

function D.Anchor()
 if not D.owner then return end
 local right=D.owner.GetRight and D.owner:GetRight()
 if not right then local x=D.owner:GetCenter();right=(x or 0)+D.owner:GetWidth()/2 end
 D.frame:ClearAllPoints()
 if right+D.frame:GetWidth()+12>UIParent:GetWidth() then
  D.frame:SetPoint("TOPRIGHT",D.owner,"TOPLEFT",-8,18)
 else D.frame:SetPoint("TOPLEFT",D.owner,"TOPRIGHT",8,18) end
end

function D.Render()
 local data=D.data;if not data then return end
 local frame=D.frame;local width=math.max(360,math.min(560,UIParent:GetWidth()-24))
 D.visible=math.max(1,math.min(D.pool,math.floor((UIParent:GetHeight()-200)/22)))
 local count=table.getn(data.rows)
 D.offset=math.max(0,math.min(D.offset,math.max(0,count-D.visible)))
 local shown=math.min(D.visible,count);local height=174+22*math.max(shown,1)
 frame:SetWidth(width);frame:SetHeight(height);D.title:SetWidth(width-56)
 D.summary:SetWidth(width-32);D.hint:SetWidth(width-32);D.header:SetWidth(width-24)
 D.spell:SetWidth(width-270);D.title:SetText(data.name)
 D.summary:SetText(string.format(FieldKit_L("Damage: %s   DPS: %s"),data.damage and string.format("%.0f",data.damage) or "?",data.dps and string.format("%.0f",data.dps) or "?"))
 local hint=data.own and "Your native spell breakdown. Scroll for more spells." or "Allies: only their top spell is exposed. Full breakdown unavailable."
 if data.unavailable then hint="Your spell breakdown is not provided by the client." end
 if data.truncated then hint="Partial view: the 512-source safety limit was reached." end
 FieldKit_Text(D.hint,hint)
 local top=data.rows[1] and data.rows[1].dmg or 1
 for i=1,D.pool do
  local row=frame.rows[i];local line=i<=shown and data.rows[D.offset+i]
  if line then
   row:ClearAllPoints();row:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-128-(i-1)*22);row:SetWidth(width-24)
   row.label:SetText(line.name);FieldKit.UpdateMeterColumns(row,line,3,width-12)
   row:SetValue(line.dmg and line.dmg/math.max(top or 0,1) or 0)
   if line.proc==1 then row:SetStatusBarColor(.25,.45,.9,.55) else row:SetStatusBarColor(.8,.55,.1,.55) end
   row:Show()
  else row:Hide() end
 end
 D.footer:ClearAllPoints();D.footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,10);D.footer:SetWidth(width-112)
 if count==0 then FieldKit_Text(D.footer,"No spell detail provided")
 elseif data.own then D.footer:SetText(string.format(FieldKit_L("Spells %d–%d / %d"),D.offset+1,D.offset+shown,count))
 else FieldKit_Text(D.footer,"Top spell only · missing values stay unknown") end
 D.previous:ClearAllPoints();D.previous:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-50,10)
 D.next:ClearAllPoints();D.next:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-14,10)
 if count>D.visible then D.previous:Show();D.next:Show() else D.previous:Hide();D.next:Hide() end
 T.Update(frame);D.Anchor()
end

function D.Open(owner)
 if FieldKit.layoutEditing or not owner.fieldkitMember then return end
 local data=D.Data(owner.fieldkitMember);if not data then D.Close();return end
 D.Build();D.owner=owner;D.member=owner.fieldkitMember;D.data=data;D.offset=0
 D.overOwner=true;D.overPopup=false;D.deadline=nil;D.Render();D.frame:Show()
end

function D.BindRow(row)
 row:SetScript("OnEnter",function() D.Open(this) end)
 row:SetScript("OnLeave",function() D.overOwner=false;D.DelayClose() end)
 row:SetScript("OnHide",function() if D.owner==this then D.Close() end end)
 if row.EnableMouseWheel then
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel",function() if D.owner==this then D.Page(-(arg1 or 0)*3) end end)
 end
end

-- Called on the existing co-op 5 Hz tick, never on every animation frame.
function D.Sync()
 if not D.member then return end
 if FieldKit.layoutEditing or not FieldKitCoop.phase or not FieldKitCoop.meter:IsShown()
  or FieldKitCoop.meter.mashCollapsed or not D.owner:IsShown() or not D.owner.fieldkitMember then D.Close();return end
 if D.owner.fieldkitMember~=D.member then
  if D.overOwner then D.Open(D.owner) else D.Close() end
  return
 end
 local data=D.Data(D.member);if not data then D.Close();return end
 D.data=data;D.Render()
end
