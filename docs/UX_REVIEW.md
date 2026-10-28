# Interface review — 0.2.0-review.1

Current unmerged UX candidate: [0.2.3-review.1](UX_SIMPLIFICATION.md). Historical behavior below is superseded where stated there.

Reviewed on 2026-10-27 against the installed FieldKit 0.1.0-review.3 and the
maintainer-provided Azeroth Stats 1.6.0-dev.6 design. This document records source
and offline checks; it is not a claim of in-game acceptance or developer approval.

## Findings and implemented changes

- The old panel exposed eleven technical pages, including two competing HP
  checkboxes for each unit. Nine task-oriented destinations now use stable ids:
  Overview, Combat text, Health & buffs, Bosses, Alerts, Windows, Minimap,
  Nameplates, Interface. HP uses one exclusive three-value choice per unit.
- Opening settings previously unlocked HUD dragging and could show a fictitious
  boss. Opening now only reads preferences. Move windows hides settings, unlocks
  handles and shows an explicit Done dock; boss placement previews only appear
  in this arrangement mode. Escape ends the mode and locks drag handlers.
- Compact action-bar changes previously reloaded immediately. The checkbox now
  stages the setting and reveals an explicit Reload UI button. No automatic
  reload interrupts the current run. The current bar stays applied until reload.
- Narrow screens previously shrank the complete interface. Pages now reflow
  horizontally and scroll vertically, retaining normal text size at 800×600.
  Exceptionally smaller viewports still use a bounded scale to keep the shell
  visible. Choice popups show at most seven rows, scroll, open upward near the
  bottom and live outside clipped page viewports.
- Reset positions now offers immediate Undo, preserving the prior coordinates
  and money-strip attachment. This resets the addon HUD window positions only;
  combat-area offsets remain independently configurable in Areas.
- Gold/chest price can be hidden separately from statistics; disabling the strip
  restores the native tally when FieldKit was replacing it. Maintenance ticks do
  not bring a disabled strip back.
- The settings shell, controls, navigation, owned HUD surfaces and stats picker
  use the Azeroth Stats material family: slate, gold, painted glyphs and bundled
  OFL sans/serif fonts. Health/portrait/action artwork keeps native semantics.
- Combat settings stay in one six-page editor: General, Events, Fonts, Filters,
  Areas, Game text. The final page contains the existing native damage/critical
  options so duplicate displays can be disabled in the same journey.

## Boundaries and preserved behavior

No new telemetry, network, dynamic execution, gameplay automation, external
helper or native write capability was introduced. Runtime.lua remains the
native-write boundary. Changing language or visiting/resizing pages does not
apply a CVar or native HUD setting. Action-slot swaps remain explicit player
drags, as documented in API_SURFACE.md. Existing boss identities, minimap data,
combat filters/colors/fonts, collapse state and saved HUD coordinates remain.

UI migrations are confined to FieldKitDB: legacy page indices/titles map to
stable ids under uiSchema=2. Other addons and client saves are outside scope.
The inherited code/game-data licensing questions in REVIEW.md still apply;
see PUBLICATION.md for the subsequently reported publication permission; restyling is not a clean-room rewrite or a rights transfer.

## Verification

- Actual TOC modules executed under Lua 5.0.3 and Lua 5.1 without string.match.
- Existing portrait, combat, minimap, collapse, privacy, malformed-data and
  persistence fixtures retained; new interface_journey.lua exercises real UI
  callbacks for routing, exclusive HP choice, staged reload, layout mode,
  reset/Undo, strip visibility, 800×600 reflow and bounded scrolling.
- Repeated reflows allocate no additional widgets. The theme caches geometry and
  material selection. UI viewport checks run every 250 ms while settings show.
- Static inventory checks every loaded module, portrait format and exact hashes
  for bundled theme assets/fonts. Font license notices accompany the package.
- Offline geometry previews use the real Lua widget tree and bundled assets;
  these are approximate projections, not screenshots of the game renderer.

## Required in-game acceptance

Restart the client to discover the new files, enable only FieldKit for its
overlapping functions, and open /fieldkit. Check English/Français, close and
Escape, all pages and scrollbars at normal and reduced window size, each HP
format, long item/spell names, and Events dropdown scrolling. Move windows,
finish, reset/Undo and reload once to check persistence. Confirm compact-bar
application only after explicit reload, money strip visibility, collapsible
panels, boss portraits with another target, and chest/lair markers. A result
recorded by the maintainer/user is needed before claiming live-game validation.

## 0.2.0-review.2 additions

Windows now begins with card styling, background opacity and meter-value format.
These apply immediately and persist. The default meter row shows the unabridged
native cumulative damage, DPS and share; alternate modes preserve a compact view.
Unknown native fields display `?`, rather than damage extrapolated from DPS/time.
The damage meter alone widens to fit the selected values and clamps its visible
position after resizing. Other window sizes and saved coordinates are preserved.

Classic style reuses four existing slices as one-pixel solid edges, hides the
other slices and grain, and keeps the body simple. Opacity changes material
layers only: frame, text, icon and border opacity is not reduced. Switching styles
restores the original UV/material geometry without allocating additional widgets.
`tests/card_preferences.lua` exercises actual choice callbacks and observed native
fields, checks all modes and unknown fields, switches both skins repeatedly,
checks 0% and partial background opacity, and leaves non-default preferences for
the serialization/reload fixture. Native Lua 5.0.3 and Lua 5.1 fixtures pass; live
visual acceptance of this addition is still pending.

## 0.2.0-review.3 correction following live user feedback

The user’s screenshots exposed two defects in review.2: HUD opacity also faded
the configuration shell, and concatenated values did not align into columns.
Theme surfaces now opt into HUD preferences explicitly. Configuration, popups,
Overview and the arrangement dock always retain the original opaque theme;
HUD collapse buttons inherit their own parent’s visual scope.

Damage, DPS and share each use one preallocated FontString with a fixed right
anchor and width, independent of numeric length. Spell names have a separate
bounded rectangle. Hidden columns change with the selected mode. Resizing keeps
the saved left edge; initial width is set before position restoration, avoiding
coordinate drift on reload. No totals or rates are inferred or recalculated.

Regression fixtures check the actual visible column regions with differently
sized numbers, mode visibility, fixed widths/anchors, retained left edge and
settings opacity while HUD opacity is zero. Both Lua runtimes pass; the corrected
candidate still requires visual confirmation in the game.
