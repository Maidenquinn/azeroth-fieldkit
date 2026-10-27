-- Same actual Lua modules and behavioral fixtures, with no modern string API.
dofile("tests/mock.lua")
string.match=nil;string.gmatch=nil
local files={"Runtime.lua","Config.lua","Localization.lua","Seed.lua","PortraitCatalog.lua","Portraits.lua","Settings.lua","OptionsSchema.lua","LegacyCrits.lua","FieldKit.lua","WorldPins.lua","CombatText.lua","CombatOptions.lua","CopyLog.lua"}
for i=1,table.getn(files) do dofile("AzerothFieldKit/"..files[i]) end
fire(FieldKitFrame,"VARIABLES_LOADED")
dofile("tests/security.lua")
-- Official API scheduling, stale-table, pause/countdown and portrait-cache contracts.
dofile("tests/mock.lua")
for i=1,table.getn(files) do dofile("AzerothFieldKit/"..files[i]) end
dofile("tests/official_api.lua")
-- Exercise user-driven native slot changes in an independent mock initialization.
dofile("tests/mock.lua")
for i=1,table.getn(files) do dofile("AzerothFieldKit/"..files[i]) end
dofile("tests/action_effects.lua")
-- Re-execute the mock and addon, separating the privacy fixture from UI scenarios.
dofile("tests/mock.lua")
for i=1,table.getn(files) do dofile("AzerothFieldKit/"..files[i]) end
FieldKitDB={compactBar=true,bossFrame=true,hidePlates=true,replaceTally=true,chestPins=true,guardianPins=true,moneyDetached=true,pos={FieldKitMoneyFrame={-2.5374755859375,-348.0493927001953}}}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
for _,name in ipairs({"test_money.lua","tests.lua","test_worldpins.lua","test_combat_editor.lua","test_localization.lua"}) do dofile("tests/"..name) end
print("Native Lua 5.0 behavioral, privacy, malformed-settings, portrait, combat and UI checks passed")
