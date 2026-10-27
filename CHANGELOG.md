# Changelog

## 0.1.0-review.1 — 2026-10-27

First separately named review candidate, based on the inspected MASH 1.3.9.

- Rename folder, TOC, commands and addon-owned globals to Azeroth FieldKit /
  FieldKit. Keep Malk's attribution and mark upstream permissions unresolved.
- Separate Runtime.lua, Config.lua, OptionsSchema.lua and LegacyCrits.lua from
  HUD/controller responsibilities; document functions and data flow in English.
- Remove native talent-toggle save/restore and related lifecycle hooks.
- Make local chat copy explicit opt-in; bound to 100 messages × 512 bytes from
  the main frame only, clear on disable, retain nothing in SavedVariables.
  Remove the chat-copy hover buttons and unconditional hook installation.
- Allowlist native CVar writes; guard missing CVars and restrict HUD section names.
- Normalize malformed stored settings and finite numbers. Bound parsed stats to
  16 KiB, combat text to 4 KiB, pending groups to 64 and learned names to 2,048.
- Compute lair distance directly from native world coordinates. Remove obsolete
  map calibration, map-selection writes and unused zoom constants.
- Disable intrusive/approval-sensitive options on a fresh configuration; preserve
  the capabilities behind explicit settings. Native damage settings and camera
  are untouched until configured.
- Stop writing WorldFrame alpha when the plate filter is disabled. Restore the
  saved alpha and original parent/scale for frames lifted by the filter.
- Remove redundant ShowNameplates forwarding, obsolete legacy tab-index migration
  and the inherited branding icon. No old rune probes/helpers are included.
- Preserve health formatting, bilingual editor, bounded combat renderer, native
  portraits, collapsible windows, money strip, equipment and minimap toggles.
- Add behavioral/privacy/malformed-setting regression tests, a native Lua 5.0.3
  runner, nested-prototype checks, static capability inventory and reproducible ZIP.
- Add an approval dossier, API side-effect inventory, threat model, contributor
  guide, release checklist and explicit attribution/rights blockers.

No new in-game validation, manual game-developer approval or public-release
authorization is claimed. MASH and other installed addons remain untouched.
