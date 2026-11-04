-- Live native rank/zone plus the Difficulty UI multiplier chart.
-- Chart values match the client's Difficulty screen (HP/damage/marks/loot),
-- not live-measured combat meters.
FieldKitRunMode={}
local R=FieldKitRunMode
R.reference="difficulty-ui"
-- Exact multipliers from the Difficulty selection screen (Normal + Heroic I–V).
R.chart={
 [0]={
  lines={"Marks x0.5"},
  notes={"The zone as-is"},
 },
 [1]={
  lines={"HP x1.79 · Damage x1.65","Marks x1 · Talent loot/XP x1.3"},
  notes={
   "Boss attacks give 15% less warning.",
   "Elite packs: elites arrive in pairs.",
  },
 },
 [2]={
  lines={"HP x1.97 · Damage x1.77","Marks x1.25 · Talent loot/XP x1.4"},
  notes={},
 },
 [3]={
  lines={"HP x2.16 · Damage x1.88","Marks x1.5 · Talent loot/XP x1.5"},
  notes={},
 },
 [4]={
  lines={"HP x2.45 · Damage x2.01","Marks x2 · Talent loot/XP x1.6"},
  notes={},
 },
 [5]={
  lines={"HP x2.72 · Damage x2.16","Marks x2.5 · Talent loot/XP x1.7"},
  notes={},
 },
}

-- Accept only explicit names from the packet. Numeric/unknown encodings remain
-- raw evidence, never a guessed weekly rotation or bitmask.
function R.Affixes()
 if not FieldKitDB.showNativeAffixes or type(AZS_ZONE)~="table" then return nil end
 local value=AZS_ZONE.affixes
 if type(value)~="string" and type(value)~="number" then return nil end
 local raw=FieldKitNative.Text(tostring(value),160)
 if raw=="" then return nil end
 local names={bolstering="Bolstering",sanguine="Sanguine",explosive="Explosive"}
 local result,seen={},{};local at=1
 while at<=string.len(raw) and table.getn(result)<3 do
  local a,b,token=string.find(raw,"([^,]+)",at);if not a then break end
  token=string.lower(string.gsub(string.gsub(token,"^%s+",""),"%s+$",""))
  if not names[token] then return FieldKit_L("Affixes (raw)")..": "..raw,false end
  if not seen[token] then table.insert(result,FieldKit_L(names[token]));seen[token]=true end
  at=b+1
 end
 if table.getn(result)==0 or at<=string.len(raw) then return FieldKit_L("Affixes (raw)")..": "..raw,false end
 return FieldKit_L("Active affixes")..": "..table.concat(result,", "),true
end

function R.ChartLines(level)
 local entry=R.chart[level]
 if not entry then return {} end
 local out={}
 for _,line in ipairs(entry.lines or {}) do table.insert(out,FieldKit_L(line)) end
 -- Live run: show combat notes for the current rank (Heroic I has the pair/warn rules).
 for _,note in ipairs(entry.notes or {}) do table.insert(out,FieldKit_L(note)) end
 return out
end

function R.Tooltip(owner)
 GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
 GameTooltip:SetText(FieldKit.GetHeroicLabel() or FieldKit_L("Mode not provided"),1,.85,.55)
 local level=FieldKit.GetHeroicLevel()
 if level==nil then
  GameTooltip:AddLine(FieldKit_L("No difficulty data received."),.9,.9,.85,true)
 else
  GameTooltip:AddLine(FieldKit_L("Difficulty screen values"),.65,.7,.7,true)
  local titles={
   [0]=FieldKit_L("Normal difficulty"),
   [1]=FieldKit_L("Heroic").." I",
   [2]=FieldKit_L("Heroic").." II",
   [3]=FieldKit_L("Heroic").." III",
   [4]=FieldKit_L("Heroic").." IV",
   [5]=FieldKit_L("Heroic").." V",
  }
  for rank=0,5 do
   local entry=R.chart[rank]
   GameTooltip:AddLine(titles[rank],1,.85,.55)
   for _,line in ipairs(entry.lines or {}) do GameTooltip:AddLine(FieldKit_L(line),.9,.9,.85,true) end
   if rank==level then
    for _,note in ipairs(entry.notes or {}) do GameTooltip:AddLine(FieldKit_L(note),.85,.9,.7,true) end
   end
  end
 end
 local affixes=R.Affixes()
 if affixes then GameTooltip:AddLine(affixes,.9,.85,.5,true) end
 GameTooltip:AddLine(FieldKit_L("Same multipliers as the Difficulty UI. Not live combat meters."),.8,.7,.45,true)
 GameTooltip:Show()
end

function R.Create(createWindow,fitRows)
 R.frame=createWindow("FieldKitModeFrame","Run mode",8);R.fitRows=fitRows
 local f=R.frame
 f:SetScript("OnEnter",function() R.Tooltip(this) end)
 f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 for i=1,table.getn(f.rows) do
  local row=f.rows[i];row.value:Hide();row.label:ClearAllPoints()
  row.label:SetPoint("LEFT",row,"LEFT",3,0);row.label:SetHeight(14)
  row:SetScript("OnEnter",function() R.Tooltip(this) end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 f:Hide();return f
end

function R.Reflow(width)
 if not R.frame then return end
 for i=1,table.getn(R.frame.rows) do R.frame.rows[i].label:SetWidth(width-24) end
end

function R.Update()
 local f=R.frame;if not f then return end
 -- Do not resize/hide this card while WoW is processing a mouse drag.
 -- The next native data tick will apply the latest data after release.
 if f.azsMoving then return end
 local active=type(AZS_GetPhase)=="function" and AZS_GetPhase()
 if not FieldKitDB.runModeCard or (not active and not FieldKit.layoutEditing) then f:Hide();return end
 local level=FieldKit.GetHeroicLevel()
 FieldKit_Text(f.total,FieldKit.GetHeroicLabel() or (active and "Mode not provided" or "Preview"))
 local zone=type(AZS_ZONE)=="table" and (AZS_ZONE.zname or AZS_ZONE.zone)
 if level==nil and FieldKitDB.hideUnknownMode and not FieldKit.layoutEditing then f:Hide();return end
 local lines={zone or FieldKit_L("Zone not provided")}
 if level==nil then table.insert(lines,FieldKit_L("No difficulty data received."))
 else
  for _,line in ipairs(R.ChartLines(level)) do table.insert(lines,line) end
 end
 local affixes=R.Affixes();if affixes then table.insert(lines,affixes) end
 local shown=math.min(table.getn(lines),table.getn(f.rows))
 for i=1,shown do
  local row=f.rows[i];row:SetValue(0);row.value:Hide();row.label:SetText(lines[i]);row:Show()
 end
 R.Reflow(f:GetWidth());R.fitRows(f,shown);f:Show()
end
