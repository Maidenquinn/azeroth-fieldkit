-- Lua 5.0: small callbacks only capture an option key and its default.
-- Format finite observed HP in numbers/percent/both, safely handling missing or zero maxima.
function FieldKit_FormatHealth(current,maximum,mode)
 local hp=FieldKit.Number(current,0,0)
 local max=FieldKit.Number(maximum,0,0)
 local percent=max>0 and math.floor(hp*100/max+0.5) or 0
 local numbers=string.format("%d / %d",hp,max)
 if mode==2 then return percent.."%" end
 if mode==3 then return numbers.." ("..percent.."%)" end
 return numbers
end
-- These are observed native meter fields, not damage inferred from DPS/time.
-- Missing fields remain visibly unknown. Damage totals are displayed unabridged.
local function MeterParts(line,rateLabel)
 local damage=FieldKit.Number(line.dmg,nil,0)
 local rate=FieldKit.Number(line.dps,nil,0)
 local share=FieldKit.Number(line.share,nil,0)
 local amount=damage and string.format("%.0f",damage) or "?"
 local dps=(rate and string.format("%.0f",rate) or "?").." "..FieldKit_L(rateLabel or "dps")
 local percent=share and string.format("%.0f%%",share*100) or "?"
 return amount,dps,percent
end
function FieldKit_FormatMeterValues(line,mode)
 local amount,dps,percent=MeterParts(line)
 if mode==1 then return dps.." | "..percent end
 if mode==2 then return amount.." | "..dps end
 return amount.." | "..dps.." | "..percent
end

function FieldKit.MeterWidth(mode)
 local w=mode==1 and 220 or (mode==2 and 320 or 360)
 -- Tabs + optional kill counts need a wider card than the classic 220 strip.
 if FieldKitDB and FieldKitDB.meterTabs~=false then w=math.max(w,340) end
 return w
end

-- One bounded set of right-aligned numeric columns per spell row. Text length
-- never moves a neighbouring column or changes the available name rectangle.
function FieldKit.CreateMeterColumns(frame)
 for i=1,table.getn(frame.rows) do
  local row=frame.rows[i];row.meterColumns={}
  for j=1,3 do
   local text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   text:SetJustifyH("RIGHT");text:SetHeight(14);row.meterColumns[j]=text
  end
  row.value:Hide()
 end
end

-- Shared column geometry for meter rows and the header strip.
function FieldKit.MeterColumnLayout(mode,showKills)
 local killW=showKills and 40 or 0
 local offsets=mode==2 and {89,3,0} or {131,45,3}
 local sizes={92,78,34}
 local valueLeft=mode==1 and 123 or (mode==2 and 89 or 223)
 local reserved=(mode==1 and 123 or (mode==2 and 181 or 223))+killW
 return offsets,sizes,killW,valueLeft,reserved
end

local function SortMark(key)
 local db=FieldKitDB
 if not db or db.meterSortKey~=key then return "" end
 return db.meterSortAsc and " ^" or " v"
end

local function HeaderLabel(btn,text)
 if btn.text then FieldKit_Text(btn.text,text) else FieldKit_Text(btn,text) end
end

function FieldKit.UpdateMeterHeaders(header,mode,width,showKills,rateLabel)
 if not header then return end
 local offsets,sizes,killW,valueLeft=FieldKit.MeterColumnLayout(mode,showKills)
 header:SetWidth(width-12)
 local spellW=math.max(40,width-12-((mode==1 and 123 or (mode==2 and 181 or 223))+killW)-11)
 header.spell:ClearAllPoints();header.spell:SetPoint("LEFT",header,"LEFT",3,0)
 header.spell:SetWidth(spellW);header.spell:SetHeight(12)
 HeaderLabel(header.spell,FieldKit_L("Spell")..SortMark("name"))
 local labels={
  (mode==2 and FieldKit_L("Healing") or FieldKit_L("Damage"))..SortMark("dmg"),
  FieldKit_L(rateLabel or (mode==2 and "hps" or "dps"))..SortMark("dps"),
  "%"..SortMark("share"),
 }
 for i=1,3 do
  local text=header.cols[i]
  text:ClearAllPoints();text:SetPoint("RIGHT",header,"RIGHT",-offsets[i],0);text:SetWidth(sizes[i]);text:SetHeight(12)
  HeaderLabel(text,labels[i])
  if (i==1 and mode==1) or (i==3 and mode==2) then text:Hide() else text:Show() end
 end
 if showKills then
  header.kills:ClearAllPoints();header.kills:SetPoint("RIGHT",header,"RIGHT",-(valueLeft+4),0)
  header.kills:SetWidth(36);header.kills:SetHeight(12)
  HeaderLabel(header.kills,FieldKit_L("Kills")..SortMark("kills"));header.kills:Show()
 else header.kills:Hide() end
 header:Show()
end

function FieldKit.UpdateMeterColumns(row,line,mode,width,rateLabel)
 FieldKitLoadout.Decorate(row,line.name)
 local columns=row.meterColumns
 local damage,rate,share=MeterParts(line,rateLabel)
 columns[1]:SetText(damage);columns[2]:SetText(rate);columns[3]:SetText(share)
 -- Kills sit in their own slot left of the value columns — never on top of damage.
 local kills=FieldKit.Number(line and line.kills,nil,0)
 local showKills=kills and kills>0 and mode~=2
 local offsets,sizes,killW,valueLeft,reserved=FieldKit.MeterColumnLayout(mode,showKills)
 local killKey=showKills and kills or 0
 if row.meterMode~=mode or row.meterWidth~=width or row.meterInset~=row.fieldkitIconInset or row.meterKills~=killKey then
  row.meterMode=mode;row.meterWidth=width;row.meterInset=row.fieldkitIconInset;row.meterKills=killKey
  for i=1,3 do
   local text=columns[i];text:ClearAllPoints()
   text:SetPoint("RIGHT",row,"RIGHT",-offsets[i],0);text:SetWidth(sizes[i])
   if (i==1 and mode==1) or (i==3 and mode==2) then text:Hide() else text:Show() end
  end
  if not row.killColumn then
   row.killColumn=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   row.killColumn:SetJustifyH("RIGHT");row.killColumn:SetHeight(14)
  end
  if showKills then
   row.killColumn:ClearAllPoints()
   row.killColumn:SetPoint("RIGHT",row,"RIGHT",-(valueLeft+4),0)
   row.killColumn:SetWidth(36)
   row.killColumn:SetText(tostring(kills))
   row.killColumn:SetTextColor(1,.82,.45)
   row.killColumn:Show()
  else
   row.killColumn:Hide();row.killColumn:SetText("")
  end
  row.label:ClearAllPoints();row.label:SetPoint("LEFT",row,"LEFT",3+(row.fieldkitIconInset or 0),0)
  row.label:SetWidth(math.max(40,width-12-reserved-11-(row.fieldkitIconInset or 0)));row.label:SetHeight(14)
 end
 if showKills and row.killColumn then
  row.killColumn:SetText(tostring(kills));row.killColumn:Show()
 elseif row.killColumn then row.killColumn:Hide() end
 row.value:Hide();row.value:SetText("")
end
-- Factory keeps checkbox closures small enough for Lua 5.0.
local function Check(key,label,tip,default)
 return {kind="check",label=label,tip=tip,
 get=function() if not FieldKitDB then return default end;return FieldKitDB[key] end,
 set=function(v) FieldKitDB[key]=v end}
end
-- Opt-in styling for the native chat frame (Prat-inspired, no third-party dependencies).
local function ChatSlider(key,label,minimum,maximum,step)
 return {kind="slider",label=label,min=minimum,max=maximum,step=step,
  get=function() return (FieldKitDB and FieldKitDB[key]) or minimum end,
  set=function(v)
   FieldKitDB[key]=v
   if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
  end,
  format=function(v) return FieldKit_L(label)..": "..v end}
end
-- Extend the existing schema with language, privacy, combat editor and boss HP controls.
function FieldKit_AddSettingsSections(sections)
 table.insert(sections,{title="Combat text",items={{kind="combat"}}})
 -- Keep the native guardian minimap option in the existing Map page.
 for i=1,table.getn(sections) do
  if sections[i].title=="Interface" then
   table.insert(sections[i].items,1,{kind="language"})
   local chat=Check("chatCopy","Enable local chat copy","Records up to 100 NEW messages from the main chat after enabling. Click Open chat copy, or type /fieldkitlog, then use Ctrl+A / Ctrl+C. Native chat text itself cannot be selected. Nothing is uploaded or saved.",false)
    chat.button={text="Open chat copy",onClick=function()
     if FieldKit.OpenChatCopy then FieldKit.OpenChatCopy() end
    end}
    table.insert(sections[i].items,chat)
    local style=Check("chatStyle","Customize main chat","Apply FieldKit's native chat size, font size and fading controls. Can be disabled to restore the previous chat appearance. Compatible with the main ChatFrame1.",false)
    local old=style.set
    style.set=function(v) old(v);if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end end
    table.insert(sections[i].items,style)
    table.insert(sections[i].items,ChatSlider("chatWidth","Chat width",280,800,10))
    table.insert(sections[i].items,ChatSlider("chatHeight","Chat height",100,450,10))
    table.insert(sections[i].items,ChatSlider("chatFontSize","Chat font size",10,20,1))
    table.insert(sections[i].items,ChatSlider("chatHistoryLines","Chat history lines",100,500,25))
    local fading=Check("chatFading","Fade older chat lines","Fade native chat text when not actively reading. Disable to keep messages visible until scrolled away.",true)
    local original=fading.set
    fading.set=function(v) original(v);if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end end
    table.insert(sections[i].items,fading)
  end
  if sections[i].title=="Map" then
   table.insert(sections[i].items,Check("guardianPins","Guardians on the minimap","Exact native lair positions, not moving guardian locations. White: asleep; red: fighting; orange: return countdown. Independent of the Lairs window.",true))
  end
 end
end
