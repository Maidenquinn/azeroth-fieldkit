# Changelog

## 0.6.0-alpha.13 - 2026-11-07 (in-card tabs, bounded lists, unpublished)

- Equipment card: real in-card Equipment / Spells tabs (flat gold-underline tabs, same card, no reader, no reload). Spells keep icon, rank and the native tooltip; the "Spells ->" button of alpha.12 is removed.
- Cards with fixed art no longer overflow: Effects, Lairs and Spells show a scrolling window (mouse wheel) with a "from-to / total" pager and tighter row geometry; a shared Row reset prevents leftover fonts/tints.
- Effects: each buff shows icon, name, stacks and time; native buff tooltip on hover, right-click cancels the buff. The client BuffFrame / TemporaryEnchantFrame is masked reversibly (existing Mask/Save/Restore) only while the card lists buffs, and restored when the card is hidden, the layout changes or the theme is off.
- Lairs: up to four guardians are always listed (no "+N" placeholder); raw status squares replaced by tinted state text (awake, asleep, waiting, empty) with delay and distance.

## 0.6.0-alpha.12 - 2026-11-07 (restored spells, effects and lair detail, unpublished)

- Equipment card: direct "Spells" access opens the native reader on its Spells tab (ranks, stats and tooltips unchanged).
- Effects: new source "Track active buffs" (default on) lists the player's real client buffs with name, icon, stacks and time left beside totems/summons/timers; the card shows real rows, with a counted overflow, and an exact empty state.
- Lairs card lists guardians in native order with state or return delay and distance; overflow is counted, the full reader stays one click away.

## 0.6.0-alpha.11 - 2026-11-07 (target auras restored, unpublished)

- The themed target hid the native frame without replacing its auras. It now shows the real native debuffs (dispel-colored border) and buffs as icon rows under the card, with stack counts and native aura tooltips on hover; the cast bar sits below them. Hidden while the selected boss card already shows the target.

## 0.6.0-alpha.10 - 2026-11-07 (target and detail readers, unpublished)

- Refine target padding and typography, use green health for friendly/self targets and retain native clicks. Hover uses a unit tooltip without a duplicate target frame.
- Detail-reader headers drag independently of the combat HUD lock; positions persist per theme/layout/profile.
- Localize damage-taken source labels while preserving native keys.

## 0.6.0-alpha.9 - 2026-11-07 (card surfaces and minimap bounds, unpublished)

- Replace opaque footer/socket patches and meter wash with an unchanged decoration-free crop of each approved theme material. Preserve authored rims.
- Use flat meter tabs with a single selected underline, without miniature ornate button frames.
- Inset Elwynn Complete terrain inside its header/footer.

## 0.6.0-alpha.8 — 2026-11-07 (empty meter and measured sockets, unpublished)

- Cover illustrative meter sockets/tracks and the baked first-tab rim with owned textured material. Only real entries receive live icons and gauges; all six tabs share the same surface.
- Elwynn Complete native actions use measured 83-pixel socket spacing and 66-pixel interiors at y=795, replacing the previous 80-pixel step.

## 0.6.0-alpha.7 — 2026-11-07 (native cache and endless corrections, unpublished)

- Accept native endless boss countdowns without a disclosed name; no inferred schedule.
- Fixed-size equipment typography, clean sampled footer/effect patches, bounded tab labels, native IconTexture bounds and explicit fraction range refresh.
- Localized kill labels and omit unavailable rates rather than printing an unknown per-second value. Native boss DPS retains the encounter time base.
- Rebuild native minimap cached geometry when its artwork owner moves; own launcher proxies preserve original click handlers without circular repositioning scripts.

## 0.6.0-alpha.6 — 2026-11-07 (complete HUD corrections, unpublished)

- Restore authored panel backgrounds and bottom rims; restrict empty-effect cleanup to its unused socket. Match heading/total colors and fonts, highlight active meter tabs and restore footer arrows.
- Widen the Elwynn Complete banner and next-boss field; show equipped item names in place of slot labels.
- Route minimap dragging to its complete artwork group and pause competing addon launcher update scripts while themed; restore them on exit.
- Add collapse buttons to the five summary cards, sharing the original settings and bottom-right restoration dock.

## 0.6.0-alpha.5 — 2026-11-07 (visual feedback, unpublished)

- Remove side selection stripes and decorative header fragments behind text; use readable serif headings and sans-serif data rows.
- Clear obsolete panel sockets/markers, simplify chat without duplicate speech bubbles, inset native action icons, fill the Elwynn square map and restore known addon launchers beside it.
- Keep summary panels when opening details, enlarge detailed statistics rows and give tracked bosses an opaque themed frame.
- Native Elwynn Complete inspected after reload; final small alignment changes require reload. Other layouts covered by Lua regressions, not a fresh six-scene acceptance.

## 0.6.0-alpha.4 — 2026-11-07 (layout audit, unpublished)

- Per-element sizes (50–130%) scoped to zone, composition and HUD profile; integral art groups resize together. Map zoom and detached XP labels follow their component.
- Fit final live text to its frame, preserve full names on hover/readers, separate effects columns and damage totals, and align Naxx statistics above their footer.
- Mechanically exclude adjacent panels from action-bar texture crops, preventing orphan panel fragments after resizing.
- Stress fixtures cover all six renderers with long localized names, large values, profile roundtrips and bounded allocations.
- Keep reference geometry stable between updates; restore native action visibility after Rejouer and prevent leftover navigation labels after variant switches. Native evidence: docs/native-ui-smoke-0.6.0-alpha4.json.

## 0.6.0-alpha.3 — 2026-11-07 (local visual pilot, unpublished)

- Rebuild all six Elwynn/Naxxramas layouts from the approved reference compositions: independently tiled empty artwork, native seven action buttons, real square minimap, live HP/resource/XP and counters.
- Apply the matching complete window shell and materials to FieldKit settings and secondary readers; add three concept previews and HUD scale/opacity controls.
- Preserve full data through existing detail readers, pinned hover panels, native menus, player buffs and stored level choices. Avoid a second compact target panel when the selected target is the already displayed boss.
- Fix choice-to-theme opacity capture, child frame levels, duplicate native action borders, map controls, menu clipping, long timer/counter labels and destructive repeated chat font setters.
- Keep the old HUD and all native ownership recoverable; use separate reference-layout position keys. No gameplay data or stable checkout changed.
- Native client 0.142.0 exercised in real Elwynn combat (Lardeur and chest) and Naxxramas combat/choices, with all six layouts inspected. Naxx boss/coop and numerical pixel fidelity are not certified. See docs/native-ui-smoke-0.6.0-alpha3.json.

## 0.5.0-rc.1 — 2026-11-06 (release candidate, not published)

- Three independent, named HUD profiles with immediate switching, preview, undo, and quick access from Home and the header.
- Preserve individual HUD layout and display preferences, including combat text, chat appearance, world markers, and native window collapse states.
- Add a movable bottom-right dock for collapsed windows; its position persists per profile after `/reload`.
- Improve FR/EN labels and live language refresh for the new profile and dock controls.
- Harden profile persistence: stage and validate snapshots before applying; roll back failed switches; preserve damaged slots for recovery rather than silently deleting or overwriting them.
- Expand automated profile, UI, serialization, rollback, and packaging regression checks; CI #659 passed for the candidate.
- In-game acceptance reported for RC.1. Migration using a real v0.4.2 SavedVariables file and distribution permissions remain publication gates.

## 0.5.0-alpha.12 — 2026-11-06 (active profile visual polish, unpublished)

- Clearly mark the currently active named profile with a persistent **gold border and subtle bronze background** in the top-right PROF selector and in its manager card.
- Retain the small localized active indicator on the manager card; inactive profile cards have no gold selection border.
- Set the header button's persistent selected state explicitly, preventing mouse-leave hover transitions from removing its active look.
- Replace the plain green Home status text with a compact, themed status strip labeled "In use: <name>" / "En cours : <nom>" under Quick profiles.
- The active visuals switch instantly using the existing profile ID, without changing saved configuration or native chat rendering.
- Extend mocked UI checks for active/inactive states, mouse leave, and the Home status surface.
- No changes to chat, profile storage, instant switching, renaming, native HUD drag or gameplay data.
- **Unpublished test candidate**, subject to native-client visual recipe.


## 0.5.0-alpha.11 — 2026-11-06 (explicit current profile indicators, unpublished)

- The persistent PROF selector now displays a visible check mark before the current profile name, in addition to its selected-button styling; the indicator updates instantly when switching.
- The Profiles manager adds a standalone green "✓ Current" / "✓ Actif" marker on the selected saved slot card, with no active marker shown on inactive cards.
- Home's Quick profiles section now explicitly states "Current profile: <name>" / "Profil actif : <nom>", while keeping its existing shortcut button highlight and selected check mark.
- All three indicators survive FR/EN locale switches, settings page navigation and /reload, and update from the same activeHudProfile source of truth.
- Updated UI regression tests for current/inactive card badges, named header indicator, Home active label and immediate switching.
- No changes to chat, profile storage, native HUD movement or game-data handling.
- **Unpublished client review build:** verify visual readability and live switching before merging.


## 0.5.0-alpha.10 — 2026-11-06 (named header profiles and rename hint spacing, unpublished)

- Show the saved custom profile names in the persistent top-right PROF shortcuts instead of only 1/2/3. Empty slots show localized placeholders and the active button remains highlighted.
- Reflow the three header shortcuts into three equal, width-constrained buttons within one anchored selector band, maintaining instant profile switching on every settings page.
- Reduce the rename editor width slightly and reserve a measured gap before the hint so the native text input never overlaps the Enter/Escape guidance.
- Add regression checks for correctly scoped header labels, responsive button widths and safe input/hint spacing.
- Keep the accepted independent profile settings, chat history/palettes, Save/Cancel, rename persistence, native drag lifecycle and previous alpha behavior untouched.
- **Unpublished**: native-client visual QA required.


## 0.5.0-alpha.9 — 2026-11-06 (isolated per-profile rename inputs, unpublished)

- Fix the Benilla native InputBoxTemplate decoration appearing on another profile card when renaming slot 2 or 3.
- Replace the shared/anonymous native template with independent untemplated EditBoxes, each inside its own styled, parented card input shell.
- Keep the dedicated Save name/Cancel actions, Enter/Escape keyboard support, validated names and previously accepted profile behavior.
- Add native UI regression assertions checking individual parent ownership and preventing other slot editors from becoming visible.
- Keep chat, instant switching, HUD mouse dragging, stored profile names and all existing game data unchanged.
- **Review build only:** needs in-game validation before merging.


## 0.5.0-alpha.8 — 2026-11-06 (profile rename UI polish, unpublished)

- Rework inline profile naming into a clean editing row that replaces the profile summary while active; the summary is restored after save or cancel.
- Show explicit Save name and Cancel actions below the name input, temporarily hiding normal profile actions to prevent overlapping click targets.
- Enter saves and Escape cancels, with invalid names retaining focus and a short validation hint.
- Retain all saved names, live profile switching, chat isolation, Home shortcuts and v0.5.0-alpha.7 behavior.
- Add UI regression tests for editing/saving/cancelling/invalid names and non-overlapping editor layout.
- **Unpublished client test candidate:** confirm the new rename editor looks correct in FR/EN and doesn't overlay other text.


## 0.5.0-alpha.7 — 2026-11-06 (profile naming and quick access, unpublished)

- Add optional display names to the 3 independent FieldKit configuration profile slots (up to 40 bytes, rejecting control characters and color markup separators).
- Rename slots from the Profiles manager with an inline input box; press Enter to save, Escape to cancel.
- Show the custom profile name on its manager card and Home quick-switch button. The compact header keeps the numeric 1/2/3 identifiers to avoid obstructing the header.
- Slash fallback: `/fieldkit profile name 1 Raid FR` (slots 1, 2 or 3).
- Names are stored as slot metadata and survive Save, SaveActive, switches and reloads. They never replace any profile settings or chat messages, and older unnamed slots remain compatible.
- Lua behavioral fixtures cover validation, preservation across save and switches, and renaming through the actual UI controls.
- The accepted alpha.6 native chat isolation, Reset/Undo, language selection and grouped HUD drag are retained unchanged.
- **Unpublished:** requires native client verification of inline editing, renaming and persistence.


## 0.5.0-alpha.6 — 2026-11-06 (chat palette isolation and reset UX, unpublished)

- Fix profile-specific chat text palettes not updating messages already visible: a profile switch now repaints recoverable native chat history using each profile's saved color/override preferences, without duplicating chat history or erasing untracked messages.
- Existing background palettes, native chat size, font and position continue using per-slot settings.
- Reset HUD positions also restores the chat frame's original position and dimensions (measured native baseline, with validated fallback), while preserving font, palette and chat messages.
- Undo HUD positions now also restores the previous chat width, height and position.
- Language preference buttons display a visible check mark and retain their active highlight after mouse hover/leave.
- Add direct mocked native chat color-swap tests, reset/undo and selected-language regression assertions. All existing alpha.5 profile isolation and safety tests remain enabled.
- **Review candidate, not released:** requires in-game 1→2→1 palette, message preservation and Reset/Undo testing.


## 0.5.0-alpha.5 — 2026-11-06 (complete configuration isolation, unpublished)

- Profile switching now restores native chat, combat text, world markers, meter preferences, accessibility, camera, party UI/sharing and the remaining declared FieldKit visual options, not just HUD cards.
- Audit covers 136 declared preference entries, 11 nested configuration tables, and 16 explicitly classified shared/operational fields. New static profile-scope audit gate prevents future unclassified preference keys.
- Preserve live chat messages, in-memory copy history, recorded combat/game statistics, learned classifications and navigation state across profile changes. Profile-local chat copy and party-detail synchronization **preferences** may change with the selected slot.
- Automatically save all changes to the profile being left, and persist the active profile on PLAYER_LOGOUT. Save-as starts editing the chosen slot without overwriting another.
- Safely migrate older alpha.1–alpha.4 layout-only profiles, keeping their original layout and initializing missing preferences from existing settings; no wipe or forced global reset.
- Live profile application reuses existing FieldKit chat, world marker, combat, nameplate, camera and display handlers. The native compact action bar option is saved per slot but structural changes still need its existing reload path.
- Add deep-copy and explicit-nil isolation checks, a destructive native chat preservation fixture, logout persistence tests and comprehensive documentation in docs/PROFILE_SCOPE_0.5.0.md.
- **Not released:** must pass native client tests for 1→2→1 settings, migration and chat-history retention before merging.


## 0.5.0-alpha.4 — 2026-11-06 (header quick-selector hitbox correction, unpublished)

- Keep the already accepted one-click Home shortcuts, immediate 1/2/3 profile switching, Undo, saved layouts, chat isolation and FR/EN UI from alpha.3.
- Put the universal profile shortcuts in a dedicated frame layer above the draggable settings-header hit area, preventing pointer-event competition on the Benilla-derived client.
- Anchor the three selectors as a single stable unit near the header's top-right edge, apart from the title and close button.
- Regression tests now track frame levels and verify that the selector's buttons sit above the drag header and remain clickable after layout reflow.
- This addresses the only unverified/KO item in the user alpha.3 recipe, without changing profile application or native HUD drag logic.
- **Unpublished client review**: verify the header selector's visibility and real mouse clicks before merging.


## 0.5.0-alpha.3 — 2026-11-05 (unpublished live HUD profile switching)

- Three compact profile shortcuts are now available in the FieldKit header on every page, with an active selection indicator. The Home page also offers quick access to all three profiles.
- Switching an existing profile immediately reapplies FieldKit-owned HUD visibility, grouping, positions, sizes and visual style without calling ReloadUI.
- The visual profile manager now offers Apply now and one-step Undo of the previous live layout. Save and Delete confirmations are unchanged.
- Profiles continue to exclude chat settings/messages, gameplay state and party sync. Native compact action bar configuration remains unchanged during live profile switches; it requires the existing dedicated reload flow.
- Safe live application is blocked while a FieldKit window is actively dragging or the layout editor is open. Failed application attempts restore the previous settings.
- Corrected French/English localization for saved and empty slots, profile status and quick actions.
- Expanded the profile tests to cover immediate visibility/positions, persistence, undo, Home/header shortcuts and language changes.
- **Unpublished alpha:** the live game client must verify the new behavior before any merge or release.


## 0.5.0-alpha.2 — 2026-11-05 (unpublished visual HUD profile manager)

- New HUD profiles page in the interface navigation with 3 profile cards, saved layout summaries, Save, staged Load and Delete buttons.
- Existing saves cannot be overwritten or deleted until the user clicks the confirmation button a second time.
- Pending profile switch can be cancelled from the visual page; applying remains deferred to /reload for safety.
- Added French UI translations, responsive layout support, and mocked end-to-end button/resize/language regression tests.
- Preserves the previously validated alpha.1 profile persistence and the stable v0.4.2 chat/HUD behavior.
- **Not released:** requires in-game UI validation.


## 0.5.0-alpha.1 — 2026-11-05 (unpublished HUD profiles foundation)

- Introduce three opt-in HUD profile slots for window layout, visibility, grouping, opacity, and allowed card sizes/positions.
- Save, list, load, delete and undo via `/fieldkit profile` commands. Applying a slot is staged until `/reload`, avoiding disruptive native-frame changes mid-run.
- Profile capture explicitly excludes native chat settings and messages, co-op sharing, gameplay statistics, and game-owned state. Bounded nested copies prevent profile tables from referencing live DB tables.
- Validate restored layout positions and sizes through existing FieldKit config normalization. Slots survive /reload; undo remains available only before a reload.
- Extend Lua 5.1 and optional native Lua 5.0 regression fixtures. All existing chat/HUD routines are untouched.
- **Alpha test candidate only** — not published or merged.


## 0.4.2 — 2026-11-05 (chat stabilization, runtime diagnostics and compatibility)

Changes since **0.4.1**:

- Improved native chat opt-out/re-enable behavior, retaining a bounded in-memory display-recovery journal across temporary styling toggles. FieldKit can rebuild observed messages after destructive native layout/font changes; older untracked lines can remain unrecoverable.
- Restored interactive chat width, height, font size and font family after a guarded-setter regression in review builds; the maintainer confirmed these controls working in-game.
- Recolor existing text only when its history is safely recoverable; clarify in EN/FR that local copy uses an opt-in 100-message buffer separate from the 500-message, session-only display journal.
- Added optional session-only `/fieldkit diag on|off|reset|report` counters for update cadence, without changing scheduling. **Not** addon CPU/FPS measurements.
- Added `/fieldkit diag api` for presence checks of 12 fixed native APIs, without asserting functional correctness.
- Added `/fieldkit diag compat` for passive checks of ChatFrame1 methods and linked left HUD root; not a universal addon-conflict detector.
- Expanded Lua fixture coverage for real settings callbacks, chat lifecycle, diagnostics commands and absent optional APIs. Previously validated linked HUD movement remains unchanged.
- Maintainer confirmed all three review lots on the Azeroth Survivors client on 2026-11-05. No independent performance or security certification is claimed.


## 0.4.2-review.3 — 2026-11-05 (passive compatibility review, unpublished)

- Adds `/fieldkit diag compat`, a passive check of native ChatFrame1 message/count methods and the linked left HUD root.
- Reports missing functions without touching frames, intercepting chat, probing other addons, or performing native writes.
- Does not claim to detect all conflicts between addons. Missing capabilities are a diagnostic observation.
- Adds Lua 5.1 and optional native Lua 5.0 regression assertions for absent native chat.
- Preserves v0.4.2-review.2 diagnostic counters and the already accepted chat/HUD fixes.
- **Review only:** requires client acceptance before final v0.4.2 publication.


## 0.4.2-review.2 — 2026-11-05 (unpublished diagnostic candidate)

- Add opt-in, session-only counters for the existing update loop: frame callbacks, data refreshes, scans, plate updates and HUD layout passes. No scheduling change.
- New `/fieldkit diag on|off|reset|report|api` commands; diagnostics disabled by default and reset on logout/reload.
- The API report checks a fixed set of native function names; missing functions are expected on some builds. Availability does not prove the function works or that co-op forwarding is supported.
- Counts and maximum observed frame delta are **not** precise per-addon CPU cost, FPS measurement or a performance benchmark.
- No network traffic, new SavedVariables, user data capture, foreign-addon scanning or gameplay actions.
- Adds standalone Lua 5.1/native Lua 5.0 diagnostics tests.
- Includes all accepted `0.4.2-review.1` chat lifecycle fixes, unchanged in this lot.
- **Not released:** a dedicated in-game smoke test is required before merging.


## 0.4.2-review.1 — 2026-11-05 (unpublished chat lifecycle stabilization candidate)

- Recolor fully recoverable visible chat history when selecting a new text palette in settings, not just on override checkbox changes.
- Restore original chat dimensions, font and maximum lines when styling is disabled **only if all displayed lines are safely recoverable**; otherwise preserve current native content and leave those settings until UI reload.
- Prevent native messages from disappearing when styling is **re-enabled after an off-mode interval**: defer destructive size, font and history setters whenever rendered native messages are no longer completely tracked; new messages continue displaying normally.
- Clearly disclose local styling's separate 500-message in-memory recovery buffer versus the opt-in 100-message copy buffer, in both English and French.
- Remove unused legacy chat color-hook and obsolete stage variables, without changing the validated HUD drag controller.
- Extend simulated native-client regressions for destructive geometry/font setters, color selection, safe opt-out and reactivation.
- **Not released:** final native-client smoke test remains required.


## 0.4.1 — 2026-11-05 (native chat customization and grouped HUD drag correction; final review candidate)

Changes since **0.4.0**:

- Customize the **native main chat** without installing a second chat window: move/lock/reset position, adjust width/height/history length, choose font family/size, background palette/opacity, and optionally override message text colors.
- Keep chat copying local and opt-in, with the Copy shortcut next to the in-game chat. Avoid fading-related instant message disappearance.
- Preserve messages observed by FieldKit when native layout/font setters clear the rendered chat; bounded in-memory recovery does not duplicate the copy log.
- Recolor **new messages** immediately; recolor previously displayed lines only where the full visible history can be recovered safely. Older untracked messages are intentionally left unchanged on clients without a readable native history API.
- Fix the linked Mode / Damage / Lairs HUD drag: use mouse down/up and cursor-based group movement rather than native drag of an invisible root, including Mode's interactive rows and refresh guard.
- Translate the text-color history guidance in French; preserve EN/FR runtime switching.
- Maintainer-confirmed in-game acceptance of the grouped drag correction on the current client; earlier native chat customization confirmed in-game. Final integrated 0.4.1 candidate is still pending a last smoke test before publication.

Full release candidate notes: [docs/RELEASE_0.4.1.md](docs/RELEASE_0.4.1.md).


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
