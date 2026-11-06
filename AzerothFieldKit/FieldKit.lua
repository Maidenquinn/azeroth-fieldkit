-- Azeroth FieldKit: HUD/controller derived from MASH by Malk. See NOTICE.md.
-- Read docs/CODE_GUIDE.md and SECURITY.md before changing native UI behavior.
--
-- Flow: VARIABLES_LOADED -> Config -> fixed frame pools; events refresh the
-- relevant windows; buffs/debuffs 20 Hz, plates ~10 Hz, layout 0.5 s, snapshots 5 Hz.
-- DB is the one normalized FieldKitDB table. AZS_* belongs to the game and is
-- read-only here. UI settings and the explicit user-drag action-slot swap are
-- the only intended native effects (enumerated in docs/API_SURFACE.md).
--
-- Lua 5.0: this/event/arg1 come from the client. Forward declarations followed
-- by `function Name` still bind to their local variables. Scoped `do` blocks
-- intentionally constrain captured locals to the old 32-upvalue limit.
-- Option callbacks live in OptionsSchema.lua; legacy crits in LegacyCrits.lua.
local MENU_FONT = "Fonts\\ARIALN.TTF"

local PLATE_BORDER = "Interface\\Tooltips\\Nameplate-Border"
local PLATE_SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local SCAN_INTERVAL = 0.05
local DATA_INTERVAL = 0.2 -- Official native snapshots arrive at most five times/second.
local LAYOUT_INTERVAL = 0.5
local PLATE_INTERVAL = 0.1
local CAMERA_BASE = 15

local DB
local plates = {}
local plateList = {}
local lastChildren = 0
local lastPlateScan = 0
local elapsed = 0
local dataClock = { elapsed = DATA_INTERVAL }
local shownNow, hiddenNow, shownMax = 0, 0, 0
local panel
local movables = {}
local movableFrames = {}

-- Write an addon-prefixed diagnostic to the local chat frame; never send chat.
local function Print(msg)
	if ( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99FieldKit|r: "..msg)
	end
end

-- Format a display-only number using compact k/m suffixes.
local function ShortNumber(v)
	if ( v >= 1000000 ) then
		return string.format("%.1fm", v / 1000000)
	elseif ( v >= 10000 ) then
		return string.format("%.1fk", v / 1000)
	end
	return string.format("%d", v)
end


local levelSeen = {}

-- Detect the native run API; older clients use the documented fallbacks.
local function HasAPI()
	return type(AZS_GetPhase) == "function"
end


-- Read a native row by named key, falling back to its legacy positional column.
local function Field(entry, key, index)
	local v = entry[key]
	if ( v == nil ) then
		v = entry[index]
	end
	return v
end


local specialAlive = {}
local specialStamp
local specialSource

-- Rebuild on a native timestamp/table change; discard retained names outside a run.
local function RefreshSpecialAlive()
	if ( not HasAPI() or not AZS_GetPhase() or type(AZS_UNITS) ~= "table" ) then
		if specialSource then specialAlive={};specialSource=nil;specialStamp=nil end
		return
	end
	if ( specialStamp == AZS_UNITS_UPDATED and specialSource == AZS_UNITS ) then
		return
	end
	specialStamp = AZS_UNITS_UPDATED
	specialSource = AZS_UNITS
	specialAlive = {}
	for i = 1, math.min(512,table.getn(AZS_UNITS)) do
		local name = Field(AZS_UNITS[i], "name", 3)
		if ( name ) then
			specialAlive[name] = true
		end
	end
end


local KIND_TO_CLASS = { final = "worldboss", boss = "worldboss", guardian = "elite", elite = "elite", normal = "normal" }

-- Prefer the native enemy kind, otherwise use legacy UnitClassification.
local function UnitClass2(unit)
	if ( HasAPI() and AZS_UnitKind ) then
		local kind = AZS_UnitKind(unit)
		if ( kind and KIND_TO_CLASS[kind] ) then
			return KIND_TO_CLASS[kind]
		end
	end
	return UnitClassification(unit)
end


-- Look up learned classification first, then the static seed. Nil means unknown.
local function IsNormal(name)
	local learned = DB.known[name]
	if ( learned ~= nil ) then
		return learned == "normal"
	end
	local seed = FieldKit_Seed and FieldKit_Seed[name]
	if ( seed ~= nil ) then
		return seed == 0
	end
	return nil
end


-- Check the static/learned classification; this is a visual classification by name.
local function IsBoss(name)
	if ( DB.known[name] == "worldboss" ) then
		return true
	end
	return FieldKit_Seed and FieldKit_Seed[name] == 3
end


-- Learn only a targeted or hovered non-player unit; bound the persisted name cache.
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
	FieldKit.RememberClassification(DB.known, name, class)
end


-- Restore a saved center-relative position, clamping the visible frame to the screen.
local function PlaceMovable(frame)
 if FieldKitPositions.Restore(frame) then return end
	local p = DB.pos[frame:GetName()]
	frame:ClearAllPoints()
 if frame.fieldkitTopLeftAnchor then
  frame:SetPoint("TOPLEFT",UIParent,"CENTER",p[1],p[2]);return
 end
	local xlimit = math.max(0, (UIParent:GetWidth() - frame:GetWidth()) / 2)
	local ylimit = math.max(0, (UIParent:GetHeight() - frame:GetHeight()) / 2)
	frame:SetPoint("CENTER", UIParent, "CENTER", math.max(-xlimit, math.min(xlimit, tonumber(p[1]) or 0)), math.max(-ylimit, math.min(ylimit, tonumber(p[2]) or 0)))
end


-- Attach drag handlers and persist positions in FieldKitDB.pos; no native save edits.
local function FinishMoving(frame)
	if not frame or not frame.azsMoving then return end
	frame.azsMoving = nil
	frame:StopMovingOrSizing()
	if FieldKitPositions.Save(frame,frame.fieldkitTopLeftAnchor) then FieldKitPositions.Restore(frame) end
end

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
  if DB.windowsLocked and not FieldKit.layoutEditing then return end
  if FieldKitPartyDetails then FieldKitPartyDetails.Close() end
		frame.azsMoving = true
		frame:StartMoving()
	end)
	-- OnDragStop alone can be swallowed after a live resize (Effects timers); MouseUp is the release fallback.
	handle:SetScript("OnDragStop", function() FinishMoving(frame) end)
	handle:SetScript("OnMouseUp", function() FinishMoving(frame) end)
 -- If the handle disappears or a game UI overlay swallows the release, recover.
 local previousHide=handle:GetScript("OnHide")
 handle:SetScript("OnHide",function()
  FinishMoving(frame)
  if previousHide then previousHide() end
 end)
	handle.azsFreeDrag = freeDrag
 handle:EnableMouse(not handle.fieldkitMouseProxy and (not DB.windowsLocked or freeDrag) and 1 or nil)
	table.insert(movables, handle)
end

-- Shared editing gate, available from settings, slash commands or the minimap.
local function SetMovablesUnlocked(unlocked)
 if not unlocked then
  if FieldKitHudStack and FieldKitHudStack.FinishDragging then FieldKitHudStack.FinishDragging() end
  -- A lock issued while a button is held must finish the native drag too.
  for i=1,table.getn(movableFrames) do
   local f=movableFrames[i]
   if f.azsMoving then FinishMoving(f) end
  end
 end
	for i = 1, table.getn(movables) do
  movables[i]:EnableMouse(not movables[i].fieldkitMouseProxy and (unlocked or not DB.windowsLocked or movables[i].azsFreeDrag) and 1 or nil)
	end
end


local BOSS_FRAMES = 4
local BOSS_DEBUFFS = 8
local DEBUFF_SIZE = 16
local BOSS_STACK = 104
local BOSS_W = 420
local BOSS_BAR_H = 18
local BOSS_PORT = 44
local BOSS_HP_W = 118
local bossFrames = {}

-- CreedUI hierarchy + FieldKit Chronicle chrome; all text kept inside the plate.
local function CreateBossFrame(i,preview)
	local prefix=preview and "FieldKitPreviewBoss" or "FieldKitBossFrame"..i
	local f = CreateFrame("Frame", prefix, UIParent)
	f:SetWidth(BOSS_W)
	f:SetHeight(96)
	f:SetFrameStrata("MEDIUM")
	if FieldKitTheme and FieldKitTheme.Surface then FieldKitTheme.Surface(f,"window",true) end

	local portBack=f:CreateTexture(nil,"BACKGROUND")
	portBack:SetTexture(FieldKitTheme.bronze[1],FieldKitTheme.bronze[2],FieldKitTheme.bronze[3])
	portBack:SetWidth(BOSS_PORT);portBack:SetHeight(BOSS_PORT)
	portBack:SetPoint("LEFT",f,"LEFT",14,4)
	f.portrait = f:CreateTexture(prefix.."Portrait", "ARTWORK")
	f.portrait:SetWidth(BOSS_PORT-4);f.portrait:SetHeight(BOSS_PORT-4)
	f.portrait:SetPoint("CENTER",portBack,"CENTER",0,0)
	f.portrait:SetTexCoord(0.08,0.92,0.08,0.92)
	f.portBack=portBack

	local jewel=f:CreateTexture(nil,"ARTWORK")
	jewel:SetTexture(FieldKitTheme.media.."ChronicleSeal.tga")
	jewel:SetWidth(20);jewel:SetHeight(20)
	jewel:SetPoint("LEFT",portBack,"RIGHT",5,0)
	jewel:SetVertexColor(1,.82,.48)
	f.jewel=jewel
	local jewelGem=f:CreateTexture(nil,"OVERLAY")
	jewelGem:SetTexture(FieldKitTheme.media.."ChronicleGlyph08.tga")
	jewelGem:SetWidth(9);jewelGem:SetHeight(9)
	jewelGem:SetPoint("CENTER",jewel,"CENTER",0,0)
	jewelGem:SetVertexColor(1,.55,.35)
	f.jewelGem=jewelGem

	local barLeft=14+BOSS_PORT+5+20+7
	local chrome=CreateFrame("Frame",nil,f)
	chrome:SetHeight(BOSS_BAR_H+6)
	chrome:SetPoint("TOPLEFT",f,"TOPLEFT",barLeft,-34)
	chrome:SetPoint("TOPRIGHT",f,"TOPRIGHT",-16,-34)
	local chromeBg=chrome:CreateTexture(nil,"BACKGROUND")
	chromeBg:SetAllPoints(chrome);chromeBg:SetTexture("Interface\\Buttons\\WHITE8X8")
	chromeBg:SetVertexColor(.02,.02,.025,.98)
	local chromeEdgeT=chrome:CreateTexture(nil,"BORDER")
	chromeEdgeT:SetTexture(FieldKitTheme.gold[1],FieldKitTheme.gold[2],FieldKitTheme.gold[3])
	chromeEdgeT:SetPoint("TOPLEFT",chrome,"TOPLEFT",0,0);chromeEdgeT:SetPoint("TOPRIGHT",chrome,"TOPRIGHT",0,0);chromeEdgeT:SetHeight(2);chromeEdgeT:SetAlpha(.85)
	local chromeEdgeB=chrome:CreateTexture(nil,"BORDER")
	chromeEdgeB:SetTexture(FieldKitTheme.bronze[1],FieldKitTheme.bronze[2],FieldKitTheme.bronze[3])
	chromeEdgeB:SetPoint("BOTTOMLEFT",chrome,"BOTTOMLEFT",0,0);chromeEdgeB:SetPoint("BOTTOMRIGHT",chrome,"BOTTOMRIGHT",0,0);chromeEdgeB:SetHeight(2);chromeEdgeB:SetAlpha(.9)
	local chromeEdgeL=chrome:CreateTexture(nil,"BORDER")
	chromeEdgeL:SetTexture(FieldKitTheme.gold[1],FieldKitTheme.gold[2],FieldKitTheme.gold[3])
	chromeEdgeL:SetPoint("TOPLEFT",chrome,"TOPLEFT",0,0);chromeEdgeL:SetPoint("BOTTOMLEFT",chrome,"BOTTOMLEFT",0,0);chromeEdgeL:SetWidth(2);chromeEdgeL:SetAlpha(.75)
	local chromeEdgeR=chrome:CreateTexture(nil,"BORDER")
	chromeEdgeR:SetTexture(FieldKitTheme.bronze[1],FieldKitTheme.bronze[2],FieldKitTheme.bronze[3])
	chromeEdgeR:SetPoint("TOPRIGHT",chrome,"TOPRIGHT",0,0);chromeEdgeR:SetPoint("BOTTOMRIGHT",chrome,"BOTTOMRIGHT",0,0);chromeEdgeR:SetWidth(2);chromeEdgeR:SetAlpha(.75)
	f.chrome=chrome

	f.bar = CreateFrame("StatusBar", prefix.."HealthBar", chrome)
	f.bar:SetPoint("TOPLEFT",chrome,"TOPLEFT",3,-3)
	f.bar:SetPoint("BOTTOMRIGHT",chrome,"BOTTOMRIGHT",-3,3)
	f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.bar:SetStatusBarColor(.82,.16,.1)
	local trough=f.bar:CreateTexture(nil,"BACKGROUND")
	trough:SetAllPoints(f.bar);trough:SetTexture("Interface\\Buttons\\WHITE8X8")
	trough:SetVertexColor(.05,.03,.03,.95)
	local grain=f.bar:CreateTexture(nil,"OVERLAY")
	grain:SetAllPoints(f.bar);grain:SetTexture(FieldKitTheme.media.."ChronicleGrain.tga");grain:SetAlpha(.42)
	local sheen=f.bar:CreateTexture(nil,"OVERLAY")
	sheen:SetTexture("Interface\\Buttons\\WHITE8X8");sheen:SetVertexColor(1,.78,.62,.28)
	sheen:SetPoint("TOPLEFT",f.bar,"TOPLEFT",0,0);sheen:SetPoint("TOPRIGHT",f.bar,"TOPRIGHT",0,0);sheen:SetHeight(math.floor(BOSS_BAR_H/3))
	local sheenLow=f.bar:CreateTexture(nil,"OVERLAY")
	sheenLow:SetTexture("Interface\\Buttons\\WHITE8X8");sheenLow:SetVertexColor(0,0,0,.25)
	sheenLow:SetPoint("BOTTOMLEFT",f.bar,"BOTTOMLEFT",0,0);sheenLow:SetPoint("BOTTOMRIGHT",f.bar,"BOTTOMRIGHT",0,0);sheenLow:SetHeight(3)

	local border = CreateFrame("Frame", prefix.."TextureFrame", f)
	border:SetAllPoints(f)
	border:SetFrameLevel(f.bar:GetFrameLevel() + 3)

	-- Fixed HP width so name never pushes numbers out of the plate.
	f.hp = border:CreateFontString(prefix.."HealthText", "OVERLAY", "GameFontHighlightSmall")
	f.hp:SetPoint("BOTTOMRIGHT",chrome,"TOPRIGHT",0,3)
	f.hp:SetWidth(BOSS_HP_W);f.hp:SetHeight(14);f.hp:SetJustifyH("RIGHT")
	if FieldKitTheme and FieldKitTheme.Font then FieldKitTheme.Font(f.hp,11,FieldKitTheme.text) end

	f.name = border:CreateFontString(prefix.."Name", "OVERLAY", "GameFontNormal")
	f.name:SetPoint("BOTTOMLEFT",chrome,"TOPLEFT",2,3)
	f.name:SetPoint("RIGHT",f.hp,"LEFT",-8,0)
	f.name:SetJustifyH("LEFT");f.name:SetHeight(14)
	if f.name.SetNonSpaceWrap then f.name:SetNonSpaceWrap(false) end
	if FieldKitTheme and FieldKitTheme.Font then FieldKitTheme.Font(f.name,12,FieldKitTheme.gold,true) end

	f.tag = border:CreateFontString(prefix.."Tag", "OVERLAY", "GameFontNormalSmall")
	f.tag:SetPoint("TOPLEFT",chrome,"BOTTOMLEFT",2,-2)
	f.tag:SetWidth(90);f.tag:SetJustifyH("LEFT")
	if FieldKitTheme and FieldKitTheme.Font then FieldKitTheme.Font(f.tag,10,FieldKitTheme.gold) end

	f.level = border:CreateFontString(prefix.."Level", "OVERLAY", "GameFontNormalSmall")
	f.level:SetPoint("BOTTOMRIGHT",portBack,"BOTTOMRIGHT",1,-1)
	f.skull = border:CreateTexture(prefix.."Skull", "OVERLAY")
	f.skull:SetTexture(PLATE_SKULL);f.skull:SetWidth(14);f.skull:SetHeight(14)
	f.skull:SetPoint("BOTTOMRIGHT",portBack,"BOTTOMRIGHT",2,-2);f.skull:Hide()

	f.debuffs = {}
	for d = 1, BOSS_DEBUFFS do
		local icon = border:CreateTexture(prefix.."Debuff"..d, "OVERLAY")
		icon:SetWidth(DEBUFF_SIZE);icon:SetHeight(DEBUFF_SIZE)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon:SetPoint("TOPLEFT", chrome, "BOTTOMLEFT", 96 + ( d - 1 ) * ( DEBUFF_SIZE + 3 ), -2)
		icon:Hide()
		icon.count = border:CreateFontString(prefix.."Debuff"..d.."Count", "OVERLAY", "NumberFontNormalSmall")
		icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
		icon.count:Hide()
		-- Timer overlays sit on the icon so they stay inside the plate.
		icon.time = border:CreateFontString(prefix.."Debuff"..d.."Time", "OVERLAY", "GameFontHighlightSmall")
		icon.time:SetFont(MENU_FONT, 9, "OUTLINE")
		icon.time:SetPoint("CENTER", icon, "CENTER", 0, 0)
		icon.time:Hide()
		f.debuffs[d] = icon
	end

	if preview then
  -- Isolated demonstration: no movable registration, native unit or HUD action.
 elseif ( i == 1 ) then
		local handle = CreateFrame("Frame", "FieldKitBossFrame1Handle", f)
		handle:SetAllPoints(f)
		handle:SetFrameLevel(border:GetFrameLevel() + 5)
		MakeMovable(f, 0, 120, true, handle)
	else
		f:SetPoint("TOP", bossFrames[i - 1], "TOP", 0, -BOSS_STACK)
	end
	-- Separate unframed compact presentation; the original boss frame remains intact.
 local c=CreateFrame("Frame",prefix.."Compact",UIParent)
 c:SetWidth(310);c:SetHeight(54);c:SetFrameStrata("HIGH")
 c:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
 c:EnableMouse(false)
 local portrait=c:CreateTexture(nil,"ARTWORK")
 portrait:SetWidth(42);portrait:SetHeight(42);portrait:SetPoint("LEFT",c,"LEFT",0,0)
 portrait:SetTexCoord(.08,.92,.08,.92);c.portrait=portrait
 local nameText=c:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 nameText:SetPoint("TOPLEFT",c,"TOPLEFT",49,-2);nameText:SetWidth(240);nameText:SetJustifyH("LEFT")
 if FieldKitTheme and FieldKitTheme.Font then FieldKitTheme.Font(nameText,12,FieldKitTheme.gold,true) end
 c.name=nameText
 local bar=CreateFrame("StatusBar",nil,c)
 bar:SetPoint("TOPLEFT",c,"TOPLEFT",49,-21);bar:SetWidth(241);bar:SetHeight(19)
 bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 local bg=bar:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(bar);bg:SetTexture("Interface\\Buttons\\WHITE8X8");bg:SetVertexColor(.09,.035,.04,.9)
 c.bar=bar
 local hpText=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 hpText:SetPoint("CENTER",bar,"CENTER",0,0);hpText:SetWidth(235);hpText:SetJustifyH("CENTER");c.hp=hpText
 local tag=c:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 tag:SetPoint("TOPRIGHT",c,"TOPRIGHT",-9,-3);c.tag=tag
 -- Chronicle Premium: compact layered chrome, not a large enclosing panel.
 -- All solid swatches use WHITE8X8; SetTexture(r,g,b,a) is not valid on this client.
 local function swatch(parent,layer,r,g,b,a)
  local t=parent:CreateTexture(nil,layer)
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(r,g,b,a)
  return t
 end
 local surface=swatch(c,"BACKGROUND",.035,.065,.085,.87)
 surface:SetPoint("TOPLEFT",c,"TOPLEFT",43,1)
 surface:SetPoint("BOTTOMRIGHT",c,"BOTTOMRIGHT",3,5)
 c.premiumSurface=surface
 local line=swatch(c,"BORDER",.67,.48,.24,.88)
 line:SetPoint("BOTTOMLEFT",c,"BOTTOMLEFT",44,5)
 line:SetPoint("BOTTOMRIGHT",c,"BOTTOMRIGHT",3,5)
 line:SetHeight(1);c.premiumLine=line
 local topLine=swatch(c,"BORDER",.42,.32,.19,.72)
 topLine:SetPoint("TOPLEFT",c,"TOPLEFT",44,1)
 topLine:SetPoint("TOPRIGHT",c,"TOPRIGHT",3,1)
 topLine:SetHeight(1);c.premiumTopLine=topLine
 local medallion=swatch(c,"BORDER",.68,.47,.22,1)
 medallion:SetPoint("CENTER",portrait,"CENTER",0,0)
 medallion:SetWidth(48);medallion:SetHeight(48)
 c.premiumMedallion=medallion
 local medallionShadow=swatch(c,"BACKGROUND",.025,.035,.045,.98)
 medallionShadow:SetPoint("CENTER",portrait,"CENTER",0,0)
 medallionShadow:SetWidth(52);medallionShadow:SetHeight(52)
 c.premiumMedallionShadow=medallionShadow
 local barBorder=swatch(c,"BORDER",.67,.48,.24,.95)
 barBorder:SetPoint("TOPLEFT",bar,"TOPLEFT",-2,2)
 barBorder:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",2,-2)
 c.premiumBarBorder=barBorder
 local shine=swatch(bar,"OVERLAY",1,.84,.64,.29)
 shine:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0)
 shine:SetPoint("TOPRIGHT",bar,"TOPRIGHT",0,0)
 shine:SetHeight(3);c.premiumShine=shine
 local bottomShade=swatch(bar,"OVERLAY",0,0,0,.3)
 bottomShade:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",0,0)
 bottomShade:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",0,0)
 bottomShade:SetHeight(3);c.premiumBottomShade=bottomShade
 local categoryGlyph=c:CreateTexture(nil,"OVERLAY")
 categoryGlyph:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
 categoryGlyph:SetWidth(15);categoryGlyph:SetHeight(15)
 categoryGlyph:SetPoint("RIGHT",tag,"LEFT",-4,0)
 c.premiumCategoryGlyph=categoryGlyph
 c.premiumParts={surface,line,topLine,medallion,medallionShadow,barBorder,shine,bottomShade,categoryGlyph}
 for _,part in ipairs(c.premiumParts) do part:Hide() end
 -- Chronicle Premium v10: the decorative plate MUST be above the StatusBar.
 -- A child StatusBar renders above parent textures, regardless of draw layer.
 -- Use a dedicated overlay frame and recreate labels on that frame.
 local overlay=CreateFrame("Frame",nil,c)
 overlay:SetAllPoints(c)
 overlay:SetFrameLevel(bar:GetFrameLevel()+3)
 overlay:EnableMouse(false)
 c.premiumOverlay=overlay
 local art=overlay:CreateTexture(nil,"ARTWORK")
 art:SetTexture("Interface\\AddOns\\AzerothFieldKit\\media\\ChroniclePremium\\chronicle_v16.tga")
 art:SetPoint("TOPLEFT",overlay,"TOPLEFT",0,0)
 art:SetWidth(310);art:SetHeight(54)
 art:SetTexCoord(0,310/512,0,54/128)
 c.premiumArt=art
 -- V11: the decorative TGA is not reliable in the legacy client.
 -- Build visible chrome from native textures on an overlay frame instead.
 art:Hide()
 local function edge(x1,y1,x2,y2,w,h,r,g,b,a)
  local t=overlay:CreateTexture(nil,"OVERLAY")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(r,g,b,a)
  t:SetPoint("TOPLEFT",overlay,"TOPLEFT",x1,y1)
  t:SetWidth(w);t:SetHeight(h)
  return t
 end
 -- Portrait rim: four thin edges, no solid plate obscuring the creature.
 -- Refined Chronicle: restrained 1px edges, more breathing room and a slim health track.
 -- V15: restrained FieldKit chrome; one perimeter, no stacked rectangles.
 c.premiumRim={
  edge(1,-2,0,0,46,1,.56,.42,.25,.88),
  edge(1,-48,0,0,46,1,.38,.29,.19,.82),
  edge(1,-2,0,0,1,47,.56,.42,.25,.88),
  edge(46,-2,0,0,1,47,.38,.29,.19,.82),
  edge(50,-2,0,0,259,1,.52,.39,.23,.78),
  edge(50,-49,0,0,259,1,.52,.39,.23,.78),
  edge(50,-2,0,0,1,48,.52,.39,.23,.78),
  edge(308,-2,0,0,1,48,.52,.39,.23,.78),
  edge(54,-29,0,0,250,1,.48,.36,.23,.78),
  edge(54,-46,0,0,250,1,.38,.29,.19,.75)
 }
 for _,t in ipairs(c.premiumRim) do t:Hide() end
 -- Native creature portrait sits inside the transparent medallion window.
 portrait:ClearAllPoints()
 portrait:SetPoint("TOPLEFT",c,"TOPLEFT",3,-4)
 portrait:SetWidth(42);portrait:SetHeight(42)
 bar:ClearAllPoints()
 -- The status fill must sit strictly INSIDE the native rim (x=55..306, y=-31..-51).
 -- Inset on every side prevents the fill from covering the 1px metal edges.
 bar:SetPoint("TOPLEFT",c,"TOPLEFT",57,-33)
 bar:SetWidth(245);bar:SetHeight(12)
 -- Recreate text above the art. Old font strings remain hidden for compatibility.
 nameText:Hide();tag:Hide();hpText:Hide()
 local premiumName=overlay:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 premiumName:SetPoint("TOPLEFT",overlay,"TOPLEFT",56,-7)
 premiumName:SetWidth(192);premiumName:SetHeight(16)
 premiumName:SetJustifyH("LEFT")
 if FieldKitTheme and FieldKitTheme.Font then FieldKitTheme.Font(premiumName,11,FieldKitTheme.gold,true) end
 local premiumTag=overlay:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 premiumTag:SetPoint("TOPRIGHT",overlay,"TOPRIGHT",-8,-7)
 premiumTag:SetWidth(58);premiumTag:SetHeight(16)
 premiumTag:SetJustifyH("RIGHT")
 if FieldKitTheme and FieldKitTheme.Font then FieldKitTheme.Font(premiumTag,10,FieldKitTheme.gold) end
 local premiumHP=overlay:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 premiumHP:SetPoint("CENTER",bar,"CENTER",0,0)
 premiumHP:SetWidth(235);premiumHP:SetHeight(13)
 premiumHP:SetJustifyH("CENTER")
 c.premiumName=premiumName;c.premiumTag=premiumTag;c.premiumHP=premiumHP
 c.premiumLegacyName=nameText;c.premiumLegacyTag=tag;c.premiumLegacyHP=hpText
 overlay:Hide()
 c:Hide();f.compact=c
	f:Hide()
	return f
end

-- Allocate the fixed four-frame pool once, then synchronize the native boss HUD.
local function CreateBossFrames()
	for i = 1, BOSS_FRAMES do
		bossFrames[i] = CreateBossFrame(i)
	end
end


-- Hide the native boss section only for the replacement option; restore when disabled.
local function SyncHudBosses()
	if ( not HasAPI() or not AZS_SetHudShown ) then
		return
	end
	if ( DB.bossFrame ) then
		FieldKit.SetHudShown("bosses", false)
		DB.hudBossesHidden = true
	elseif ( DB.hudBossesHidden ) then
		FieldKit.SetHudShown("bosses", true)
		DB.hudBossesHidden = nil
	end
end

-- Fill one frame from a native instance id, HP and state, then its native debuffs.
local function ShowBossFrame(f, name, hp, hpm, kind, state, id)
 local compact=f.compact
 if compact then
  if DB.bossStyle=="compact" or DB.bossStyle=="premium" then
   f:SetAlpha(0);compact:Show()
   local premium=DB.bossStyle=="premium"
   for _,part in ipairs(compact.premiumParts) do part:Hide() end
   compact.premiumOverlay:Hide()
   for _,part in ipairs(compact.premiumRim) do part:Hide() end
   if premium then
    local guardian=(kind=="guardian")
    -- Native frame accents, deliberately independent of external TGA assets.
    compact.premiumSurface:Show()
    compact.premiumLine:Show()
    compact.premiumTopLine:Show()
    compact.premiumShine:Show()
    compact.premiumBottomShade:Show()
    compact.premiumSurface:SetVertexColor(.035,.065,.085,.79)
    -- V16: one authored chrome asset replaces the stacked native rectangles.
    for _,part in ipairs(compact.premiumRim) do part:Hide() end
    compact.premiumSurface:Hide()
    compact.premiumLine:Hide()
    compact.premiumTopLine:Hide()
    compact.premiumShine:Hide()
    compact.premiumBottomShade:Hide()
    compact.premiumOverlay:Show()
    compact.premiumArt:Show()
   end
   -- Avoid multi-line names: preserve the full value in the original boss data.
   local displayName=name or ""
   if string.len(displayName)>28 then displayName=string.sub(displayName,1,25).."..." end
   compact.premiumName:SetText(displayName)
   compact.premiumTag:SetText(kind=="guardian" and FieldKit_L("Guardian") or (kind=="final" and FieldKit_L("Final boss") or FieldKit_L("Boss")))
   compact.premiumHP:SetText(FieldKit_FormatHealth(hp,hpm,DB.bossHealthMode))
   if premium then
    compact.premiumLegacyName:Hide();compact.premiumLegacyTag:Hide();compact.premiumLegacyHP:Hide()
   else
    compact.premiumLegacyName:Show();compact.premiumLegacyTag:Show();compact.premiumLegacyHP:Show()
   end
   compact.name:SetText(premium and "" or (name or ""))
   local maxHP=math.max(tonumber(hpm) or 1,1)
   local currentHP=math.max(0,math.min(tonumber(hp) or 0,maxHP))
   compact.bar:SetMinMaxValues(0,maxHP);compact.bar:SetValue(currentHP)
   compact.hp:SetText(premium and "" or FieldKit_FormatHealth(hp,hpm,DB.bossHealthMode))
   compact.bar:SetStatusBarColor(kind=="guardian" and .19 or .68,kind=="guardian" and .45 or .15,kind=="guardian" and .69 or .17)
   compact.tag:SetText(premium and "" or (kind=="guardian" and FieldKit_L("Guardian") or (kind=="final" and FieldKit_L("Final boss") or FieldKit_L("Boss"))))
  else
   f:SetAlpha(1);compact:Hide()
  end
 end
	f.name:SetText(name)
	f.bar:SetMinMaxValues(0, math.max(hpm or 1, 1))
	f.bar:SetValue(hp or 0)
	FieldKit_Text(f.hp,FieldKit_FormatHealth(hp, hpm, DB.bossHealthMode))
	if ( kind == "guardian" ) then
		f.bar:SetStatusBarColor(.62,.08,.12)
		FieldKit_Text(f.tag,"|cffffd100"..FieldKit_L("Guardian").."|r")
		if f.jewel then f.jewel:SetVertexColor(1,.82,.45) end
	elseif ( state == 1 or state == true ) then
		f.bar:SetStatusBarColor(.98,.28,.06)
		FieldKit_Text(f.tag,"|cffff2020"..FieldKit_L("ENRAGED").."|r")
		if f.jewel then f.jewel:SetVertexColor(1,.45,.2) end
	elseif ( kind == "final" ) then
		f.bar:SetStatusBarColor(.85,.22,.08)
		FieldKit_Text(f.tag,"|cffff8000"..FieldKit_L("Final boss").."|r")
		if f.jewel then f.jewel:SetVertexColor(1,.7,.3) end
	else
		f.bar:SetStatusBarColor(.82,.16,.1)
		FieldKit_Text(f.tag,"")
		if f.jewel then f.jewel:SetVertexColor(1,.82,.48) end
	end

	if ( UnitExists("target") and UnitName("target") == name ) then
		local lvl = UnitLevel("target")
		levelSeen[name] = ( lvl and lvl > 0 ) and tostring(lvl) or "??"
	end
	local lvl = levelSeen[name]
	if ( lvl and lvl ~= "??" ) then
		FieldKit_Text(f.level,lvl)
		f.level:Show()
		f.skull:Hide()
	elseif ( lvl == "??" or kind ~= "guardian" ) then
		f.level:Hide()
		f.skull:Show()
	else
		f.level:Hide()
		f.skull:Hide()
	end


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
			FieldKit_Text(slot.count,info.count)
			slot.count:Show()
		else
			slot.count:Hide()
		end
		if ( info.left and info.left > 0 ) then
			FieldKit_Text(slot.time,info.left < 10 and string.format("%.1f", info.left) or string.format("%d", info.left))
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

	FieldKit_Portraits.Apply(f, name, kind, id)
 if f.compact then f.compact.portrait:SetTexture(f.portrait:GetTexture()) end

	f:Show()
end

-- Lair ids currently fighting. Empty/returning/asleep lairs must not keep a
-- guardian boss frame after despawn or across a fresh run when AZS_UNITS lags.
-- Read AZS_LAIRS directly (same source as pins) so boss refresh does not bump
-- the documented 5 Hz GetLairs snapshot cadence.
local function AwakeGuardianIds()
	if type(AZS_LAIRS) ~= "table" or table.getn(AZS_LAIRS) == 0 then
		return nil
	end
	local awake = {}
	for i = 1, table.getn(AZS_LAIRS) do
		local l = AZS_LAIRS[i]
		local id = l and FieldKit.Number(l.id)
		if l and l.state == "awake" and id and id > 0 then
			awake[id] = true
		end
	end
	return awake
end

-- Select live final/boss/awake-guardian entries and update the bounded frame pool.
local function UpdateBossFrame()
 for bi=2,table.getn(bossFrames) do
  local bf=bossFrames[bi]
  bf:ClearAllPoints()
  bf:SetPoint("TOP",bossFrames[bi-1],"TOP",0,-((DB.bossStyle=="compact" or DB.bossStyle=="premium") and 58 or BOSS_STACK))
 end
	if ( table.getn(bossFrames) == 0 ) then
		return
	end
	local n = 0
	if ( DB.bossFrame and HasAPI() and type(AZS_UNITS) == "table" ) then
		local phase = AZS_GetPhase()
		if ( phase and phase ~= "ready" ) then
			local awakeIds = AwakeGuardianIds()

			for pass = 1, 2 do
				for i = 1, math.min(512,table.getn(AZS_UNITS)) do
					local e = AZS_UNITS[i]
					local kind = Field(e, "kind", 1)
					local state = Field(e, "state", 6)
					local wanted
					if ( pass == 1 ) then
						wanted = ( kind == "final" or kind == "boss" )
					else
						wanted = ( kind == "guardian" and ( state == 1 or state == true ) )
						-- Prefer the lair awake flag over a stale AZS_UNITS state=1.
						if wanted and awakeIds then
							local id = FieldKit.Number(Field(e, "id", 2))
							wanted = id and awakeIds[id]
						end
					end
					if ( wanted and n < BOSS_FRAMES ) then
						n = n + 1
						ShowBossFrame(bossFrames[n], Field(e, "name", 3), Field(e, "hp", 4), Field(e, "hpm", 5), kind, state, Field(e, "id", 2))
					end
				end
			end
		end
	end

	if ( n == 0 and DB.bossFrame and FieldKit.layoutEditing ) then
		n = 1
		ShowBossFrame(bossFrames[1], "Boss", 1, 1, "boss", 0)
		FieldKit_Text(bossFrames[1].hp,"drag to move")
	end
	for i = n + 1, BOSS_FRAMES do
		if bossFrames[i].compact then bossFrames[i].compact:Hide() end
		bossFrames[i]:Hide()
	end
	if FieldKitBossTimeline and FieldKitBossTimeline.Update then FieldKitBossTimeline.Update() end
end


local ApplyPlate, Drop

-- Recognize a native nameplate and chain its previous show/hide handlers.
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

	local previous = frame:GetScript("OnShow")
	frame:SetScript("OnShow", function()
		if ( previous ) then
			previous()
		end
		if ( DB and DB.hidePlates and not frame.azsReparenting and frame.azsReparentTime ~= GetTime() ) then
			ApplyPlate(info, true)
		end
	end)


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

-- Change alpha on the recognized plate regions rather than invent a new nameplate.
local function SetPlateAlpha(info, alpha)
	for i = 1, table.getn(info.parts) do
		info.parts[i]:SetAlpha(alpha)
	end
end


-- Reparent a native frame to UIParent, compensating scale. Guard reentrant show/hide events.
local liftedFrames = {}
local worldAlphaBefore
local function Lift(frame)
	if ( frame:GetParent() ~= UIParent ) then
		if not liftedFrames[frame] then liftedFrames[frame]={parent=frame:GetParent(),scale=frame:GetScale()} end
		frame.azsReparenting = true
		frame.azsReparentTime = GetTime()
		frame:SetParent(UIParent)
		frame.azsReparenting = nil
	end
	frame:SetScale(WorldFrame:GetEffectiveScale() / UIParent:GetEffectiveScale())
end

-- Return a lifted frame to WorldFrame. This forward-declared function is local, not global.
function Drop(frame)
	if ( frame:GetParent() ~= WorldFrame ) then
		local previous=liftedFrames[frame]
		frame.azsReparenting = true
		frame.azsReparentTime = GetTime()
		frame:SetParent(WorldFrame)
		frame:SetScale(previous and previous.scale or 1)
		frame.azsReparenting = nil
	end
	liftedFrames[frame]=nil
end


local PLATE_STABLE = 2


-- Re-evaluate reused nameplate identity after two stable scans; apply filter and V-key state.
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

		hide = true
	elseif ( DB.hidePlates and info.stable < PLATE_STABLE ) then

		hide = true
	elseif ( DB.hidePlates and ( HasAPI() or not skull ) ) then

		local normal = IsNormal(name)
		if ( name == "" or name == UNKNOWNOBJECT or name == UNKNOWN ) then

			hide = true
		elseif ( specialAlive[name] or IsBoss(name) or FieldKit.IsCriticalObjective(name) ) then

			hide = false
		elseif ( normal == nil ) then

			hide = HasAPI() or DB.hideUnknown
		else
			hide = normal
		end
	end


	SetPlateAlpha(info, hide and 0 or 1)
	if ( not DB.hidePlates ) then

	elseif ( hide ) then
		Drop(info.frame)
	else
		Lift(info.frame)
	end
	return hide
end

-- Scan native WorldFrame children on change or every 0.25s; apply the optional visual filter.
local function UpdatePlates()
	-- Disabled means no WorldFrame writes. Restore only frames we actually lifted.
	if not DB.hidePlates then
		if worldAlphaBefore~=nil then
			WorldFrame:SetAlpha(worldAlphaBefore);worldAlphaBefore=nil
			for f,previous in pairs(liftedFrames) do
				if f:GetParent()==UIParent then
					f.azsReparenting=true;f:SetParent(previous.parent);f:SetScale(previous.scale);f.azsReparenting=nil
				end
			end
			liftedFrames={}
			for i=1,table.getn(plateList) do SetPlateAlpha(plates[plateList[i]],1) end
		end
		return
	end
	if worldAlphaBefore==nil then worldAlphaBefore=WorldFrame:GetAlpha() end
	RefreshSpecialAlive()
	local alpha = DB.hidePlates and 0 or 1
	if ( WorldFrame:GetAlpha() ~= alpha ) then
		WorldFrame:SetAlpha(alpha)
	end


	local n = WorldFrame:GetNumChildren()
	local now = GetTime()
	if ( n ~= lastChildren or now - lastPlateScan > 0.25 ) then
		lastChildren = n
		lastPlateScan = now
		local children = { WorldFrame:GetChildren() }
		for i = 1, table.getn(children) do
			local child = children[i]
			RegisterPlate(child)

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


local NativeShowNameplates, NativeHideNameplates = ShowNameplates, HideNameplates

HideNameplates = function()
	if ( DB and DB.hidePlates ) then
		return
	end
	NativeHideNameplates()
end


-- Keep native plates active for classification while the optional filter manages visibility.
local function SyncNativePlates()
	if ( DB.hidePlates or NAMEPLATES_ON ) then
		NativeShowNameplates()
	else
		NativeHideNameplates()
	end
end

-- Persist the user choice and synchronize native nameplate visibility.
local function SetFilter(on)
	DB.hidePlates = on
	SyncNativePlates()
end


-- Apply only an explicitly configured 15–50 yard distance through the CVar allowlist.
local function ApplyCamera(zoomOut)
	if ( not DB.cameraMax ) then
		return
	end
	FieldKit.SetCVar("cameraDistanceMaxFactor", string.format("%.3f", FieldKit.Number(DB.cameraMax,15,15,50) / CAMERA_BASE))
	if ( zoomOut and CameraZoomOut ) then
		CameraZoomOut(DB.cameraMax)
	end
end


local targetHealthText

-- Draw player-selected numeric/percentage HP formatting on the stock target frame.
local function UpdateTargetHealth()
	if ( not TargetFrame or not TargetFrameHealthBar ) then
		return
	end
	if ( not targetHealthText ) then

		local holder = CreateFrame("Frame", "FieldKitTargetHealth", TargetFrame)
		holder:SetFrameLevel(TargetFrame:GetFrameLevel() + 5)
		holder:SetAllPoints(TargetFrameHealthBar)
		targetHealthText = holder:CreateFontString("FieldKitTargetHealthText", "OVERLAY", "GameFontHighlightSmall")
		targetHealthText:SetPoint("CENTER", holder, "CENTER", 0, 0)
	end
	if ( not DB.targetHealth or not UnitExists("target") ) then
		FieldKit_Text(targetHealthText,"")
		return
	end
	local cur, max = UnitHealth("target") or 0, UnitHealthMax("target") or 0
	if ( UnitIsDead("target") ) then
		cur = 0
	end
	FieldKit_Text(targetHealthText,FieldKit_FormatHealth(cur, max, DB.targetHealthMode))
end


local playerBar

local lowTestUntil = 0

-- Display observed HP and shield; low-health audio is separately optional.
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
        FieldKit_Text(playerBar.healthText,FieldKit_FormatHealth(cur, max, DB.playerHealthMode))
    end


	local shield = 0
	if ( DB.playerShield and HasAPI() and AZS_GetPhase() and type(AZS_RUN) == "table" ) then
		shield = AZS_RUN.sh or 0
	end
	if ( shield > 0 ) then
		playerBar.shield:SetWidth(math.max(1, playerBar:GetWidth() * math.min(shield / max, 1)))
		playerBar.shield:Show()
		FieldKit_Text(playerBar.shieldText,ShortNumber(shield))
		playerBar.shieldText:Show()
	else
		playerBar.shield:Hide()
		playerBar.shieldText:Hide()
	end
	local low = GetTime() < lowTestUntil
		or ( DB.lowHealth and not UnitIsDeadOrGhost("player") and cur / max * 100 < DB.lowHealthPct )
	if ( low and not playerBar.low and DB.lowHealthSound ) then

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


-- Animate the low-health warning using time; no game state is altered.
local function PulsePlayerBar()
	if ( playerBar and playerBar.low ) then
		local p = 0.5 + 0.5 * math.sin(GetTime() * 10)
		playerBar:SetStatusBarColor(0.5 + 0.5 * p, 0.05, 0.05)
		playerBar.glow:SetAlpha(0.25 + 0.6 * p)
	end
end

-- Start a temporary warning preview from an explicit Test button click.
local function TestLowHealth()
	lowTestUntil = GetTime() + 3
	UpdatePlayerBar()
end

-- Allocate the movable player HP/shield display, then populate current values.
local function CreatePlayerBar()
	playerBar = CreateFrame("StatusBar", "FieldKitPlayerBar", UIParent)
	playerBar:SetWidth(120)
	playerBar:SetHeight(9)
	playerBar:SetFrameStrata("LOW")
    playerBar.healthText = playerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    playerBar.healthText:SetPoint("BOTTOM", playerBar, "TOP", 0, 3)
	playerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	playerBar:SetStatusBarColor(0.1, 0.9, 0.1)
	local bg = playerBar:CreateTexture("FieldKitPlayerBarBg", "BACKGROUND")
	bg:SetTexture(0, 0, 0, 0.6)
	bg:SetPoint("TOPLEFT", playerBar, "TOPLEFT", -1, 1)
	bg:SetPoint("BOTTOMRIGHT", playerBar, "BOTTOMRIGHT", 1, -1)

	playerBar.glow = playerBar:CreateTexture("FieldKitPlayerBarGlow", "BACKGROUND")
	playerBar.glow:SetTexture(1.0, 0.0, 0.0, 1.0)
	playerBar.glow:SetPoint("TOPLEFT", playerBar, "TOPLEFT", -4, 4)
	playerBar.glow:SetPoint("BOTTOMRIGHT", playerBar, "BOTTOMRIGHT", 4, -4)
	playerBar.glow:Hide()

	playerBar.shield = playerBar:CreateTexture("FieldKitPlayerBarShield", "OVERLAY")
	playerBar.shield:SetTexture(0.55, 0.85, 1.0, 0.75)
	playerBar.shield:SetPoint("TOPLEFT", playerBar, "TOPLEFT", 0, 0)
	playerBar.shield:SetPoint("BOTTOMLEFT", playerBar, "BOTTOMLEFT", 0, 0)
	playerBar.shield:Hide()
	playerBar.shieldText = playerBar:CreateFontString("FieldKitPlayerBarShieldText", "OVERLAY", "GameFontHighlightSmall")
	playerBar.shieldText:SetFont(MENU_FONT, 11, "OUTLINE")
	playerBar.shieldText:SetTextColor(0.75, 0.92, 1.0)
	playerBar.shieldText:SetPoint("CENTER", playerBar, "CENTER", 0, 1)
	playerBar.shieldText:Hide()
	MakeMovable(playerBar, DB.playerBarX or 0, DB.playerBarY or -70)
	UpdatePlayerBar()
end


local BUFF_SIZE, BUFF_GAP, BUFF_MAX = 18, 2, 10
local buffRow
local buffIcons = {}

-- Lazily allocate a reusable buff icon at the requested bounded index.
local function BuffIcon(i)
	local icon = buffIcons[i]
	if ( icon ) then
		return icon
	end
	icon = CreateFrame("Frame", "FieldKitPlayerBuff"..i, buffRow)
	icon:SetWidth(BUFF_SIZE)
	icon:SetHeight(BUFF_SIZE)
	icon.texture = icon:CreateTexture("FieldKitPlayerBuff"..i.."Icon", "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.time = icon:CreateFontString("FieldKitPlayerBuff"..i.."Time", "OVERLAY", "GameFontHighlightSmall")
	icon.time:SetPoint("TOP", icon, "BOTTOM", 0, -1)
	buffIcons[i] = icon
	return icon
end

-- Format a received remaining duration for display, including short/subminute values.
local function FormatBuffTime(t)
	if ( not t or t <= 0 ) then
		return ""
	elseif ( t < 60 ) then
		return string.format("%d", t)
	end
	return string.format(FieldKit_L("%dm"), math.ceil(t / 60))
end

-- Display the active player buffs and durations exposed by the client.
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
				FieldKit_Text(icon.time,FormatBuffTime(GetPlayerBuffTimeLeft(index)))
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

-- Create the player buff container and its drag handle.
local function CreatePlayerBuffs()
	buffRow = CreateFrame("Frame", "FieldKitPlayerBuffs", playerBar)
	buffRow:SetHeight(BUFF_SIZE)
	buffRow:SetPoint("TOP", playerBar, "BOTTOM", 0, -3)
	UpdatePlayerBuffs()
end


local STACK_WIDTH = 200

local statsFrame
local statsPicker
local stats

-- Convert a native ratio to a percentage string for the stats window.
local function Pct(v)
	return FieldKit.FormatPercent(v,true)
end

-- Convert a native multiplier to a signed percent for the stats window.
local function PctOf(v)
	return FieldKit.FormatPercent(v,false)
end


local STATS = {
	{ "hp", "Health", function(s) return string.format("%.0f", s.hp) end },
	{ "dmg", "Damage", function(s) return Pct(s.dmg - 1) end },
	{ "haste", "Haste", function(s) return Pct(1 - s.cd) end },
	{ "crit", "Crit Chance", function(s) return PctOf(s.crit) end },
	{ "cm", "Crit Dmg", function(s) return PctOf(s.cm) end },
	{ "arm", "Armor", function(s) return PctOf(s.arm) end },
	{ "area", "Area", function(s) return Pct(s.area - 1) end },
	{ "cnt", "Targets", function(s) return string.format("+%d", s.cnt) end },
	{ "echo", "Echo", function(s) return PctOf(s.echo) end },
	{ "spd", "Speed", function(s) return Pct(s.spd - 1) end },
	{ "reg", "Regen", function(s) return string.format("%.1f", s.reg) end },
	{ "pick", "Pickup", function(s) return string.format(FieldKit_L("%.0f yd"), s.pick) end },
	{ "lch", "Lifesteal", function(s) return PctOf(s.lch) end },
	{ "heal", "Kill Heal", function(s) return FieldKit.FormatBonus(s.heal) end },
	{ "thn", "Thorns", function(s) return PctOf(s.thn) end },
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

-- Parse at most 16 KiB of numeric key/value data; never evaluate packet text as code.
local function ParseStats(msg)
	if type(msg)~="string" or string.len(msg)>16384 then return {} end
	local t, pos = {}, 1
	while ( true ) do
		local first, last, k, v = string.find(msg, "(%w+)=([^;]*)", pos)
		if ( not first ) then
			break
		end
		t[k] = FieldKit.Number(v,0)
		pos = last + 1
	end
	return t
end

-- Return the already-allocated stats row for the requested index.
local function StatsRow(i)
	local row = statsFrame.rows[i]
	if ( row ) then
		return row
	end
	row = {}
	row.label = statsFrame:CreateFontString("FieldKitStatsLabel"..i, "OVERLAY", "GameFontNormalSmall")
	row.label:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 9, -8 - 13 * ( i - 1 ))
	row.value = statsFrame:CreateFontString("FieldKitStatsValue"..i, "OVERLAY", "GameFontHighlightSmall")
	row.value:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -27, -8 - 13 * ( i - 1 ))
	statsFrame.rows[i] = row
	return row
end


-- Collapse or expand a stats/equipment panel while retaining its saved position.
local RefreshCollapseDock
local function ApplyCompactPanel(f, key, expandedHeight)
    if not f then return end
    local collapsed = DB[key]
    local count=f.slots and table.getn(f.slots) or math.max(1,math.floor((expandedHeight-14)/13))
    FieldKitCardLayout.Rows(f,expandedHeight,count,f.slots and "gear" or "stats",collapsed)
    FieldKitTheme.Update(f)
    local rows = f.rows or f.slots or {}
    for i = 1, table.getn(rows) do
        local row = rows[i]


        if f.slots then
            if collapsed then row:Hide() else row:Show() end
        else
            if row.label then if collapsed then row.label:Hide() else row.label:Show() end end
            if row.value then if collapsed then row.value:Hide() else row.value:Show() end end
        end
    end
    if f.mashCollapseButton then
        FieldKit_Text(f.mashCollapseButton,collapsed and "+" or "-")
    end
end
-- Attach one collapse button that updates the owning DB option and refreshes the panel.
local function AddCompactButton(f, key, refresh)
    local b = FieldKitTheme.Button(f,nil,"",0,0,18,17,nil);b:ClearAllPoints()
    b:SetWidth(18); b:SetHeight(17)
    b:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    FieldKit_Text(b,DB[key] and "+" or "-")
    b:SetFrameLevel(f:GetFrameLevel() + 10)
    b:SetScript("OnClick", function() DB[key] = not DB[key]; refresh(); if RefreshCollapseDock then RefreshCollapseDock() end end)
    f.mashCollapseButton = b
end

-- Display the selected native stats, or hide the window if its option is disabled.
local function UpdateStatsFrame()
	if ( not statsFrame ) then
		return
	end
	if HasAPI() and not AZS_GetPhase() then statsFrame:Hide();return end
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
			FieldKit_Text(row.label,def[2])
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

-- Create the stats display; last native stats may be reused until a fresh packet arrives.
local function CreateStatsFrame()
	statsFrame = CreateFrame("Frame", "FieldKitStatsFrame", UIParent)
	statsFrame:SetFrameStrata("LOW")
	statsFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	statsFrame:SetBackdropColor(0, 0, 0, 0.6)
	statsFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
 FieldKitTheme.Surface(statsFrame,"card",true)
	statsFrame:SetWidth(STACK_WIDTH)
	statsFrame:SetHeight(20)
	statsFrame.rows = {}
	AddCompactButton(statsFrame, "statsCollapsed", UpdateStatsFrame)
	MakeMovable(statsFrame, UIParent:GetWidth() / 2 - 100, 0, true)


	if ( type(AZS_STATS) == "table" ) then
		stats = AZS_STATS
	elseif ( type(DB.lastStats) == "table" ) then
		stats = DB.lastStats
	end
	UpdateStatsFrame()
end


-- Apply a readable settings font and color, retaining the template font as fallback.
local function MenuFont(fs, size, r, g, b)
	fs:SetFont(MENU_FONT, size)
	if ( r ) then
		fs:SetTextColor(r, g, b)
	end
end


-- Create title, close button and drag behavior for addon-owned windows.
local function StyleWindow(f,titleText,subtitleText)
 FieldKitTheme.Surface(f,"window")
 FieldKitTheme.Label(f,titleText,16,10,f:GetWidth()-58,28,20,FieldKitTheme.gold,true)
 local close=CreateFrame("Button",f:GetName().."Close",f,"UIPanelCloseButton")
 close:SetWidth(26);close:SetHeight(26);close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-6)
 close:SetFrameLevel(f:GetFrameLevel()+10);close:SetScript("OnClick",function() f:Hide() end)
 f:SetFrameStrata("DIALOG");f:SetToplevel(1);f:EnableMouse(1);f:SetMovable(1)
 if f.SetClampedToScreen then f:SetClampedToScreen(1) end
 f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",function() f:StartMoving() end)
 f:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
end


local PICKER_ROW = 20

-- Build one checkbox per supported native statistic; preserve the user selection.
local function CreateStatsPicker()
	statsPicker = CreateFrame("Frame", "FieldKitStatsPicker", UIParent)
	statsPicker:SetWidth(280)
	statsPicker:SetHeight(38 + PICKER_ROW * table.getn(STATS))
	StyleWindow(statsPicker, "Stats")

	statsPicker.checks = {}
	for i = 1, table.getn(STATS) do
		local def = STATS[i]
		local check = CreateFrame("CheckButton", "FieldKitStatsPickerCheck"..i, statsPicker, "UICheckButtonTemplate")
		check:SetWidth(18)
		check:SetHeight(18)
		check:SetPoint("TOPLEFT", statsPicker, "TOPLEFT", 8, -32 - PICKER_ROW * ( i - 1 ))
		if ( check.SetHitRectInsets ) then
			check:SetHitRectInsets(0, -130, 0, 0)
		end
		local label = check:CreateFontString("FieldKitStatsPickerCheck"..i.."Label", "OVERLAY", "GameFontHighlightSmall")
		MenuFont(label, 13)
		label:SetPoint("LEFT", check, "RIGHT", 2, 1)
		FieldKit_Text(label,def[2])
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

-- Open/close the existing picker and fit it to the current viewport.
local function ToggleStatsPicker()
	if ( not statsPicker ) then
		CreateStatsPicker()
	end
	if ( statsPicker:IsShown() ) then
		statsPicker:Hide()
		return
	end
	statsPicker:SetScale(math.min(1,(UIParent:GetHeight()-30)/statsPicker:GetHeight()))
	statsPicker:ClearAllPoints()
	if ( panel and panel:IsShown() and UIParent:GetWidth() >= panel:GetWidth()+580 ) then
		statsPicker:SetPoint("TOPLEFT", panel, "TOPRIGHT", 2, 0)
	else
		statsPicker:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end
	statsPicker:Show()
end


local moneyFrame
local lastGold


-- Prefer the native run gold count; legacy fallback converts the client currency value.
local function RunGold()
	if ( HasAPI() and type(AZS_RUN) == "table" and AZS_RUN.gold ) then
		return AZS_RUN.gold
	end
	return math.floor(( GetMoney() or 0 ) / 10000)
end


-- Compute the historical fallback price schedule; authoritative AZS_RUN.chest takes priority.
local function ChestPrice(n)
	local price = 20
	for i = 2, n do
		price = math.floor(( price * 13 + 50 ) / 10)
	end
	return price
end

-- Read the native next chest price, or use the explicitly documented legacy estimate.
local function ChestCost()
	if HasAPI() and not AZS_GetPhase() then return nil end
	if ( HasAPI() and type(AZS_RUN) == "table" and AZS_RUN.chest ) then
		return AZS_RUN.chest
	end
	if ( DB.chestsOpened < 0 ) then
		return nil
	end
	return ChestPrice(DB.chestsOpened + 1)
end

-- Prefer the documented cache count; infer spending only on older clients missing it.
-- Neither path opens or buys a chest.
local function NoteGoldChange()
	if HasAPI() then
		if not AZS_GetPhase() then return end
		local exact=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.ck,nil,0)
		if exact then DB.chestsOpened=exact;lastGold=RunGold();return end
	end
	local gold = RunGold()
	if ( lastGold and gold < lastGold ) then
		local paid = lastGold - gold

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


-- Truncate large display values to k/m suffixes so the money strip remains readable.
local function Compact(v)
	v = v or 0
	if ( v < 10000 ) then
		return string.format("%d", v)
	elseif ( v < 100000 ) then
		return string.format("%.1fk", math.floor(v / 100) / 10)
	elseif ( v < 1000000 ) then
		return string.format(FieldKit_L("%dk"), math.floor(v / 1000))
	end
	return string.format("%.1fm", math.floor(v / 100000) / 10)
end

-- Keep gold/next-price/kills visible, respecting a deliberately detached strip position.
local function UpdateMoneyFrame()
	if ( not moneyFrame ) then
		return
	end
	if not DB.moneyFrame or (HasAPI() and not AZS_GetPhase())
  or FieldKit.IsChoiceScreen() then
  moneyFrame:Hide();return
 end
	local exact=HasAPI() and type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.ck,nil,0)
	if exact then DB.chestsOpened=exact end

	if ( not moneyFrame:IsShown() ) then
		moneyFrame:Show()
	end
	local cx, cy = moneyFrame:GetCenter()
	if ( cx and ( cx < 0 or cy < 0 or cx > UIParent:GetWidth() or cy > UIParent:GetHeight() ) ) then
		if ( DB.moneyDetached and DB.pos["FieldKitMoneyFrame"] and moneyFrame.azsDefault ) then

			PlaceMovable(moneyFrame)
		end
	end
	local gold = RunGold()
 FieldKitCardLayout.Money(moneyFrame)
	FieldKit_Text(moneyFrame.gold,Compact(gold))
	local chestCost = ChestCost()
	if ( chestCost ) then
		FieldKit_Text(moneyFrame.chest,Compact(chestCost))
		if ( chestCost > gold ) then
			moneyFrame.chest:SetTextColor(1.0, 0.1, 0.1)
		else
			moneyFrame.chest:SetTextColor(0.1, 1.0, 0.1)
		end
	else
		FieldKit_Text(moneyFrame.chest,"?")
		moneyFrame.chest:SetTextColor(0.6, 0.6, 0.6)
	end


	if ( DB.replaceTally and HasAPI() and type(AZS_RUN) == "table" and AZS_RUN.kills ) then
		FieldKit_Text(moneyFrame.kills,Compact(AZS_RUN.kills))
		moneyFrame.kills:Show()
		moneyFrame.killsLabel:Show()
	else
		moneyFrame.kills:Hide()
		moneyFrame.killsLabel:Hide()
	end
end


-- Synchronize only the native tally visibility for the user-selected replacement option.
local function SyncHudTally()
	if ( not HasAPI() or not AZS_SetHudShown ) then
		return
	end
	if ( DB.replaceTally and DB.moneyFrame ) then
		FieldKit.SetHudShown("tally", false)
		DB.hudTallyHidden = true
	elseif ( DB.hudTallyHidden ) then
		FieldKit.SetHudShown("tally", true)
		DB.hudTallyHidden = nil
	end
end

-- Create the movable gold/price/kills strip; docking is handled separately.
local function CreateMoneyFrame()
	moneyFrame = CreateFrame("Frame", "FieldKitMoneyFrame", UIParent)
	moneyFrame:SetFrameStrata("LOW")
	moneyFrame:SetClampedToScreen(1)
	moneyFrame:SetWidth(statsFrame:GetWidth())
	moneyFrame:SetHeight(22)
	moneyFrame:SetPoint("TOPLEFT", statsFrame, "BOTTOMLEFT", 0, -2)
	moneyFrame:SetBackdrop(statsFrame:GetBackdrop())
	moneyFrame:SetBackdropColor(0, 0, 0, 0.6)
	moneyFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
 FieldKitTheme.Surface(moneyFrame,"card",true)

	local coin = moneyFrame:CreateTexture("FieldKitMoneyFrameCoin", "ARTWORK")
	coin:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
	coin:SetTexCoord(0, 0.25, 0, 1)
	coin:SetWidth(12)
	coin:SetHeight(12)
	moneyFrame.coin = coin
	moneyFrame.gold = moneyFrame:CreateFontString("FieldKitMoneyFrameGold", "OVERLAY", "GameFontHighlightSmall")
	coin:SetPoint("RIGHT", moneyFrame.gold, "LEFT", -3, 0)

	moneyFrame.chest = moneyFrame:CreateFontString("FieldKitMoneyFrameChest", "OVERLAY", "GameFontHighlightSmall")
	moneyFrame.chest:SetPoint("RIGHT", moneyFrame, "RIGHT", -9, 0)
	local label = moneyFrame:CreateFontString("FieldKitMoneyFrameChestLabel", "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("RIGHT", moneyFrame.chest, "LEFT", -3, 0)
	moneyFrame.gold:SetPoint("RIGHT", label, "LEFT", -12, 0)
	FieldKit_Text(label,"Chest:")

	moneyFrame.killsLabel = moneyFrame:CreateFontString("FieldKitMoneyFrameKillsLabel", "OVERLAY", "GameFontNormalSmall")
	moneyFrame.killsLabel:SetPoint("LEFT", moneyFrame, "LEFT", 9, 0)
	FieldKit_Text(moneyFrame.killsLabel,"Kills:")
	moneyFrame.kills = moneyFrame:CreateFontString("FieldKitMoneyFrameKills", "OVERLAY", "GameFontHighlightSmall")
	moneyFrame.kills:SetPoint("LEFT", moneyFrame.killsLabel, "RIGHT", 3, 0)


 MakeMovable(moneyFrame,UIParent:GetWidth()/2-100,-110,true)
 local stop=moneyFrame:GetScript("OnDragStop")
 moneyFrame:SetScript("OnDragStop",function()
  if moneyFrame.azsMoving then stop();DB.moneyDetached=true end
 end)
	UpdateMoneyFrame()
end


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


-- Read a native equipment slot name and texture for display; never equip an item.
function ReadSlot(slotId)
	local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", slotId)
	local link = GetInventoryItemLink and GetInventoryItemLink("player", slotId)
	if ( link ) then
		local _, _, color = string.find(link, "|c(%x%x%x%x%x%x%x%x)")
		local _, _, name = string.find(link, "%[(.-)%]")
		return ( color and "|c"..color or "" )..( name or link ).."|r", texture
	end
	if ( not scanTip ) then
		scanTip = CreateFrame("GameTooltip", "FieldKitScanTip", nil, "GameTooltipTemplate")
	end
	scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scanTip:ClearLines()
	scanTip:SetInventoryItem("player", slotId)
	local line = FieldKitScanTipTextLeft1
	local name = line and line:IsShown() and line:GetText()
	if ( name and name ~= "" ) then
		local r, g, b = line:GetTextColor()
		return string.format(FieldKit_L("|cff%02x%02x%02x%s|r"), r * 255, g * 255, b * 255, name), texture
	end
	return nil, texture
end

-- Refresh equipment rows and the visible collapse state from current inventory data.
local function UpdateGearFrame()
 if not gearFrame then return end
 if not DB.gearFrame or (HasAPI() and not AZS_GetPhase()) then gearFrame:Hide();return end
 FieldKitLoadout.Render(gearFrame)
end

-- Build equipment labels/tooltips and a saved, collapsible movable container.
local function CreateGearFrame()
	gearFrame = CreateFrame("Frame", "FieldKitGearFrame", UIParent)
	gearFrame:SetFrameStrata("LOW")
	gearFrame:SetWidth(STACK_WIDTH)
	gearFrame:SetHeight(100)
	gearFrame:SetBackdrop(statsFrame:GetBackdrop())
	gearFrame:SetBackdropColor(0, 0, 0, 0.6)
	gearFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
 FieldKitTheme.Surface(gearFrame,"card",true)
	gearFrame.slots = {}
	AddCompactButton(gearFrame, "gearCollapsed", UpdateGearFrame)
	for i = 1, table.getn(GEAR_SLOTS) do
		local slotId = GEAR_SLOTS[i][1]
		local row = CreateFrame("Frame", "FieldKitGearSlot"..i, gearFrame)
		row:SetHeight(16)
		row:EnableMouse(1)
		row.icon = row:CreateTexture("FieldKitGearSlot"..i.."Icon", "ARTWORK")
		row.icon:SetWidth(14)
		row.icon:SetHeight(14)
		row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.label = row:CreateFontString("FieldKitGearSlot"..i.."Label", "OVERLAY", "GameFontNormalSmall")
		row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 20, 0)
		row.label:SetJustifyH("LEFT");row.label:SetJustifyV("TOP")
		row.value = row:CreateFontString("FieldKitGearSlot"..i.."Value", "OVERLAY", "GameFontHighlightSmall")
		row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, 0)
		row.value:SetPoint("TOPLEFT", row, "TOPLEFT", 80, 0)
		row.value:SetJustifyH("RIGHT")
  row.bonus=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.bonus:SetPoint("TOPLEFT",row,"TOPLEFT",20,-16);row.bonus:SetHeight(12);row.bonus:SetTextColor(.3,1,.4)
  row.bonus:SetJustifyH("LEFT");row.bonus:SetJustifyV("TOP");if row.bonus.SetNonSpaceWrap then row.bonus:SetNonSpaceWrap(true) end

		row:SetScript("OnEnter", function()
			if ( GetInventoryItemLink and GetInventoryItemLink("player", slotId) ) then
				GameTooltip:SetOwner(this, "ANCHOR_LEFT")
				GameTooltip:SetInventoryItem("player", slotId)
				GameTooltip:Show()
			end
		end)
		row:SetScript("OnLeave", function() GameTooltip:Hide() end)

		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function() gearFrame:GetScript("OnDragStart")() end)
		row:SetScript("OnDragStop", function() gearFrame:GetScript("OnDragStop")() end)
		gearFrame.slots[i] = row
	end

	gearFrame:SetPoint("BOTTOMLEFT", statsFrame, "TOPLEFT", 0, 2)
 MakeMovable(gearFrame,UIParent:GetWidth()/2-100,150,true)
 FieldKitLoadout.Attach(gearFrame,ReadSlot,UpdateGearFrame)
	UpdateGearFrame()
end


local METER_WIDTH = 220
local METER_ROWS = 8
local TAKEN_ROWS = 7
local ROW_HEIGHT = 15
local meterFrame, takenFrame

local TAKEN_NAMES = {
	["boss melee"] = "Boss melee",
	["boss spell"] = "Boss spells",
	["elite"] = "Elites",
	["mob melee"] = "Monster melee",
	["mob spell"] = "Monster spells",
	["area"] = "Ground effects",
}


-- WoW 1.12 does not clip child widgets to a shortened parent frame.
-- Remember visible children while folded, then restore them on expansion.
local function FoldChildren(f)
 local children={f:GetChildren()}
 for i=1,table.getn(children) do
  local child=children[i]
  if child~=f.mashCollapseButton and child:IsShown() then
   child.fieldkitFoldWasShown=true
   child:Hide()
  end
 end
end
local function UnfoldChildren(f)
 local children={f:GetChildren()}
 for i=1,table.getn(children) do
  local child=children[i]
  if child.fieldkitFoldWasShown then
   child.fieldkitFoldWasShown=nil
   child:Show()
  end
 end
end

-- Construct a bounded meter-style window with row pool, collapse button and drag handle.
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
 FieldKitTheme.Surface(f,"card",true)
	f.title = f:CreateFontString(name.."Title", "OVERLAY", "GameFontNormalSmall")
	f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 9, -7)
	FieldKit_Text(f.title,title)
	f.total = f:CreateFontString(name.."Total", "OVERLAY", "GameFontHighlightSmall")
	f.total:SetPoint("TOPRIGHT", f, "TOPRIGHT", -25, -7)
	local collapse = FieldKitTheme.Button(f,name.."Collapse","-",0,0,18,17,nil);collapse:ClearAllPoints()
	collapse:SetWidth(18); collapse:SetHeight(17)
	collapse:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
	FieldKit_Text(collapse,"-")
	collapse:SetFrameLevel(f:GetFrameLevel() + 10)
	collapse:SetScript("OnClick", function()
		local collapsed = not f.mashCollapsed
  if f.nextBoss then
   if collapsed then
    f.nextBoss:Hide();if f.nextBossTime then f.nextBossTime:Hide() end
    if f.bossBar then f.bossBar:Hide() end;if f.bossPct then f.bossPct:Hide() end
   elseif (f.fieldkitFooterHeight or 0)>0 then
    -- Content refresh decides countdown versus live boss strip.
   end
  end
		f.mashCollapsed = collapsed
		DB.collapsedWindows = DB.collapsedWindows or {}
		DB.collapsedWindows[name] = collapsed or nil
		if collapsed then
			f.mashExpandHeight = f:GetHeight()
			f:SetHeight(24);FieldKitTheme.Update(f); f.total:Hide()
			for j = 1, table.getn(f.rows) do f.rows[j]:Hide() end
			FieldKit_Text(this,"+");FoldChildren(f)
		else
			f:SetHeight(f.mashExpandHeight > 24 and f.mashExpandHeight or 45);FieldKitTheme.Update(f)
			f.total:Show(); FieldKit_Text(this,"-");UnfoldChildren(f)
   for j=1,(f.mashVisibleRows or 0) do f.rows[j]:Show() end
   FieldKitCardLayout.Rows(f,f.fieldkitNaturalHeight or (28+ROW_HEIGHT*math.max(f.mashVisibleRows or 0,1)),f.mashVisibleRows or 0,f.fieldkitRowKind or "bar",false)
		end
		FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight()
  if RefreshCollapseDock then RefreshCollapseDock() end
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

		row:EnableMouse(1)
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function() f:GetScript("OnDragStart")() end)
		row:SetScript("OnDragStop", function() FinishMoving(f) end)
		row:SetScript("OnMouseUp", function() FinishMoving(f) end)
		row:Hide()
		f.rows[i] = row
	end
	if DB and DB.collapsedWindows and DB.collapsedWindows[name] then
		f.mashCollapsed = true; f.mashExpandHeight = f:GetHeight()
		f:SetHeight(24);FieldKitTheme.Update(f); f.total:Hide(); FieldKit_Text(collapse,"+");FoldChildren(f)
	end
	return f
end


-- Reconcile live profile switches with existing meter/taken/lair panels.
-- Their collapse buttons are created once, so DB replacement alone does not
-- update the frame state until explicitly synchronized.
local function SyncBarWindowCollapse(f)
 if not f or not DB then return end
 local wanted=DB.collapsedWindows and DB.collapsedWindows[f:GetName()] and true or false
 if f.mashCollapsed==wanted then return end
 f.mashCollapsed=wanted
 FieldKit_Text(f.mashCollapseButton,wanted and "+" or "-")
 if wanted then
  f.total:Hide()
  for i=1,table.getn(f.rows) do f.rows[i]:Hide() end
  if f.nextBoss then f.nextBoss:Hide() end
  if f.nextBossTime then f.nextBossTime:Hide() end
  if f.bossBar then f.bossBar:Hide() end
  if f.bossPct then f.bossPct:Hide() end
  f:SetHeight(24)
  FoldChildren(f)
 else
  UnfoldChildren(f)
  f.total:Show()
  f:SetHeight(f.mashExpandHeight>24 and f.mashExpandHeight or 45)
 end
 FieldKitTheme.Update(f)
end

-- Size the visible row pool while keeping a collapsed window at header height.
local function FitRows(f, n)
 f.mashVisibleRows=n
	for i = n + 1, table.getn(f.rows) do
		f.rows[i]:Hide()
	end
	local height = 28 + (f.fieldkitFooterHeight or 0) + ROW_HEIGHT * math.max(n, 1)
	f.mashExpandHeight = height
	if f.mashCollapsed then
		f.total:Hide()
		for i = 1, table.getn(f.rows) do f.rows[i]:Hide() end
		f:SetHeight(24)
	else f:SetHeight(height); f.total:Show() end
 f.mashExpandHeight=FieldKitCardLayout.Rows(f,height,n,"bar",f.mashCollapsed)
 if f.mashCollapsed then FoldChildren(f) end
end

-- Require the native API and a non-nil native phase before using run data.
local function InRun()
	return HasAPI() and AZS_GetPhase() ~= nil
end

-- Refresh native total DPS at snapshot cadence; rebuild rows only when their list changes.
local function UpdateMeterFrame(force)
 if not meterFrame then return end
 if not DB.meterFrame or not InRun() then meterFrame:Hide();return end
 local mode=FieldKitMeters.Mode()
 local lines,total,rate,known=FieldKitMeters.Read(mode)
 FieldKit_Text(meterFrame.title,FieldKitMeters.labels[mode])
 meterFrame.fieldkitMeterView=mode
 local width=FieldKitCardLayout.Width(meterFrame,FieldKit.MeterWidth(DB.meterValues))
 if meterFrame:GetWidth()~=width then
  local previous=meterFrame:GetWidth();meterFrame:SetWidth(width);FieldKitTheme.Update(meterFrame)
  if not DB.linkLeftCards and meterFrame.azsDefault and not meterFrame.azsMoving then
   local position=DB.pos[meterFrame:GetName()]
   if position then position[1]=position[1]+(width-previous)/2 end
   PlaceMovable(meterFrame)
  end
 end
 local rateLabel=mode==2 and "hps" or "dps"
 if known then meterFrame.total:SetText((total and ShortNumber(total) or "?").."  ("..(rate and ShortNumber(rate) or "?").." "..FieldKit_L(rateLabel)..")")
 else FieldKit_Text(meterFrame.total,"Not provided") end
 local top=lines[1] and lines[1].dmg or 1
 local n=math.min(table.getn(lines),METER_ROWS)
 for i=1,n do
  local line,row=lines[i],meterFrame.rows[i]
  row:SetValue((line.dmg or 0)/math.max(top or 0,1))
  if line.proc==1 then row:SetStatusBarColor(.25,.45,.9,.55)
  else row:SetStatusBarColor(mode==2 and .2 or .8,mode==2 and .7 or .55,.2,.55) end
  row.label:SetText(line.name);FieldKit.UpdateMeterColumns(row,line,DB.meterValues,width,rateLabel);row:Show()
 end
 if n==0 and not known then
  local row=meterFrame.rows[1];FieldKitLoadout.ClearIcon(row);FieldKit_Text(row.label,"Meter data not provided");row.label:SetWidth(width-24)
  row:SetValue(0);row.value:Hide();for _,column in ipairs(row.meterColumns) do column:Hide() end
  row.meterMode=nil;row:Show();n=1
 end
 FitRows(meterFrame,n);meterFrame:Show()
end

-- Render native damage-source totals separately; do not infer individual enemy hits.
local function UpdateTakenFrame(force)
 if not takenFrame then return end
 if not DB.takenFrame or not InRun() then takenFrame:Hide();return end
 local lines,sum,known=FieldKitCoop.Taken()
 FieldKit_Text(takenFrame.total,known and ShortNumber(sum) or "Not provided")
 local n=math.min(table.getn(lines),TAKEN_ROWS)
 local top=lines[1] and lines[1].dmg or 1
 for i=1,n do
  local row=takenFrame.rows[i];local line=lines[i]
  row.takenSource=line.source;row.takenDamage=line.dmg
  row:SetValue(line.dmg/math.max(top,1));row:SetStatusBarColor(.75,.1,.1,.55)
  FieldKit_Text(row.label,TAKEN_NAMES[line.source] or line.source)
  row.value:SetText(string.format("%s  %.0f%%",ShortNumber(line.dmg),100*line.dmg/math.max(sum,1)))
  row:Show()
 end
 if n==0 then
  local row=takenFrame.rows[1];row.takenSource=nil;row:SetValue(0);row.value:SetText("")
  FieldKit_Text(row.label,known and "No damage taken yet" or "Damage data not provided")
  row:Show();n=1
 end
 FitRows(takenFrame,n);takenFrame:Show()
end

-- Restore a native meter hidden by an older configuration; this addon does not replace it.
local function SyncHudMeter()
	if ( DB.hudMeterHidden and HasAPI() and AZS_SetHudShown ) then
		FieldKit.SetHudShown("meter", true)
		DB.hudMeterHidden = nil
	end
end

-- Create fixed outgoing/taken meter pools, each independently collapsible.
local function CreateMeterFrames()
	meterFrame = CreateBarWindow("FieldKitMeterFrame", "Damage", METER_ROWS)
 meterFrame:SetWidth(FieldKit.MeterWidth(DB.meterValues));FieldKitTheme.Update(meterFrame)
 FieldKit.CreateMeterColumns(meterFrame)
 for i=1,table.getn(meterFrame.rows) do FieldKitPartyDetails.BindRow(meterFrame.rows[i],meterFrame,true) end
	takenFrame = CreateBarWindow("FieldKitTakenFrame", "Damage taken", TAKEN_ROWS)
 for _,row in ipairs(takenFrame.rows) do
  row:SetScript("OnEnter",function() FieldKitTakenDetails.Show(this) end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end

	takenFrame:SetPoint("TOPLEFT", meterFrame, "BOTTOMLEFT", 0, -2)
	MakeMovable(meterFrame, -( UIParent:GetWidth() / 2 - 140 ), 60, true)
 MakeMovable(takenFrame,-(UIParent:GetWidth()/2-140),-60,true)
	meterFrame:Hide()
	takenFrame:Hide()
 if FieldKitMeterSuite and FieldKitMeterSuite.HookMeter then FieldKitMeterSuite.HookMeter(meterFrame) end
end

-- Refresh both optional meter displays, supporting an explicit forced refresh.
local function UpdateMeterFrames(force)
 local d=DB or FieldKitDB
 if FieldKitMeterSuite and FieldKitMeterSuite.Update and d and d.meterTabs~=false then
  FieldKitMeterSuite.Update(force)
  local view=d.meterViewKey or "damage"
  local onTaken=(view=="taken") or d.meterDetach_taken
  if d.takenFrame and (not onTaken or d.meterKeepTakenFrame) then UpdateTakenFrame(force) end
 else
  UpdateMeterFrame(force)
  UpdateTakenFrame(force)
  FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight()
 end
end

local UpdateChestPins, UpdateLairFrame, CreateLairFrame
do


-- Delegate world projection to WorldPins.lua; no second projection implementation exists.
function UpdateChestPins()
 if FieldKit_UpdateWorldPins then FieldKit_UpdateWorldPins() end
end


local LAIR_ROWS = 10
local LAIR_DIST_COLORS = { { 0.2, 1.0, 0.2 }, { 1.0, 1.0, 0.2 }, { 1.0, 0.55, 0.1 }, { 1.0, 0.2, 0.2 } }
local lairFrame

-- Format a non-negative whole-second lair return countdown as minutes:seconds.
local function FormatClock(s)
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", math.floor(s / 60), s - 60 * math.floor(s / 60))
end

-- Sort exposed lair world positions by distance and show native guardian states.
function UpdateLairFrame()
	if ( not lairFrame ) then
		return
	end
	if ( not DB.lairFrame or not HasAPI() or not AZS_GetLairs or not AZS_GetPhase() ) then
		lairFrame:Hide()
		return
	end
	local lairs = AZS_GetLairs()
	local nextBoss=DB.lairNextBoss and FieldKitNativeTools.NextBoss()
 if ( table.getn(lairs) == 0 and not nextBoss ) then
		lairFrame:Hide()
		return
	end
	local px = type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.px)
	local py = type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.py)
	local held = 0
 local flagged=DB.highlightFlaggedLair and FieldKitNative.Read("AZS_GetFlaggedLair")
	local n = math.min(table.getn(lairs), LAIR_ROWS)


	local dists, order = {}, {}
	for i = 1, n do
		if ( px and py and FieldKit.Number(lairs[i].x) and FieldKit.Number(lairs[i].y) ) then
			local east, north = py-tonumber(lairs[i].y), tonumber(lairs[i].x)-px
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
			state, r, g, b = "asleep", 0.2, 1.0, 0.2
			held = held + 1
		elseif ( tonumber(l.left) and l.left > 0 ) then
			state, r, g, b = FieldKit_L("back in ")..FormatClock(l.left), 0.6, 0.6, 0.6
		else
			state, r, g, b = "empty", 0.6, 0.6, 0.6
		end
		row:SetValue(0)
		local flaggedRow=type(flagged)=="table" and ((flagged.index and flagged.index==l.index) or (flagged.id and flagged.id==l.id))
		row.label:SetText((flaggedRow and "> " or "")..(l.name or "?"))
		row.label:SetTextColor(r, g, b)
		row.value:SetText(FieldKit_L(state))
		row.value:SetTextColor(r, g, b)
		if ( dists[i] ) then

			local c = LAIR_DIST_COLORS[math.min(rank[i], table.getn(LAIR_DIST_COLORS))]
			if ( rank[i] == table.getn(order) and table.getn(order) > 1 ) then
				c = LAIR_DIST_COLORS[table.getn(LAIR_DIST_COLORS)]
			end
			FieldKit_Text(row.dist,string.format(FieldKit_L("%d yd"), dists[i]))
			row.dist:SetTextColor(c[1], c[2], c[3])
		else
			FieldKit_Text(row.dist,"")
		end
		row:Show()
	end
	FieldKit_Text(lairFrame.total,held.." / "..table.getn(lairs)..FieldKit_L(" held"))
 -- Prefer a living boss HP strip; otherwise keep the scheduled arrival countdown.
 local live
 if type(AZS_UNITS)=="table" and AZS_GetPhase and AZS_GetPhase() and AZS_GetPhase()~="ready" then
  for i=1,math.min(512,table.getn(AZS_UNITS)) do
   local e=AZS_UNITS[i];local kind=Field(e,"kind",1)
   if kind=="final" or kind=="boss" then
    local hp,hpm=Field(e,"hp",4),Field(e,"hpm",5)
    if FieldKit.Number(hpm) and hpm>0 then
     live={name=Field(e,"name",3) or "?",hp=hp or 0,hpm=hpm,enraged=Field(e,"state",6)}
     break
    end
   end
  end
 end
 local footer=0
 if live then footer=40 elseif nextBoss then footer=28 end
 lairFrame.fieldkitFooterHeight=footer
 if lairFrame.mashCollapsed or footer==0 then
  lairFrame.nextBoss:Hide();lairFrame.nextBossTime:Hide();lairFrame.bossBar:Hide();lairFrame.bossPct:Hide()
 elseif live then
  local pct=math.max(0,math.min(1,(live.hp or 0)/live.hpm))
  local info=string.format("%d%%",math.floor(pct*100+.5))
  if live.enraged==1 or live.enraged==true then info=FieldKit_L("ENRAGED").."  "..info end
  -- Keep name / % / bar clear of the decorative corner chrome.
  lairFrame.nextBoss:SetText(live.name);lairFrame.nextBoss:SetTextColor(1,.82,0)
  lairFrame.nextBoss:SetFontObject(GameFontNormal)
  lairFrame.nextBoss:ClearAllPoints();lairFrame.nextBoss:SetPoint("BOTTOMLEFT",lairFrame,"BOTTOMLEFT",12,24)
  lairFrame.nextBoss:SetWidth(lairFrame:GetWidth()-96);lairFrame.nextBoss:Show()
  lairFrame.nextBossTime:Hide()
  lairFrame.bossPct:ClearAllPoints();lairFrame.bossPct:SetPoint("BOTTOMRIGHT",lairFrame,"BOTTOMRIGHT",-14,24)
  lairFrame.bossPct:SetWidth(68);lairFrame.bossPct:SetText(info);lairFrame.bossPct:Show()
  lairFrame.bossBar:ClearAllPoints();lairFrame.bossBar:SetPoint("BOTTOMLEFT",lairFrame,"BOTTOMLEFT",12,10)
  lairFrame.bossBar:SetMinMaxValues(0,live.hpm);lairFrame.bossBar:SetValue(live.hp or 0)
  lairFrame.bossBar:SetWidth(lairFrame:GetWidth()-24);lairFrame.bossBar:Show()
 else
  lairFrame.nextBoss:SetText(FieldKit_L("Next boss")..": "..nextBoss.name)
  lairFrame.nextBoss:SetTextColor(1,.82,0);lairFrame.nextBoss:SetFontObject(GameFontNormal)
  lairFrame.nextBoss:ClearAllPoints();lairFrame.nextBoss:SetPoint("BOTTOMLEFT",lairFrame,"BOTTOMLEFT",12,10)
  lairFrame.nextBoss:SetWidth(lairFrame:GetWidth()-86);lairFrame.nextBoss:Show()
  lairFrame.nextBossTime:ClearAllPoints();lairFrame.nextBossTime:SetPoint("BOTTOMRIGHT",lairFrame,"BOTTOMRIGHT",-14,10)
  lairFrame.nextBossTime:SetWidth(56);lairFrame.nextBossTime:SetText(FieldKitNative.Clock(nextBoss.left))
  lairFrame.nextBossTime:SetTextColor(1,.9,.75);lairFrame.nextBossTime:SetFontObject(GameFontNormal)
  lairFrame.nextBossTime:Show();lairFrame.bossBar:Hide();lairFrame.bossPct:Hide()
 end
 FitRows(lairFrame, n)
	lairFrame:Show()
end

-- Allocate the ten-row lair window with separate distance/state columns.
function CreateLairFrame()
	lairFrame = CreateBarWindow("FieldKitLairFrame", "Lairs", LAIR_ROWS)
 lairFrame.nextBoss=lairFrame:CreateFontString(nil,"OVERLAY","GameFontNormal");lairFrame.nextBoss:SetPoint("BOTTOMLEFT",lairFrame,"BOTTOMLEFT",12,10);lairFrame.nextBoss:SetHeight(16);lairFrame.nextBoss:SetJustifyH("LEFT");lairFrame.nextBoss:SetTextColor(1,.82,0);lairFrame.nextBoss:Hide()
 lairFrame.nextBossTime=lairFrame:CreateFontString(nil,"OVERLAY","GameFontNormal");lairFrame.nextBossTime:SetPoint("BOTTOMRIGHT",lairFrame,"BOTTOMRIGHT",-14,10);lairFrame.nextBossTime:SetWidth(56);lairFrame.nextBossTime:SetHeight(16);lairFrame.nextBossTime:SetJustifyH("RIGHT");lairFrame.nextBossTime:SetTextColor(1,.9,.75);lairFrame.nextBossTime:Hide()
 lairFrame.bossPct=lairFrame:CreateFontString(nil,"OVERLAY","GameFontNormal");lairFrame.bossPct:SetPoint("BOTTOMRIGHT",lairFrame,"BOTTOMRIGHT",-14,24);lairFrame.bossPct:SetWidth(68);lairFrame.bossPct:SetHeight(16);lairFrame.bossPct:SetJustifyH("RIGHT");lairFrame.bossPct:SetTextColor(1,.9,.75);lairFrame.bossPct:Hide()
 lairFrame.bossBar=CreateFrame("StatusBar",nil,lairFrame);lairFrame.bossBar:SetHeight(8);lairFrame.bossBar:SetPoint("BOTTOMLEFT",lairFrame,"BOTTOMLEFT",12,10)
 lairFrame.bossBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");lairFrame.bossBar:SetStatusBarColor(.82,.13,.08);lairFrame.bossBar:SetMinMaxValues(0,1);lairFrame.bossBar:Hide()
 local barBg=lairFrame.bossBar:CreateTexture(nil,"BACKGROUND");barBg:SetAllPoints(lairFrame.bossBar);barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");barBg:SetVertexColor(.12,.08,.05)

	for i = 1, LAIR_ROWS do
		local row = lairFrame.rows[i]
		row.dist = row:CreateFontString("FieldKitLairFrameRow"..i.."Dist", "OVERLAY", "GameFontHighlightSmall")
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
 return lairFrame
end

end


local DAMAGE_CVARS = { "CombatDamage", "PetMeleeDamage", "PetSpellDamage" }

-- Apply the three allowlisted native damage display switches only when configured.
local function ApplyDamageNumbers()
	if ( DB.hideDamage == nil ) then
		return
	end
	for i = 1, table.getn(DAMAGE_CVARS) do
		FieldKit.SetCVar(DAMAGE_CVARS[i], DB.hideDamage and "0" or "1")
	end
end


-- Explicit editor action: enable scrolling text and suppress the two other damage displays.
function FieldKit_UseCombatTextOnly()
 if not DB then return end
 DB.combatText=true;DB.hideDamage=true;DB.showCrits=false
 ApplyDamageNumbers()
end


local CreateCompactBar, UpdateCompactXP, KeepCompactBar, AttachMoneyToBar
do


local BAR_SLOTS = { 1, 2, 3, 4, 5, 6, 12 }
local BAR_BUTTON = 36
local BAR_GAP = 4
local BAR_PAD = 6
local XP_HEIGHT = 7
local XP_SEGMENTS = 10
local compactBar
local PlaceMicroMenu


local dragSource

-- Resolve a dragged native action button to its paged action-slot id.
local function SlotOf(b)
	if ( ActionButton_GetPagedID ) then
		return ActionButton_GetPagedID(b)
	end
	return b:GetID()
end

-- On user drag only, exchange two native action slots through PickupAction/PlaceAction.
local function SwapSlots(a, b)
	if type(ClearCursor)~="function" or type(PickupAction)~="function" or type(PlaceAction)~="function" then return end
	ClearCursor()
	PickupAction(a)
	PlaceAction(b)
	PlaceAction(a)
	ClearCursor()
end

-- Replace native drag handlers only when compact bar is enabled; dropping outside changes nothing.
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
			if ( target and target ~= source and type(MouseIsOver)=="function" and MouseIsOver(target) ) then
				SwapSlots(SlotOf(source), SlotOf(target))
				return
			end
		end
	end)
end


local MICRO_BUTTONS = { "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"QuestLogMicroButton", "SocialsMicroButton", "WorldMapMicroButton", "MainMenuMicroButton", "HelpMicroButton" }
local microMenu
local microShown

-- Reposition already-existing native micro-menu buttons; retain the original visibility choices.
function PlaceMicroMenu()
	if ( not microMenu ) then
		microShown = {}
		for i = 1, table.getn(MICRO_BUTTONS) do
			local b = getglobal(MICRO_BUTTONS[i])
			if ( b and b:IsShown() ) then
				table.insert(microShown, MICRO_BUTTONS[i])
			end
		end
		microMenu = CreateFrame("Frame", "FieldKitMicroMenu", UIParent)
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

-- Reparent the seven native action buttons into the optional compact bar.
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

-- Read player XP and refresh the compact display; no XP or progression is written.
function UpdateCompactXP()
	if ( not compactBar ) then
		return
	end
	local cur, max = UnitXP("player") or 0, UnitXPMax("player") or 0
	compactBar.xp:SetMinMaxValues(0, math.max(max, 1))
	compactBar.xp:SetValue(cur)
	FieldKit_Text(compactBar.xpText,"XP "..cur.." / "..max)
end

-- Optional invasive layout: reparent native buttons, hide stock bar, dock money/XP.
function CreateCompactBar()
	if ( not DB.compactBar or not MainMenuBar ) then
		return
	end
	local slots = table.getn(BAR_SLOTS)
	compactBar = CreateFrame("Frame", "FieldKitCompactBar", UIParent)
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
 FieldKitTheme.Surface(compactBar,"card",true)


	local xp = CreateFrame("StatusBar", "FieldKitCompactBarXP", compactBar)
	xp:SetHeight(XP_HEIGHT)
	xp:SetPoint("BOTTOMLEFT", compactBar, "BOTTOMLEFT", BAR_PAD, BAR_PAD)
	xp:SetPoint("BOTTOMRIGHT", compactBar, "BOTTOMRIGHT", -BAR_PAD, BAR_PAD)
	xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	xp:SetStatusBarColor(0.58, 0.0, 0.55)
	local bg = xp:CreateTexture("FieldKitCompactBarXPBg", "BACKGROUND")
	bg:SetAllPoints(xp)
	bg:SetTexture(0.1, 0.0, 0.1, 0.8)
	local width = compactBar:GetWidth() - BAR_PAD * 2
	for s = 1, XP_SEGMENTS - 1 do
		local tick = xp:CreateTexture("FieldKitCompactBarXPTick"..s, "OVERLAY")
		tick:SetTexture(0, 0, 0, 0.8)
		tick:SetWidth(1)
		tick:SetPoint("TOPLEFT", xp, "TOPLEFT", width * s / XP_SEGMENTS, 0)
		tick:SetPoint("BOTTOMLEFT", xp, "BOTTOMLEFT", width * s / XP_SEGMENTS, 0)
	end
	compactBar.xp = xp

	compactBar.xpText = xp:CreateFontString("FieldKitCompactBarXPText", "OVERLAY", "GameFontHighlightSmall")
	compactBar.xpText:SetPoint("BOTTOM", xp, "TOP", 0, 2)
	compactBar.xpText:Hide()
	xp:EnableMouse(1)
	xp:SetScript("OnEnter", function() compactBar.xpText:Show() end)
	xp:SetScript("OnLeave", function() compactBar.xpText:Hide() end)


	local barH = compactBar:GetHeight()
	MakeMovable(compactBar, 0, -( UIParent:GetHeight() / 2 ) + barH / 2 + 8)
	compactBar:SetClampedToScreen(1)

	PlaceBarButtons()


	if ( moneyFrame ) then
		moneyFrame:SetParent(UIParent)
		moneyFrame:SetFrameStrata("MEDIUM")
		moneyFrame:SetWidth(compactBar:GetWidth())
		MakeMovable(moneyFrame, 0, 0, true)

		local stop = moneyFrame:GetScript("OnDragStop")
		moneyFrame:SetScript("OnDragStop", function()
			stop()
			DB.moneyDetached = true
		end)
		moneyFrame:SetClampedToScreen(1)


		local repair = DB.moneyDockRepair ~= 1
		AttachMoneyToBar(repair)
		DB.moneyDockRepair = 1
		if not DB.moneyFrame or (HasAPI() and not AZS_GetPhase()) then moneyFrame:Hide() else moneyFrame:Show() end
	end


	MainMenuBar:Hide()
	MainMenuBar:SetScript("OnShow", function() this:Hide() end)
	UpdateCompactXP()
	KeepCompactBar()
end


-- Dock or repair the strip unless the user intentionally detached it.
function AttachMoneyToBar(force)
	if ( not compactBar or not moneyFrame ) then return end
	if ( force ) then DB.moneyDetached = nil;DB.frameAnchors.FieldKitMoneyFrame=nil end
	if ( not DB.moneyDetached and not moneyFrame.azsMoving ) then
		if moneyFrame:GetParent() ~= UIParent then moneyFrame:SetParent(UIParent) end
		moneyFrame:SetFrameStrata("MEDIUM")
		moneyFrame:SetFrameLevel(compactBar:GetFrameLevel() + 2)
		local width = compactBar:GetWidth()
		if width and width > 0 then moneyFrame:SetWidth(width);FieldKitTheme.Update(moneyFrame) end
		moneyFrame:SetHeight(22)
  FieldKitCardLayout.Money(moneyFrame)
		local point, relative, relativePoint, x, y = moneyFrame:GetPoint(1)
		if point ~= "BOTTOM" or relative ~= compactBar or relativePoint ~= "TOP" or x ~= 0 or y ~= 2 then
			moneyFrame:ClearAllPoints()
			moneyFrame:SetPoint("BOTTOM", compactBar, "TOP", 0, 2)
		end
		if not DB.moneyFrame or (HasAPI() and not AZS_GetPhase()) or FieldKit.IsChoiceScreen() then
   moneyFrame:Hide()
  else moneyFrame:Show() end
	end
end

-- Maintain optional compact anchors and prevent the bar from falling below the viewport.
function KeepCompactBar()
	if ( not compactBar ) then
		return
	end
 -- The old repair loop resurrected action buttons hidden by native choices.
 -- Suppress our whole compact surface, including XP, before touching buttons.
 -- Remember only visibility we changed, so unrelated hidden state stays hidden.
 if FieldKit.IsChoiceScreen() then
  if compactBar:IsShown() then
   compactBar.fieldkitChoiceHidden=true
   compactBar:Hide()
  end
  if moneyFrame then moneyFrame:Hide() end
  return
 end
 if compactBar.fieldkitChoiceHidden then
  compactBar.fieldkitChoiceHidden=nil
  compactBar:Show()
 end
	AttachMoneyToBar(false)
	if ( ( ActionButton1 and ActionButton1:GetParent() ~= compactBar )
		or ( MainMenuMicroButton and microMenu and MainMenuMicroButton:GetParent() ~= microMenu ) ) then
		PlaceBarButtons()
	end

	for i = 1, table.getn(BAR_SLOTS) do
		local b = getglobal("ActionButton"..BAR_SLOTS[i])
		if ( b and not b:IsShown() and HasAction(BAR_SLOTS[i]) ) then
			b:Show()
		end
	end

	local bottom = compactBar:GetBottom()
	if ( bottom and bottom < 0 and not compactBar.azsMoving and not DB.frameAnchors.FieldKitCompactBar ) then
		local p = DB.pos["FieldKitCompactBar"]
		p[2] = p[2] - bottom
		PlaceMovable(compactBar)
	end
end

end


-- Apply the optional native action-bar decorative end-cap visibility setting.
local function UpdateGryphons()
	if DB.hideGryphons==nil then return end -- Unset means preserve the native/other-addon state.
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


-- A detached, compact dock keeps folded windows out of the play area.
-- The original frames retain their saved geometry and can be restored in one click.
local collapseDock,collapseDockButtons
local function BuildCollapseDock()
 if collapseDock then return end
 collapseDock=CreateFrame("Frame","FieldKitCollapseDock",UIParent)
 collapseDock:SetFrameStrata("HIGH")
 collapseDock:SetWidth(164);collapseDock:SetHeight(24)
 collapseDock:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-18,110)
 collapseDockButtons={}
 local labels={"Mode de jeu","Dégâts","Dégâts subis","Antres","Statistiques","Accessoires / Sorts"}
 for i=1,6 do
  local index=i
  local button=FieldKitTheme.Button(collapseDock,nil,labels[i],0,0,164,23,nil)
  button:ClearAllPoints()
  button:SetPoint("BOTTOMRIGHT",collapseDock,"BOTTOMRIGHT",0,0)
  button:SetScript("OnClick",function()
   if index==1 and DB.collapsedWindows then DB.collapsedWindows.FieldKitRunModeFrame=nil
   elseif index==2 or index==3 or index==4 then
    local f=index==2 and meterFrame or index==3 and takenFrame or lairFrame
    if f and f.mashCollapseButton then f.mashCollapseButton:Click() end
   elseif index==5 then DB.statsCollapsed=false;UpdateStatsFrame()
   elseif index==6 then DB.gearCollapsed=false;UpdateGearFrame() end
   if RefreshCollapseDock then RefreshCollapseDock() end
  end)
  collapseDockButtons[i]=button
 end
end
RefreshCollapseDock=function()
 if not DB then return end
 BuildCollapseDock()
 local frames={nil,meterFrame,takenFrame,lairFrame,statsFrame,gearFrame}
 local states={false,meterFrame and meterFrame.mashCollapsed,takenFrame and takenFrame.mashCollapsed,
  lairFrame and lairFrame.mashCollapsed,DB.statsCollapsed,DB.gearCollapsed}
 local count=0
 for i=1,6 do
  local f=frames[i]
  local active=states[i] and f and f:IsShown()
  if active then
   count=count+1
   collapseDockButtons[i]:ClearAllPoints()
   collapseDockButtons[i]:SetPoint("BOTTOMRIGHT",collapseDock,"BOTTOMRIGHT",0,(count-1)*26)
   collapseDockButtons[i]:Show()
   f:Hide()
   f.fieldkitDockHidden=true
  else
   collapseDockButtons[i]:Hide()
   if f and f.fieldkitDockHidden then
    f.fieldkitDockHidden=nil
    f:Show()
   end
  end
 end
 collapseDock:SetHeight(math.max(24,count*26))
 if count>0 then collapseDock:Show() else collapseDock:Hide() end
end

local settingsActions={
 SetFilter=SetFilter,
 UpdateTargetHealth=UpdateTargetHealth,
 SyncHudBosses=SyncHudBosses,
 UpdateBossFrame=UpdateBossFrame,
 ApplyDamageNumbers=ApplyDamageNumbers,
 UpdatePlayerBar=UpdatePlayerBar,
 UpdatePlayerBuffs=UpdatePlayerBuffs,
 TestLowHealth=TestLowHealth,
 UpdateStatsFrame=UpdateStatsFrame,
 ToggleStatsPicker=ToggleStatsPicker,
 SyncHudTally=SyncHudTally,
 UpdateMoneyFrame=UpdateMoneyFrame,
 UpdateMeterFrames=UpdateMeterFrames,
 UpdateGearFrame=UpdateGearFrame,
 UpdateChestPins=UpdateChestPins,
 UpdateLairFrame=UpdateLairFrame,
 UpdateGryphons=UpdateGryphons,
 UpdateHudStack=function() FieldKitHudStack.Apply();UpdateMeterFrames(true) end,
 UpdateRunMode=function() FieldKitRunMode.Update();FieldKitHudStack.Apply() end,
}
-- Safe live application boundary for a FieldKit HUD-only profile.
-- This is deliberately NOT a ReloadUI and never invokes chat styling, party
-- transport, native action bar rebuilding, camera CVars or game-save changes.
function FieldKit.ApplyHUDProfileLive()
 if not DB or FieldKit.layoutEditing then return false end
 if (FieldKitHudStack.root and FieldKitHudStack.root.azsMoving) or
  (FieldKitCardLayout.root and FieldKitCardLayout.root.azsMoving) then return false end
 for i=1,table.getn(movableFrames) do
  if movableFrames[i].azsMoving then return false end
 end
 FieldKitHudStack.FinishDragging()
 -- Restore saved geometry only for registered FieldKit-owned movable frames.
 for i=1,table.getn(movableFrames) do
  local f=movableFrames[i]
  if DB.pos[f:GetName()] then PlaceMovable(f) end
 end
 -- Recompute cached group anchors even when the root size is unchanged.
 FieldKitHudStack.appliedAnchor=nil
 FieldKitHudStack.legacyX=nil
 FieldKitCardLayout.anchor=nil
 settingsActions.UpdateStatsFrame()
 settingsActions.UpdateGearFrame()
 SyncBarWindowCollapse(meterFrame)
 SyncBarWindowCollapse(takenFrame)
 SyncBarWindowCollapse(lairFrame)
 settingsActions.UpdateRunMode()
 settingsActions.UpdateMeterFrames(true)
 settingsActions.UpdateLairFrame()
 settingsActions.UpdateMoneyFrame()
 settingsActions.SyncHudTally()
 settingsActions.UpdatePlayerBar()
 settingsActions.UpdatePlayerBuffs()
 settingsActions.UpdateBossFrame()
 FieldKitBossTimeline.Update()
 FieldKitNativeTools.Update()
 FieldKitCoop.Update()
 FieldKitHudStack.Apply()
 FieldKitCardLayout.ApplyRight()
 FieldKitTheme.Refresh()
 RefreshCollapseDock()
 -- A profile is now a full preference context, not merely a HUD layout.
 -- Apply the same existing handlers used by individual settings controls.
 settingsActions.UpdateTargetHealth()
 settingsActions.UpdateChestPins()
 settingsActions.ApplyDamageNumbers()
 settingsActions.UpdateGryphons()
 SyncNativePlates()
 ApplyCamera(false)
 if FieldKitScreenLayers then FieldKitScreenLayers.Update() end
 if FieldKitWorldMarkers and FieldKitWorldMarkers.ReloadProfileSettings then
  FieldKitWorldMarkers.ReloadProfileSettings()
 end
 if FieldKitPartySync then FieldKitPartySync.Watch() end
 if FieldKit.SyncChat then FieldKit.SyncChat() end
 if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
 -- Repaint only recoverable chat history after switching a palette.
 if FieldKit.RecolorDisplayedChat then FieldKit.RecolorDisplayedChat() end
 FieldKit_SetLanguage(DB.language)
 SetMovablesUnlocked(not DB.windowsLocked)
 if FieldKitUI and FieldKitUI.frame then FieldKitUI.Refresh() end
 return true
end

local SECTIONS=FieldKit.CreateOptionsSchema(settingsActions)
FieldKit_AddSettingsSections(SECTIONS)
SECTIONS=FieldKit.BuildJourneySections(SECTIONS,settingsActions)

-- Restore only addon HUD positions. The journey offers an immediate Undo.
local function ResetPositions()
 DB.frameAnchors={}
 for i=1,table.getn(movableFrames) do
  local f=movableFrames[i];DB.pos[f:GetName()]={f.azsDefault[1],f.azsDefault[2]};PlaceMovable(f)
 end
 if AttachMoneyToBar then AttachMoneyToBar(true) end
 if FieldKit.ResetChatLayout then FieldKit.ResetChatLayout() end
 FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight()
end
local function RefreshPanel() if panel then FieldKitUI.Refresh() end end
function FieldKit_RefreshInterfaceLanguage()
 RefreshPanel();UpdateStatsFrame();UpdateGearFrame();UpdateMeterFrames(true);FieldKitNativeTools.Update();FieldKitLoadout.Update();FieldKitScreenLayers.Update()
 UpdateBossFrame();UpdateLairFrame();UpdateMoneyFrame();FieldKitRunMode.Update();FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight()
 FieldKitCoop.Update()
 if FieldKit_UpdateWorldPins then FieldKit_UpdateWorldPins() end
end
local function CreatePanel()
 panel=FieldKitUI.Build(SECTIONS,{
  unlock=SetMovablesUnlocked,bosses=UpdateBossFrame,reset=ResetPositions,
  dismiss=function() if statsPicker then statsPicker:Hide() end end,
  positions=function()
   for i=1,table.getn(movableFrames) do PlaceMovable(movableFrames[i]) end
   AttachMoneyToBar(false);FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight()
  end,
  camera=function(v) DB.cameraMax=v;ApplyCamera(true) end,
  reload=function() ReloadUI() end,
 })
 FieldKit_RefreshLanguage(FieldKit_RefreshInterfaceLanguage)
end
local function TogglePanel()
 if not panel then CreatePanel() end
 FieldKitUI.Toggle()
end

-- Persist the movement preference without constructing/showing any settings,
-- arrangement dock or preview. Ordinary gameplay dragging uses this preference.
function FieldKit.SetWindowsLocked(locked)
 if not DB then return end
 DB.windowsLocked=locked and true or false
 if FieldKit.layoutEditing and FieldKitUI.frame then FieldKitUI.SetLayoutEditing(false,false) end
 SetMovablesUnlocked(not DB.windowsLocked)
 if FieldKitUI.frame then FieldKitUI.Refresh() end
end

-- Create the addon settings shortcut; dragging changes only its saved rim angle.
local function CreateMinimapButton()
	if ( not Minimap ) then
		return
	end

	local b = CreateFrame("Button", "FieldKitMinimapButton", Minimap)
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

	local icon = b:CreateTexture("FieldKitMinimapButtonIcon", "ARTWORK")
	icon:SetTexture(FieldKitTheme.media.."ChronicleSeal.tga")
	icon:SetAllPoints(b)
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
 b:RegisterForClicks("LeftButtonUp","RightButtonUp")
 b:SetScript("OnClick",function()
  GameTooltip:Hide()
  if arg1=="RightButton" then FieldKit.SetWindowsLocked(not DB.windowsLocked)
  else TogglePanel() end
 end)
	b:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:SetText("Azeroth FieldKit", 1.0, 1.0, 1.0)
  GameTooltip:AddLine(FieldKit_L("Left-click: settings. Right-click: lock/unlock windows. Drag: move this shortcut."),NORMAL_FONT_COLOR.r,NORMAL_FONT_COLOR.g,NORMAL_FONT_COLOR.b)
  GameTooltip:AddLine(FieldKit_L((FieldKit.layoutEditing or not DB.windowsLocked) and "Windows unlocked" or "Windows locked"),1,.85,.55)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end


-- Initialize only FieldKitDB via Config.lua, then apply the selected UI language.
local function InitDB()
	DB = FieldKit.InitializeSettings(DEFAULT_SHOWN)
 FieldKitProfiles.ActivatePending()
 FieldKit_SetLanguage(DB.language)
end

local frame = CreateFrame("Frame", "FieldKitFrame", UIParent)
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_AURAS_CHANGED")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")

-- Initialize once on VARIABLES_LOADED; never persist or restore native talent state.
local function FieldKitEventLifecycle()
 if event=="PLAYER_LOGOUT" then
  -- Persist edits to the current profile even if the user never explicitly
  -- pressed Save before quitting or /reload. Do not duplicate game data.
  if DB and FieldKitProfiles then
   if FieldKitProfiles.preview then FieldKitProfiles.CancelPreview() end
   if not FieldKitProfiles.preview then FieldKitProfiles.SaveActive() end
  end
  return
 end
	if ( event == "VARIABLES_LOADED" ) then
		if DB then return end
		InitDB()
		CreateMinimapButton()
		CreatePlayerBar()
		CreatePlayerBuffs()
		CreateBossFrames()
  if FieldKitBossTimeline and FieldKitBossTimeline.Update then FieldKitBossTimeline.Update() end
		CreateStatsFrame()
		CreateMoneyFrame()
		CreateGearFrame()
		CreateMeterFrames()
		local lairs=CreateLairFrame()
  local mode=FieldKitRunMode.Create(CreateBarWindow,FitRows)
  MakeMovable(mode,-(UIParent:GetWidth()/2-140),260,true)
  FieldKitHudStack.Initialize({mode,meterFrame,takenFrame,lairs},MakeMovable,PlaceMovable)
  FieldKitCardLayout.Initialize(MakeMovable,PlaceMovable)
  FieldKitCoop.Create(CreateBarWindow,FitRows,MakeMovable)
  FieldKitNativeTools.Create(CreateBarWindow,FitRows,MakeMovable)
  FieldKitTakenDetails.Reset();FieldKitLoadout.Update()
  FieldKitPreview.Initialize(CreateBarWindow,CreateBossFrame,PlaceMovable)
		CreateCompactBar()
  FieldKit.appliedCompactBar=DB.compactBar==true
		UpdateGryphons()
		return
	end
	if ( not DB ) then
		return
	end
end

-- Refresh visuals at world entry; native visual writes are routed through Runtime.lua.
local function FieldKitEventWorld()
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		SyncNativePlates()
		UpdatePlayerBar()
		UpdatePlayerBuffs()
		lastGold = RunGold()

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
		UpdateMeterFrames(true)
	end
end

-- Dispatch supported native/combat events; packet strings are parsed as data only.
local function FieldKitEventOther()
	if ( event == "PLAYER_TARGET_CHANGED" ) then
		Learn("target")
		UpdateTargetHealth()
		UpdateBossFrame()
	elseif ( event == "UPDATE_MOUSEOVER_UNIT" ) then
		Learn("mouseover")
	elseif ( event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_COMBAT_SELF_HITS" ) then
		FieldKitCrits.Capture(arg1)
	elseif ( event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" ) then
		UpdateCompactXP()
	elseif ( event == "PLAYER_MONEY" ) then
		NoteGoldChange()
		UpdateMoneyFrame()
	elseif ( event == "PLAYER_AURAS_CHANGED" ) then
		UpdatePlayerBuffs()
	elseif ( event == "CHAT_MSG_ADDON" ) then
  -- The official AZSRUN parser runs before addon event handlers. React now,
  -- rather than leaving an extra polling interval of compact HUD on choices.
  if arg1=="AZSRUN" then KeepCompactBar() end
  FieldKitNative.Packet(arg1)
  FieldKitPartySync.Receive(arg1,arg2,arg3,arg4)
  FieldKitCoop.Packet(arg1)
		if ( arg1 == "AZS" and arg2 ) then
			-- The official parser runs before addons; avoid parsing its payload twice.
			stats = type(AZS_STATS)=="table" and AZS_STATS or ParseStats(arg2)
			DB.lastStats = stats
			UpdateStatsFrame()
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
	if ( event == "VARIABLES_LOADED" or event=="PLAYER_LOGOUT" ) then
		FieldKitEventLifecycle()
	elseif ( not DB ) then
		return
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		FieldKitEventWorld()
	else
		FieldKitEventOther()
	end
end)

-- Poll snapshots at their documented delivery rate. Timed debuffs/animations stay
-- on the faster path. A phase change must hide stale tables even without new stats.
local function RefreshNativeData()
	if not HasAPI() then return end
	local phase=AZS_GetPhase()
	local zone=type(AZS_ZONE)=="table" and AZS_ZONE.zone
	local rt=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.t)
	if zone~=dataClock.zone or (rt and dataClock.rt and rt<dataClock.rt) or (phase=="ready" and dataClock.phase~="ready") then levelSeen={} end
	local changed=phase~=dataClock.phase
	if changed or AZS_STATS_UPDATED~=dataClock.statsStamp or AZS_STATS~=dataClock.statsSource then
		stats=type(AZS_STATS)=="table" and AZS_STATS or nil
		if phase then DB.lastStats=stats end
		UpdateStatsFrame()
		UpdateGearFrame()
	end
	dataClock.phase=phase;dataClock.zone=zone;dataClock.rt=rt
	dataClock.statsStamp=AZS_STATS_UPDATED;dataClock.statsSource=AZS_STATS
	UpdateMoneyFrame();UpdateMeterFrames();UpdateChestPins();UpdateLairFrame()
end

local plateElapsed, layoutElapsed = 0, 0
local platesFilterOn = false
frame:SetScript("OnUpdate", function()
	if ( not DB ) then
		return
	end
	local dt = arg1 or 0
 FieldKitDiagnostics.Tick(dt)
 -- Native drag release can be lost when the run-mode card is reflowed mid-drag.
 -- Poll the actual mouse button as a fail-safe; do not end a held drag.
 if type(IsMouseButtonDown)=="function" and not IsMouseButtonDown("LeftButton") then
  for i=1,table.getn(movableFrames) do
   if movableFrames[i].azsMoving then FinishMoving(movableFrames[i]) end
  end
 end
	local choosing = FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen()
	-- Yield every FieldKit HUD while native level-up/jewelry cards own the screen.
	-- Re-apply while choosing so a late Show() cannot paint over the cards.
	if FieldKitScreenLayers and FieldKitScreenLayers.ApplyChoice then
		local edge=choosing~=frame.fieldkitChoicePhase
		frame.fieldkitChoicePhase=choosing
		if choosing or edge then
			FieldKitScreenLayers.ApplyChoice()
			if edge and FieldKitBossTimeline and FieldKitBossTimeline.Update then FieldKitBossTimeline.Update() end
		end
	end
	-- Nameplate filtering is expensive in combat; skip entirely when disabled or
	-- while the native reward/level-up overlay owns the screen. Toggle edges
	-- always sync immediately so other UI alphas are restored without delay.
	local wantPlates = DB.hidePlates and not choosing
	plateElapsed = plateElapsed + dt
	if wantPlates then
		if (not platesFilterOn) or plateElapsed >= PLATE_INTERVAL then
			plateElapsed = 0
			UpdatePlates()
   FieldKitDiagnostics.Mark("plates")
		end
		platesFilterOn = true
	else
		if platesFilterOn or plateElapsed >= 1 then
			plateElapsed = 0
			UpdatePlates()
   FieldKitDiagnostics.Mark("plates")
		end
		platesFilterOn = false
	end
	if not choosing then
		FieldKitCrits.Animate()
		PulsePlayerBar()
	end
	elapsed = elapsed + dt
	dataClock.elapsed = dataClock.elapsed + dt
	layoutElapsed = layoutElapsed + dt
	if ( elapsed < SCAN_INTERVAL ) then
		return
	end
	elapsed = 0
 FieldKitDiagnostics.Mark("scan")
	KeepCompactBar()
	if not choosing then
		UpdateBossFrame()
		UpdatePlayerBuffs()
		UpdatePlayerBar()
	end
	if dataClock.elapsed>=DATA_INTERVAL then
		dataClock.elapsed=0
  FieldKitDiagnostics.Mark("snapshot")
		FieldKitNative.Watch();RefreshNativeData();FieldKitRunMode.Update();FieldKitCoop.Update()
		FieldKitNativeTools.Update()
		-- Loadout tooltip scans hitch hard; keep them off the choosing overlay path.
		if not choosing then FieldKitLoadout.Update() end
		FieldKitScreenLayers.Update()
		-- Cards may show/hide after native snapshots; restack once here, not every paint.
		layoutElapsed = 0
		if not choosing then FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight();FieldKitDiagnostics.Mark("layout") end
	elseif layoutElapsed >= LAYOUT_INTERVAL then
		-- Safety restack when no snapshot landed (collapse/options already call Apply).
		layoutElapsed = 0
		if not choosing then FieldKitHudStack.Apply();FieldKitCardLayout.ApplyRight();FieldKitDiagnostics.Mark("layout") end
	end
	if not choosing then FieldKitPartySync.Tick() end
end)

SLASH_FieldKit1 = "/fieldkit"
SlashCmdList["FieldKit"] = function(msg)
 if msg=="sync" then FieldKitPartySync.Diagnostic();return end
 if msg=="coop" then FieldKitCoop.Diagnostic();return end
	if ( not DB ) then
		return
	end
	msg = string.lower(msg or "")
 if msg=="profile" then FieldKitProfiles.Command("");return end
 if string.sub(msg,1,8)=="profile " then FieldKitProfiles.Command(string.sub(msg,9));return end
 if msg=="diag" then FieldKitDiagnostics.Command("");return end
 if string.sub(msg,1,5)=="diag " then FieldKitDiagnostics.Command(string.sub(msg,6));return end
 if msg=="native" then FieldKitNativeTools.Diagnostic();return end
 if msg=="lock" or msg=="unlock" then FieldKit.SetWindowsLocked(msg=="lock");return end
	if msg == "money" then
		AttachMoneyToBar(true)
		UpdateMoneyFrame()
		Print(FieldKit_L("Gold/chest bar restored above the action bar. Other positions unchanged."))
		return
	elseif msg == "combat" then
		if not panel then CreatePanel() end
		panel:Show()
		for i=1,table.getn(SECTIONS) do if SECTIONS[i].title=="Combat text" then FieldKitUI.Select(i) end end
		return
	elseif ( string.find(msg, "plates") ) then
		SetFilter(not DB.hidePlates)
	elseif ( string.find(msg, "unknown", 1, true) ) then
		DB.hideUnknown = not DB.hideUnknown
	elseif ( string.find(msg, "hp") ) then
		DB.targetHealth = not DB.targetHealth
		UpdateTargetHealth()
	elseif ( string.find(msg, "stats") ) then
		ToggleStatsPicker()
		return
	elseif ( string.find(msg, "chest") ) then
		if HasAPI() and not AZS_GetPhase() then Print(FieldKit_L("No active run."));return end
		Print(FieldKit_L("chests opened this run: ")..( DB.chestsOpened >= 0 and DB.chestsOpened or FieldKit_L("unknown") )
			..FieldKit_L(", next chest: ")..( ChestCost() or "?" ))
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
	Print(FieldKit_L("nameplate filter ")..( DB.hidePlates and FieldKit_L("ON") or FieldKit_L("off") )
		..FieldKit_L(", unknown monsters ")..( DB.hideUnknown and FieldKit_L("hidden") or FieldKit_L("shown") )
		..FieldKit_L(", target health ")..( DB.targetHealth and FieldKit_L("ON") or FieldKit_L("off") )
		..FieldKit_L(", plates on screen ")..shownNow.." ("..hiddenNow..FieldKit_L(" hidden, max ")..shownMax.."), "
		..learned..FieldKit_L(" monsters learned, camera ")..( FieldKit.GetCVar("cameraDistanceMaxFactor") or "?" ).."x.")
end
