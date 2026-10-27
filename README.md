# Azeroth FieldKit

**A configurable, entirely in-game combat and HUD toolkit for Azeroth Survivors.**

Maintained by **Kevin Radlowski / Maidenhead**. Derived from **MASH by Malk**.
Version **0.2.0-review.1** is a public **review candidate** shared for technical examination,
not a developer-approved or stable release. Renaming identifies this maintained fork; it does not
change the authorship or rights of the inherited code.

[Français](README.fr.md) · [Review dossier](docs/REVIEW.md) ·
[Security assessment](SECURITY.md) · [Code guide](docs/CODE_GUIDE.md) ·
[Native API effects](docs/API_SURFACE.md) · [Credits and provenance](NOTICE.md)

## Why this project exists

MASH already combined many useful UI improvements. FieldKit makes that work easier
to inspect: explicit ownership boundaries, documented native effects, conservative
defaults, bounded optional chat capture, isolated settings and repeatable checks.
It is submitted for discussion under the game's manual addon approval process.
No statement here substitutes for a decision from the game's developers.

## Features

- **Combat text:** an integrated MSBT-style renderer, with event categories,
  incoming/outgoing/healing filters, ability exclusions, colors, fonts, opacity,
  critical sizes, grouped hits, animation, lifetime and visible-message limits.
  One editor contains General, Events, Fonts, Filters and Areas. No MSBT install.
- **Health:** player/target/boss values, percentages or both; player shield and
  buffs; adjustable low-health visual warning and optional sound.
- **Boss frames:** movable native-state displays and static independent portraits.
  Changing or clearing the player's target does not select another portrait.
- **Run displays:** selected stats, equipment with tooltips, damage/source meters,
  lair states and a separate gold/next-chest-price/kills strip. Windows can collapse.
- **Optional minimap markers:** native chest positions as chest icons; native lair
  positions with guardian state/countdown. A lair pin is **not** a moving guardian.
- **Optional layout tools:** elite/boss nameplate filtering, a compact action bar,
  decorative gryphon visibility and a 15–50 yard camera setting.
- **EN/FR:** immediate, persisted language switch. Native creature, ability and
  item names retain the language provided by the game.
- **Optional local chat copy:** disabled by default. Up to 100 messages from
  the main chat frame, at most 512 bytes each, in memory only. Whispers may be
  included. Nothing is uploaded, posted or automatically copied to the clipboard.

## Getting started with the interface

Open `/fieldkit` or click the compass beside the minimap. **Overview** shows the
main tools and their current status. Choose **Configure** to change one area.
All preferences apply immediately except the optional compact action bar, which
shows an explicit **Reload UI** action when changed.

- **Combat text:** General, Events, Fonts, Filters, Areas, Game text. Use Game text
  to turn off duplicate native damage/critical displays.
- **Health & buffs / Bosses:** select Numbers, Percentage or both in one control.
- **Windows / Minimap:** independently enable the windows and pins you need.
- **Interface:** English/Français, compact bar, native decorations, optional chat
  copy and camera. Native creature/spell/item names are not translated.
- **Move windows:** temporarily hides settings; drag the enabled HUD windows or
  combat-area handles, then **Done** returns to settings. Escape exits this mode.
- **Reset HUD positions:** restores HUD window defaults and offers **Undo**.
  Combat-area offsets have their own controls in Areas.

Pages keep readable font sizes and scroll on smaller screens. Close with the
upper-right cross, **Close**, Escape or `/fieldkit`. The [UX review](docs/UX_REVIEW.md)
records findings, migration and live acceptance checks. The slate/gold theme is
shared with Azeroth Stats but bundled locally: that addon is not required.

## Conservative defaults

Fresh settings leave **nameplate filtering, chest/lair minimap pins, native boss
HUD replacement, tally replacement, compact action bar, scrolling combat text,
chat copy and low-health audio disabled**. They remain configurable for review.
The camera is unchanged until configured. Native damage-number settings remain
unchanged until that option is explicitly chosen.

Addon-owned health/stats/equipment/meter/lair/money windows are enabled. These can
also be disabled independently. Conservative defaults are not a certification
that an enabled feature complies with the game's rules.

## Installation for an authorized review

1. Obtain permission to test this candidate under the current game policy.
2. Disable MASH before enabling FieldKit: they modify some of the same native UI.
   Do not run both concurrently, even though their saved variables are separate.
3. Copy the **inner `AzerothFieldKit` folder** into the launcher's AddOns directory
   (or `Interface/AddOns`). Its TOC must be `AzerothFieldKit/AzerothFieldKit.toc`.
4. Enable it in the game selector and restart/reload the UI. A restart may be
   required for the client to discover the new folder.
5. Open `/fieldkit`. Select English/Français in Interface and enable only the
   features authorized for the test.

There is no installer, companion executable, injection, process reader, external
service or required third-party addon. Python/Lua test tooling is for developers
only and is not included in the addon runtime ZIP.

## Commands

- `/fieldkit`: open/close settings; the minimap book icon opens the same panel.
- `/fieldkitcombat`: open the single combat-text editor.
- `/fieldkit money`: restore the gold/chest strip above the compact bar if enabled.
- `/fieldkit stats`: choose displayed stats.
- `/fieldkit chests`: show the observed/legacy chest count and next price locally.
- `/fieldkit status`: display local nameplate/camera diagnostics.
- `/fieldkitportrait coverage`: catalog coverage; `/fieldkitportrait`: current source.
- `/fieldkitlog on` / `off`: explicitly enable/disable local chat capture.
- `/fieldkitlog`: open retained main-chat text for manual Ctrl+A / Ctrl+C.
- `/fieldkitlog clear`: clear retained chat and the copy editbox immediately.

Chat capture can also be toggled in Interface. Disabling clears its memory on the
next watcher tick (at most 0.2 seconds); `/fieldkitlog off` clears it immediately.
Messages received while disabled are never retained or reconstructed later.

## Data accuracy and limitations

The addon displays information already exposed by the native Lua run API and
legacy combat events. Native tables are **not authenticated by FieldKit**. Other
addons sharing the Lua environment could falsify them or interfere with frames.
Packet text is parsed as data, never executed.

Combat categories appear only when a recognized corresponding event is received.
English legacy combat templates are supported; unrecognized messages do not
generate invented hits. Healing displays positive cumulative-meter deltas, not a
claim to exact individual tick times, overhealing or every heal event.

The static portrait catalog describes the **examined client version**: 100
definitions (60 scheduled bosses and 40 special/elite/guardian definitions), 12
maps, 98 displays and 1,063 localized aliases. It does not automatically discover
new bosses or transformation appearances. A conflicting explicit display id or
unresolved identity produces a question-mark fallback. Multiple native instance
ids keep separate health/state even if they share an appearance.

Markers require exposed native coordinates. Rotation disables the custom pins
instead of projecting them incorrectly. Unknown minimap shapes use a round-map
assumption. Edge markers show direction outside the displayed range. Countdowns display the native remaining value without subtracting wall-clock time
during a pause/card choice; zero does not confirm a respawn.

There is **no ground-rune tracking**. Old pickup observations, probes, external
helpers and experimental modules are not distributed. Chest pricing/counting on
older clients can use a historical estimate; native price and `AZS_RUN.ck` cache
count take priority. Run-owned displays are hidden when the native phase is nil.

## Saved data, migration and removal

The client owns serialization of **`FieldKitDB`**: settings, window positions,
collapsed states, learned enemy-name classifications, last native stats and the
legacy chest-count state. Chat content is not in SavedVariables. There is no
automatic import, rename or edit of `MASHDB`, game saves or other addon settings.

To stop using FieldKit, disable it and reload/restart. Stock frame hooks and
reparenting are session-local. **Native CVars/HUD visibility can persist**: restore
your preferred damage/camera/HUD options in the game settings. Disabling an addon
does not guarantee restoration of every native preference it changed. No data
needs to be deleted; retain the old MASH installation until review is resolved.

## For developers and reviewers

Start with [REVIEW](docs/REVIEW.md), then [SECURITY](SECURITY.md). The
[code guide](docs/CODE_GUIDE.md) describes initialization, data flow and module
order. [CODE_INDEX](docs/CODE_INDEX.md) links named functions to source.
[API_SURFACE](docs/API_SURFACE.md) lists native writes and hooks, including the
manual action-slot swap. [TESTING](docs/TESTING.md) explains what the checks prove
and which in-game tests remain outstanding.

Run from the repository root with Python 3.12+:

```sh
python -m pip install -r requirements-dev.txt
python tools/audit.py
python tools/verify.py
python tools/package.py
```

For an additional native Lua 5.0.3 run:

```sh
python tools/verify.py --lua50 /path/to/lua50
```

Lua 5.1 bytecode is inspected for every nested function against the old
32-upvalue limit. The provided local Lua 5.0.3 run also executes actual modules
and behavioral fixtures. Neither is a test inside the running game. Runtime ZIPs
are generated deterministically with a file manifest and external SHA-256 sum.
Developer tests/dependencies and obsolete experiments are excluded from them.

## Provenance and release status

[NOTICE](NOTICE.md) and [LICENSE](LICENSE.md) describe unresolved upstream and
asset permissions. No project-wide open-source license or author approval is
claimed. The Git history retains the exact inspected MASH 1.3.9 snapshot before
the fork changes, so reviewers can compare the changes rather than trust a rename.
No public release should be advertised as approved until rights and the developer
review are resolved. See [CHANGELOG](CHANGELOG.md) for the concrete changes.
