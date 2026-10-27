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
