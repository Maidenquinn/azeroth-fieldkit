# FieldKit 0.5.0-alpha.5 — exhaustive profile-setting scope audit

## Root cause confirmed

The alpha.1–alpha.4 `Profiles.lua` captured only 25 simple HUD flags plus four layout tables. All other values remained in the flat `FieldKitDB` and therefore leaked across profile switches. The old scheme also did not save edits to the outgoing active slot before switching.

## Audit methodology

The source-of-truth now combines:
- Every default in `Config.lua` (`FieldKit.ProfilePreferenceDefaults`), including chat, accessibility, boss alerts, HUD, health, display, party and native presentation toggles.
- Explicit additional persisted options used by `Interface.lua`, `FieldKit.lua`, and the combat editor, including font size, camera, languages, minimap button, meters, combat text filters and colors.
- The dynamic defaults in `FieldKitCombat.defaults`, so future combat options are automatically scoped.
- A bounded deep copy of 11 known nested settings maps.

The new `tools/profile_scope_audit.py` is enforced by `tools/verify.py`. It currently classifies **136 declared preference fields**, **11 persisted preference tables** (counted within declared scope), and **16 explicitly shared or operational fields**. It scans all addon Lua modules and rejects newly referenced `FieldKitDB.<key>` or core `DB.<key>` fields until classified. Dynamic access via `FieldKitDB[key]` is covered through the defaults and explicit option lists. Static coverage is not a formal proof against every future use of arbitrary dynamic keys.

## Per-profile settings

| Category | Representative fields and structures |
|---|---|
| Native chat | `chatStyle`, `chatCopy`, `chatMove`, `chatAnchor`, `chatWidth`, `chatHeight`, `chatFontSize`, `chatFontFace`, `chatHistoryLines`, `chatFading`, `chatBackgroundOpacity`, background/text colors, overriding and copy button |
| HUD / layout | `pos`, `frameAnchors`, `cardSizes`, `collapsedWindows`, `onTopWindows`, left/right linking, locking, visibility, styles and opacity |
| Combat | `combatText*`, `combatEvents`, `combatProfiles`, `combatProfileActive`, `showCrits`, `groupCrits`, `hideDamage`, healing/incoming/outgoing, thresholds, scroll directions, size, font, colors and world text |
| Bosses and native overlays | Boss style, warnings, timeline, lead time, alerts, health modes, optional native overlays and nameplates |
| Map / world | Chest/guardian pins, `worldMarkerSettings` categories/ranges/scales/aura, minimap button position |
| Meter / statistics view | Meter tabs, values, sorting, detachable panes, hidden rows, `shownStats`, spell tips, collapsed state |
| Player / accessibility | Health alerts and sound, target and player health display, buffs, shields, compact bar preference, camera maximum |
| Multiplayer | Party cards, meter, health modes, replacement options and **`partyDetailSync` permission** |
| Presentation / language | `language`, panel styles, visibility, text/overlay preferences |

Selecting a slot applies all compatible FieldKit options immediately through their native update handlers. One known exception is **`compactBar`**: the desired flag is isolated and saved per slot, but changing the native action bar's structural layout still requires the existing `/reload` workflow. The UI reports this case.

A profile with `chatCopy=true` or `partyDetailSync=true` may enable those features when selected. These are preference changes explicitly chosen by selecting the profile, not covert background actions. Chat messages and co-op transmitted content are **never stored in profiles**.

## Shared data: intentionally NOT copied

- `known` (learned enemy classifications), `lastStats`, `chestsOpened`: gameplay observations/counters.
- `uiPage`, `panelSection`, `panelTab`, `windowPage`, `uiSchema`: where the user is browsing in the settings UI.
- `schema`, `interfaceProfiles`, `activeHudProfile`, `profilePendingSlot`: persistence/versioning/slot container.
- `hudBossesHidden`, `hudMeterHidden`, `hudTallyHidden`, `moneyDockRepair`: derived flags and native repair bookkeeping.

Likewise, native chat **message history**, the in-memory recovery journal, opt-in copy history, game saves, combat telemetry and other-addon data are not part of profile snapshots.

## Migration and durability

1. Existing alpha.1–alpha.4 slots retain their saved positions, sizes, opacity and other old fields.
2. Newly supported settings are copied from the current user's flat `FieldKitDB` into each legacy slot. This preserves the initial appearance for existing users; the new preferences then diverge naturally when customized.
3. New slots receive a deep copy with explicit nil markers, so a missing optional setting cannot inherit the preceding slot's value.
4. Save-as selects the new profile editing context without overwriting the previous slot. When switching to another slot, all unsaved preference changes in the outgoing active slot are captured automatically.
5. `PLAYER_LOGOUT` captures the final active profile configuration so a reload or exit persists edits. All flat settings continue to use the existing SavedVariables mechanism.
6. A failed live application attempts rollback to the previous full settings snapshot. Native frame mutations are not guaranteed fully reversible on every client; the release remains gated by real in-game testing.

## Validation matrix

- Two deliberately conflicting slots: chat width/height/font/fading/colors; boss alerts, meter options, world marker settings, combat events, party sync, camera, language and visual layout.
- 1 → 2 → 1 repeated live switches and Undo, with no field contamination.
- Changes made to a slot **without pressing Save** preserved when leaving and returning.
- Legacy profile migration and SavedVariables serialization.
- Native chat mock with destructive font/geometry setters verifies messages survive profile switches without duplicate lines.
- Gameplay stats, learned enemy data and chat history stay shared.
- Existing linked HUD mouse release and the stable v0.4.2 chat controls remain critical in-game regression gates.

**Status:** code and synthetic Lua regression candidate; the maintainer's native-client tests have NOT yet been completed for alpha.5.
