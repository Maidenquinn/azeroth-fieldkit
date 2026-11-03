# Changelog

## 0.4.0 — 2026-11-03 (bilingual UI, combat text profiles, 19 previews)

Changes since **0.3.4**:

- Polished dark/gold UI: navigation, selected states, tabs, controls, footer layout and scrolling; corrected Undo/Reset HUD positions overlap.
- Expanded French/English localization throughout navigation, settings, dynamic controls and combat-text simulation examples.
- Added clearer selection and independent customization for the three combat-text profiles (Balanced / Quiet / All).
- Improved simulation behavior and reduced redundant updates without altering real combat totals.
- Reworked the inspector and 19 HUD previews with representative **sample** data; repaired blank Damage/Revive/Bosses/health displays and unsupported button method calls.
- Hardened incomplete profile defaults and invalid display settings; maintained saved preferences.
- Maintainer-confirmed in-game acceptance; Lua and TOC checks performed on the packaged runtime. Previews show sample values, not live statistics.

Full release notes: [docs/RELEASE_0.4.0.md](docs/RELEASE_0.4.0.md).

## 0.3.4 — 2026-11-02 (chronicle HUD, meter suite, settings split; GitHub prerelease)

Maintainer accepted for publication. Changes since **0.3.2**:

- Tabbed combat meter (damage / healing / boss / taken / party / kills) with Reset, sort, hide, heal perspective, party drill, pet/DoT ledger hits and Max Hit–style tips; merge same ability across ranks.
- Boss schedule timeline (Chronicle rail, next-boss countdown) and redesigned boss frames (portraits, name/HP above, tags under, no overflow).
- Settings: replace mega Windows page with HUD cards / Combat meter / Layout & arrange / Look / Co-op.
- Effects drag no longer sticks during timer refresh; choice screens still yield HUD; native Show Target Damage exposed in Combat text.
- Offline Lua 5.0.3/5.1 and packaging checks pass; no new agent in-game certification claimed.

## 0.3.3-review.1 — 2026-11-01 (Show target damage toggle in Combat text)

- Expose the native Options → Combat → Show Target Damage (`CombatDamage`) switch on Combat text → General, with the same wording as the game, so FieldKit-only text is one uncheck away.

## 0.3.2 — 2026-11-01 (loadout, Difficulty multipliers and HUD polish; GitHub prerelease)

Maintainer accepted for publication. Changes since **0.3.0**:

- Integrate Accessories and Spells on one equipment card (tabs, shared size/collapse/style). Spells come only from the native learned list; bonuses/upgrades from action tooltips; icons from a local Spell.dbc index (no Azerloot copy).
- Show compact jewelry boosts, item names as row labels, left-aligned accessory text, and tier-colored spell ranks.
- Run mode shows Difficulty-screen multipliers (HP / damage / marks / talent loot·XP) for the live native rank; full chart on hover.
- Guardian boss frames require a matching awake lair, so despawned/returning guardians no longer leave frames after a fresh run.
- Lairs: next-boss countdown, clearer FR states (en attente / en combat), footer inset.
- Partial named taken details from combat log + native categories; incomplete coverage stays labelled.
- Compact bar / XP / money hide during native level-up and chest choices; restore FieldKit-suppressed visibility afterward.
- Context-free placement previews with optional hide/show of other UI; install ZIP still excludes JSON/docs.
- Idle combat-text / crit paint shortcuts; French meter icon aliases; short empty Spells label (« Aucun sort »).
- Offline Lua 5.0.3/5.1 and packaging checks pass; no new agent in-game certification claimed.

Candidate review entries below remain historical records of the path to this release.


## 0.3.2-review.9 — 2026-11-01 (left-align accessory names)

- Accessory and spell row labels are forced left-aligned; wide label boxes no longer center short slot names.

## 0.3.2-review.8 — 2026-11-01 (hide despawned guardian boss frames)

- Guardian boss frames now require a matching lair in `awake` state, so stale `AZS_UNITS` entries after despawn or a fresh run no longer keep Berserker/Champion frames on screen.

## 0.3.2-review.7 — 2026-11-01 (Difficulty UI multipliers on run mode)

- Run mode card shows the Difficulty screen multipliers (Vie / Dégâts / Marques / Butin·XP) for the live native rank, not the old qualitative 0.121 rule names.
- Empty Spells tab uses the short label « Aucun sort » instead of the truncated « Données des sorts non… ».

## 0.3.2-review.6 — 2026-11-01 (accessory boosts + meter icons + lair wording)

- Restore accessory bonuses as compact lines (`+72% chance`, `-10% dmg`) instead of dropping Equip prose.
- Add French meter icon aliases for Saccager, Rafale and Blessures profondes.
- Lair states: asleep → en attente, awake → en combat.

## 0.3.2-review.5 — 2026-11-01 (loadout / mode / lairs polish)

- Accessories show compact numeric boosts only; French prose with a bare percentage no longer fills the card.
- Equipped jewelry uses the item name as the row label (no repeated "Amulet" / slot title).
- Spell ranks use tiered colors on the Spells tab.
- Run mode lists the live Heroic reference impacts on the card (full detail still on hover).
- Lairs next-boss / HP footer inset away from decorative corners.
- Broader exact combat-log templates for named taken attribution (melee + creature spells).

## 0.3.2-review.3 — 2026-10-31 (unpublished integrated loadout correction)

- Remove the separate Spells window. Accessories/Spells tabs now share the existing
  equipment card, position, sizing, collapse state, opacity and visual style.
- Populate spells only from the native learned list; ranks no longer come from
  unlearned or unrelated spellbook entries. Read localized run bonuses and upgrade
  lines from action tooltips, including multiple paragraphs in one text region.
- Associate action textures with native spell IDs using an independently generated
  local Spell.dbc/SpellIcon.dbc base-class asset index. Reject ambiguous textures.
  Azerloot is a behavioral reference only, with no copied code/data or dependency.
- Request explicit .tga portrait files and normalize ASCII zone-key whitespace/case.
  Add regression fixtures for Jeklik, Gurubashi Berserker, rejected textures and the
  full existing portrait catalog. Keep display/identity conflict protection.
- Extend the portrait diagnostic with the raw zone key and attempted resource.
  In-game confirmation is still required; no all-map success is claimed.

## 0.3.2-review.2 — 2026-10-31 (local compact-bar fix candidate)

- Hide FieldKit's compact action bar, XP surface and docked money strip during
  native level-up/chest choices. Stop repairing hidden native action buttons in
  that phase; restore only visibility suppressed by FieldKit when play resumes.
- React to native run-phase packets as well as polling. Keep intentionally
  detached money windows and saved positions/preferences unchanged.
- Add regression fixtures for phase transitions, money events, repeated polls,
  hidden bars, missing phase API and absence of automatic action-slot changes.
- Native confirmation of the reported gray rectangle is still pending.

## 0.3.2-review.1 — 2026-10-31 (unpublished loadout candidate)

- Add a movable, collapsible Spells card with native ranks and current green
  tooltip bonus lines. Reuse the card styles, opacity, sizing and preview editor.
- Add native jewelry bonus summaries to Accessories. Keep rarity/item names and
  their native tier suffix; never infer jewelry rank from observed upgrades.
- Show learned native icons beside spell names in local/party detail meters.
  Unknown icons remain absent; no dependency on AZSSpellMeter is installed.
- Add the next scheduled boss and a separate countdown column inside Lairs.
- Add taken-category hover details for unambiguously named melee hits observed
  during this run and classified by fresh native unit/target data. Explicitly show
  incomplete coverage and unassigned totals; no guessed monster breakdown.
- Validate the readers, geometry, icons, attribution guards and run resets under
  Lua 5.0.3/5.1. Real-client visual and event coverage validation is still pending.

## 0.3.1-review.2 — 2026-10-31 (unpublished UX candidate)

- Isolate placement from the real FieldKit HUD. Add a Show/Hide other interface
  elements button (hidden initially), with temporary alpha/input masking and exact
  exit restoration. Keep UI update/event handlers and normal visibility untouched.
- Keep audit JSON, review docs and the manifest out of the install ZIP; retain
  the evidence in the repository and separate release attachments. Validate exact
  ZIP membership, allowed file types and per-file sidecar hashes.
- Add a reusable English/French example inspector for cards, boss portraits and
  debuffs, player/target HP formats, teammate cards, revive, effects and reminders.
- Test disabled modules without a party, boss, combat, or native API provider.
- Reflect card style, opacity, dimensions, meter columns and HP formats live;
  synchronize the inspector selection with Windows → Layout.
- Place a selected window with settings hidden, or compose selected examples,
  including disabled cards. Preserve grouped movement and the saved lock.
- Keep sample data out of native tables, counters, party sharing and saved gameplay
  data. Close/Escape/Done clean up examples without changing module enable flags.
- Reset a single independent window position; grouped cards request ungrouping
  first so unrelated windows are not reset.
- Player/target format examples are read-only; the live player bar remains directly
  draggable and target text remains attached to the native target frame.
- Validate isolation, no native writes, frame reuse, EN/FR, style, geometry and
  lifecycle under Lua 5.0.3 and 5.1. Actual visual/game validation remains pending.

## 0.3.0 — 2026-10-31 (native tools update; GitHub prerelease)

Maintainer accepted for publication. Changes since 0.2.3:

- Add optional contextual tracking of native totems, grouped summons and published
  talent/item timers, preserving native counts and remaining-time semantics.
- Add local Healing/HPS and Boss Damage views to the existing meter and pinned
  detail, keeping native rates and each fight's time base.
- Add passive local co-op revive progress; preserve the native revive HUD.
- Add optional native banner filters, bounded/deduplicated warnings, native boss-
  arrival alerts, stored-level reminders and flagged-lair emphasis. No attack prediction.
- Add per-window opt-in foreground above level/jewelry choices, restricted to
  owned FieldKit frames. Other modals are not guaranteed.
- Show received literal affix names when recognized; unknown encodings stay raw.
- Preserve positions, sizes, locks, collapse states, EN/FR, and disabled defaults
  for new panels/warnings. Add `/fieldkit native` diagnostics.
- Full offline Lua 5.0.3/5.1 and CI checks pass; an additional extracted-API harness
  used synthetic messages. Live rendering and real affix encoding remain to verify.

Historical candidate entries below describe their state when written.


## 0.3.0-review.1 — 2026-10-31 (unreleased native-tools candidate)

- Add opt-in passive Effects, Revive and Run reminders cards, reusing existing
  theme, dragging, lock, independent sizes, collapse and language controls.
- Track native totem counts/caps/soonest expiry, permanent/temporary summons and
  published talent/item cooldowns. Reject retained snapshots across run boundaries.
- Add local Healing/HPS and Boss Damage views to the existing meter and pinned
  details, preserving native rate time bases and honest unsupported states.
- Add bounded/deduplicated native boss/mechanic warnings and one configurable
  arrival warning per observed boss schedule; no attack prediction or native HUD hiding.
- Add optional stored-level count and native flagged-lair emphasis. No level spending.
- Read native affix names only when supplied; unrecognized numeric/string formats
  remain explicitly raw. No invented weekly rotation or bitmask interpretation.
- Add individually opted-in overlays above level/jewelry choices through the new
  native API, allowlisted to FieldKit frames. No guarantee for death/other modals.
- Add guarded older-client fallbacks, local `/fieldkit native` diagnostics and
  EN/FR help. New panels/warnings start off; existing preferences are retained.
- Offline Lua 5.0.3/5.1 behavioral fixtures cover data fidelity, old APIs, run resets,
  packet ordering, bounds, overlays, persistence and navigation. Live rendering,
  co-op delivery and the real affix encoding still require game testing.


## 0.2.3 — 2026-10-28 (published update; GitHub prerelease)

Maintainer accepted for publication. Consolidates the layout, co-op and UX work
since 0.2.1-review.3; original candidate entries below remain historical records.

- Move active HUD windows directly without opening settings; persist an optional
  global lock, independent/grouped anchors, collapse state and per-card dimensions.
- Add fixed damage/DPS/share columns and native co-op totals; fill missing damage-
  taken source coverage with an explicit unattributed native remainder.
- Add optional passive teammate cards while retaining native interactions by default;
  native-frame hiding now requires a separate explicit option.
- Browse and pin spell detail from solo/group meters; preserve pinned player identity
  through rank changes. Local native detail is complete within documented bounds;
  native allied detail remains limited to the exposed top spell.
- Add optional in-game spell-snapshot sharing with bounded PARTY-only messages,
  observed status and local diagnostics. Disabled by default; live transport unconfirmed.
- Split Windows into Display, Layout, Appearance and Co-op / test; add reversible
  Essential HUD, clear preview arrangement, dimension minima and compact mode context.
- Keep HUD style/opacity separate from settings; preserve EN/FR and rewrite guides.
- Lua 5.0.3/5.1 behavioral/prototype checks pass. No new agent in-game or performance
  test is claimed. See docs/RELEASE_0.2.3.md for update instructions and remaining limits.


## 0.2.3-review.1 — UX simplification candidate (unmerged)

- Split Windows into Display, Layout, Appearance and Co-op / test with saved routing.
- Clarify direct dragging versus preview arrangement, in English and French.
- Keep native teammate interactions by default; make passive-frame replacement explicit.
- Separate experimental sharing and show observed receive/availability status.
- Compact mode rank/zone; hide unknown mode by default, keep versioned rules on hover.
- Expose dimension minima, add an optional reversible Essential HUD visibility preset.
- Allow solo spell details and pin a player's breakdown through pointer/rank changes.
- Replace positional option bindings with stable ids; rewrite both getting-started guides.
- Add Lua 5.0/5.1 regression coverage. Pending in-game acceptance; no new release.


## 0.2.2-review.6 — 2026-10-28 (normal gameplay dragging)

- Correct the movement model: active HUD windows drag directly during play by
  default, without settings, dock, previews or a prior unlock command.
- Add Windows → Lock window positions, saved as windowsLocked=false by default.
  Slash/minimap shortcuts change this preference without constructing settings.
- Keep explicit arrangement for previews/areas; finishing it restores the saved
  preference. Remove the no-longer-needed external arrangement navigation state.
- Preserve groups, independent anchors, dimensions, collapse and hover controls.
  Close hover details when actually dragging so they do not obstruct placement.
- Verify default no-panel dragging, option/shortcut locks, active drag stops and
  saved locked preference on reload under Lua 5.0.3/5.1.

## 0.2.2-review.5 — 2026-10-28 (global window lock)

- Add `/fieldkit unlock` and `/fieldkit lock` without opening settings.
- Right-click the FieldKit minimap shortcut to toggle the global HUD edit state;
  left-click still opens settings and dragging still moves the shortcut itself.
- External placement's Done/Escape locks without reopening settings. Explicit
  settings/sizing actions retain their normal navigation.
- Locking finishes and saves active owned-frame/group and combat-area drags.
  Grouping, individual dimensions and positions remain intact. Reload starts locked.
- Exercise real command/click callbacks and in-progress drag handling under
  Lua 5.0.3/5.1. No new network or gameplay capability is introduced.

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
