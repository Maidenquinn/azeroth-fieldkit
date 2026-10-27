MASH 1.3.9 — Malk Azeroth Survivor Helper
English / Français — standalone in-game addon for Azeroth Survivors

INSTALL / UPDATE
Place the MASH folder in Interface/AddOns (or the launcher's mapped AddOns
directory), replacing the previous MASH folder. Keep the folder name MASH.
Reload the UI or restart the game after updating the TOC. Saved preferences
are retained. No MSBT installation, companion program or external service.

LANGUAGE
/mash > Interface > English / Français. The switch takes effect immediately
and is saved. English is the default. It changes MASH-owned text, not native
spell names, item names, creature names or messages from the game / other addons.

COMBAT TEXT
/mashcombat opens the single combat editor:
- General: enable, merging window, lifetime, total visible limit, presets.
- Events: select a category; enable it, change RGB colors and category size.
- Fonts: normal/critical font and size, outline, opacity, names and hit counts.
- Filters: outgoing, incoming, healing, minimum amounts and ignored abilities.
  Enter exact game-provided ability names, one per line, then Apply list.
- Areas: split incoming/healing from outgoing, scroll direction, drag handles,
  spacing and numeric horizontal/vertical offsets for each area.
Balanced is a starting preset; Quiet hides healing and small hits. Presets keep
fonts, colors and positions. Preview is explicitly marked sample data.
Use only this combat text enables MASH scrolling text and hides the native
damage numbers and legacy critical display. Restore those options in Combat.
The old Text layout tab is removed; its saved settings are retained here.

OTHER FEATURES
Boss portraits use independent static native renders. The verified catalog
covers 12 maps; see PORTRAITS.txt for identity / source evidence and limitations.
Map contains independent toggles for chests and guardian lairs on the minimap.
Guardian pins mark lair positions, not moving creatures. Edge pins indicate
direction beyond the map range. No ground-rune tracking is included: the client
has no identified in-game Lua coordinate provider for ground runes.
Player, Target and Boss health support values, percentage or both.
Meter, taken, lair, equipment and stats windows retain their collapse options.
The gold / chest-price / kills strip remains above the compact action bar.

COMMANDS
/mash             configuration
/mashcombat       combat editor
/mash money       restore the gold/chest strip above the action bar
/mash stats       choose displayed stats
/mash chests      chest count and next price
/mash status      nameplate / target / camera diagnostics
/mashportrait coverage  portrait catalog coverage
/mashportrait     current portrait source diagnostic
/mashlog          copy captured chat; /mashlog clear clears MASH's chat history

VALIDATION BEFORE PUBLIC RELEASE
Automated mock-client tests cover loading, all tabs, EN/FR switches, saved
preferences / reload, combat categories and filters, numeric area editing,
money strip, health formats, collapsible windows, minimap and portraits.
Lua 5.1 syntax/prototype checks with string.match/gmatch unavailable pass;
maximum captured variables: 24 (legacy limit: 32). This is NOT a test in the
game's native Lua runtime. No new in-game test is claimed for this version.
1. Reload; switch English / Français, reopen /mash, then reload again.
2. Check long French labels, dropdown visibility and all tabs on your resolution.
3. Preview event colors, fonts and both areas; adjust X/Y and drag both handles.
4. Fight with healing / damage filters and ability exclusions enabled/disabled.
5. Check gold/chest strip, collapse states, health formats and minimap toggles.
6. Change target / clear it while observing a boss portrait; test other maps.

FRANÇAIS
Le guide détaillé en français est dans GUIDE-COMBAT.txt. Choisir la langue dans
/mash > Interface. Les paramètres restent conservés. Toute la configuration du
texte de combat est réunie dans un seul onglet. Les noms fournis par le jeu
restent dans sa langue, y compris dans la liste des compétences à masquer.

DESIGN REFERENCE
MikScrollingBattleText configuration concepts (categories, styling, merging).
Independent legacy-Lua implementation; no MSBT code/assets/fonts distributed.
https://www.curseforge.com/wow/addons/mik-scrolling-battle-text
Minimap API investigation reference: https://github.com/cadoky/LuckyOdds
See WorldPins.lua and PORTRAITS.txt for source / native data details.
