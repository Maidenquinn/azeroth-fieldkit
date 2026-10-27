# Changelog

## 0.1.0-review.3 — 2026-10-27

- Align run snapshot polling with the official API's 5 Hz delivery limit; retain
  20 Hz debuff/layout refreshes and per-frame critical/low-health animation.
- Cache unchanged static portraits using native unit stamps/table identity,
  instance/name/zone and language; preserve uncached legacy behavior.
- Use native pre-parsed stats and exact cache count `AZS_RUN.ck` when available.
- Hide retained run-owned stats, money, equipment, meters, lairs, pins and shield
  outside a run; prevent compact docking from reviving stale money text.
- Display native lair remaining seconds without wall-clock extrapolation during
  paused/choosing phases; keep native total DPS fresh without rebuilding spell rows.
- Document the supplied official API snapshot and add contract regression tests.
- Mock counters: 5 snapshot batches per 20 × 50 ms ticks; no in-game FPS claim.
- Lua 5.0.3 / 5.1 fixtures pass; maximum captured variables is 23 (<32).

## 0.1.0-review.2 — 2026-10-27

- Publish source and a prerelease for developer review at the maintainer's request.
- Update review/status documentation while retaining credits, unresolved rights
  and the explicit lack of game approval.
- Package committed validation evidence, separating it from the current CI run.
- No gameplay/UI behavior changes from review.1; version metadata updated.

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
