# Azeroth FieldKit 0.3.2 — loadout, Difficulty multipliers and HUD polish

Changes since **0.3.0**. Maintainer accepted for publication on 2026-11-01; GitHub
prerelease maturity is retained. FieldKit remains a maintained fork of **MASH by Malk**.
Saved preferences and run data formats are unchanged.

## What's new

- **Accessories / Spells card:** one equipment window with tabs. Spells come from the
  native learned list; green bonus/upgrade lines from action tooltips; icons from a
  local Spell.dbc index. Jewelry shows compact boosts and the item name as the row
  label, left-aligned. Spell ranks use tier colors.
- **Run mode:** Difficulty-screen multipliers (HP, damage, marks, talent loot/XP)
  for the live native rank, with the full chart on hover. Not live combat meters.
- **Guardian frames:** a guardian boss frame appears only when its lair is `awake`,
  so despawned or returning guardians no longer linger after a fresh run.
- **Lairs:** next scheduled boss countdown, clearer French asleep/awake wording,
  footer inset away from decorative corners.
- **Taken details:** partial named melee/spell attribution when the combat log and
  native categories agree; incomplete coverage stays labelled.
- **Choice screens:** compact bar, XP strip and money hide during native level-up
  and chest choices, then restore FieldKit-suppressed visibility.
- **Previews:** context-free placement with optional hide/show of other UI; sample
  data never writes native gameplay tables.
- **Small polish:** idle combat-text/crit shortcuts, French meter icon aliases,
  short empty Spells label.

## Update and evidence

Download **AzerothFieldKit-0.3.2.zip** from Assets, not the Source code ZIP. Back up
and replace the existing FieldKit folder in the launched client's AddOns directory,
keep your saved preferences and restart. Disable legacy MASH if still enabled.
No external program or extra addon is required.

Static inventory and Lua **5.0.3** / **5.1** behavioral checks pass. No new
agent-performed in-game rendering, performance, affix-encoding or co-op transport
test is claimed. Ground runes, armory/star/mark progression and invented multipliers
remain out of scope. Existing credits and rights notes are retained.
