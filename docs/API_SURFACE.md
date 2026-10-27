# Native effects and data boundary

The review boundary is **TOC-loaded source**, not every file in the developer
repository. Runtime.lua centralizes CVar/HUD writes; ordinary frame methods remain
in their owning UI modules. `tools/audit.py` emits a complementary machine inventory.

## Reads

- Run API: AZS_GetPhase, AZS_GetMeter, AZS_GetLairs, AZS_GetDebuffs and
  AZS_UnitKind when present; AZS_RUN, AZS_ZONE, AZS_UNITS, AZS_STATS, AZS_BUFFS,
  AZS_HEALING, AZS_TAKEN, AZS_CHESTS, AZS_LAIRS and update timestamps.
- Legacy unit/inventory/XP/currency APIs: player/target/mouseover observations,
  health, level/classification, buffs/debuffs, equipment names and tooltips.
- Legacy self/creature combat event strings and CHAT_MSG_ADDON prefix AZS for
  numeric stats fallback. No packets are executed or treated as authenticated.
- UI geometry/regions/children, minimap zoom/shape, mouse position/focus during
  explicit dragging, CVar reads for rotation/camera and local time for animation.

The supplied official addon API document confirms the native run-state, chest,
lair and HUD interfaces. See OFFICIAL_API.md for the exact document fingerprint
and the resulting scheduling/phase/countdown corrections. This describes the
intended API contract, not approval of this specific addon or its game assets.

These reads may expose information beyond the selected target; game developers
must decide which of those capabilities are acceptable.

## Writes and hooks

### Always-installed addon UI

The addon creates its own frames/fontstrings/textures, slash commands and event
listeners, including a minimap settings shortcut. It stores its own FieldKitDB.
Target health text is attached to the native target display. Local diagnostic
messages use DEFAULT_CHAT_FRAME:AddMessage, which is not network chat sending.

HideNameplates is wrapped once, capturing the preceding native/other-addon
implementation. With filtering off it forwards directly. ShowNameplates is no
longer redundantly wrapped. These are shared-global integration points.

### Optional nameplate filtering (fresh default off)

The filter scans WorldFrame children on count change or every 0.25 seconds,
chains recognized plate OnShow/OnHide scripts, adjusts region alpha and lifts
selected/native nonplate frames to UIParent with scale compensation. It keeps
native plates available while the V-key state controls visible special plates.
WorldFrame alpha is changed while filtering is active. Turning filtering off
restores the alpha and frames moved by this filter. Concurrent addons can still
make conflicting decisions; a UI reload is the reliable session reset.

### Optional native HUD replacements (fresh default off)

FieldKit.SetHudShown only forwards `bosses`, `tally`, or legacy `meter` restoration
to AZS_SetHudShown. The game implements this via its own HUD CVars. Boss/tally
options track that FieldKit hid the native section and restore it when disabled.
The native damage meter is not replaced; its compatibility path only restores a
previously hidden meter. These settings can persist after addon removal.

### Optional damage numbers and camera (unset until chosen)

The only direct SetCVar call is in Runtime.lua. Its keys are allowlisted:
CombatDamage, PetMeleeDamage, PetSpellDamage (0/1), cameraDistanceMaxFactor
(1 through approximately 3.333, equivalent to the configured 15–50 yards).
CameraZoomOut occurs on a camera-slider interaction. No gameplay/progression
CVars such as spendLevels/storeLevels are accepted.

### Optional compact action bar (fresh default off)

Reparents existing ActionButton1–6 and ActionButton12 into a compact frame,
repositions native micro-menu buttons, hides MainMenuBar and installs its OnShow
hide handler. Existing action-button clicks remain native. Custom drag handlers
allow a **player-initiated** slot exchange with ClearCursor, PickupAction and
PlaceAction. No actions are executed on a timer or chosen by an algorithm.
Changing compact mode calls ReloadUI from the explicit settings checkbox.

Disabling/reloading returns native frames to the freshly constructed stock UI;
the actual action-slot arrangement remains a real user-modified arrangement.

### Optional low-health audio and decorative changes

PlaySound uses native RaidWarning or igQuestFailed identifiers, with error guards.
No sound files or external media are loaded. Gryphon end-cap Hide/Show affects
the native action bar when that setting is explicitly selected.

### Optional main-chat copy (fresh default off)

Only ChatFrame1:AddMessage is observed after opt-in. hooksecurefunc is preferred;
otherwise a once-installed wrapper captures then forwards the original five
arguments/return. No other chat frames are hooked. Disable clears the table and
editbox; the dormant forwarding hook survives until UI reload to avoid removing
another addon's later hook. No AddMessage replacement occurs before opt-in.

### What persistence contains

FieldKitDB includes configuration, collapsed states, frame positions, selected
stats, learned non-player names, last native stats and the old fallback chest
count. Positions are UI coordinates, not a player travel log. The engine writes
this table on its normal lifecycle. Native game saves and MASHDB are not accessed.
The removed talent state and optional chat content are not persisted.

## What was deliberately removed or excluded

- AZS_TALENT_TOGGLES save/restore and its logout/addon-loaded branches.
- SetMapToCurrentZone/GetPlayerMapPosition calibration path for lair distance.
- Redundant ShowNameplates forwarding and obsolete MASH tab migration.
- Unconditional chat capture and hover buttons; inherited MASH branding icon.
- All old rune observers/probes/companion experiments, DLL/EXE helpers and raw
  reverse-engineering extraction tooling (already outside the 1.3.9 runtime).

Keeping a feature disabled does not make an unapproved addon acceptable to load.
The complete candidate, not just its default configuration, must be reviewed.

## Configuration and theme surfaces (0.2)

Interface.lua creates addon-owned frames, scroll viewports, bounded popups and
an arrangement dock. Theme.lua loads only bundled, fixed local textures/fonts.
No Stats Lua API is imported. Language/reflow/Refresh never invokes native setting
setters. All native actions still originate in the existing schema callbacks or
an explicit Reload UI button. Opening configuration does not unlock HUD dragging;
the Move windows / Done action controls that in-memory mode. Saved uiPage and
uiSchema only record navigation/migration, not game state or player coordinates.

## 0.121 compatibility

GameCompatibility.lua reads AZS_ZONE.heroic only during an active native phase. Critical-objective EN/FR names exempt existing orb nameplates from ordinary-mob filtering; the V key still controls visibility. No spawn coordinates, target/combat actions, progression writes or inferred mark/star/affix data are introduced. See GAME_0_121.md for evidence and limitations.

## Linked HUD and run-mode reference

RunMode.lua reads only the existing native rank/zone and phase; its versioned reference is static text, not live affix or multiplier data. HudStack.lua reanchors FieldKit-owned frames only. FieldKitDB.linkLeftCards, runModeCard and pos.FieldKitLeftStack persist configuration and a UI anchor. Legacy individual coordinates are retained; no world-position history or game progression is written.

## Native anchor persistence

Positions.lua reads GetPoint and writes only FieldKitDB.frameAnchors (validated own-frame names and point/relative-point/numeric offsets). Restoring uses UIParent-relative SetPoint; no frame pointers are serialized. Native SetClampedToScreen handles bounds of the linked group proxy, with child clamps disabled while linked. Legacy positions are retained and Reset/Undo includes both representations. No game/save/other-addon state is accessed.
