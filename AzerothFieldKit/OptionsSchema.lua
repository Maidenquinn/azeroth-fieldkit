-- Declarative options only: each descriptor defines a getter and a user-action
-- setter. No setting is applied while this schema is built. The HUD injects the
-- actions instead of exposing its local functions as global names.
function FieldKit.CreateOptionsSchema(actions)
local SECTIONS = {
	{
		title = "Nameplates",
		items = {
			{
				kind = "check",
				label = "Show only elites and bosses",
				tip = "Common monsters get no nameplate. The V key shows or hides the elite and boss plates.",
				get = function() return FieldKitDB.hidePlates end,
				set = function(v) actions.SetFilter(v) end,
			},
			{
				kind = "check",
				label = "Hide unclassified monsters",
				tip = "Monsters FieldKit has not learned yet are hidden too. They are learned when you target or mouse over them.",
				get = function() return FieldKitDB.hideUnknown end,
				set = function(v) FieldKitDB.hideUnknown = v end,
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
				get = function() return FieldKitDB.targetHealth end,
				set = function(v) FieldKitDB.targetHealth = v; actions.UpdateTargetHealth() end,
			},

		},
	},
	{
		title = "Combat",
		items = {
			{
				kind = "check",
				label = "Replace the game's boss bars",
				tip = "Hides the big boss bars of the HUD and shows bosses and awake guardians in target-style frames instead. Use Move windows to position them.",
				get = function() return FieldKitDB.bossFrame end,
				set = function(v) FieldKitDB.bossFrame = v; actions.SyncHudBosses(); actions.UpdateBossFrame() end,
			},
			{
				kind = "check",
				label = "Hide damage numbers",
				tip = "Hides the damage numbers that pop over monsters (yours and your pet's).",
				get = function() return FieldKitDB.hideDamage end,
				set = function(v) FieldKitDB.hideDamage = v; actions.ApplyDamageNumbers() end,
			},
			{
				kind = "check",
				label = "Show my crits above the hero",
				tip = "Your critical hits pop up above your character. Pair it with Hide damage numbers to see only crits.",
				get = function() return FieldKitDB.showCrits end,
				set = function(v) FieldKitDB.showCrits = v end,
			},
			{
				kind = "check",
				label = "Group crits",
				tip = "Crits that land within a quarter second become one line: the biggest, with how many there were (x7).",
				get = function() return FieldKitDB.groupCrits end,
				set = function(v) FieldKitDB.groupCrits = v end,
			},
		},
	},
	{
		title = "Player",
		items = {
			{
				kind = "check",
				label = "Health bar under the character",
				tip = "A small green bar under your hero. Use Move windows to position it.",
				get = function() return FieldKitDB.playerBar end,
				set = function(v) FieldKitDB.playerBar = v; actions.UpdatePlayerBar() end,
			},

			{
				kind = "check",
				label = "Buff icons under the health bar",
				tip = "Your active buffs with their time left.",
				get = function() return FieldKitDB.playerBuffs end,
				set = function(v) FieldKitDB.playerBuffs = v; actions.UpdatePlayerBuffs() end,
			},
			{
				kind = "check",
				label = "Shield on the health bar",
				tip = "Your absorb shield shows as a light blue band over the health bar, with its value in numbers.",
				get = function() return FieldKitDB.playerShield end,
				set = function(v) FieldKitDB.playerShield = v; actions.UpdatePlayerBar() end,
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
				get = function() return FieldKitDB.lowHealth end,
				set = function(v) FieldKitDB.lowHealth = v; actions.UpdatePlayerBar() end,
				button = { text = "Test", onClick = function() actions.TestLowHealth() end },
			},
			{
				kind = "check",
				label = "Sound on low health",
				tip = "Plays a warning sound once each time your health drops below the limit.",
				get = function() return FieldKitDB.lowHealthSound end,
				set = function(v) FieldKitDB.lowHealthSound = v end,
			},
			{
				kind = "slider",
				label = "Low health limit",
				tip = "Below this much health the warning starts.",
				min = 10, max = 70, step = 5,
				format = function(v) return FieldKit_L("Low health below ")..v.."%" end,
				get = function() return FieldKitDB.lowHealthPct end,
				set = function(v) FieldKitDB.lowHealthPct = v; actions.UpdatePlayerBar() end,
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
				get = function() return FieldKitDB.statsFrame end,
				set = function(v) FieldKitDB.statsFrame = v; actions.UpdateStatsFrame() end,
				button = { text = "Choose...", onClick = function() actions.ToggleStatsPicker() end },
			},
			{
				kind = "check",
				label = "Kills under the gold",
				tip = "Shows your kills below the gold and chest price, and hides the game's Kills / Gold / cache box.",
				get = function() return FieldKitDB.replaceTally end,
				set = function(v) FieldKitDB.replaceTally = v; actions.SyncHudTally(); actions.UpdateMoneyFrame() end,
			},
			{
				kind = "check",
				label = "Damage meter",
				tip = "Damage, DPS and share of each spell this run. The game's own meter stays as it is.",
				get = function() return FieldKitDB.meterFrame end,
				set = function(v) FieldKitDB.meterFrame = v; actions.UpdateMeterFrames(true) end,
			},
			{
				kind = "check",
				label = "Damage taken",
				tip = "Where the damage you took came from: bosses, elites, monsters or ground effects.",
				get = function() return FieldKitDB.takenFrame end,
				set = function(v) FieldKitDB.takenFrame = v; actions.UpdateMeterFrames(true) end,
			},
			{
				kind = "check",
				label = "Accessories",
				tip = "Your amulet, trinkets and rings with rarity colors. Empty slots show in red.",
				get = function() return FieldKitDB.gearFrame end,
				set = function(v) FieldKitDB.gearFrame = v; actions.UpdateGearFrame() end,
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
				get = function() return FieldKitDB.chestPins end,
				set = function(v) FieldKitDB.chestPins = v; actions.UpdateChestPins() end,
			},
			{
				kind = "check",
				label = "Lairs",
				tip = "A window with every guardian lair: who holds it, asleep or awake, when an empty one fills again, and how far it is.",
				get = function() return FieldKitDB.lairFrame end,
				set = function(v) FieldKitDB.lairFrame = v; actions.UpdateLairFrame() end,
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
				get = function() return FieldKitDB.compactBar end,
				set = function(v) FieldKitDB.compactBar = v end,
			},
			{
				kind = "check",
				label = "Hide gryphons",
				tip = "Hides the two gryphons at the ends of the action bar.",
				get = function() return FieldKitDB.hideGryphons end,
				set = function(v) FieldKitDB.hideGryphons = v; actions.UpdateGryphons() end,
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


 return SECTIONS
end
