-- Live rank + explicitly versioned mechanic reference. No inferred affix ids,
-- enemy multipliers, rewards, star ranks or progression are presented as live data.
FieldKitRunMode={}
local R=FieldKitRunMode
R.reference="0.121"
R.modifiers={
 {"Shorter warnings","Boss attacks give less warning and lead your movement more as Heroic rises."},
 {"Elite packs","Ordinary elites arrive in pairs."},
 {"Relentless","Bosses start enraged and become fiercer below 30% health."},
 {"Sentinels","Slain guardians strengthen the others; lairs refill sooner."},
 {"Lean purse","One free reroll; caches cost a quarter more."},
 {"Horde affix","A weekly horde affix applies. Its active identity is not supplied to FieldKit."},
 {"Old mechanics","Boss towers and gazes return."},
 {"Unforgiving","A failed boss mechanic deals triple damage."},
 {"Withering","Regeneration, healing and leech are halved; revives are slower and weaker."},
 {"Council","The final boss brings an earlier boss; two weekly affixes apply."},
}

function R.Tooltip(owner)
 GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
 GameTooltip:SetText(FieldKit.GetHeroicLabel() or FieldKit_L("Mode not provided"),1,.85,.55)
 local level=FieldKit.GetHeroicLevel()
 if level==0 then GameTooltip:AddLine(FieldKit_L("Normal zone rules."),.9,.9,.85,true)
 elseif level then
  GameTooltip:AddLine(FieldKit_L("Modifier reference").." · "..R.reference,.65,.7,.7,true)
  for i=1,level*2 do
   GameTooltip:AddLine(FieldKit_L(R.modifiers[i][1])..": "..FieldKit_L(R.modifiers[i][2]),.9,.9,.85,true)
  end
 end
 GameTooltip:AddLine(FieldKit_L("Reference rules are not measured live values. Enemy HP/damage multipliers and current affix names are not supplied."),.8,.7,.45,true)
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

-- Up to four mechanic names remain visible; the complete cumulative reference
-- is available on hover. Unknown mode means no guessed Normal/Heroic modifiers.
function R.Update()
 local f=R.frame;if not f then return end
 local active=type(AZS_GetPhase)=="function" and AZS_GetPhase()
 if not FieldKitDB.runModeCard or (not active and not FieldKit.layoutEditing) then f:Hide();return end
 local level=FieldKit.GetHeroicLevel()
 FieldKit_Text(f.total,FieldKit.GetHeroicLabel() or (active and "Mode not provided" or "Preview"))
 local zone=type(AZS_ZONE)=="table" and (AZS_ZONE.zname or AZS_ZONE.zone)
 -- Keep only current native context on the HUD. Historical mechanic reference
 -- remains in the tooltip and never masquerades as current measured modifiers.
 if level==nil and FieldKitDB.hideUnknownMode and not FieldKit.layoutEditing then f:Hide();return end
 local lines={zone or FieldKit_L("Zone not provided")}
 if level==nil then table.insert(lines,FieldKit_L("No difficulty data received.")) end
 for i=1,table.getn(lines) do
  local row=f.rows[i];row:SetValue(0);row.value:Hide();row.label:SetText(lines[i]);row:Show()
 end
 R.Reflow(f:GetWidth());R.fitRows(f,table.getn(lines));f:Show()
end
