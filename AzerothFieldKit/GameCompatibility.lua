-- Read-only 0.121 compatibility. See docs/GAME_0_121.md for local evidence.
-- Missing fields remain unknown: zone difficulty is not the Heroic rank.
local ranks={"I","II","III","IV","V"}
function FieldKit.GetHeroicLevel()
 if type(AZS_GetPhase)~="function" or not AZS_GetPhase() or type(AZS_ZONE)~="table" then return nil end
 local level=FieldKit.Number(AZS_ZONE.heroic)
 if not level or level~=math.floor(level) or level<0 or level>5 then return nil end
 return level
end
function FieldKit.GetHeroicLabel()
 local level=FieldKit.GetHeroicLevel()
 if level==nil then return nil end
 if level==0 then return FieldKit_L("Normal difficulty") end
 return FieldKit_L("Heroic").." "..ranks[level]
end

-- Keep targetable mechanics readable when the optional ordinary-mob filter is
-- active. These exact EN/FR client names do not trigger targeting or combat.
function FieldKit.IsCriticalObjective(name)
 return name=="Explosive Orb" or name=="Orbe explosif"
end

-- New star bonuses can be smaller than 1%. Keep tenths, omit a trailing .0,
-- and avoid displaying a negative zero after rounding a very small value.
function FieldKit.FormatPercent(value,signed)
 local percent=FieldKit.Number(value,0)*100
 if math.abs(percent)<.05 then percent=0 end
 local text=string.format(signed and "%+.1f%%" or "%.1f%%",percent)
 return (string.gsub(text,"%.0%%$","%%"))
end
function FieldKit.FormatBonus(value)
 local amount=FieldKit.Number(value,0)
 if math.abs(amount)<.05 then amount=0 end
 return (string.gsub(string.format("%.1f",amount),"%.0$",""))
end
