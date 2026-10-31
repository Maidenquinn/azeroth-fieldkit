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

function FieldKit.MeterWidth(mode) return mode==1 and 220 or (mode==2 and 320 or 360) end

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

function FieldKit.UpdateMeterColumns(row,line,mode,width,rateLabel)
 local columns=row.meterColumns
 local damage,rate,share=MeterParts(line,rateLabel)
 columns[1]:SetText(damage);columns[2]:SetText(rate);columns[3]:SetText(share)
 if row.meterMode~=mode or row.meterWidth~=width then
  row.meterMode=mode;row.meterWidth=width
  local offsets=mode==2 and {89,3,0} or {131,45,3}
  local sizes={92,78,34}
  for i=1,3 do
   local text=columns[i];text:ClearAllPoints()
   text:SetPoint("RIGHT",row,"RIGHT",-offsets[i],0);text:SetWidth(sizes[i])
   if (i==1 and mode==1) or (i==3 and mode==2) then text:Hide() else text:Show() end
  end
  local reserved=mode==1 and 123 or (mode==2 and 181 or 223)
  row.label:ClearAllPoints();row.label:SetPoint("LEFT",row,"LEFT",3,0)
  row.label:SetWidth(width-12-reserved-11);row.label:SetHeight(14)
 end
 -- Other bar windows still use the generic value region; this meter hides it.
 row.value:Hide()
end
-- Factory keeps checkbox closures small enough for Lua 5.0.
local function Check(key,label,tip,default)
 return {kind="check",label=label,tip=tip,
 get=function() if not FieldKitDB then return default end;return FieldKitDB[key] end,
 set=function(v) FieldKitDB[key]=v end}
end
-- Extend the existing schema with language, privacy, combat editor and boss HP controls.
function FieldKit_AddSettingsSections(sections)
 table.insert(sections,{title="Combat text",items={{kind="combat"}}})
 -- Keep the native guardian minimap option in the existing Map page.
 for i=1,table.getn(sections) do
  if sections[i].title=="Interface" then
   table.insert(sections[i].items,1,{kind="language"})
   table.insert(sections[i].items,Check("chatCopy","Enable local chat copy","Off by default. Keeps up to 100 main-chat messages in memory only, including private messages. Nothing is sent or saved. Disabling clears the buffer.",false))
  end
  if sections[i].title=="Map" then
   table.insert(sections[i].items,Check("guardianPins","Guardians on the minimap","Exact native lair positions, not moving guardian locations. White: asleep; red: fighting; orange: return countdown. Independent of the Lairs window.",true))
  end
 end
end
