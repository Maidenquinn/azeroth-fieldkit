-- The native taken API exposes category totals, not a per-creature ledger.
-- Keep a bounded, explicitly partial log of named hits when current native unit
-- data proves the source kind. Melee and exact spell templates only; no guessing.
FieldKitTakenDetails={buckets={},count=0}
local D=FieldKitTakenDetails
function D.Reset()
 D.buckets={};D.count=0;D.started=GetTime();D.serial=FieldKitNative.serial
 D.oldUnits=AZS_UNITS;D.oldUnitsStamp=AZS_UNITS_UPDATED;D.oldTarget=AZS_TARGET;D.oldTargetStamp=AZS_TARGET_UPDATED
end
function D.Kind(name, attack)
 local found,conflict
 local function note(n,k)
  if n~=name then return end
  local v
  if k=="normal" then v=attack=="spell" and "mob spell" or "mob melee"
  elseif k=="elite" then v="elite"
  elseif k=="boss" or k=="final" then v=attack=="spell" and "boss spell" or "boss melee"
  else v="other" end
  if found and found~=v then conflict=true end;found=v
 end
 if (AZS_UNITS~=D.oldUnits or AZS_UNITS_UPDATED~=D.oldUnitsStamp) and type(AZS_UNITS)=="table" and type(AZS_UNITS_UPDATED)=="number" and AZS_UNITS_UPDATED>=D.started then
  for i=1,math.min(512,table.getn(AZS_UNITS)) do local u=AZS_UNITS[i];if type(u)=="table" then note(u.name or u[3],u.kind or u[1]) end end
 end
 if (AZS_TARGET~=D.oldTarget or AZS_TARGET_UPDATED~=D.oldTargetStamp) and type(AZS_TARGET)=="table" and type(AZS_TARGET_UPDATED)=="number" and AZS_TARGET_UPDATED>=D.started then note(AZS_TARGET.name,AZS_TARGET.kind) end
 if not conflict and found~="other" then return found end
end
function D.Parse(message)
 if type(message)~="string" or string.len(message)>1000 then return end
 local name,amount,attack
 local n,a
 -- Spell templates first: "Name's Spell hits you" also matches generic melee otherwise.
 _,_,n,a=string.find(message,"^(.+)'s .- critically hits you for (%d+)")
 if not n then _,_,n,a=string.find(message,"^(.+)'s .- crits you for (%d+)") end
 if not n then _,_,n,a=string.find(message,"^(.+)'s .- hits you for (%d+)") end
 if not n then _,_,a,n=string.find(message,"^You suffer (%d+) .- damage from (.+)'s ") end
 if n then name,amount,attack=n,a,"spell" end
 if not name then
  _,_,n,a=string.find(message,"^.- de (.+) vous inflige (%d+) points? de dégâts%.$")
  if not n then _,_,n,a=string.find(message,"^(.+) lance .- et vous inflige (%d+) points? de dégâts%.$") end
  if not n then _,_,a,n=string.find(message,"^Vous subissez (%d+) points? de dégâts .- de la part de (.+)%.$") end
  if n then name,amount,attack=n,a,"spell" end
 end
 -- Exact English melee templates.
 if not name then
  _,_,n,a=string.find(message,"^(.+) critically hits you for (%d+)%.?$")
  if not n then _,_,n,a=string.find(message,"^(.+) crits you for (%d+)%.?$") end
  if not n then _,_,n,a=string.find(message,"^(.+) hits you for (%d+)%.?$") end
  if not n then _,_,n,a=string.find(message,"^(.+) hits you for (%d+) damage%.$") end
  if n then name,amount,attack=n,a,"melee" end
 end
 -- Exact French melee templates.
 if not name then
  _,_,n,a=string.find(message,"^(.+) vous touche et vous inflige (%d+) points? de dégâts%.$")
  if not n then _,_,n,a=string.find(message,"^(.+) vous inflige un coup critique pour (%d+) points? de dégâts%.$") end
  if not n then _,_,n,a=string.find(message,"^(.+) vous touche de manière critique et vous inflige (%d+) points? de dégâts%.$") end
  if n then name,amount,attack=n,a,"melee" end
 end
 local damage=FieldKit.Number(amount,nil,1,1000000000)
 if not name or not damage then return end
 return FieldKitNative.Text(name),damage,attack or "melee"
end
function D.Capture(message)
 FieldKitNative.Watch()
 if D.serial~=FieldKitNative.serial or not D.started then D.Reset() end
 if not FieldKitNative.Active() then return end
 local name,damage,attack=D.Parse(message)
 if not name then return end
 local kind=D.Kind(name,attack);if not kind then return end
 local bucket=D.buckets[kind] or {};D.buckets[kind]=bucket
 if not bucket[name] then if D.count>=128 then return end;D.count=D.count+1;bucket[name]=0 end
 bucket[name]=bucket[name]+damage
end
function D.Show(row)
 if not row.takenSource then return end
 if D.serial~=FieldKitNative.serial then D.Reset() end
 GameTooltip:SetOwner(row,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L("Observed attacker details"))
 GameTooltip:AddLine(FieldKit_L("Partial named hit log; native category totals remain authoritative."),.8,.7,.4,true)
 local list={};local total=0
 for name,damage in pairs(D.buckets[row.takenSource] or {}) do table.insert(list,{name=name,damage=damage});total=total+damage end
 table.sort(list,function(a,b) return a.damage>b.damage end)
 for i=1,math.min(12,table.getn(list)) do GameTooltip:AddLine(list[i].name..": "..string.format("%.0f",list[i].damage),1,1,1) end
 if table.getn(list)==0 then GameTooltip:AddLine(FieldKit_L("No attributable creature hits received. The client only provided category totals."),.65,.7,.7,true) end
 if table.getn(list)>12 then GameTooltip:AddLine(string.format(FieldKit_L("%d more sources"),table.getn(list)-12),.65,.7,.7) end
 if total< (row.takenDamage or 0) then GameTooltip:AddLine(FieldKit_L("Not identified")..": "..string.format("%.0f",row.takenDamage-total),.65,.7,.7)
 elseif total>(row.takenDamage or 0) then GameTooltip:AddLine(FieldKit_L("Combat log and native totals are not synchronized."),.8,.7,.4,true) end
 GameTooltip:Show()
end
local frame=CreateFrame("Frame","FieldKitTakenObserver",UIParent)
frame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
frame:SetScript("OnEvent",function() D.Capture(arg1) end)
