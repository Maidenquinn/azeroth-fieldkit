-- Optional legacy critical display, independent from the full combat renderer.
-- Bounded to eight lines. Grouping retains the largest critical value and a count,
-- not a sum: this preserves the original display semantics.
FieldKitCrits={}
local CRIT_WINDOW = 0.25  -- agrupado: segundos juntando criticos numa linha
local CRIT_LIFE = 1.6     -- segundos que cada linha fica na tela
local CRIT_LINES = 8      -- linhas no maximo
local CRIT_GAP = 17       -- distancia entre linhas
local critHolder
local critLines = {}      -- da mais nova (1) para a mais velha
local critPending         -- agrupado: { best, count, since } do intervalo atual

-- Allocate the amount/count fontstrings for one reusable line.
local function CreateCritLine(i)
	local line = {}
	line.value = critHolder:CreateFontString("FieldKitCrit"..i, "OVERLAY", "GameFontNormalLarge")
	line.value:SetTextColor(1.0, 0.85, 0.1)
	line.count = critHolder:CreateFontString("FieldKitCrit"..i.."Count", "OVERLAY", "GameFontHighlightSmall")
	line.count:SetTextColor(1.0, 0.85, 0.1)
	line.count:SetPoint("LEFT", line.value, "RIGHT", 3, -2)
	return line
end

-- Anchor above the player bar when shown, otherwise near screen center.
local function PlaceCritHolder()
	critHolder:ClearAllPoints()
	if ( FieldKitPlayerBar and FieldKitPlayerBar:IsShown() ) then
		critHolder:SetPoint("BOTTOM", FieldKitPlayerBar, "TOP", 0, 80)
	else
		critHolder:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
	end
end

-- Recycle the oldest of eight lines and stamp its display lifetime.
local function AddCritLine(amount, count)
	if ( not critHolder ) then
		critHolder = CreateFrame("Frame", "FieldKitLegacyCritFrame", UIParent)
		critHolder:SetWidth(1)
		critHolder:SetHeight(1)
		critHolder:SetFrameStrata("HIGH")
		for i = 1, CRIT_LINES do
			critLines[i] = CreateCritLine(i)
		end
	end
	PlaceCritHolder()
	-- a linha mais velha e reaproveitada como a nova
	local line = table.remove(critLines)
	table.insert(critLines, 1, line)
	line.born = GetTime()
	FieldKit_Text(line.value,amount)
	FieldKit_Text(line.count,count > 1 and ( "x"..count ) or "")
end

-- Group by maximum critical amount and count, preserving historical display semantics.
local function ShowCrit(amount)
	amount = FieldKit.Number(amount,0,0)
	if ( not FieldKitDB.groupCrits ) then
		AddCritLine(amount, 1)
	elseif ( not critPending ) then
		critPending = { best = amount, count = 1, since = GetTime() }
	else
		critPending.count = critPending.count + 1
		if ( amount > critPending.best ) then
			critPending.best = amount
		end
	end
end

-- chamado no OnUpdate: fecha o intervalo agrupado e posiciona/apaga as linhas
-- Fade/expire fixed lines and flush a completed 0.25s grouping window.
function FieldKitCrits.Animate()
	if not FieldKitDB.showCrits then
		critPending = nil
		for i=1,table.getn(critLines) do
			critLines[i].born=nil;critLines[i].value:Hide();critLines[i].count:Hide()
		end
		return
	end
	local now = GetTime()
	if ( critPending and now - critPending.since >= CRIT_WINDOW ) then
		AddCritLine(critPending.best, critPending.count)
		critPending = nil
	end
	for i = 1, table.getn(critLines) do
		local line = critLines[i]
		local age = line.born and ( now - line.born ) / CRIT_LIFE or 1
		if ( age >= 1 ) then
			line.value:Hide()
			line.count:Hide()
		else
			line.value:ClearAllPoints()
			line.value:SetPoint("BOTTOM", critHolder, "BOTTOM", 0, CRIT_GAP * ( i - 1 ))
			line.value:SetAlpha(age < 0.7 and 1 or ( 1 - age ) / 0.3)
			line.count:SetAlpha(line.value:GetAlpha())
			line.value:Show()
			line.count:Show()
		end
	end
end

-- Accept only bounded recognized English critical-hit messages.
function FieldKitCrits.Capture(msg)
	if ( not FieldKitDB.showCrits or type(msg)~="string" or string.len(msg)>4096 ) then
		return
	end
	local _, _, amount = string.find(msg, "^Your .- crits .- for (%d+)")
	if ( not amount ) then
		_, _, amount = string.find(msg, "^You crit .- for (%d+)")
	end
	if ( amount ) then
		ShowCrit(amount)
	end
end
