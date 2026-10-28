# Changelog

## 0.2.2-review.4 — 2026-10-28 (experimental party-sharing candidate)

- Apply the selected Classic/Decorative HUD style and opacity to hover cards,
  including their paging controls. Settings opacity remains separate.
- Add off-by-default, request-driven PARTY spell snapshot sharing, explicitly
  authorized by the maintainer. Both peers need FieldKit and must opt in.
- Full received peer snapshots render real per-spell damage, DPS and share;
  native-only fallback shows only the known top-spell DPS, without empty columns.
- Centralize the sole send capability in Runtime.lua: fixed prefix/channel,
  printable 230-byte packets, four calls/second. No visible chat fallback.
- Bound and validate requests, nonces, roster membership, fragments, source/byte
  counts, numeric values, caches, timers and opt-out/run invalidation.
- Add `/fieldkit sync` diagnostics. Accepted API calls are not delivery evidence.
- Verify isolated Lua-client round trips, fragmentation, exact damage, malformed
  packets, opt-in and theme behavior. Real co-op forwarding remains unconfirmed;
  the candidate does not replace the current public release.

## 0.2.2-review.3 — 2026-10-28 (local hover-detail candidate)

- Add a reusable themed detail card when hovering a player's group-meter row.
  It stays open when crossing onto it; wheel or arrow buttons browse the list.
- Show every available local spell source (bounded to 512, explicit partial label
  beyond that) in damage/DPS/share columns with a ten-row reusable pool.
- For allies, show only their native best spell/top DPS with an explicit full-list
  limitation. Unknown spell damage/share remain unknown; own spells are never
  assigned to a peer and no DPS-to-damage estimate is used.
- Keep popup materials opaque, choose the side with room and use native screen
  clamping. Close on exit/collapse/run loss/layout, with Escape and close button.
- Test provenance, pagination, row-rank changes, hover lifetime, missing fields,
  bounded allocation and Lua 5.0.3/5.1 compatibility. Live visual acceptance pending.

## 0.2.2-review.2 — 2026-10-28 (local co-op candidate)

- Read the native run damage-taken total when the source list is empty/incomplete;
  label its remainder Unattributed (native total). Missing data is not shown as 0.
- Remove source-stamp-only caching, so changes to AZS_RUN.taken appear immediately
  at the normal 5 Hz snapshot cadence. Reject previous-run source buckets.
- Add a separate native group damage/DPS/contribution meter, including the player.
  Show the received-player count; reject duplicate, departed and stale-run rows.
  Peer spell breakdowns, healing and damage taken are not fabricated.
- Add opt-in teammate cards for party1–party4: native health/resource/status and
  party-meter damage/DPS. Each card moves, collapses and resizes independently.
- Preserve native party-frame OnShow handlers and restore them when replacements
  are disabled or unavailable. No native targeting/casting action is introduced.
- Add EN/FR options, explicit layout previews and `/fieldkit coop` diagnostics.
- Inspect the installed 0.123.0 client's embedded API read-only; record its hash
  and data contracts. Native Lua 5.0.3/5.1 fixtures pass; real co-op acceptance pending.

## 0.2.2-review.1 — 2026-10-28 (local test candidate)

- Truly independent damage-taken, accessories and statistics movement when their
  left/right group is disabled; native data refreshes no longer reattach them.
- Add left/right grouping switches and an Adjust sizes shortcut to layout mode.
- Add per-card width/height preferences for run mode, damage, damage taken, lairs,
  accessories, statistics and the money strip. Preserve automatic sizing as the default.
- Retain per-card positions and sizes when grouping; right-side full-group native
  clamping uses a mouse-disabled proxy, just like the left stack.
- Keep text/icon sizes unchanged; heights cannot crop visible data rows. Larger
  cards increase row spacing up to 32 pixels, then retain empty background space.
- Normalise persisted dimensions and test real UI callbacks, collapse, group routing,
  native anchor retention and reload under Lua 5.0.3/5.1. Live validation pending.


## Publication documentation — 2026-10-28 (no runtime change)

- Record maintainer-reported game-team permission to post as a verified addon.
- Update EN/FR getting-started and approval status; retain Malk's credits and
  separate unresolved rights from publication permission.
- Prepare a Discord announcement, exact package identity and player-support guide.
- Keep 0.2.1-review.3, its ZIP, tag, checksum and prerelease label unchanged.
  Historical validation reports are not rewritten as certification evidence.

## 0.2.1-review.3 — 2026-10-28

- Fix post-drag repositioning by saving/restoring native GetPoint anchors instead of subtracting GetCenter coordinates and immediately applying a second center clamp.
- Remove the linked stack’s hardcoded 12-pixel screen inset. Clamp a full-size group proxy natively, with linked child clamps disabled.
- Keep the transparent proxy mouse-disabled so it cannot cover card controls. Preserve edge anchors and avoid forced reanchoring every tick.
- Persist validated frameAnchors separately from legacy numeric positions; Reset/Undo covers both. The compact bar no longer enforces a two-pixel bottom gap.
- Check all four edge anchors, no-GetCenter drop handling, native right pinning after resizing, serialization/reload, proxy bounds and Undo under Lua 5.0.3 / 5.1. Live confirmation pending.

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
