# Changelog

## 0.2.1-review.2 — 2026-10-27

- Add an optional Run mode HUD card: native rank and zone, explicitly labelled cumulative 0.121 mechanic references, full rules on hover and unknown live affix identity. No guessed HP/damage multipliers.
- Align run mode, damage, damage taken and lairs into one left HUD stack by default: common width, left/right edges and six-pixel spacing, with no holes after collapse/hiding.
- Move the stack through any member in Move windows mode. Preserve legacy individual positions; the Windows alignment checkbox restores the unlinked layout.
- Give the stack its own persisted top-left anchor, migrated once from the old damage window and clamped into the viewport when the cards fit. Reuse unchanged anchors.
- Restore cached meter rows immediately after expansion, without waiting for new damage.
- Validate stack geometry, drag forwarding, hide/collapse, width changes, unlinking, native rank changes and reference/unknown semantics in Lua 5.0.3 and 5.1. Live visual acceptance pending.

## 0.2.1-review.1 — 2026-10-27

- Read the native AZS_ZONE.heroic field and display Normal / Heroic I–V in settings context, only during a run. Never infer a Heroic rank from zone difficulty or old Run Options.
- Preserve tenths in stat bonuses, including +0.3%, and fractional kill-heal values supplied by the native stats.
- Preserve Explosive Orb / Orbe explosif nameplates under the ordinary-mob filter; the player’s V-key state still applies. No targeting or combat action is automated.
- Validate simultaneous final/companion boss frames, fractional bonuses, old/missing Heroic fields and critical-objective filtering in Lua 5.0.3 / 5.1 fixtures.
- Document installed-client evidence and remaining API gaps for marks, stars, set progress and active affixes. No simulated progression or doubled Heroic modifiers.

## 0.2.0-review.3 — 2026-10-27

- Fix HUD style/opacity leaking into the settings window, menus, Overview cards and layout dock. Only explicitly marked in-game HUD surfaces use these preferences.
- Replace the concatenated damage/DPS/share string with three fixed-width, right-aligned numeric columns. Ability names have a separate bounded rectangle.
- Preserve the meter’s saved left edge when switching display width; initialize its width before restoring positions to avoid reload drift.
- Add regressions for 0% HUD opacity with opaque settings, column geometry across orders of magnitude, mode visibility and saved left-edge stability.

## 0.2.0-review.2 — 2026-10-27

- Show exact native cumulative damage per ability alongside DPS and contribution by default. Keep selectable DPS/share and damage/DPS modes; widen only the damage meter as needed.
- Add Decorative / Classic cards and a 0–100% background-opacity slider in Windows. Changes apply immediately to owned panels; labels, icons and borders retain their opacity.
- Reuse existing material slices for classic one-pixel borders; appearance changes allocate no new frames or textures.
- Verify native totals, unknown-value display, all meter modes, skin switching, zero opacity and persistence under Lua 5.0.3 / 5.1. In-game acceptance pending.

## 0.2.0-review.1 — 2026-10-27

- Rebuild settings around nine task-oriented pages, with an Overview and direct configuration cards.
- Adopt the maintainer’s Azeroth Stats material, glyph and OFL font family; no Stats dependency.
- Use a single exclusive HP-format selector per unit and keep all existing preferences.
- Introduce explicit Move windows / Done mode, HUD position reset with Undo, and a separate gold/chest strip toggle.
- Stage compact-bar changes until an explicit Reload UI click; opening settings no longer unlocks HUD dragging or displays a fake boss.
- Reflow and scroll pages at 800×600; bound choice menus to seven visible entries.
- Consolidate native damage/critical options into the combat editor’s Game text page.
- Add UI migration, interaction/resize fixtures and exact theme-asset inventory.
- Offline Lua 5.0.3/5.1 validation; in-game acceptance and developer approval pending.

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
