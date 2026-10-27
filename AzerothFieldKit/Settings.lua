-- Lua 5.0: small callbacks only capture an option key and its default.
function MASH_FormatHealth(current,maximum,mode)
 local hp=math.max(0,tonumber(current) or 0)
 local max=math.max(0,tonumber(maximum) or 0)
 local percent=max>0 and math.floor(hp*100/max+0.5) or 0
 local numbers=string.format("%d / %d",hp,max)
 if mode==2 then return percent.."%" end
 if mode==3 then return numbers.." ("..percent.."%)" end
 return numbers
end
local function Check(key,label,tip,default)
 return {kind="check",label=label,tip=tip,
 get=function() if not MASHDB then return default end;return MASHDB[key] end,
 set=function(v) MASHDB[key]=v end}
end
function MASH_AddSettingsSections(sections)
 table.insert(sections,{title="Combat text",items={{kind="combat"}}})
 table.insert(sections,{title="Boss health",items={
 {kind="check",label="Boss health: percentage",tip="Percentage only. Uncheck to return to exact numbers.",
 get=function() return MASHDB and MASHDB.bossHealthMode==2 end,
 set=function(v) MASHDB.bossHealthMode=v and 2 or 1 end},
 {kind="check",label="Boss health: numbers + percent",tip="Exact numeric values and percentage.",
 get=function() return MASHDB and MASHDB.bossHealthMode==3 end,
 set=function(v) MASHDB.bossHealthMode=v and 3 or 1 end}
 }})
 -- Keep the native guardian minimap option in the existing Map page.
 for i=1,table.getn(sections) do
  if sections[i].title=="Interface" then table.insert(sections[i].items,1,{kind="language"}) end
  if sections[i].title=="Map" then
   table.insert(sections[i].items,Check("guardianPins","Guardians on the minimap","Exact native lair positions, not moving guardian locations. White: asleep; red: fighting; orange: return countdown. Independent of the Lairs window.",true))
  end
 end
end
