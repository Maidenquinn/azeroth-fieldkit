# Azeroth FieldKit

> **0.3.0 native-tools update:** optional effects, revive progress, Healing/Boss
> meters and guarded HUD tools. See [activation and limits](docs/NATIVE_TOOLS_0_130.md).

An entirely in-game combat and HUD toolkit for Azeroth Survivors. Maintained by
**Kevin Radlowski / Maidenhead**, derived from **MASH by Malk**.

[Français](README.fr.md) · [Changelog](CHANGELOG.md) · [Review dossier](docs/REVIEW.md)

## Versions and downloads

- **Latest package:** [0.3.0](https://github.com/Maidenquinn/azeroth-fieldkit/releases/tag/v0.3.0), published as a GitHub prerelease.
- Accepted for publication by the maintainer on 2026-10-31. This update adds native
  tools for the inspected 0.130.1 client, retaining guarded older-client fallbacks.
  [Release notes](docs/RELEASE_0.3.0.md). New cards/warnings start disabled.
- On 2026-10-28 the maintainer reported permission to post FieldKit as a verified
  addon. That publication permission does not independently certify this package or settle
  inherited code/assets rights. See [publication scope](docs/PUBLICATION.md),
  [NOTICE](NOTICE.md) and [LICENSE](LICENSE.md).

## Install

1. Back up your existing FieldKit folder. Download the version's named ZIP from
   release **Assets**, not GitHub's automatic source archives.
2. Copy its `AzerothFieldKit` folder into the **actual launched client's** AddOns
   directory. Check `AddOns/AzerothFieldKit/AzerothFieldKit.toc` exists; avoid nesting
   the folder twice. Disable the legacy MASH addon to avoid duplicate behavior.
3. Enable FieldKit in the client's addon selector and restart the game.

Download `AzerothFieldKit-0.3.0.zip` from the release above; it contains the
current interface. No external executable or companion addon is required. FieldKit
never imports MASHDB automatically or modifies your game saves.

## Start here

Open `/fieldkit` or left-click its minimap compass. Choose English or French in
**Interface**; native spell and creature names retain the game's language.

Active FieldKit windows **drag directly by default**. In **Windows → Layout**, lock
positions, group/unlink left or right cards, or adjust a selected card's dimensions.
The saved lock can also be changed with `/fieldkit lock`, `/fieldkit unlock` or a
right-click on the minimap compass. **Previews** is for arranging hidden cards and
combat-text areas; it temporarily overrides the lock and restores it on Done.

**Overview → Use essential HUD** shows damage, lairs, gold and group totals while
hiding stats, accessories, mode and damage taken. It is an explicit visibility-only
preset: positions, dimensions, style, combat options and other addons are unchanged.
**Undo HUD preset** restores the visibility choices until the next reload.

## Settings

- **Combat text:** one editor for categories, filters, fonts, colors, grouping,
  duration, animation, areas and native text. Optional; no MSBT dependency.
- **Health & buffs / Bosses / Alerts:** health formats, shields, buffs, independent
  boss portraits and low-health warnings. Boss portraits use an identified static
  catalog; future maps/models are not automatically covered.
- **Windows → Display:** visible HUD cards. The native damage meter stays available;
  choose your preferred display in its own options to avoid duplicates.
- **Windows → Layout:** lock, grouping and individual width/height. Slider minima
  follow the selected card and visible rows. Increasing height changes spacing,
  not font size; very large cards can leave unused space.
- **Windows → Appearance:** Classic/Decorative style, HUD background opacity and
  damage/DPS/share columns. Settings and menus retain their readable background.
- **Windows → Co-op / test:** optional passive teammate cards, health format and
  experimental spell sharing. Native teammate frames remain interactive by default.
  Explicitly hiding them removes their targeting/menu/buff interactions until restored.
- **Minimap / Nameplates / Interface:** independent chest/lair markers, optional
  enemy filtering, language, camera, compact bar and optional local chat copy.

Hover a spell in your own meter or a player in the group meter for detail. **Pin**
keeps that player's detail open while you scroll; Unpin, Escape or the close button
releases it. Rank changes do not select a different player in a pinned card.
The card closes when its source meter closes or the run ends.

## Data and limits

Damage values come from native counters, never DPS multiplied by time. Damage taken
can include an explicitly **Unattributed (native total)** remainder. Missing values
stay unknown; healing totals are not evidence of individual healing ticks.

Native group data supplies player totals and at most the top allied spell.
Experimental sharing is **off by default**: both players must opt in, and only own
spell counters are sent via bounded `AFKDETAIL1` PARTY addon messages on request.
Live co-op transport is **not confirmed**. The status reports recent received data,
not a successful send call as proof of delivery. [Protocol and limits](docs/PARTY_SYNC.md).

The mode card is compact and hidden without a native difficulty rank by default.
Its hover rules are explicitly a **0.121 reference**, not verified current mechanics
or measured live multipliers. No active affix/marks/star data is invented. Runes on
the ground are not tracked; lair pins are not moving guardian coordinates.

## Commands and privacy

- `/fieldkit`, `/fieldkitcombat`: settings and combat editor.
- `/fieldkit lock`, `/fieldkit unlock`: saved movement lock, without opening settings.
- `/fieldkit money`: reattach the gold/chest strip above the action bar.
- `/fieldkit coop`, `/fieldkit sync`: local co-op diagnostics.
- `/fieldkitlog on`, `off`, `clear`: optional in-memory chat-copy buffer. It may include
  private messages; disabling clears it. It is not saved or transmitted.

No downloaded code is executed. Native writes are restricted to documented visual
settings and optional action-bar behavior. Native CVars may outlive addon disabling;
restore preferences in the game's options as needed. [API surface](docs/API_SURFACE.md)
and [security scope](SECURITY.md) explain these effects and possible addon conflicts.

## Validation and development

Offline tests cover Lua 5.0.3/5.1, nested-function upvalues, malformed settings,
persistence, native-data provenance, movement, co-op fallbacks and UI callbacks.
They do **not** certify live rendering, performance or network delivery.

```text
python tools/audit.py
python tools/verify.py --lua50 PATH_TO_LUA_5_0_3
python tools/package.py
```

Packaging requires committed source and fresh inventory/validation snapshots.
See [contributing](CONTRIBUTING.md), [code guide](docs/CODE_GUIDE.md),
[testing](docs/TESTING.md), and the [candidate acceptance checklist](docs/UX_SIMPLIFICATION.md).
Please use that checklist for upgrade feedback. Offline checks do not prove live rendering or network delivery.
