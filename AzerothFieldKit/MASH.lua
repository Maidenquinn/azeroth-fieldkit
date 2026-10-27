-- MASH (Malk Azeroth Survivor Helper): utilidades para Azeroth Survivors.
-- /mash           abre/fecha o painel
-- /mash plates     liga/desliga o filtro de nameplates (so elites e bosses ficam visiveis)
-- /mash unknown    alterna o que fazer com monstros ainda nao classificados (mostrar/esconder)
-- /mash hp         liga/desliga o numero de vida no quadro do alvo
-- /mash stats      escolhe quais status aparecem na tela
-- /mash chests     mostra no chat quantos baus foram abertos e o preco do proximo
-- /mash status     resumo no chat

local MASH_VERSION = "1.3.9"  -- manter igual ao "## Version" do .toc
local ADDON_DIR = "MASH"  -- nome da pasta em Interface\AddOns (caminho do icone)
local MENU_FONT = "Fonts\\ARIALN.TTF"  -- fonte do menu: mais legivel que a padrao em tamanho pequeno

local PLATE_BORDER = "Interface\\Tooltips\\Nameplate-Border"
local PLATE_SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local SCAN_INTERVAL = 0.05
local CAMERA_BASE = 15         -- jardas do cliente para cameraDistanceMaxFactor = 1

local DB
local plates = {}      -- [frame] = false (nao e plate) ou { name, skull, bar, parts }
local plateList = {}
local lastChildren = 0
local lastPlateScan = 0
local elapsed = 0
local shownNow, hiddenNow, shownMax = 0, 0, 0
local panel
local movables = {}    -- frames que podem ser arrastados com o painel aberto
local movableFrames = {}  -- os frames (nao os handles), para o "Reset positions"

local function Print(msg)
	if ( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99MASH|r: "..msg)
	end
end

local function ShortNumber(v)
	if ( v >= 1000000 ) then
		return string.format("%.1fm", v / 1000000)
	elseif ( v >= 10000 ) then
		return string.format("%.1fk", v / 1000)
	end
	return string.format("%d", v)
end

----------------------------------------------------------------------------------------------------
-- API do jogo (AZS_*): o cliente preenche essas globais com o estado da run. Versoes antigas do
-- jogo nao tem; tudo que usa a API cai no comportamento antigo quando ela falta.
----------------------------------------------------------------------------------------------------

-- Nivel dos bosses e guardioes, lido do alvo ou da nameplate e guardado pelo nome
-- (a API nao manda o nivel). "??" = nivel muito acima, como a caveira do quadro de alvo.
local levelSeen = {}

local function HasAPI()
	return type(AZS_GetPhase) == "function"
end

-- Campo de uma entrada das listas da API, que pode vir nomeado ou por posicao.
local function Field(entry, key, index)
	local v = entry[key]
	if ( v == nil ) then
		v = entry[index]
	end
	return v
end

-- Nomes dos elites, guardioes e bosses vivos agora (AZS_UNITS), refeito quando a lista muda.
local specialAlive = {}
local specialStamp

local function RefreshSpecialAlive()
	if ( not HasAPI() or type(AZS_UNITS) ~= "table" ) then
		return
	end
	if ( specialStamp == AZS_UNITS_UPDATED ) then
		return
	end
	specialStamp = AZS_UNITS_UPDATED
	specialAlive = {}
	for i = 1, table.getn(AZS_UNITS) do
		local name = Field(AZS_UNITS[i], "name", 3)
		if ( name ) then
			specialAlive[name] = true
		end
	end
end


-- Aprende a classe do monstro: pela API quando existe, senao pela classificacao do cliente.
local KIND_TO_CLASS = { final = "worldboss", boss = "worldboss", guardian = "elite", elite = "elite", normal = "normal" }

local function UnitClass2(unit)
	if ( HasAPI() and AZS_UnitKind ) then
		local kind = AZS_UnitKind(unit)
		if ( kind and KIND_TO_CLASS[kind] ) then
			return KIND_TO_CLASS[kind]
		end
	end
	return UnitClassification(unit)
end

----------------------------------------------------------------------------------------------------
-- Classificacao por nome
----------------------------------------------------------------------------------------------------

-- true = comum (esconder), false = elite/boss (mostrar), nil = ainda nao sabemos
local function IsNormal(name)
	local learned = DB.known[name]
	if ( learned ~= nil ) then
		return learned == "normal"
	end
	local seed = MASH_Seed and MASH_Seed[name]
	if ( seed ~= nil ) then
		return seed == 0
	end
	return nil
end

-- Os bosses do cronometro: rank 3 no cache do jogo, "worldboss" para o cliente.
local function IsBoss(name)
	if ( DB.known[name] == "worldboss" ) then
		return true
	end
	return MASH_Seed and MASH_Seed[name] == 3
end

-- Um nome visto uma vez como elite/boss nunca mais e tratado como comum.
local function Learn(unit)
	if ( not UnitExists(unit) or UnitIsPlayer(unit) ) then
		return
	end
	local name = UnitName(unit)
	local class = UnitClass2(unit)
	if ( not name or not class ) then
		return
	end
	local old = DB.known[name]
	if ( old and old ~= "normal" ) then
		return
	end
	DB.known[name] = class
end

----------------------------------------------------------------------------------------------------
-- Frames arrastaveis (so com o painel aberto); a posicao fica salva em DB.pos[nome]
----------------------------------------------------------------------------------------------------

local function PlaceMovable(frame)
	local p = DB.pos[frame:GetName()]
	frame:ClearAllPoints()
	local xlimit = math.max(0, (UIParent:GetWidth() - frame:GetWidth()) / 2)
	local ylimit = math.max(0, (UIParent:GetHeight() - frame:GetHeight()) / 2)
	frame:SetPoint("CENTER", UIParent, "CENTER", math.max(-xlimit, math.min(xlimit, tonumber(p[1]) or 0)), math.max(-ylimit, math.min(ylimit, tonumber(p[2]) or 0)))
end

-- freeDrag: arrastavel a qualquer hora (senao, so com o painel aberto).
-- handle: o frame que recebe o mouse (o cliente entrega o clique ao filho de cima, nao ao pai).
local function MakeMovable(frame, defaultX, defaultY, freeDrag, handle)
	handle = handle or frame
	if ( not frame.azsDefault ) then
		frame.azsDefault = { defaultX, defaultY }
		table.insert(movableFrames, frame)
	end
	if ( not DB.pos[frame:GetName()] ) then
		DB.pos[frame:GetName()] = { defaultX, defaultY }
	end
	PlaceMovable(frame)
	frame:SetMovable(1)
	if frame.SetClampedToScreen then frame:SetClampedToScreen(1) end
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		frame.azsMoving = true
		frame:StartMoving()
	end)
	handle:SetScript("OnDragStop", function()
		if ( not frame.azsMoving ) then
			return
		end
		frame.azsMoving = nil
		frame:StopMovingOrSizing()
		local x, y = frame:GetCenter()
		local px, py = UIParent:GetCenter()
		DB.pos[frame:GetName()] = { x - px, y - py }
		PlaceMovable(frame)
	end)
	handle.azsFreeDrag = freeDrag
	handle:EnableMouse(freeDrag and 1 or nil)
	table.insert(movables, handle)
end

local function SetMovablesUnlocked(unlocked)
	for i = 1, table.getn(movables) do
		if ( not movables[i].azsFreeDrag ) then
			movables[i]:EnableMouse(unlocked and 1 or nil)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Quadros de boss no estilo do quadro de alvo, no lugar das barras do HUD do jogo.
-- Mostra os bosses vivos (o final primeiro) e os guardioes acordados, empilhados.
----------------------------------------------------------------------------------------------------

local BOSS_FRAMES = 4
local BOSS_DEBUFFS = 6  -- icones de debuff por quadro
local DEBUFF_SIZE = 18
local BOSS_STACK = 106   -- distancia entre um quadro e o de baixo (a arte do dragao tem ~90)
local bossFrames = {}

-- Copia tamanho e ancora de uma peca do TargetFrame, se ela estiver ancorada nele.
local function MirrorTarget(owner, region, sourceName, fallbackPoint, fallbackX, fallbackY, fallbackW, fallbackH)
	local source = getglobal(sourceName)
	local point, relPoint, x, y = fallbackPoint, fallbackPoint, fallbackX, fallbackY
	local w, h = fallbackW, fallbackH
	if ( source ) then
		local p, rel, rp, sx, sy = source:GetPoint(1)
		if ( p and ( rel == TargetFrame or rel == TargetFrameTextureFrame ) ) then
			point, relPoint, x, y = p, rp or p, sx, sy
		end
		if ( source:GetWidth() and source:GetWidth() > 0 ) then
			w, h = source:GetWidth(), source:GetHeight()
		end
	end
	region:SetWidth(w)
	region:SetHeight(h)
	region:SetPoint(point, owner, relPoint, x, y)
end

local function CreateBossFrame(i)
	local f = CreateFrame("Frame", "MASHBossFrame"..i, UIParent)
	f:SetWidth(232)
	f:SetHeight(100)
	f:SetFrameStrata("LOW")

	f.portrait = f:CreateTexture("MASHBossFrame"..i.."Portrait", "BACKGROUND")
	MirrorTarget(f, f.portrait, "TargetPortrait", "TOPRIGHT", -42, -12, 64, 64)

	local nameBg = f:CreateTexture("MASHBossFrame"..i.."NameBackground", "BACKGROUND")
	nameBg:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
	nameBg:SetVertexColor(1.0, 0.0, 0.0)
	MirrorTarget(f, nameBg, "TargetFrameNameBackground", "TOPRIGHT", -88, -22, 119, 19)

	f.bar = CreateFrame("StatusBar", "MASHBossFrame"..i.."HealthBar", f)
	MirrorTarget(f, f.bar, "TargetFrameHealthBar", "TOPRIGHT", -106, -41, 119, 12)
	f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.bar:SetStatusBarColor(0.0, 1.0, 0.0)

	local border = CreateFrame("Frame", "MASHBossFrame"..i.."TextureFrame", f)
	border:SetAllPoints(f)
	border:SetFrameLevel(f.bar:GetFrameLevel() + 2)
	local tex = border:CreateTexture("MASHBossFrame"..i.."Texture", "BORDER")
	tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
	tex:SetTexCoord(0.09375, 1.0, 0.0, 0.78125)
	tex:SetWidth(232)
	tex:SetHeight(100)
	tex:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

	f.level = border:CreateFontString("MASHBossFrame"..i.."Level", "OVERLAY", "GameFontNormalSmall")
	f.skull = border:CreateTexture("MASHBossFrame"..i.."Skull", "OVERLAY")
	f.skull:SetTexture(PLATE_SKULL)
	MirrorTarget(f, f.skull, "TargetHighLevelTexture", "CENTER", 63, -16, 16, 16)
	if ( TargetLevelText ) then
		local p, rel, rp, x, y = TargetLevelText:GetPoint(1)
		if ( p and ( rel == TargetFrame or rel == TargetFrameTextureFrame ) ) then
			f.skull:ClearAllPoints()
			f.skull:SetPoint(p, f, rp, x, y)
		end
	end
	f.level:SetPoint("CENTER", f.skull, "CENTER", 0, 0)

	f.name = border:CreateFontString("MASHBossFrame"..i.."Name", "OVERLAY", "GameFontNormalSmall")
	MirrorTarget(f, f.name, "TargetName", "CENTER", -50, 19, 100, 10)
	f.hp = border:CreateFontString("MASHBossFrame"..i.."HealthText", "OVERLAY", "GameFontHighlightSmall")
	f.hp:SetPoint("CENTER", f.bar, "CENTER", 0, 0)
	f.tag = border:CreateFontString("MASHBossFrame"..i.."Tag", "OVERLAY", "GameFontNormalSmall")
	f.tag:SetPoint("TOP", f.bar, "BOTTOM", 0, -2)

	-- debuffs/DoTs do boss que e o alvo, numa fileira embaixo da barra
	f.debuffs = {}
	for d = 1, BOSS_DEBUFFS do
		local icon = border:CreateTexture("MASHBossFrame"..i.."Debuff"..d, "OVERLAY")
		icon:SetWidth(DEBUFF_SIZE)
		icon:SetHeight(DEBUFF_SIZE)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon:SetPoint("TOPLEFT", f.bar, "BOTTOMLEFT", ( d - 1 ) * ( DEBUFF_SIZE + 1 ), -15)
		icon:Hide()
		icon.count = border:CreateFontString("MASHBossFrame"..i.."Debuff"..d.."Count", "OVERLAY", "NumberFontNormalSmall")
		icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
		icon.count:Hide()
		-- tempo restante embaixo do icone
		icon.time = border:CreateFontString("MASHBossFrame"..i.."Debuff"..d.."Time", "OVERLAY", "GameFontHighlightSmall")
		icon.time:SetFont(MENU_FONT, 10, "OUTLINE")
		icon.time:SetPoint("TOP", icon, "BOTTOM", 0, -1)
		icon.time:Hide()
		f.debuffs[d] = icon
	end

	if ( i == 1 ) then
		-- o primeiro e arrastavel (camada por cima de tudo); os outros vao embaixo dele
		local handle = CreateFrame("Frame", "MASHBossFrame1Handle", f)
		handle:SetAllPoints(f)
		handle:SetFrameLevel(border:GetFrameLevel() + 5)
		MakeMovable(f, 0, 150, true, handle)
	else
		f:SetPoint("TOP", bossFrames[i - 1], "TOP", 0, -BOSS_STACK)
	end
	f:Hide()
	return f
end

local function CreateBossFrames()
	for i = 1, BOSS_FRAMES do
		bossFrames[i] = CreateBossFrame(i)
	end
end

-- Liga/desliga as barras de boss do proprio HUD. So mexe nelas se o MASH as trocou.
local function SyncHudBosses()
	if ( not HasAPI() or not AZS_SetHudShown ) then
		return
	end
	if ( DB.bossFrame ) then
		AZS_SetHudShown("bosses", false)
		DB.hudBossesHidden = true
	elseif ( DB.hudBossesHidden ) then
		AZS_SetHudShown("bosses", true)
		DB.hudBossesHidden = nil
	end
end

local function ShowBossFrame(f, name, hp, hpm, kind, state, id)
	f.name:SetText(name)
	f.bar:SetMinMaxValues(0, math.max(hpm or 1, 1))
	f.bar:SetValue(hp or 0)
	MASH_Text(f.hp,MASH_FormatHealth(hp, hpm, DB.bossHealthMode))
	if ( kind == "guardian" ) then
		MASH_Text(f.tag,"|cffffd100"..MASH_L("Guardian").."|r")
	elseif ( state == 1 or state == true ) then
		MASH_Text(f.tag,"|cffff2020"..MASH_L("ENRAGED").."|r")
	elseif ( kind == "final" ) then
		MASH_Text(f.tag,"|cffff8000"..MASH_L("Final boss").."|r")
	else
		MASH_Text(f.tag,"")
	end
	-- nivel: do alvo, se for ele, senao o ultimo lido da nameplate; "??" ou desconhecido = caveira
	if ( UnitExists("target") and UnitName("target") == name ) then
		local lvl = UnitLevel("target")
		levelSeen[name] = ( lvl and lvl > 0 ) and tostring(lvl) or "??"
	end
	local lvl = levelSeen[name]
	if ( lvl and lvl ~= "??" ) then
		MASH_Text(f.level,lvl)
		f.level:Show()
		f.skull:Hide()
	elseif ( lvl == "??" or kind ~= "guardian" ) then
		f.level:Hide()
		f.skull:Show()
	else
		f.level:Hide()
		f.skull:Hide()
	end
	-- Imagem fixa por tipo, no lugar do retrato: o retrato do cliente fica preso ao alvo ao vivo
	-- (troca em todos os quadros quando o alvo muda) e nao da para soltar.
	-- Debuffs: pela API (AZS_GetDebuffs), os de cada boss/guardiao pelo id, com tempo restante.
	-- Sem ela, o cliente so diz os debuffs do alvo (UnitDebuff), sem tempo.
	local list = {}
	if ( id and AZS_GetDebuffs ) then
		local debuffs = AZS_GetDebuffs(id)
		for d = 1, table.getn(debuffs) do
			local icon = debuffs[d].icon
			if ( icon and icon ~= "" and not string.find(icon, "\\", 1, 1) ) then
				icon = "Interface\\Icons\\"..icon
			end
			table.insert(list, { texture = icon, count = debuffs[d].stacks, left = debuffs[d].remaining })
		end
	elseif ( UnitExists("target") and UnitName("target") == name ) then
		for d = 1, 16 do
			local texture, count = UnitDebuff("target", d)
			if ( not texture ) then
				break
			end
			table.insert(list, { texture = texture, count = count })
		end
	end
	local n = math.min(table.getn(list), BOSS_DEBUFFS)
	for d = 1, n do
		local slot, info = f.debuffs[d], list[d]
		slot:SetTexture(info.texture)
		slot:Show()
		if ( info.count and info.count > 1 ) then
			MASH_Text(slot.count,info.count)
			slot.count:Show()
		else
			slot.count:Hide()
		end
		if ( info.left and info.left > 0 ) then
			MASH_Text(slot.time,info.left < 10 and string.format("%.1f", info.left) or string.format("%d", info.left))
			slot.time:Show()
		else
			slot.time:Hide()
		end
	end
	for d = n + 1, BOSS_DEBUFFS do
		f.debuffs[d]:Hide()
		f.debuffs[d].count:Hide()
		f.debuffs[d].time:Hide()
	end

	MASH_Portraits.Apply(f, name, kind, id)

	f:Show()
end

local function UpdateBossFrame()
	if ( table.getn(bossFrames) == 0 ) then
		return
	end
	local n = 0
	if ( DB.bossFrame and HasAPI() and type(AZS_UNITS) == "table" ) then
		local phase = AZS_GetPhase()
		if ( phase and phase ~= "ready" ) then
			-- bosses (o final vem primeiro na lista) e depois os guardioes acordados
			for pass = 1, 2 do
				for i = 1, table.getn(AZS_UNITS) do
					local e = AZS_UNITS[i]
					local kind = Field(e, "kind", 1)
					local state = Field(e, "state", 6)
					local wanted
					if ( pass == 1 ) then
						wanted = ( kind == "final" or kind == "boss" )
					else
						wanted = ( kind == "guardian" and ( state == 1 or state == true ) )
					end
					if ( wanted and n < BOSS_FRAMES ) then
						n = n + 1
						ShowBossFrame(bossFrames[n], Field(e, "name", 3), Field(e, "hp", 4), Field(e, "hpm", 5), kind, state, Field(e, "id", 2))
					end
				end
			end
		end
	end
	-- com o painel aberto e nada vivo, um quadro de exemplo para posicionar
	if ( n == 0 and DB.bossFrame and panel and panel:IsShown() ) then
		n = 1
		ShowBossFrame(bossFrames[1], "Boss", 1, 1, "boss", 0)
		MASH_Text(bossFrames[1].hp,"drag to move")
	end
	for i = n + 1, BOSS_FRAMES do
		bossFrames[i]:Hide()
	end
end


----------------------------------------------------------------------------------------------------
-- Nameplates
----------------------------------------------------------------------------------------------------

local ApplyPlate, Drop

local function RegisterPlate(frame)
	if ( plates[frame] ~= nil ) then
		return
	end
	plates[frame] = false
	if ( frame:GetObjectType() ~= "Button" or frame:GetName() ) then
		return
	end
	local regions = { frame:GetRegions() }
	local border = regions[1]
	if ( not border or border:GetObjectType() ~= "Texture" or border:GetTexture() ~= PLATE_BORDER ) then
		-- um botao sem nome pode ser uma plate ainda sendo montada: tenta de novo na proxima varredura
		plates[frame] = nil
		return
	end
	local info = { frame = frame, parts = {} }
	for i = 1, table.getn(regions) do
		local r = regions[i]
		table.insert(info.parts, r)
		if ( not info.name and r:GetObjectType() == "FontString" ) then
			info.name = r
		elseif ( not info.level and r:GetObjectType() == "FontString" ) then
			info.level = r
		elseif ( r:GetObjectType() == "Texture" and r:GetTexture() == PLATE_SKULL ) then
			info.skull = r
		end
	end
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		table.insert(info.parts, children[i])
		if ( children[i]:GetObjectType() == "StatusBar" ) then
			info.bar = children[i]
		end
	end
	if ( not info.name ) then
		return
	end
	plates[frame] = info
	table.insert(plateList, frame)
	-- aplica no mesmo instante em que o cliente mostra a plate, sem esperar o proximo quadro
	local previous = frame:GetScript("OnShow")
	frame:SetScript("OnShow", function()
		if ( previous ) then
			previous()
		end
		if ( DB and not frame.azsReparenting and frame.azsReparentTime ~= GetTime() ) then
			ApplyPlate(info, true)
		end
	end)
	-- ao sumir, volta para a camada invisivel: se o cliente a reaproveitar para um monstro comum,
	-- ela ja reaparece escondida
	local previousHide = frame:GetScript("OnHide")
	frame:SetScript("OnHide", function()
		if ( previousHide ) then
			previousHide()
		end
		if ( DB and DB.hidePlates and not frame.azsReparenting and frame.azsReparentTime ~= GetTime() ) then
			Drop(frame)
		end
	end)
end

local function SetPlateAlpha(info, alpha)
	for i = 1, table.getn(info.parts) do
		info.parts[i]:SetAlpha(alpha)
	end
end

-- Decide e aplica a transparencia de uma plate; devolve true se ela ficou escondida.
-- Anti-piscar: com o filtro ligado o WorldFrame fica transparente, entao toda plate nova ja nasce
-- invisivel. As que devem aparecer sao "levantadas" para o UIParent, com a escala compensada
-- para continuarem no mesmo lugar e tamanho; as outras voltam para o WorldFrame.
-- Neste cliente trocar o pai da plate dispara OnShow/OnHide nela. Esses avisos vindos da nossa
-- propria troca sao ignorados (durante a troca e no mesmo quadro dela); senao, mostrar uma plate de elite fazia o
-- OnShow trata-la como plate nova e esconde-la de novo, num ciclo sem fim.
local function Lift(frame)
	if ( frame:GetParent() ~= UIParent ) then
		frame.azsReparenting = true
		frame.azsReparentTime = GetTime()
		frame:SetParent(UIParent)
		frame.azsReparenting = nil
	end
	frame:SetScale(WorldFrame:GetEffectiveScale() / UIParent:GetEffectiveScale())
end

function Drop(frame)
	if ( frame:GetParent() ~= WorldFrame ) then
		frame.azsReparenting = true
		frame.azsReparentTime = GetTime()
		frame:SetParent(WorldFrame)
		frame:SetScale(1)
		frame.azsReparenting = nil
	end
end

-- Quantas passadas seguidas o nome tem de ficar igual antes de a plate poder aparecer. Quando o
-- cliente reaproveita uma plate de elite para um monstro comum, ela chega por um instante com o
-- nome antigo; sem essa espera, ela piscava visivel antes de o nome novo chegar.
local PLATE_STABLE = 2

-- justShown: chamada pelo OnShow; a plate fica escondida ate o nome se firmar.
function ApplyPlate(info, justShown)
	local name = info.name:GetText() or ""
	if ( info.level and name ~= "" and not justShown and name == info.lastName ) then
		local lvl = info.level:GetText()
		if ( lvl and lvl ~= "" ) then
			if ( info.skull and info.skull:IsShown() ) then
				lvl = "??"
			end
			levelSeen[name] = lvl
		end
	end
	if ( justShown or name ~= info.lastName ) then
		info.lastName = name
		info.stable = 0
	else
		info.stable = ( info.stable or 0 ) + 1
	end
	local skull = info.skull and info.skull:IsShown()
	local hide = false
	if ( DB.hidePlates and not NAMEPLATES_ON ) then
		-- V desligado: nem elites nem bosses
		hide = true
	elseif ( DB.hidePlates and info.stable < PLATE_STABLE ) then
		-- nome recem-chegado ou trocado: espera ele se firmar
		hide = true
	elseif ( DB.hidePlates and ( HasAPI() or not skull ) ) then
		-- (sem a API, a caveira de nivel alto vale como boss; com a API, a lista de especiais decide)
		local normal = IsNormal(name)
		if ( name == "" or name == UNKNOWNOBJECT or name == UNKNOWN ) then
			-- a plate pode aparecer um instante antes do nome do monstro chegar
			hide = true
		elseif ( specialAlive[name] or IsBoss(name) ) then
			-- a API diz que ha um elite/guardiao/boss vivo com esse nome, ou ele ja e conhecido como boss
			hide = false
		elseif ( normal == nil ) then
			-- desconhecido: com a API, quem nao esta na lista de especiais e comum
			hide = HasAPI() or DB.hideUnknown
		else
			hide = normal
		end
	end
	-- Sem estado guardado: o cliente recicla as plates entre monstros, entao tudo e reaplicado
	-- sempre, nos dois sentidos.
	SetPlateAlpha(info, hide and 0 or 1)
	if ( not DB.hidePlates ) then
		-- filtro desligado: o WorldFrame volta a ser visivel e nao importa onde a plate esta
	elseif ( hide ) then
		Drop(info.frame)
	else
		Lift(info.frame)
	end
	return hide
end

local function UpdatePlates()
	RefreshSpecialAlive()
	local alpha = DB.hidePlates and 0 or 1
	if ( WorldFrame:GetAlpha() ~= alpha ) then
		WorldFrame:SetAlpha(alpha)
	end
	-- Varre quando a quantidade de filhos muda e tambem 4x por segundo: uma plate pode ser criada
	-- no mesmo instante em que outra sobe para o UIParent, e ai a quantidade nao muda.
	local n = WorldFrame:GetNumChildren()
	local now = GetTime()
	if ( n ~= lastChildren or now - lastPlateScan > 0.25 ) then
		lastChildren = n
		lastPlateScan = now
		local children = { WorldFrame:GetChildren() }
		for i = 1, table.getn(children) do
			local child = children[i]
			RegisterPlate(child)
			-- o que nao e nameplate (ex.: balao de fala) continua visivel
			if ( plates[child] == false and DB.hidePlates ) then
				Lift(child)
			end
		end
	end

	local shown, hidden = 0, 0
	for i = 1, table.getn(plateList) do
		local frame = plateList[i]
		local info = plates[frame]
		if ( frame:IsShown() ) then
			if ( ApplyPlate(info) ) then
				hidden = hidden + 1
			end
			shown = shown + 1
		end
	end
	shownNow, hiddenNow = shown, hidden
	if ( shown > shownMax ) then
		shownMax = shown
	end
end

-- A tecla V (Bindings.xml) chama ShowNameplates/HideNameplates e guarda o estado em NAMEPLATES_ON.
-- Com o filtro ligado, as plates do cliente ficam sempre ativas por baixo (sao elas que dizem onde
-- esta cada monstro e quanta vida ele tem) e NAMEPLATES_ON passa a valer so para elites e bosses.
local NativeShowNameplates, NativeHideNameplates = ShowNameplates, HideNameplates

ShowNameplates = function()
	NativeShowNameplates()
end

HideNameplates = function()
	if ( DB and DB.hidePlates ) then
		return
	end
	NativeHideNameplates()
end

-- Poe as plates do cliente no estado certo para o modo atual.
local function SyncNativePlates()
	if ( DB.hidePlates or NAMEPLATES_ON ) then
		NativeShowNameplates()
	else
		NativeHideNameplates()
	end
end

local function SetEnemyPlates(on)
	if ( on ) then
		NAMEPLATES_ON = 1
		ShowNameplates()
	else
		NAMEPLATES_ON = nil
		HideNameplates()
	end
end

local function SetFilter(on)
	DB.hidePlates = on
	SyncNativePlates()
end

----------------------------------------------------------------------------------------------------
-- Camera: distancia maxima em jardas (o cliente guarda como fator sobre 15 jardas)
----------------------------------------------------------------------------------------------------

local function ApplyCamera(zoomOut)
	if ( not DB.cameraMax ) then
		return
	end
	SetCVar("cameraDistanceMaxFactor", string.format("%.3f", DB.cameraMax / CAMERA_BASE))
	if ( zoomOut and CameraZoomOut ) then
		CameraZoomOut(DB.cameraMax)
	end
end

----------------------------------------------------------------------------------------------------
-- Vida do alvo em numeros, sobre a barra de vida do TargetFrame
----------------------------------------------------------------------------------------------------

local targetHealthText

local function UpdateTargetHealth()
	if ( not TargetFrame or not TargetFrameHealthBar ) then
		return
	end
	if ( not targetHealthText ) then
		-- num frame proprio, acima da moldura do TargetFrame
		local holder = CreateFrame("Frame", "MASHTargetHealth", TargetFrame)
		holder:SetFrameLevel(TargetFrame:GetFrameLevel() + 5)
		holder:SetAllPoints(TargetFrameHealthBar)
		targetHealthText = holder:CreateFontString("MASHTargetHealthText", "OVERLAY", "GameFontHighlightSmall")
		targetHealthText:SetPoint("CENTER", holder, "CENTER", 0, 0)
	end
	if ( not DB.targetHealth or not UnitExists("target") ) then
		MASH_Text(targetHealthText,"")
		return
	end
	local cur, max = UnitHealth("target") or 0, UnitHealthMax("target") or 0
	if ( UnitIsDead("target") ) then
		cur = 0
	end
	MASH_Text(targetHealthText,MASH_FormatHealth(cur, max, DB.targetHealthMode))
end

----------------------------------------------------------------------------------------------------
-- Barra de vida do jogador, logo abaixo do personagem
----------------------------------------------------------------------------------------------------

local playerBar

local lowTestUntil = 0  -- "Test" no painel: simula a vida baixa por alguns segundos

local function UpdatePlayerBar()
	if ( not playerBar ) then
		return
	end
	if ( not DB.playerBar ) then
		playerBar:Hide()
		return
	end
	local max = UnitHealthMax("player") or 0
	if ( max <= 0 ) then
		max = 1
	end
	local cur = UnitHealth("player") or 0
	playerBar:SetMinMaxValues(0, max)
	playerBar:SetValue(cur)
    if playerBar.healthText then
        MASH_Text(playerBar.healthText,MASH_FormatHealth(cur, max, DB.playerHealthMode))
    end

	-- escudo de absorcao (API): faixa azul-clara sobre a barra e o valor em numero no meio
	local shield = 0
	if ( DB.playerShield and HasAPI() and type(AZS_RUN) == "table" ) then
		shield = AZS_RUN.sh or 0
	end
	if ( shield > 0 ) then
		playerBar.shield:SetWidth(math.max(1, playerBar:GetWidth() * math.min(shield / max, 1)))
		playerBar.shield:Show()
		MASH_Text(playerBar.shieldText,ShortNumber(shield))
		playerBar.shieldText:Show()
	else
		playerBar.shield:Hide()
		playerBar.shieldText:Hide()
	end
	local low = GetTime() < lowTestUntil
		or ( DB.lowHealth and not UnitIsDeadOrGhost("player") and cur / max * 100 < DB.lowHealthPct )
	if ( low and not playerBar.low and DB.lowHealthSound ) then
		-- som so na hora em que cruza o limite, nao a cada atualizacao
		if ( not pcall(PlaySound, "RaidWarning") ) then
			pcall(PlaySound, "igQuestFailed")
		end
	end
	playerBar.low = low
	if ( not low ) then
		playerBar:SetStatusBarColor(0.1, 0.9, 0.1)
		playerBar.glow:Hide()
	else
		playerBar.glow:Show()
	end
	playerBar:Show()
end

-- Com a vida baixa, a barra pisca entre vermelho vivo e vermelho escuro (chamado no OnUpdate).
local function PulsePlayerBar()
	if ( playerBar and playerBar.low ) then
		local p = 0.5 + 0.5 * math.sin(GetTime() * 10)
		playerBar:SetStatusBarColor(0.5 + 0.5 * p, 0.05, 0.05)
		playerBar.glow:SetAlpha(0.25 + 0.6 * p)
	end
end

local function TestLowHealth()
	lowTestUntil = GetTime() + 3
	UpdatePlayerBar()
end

local function CreatePlayerBar()
	playerBar = CreateFrame("StatusBar", "MASHPlayerBar", UIParent)
	playerBar:SetWidth(120)
	playerBar:SetHeight(9)
	playerBar:SetFrameStrata("LOW")
    playerBar.healthText = playerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    playerBar.healthText:SetPoint("BOTTOM", playerBar, "TOP", 0, 3)
	playerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	playerBar:SetStatusBarColor(0.1, 0.9, 0.1)
	local bg = playerBar:CreateTexture("MASHPlayerBarBg", "BACKGROUND")
	bg:SetTexture(0, 0, 0, 0.6)
	bg:SetPoint("TOPLEFT", playerBar, "TOPLEFT", -1, 1)
	bg:SetPoint("BOTTOMRIGHT", playerBar, "BOTTOMRIGHT", 1, -1)
	-- brilho vermelho em volta da barra, so com a vida baixa
	playerBar.glow = playerBar:CreateTexture("MASHPlayerBarGlow", "BACKGROUND")
	playerBar.glow:SetTexture(1.0, 0.0, 0.0, 1.0)
	playerBar.glow:SetPoint("TOPLEFT", playerBar, "TOPLEFT", -4, 4)
	playerBar.glow:SetPoint("BOTTOMRIGHT", playerBar, "BOTTOMRIGHT", 4, -4)
	playerBar.glow:Hide()
	-- escudo: faixa por cima do preenchimento verde, a partir da esquerda, e o numero centralizado
	playerBar.shield = playerBar:CreateTexture("MASHPlayerBarShield", "OVERLAY")
	playerBar.shield:SetTexture(0.55, 0.85, 1.0, 0.75)
	playerBar.shield:SetPoint("TOPLEFT", playerBar, "TOPLEFT", 0, 0)
	playerBar.shield:SetPoint("BOTTOMLEFT", playerBar, "BOTTOMLEFT", 0, 0)
	playerBar.shield:Hide()
	playerBar.shieldText = playerBar:CreateFontString("MASHPlayerBarShieldText", "OVERLAY", "GameFontHighlightSmall")
	playerBar.shieldText:SetFont(MENU_FONT, 11, "OUTLINE")
	playerBar.shieldText:SetTextColor(0.75, 0.92, 1.0)
	playerBar.shieldText:SetPoint("CENTER", playerBar, "CENTER", 0, 1)
	playerBar.shieldText:Hide()
	MakeMovable(playerBar, DB.playerBarX or 0, DB.playerBarY or -70)
	UpdatePlayerBar()
end

-- Icones dos buffs ativos, centralizados logo abaixo da barra verde (vao junto quando ela move).
local BUFF_SIZE, BUFF_GAP, BUFF_MAX = 18, 2, 10
local buffRow
local buffIcons = {}

local function BuffIcon(i)
	local icon = buffIcons[i]
	if ( icon ) then
		return icon
	end
	icon = CreateFrame("Frame", "MASHPlayerBuff"..i, buffRow)
	icon:SetWidth(BUFF_SIZE)
	icon:SetHeight(BUFF_SIZE)
	icon.texture = icon:CreateTexture("MASHPlayerBuff"..i.."Icon", "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.time = icon:CreateFontString("MASHPlayerBuff"..i.."Time", "OVERLAY", "GameFontHighlightSmall")
	icon.time:SetPoint("TOP", icon, "BOTTOM", 0, -1)
	buffIcons[i] = icon
	return icon
end

local function FormatBuffTime(t)
	if ( not t or t <= 0 ) then
		return ""
	elseif ( t < 60 ) then
		return string.format("%d", t)
	end
	return string.format(MASH_L("%dm"), math.ceil(t / 60))
end

local function UpdatePlayerBuffs()
	if ( not buffRow ) then
		return
	end
	local n = 0
	if ( DB.playerBuffs ) then
		for i = 0, 31 do
			if ( n >= BUFF_MAX ) then
				break
			end
			local index = GetPlayerBuff(i, "HELPFUL")
			if ( not index or index < 0 ) then
				break
			end
			local texture = GetPlayerBuffTexture(index)
			if ( texture ) then
				n = n + 1
				local icon = BuffIcon(n)
				icon.texture:SetTexture(texture)
				MASH_Text(icon.time,FormatBuffTime(GetPlayerBuffTimeLeft(index)))
				icon:ClearAllPoints()
				icon:SetPoint("TOPLEFT", buffRow, "TOPLEFT", ( n - 1 ) * ( BUFF_SIZE + BUFF_GAP ), 0)
				icon:Show()
			end
		end
	end
	for i = n + 1, table.getn(buffIcons) do
		buffIcons[i]:Hide()
	end
	buffRow:SetWidth(math.max(1, n * ( BUFF_SIZE + BUFF_GAP ) - BUFF_GAP))
end

local function CreatePlayerBuffs()
	buffRow = CreateFrame("Frame", "MASHPlayerBuffs", playerBar)
	buffRow:SetHeight(BUFF_SIZE)
	buffRow:SetPoint("TOP", playerBar, "BOTTOM", 0, -3)
	UpdatePlayerBuffs()
end

----------------------------------------------------------------------------------------------------
-- Resumo de status, das mensagens "AZS" que o servidor manda (as mesmas da ficha do personagem)
----------------------------------------------------------------------------------------------------

-- Acessorios (em cima), status e ouro (embaixo) formam uma pilha de janelas com a mesma largura.
local STACK_WIDTH = 200

local statsFrame
local statsPicker
local stats

local function Pct(v)
	return string.format("%+.0f%%", v * 100)
end

local function PctOf(v, fmt)
	return string.format(fmt, v * 100)
end

-- Todos os status que a ficha do personagem mostra, na mesma ordem e no mesmo formato.
-- { id, rotulo, funcao que formata a partir da tabela de status }
local STATS = {
	{ "hp", "Health", function(s) return string.format("%.0f", s.hp) end },
	{ "dmg", "Damage", function(s) return Pct(s.dmg - 1) end },
	{ "haste", "Haste", function(s) return Pct(1 - s.cd) end },
	{ "crit", "Crit Chance", function(s) return PctOf(s.crit, "%.1f%%") end },
	{ "cm", "Crit Dmg", function(s) return PctOf(s.cm, "%.0f%%") end },
	{ "arm", "Armor", function(s) return PctOf(s.arm, "%.0f%%") end },
	{ "area", "Area", function(s) return Pct(s.area - 1) end },
	{ "cnt", "Targets", function(s) return string.format("+%d", s.cnt) end },
	{ "echo", "Echo", function(s) return PctOf(s.echo, "%.0f%%") end },
	{ "spd", "Speed", function(s) return Pct(s.spd - 1) end },
	{ "reg", "Regen", function(s) return string.format("%.1f", s.reg) end },
	{ "pick", "Pickup", function(s) return string.format(MASH_L("%.0f yd"), s.pick) end },
	{ "lch", "Lifesteal", function(s) return PctOf(s.lch, "%.1f%%") end },
	{ "heal", "Kill Heal", function(s) return string.format("%.0f", s.heal) end },
	{ "thn", "Thorns", function(s) return PctOf(s.thn, "%.0f%%") end },
	{ "liv", "Lives", function(s) return string.format("%d", s.liv) end },
	{ "xp", "Experience", function(s) return Pct(s.xp - 1) end },
	{ "gold", "Gold", function(s) return Pct(s.gold - 1) end },
	{ "luck", "Luck", function(s) return Pct(s.luck) end },
	{ "bp", "Buff Power", function(s) return Pct(s.bp) end },
	{ "dots", "DoT Stacks", function(s) return string.format("%d", s.dots) end },
	{ "doth", "DoT Haste", function(s) return Pct(s.doth) end },
	{ "big", "Vs Elites", function(s) return Pct(s.big) end },
	{ "exe", "Execute", function(s) return Pct(s.exe) end },
	{ "cc", "Vs Controlled", function(s) return Pct(s.cc) end },
	{ "dotd", "Vs Afflicted", function(s) return Pct(s.dotd) end },
	{ "shd", "Shielded", function(s) return Pct(s.shd) end },
	{ "auto", "Melee", function(s) return Pct(s.auto) end },
	{ "pet", "Pet Damage", function(s) return Pct(s.pet) end },
}

local DEFAULT_SHOWN = { "crit", "cm", "dmg", "haste", "luck", "xp", "gold", "lch", "heal" }

local function ParseStats(msg)
	local t, pos = {}, 1
	while ( true ) do
		local first, last, k, v = string.find(msg, "(%w+)=([^;]*)", pos)
		if ( not first ) then
			break
		end
		t[k] = tonumber(v) or 0
		pos = last + 1
	end
	return t
end

local function StatsRow(i)
	local row = statsFrame.rows[i]
	if ( row ) then
		return row
	end
	row = {}
	row.label = statsFrame:CreateFontString("MASHStatsLabel"..i, "OVERLAY", "GameFontNormalSmall")
	row.label:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 9, -8 - 13 * ( i - 1 ))
	row.value = statsFrame:CreateFontString("MASHStatsValue"..i, "OVERLAY", "GameFontHighlightSmall")
	row.value:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -27, -8 - 13 * ( i - 1 ))
	statsFrame.rows[i] = row
	return row
end

-- Shared collapse controls for the stats and accessories panels.
local function ApplyCompactPanel(f, key, expandedHeight)
    if not f then return end
    local collapsed = DB[key]
    f:SetHeight(collapsed and 23 or expandedHeight)
    local rows = f.rows or f.slots or {}
    for i = 1, table.getn(rows) do
        local row = rows[i]
        -- Accessories uses child frames; hiding their fontstrings directly
        -- leaves them hidden after the parent is expanded again.
        if f.slots then
            if collapsed then row:Hide() else row:Show() end
        else
            if collapsed then
                if row.label then row.label:Hide() end
                if row.value then row.value:Hide() end
            end
            -- Stats visibility is managed by UpdateStatsFrame.
        end
    end
    if f.mashCollapseButton then
        MASH_Text(f.mashCollapseButton,collapsed and "+" or "-")
    end
end
local function AddCompactButton(f, key, refresh)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetWidth(18); b:SetHeight(17)
    b:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    MASH_Text(b,DB[key] and "+" or "-")
    b:SetFrameLevel(f:GetFrameLevel() + 10)
    b:SetScript("OnClick", function() DB[key] = not DB[key]; refresh() end)
    f.mashCollapseButton = b
end

local function UpdateStatsFrame()
	if ( not statsFrame ) then
		return
	end
	local n = 0
	for i = 1, table.getn(STATS) do
		local def = STATS[i]
		if ( DB.shownStats[def[1]] ) then
			n = n + 1
			local row = StatsRow(n)
			local value = "-"
			if ( stats ) then
				local ok, text = pcall(def[3], stats)
				value = ok and text or "?"
			end
			MASH_Text(row.label,def[2])
			row.value:SetText(value)
			row.label:Show()
			row.value:Show()
		end
	end
	for i = n + 1, table.getn(statsFrame.rows) do
		statsFrame.rows[i].label:Hide()
		statsFrame.rows[i].value:Hide()
	end
	if ( not DB.statsFrame or n == 0 ) then
		statsFrame:Hide()
		return
	end
	statsFrame:SetHeight(14 + 13 * n)
	ApplyCompactPanel(statsFrame, "statsCollapsed", 14 + 13 * n)
	statsFrame:Show()
end

local function CreateStatsFrame()
	statsFrame = CreateFrame("Frame", "MASHStatsFrame", UIParent)
	statsFrame:SetFrameStrata("LOW")
	statsFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	statsFrame:SetBackdropColor(0, 0, 0, 0.6)
	statsFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	statsFrame:SetWidth(STACK_WIDTH)
	statsFrame:SetHeight(20)
	statsFrame.rows = {}
	AddCompactButton(statsFrame, "statsCollapsed", UpdateStatsFrame)
	MakeMovable(statsFrame, UIParent:GetWidth() / 2 - 100, 0, true)
	-- depois de um /reload no meio da run o jogo so manda numeros novos na proxima mudanca;
	-- ate la valem os ultimos recebidos (guardados no DB)
	if ( type(AZS_STATS) == "table" ) then
		stats = AZS_STATS
	elseif ( type(DB.lastStats) == "table" ) then
		stats = DB.lastStats
	end
	UpdateStatsFrame()
end

-- Fonte do menu num tamanho e cor (a fonte do template fica como reserva se a do jogo faltar).
local function MenuFont(fs, size, r, g, b)
	fs:SetFont(MENU_FONT, size)
	if ( r ) then
		fs:SetTextColor(r, g, b)
	end
end

-- Visual comum das janelas do MASH: fundo escuro translucido, borda fina dourada e barra de titulo.
local function StyleWindow(f, titleText, subtitleText)
	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	f:SetBackdropColor(0.04, 0.04, 0.06, 0.94)
	f:SetBackdropBorderColor(0.75, 0.62, 0.25, 1.0)

	local bar = f:CreateTexture(nil, "ARTWORK")
	bar:SetTexture(1.0, 0.82, 0.0, 0.10)
	bar:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
	bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
	bar:SetHeight(22)
	local line = f:CreateTexture(nil, "ARTWORK")
	line:SetTexture(1.0, 0.82, 0.0, 0.35)
	line:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
	line:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
	line:SetHeight(1)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", bar, "LEFT", 8, 0)
	MASH_Text(title,titleText)
	if ( subtitleText ) then
		local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		MenuFont(subtitle, 13, 0.7, 0.7, 0.7)
		subtitle:SetPoint("LEFT", title, "RIGHT", 8, 0)
		MASH_Text(subtitle,subtitleText)
	end

	local close = CreateFrame("Button", f:GetName().."Close", f, "UIPanelCloseButton")
	close:SetWidth(24)
	close:SetHeight(24)
	close:SetPoint("RIGHT", bar, "RIGHT", 2, 0)
	close:SetFrameLevel(f:GetFrameLevel() + 10)
	close:SetScript("OnClick", function() this:GetParent():Hide() end)

	f:SetFrameStrata("DIALOG")
	f:SetToplevel(1)
	f:EnableMouse(1)
	f:SetMovable(1)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function() this:StartMoving() end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
end

-- Lista compacta de status, uma caixa por linha; o que estiver marcado aparece no resumo da tela.
-- Abre encostada ao lado do menu do MASH.
local PICKER_ROW = 15

local function CreateStatsPicker()
	statsPicker = CreateFrame("Frame", "MASHStatsPicker", UIParent)
	statsPicker:SetWidth(168)
	statsPicker:SetHeight(38 + PICKER_ROW * table.getn(STATS))
	StyleWindow(statsPicker, "Stats")

	statsPicker.checks = {}
	for i = 1, table.getn(STATS) do
		local def = STATS[i]
		local check = CreateFrame("CheckButton", "MASHStatsPickerCheck"..i, statsPicker, "UICheckButtonTemplate")
		check:SetWidth(18)
		check:SetHeight(18)
		check:SetPoint("TOPLEFT", statsPicker, "TOPLEFT", 8, -32 - PICKER_ROW * ( i - 1 ))
		if ( check.SetHitRectInsets ) then
			check:SetHitRectInsets(0, -130, 0, 0)  -- clicar no nome tambem marca
		end
		local label = check:CreateFontString("MASHStatsPickerCheck"..i.."Label", "OVERLAY", "GameFontHighlightSmall")
		MenuFont(label, 13)
		label:SetPoint("LEFT", check, "RIGHT", 2, 1)
		MASH_Text(label,def[2])
		check:SetScript("OnClick", function()
			DB.shownStats[def[1]] = this:GetChecked() and true or nil
			UpdateStatsFrame()
		end)
		statsPicker.checks[i] = check
	end
	statsPicker:SetScript("OnShow", function()
		for i = 1, table.getn(STATS) do
			this.checks[i]:SetChecked(DB.shownStats[STATS[i][1]] and 1 or nil)
		end
	end)
	statsPicker:Hide()
end

local function ToggleStatsPicker()
	if ( not statsPicker ) then
		CreateStatsPicker()
	end
	if ( statsPicker:IsShown() ) then
		statsPicker:Hide()
		return
	end
	statsPicker:ClearAllPoints()
	if ( panel and panel:IsShown() ) then
		statsPicker:SetPoint("TOPLEFT", panel, "TOPRIGHT", 2, 0)
	else
		statsPicker:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end
	statsPicker:Show()
end

-- Janelinha de ouro, colada embaixo do resumo de status: ouro da run e preco do proximo baú.
-- O cliente nao passa o preco do baú para a interface, mas ele segue uma regra fixa: o 1o custa 20
-- e cada um custa o anterior x 1.3 + 5, arredondado para baixo (20, 31, 45, 63, 86, 116, 155, 206,
-- 272, 358, 470, 616...; conferido no jogo). Cada ouro gasto com um desses valores diz qual baú
-- foi aberto, entao a contagem se acerta sozinha mesmo depois de um /reload.
local moneyFrame
local lastGold

-- GetMoney vem em cobre; o ouro da run e o mesmo numero do HUD do jogo.
local function RunGold()
	if ( HasAPI() and type(AZS_RUN) == "table" and AZS_RUN.gold ) then
		return AZS_RUN.gold
	end
	return math.floor(( GetMoney() or 0 ) / 10000)
end

-- Preco do n-esimo baú da run (conta inteira, sem erro de ponto flutuante).
local function ChestPrice(n)
	local price = 20
	for i = 2, n do
		price = math.floor(( price * 13 + 50 ) / 10)
	end
	return price
end

local function ChestCost()
	if ( HasAPI() and type(AZS_RUN) == "table" and AZS_RUN.chest ) then
		return AZS_RUN.chest
	end
	if ( DB.chestsOpened < 0 ) then
		return nil
	end
	return ChestPrice(DB.chestsOpened + 1)
end

local function NoteGoldChange()
	local gold = RunGold()
	if ( lastGold and gold < lastGold ) then
		local paid = lastGold - gold
		-- acha qual baú custa exatamente o que foi pago; gasto com outro valor = contagem perdida
		local n = -1
		for i = 1, 60 do
			local price = ChestPrice(i)
			if ( price == paid ) then
				n = i
				break
			elseif ( price > paid ) then
				break
			end
		end
		DB.chestsOpened = n
	end
	lastGold = gold
end

-- Numero curto para a linha de kills/ouro/bau caber na janela mesmo com valores enormes:
-- ate 9999 inteiro, depois 99.9k, 999k, 9.9m (truncado, nunca arredonda para cima).
local function Compact(v)
	v = v or 0
	if ( v < 10000 ) then
		return string.format("%d", v)
	elseif ( v < 100000 ) then
		return string.format("%.1fk", math.floor(v / 100) / 10)
	elseif ( v < 1000000 ) then
		return string.format(MASH_L("%dk"), math.floor(v / 1000))
	end
	return string.format("%.1fm", math.floor(v / 100000) / 10)
end

local function UpdateMoneyFrame()
	if ( not moneyFrame ) then
		return
	end
	-- nunca pode ficar escondida nem fora da tela
	if ( not moneyFrame:IsShown() ) then
		moneyFrame:Show()
	end
	local cx, cy = moneyFrame:GetCenter()
	if ( cx and ( cx < 0 or cy < 0 or cx > UIParent:GetWidth() or cy > UIParent:GetHeight() ) ) then
		if ( DB.moneyDetached and DB.pos["MASHMoneyFrame"] and moneyFrame.azsDefault ) then
			-- Clamp the displayed location; retain the user's original saved coordinates.
			PlaceMovable(moneyFrame)
		end
	end
	local gold = RunGold()
	MASH_Text(moneyFrame.gold,Compact(gold))
	local chestCost = ChestCost()
	if ( chestCost ) then
		MASH_Text(moneyFrame.chest,Compact(chestCost))
		if ( chestCost > gold ) then
			moneyFrame.chest:SetTextColor(1.0, 0.1, 0.1)
		else
			moneyFrame.chest:SetTextColor(0.1, 1.0, 0.1)
		end
	else
		MASH_Text(moneyFrame.chest,"?")
		moneyFrame.chest:SetTextColor(0.6, 0.6, 0.6)
	end
	-- kills na mesma linha, antes do ouro (no lugar da caixa "Kills / Gold / cache" do HUD)
	-- kills a esquerda; ouro e preco do bau juntos na direita, para comparar de relance
	if ( DB.replaceTally and HasAPI() and type(AZS_RUN) == "table" and AZS_RUN.kills ) then
		MASH_Text(moneyFrame.kills,Compact(AZS_RUN.kills))
		moneyFrame.kills:Show()
		moneyFrame.killsLabel:Show()
	else
		moneyFrame.kills:Hide()
		moneyFrame.killsLabel:Hide()
	end
end

-- Esconde a caixa de kills/gold do HUD so enquanto o MASH a substitui; devolve se foi desligado.
local function SyncHudTally()
	if ( not HasAPI() or not AZS_SetHudShown ) then
		return
	end
	if ( DB.replaceTally ) then
		AZS_SetHudShown("tally", false)
		DB.hudTallyHidden = true
	elseif ( DB.hudTallyHidden ) then
		AZS_SetHudShown("tally", true)
		DB.hudTallyHidden = nil
	end
end

local function CreateMoneyFrame()
	moneyFrame = CreateFrame("Frame", "MASHMoneyFrame", UIParent)
	moneyFrame:SetFrameStrata("LOW")
	moneyFrame:SetClampedToScreen(1)
	moneyFrame:SetWidth(statsFrame:GetWidth())
	moneyFrame:SetHeight(22)
	moneyFrame:SetPoint("TOPLEFT", statsFrame, "BOTTOMLEFT", 0, -2)
	moneyFrame:SetBackdrop(statsFrame:GetBackdrop())
	moneyFrame:SetBackdropColor(0, 0, 0, 0.6)
	moneyFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

	local coin = moneyFrame:CreateTexture("MASHMoneyFrameCoin", "ARTWORK")
	coin:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
	coin:SetTexCoord(0, 0.25, 0, 1)
	coin:SetWidth(12)
	coin:SetHeight(12)
	moneyFrame.coin = coin
	moneyFrame.gold = moneyFrame:CreateFontString("MASHMoneyFrameGold", "OVERLAY", "GameFontHighlightSmall")
	coin:SetPoint("RIGHT", moneyFrame.gold, "LEFT", -3, 0)

	moneyFrame.chest = moneyFrame:CreateFontString("MASHMoneyFrameChest", "OVERLAY", "GameFontHighlightSmall")
	moneyFrame.chest:SetPoint("RIGHT", moneyFrame, "RIGHT", -9, 0)
	local label = moneyFrame:CreateFontString("MASHMoneyFrameChestLabel", "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("RIGHT", moneyFrame.chest, "LEFT", -3, 0)
	moneyFrame.gold:SetPoint("RIGHT", label, "LEFT", -12, 0)
	MASH_Text(label,"Chest:")

	moneyFrame.killsLabel = moneyFrame:CreateFontString("MASHMoneyFrameKillsLabel", "OVERLAY", "GameFontNormalSmall")
	moneyFrame.killsLabel:SetPoint("LEFT", moneyFrame, "LEFT", 9, 0)
	MASH_Text(moneyFrame.killsLabel,"Kills:")
	moneyFrame.kills = moneyFrame:CreateFontString("MASHMoneyFrameKills", "OVERLAY", "GameFontHighlightSmall")
	moneyFrame.kills:SetPoint("LEFT", moneyFrame.killsLabel, "RIGHT", 3, 0)

	-- arrastar a janelinha move o conjunto
	MakeMovable(statsFrame, UIParent:GetWidth() / 2 - 100, 0, true, moneyFrame)
	UpdateMoneyFrame()
end

-- Resumo dos acessorios da run: o que esta em cada espaco, ou vazio.
local GEAR_SLOTS = {
	{ 2, "Amulet" },
	{ 13, "Trinket 1" },
	{ 14, "Trinket 2" },
	{ 11, "Ring 1" },
	{ 12, "Ring 2" },
}

local gearFrame
local scanTip
local ReadSlot

-- Le um espaco de equipamento: pelo link do item, senao pelo icone + nome do tooltip.
-- Devolve nome (ja colorido, quando houver cor) e textura; nil, nil = vazio.
function ReadSlot(slotId)
	local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", slotId)
	local link = GetInventoryItemLink and GetInventoryItemLink("player", slotId)
	if ( link ) then
		local _, _, color = string.find(link, "|c(%x%x%x%x%x%x%x%x)")
		local _, _, name = string.find(link, "%[(.-)%]")
		return ( color and "|c"..color or "" )..( name or link ).."|r", texture
	end
	if ( not scanTip ) then
		scanTip = CreateFrame("GameTooltip", "MASHScanTip", nil, "GameTooltipTemplate")
	end
	scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scanTip:ClearLines()
	scanTip:SetInventoryItem("player", slotId)
	local line = MASHScanTipTextLeft1
	local name = line and line:IsShown() and line:GetText()
	if ( name and name ~= "" ) then
		local r, g, b = line:GetTextColor()
		return string.format(MASH_L("|cff%02x%02x%02x%s|r"), r * 255, g * 255, b * 255, name), texture
	end
	return nil, texture
end

local function UpdateGearFrame()
	if ( not gearFrame ) then
		return
	end
	if ( not DB.gearFrame ) then
		gearFrame:Hide()
		return
	end
	local y = -8
	for i = 1, table.getn(GEAR_SLOTS) do
		local slot = GEAR_SLOTS[i]
		local row = gearFrame.slots[i]
		local name, texture = ReadSlot(slot[1])
		MASH_Text(row.label,slot[2])
		if ( name or texture ) then
			row.value:SetText(name or "|cff9d9d9d"..MASH_L("(worn)").."|r")
			row.icon:SetTexture(texture)
			row.icon:Show()
		else
			row.value:SetText("|cffff5555"..MASH_L("empty").."|r")
			row.icon:Hide()
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", gearFrame, "TOPLEFT", 6, y)
		row:SetPoint("RIGHT", gearFrame, "RIGHT", i == 1 and -26 or -6, 0)
		y = y - 18
	end

	gearFrame:SetHeight(-y + 6)
	ApplyCompactPanel(gearFrame, "gearCollapsed", -y + 6)
	gearFrame:Show()
end

local function CreateGearFrame()
	gearFrame = CreateFrame("Frame", "MASHGearFrame", UIParent)
	gearFrame:SetFrameStrata("LOW")
	gearFrame:SetWidth(STACK_WIDTH)
	gearFrame:SetHeight(100)
	gearFrame:SetBackdrop(statsFrame:GetBackdrop())
	gearFrame:SetBackdropColor(0, 0, 0, 0.6)
	gearFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	gearFrame.slots = {}
	AddCompactButton(gearFrame, "gearCollapsed", UpdateGearFrame)
	for i = 1, table.getn(GEAR_SLOTS) do
		local slotId = GEAR_SLOTS[i][1]
		local row = CreateFrame("Frame", "MASHGearSlot"..i, gearFrame)
		row:SetHeight(16)
		row:EnableMouse(1)
		row.icon = row:CreateTexture("MASHGearSlot"..i.."Icon", "ARTWORK")
		row.icon:SetWidth(14)
		row.icon:SetHeight(14)
		row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.label = row:CreateFontString("MASHGearSlot"..i.."Label", "OVERLAY", "GameFontNormalSmall")
		row.label:SetPoint("LEFT", row, "LEFT", 20, 0)
		row.value = row:CreateFontString("MASHGearSlot"..i.."Value", "OVERLAY", "GameFontHighlightSmall")
		row.value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
		row.value:SetPoint("LEFT", row, "LEFT", 80, 0)
		row.value:SetJustifyH("RIGHT")
		-- passar o mouse mostra o item como no WoW
		row:SetScript("OnEnter", function()
			if ( GetInventoryItemLink and GetInventoryItemLink("player", slotId) ) then
				GameTooltip:SetOwner(this, "ANCHOR_LEFT")
				GameTooltip:SetInventoryItem("player", slotId)
				GameTooltip:Show()
			end
		end)
		row:SetScript("OnLeave", function() GameTooltip:Hide() end)
		-- as linhas cobrem o quadro, entao elas tambem servem para arrastar
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function() gearFrame:GetScript("OnDragStart")() end)
		row:SetScript("OnDragStop", function() gearFrame:GetScript("OnDragStop")() end)
		gearFrame.slots[i] = row
	end
	-- colada em cima do resumo de status; arrastar move a pilha toda
	gearFrame:SetPoint("BOTTOMLEFT", statsFrame, "TOPLEFT", 0, 2)
	MakeMovable(statsFrame, UIParent:GetWidth() / 2 - 100, 0, true, gearFrame)
	UpdateGearFrame()
end

----------------------------------------------------------------------------------------------------
-- Medidor de dano (AZS_GetMeter) e dano recebido por fonte (AZS_TAKEN), em duas janelas
-- empilhadas: o medidor em cima e o recebido colado embaixo. So existem com a API do jogo.
-- O medidor do proprio jogo nunca e escondido: os dois convivem.
----------------------------------------------------------------------------------------------------

local METER_WIDTH = 220
local METER_ROWS = 8
local TAKEN_ROWS = 6
local ROW_HEIGHT = 15
local meterFrame, takenFrame
local meterStamp, takenStamp

local TAKEN_NAMES = {
	["boss melee"] = "Boss melee",
	["boss spell"] = "Boss spells",
	["elite"] = "Elites",
	["mob melee"] = "Monster melee",
	["mob spell"] = "Monster spells",
	["area"] = "Ground effects",
}

-- Janela com titulo, total a direita e linhas com barra de fundo.
local function CreateBarWindow(name, title, rows)
	local f = CreateFrame("Frame", name, UIParent)
	f:SetFrameStrata("LOW")
	f.mashCollapsed = false
	f.mashExpandHeight = 0
	f:SetWidth(METER_WIDTH)
	f:SetHeight(26 + ROW_HEIGHT * rows)
	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	f:SetBackdropColor(0, 0, 0, 0.6)
	f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	f.title = f:CreateFontString(name.."Title", "OVERLAY", "GameFontNormalSmall")
	f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 9, -7)
	MASH_Text(f.title,title)
	f.total = f:CreateFontString(name.."Total", "OVERLAY", "GameFontHighlightSmall")
	f.total:SetPoint("TOPRIGHT", f, "TOPRIGHT", -25, -7)
	local collapse = CreateFrame("Button", name.."Collapse", f, "UIPanelButtonTemplate")
	collapse:SetWidth(18); collapse:SetHeight(17)
	collapse:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
	MASH_Text(collapse,"-")
	collapse:SetFrameLevel(f:GetFrameLevel() + 10)
	collapse:SetScript("OnClick", function()
		local collapsed = not f.mashCollapsed
		f.mashCollapsed = collapsed
		DB.collapsedWindows = DB.collapsedWindows or {}
		DB.collapsedWindows[name] = collapsed or nil
		if collapsed then
			f.mashExpandHeight = f:GetHeight()
			f:SetHeight(24); f.total:Hide()
			for j = 1, table.getn(f.rows) do f.rows[j]:Hide() end
			MASH_Text(this,"+")
		else
			f:SetHeight(f.mashExpandHeight > 24 and f.mashExpandHeight or 45)
			f.total:Show(); MASH_Text(this,"-")
		end
	end)
	f.mashCollapseButton = collapse
	f.rows = {}
	for i = 1, rows do
		local row = CreateFrame("StatusBar", name.."Row"..i, f)
		row:SetHeight(ROW_HEIGHT - 2)
		row:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -22 - ROW_HEIGHT * ( i - 1 ))
		row:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -22 - ROW_HEIGHT * ( i - 1 ))
		row:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		row:SetMinMaxValues(0, 1)
		row.label = row:CreateFontString(name.."Row"..i.."Label", "OVERLAY", "GameFontHighlightSmall")
		row.label:SetPoint("LEFT", row, "LEFT", 3, 0)
		row.value = row:CreateFontString(name.."Row"..i.."Value", "OVERLAY", "GameFontHighlightSmall")
		row.value:SetPoint("RIGHT", row, "RIGHT", -3, 0)
		row.label:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
		row.label:SetJustifyH("LEFT")
		-- as linhas cobrem a janela, entao repassam o arrastar para ela
		row:EnableMouse(1)
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function() f:GetScript("OnDragStart")() end)
		row:SetScript("OnDragStop", function() f:GetScript("OnDragStop")() end)
		row:Hide()
		f.rows[i] = row
	end
	if DB and DB.collapsedWindows and DB.collapsedWindows[name] then
		f.mashCollapsed = true; f.mashExpandHeight = f:GetHeight()
		f:SetHeight(24); f.total:Hide(); MASH_Text(collapse,"+")
	end
	return f
end

-- Mostra n linhas e ajusta a altura da janela.
local function FitRows(f, n)
	for i = n + 1, table.getn(f.rows) do
		f.rows[i]:Hide()
	end
	local height = 28 + ROW_HEIGHT * math.max(n, 1)
	f.mashExpandHeight = height
	if f.mashCollapsed then
		f.total:Hide()
		for i = 1, table.getn(f.rows) do f.rows[i]:Hide() end
		f:SetHeight(24)
	else f:SetHeight(height); f.total:Show() end
end

local function InRun()
	return HasAPI() and AZS_GetPhase() ~= nil
end

local function UpdateMeterFrame(force)
	if ( not meterFrame ) then
		return
	end
	if ( not DB.meterFrame or not InRun() or not AZS_GetMeter ) then
		meterFrame:Hide()
		return
	end
	if ( not force and meterStamp == AZS_METER_UPDATED and meterFrame:IsShown() ) then
		return
	end
	meterStamp = AZS_METER_UPDATED
	local lines, total, dps = AZS_GetMeter()
	lines = lines or {}
	MASH_Text(meterFrame.total,ShortNumber(total or 0).."  ("..ShortNumber(dps or 0).." dps)")
	local top = lines[1] and lines[1].dmg or 1
	local n = math.min(table.getn(lines), METER_ROWS)
	for i = 1, n do
		local line = lines[i]
		local row = meterFrame.rows[i]
		row:SetValue(( line.dmg or 0 ) / math.max(top, 1))
		if ( line.proc == 1 ) then
			-- dano de talento/amuleto: azul, como no medidor do jogo
			row:SetStatusBarColor(0.25, 0.45, 0.9, 0.55)
		else
			row:SetStatusBarColor(0.8, 0.55, 0.1, 0.55)
		end
		row.label:SetText(line.name or "?") -- native spell name
		row.value:SetText(string.format("%s  %.0f%%", ShortNumber(line.dps or 0), ( line.share or 0 ) * 100))
		row:Show()
	end
	FitRows(meterFrame, n)
	meterFrame:Show()
end

local function UpdateTakenFrame(force)
	if ( not takenFrame ) then
		return
	end
	if ( not DB.takenFrame or not InRun() or type(AZS_TAKEN) ~= "table" ) then
		takenFrame:Hide()
		return
	end
	if ( not force and takenStamp == AZS_TAKEN_UPDATED and takenFrame:IsShown() ) then
		return
	end
	takenStamp = AZS_TAKEN_UPDATED
	local sum = 0
	for i = 1, table.getn(AZS_TAKEN) do
		sum = sum + ( Field(AZS_TAKEN[i], "dmg", 2) or 0 )
	end
	MASH_Text(takenFrame.total,ShortNumber(sum))
	local top = AZS_TAKEN[1] and Field(AZS_TAKEN[1], "dmg", 2) or 1
	local n = math.min(table.getn(AZS_TAKEN), TAKEN_ROWS)
	for i = 1, n do
		local source = Field(AZS_TAKEN[i], "source", 1) or "?"
		local dmg = Field(AZS_TAKEN[i], "dmg", 2) or 0
		local row = takenFrame.rows[i]
		row:SetValue(dmg / math.max(top, 1))
		row:SetStatusBarColor(0.75, 0.1, 0.1, 0.55)
		MASH_Text(row.label,TAKEN_NAMES[source] or source)
		row.value:SetText(string.format("%s  %.0f%%", ShortNumber(dmg), 100 * dmg / math.max(sum, 1)))
		row:Show()
	end
	FitRows(takenFrame, n)
	takenFrame:Show()
end

-- Uma versao de teste do MASH escondia o medidor do jogo; aqui ele e devolvido, uma vez.
local function SyncHudMeter()
	if ( DB.hudMeterHidden and HasAPI() and AZS_SetHudShown ) then
		AZS_SetHudShown("meter", true)
		DB.hudMeterHidden = nil
	end
end

local function CreateMeterFrames()
	meterFrame = CreateBarWindow("MASHMeterFrame", "Damage", METER_ROWS)
	takenFrame = CreateBarWindow("MASHTakenFrame", "Damage taken", TAKEN_ROWS)
	-- o recebido fica colado embaixo do medidor; arrastar qualquer um move os dois
	takenFrame:SetPoint("TOPLEFT", meterFrame, "BOTTOMLEFT", 0, -2)
	MakeMovable(meterFrame, -( UIParent:GetWidth() / 2 - 140 ), 60, true)
	MakeMovable(meterFrame, -( UIParent:GetWidth() / 2 - 140 ), 60, true, takenFrame)
	meterFrame:Hide()
	takenFrame:Hide()
end

local function UpdateMeterFrames(force)
	UpdateMeterFrame(force)
	UpdateTakenFrame(force)
	-- sem o medidor, o recebido sobe para o lugar dele
	if ( takenFrame ) then
		takenFrame:ClearAllPoints()
		if ( meterFrame:IsShown() ) then
			takenFrame:SetPoint("TOPLEFT", meterFrame, "BOTTOMLEFT", 0, -2)
		else
			takenFrame:SetPoint("TOPLEFT", meterFrame, "TOPLEFT", 0, 0)
		end
	end
end

local ResetMapZone, UpdateChestPins, UpdateLairFrame, CreateLairFrame
do
----------------------------------------------------------------------------------------------------
-- Posicoes no mapa (API): os baus (AZS_CHESTS) e os covis (AZS_LAIRS) vem com a posicao no mapa
-- da zona (mx, my de 0 a 1) e no mundo (x, y). O tamanho do mapa em jardas sai de dois desses
-- pontos; a posicao do jogador vem de GetPlayerMapPosition.
----------------------------------------------------------------------------------------------------

-- Diametro do minimapa em jardas por nivel de zoom (ao ar livre, valores do 1.12).
local MINIMAP_YARDS = { [0] = 466.6667, 400, 333.3333, 266.6667, 200, 133.3333 }
local mapYardsW, mapYardsH      -- jardas que o mapa da zona tem de largura e altura
local mapStamp
local mapZoneSet

-- Mede as jardas do mapa pelos pares de pontos mais afastados (x do mundo e norte/sul, y e leste/oeste).
local function CalibrateMap()
	local stamp = ( AZS_CHESTS_UPDATED or 0 ) + ( AZS_LAIRS_UPDATED or 0 )
	if ( stamp == mapStamp ) then
		return
	end
	mapStamp = stamp
	local pts = {}
	local lists = { AZS_LAIRS, AZS_CHESTS }
	for l = 1, 2 do
		if ( type(lists[l]) == "table" ) then
			for i = 1, table.getn(lists[l]) do
				local p = lists[l][i]
				if ( tonumber(p.mx) and p.mx >= 0 and tonumber(p.x) ) then
					table.insert(pts, p)
				end
			end
		end
	end
	local bestX, bestY = 0, 0
	for i = 1, table.getn(pts) do
		for j = i + 1, table.getn(pts) do
			local a, b = pts[i], pts[j]
			local dmx, dmy = math.abs(a.mx - b.mx), math.abs(a.my - b.my)
			if ( dmx > bestX and dmx > 0.01 ) then
				bestX = dmx
				mapYardsW = math.abs(a.y - b.y) / dmx
			end
			if ( dmy > bestY and dmy > 0.01 ) then
				bestY = dmy
				mapYardsH = math.abs(a.x - b.x) / dmy
			end
		end
	end
end

function ResetMapZone()
	mapZoneSet = nil
end

-- Posicao do jogador no mapa da zona (o mapa do mundo e apontado para a zona atual so quando preciso).
local function PlayerMapPos()
	if ( not mapZoneSet and not ( WorldMapFrame and WorldMapFrame:IsVisible() ) and SetMapToCurrentZone ) then
		SetMapToCurrentZone()
		mapZoneSet = true
	end
	local px, py = GetPlayerMapPosition("player")
	if ( not px or ( px == 0 and py == 0 ) ) then
		mapZoneSet = nil
		return nil
	end
	return px, py
end

-- Leste e norte (em jardas) de um ponto do mapa em relacao ao jogador; nil sem dados.
local function MapOffset(mx, my, px, py)
	if ( not mapYardsW or not mapYardsH or not tonumber(mx) or mx < 0 ) then
		return nil
	end
	return ( mx - px ) * mapYardsW, ( py - my ) * mapYardsH
end

----------------------------------------------------------------------------------------------------
-- Baus no minimapa: um ponto laranja por bau; os que estao fora do alcance ficam presos na borda,
-- menores e meio apagados, apontando a direcao.
----------------------------------------------------------------------------------------------------

-- World-position projection lives in its own Lua 5.0-sized module.
function UpdateChestPins()
 if MASH_UpdateWorldPins then MASH_UpdateWorldPins() end
end

----------------------------------------------------------------------------------------------------
-- Covis dos guardioes: uma linha por covil com o guardiao, o estado (dormindo, acordado, vazio e
-- quanto falta para encher) e a distancia.
----------------------------------------------------------------------------------------------------

local LAIR_ROWS = 10
local LAIR_DIST_COLORS = { { 0.2, 1.0, 0.2 }, { 1.0, 1.0, 0.2 }, { 1.0, 0.55, 0.1 }, { 1.0, 0.2, 0.2 } }
local lairFrame

local function FormatClock(s)
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", math.floor(s / 60), s - 60 * math.floor(s / 60))
end

function UpdateLairFrame()
	if ( not lairFrame ) then
		return
	end
	if ( not DB.lairFrame or not HasAPI() or not AZS_GetLairs or not AZS_GetPhase() ) then
		lairFrame:Hide()
		return
	end
	local lairs = AZS_GetLairs()
	if ( table.getn(lairs) == 0 ) then
		lairFrame:Hide()
		return
	end
	CalibrateMap()
	local px, py = PlayerMapPos()
	local held = 0
	local n = math.min(table.getn(lairs), LAIR_ROWS)

	-- distancia de cada covil e a ordem do mais perto ao mais longe, para colorir as jardas
	local dists, order = {}, {}
	for i = 1, n do
		if ( px ) then
			local east, north = MapOffset(lairs[i].mx, lairs[i].my, px, py)
			if ( east ) then
				dists[i] = math.sqrt(east * east + north * north)
				table.insert(order, i)
			end
		end
	end
	table.sort(order, function(a, b) return dists[a] < dists[b] end)
	local rank = {}
	for k = 1, table.getn(order) do
		rank[order[k]] = k
	end
	-- a lista aparece do mais perto ao mais longe; covis sem distancia conhecida vao no fim
	local display = {}
	for k = 1, table.getn(order) do
		table.insert(display, order[k])
	end
	for i = 1, n do
		if ( not dists[i] ) then
			table.insert(display, i)
		end
	end

	for k = 1, n do
		local i = display[k]
		local l = lairs[i]
		local row = lairFrame.rows[k]
		local state, r, g, b
		if ( l.state == "awake" ) then
			state, r, g, b = "awake", 1.0, 0.25, 0.25
			held = held + 1
		elseif ( l.state == "asleep" ) then
			state, r, g, b = "asleep", 0.2, 1.0, 0.2  -- vivo no covil: verde
			held = held + 1
		elseif ( tonumber(l.left) and l.left > 0 ) then
			state, r, g, b = MASH_L("back in ")..FormatClock(l.left), 0.6, 0.6, 0.6
		else
			state, r, g, b = "empty", 0.6, 0.6, 0.6
		end
		row:SetValue(0)
		row.label:SetText(l.name or "?") -- native creature name
		row.label:SetTextColor(r, g, b)
		row.value:SetText(MASH_L(state))
		row.value:SetTextColor(r, g, b)
		if ( dists[i] ) then
			-- mais perto verde, depois amarelo, laranja, e o resto (o mais longe) vermelho
			local c = LAIR_DIST_COLORS[math.min(rank[i], table.getn(LAIR_DIST_COLORS))]
			if ( rank[i] == table.getn(order) and table.getn(order) > 1 ) then
				c = LAIR_DIST_COLORS[table.getn(LAIR_DIST_COLORS)]
			end
			MASH_Text(row.dist,string.format(MASH_L("%d yd"), dists[i]))
			row.dist:SetTextColor(c[1], c[2], c[3])
		else
			MASH_Text(row.dist,"")
		end
		row:Show()
	end
	MASH_Text(lairFrame.total,held.." / "..table.getn(lairs)..MASH_L(" held"))
	FitRows(lairFrame, n)
	lairFrame:Show()
end

function CreateLairFrame()
	lairFrame = CreateBarWindow("MASHLairFrame", "Lairs", LAIR_ROWS)
	-- a distancia tem coluna e cor proprias, na direita; o estado fica antes dela
	for i = 1, LAIR_ROWS do
		local row = lairFrame.rows[i]
		row.dist = row:CreateFontString("MASHLairFrameRow"..i.."Dist", "OVERLAY", "GameFontHighlightSmall")
		row.dist:SetPoint("RIGHT", row, "RIGHT", -3, 0)
		row.dist:SetWidth(44)
		row.dist:SetJustifyH("RIGHT")
		row.value:ClearAllPoints()
		row.value:SetPoint("RIGHT", row.dist, "LEFT", -4, 0)
		row.label:ClearAllPoints()
		row.label:SetPoint("LEFT", row, "LEFT", 3, 0)
		row.label:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
	end
	MakeMovable(lairFrame, -( UIParent:GetWidth() / 2 - 140 ), -170, true)
	lairFrame:Hide()
end

end

----------------------------------------------------------------------------------------------------
-- Numeros de dano sobre os monstros: sao as CVars do proprio cliente ("Show Target Damage" nas
-- opcoes de Combat, e as dos pets). So mexe nelas quando a opcao muda ou ao entrar no mundo.
----------------------------------------------------------------------------------------------------

local DAMAGE_CVARS = { "CombatDamage", "PetMeleeDamage", "PetSpellDamage" }

local function ApplyDamageNumbers()
	if ( DB.hideDamage == nil ) then
		return
	end
	for i = 1, table.getn(DAMAGE_CVARS) do
		pcall(SetCVar, DAMAGE_CVARS[i], DB.hideDamage and "0" or "1")
	end
end

-- Explicit user action from the scrolling text editor; existing switches stay available.
function MASH_UseCombatTextOnly()
 if not DB then return end
 DB.combatText=true;DB.hideDamage=true;DB.showCrits=false
 ApplyDamageNumbers()
end

----------------------------------------------------------------------------------------------------
-- Seus criticos acima do personagem. Vem das mensagens de combate do jogo ("Your Holy Shock crits
-- X for 370 Holy damage." / "You crit X for 120."). Cada critico vira uma linha de uma lista
-- flutuante: a nova entra embaixo e empurra as outras para cima, sem sobrepor. Com DB.groupCrits,
-- os criticos de cada intervalo curto viram uma linha so (o maior, com "xN").
----------------------------------------------------------------------------------------------------

local CRIT_WINDOW = 0.25  -- agrupado: segundos juntando criticos numa linha
local CRIT_LIFE = 1.6     -- segundos que cada linha fica na tela
local CRIT_LINES = 8      -- linhas no maximo
local CRIT_GAP = 17       -- distancia entre linhas
local critHolder
local critLines = {}      -- da mais nova (1) para a mais velha
local critPending         -- agrupado: { best, count, since } do intervalo atual

local function CreateCritLine(i)
	local line = {}
	line.value = critHolder:CreateFontString("MASHCrit"..i, "OVERLAY", "GameFontNormalLarge")
	line.value:SetTextColor(1.0, 0.85, 0.1)
	line.count = critHolder:CreateFontString("MASHCrit"..i.."Count", "OVERLAY", "GameFontHighlightSmall")
	line.count:SetTextColor(1.0, 0.85, 0.1)
	line.count:SetPoint("LEFT", line.value, "RIGHT", 3, -2)
	return line
end

local function PlaceCritHolder()
	critHolder:ClearAllPoints()
	if ( playerBar and playerBar:IsShown() ) then
		critHolder:SetPoint("BOTTOM", playerBar, "TOP", 0, 80)
	else
		critHolder:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
	end
end

local function AddCritLine(amount, count)
	if ( not critHolder ) then
		critHolder = CreateFrame("Frame", "MASHCrits", UIParent)
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
	MASH_Text(line.value,amount)
	MASH_Text(line.count,count > 1 and ( "x"..count ) or "")
end

local function ShowCrit(amount)
	amount = tonumber(amount) or 0
	if ( not DB.groupCrits ) then
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
local function AnimateCrits()
	if not DB.showCrits then
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

local function CheckCritMessage(msg)
	if ( not DB.showCrits or not msg ) then
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

local CreateCompactBar, UpdateCompactXP, KeepCompactBar, AttachMoneyToBar
do
----------------------------------------------------------------------------------------------------
-- Barra compacta: neste jogo so existem 6 magias (slots 1-6) e a racial (slot 12). Os proprios
-- botoes do WoW sao levados para um painel pequeno com a barra de XP embaixo, e a barra grande
-- (com bolsas, setas de pagina e botoes de menu) some. Do menu so fica o botao do "computador"
-- e os outros botoes de menu vao para o canto inferior direito, e a linha de kills/ouro/bau vai
-- para cima dela. Arrastar
-- um botao so reordena as magias.
-- Ligar/desligar recarrega a interface.
----------------------------------------------------------------------------------------------------

local BAR_SLOTS = { 1, 2, 3, 4, 5, 6, 12 }
local BAR_BUTTON = 36
local BAR_GAP = 4
local BAR_PAD = 6
local XP_HEIGHT = 7
local XP_SEGMENTS = 10
local compactBar
local PlaceMicroMenu

-- Arrastar so troca magias de lugar dentro da barra: soltar em cima de outro botao troca as duas;
-- soltar fora nao faz nada (no WoW, soltar fora tira a magia da barra).
local dragSource

local function SlotOf(b)
	if ( ActionButton_GetPagedID ) then
		return ActionButton_GetPagedID(b)
	end
	return b:GetID()
end

local function SwapSlots(a, b)
	ClearCursor()
	PickupAction(a)   -- a magia de A vai para o cursor
	PlaceAction(b)    -- entra em B; a de B vai para o cursor
	PlaceAction(a)    -- e entra em A
	ClearCursor()
end

local function HookBarDrag(b)
	if ( b.azsSwap ) then
		return
	end
	b.azsSwap = true
	b:RegisterForDrag("LeftButton")
	b:SetScript("OnDragStart", function()
		dragSource = this
		this:SetAlpha(0.4)
	end)
	b:SetScript("OnDragStop", function()
		local source = dragSource
		dragSource = nil
		if ( not source ) then
			return
		end
		source:SetAlpha(1)
		for i = 1, table.getn(BAR_SLOTS) do
			local target = getglobal("ActionButton"..BAR_SLOTS[i])
			if ( target and target ~= source and MouseIsOver(target) ) then
				SwapSlots(SlotOf(source), SlotOf(target))
				return
			end
		end
	end)
end

-- Botoes de menu (personagem, talentos, mapa, menu do jogo, ajuda): os que o jogo deixa visiveis
-- vao juntos para o canto inferior direito da tela.
local MICRO_BUTTONS = { "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"QuestLogMicroButton", "SocialsMicroButton", "WorldMapMicroButton", "MainMenuMicroButton", "HelpMicroButton" }
local microMenu
local microShown   -- nomes dos botoes que o jogo mostrava antes de a barra grande sumir

function PlaceMicroMenu()
	if ( not microMenu ) then
		microShown = {}
		for i = 1, table.getn(MICRO_BUTTONS) do
			local b = getglobal(MICRO_BUTTONS[i])
			if ( b and b:IsShown() ) then
				table.insert(microShown, MICRO_BUTTONS[i])
			end
		end
		microMenu = CreateFrame("Frame", "MASHMicroMenu", UIParent)
		microMenu:SetHeight(38)
		microMenu:SetWidth(math.max(1, table.getn(microShown) * 25 + 3))
		microMenu:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 2)
	end
	local prev
	for i = 1, table.getn(microShown) do
		local b = getglobal(microShown[i])
		b:SetParent(microMenu)
		b:ClearAllPoints()
		if ( prev ) then
			b:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", -3, 0)
		else
			b:SetPoint("BOTTOMLEFT", microMenu, "BOTTOMLEFT", 0, 0)
		end
		b:Show()
		prev = b
	end
end

local function PlaceBarButtons()
	for i = 1, table.getn(BAR_SLOTS) do
		local b = getglobal("ActionButton"..BAR_SLOTS[i])
		if ( b ) then
			if ( b:GetParent() ~= compactBar ) then
				b:SetParent(compactBar)
			end
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", compactBar, "TOPLEFT", BAR_PAD + ( i - 1 ) * ( BAR_BUTTON + BAR_GAP ), -BAR_PAD)
			HookBarDrag(b)
			b:Show()
		end
	end
	PlaceMicroMenu()
end

function UpdateCompactXP()
	if ( not compactBar ) then
		return
	end
	local cur, max = UnitXP("player") or 0, UnitXPMax("player") or 0
	compactBar.xp:SetMinMaxValues(0, math.max(max, 1))
	compactBar.xp:SetValue(cur)
	MASH_Text(compactBar.xpText,"XP "..cur.." / "..max)
end

function CreateCompactBar()
	if ( not DB.compactBar or not MainMenuBar ) then
		return
	end
	local slots = table.getn(BAR_SLOTS)
	compactBar = CreateFrame("Frame", "MASHCompactBar", UIParent)
	compactBar:SetWidth(BAR_PAD * 2 + slots * BAR_BUTTON + ( slots - 1 ) * BAR_GAP)
	compactBar:SetHeight(BAR_PAD * 3 + BAR_BUTTON + XP_HEIGHT)
	compactBar:SetFrameStrata("MEDIUM")
	compactBar:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	compactBar:SetBackdropColor(0, 0, 0, 0.7)
	compactBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)

	-- barra de XP roxa, dividida em segmentos como a do WoW
	local xp = CreateFrame("StatusBar", "MASHCompactBarXP", compactBar)
	xp:SetHeight(XP_HEIGHT)
	xp:SetPoint("BOTTOMLEFT", compactBar, "BOTTOMLEFT", BAR_PAD, BAR_PAD)
	xp:SetPoint("BOTTOMRIGHT", compactBar, "BOTTOMRIGHT", -BAR_PAD, BAR_PAD)
	xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	xp:SetStatusBarColor(0.58, 0.0, 0.55)
	local bg = xp:CreateTexture("MASHCompactBarXPBg", "BACKGROUND")
	bg:SetAllPoints(xp)
	bg:SetTexture(0.1, 0.0, 0.1, 0.8)
	local width = compactBar:GetWidth() - BAR_PAD * 2
	for s = 1, XP_SEGMENTS - 1 do
		local tick = xp:CreateTexture("MASHCompactBarXPTick"..s, "OVERLAY")
		tick:SetTexture(0, 0, 0, 0.8)
		tick:SetWidth(1)
		tick:SetPoint("TOPLEFT", xp, "TOPLEFT", width * s / XP_SEGMENTS, 0)
		tick:SetPoint("BOTTOMLEFT", xp, "BOTTOMLEFT", width * s / XP_SEGMENTS, 0)
	end
	compactBar.xp = xp
	-- os numeros so ao passar o mouse
	compactBar.xpText = xp:CreateFontString("MASHCompactBarXPText", "OVERLAY", "GameFontHighlightSmall")
	compactBar.xpText:SetPoint("BOTTOM", xp, "TOP", 0, 2)
	compactBar.xpText:Hide()
	xp:EnableMouse(1)
	xp:SetScript("OnEnter", function() compactBar.xpText:Show() end)
	xp:SetScript("OnLeave", function() compactBar.xpText:Hide() end)

	-- padrao: encostada embaixo (a linha de kills/ouro/bau fica em cima dela)
	local barH = compactBar:GetHeight()
	MakeMovable(compactBar, 0, -( UIParent:GetHeight() / 2 ) + barH / 2 + 8)
	compactBar:SetClampedToScreen(1)

	PlaceBarButtons()

	-- a linha de kills/ouro/bau sai de baixo dos status e vira uma janela propria, arrastavel,
	-- que por padrao fica logo acima da barra e com a mesma largura
	if ( moneyFrame ) then
		moneyFrame:SetParent(UIParent)
		moneyFrame:SetFrameStrata("MEDIUM")
		moneyFrame:SetWidth(compactBar:GetWidth())
		MakeMovable(moneyFrame, 0, 0, true)
		-- arrastar solta a janela da barra (DB.moneyDetached); ate la ela segue a barra
		local stop = moneyFrame:GetScript("OnDragStop")
		moneyFrame:SetScript("OnDragStop", function()
			stop()
			DB.moneyDetached = true
		end)
		moneyFrame:SetClampedToScreen(1)
		-- Repair the missing bar once. Saved coordinates are retained, and future
		-- deliberate dragging still detaches the bar normally.
		local repair = DB.moneyDockRepair ~= 1
		AttachMoneyToBar(repair)
		DB.moneyDockRepair = 1
		moneyFrame:Show()
	end

	-- a barra grande some e nao volta sozinha
	MainMenuBar:Hide()
	MainMenuBar:SetScript("OnShow", function() this:Hide() end)
	UpdateCompactXP()
end

-- O cliente pode reposicionar os botoes (ex.: ao trocar de pagina); confere de vez em quando.
-- Prende a linha de kills/ouro/bau logo acima da barra (a menos que o jogador a tenha arrastado
-- para outro lugar; force = true prende de novo, usado pelo "Reset positions").
function AttachMoneyToBar(force)
	if ( not compactBar or not moneyFrame ) then return end
	if ( force ) then DB.moneyDetached = nil end
	if ( not DB.moneyDetached and not moneyFrame.azsMoving ) then
		if moneyFrame:GetParent() ~= UIParent then moneyFrame:SetParent(UIParent) end
		moneyFrame:SetFrameStrata("MEDIUM")
		moneyFrame:SetFrameLevel(compactBar:GetFrameLevel() + 2)
		local width = compactBar:GetWidth()
		if width and width > 0 then moneyFrame:SetWidth(width) end
		moneyFrame:SetHeight(22)
		local point, relative, relativePoint, x, y = moneyFrame:GetPoint(1)
		if point ~= "BOTTOM" or relative ~= compactBar or relativePoint ~= "TOP" or x ~= 0 or y ~= 2 then
			moneyFrame:ClearAllPoints()
			moneyFrame:SetPoint("BOTTOM", compactBar, "TOP", 0, 2)
		end
		moneyFrame:Show()
	end
end

function KeepCompactBar()
	if ( not compactBar ) then
		return
	end
	AttachMoneyToBar(false)
	if ( ( ActionButton1 and ActionButton1:GetParent() ~= compactBar )
		or ( MainMenuMicroButton and microMenu and MainMenuMicroButton:GetParent() ~= microMenu ) ) then
		PlaceBarButtons()
	end
	-- botao com magia escondido por fora (ex.: a barra grande escondendo os filhos): mostra de novo
	for i = 1, table.getn(BAR_SLOTS) do
		local b = getglobal("ActionButton"..BAR_SLOTS[i])
		if ( b and not b:IsShown() and HasAction(BAR_SLOTS[i]) ) then
			b:Show()
		end
	end
	-- se a barra ficou fora da tela embaixo (ex.: posicao salva antiga), sobe o necessario
	local bottom = compactBar:GetBottom()
	if ( bottom and bottom < 2 and not compactBar.azsMoving ) then
		local p = DB.pos["MASHCompactBar"]
		p[2] = p[2] + ( 2 - bottom )
		PlaceMovable(compactBar)
	end
end

end

----------------------------------------------------------------------------------------------------
-- Grifos dos lados da barra de acoes
----------------------------------------------------------------------------------------------------

local function UpdateGryphons()
	local caps = { MainMenuBarLeftEndCap, MainMenuBarRightEndCap }
	for i = 1, 2 do
		if ( caps[i] ) then
			if ( DB.hideGryphons ) then
				caps[i]:Hide()
			else
				caps[i]:Show()
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Painel
----------------------------------------------------------------------------------------------------

-- O painel e montado a partir desta lista: cada secao vira uma aba, com suas opcoes.
-- Tipos: "check" (caixa, com botao opcional ao lado), "camera" (controle deslizante).
-- Fora do menu por enquanto: tecla V (continua funcionando).
local SECTIONS = {
	{
		title = "Nameplates",
		items = {
			{
				kind = "check",
				label = "Show only elites and bosses",
				tip = "Common monsters get no nameplate. The V key shows or hides the elite and boss plates.",
				get = function() return DB.hidePlates end,
				set = function(v) SetFilter(v) end,
			},
			{
				kind = "check",
				label = "Hide unclassified monsters",
				tip = "Monsters MASH has not learned yet are hidden too. They are learned when you target or mouse over them.",
				get = function() return DB.hideUnknown end,
				set = function(v) DB.hideUnknown = v end,
			},
		},
	},
	{
		title = "Target",
		items = {
			{
				kind = "check",
				label = "Enemy target health numbers",
				tip = "Shows current / max health on the target frame.",
				get = function() return DB.targetHealth end,
				set = function(v) DB.targetHealth = v; UpdateTargetHealth() end,
			},
			{ kind = "check", label = "Target health: percentage", tip = "Switch between numeric health and percentage; use the next option to show both.",
			  get = function() return DB.targetHealthMode == 2 end,
			  set = function(v) DB.targetHealthMode = v and 2 or 1; UpdateTargetHealth() end },
			{ kind = "check", label = "Target health: numbers + percent", tip = "Display both numeric HP and percentage.",
			  get = function() return DB.targetHealthMode == 3 end,
			  set = function(v) DB.targetHealthMode = v and 3 or 1; UpdateTargetHealth() end },
		},
	},
	{
		title = "Combat",
		items = {
			{
				kind = "check",
				label = "Replace the game's boss bars",
				tip = "Hides the big boss bars of the HUD and shows bosses and awake guardians in target-style frames instead. Drag them while this panel is open.",
				get = function() return DB.bossFrame end,
				set = function(v) DB.bossFrame = v; SyncHudBosses(); UpdateBossFrame() end,
			},
			{
				kind = "check",
				label = "Hide damage numbers",
				tip = "Hides the damage numbers that pop over monsters (yours and your pet's).",
				get = function() return DB.hideDamage end,
				set = function(v) DB.hideDamage = v; ApplyDamageNumbers() end,
			},
			{
				kind = "check",
				label = "Show my crits above the hero",
				tip = "Your critical hits pop up above your character. Pair it with Hide damage numbers to see only crits.",
				get = function() return DB.showCrits end,
				set = function(v) DB.showCrits = v end,
			},
			{
				kind = "check",
				label = "Group crits",
				tip = "Crits that land within a quarter second become one line: the biggest, with how many there were (x7).",
				get = function() return DB.groupCrits end,
				set = function(v) DB.groupCrits = v end,
			},
		},
	},
	{
		title = "Player",
		items = {
			{
				kind = "check",
				label = "Health bar under the character",
				tip = "A small green bar under your hero. Drag it while this panel is open.",
				get = function() return DB.playerBar end,
				set = function(v) DB.playerBar = v; UpdatePlayerBar() end,
			},
            { kind = "check", label = "Player health: percentage", tip = "Show player health as a percentage.",
              get = function() return DB.playerHealthMode == 2 end,
              set = function(v) DB.playerHealthMode = v and 2 or 1; UpdatePlayerBar() end },
            { kind = "check", label = "Player health: numbers + percent", tip = "Show both health numbers and percentage.",
              get = function() return DB.playerHealthMode == 3 end,
              set = function(v) DB.playerHealthMode = v and 3 or 1; UpdatePlayerBar() end },
			{
				kind = "check",
				label = "Buff icons under the health bar",
				tip = "Your active buffs with their time left.",
				get = function() return DB.playerBuffs end,
				set = function(v) DB.playerBuffs = v; UpdatePlayerBuffs() end,
			},
			{
				kind = "check",
				label = "Shield on the health bar",
				tip = "Your absorb shield shows as a light blue band over the health bar, with its value in numbers.",
				get = function() return DB.playerShield end,
				set = function(v) DB.playerShield = v; UpdatePlayerBar() end,
			},
		},
	},
	{
		title = "Warnings",
		items = {
			{
				kind = "check",
				label = "Low health warning",
				tip = "The health bar under your hero flashes red when your health drops below the limit.",
				get = function() return DB.lowHealth end,
				set = function(v) DB.lowHealth = v; UpdatePlayerBar() end,
				button = { text = "Test", onClick = function() TestLowHealth() end },
			},
			{
				kind = "check",
				label = "Sound on low health",
				tip = "Plays a warning sound once each time your health drops below the limit.",
				get = function() return DB.lowHealthSound end,
				set = function(v) DB.lowHealthSound = v end,
			},
			{
				kind = "slider",
				label = "Low health limit",
				tip = "Below this much health the warning starts.",
				min = 10, max = 70, step = 5,
				format = function(v) return MASH_L("Low health below ")..v.."%" end,
				get = function() return DB.lowHealthPct end,
				set = function(v) DB.lowHealthPct = v; UpdatePlayerBar() end,
			},
		},
	},
	{
		title = "Windows",
		items = {
			{
				kind = "check",
				label = "Stats",
				tip = "Your run stats on screen, with gold and the next chest price below.",
				get = function() return DB.statsFrame end,
				set = function(v) DB.statsFrame = v; UpdateStatsFrame() end,
				button = { text = "Choose...", onClick = function() ToggleStatsPicker() end },
			},
			{
				kind = "check",
				label = "Kills under the gold",
				tip = "Shows your kills below the gold and chest price, and hides the game's Kills / Gold / cache box.",
				get = function() return DB.replaceTally end,
				set = function(v) DB.replaceTally = v; SyncHudTally(); UpdateMoneyFrame() end,
			},
			{
				kind = "check",
				label = "Damage meter",
				tip = "Damage, DPS and share of each spell this run. The game's own meter stays as it is.",
				get = function() return DB.meterFrame end,
				set = function(v) DB.meterFrame = v; UpdateMeterFrames(true) end,
			},
			{
				kind = "check",
				label = "Damage taken",
				tip = "Where the damage you took came from: bosses, elites, monsters or ground effects.",
				get = function() return DB.takenFrame end,
				set = function(v) DB.takenFrame = v; UpdateMeterFrames(true) end,
			},
			{
				kind = "check",
				label = "Accessories",
				tip = "Your amulet, trinkets and rings with rarity colors. Empty slots show in red.",
				get = function() return DB.gearFrame end,
				set = function(v) DB.gearFrame = v; UpdateGearFrame() end,
			},
		},
	},
	{
		title = "Map",
		items = {
			{
				kind = "check",
				label = "Chests on the minimap",
				tip = "Every Battleground Cache on the field gets an icon on the minimap. Far ones sit on the edge, pointing the way.",
				get = function() return DB.chestPins end,
				set = function(v) DB.chestPins = v; UpdateChestPins() end,
			},
			{
				kind = "check",
				label = "Lairs",
				tip = "A window with every guardian lair: who holds it, asleep or awake, when an empty one fills again, and how far it is.",
				get = function() return DB.lairFrame end,
				set = function(v) DB.lairFrame = v; UpdateLairFrame() end,
			},
		},
	},
	{
		title = "Interface",
		items = {
			{
				kind = "check",
				label = "Compact action bar",
				tip = "Your 6 spells and racial in a small bar with the XP bar below and the kills, gold and chest line above, and the menu buttons in the bottom right corner. Changing this reloads the interface.",
				get = function() return DB.compactBar end,
				set = function(v) DB.compactBar = v; ReloadUI() end,
			},
			{
				kind = "check",
				label = "Hide gryphons",
				tip = "Hides the two gryphons at the ends of the action bar.",
				get = function() return DB.hideGryphons end,
				set = function(v) DB.hideGryphons = v; UpdateGryphons() end,
			},
		},
	},
	{
		title = "Camera",
		items = {
			{ kind = "camera" },
		},
	},
}


-- Additional sections use factories to avoid capturing the entire main chunk (32-upvalue limit).
MASH_AddSettingsSections(SECTIONS)

-- Layout: barra de titulo, abas (uma por secao) na esquerda e o conteudo da aba escolhida na direita.
local PANEL_WIDTH, PANEL_HEIGHT = 620, 620
local TAB_WIDTH = 148
local CONTENT_X = TAB_WIDTH + 22
local CONTENT_WIDTH = PANEL_WIDTH - CONTENT_X - 16
local CONTENT_TOP = -36

local function RefreshPanel()
	if ( not panel ) then
		return
	end
	for i = 1, table.getn(panel.checks) do
		local check = panel.checks[i]
		check:SetChecked(check.item.get() and 1 or nil)
	end
	panel.refreshing = true
	for i = 1, table.getn(panel.sliders) do
		local slider = panel.sliders[i]
		slider:SetValue(slider.item.get())
		local text = getglobal(slider:GetName().."Text")
		if ( text ) then
			MASH_Text(text,slider.item.format(slider.item.get()))
		end
	end
	panel.refreshing = nil
	if ( panel.camera ) then
		panel.refreshing = true
		panel.camera:SetValue(DB.cameraMax or CAMERA_BASE)
		if MASHPanelCameraText then MASH_Text(MASHPanelCameraText,MASH_L("Max camera distance: ")..(DB.cameraMax or CAMERA_BASE)..MASH_L(" yd")) end
		panel.refreshing = nil
	end
end

-- A separate callback leaves ample room under the legacy 32-upvalue limit.
function MASH_RefreshInterfaceLanguage()
 RefreshPanel();UpdateStatsFrame();UpdateGearFrame();UpdateMeterFrames(true)
 UpdateBossFrame();UpdateLairFrame();UpdateMoneyFrame()
 if MASH_UpdateWorldPins then MASH_UpdateWorldPins() end
end

local function ShowTip(owner, title, text)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(MASH_L(title), 1.0, 1.0, 1.0)
	if ( text ) then
		GameTooltip:AddLine(MASH_L(text), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end
	GameTooltip:Show()
end

-- Cada opcao: caixa + nome, e a descricao em cinza logo abaixo.
local function AddCheck(page, item, y)
	local n = table.getn(panel.checks) + 1
	local check = CreateFrame("CheckButton", "MASHPanelCheck"..n, page, "UICheckButtonTemplate")
	check:SetWidth(22)
	check:SetHeight(22)
	check:SetPoint("TOPLEFT", page, "TOPLEFT", -3, y)
	check.item = item
	if ( check.SetHitRectInsets ) then
		check:SetHitRectInsets(0, -180, 0, 0)  -- clicar no nome tambem marca
	end
	local label = check:CreateFontString("MASHPanelCheck"..n.."Label", "OVERLAY", "GameFontHighlight")
	MenuFont(label, 15)
	label:SetPoint("LEFT", check, "RIGHT", 2, 1)
	MASH_Text(label,item.label)
	check:SetScript("OnClick", function()
		this.item.set(this:GetChecked() and true or false)
		RefreshPanel()
	end)
	panel.checks[n] = check

	if ( item.button ) then
		local b = CreateFrame("Button", "MASHPanelCheck"..n.."Button", page, "UIPanelButtonTemplate")
		b:SetWidth(78)
		b:SetHeight(20)
		b:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, y - 1)
		MASH_Text(b,item.button.text)
		b:SetScript("OnClick", item.button.onClick)
	end

	local tip = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	MenuFont(tip, 13, 0.75, 0.75, 0.75)
	tip:SetPoint("TOPLEFT", page, "TOPLEFT", 22, y - 21)
	tip:SetWidth(CONTENT_WIDTH - 24)
	tip:SetJustifyH("LEFT")
	MASH_Text(tip,item.tip)
	-- altura do texto quebrado em linhas (estimada pela largura, que todo cliente informa)
	-- Reserve the taller language once so switching never overlaps the next row.
 local widest=tip:GetStringWidth() or 0
 tip:SetText(MASHLocale.fr[item.tip] or item.tip)
 widest=math.max(widest,tip:GetStringWidth() or 0)
 tip:SetText(MASHLocale.en[item.tip] or item.tip)
 widest=math.max(widest,tip:GetStringWidth() or 0)
 MASH_Text(tip,item.tip)
 local lines = math.max(1, math.ceil(widest / ( CONTENT_WIDTH - 24 )))
 return y - 21 - 14 * lines - 10
end

local function AddSlider(page, item, y)
	local n = table.getn(panel.sliders) + 1
	local name = "MASHPanelSlider"..n
	local ok, slider = pcall(CreateFrame, "Slider", name, page, "OptionsSliderTemplate")
	if ( not ok or not slider ) then
		return y
	end
	slider.item = item
	slider:SetWidth(CONTENT_WIDTH - 20)
	slider:SetHeight(17)
	slider:SetPoint("TOPLEFT", page, "TOPLEFT", 8, y - 16)
	slider:SetMinMaxValues(item.min, item.max)
	slider:SetValueStep(item.step)
	if ( getglobal(name.."Low") ) then
		MASH_Text(getglobal(name.."Low"),tostring(item.min))
		MASH_Text(getglobal(name.."High"),tostring(item.max))
	end
	slider:SetScript("OnValueChanged", function()
		local v = math.floor(this:GetValue() + 0.5)
		if ( getglobal(this:GetName().."Text") ) then
			MASH_Text(getglobal(this:GetName().."Text"),this.item.format(v))
		end
		if ( not panel.refreshing and this.item.get() ~= v ) then
			this.item.set(v)
		end
	end)
	slider:SetScript("OnEnter", function() ShowTip(this, this.item.label, this.item.tip) end)
	slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
	panel.sliders[n] = slider
	return y - 52
end

local function AddCameraSlider(page, y)
	local ok, slider = pcall(CreateFrame, "Slider", "MASHPanelCamera", page, "OptionsSliderTemplate")
	if ( not ok or not slider ) then
		return y
	end
	slider:SetWidth(CONTENT_WIDTH - 20)
	slider:SetHeight(17)
	slider:SetPoint("TOPLEFT", page, "TOPLEFT", 8, y - 16)
	slider:SetMinMaxValues(CAMERA_BASE, 50)
	slider:SetValueStep(1)
	if ( MASHPanelCameraLow ) then
		MASH_Text(MASHPanelCameraLow,CAMERA_BASE..MASH_L(" yd"))
		MASH_Text(MASHPanelCameraHigh,"50 yd")
	end
	slider:SetScript("OnValueChanged", function()
		local v = math.floor(this:GetValue() + 0.5)
		if ( MASHPanelCameraText ) then
			MASH_Text(MASHPanelCameraText,MASH_L("Max camera distance: ")..v..MASH_L(" yd"))
		end
		if ( DB.cameraMax ~= v and not panel.refreshing ) then
			DB.cameraMax = v
			ApplyCamera(true)
		end
	end)
	panel.camera = slider
	local tip = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	MenuFont(tip, 13, 0.75, 0.75, 0.75)
	tip:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y - 56)
	tip:SetWidth(CONTENT_WIDTH)
	tip:SetJustifyH("LEFT")
	MASH_Text(tip,"How far the camera can zoom out. The game's own option stops at about 30 yd.")
	return y - 80
end

local function ResetPositions()
	for i = 1, table.getn(movableFrames) do
		local f = movableFrames[i]
		DB.pos[f:GetName()] = { f.azsDefault[1], f.azsDefault[2] }
		PlaceMovable(f)
	end
	if ( AttachMoneyToBar ) then
		AttachMoneyToBar(true)
	end
	Print(MASH_L("window positions reset."))
end

local function SelectTab(index)
	index = math.max(1, math.min(table.getn(panel.tabs), tonumber(index) or 1))
	DB.panelTab = index
	DB.panelSection = SECTIONS[index].title
	for i = 1, table.getn(panel.tabs) do
		local tab = panel.tabs[i]
		if ( i == index ) then
			tab.selected:Show()
			tab.mark:Show()
			tab.text:SetTextColor(1.0, 0.82, 0.0)
			tab.page:Show()
		else
			tab.selected:Hide()
			tab.mark:Hide()
			tab.text:SetTextColor(0.8, 0.8, 0.8)
			tab.page:Hide()
		end
	end
	if ( statsPicker ) then
		statsPicker:Hide()
	end
end

local function CreatePanel()
	panel = CreateFrame("Frame", "MASHPanel", UIParent)
	panel:SetWidth(PANEL_WIDTH)
	panel:SetHeight(PANEL_HEIGHT)
	if panel.SetClampedToScreen then panel:SetClampedToScreen(1) end
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
	-- Set the parent level before creating children: this client does not
	-- reliably raise an existing template close button with its parent.
	panel:SetFrameLevel(100)
	StyleWindow(panel, "MASH", "Malk Azeroth Survivor Helper  -  v"..MASH_VERSION)
 -- A solid texture also works in native clients whose backdrop alpha differs.
 local background=panel:CreateTexture(nil,"BACKGROUND")
 background:SetAllPoints(panel);background:SetTexture(0.025,0.025,0.035,1)

	-- coluna das abas, com fundo um pouco mais escuro e um divisor
	local tabsBg = panel:CreateTexture(nil, "BACKGROUND")
	tabsBg:SetTexture(0, 0, 0, 0.35)
	tabsBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -27)
	tabsBg:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 4)
	tabsBg:SetWidth(TAB_WIDTH)
	local divider = panel:CreateTexture(nil, "ARTWORK")
	divider:SetTexture(1.0, 0.82, 0.0, 0.25)
	divider:SetPoint("TOPLEFT", tabsBg, "TOPRIGHT", 0, 0)
	divider:SetPoint("BOTTOMLEFT", tabsBg, "BOTTOMRIGHT", 0, 0)
	divider:SetWidth(1)

	panel.checks = {}
	panel.sliders = {}
	panel.tabs = {}
	for s = 1, table.getn(SECTIONS) do
		local section = SECTIONS[s]

		local tab = CreateFrame("Button", "MASHPanelTab"..s, panel)
		tab:SetWidth(TAB_WIDTH - 8)
		tab:SetHeight(24)
		tab:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -34 - 26 * ( s - 1 ))
		tab.selected = tab:CreateTexture(nil, "BACKGROUND")
		tab.selected:SetTexture(1.0, 0.82, 0.0, 0.16)
		tab.selected:SetAllPoints(tab)
		local mark = tab:CreateTexture(nil, "ARTWORK")
		mark:SetTexture(1.0, 0.82, 0.0, 0.9)
		mark:SetWidth(2)
		mark:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
		mark:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
		tab.mark = mark
		local hover = tab:CreateTexture(nil, "BACKGROUND")
		hover:SetTexture(1.0, 1.0, 1.0, 0.06)
		hover:SetAllPoints(tab)
		hover:Hide()
		tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		MenuFont(tab.text, 15)
		tab.text:SetPoint("LEFT", tab, "LEFT", 10, 0)
		MASH_Text(tab.text,section.title)
		tab:SetScript("OnEnter", function() hover:Show() end)
		tab:SetScript("OnLeave", function() hover:Hide() end)
		local tabIndex = s -- capture a distinct index for each tab
		tab:SetScript("OnClick", function() SelectTab(tabIndex) end)

		-- pagina da aba: titulo da secao e as opcoes
		local page = CreateFrame("Frame", "MASHPanelPage"..s, panel)
		page:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_X, CONTENT_TOP)
		page:SetWidth(CONTENT_WIDTH)
		page:SetHeight(PANEL_HEIGHT + CONTENT_TOP - 40)
		local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		heading:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
		MASH_Text(heading,section.title)
		local y = -28
		for i = 1, table.getn(section.items) do
			local item = section.items[i]
			if ( item.kind == "language" ) then
				y = MASH_CreateLanguageOption(page, y)
			elseif ( item.kind == "combat" ) then
				MASH_CreateCombatOptions(page)
			elseif ( item.kind == "check" ) then
				y = AddCheck(page, item, y)
			elseif ( item.kind == "slider" ) then
				y = AddSlider(page, item, y)
			elseif ( item.kind == "camera" ) then
				y = AddCameraSlider(page, y)
			end
		end
		tab.page = page
		panel.tabs[s] = tab
	end

	-- pe da coluna das abas: resetar posicoes
	local reset = CreateFrame("Button", "MASHPanelReset", panel, "UIPanelButtonTemplate")
	reset:SetWidth(TAB_WIDTH - 12)
	reset:SetHeight(20)
	reset:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)
	MASH_Text(reset,"Reset positions")
	reset:SetScript("OnClick", ResetPositions)
	reset:SetScript("OnEnter", function() ShowTip(this, "Reset positions", "Puts every MASH window and the health bar back in its default place.") end)
	reset:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- rodape do conteudo: dica e contador de nameplates
	panel.status = panel:CreateFontString("MASHPanelStatus", "OVERLAY", "GameFontDisableSmall")
	MenuFont(panel.status, 12, 0.6, 0.6, 0.6)
	panel.status:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", CONTENT_X, 12)
	panel.statusElapsed = 0
	panel:SetScript("OnUpdate", function()
		this.statusElapsed = this.statusElapsed + ( arg1 or 0 )
		if ( this.statusElapsed < 0.3 ) then
			return
		end
		this.statusElapsed = 0
		MASH_Text(this.status,string.format(MASH_L("Drag MASH windows to move them  -  plates: %d (%d hidden)"), shownNow, hiddenNow))
	end)

	panel:SetScript("OnShow", function()
		RefreshPanel()
		SetMovablesUnlocked(true)
		UpdateBossFrame()
	end)
	panel:SetScript("OnHide", function()
		if MASHCombat then MASHCombat.HideAnchors() end
		SetMovablesUnlocked(false)
		UpdateBossFrame()
		if ( statsPicker ) then
			statsPicker:Hide()
		end
	end)
	local selected=DB.panelTab or 1
 if DB.panelSection then
  for i=1,table.getn(SECTIONS) do if SECTIONS[i].title==DB.panelSection then selected=i end end
 elseif selected==11 then selected=10 elseif selected==12 then selected=11 end
 SelectTab(selected)
 MASH_RefreshLanguage(MASH_RefreshInterfaceLanguage)
	panel:Hide()
end

local function TogglePanel()
	if ( not panel ) then
		CreatePanel()
	end
	if panel.SetScale then panel:SetScale(math.min(1, (UIParent:GetHeight() - 20) / PANEL_HEIGHT, (UIParent:GetWidth() - 20) / PANEL_WIDTH)) end
	if ( panel:IsShown() ) then
		panel:Hide()
	else
		panel:Show()
	end
end

-- Botao ao lado do minimapa para abrir o painel.
local function CreateMinimapButton()
	if ( not Minimap ) then
		return
	end
	-- mesmas medidas dos botoes redondos do proprio minimapa (tracking, correio)
	local b = CreateFrame("Button", "MASHMinimapButton", Minimap)
	b:SetWidth(31)
	b:SetHeight(31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	local function PlaceOnRim()
		local a = math.rad(DB.minimapAngle)
		b:ClearAllPoints()
		b:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
	end
	PlaceOnRim()
	-- arrastar gira o botao em volta do minimapa
	b:RegisterForDrag("LeftButton")
	b:SetScript("OnDragStart", function()
		this:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			DB.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
			PlaceOnRim()
		end)
	end)
	b:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)
	-- icone proprio (icon.tga na pasta do addon), que ja traz o aro dourado
	local icon = b:CreateTexture("MASHMinimapButtonIcon", "ARTWORK")
	icon:SetTexture("Interface\\AddOns\\"..ADDON_DIR.."\\icon")
	icon:SetAllPoints(b)
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	b:SetScript("OnClick", TogglePanel)
	b:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:SetText("MASH - Malk Azeroth Survivor Helper", 1.0, 1.0, 1.0)
		GameTooltip:AddLine(MASH_L("Click to open the panel. Drag to move."), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

----------------------------------------------------------------------------------------------------
-- Frame principal
----------------------------------------------------------------------------------------------------

local function InitDB()
	if ( type(MASHDB) ~= "table" ) then
		MASHDB = {}
	end
	DB = MASHDB
	if DB.language~="fr" then DB.language="en" end
	local defaults = { hidePlates = true, hideUnknown = false, targetHealth = true, playerBar = true, bossFrame = true, statsFrame = true, playerBuffs = true, gearFrame = true,
		meterFrame = true, takenFrame = true, replaceTally = true, playerShield = true,
		chestPins = true, guardianPins = true, lairFrame = true, compactBar = true,
		lowHealth = true, lowHealthSound = true, lowHealthPct = 30, targetHealthMode = 1, playerHealthMode = 1, bossHealthMode = 1}
	for k, v in pairs(defaults) do
		if ( DB[k] == nil ) then
			DB[k] = v
		end
	end
	if MASHCombat then MASHCombat.Ensure() end
	-- Remove only obsolete MASH experiment data; leave user settings intact.
	for _,key in ipairs({"runePins","runeRecord","runePickupSetup","runeObservations","runeProbe","worldProbe","runeTrace","runeOverlay"}) do DB[key]=nil end

	if ( type(DB.known) ~= "table" ) then
		DB.known = {}
	end
	if ( type(DB.minimapAngle) ~= "number" ) then
		DB.minimapAngle = 150
	end
	if ( type(DB.pos) ~= "table" ) then
		DB.pos = {}
	end
	-- restos das versoes que aprendiam os precos
	DB.chestSeq, DB.goldSpent = nil, nil
	if ( type(DB.chestsOpened) ~= "number" ) then
		DB.chestsOpened = 0
	end
	if ( type(DB.shownStats) ~= "table" ) then
		DB.shownStats = {}
		for i = 1, table.getn(DEFAULT_SHOWN) do
			DB.shownStats[DEFAULT_SHOWN[i]] = true
		end
	end
 MASH_SetLanguage(DB.language)
end

local frame = CreateFrame("Frame", "MASHFrame", UIParent)
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_AURAS_CHANGED")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")

local function MASHEventLifecycle()
	if ( event == "PLAYER_LOGOUT" ) then
		if ( type(MASHDB) == "table" ) then
			MASHDB.talentToggles = AZS_TALENT_TOGGLES
			MASHDB.talentStamp = GetTime()
		end
		return
	elseif ( event == "ADDON_LOADED" ) then
		if ( arg1 == ADDON_DIR and type(MASHDB) == "table" and MASHDB.talentToggles
			and MASHDB.talentStamp and GetTime() >= MASHDB.talentStamp ) then
			AZS_TALENT_TOGGLES = MASHDB.talentToggles
		end
		return
	end
	if ( event == "VARIABLES_LOADED" ) then
		InitDB()
		CreateMinimapButton()
		CreatePlayerBar()
		CreatePlayerBuffs()
		CreateBossFrames()
		CreateStatsFrame()
		CreateMoneyFrame()
		CreateGearFrame()
		CreateMeterFrames()
		CreateLairFrame()
		CreateCompactBar()
		UpdateGryphons()
		return
	end
	if ( not DB ) then
		return
	end
end

local function MASHEventWorld()
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		SyncNativePlates()
		UpdatePlayerBar()
		UpdatePlayerBuffs()
		lastGold = RunGold()
		-- run nova (nivel 1, sem ouro): zera a contagem; num /reload no meio da run ela continua
		if ( UnitLevel("player") == 1 and lastGold == 0 ) then
			DB.chestsOpened = 0
			if ( DB.lastStats and stats == DB.lastStats ) then
				stats = nil
				UpdateStatsFrame()
			end
			DB.lastStats = nil
		end
		UpdateMoneyFrame()
		UpdateGearFrame()
		ApplyCamera(false)
		ApplyDamageNumbers()
		SyncHudBosses()
		SyncHudMeter()
		SyncHudTally()
		ResetMapZone()
		UpdateMeterFrames(true)
	end
end

local function MASHEventOther()
	if ( event == "PLAYER_TARGET_CHANGED" ) then
		Learn("target")
		UpdateTargetHealth()
		UpdateBossFrame()
	elseif ( event == "UPDATE_MOUSEOVER_UNIT" ) then
		Learn("mouseover")
	elseif ( event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_COMBAT_SELF_HITS" ) then
		CheckCritMessage(arg1)
	elseif ( event == "ZONE_CHANGED_NEW_AREA" ) then
		ResetMapZone()
	elseif ( event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" ) then
		UpdateCompactXP()
	elseif ( event == "PLAYER_MONEY" ) then
		NoteGoldChange()
		UpdateMoneyFrame()
	elseif ( event == "PLAYER_AURAS_CHANGED" ) then
		UpdatePlayerBuffs()
	elseif ( event == "CHAT_MSG_ADDON" ) then
		if ( arg1 == "AZS" and arg2 ) then
			stats = ParseStats(arg2)
			DB.lastStats = stats
			UpdateStatsFrame()
			UpdateGearFrame()
		end
	elseif ( arg1 == "target" ) then
		UpdateTargetHealth()
		UpdateBossFrame()
	elseif ( arg1 == "player" ) then
		UpdatePlayerBar()
		if ( event == "UNIT_INVENTORY_CHANGED" ) then
			UpdateGearFrame()
		end
	end
end

frame:SetScript("OnEvent", function()
	if ( event == "PLAYER_LOGOUT" or event == "ADDON_LOADED" or event == "VARIABLES_LOADED" ) then
		MASHEventLifecycle()
	elseif ( not DB ) then
		return
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		MASHEventWorld()
	else
		MASHEventOther()
	end
end)

frame:SetScript("OnUpdate", function()
	if ( not DB ) then
		return
	end
	UpdatePlates()
	AnimateCrits()
	elapsed = elapsed + ( arg1 or 0 )
	if ( elapsed < SCAN_INTERVAL ) then
		return
	end
	elapsed = 0
	KeepCompactBar()
	UpdateBossFrame()
	UpdatePlayerBuffs()
	UpdatePlayerBar()
	PulsePlayerBar()
	if ( HasAPI() ) then
		UpdateMoneyFrame()  -- ouro e preco do baú chegam pela API varias vezes por segundo
		UpdateMeterFrames()
		UpdateChestPins()
		UpdateLairFrame()
	end
end)

SLASH_MASH1 = "/mash"
SlashCmdList["MASH"] = function(msg)
	if ( not DB ) then
		return
	end
	msg = string.lower(msg or "")
	if msg == "money" then
		AttachMoneyToBar(true)
		UpdateMoneyFrame()
		Print(MASH_L("Gold/chest bar restored above the action bar. Other positions unchanged."))
		return
	elseif msg == "combat" then
		if not panel then CreatePanel() end
		panel:Show()
		for i=1,table.getn(SECTIONS) do if SECTIONS[i].title=="Combat text" then SelectTab(i) end end
		return
	elseif ( string.find(msg, "plates") ) then
		SetFilter(not DB.hidePlates)
	elseif ( string.find(msg, MASH_L("unknown")) ) then
		DB.hideUnknown = not DB.hideUnknown
	elseif ( string.find(msg, "hp") ) then
		DB.targetHealth = not DB.targetHealth
		UpdateTargetHealth()
	elseif ( string.find(msg, "stats") ) then
		ToggleStatsPicker()
		return
	elseif ( string.find(msg, "chest") ) then
		Print(MASH_L("chests opened this run: ")..( DB.chestsOpened >= 0 and DB.chestsOpened or MASH_L("unknown") )
			..MASH_L(", next chest: ")..( ChestCost() or "?" ))
		return
	elseif ( not string.find(msg, "status") ) then
		TogglePanel()
		return
	end
	RefreshPanel()
	local learned = 0
	for _ in pairs(DB.known) do
		learned = learned + 1
	end
	Print(MASH_L("nameplate filter ")..( DB.hidePlates and MASH_L("ON") or MASH_L("off") )
		..MASH_L(", unknown monsters ")..( DB.hideUnknown and MASH_L("hidden") or MASH_L("shown") )
		..MASH_L(", target health ")..( DB.targetHealth and MASH_L("ON") or MASH_L("off") )
		..MASH_L(", plates on screen ")..shownNow.." ("..hiddenNow..MASH_L(" hidden, max ")..shownMax.."), "
		..learned..MASH_L(" monsters learned, camera ")..( GetCVar("cameraDistanceMaxFactor") or "?" ).."x.")
end
