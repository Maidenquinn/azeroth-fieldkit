# Native tools — 0.3.0-review.1 test candidate

Based on the read-only audit of the installed **0.130.1** client on 2026-10-31.
Evidence: [CLIENT_0_130_EVIDENCE.json](CLIENT_0_130_EVIDENCE.json). Exe hash:
`e8ff033544095e81d74087ff400d50286b26af02291e649f4c5e4d76cbcf8863`.
Branch: `codex/native-tools-0-130`. Public release remains **0.2.3**.

## Where to enable things / Activation

All new cards and warnings are **off by default**. No existing setting is reset.
The new affix display is on only within the existing mode card and only uses
received data. No guessed data is created to demonstrate a feature.

- **Windows → Display / Fenêtres → Affichage**: Effects tracker / Suivi des effets;
  Next boss reminder / Rappel du prochain boss; Stored level-up reminder / Rappel
  des niveaux stockés. Local meter view / Vue du compteur local selects Damage,
  Healing or Boss damage in the existing meter.
- **Health & buffs / Vie et effets**: select totems, summons and native effect timers
  for the Effects card. Empty categories produce no rows. Its overflow count suggests
  adjusting filters instead of building unbounded windows.
- **Windows → Co-op / test / Fenêtres → Coop / tests**: Co-op revive progress /
  Progression des réanimations en coop. Shows the local revive/ally involved;
  the original revive UI remains available.
- **Alerts / Alertes**: native boss/mechanic warning filters, arrival warning and
  lead time (3–30 seconds). Native banners stay unchanged; select your preferred
  native display in the game's own options if duplicates are distracting.
- **Minimap / Minicarte**: highlight the lair selected by the native flag in the
  existing Lairs card. This is not a moving-guardian tracker.
- **Windows → Layout / Fenêtres → Disposition**: new cards appear in the size selector
  and drag/lock like the old ones. Keep this window above card choices is a separate
  opt-in per selected window. It only applies while the selected HUD is visible.
- **Windows → Appearance / Fenêtres → Apparence**: separately allow pinned spell
  details above level/jewelry choices. Other modals, including death, are not promised.
- `/fieldkit native`: local API capability/raw-affix diagnostic; no network message.

## Honest data and compatibility

`NativeData.lua` holds a fixed read-only API list and protected calls. Native tables
are never edited. Per-run barriers compare prior table identity, update stamps and
packet generations: old retained effects/revive data is rejected after resets,
while fresh packets already delivered in the new batch remain usable.

The meter adapter retains native totals/rates. Healing uses HPS (SPS in French),
not DPS. Boss rates use that native fight's time base. Switching a local view
closes prior spell details; group rows always retain the group's damage semantics.
Party sharing still sends own damage snapshots only, regardless of the local view.
Missing meter APIs show Not provided instead of substituting Damage or zero.

Totems report counts/caps and the earliest expiration per type, not each individual
totem's position/health. Summon durations are earliest temporary expiration; only
an explicitly permanent group is labelled Permanent. Unknown duration stays `?`.
Only timers actually supplied by the native API can be shown. No spell is cast.

Revive data is local: down/progress/reviver or the friend being revived. It is not
a full downed-roster/location feed. No native revive frame is hidden by this feature.

Affixes accept literal recognized English names (Bolstering, Sanguine, Explosive),
including case/space variations, only when actually received in `AZS_ZONE.affixes`.
Unknown numeric/string encodings are displayed as **Affixes (raw)**, never decoded
as a guessed bitmask or inferred from the calendar. The real producer encoding and
co-op availability still need observations; `/fieldkit native` helps collect them.
Historical Heroic rule explanations remain explicitly a 0.121 reference.

Native warnings subscribe through the provided banner API, unsubscribe when supported,
ignore irrelevant kinds, sanitize/limit text, and cap/deduplicate visible events.
At most 3 warnings last up to 4 seconds; the native banner remains available. The
boss arrival warning comes only from native upcoming/endless data and fires once
per observed arrival. It predicts no attacks or ground hazards. Pause/choosing stops
arrival warnings; timers rely on native remaining time rather than wall time.

`ScreenLayers.lua` calls only the Runtime.lua wrapper. It refuses foreign/native
frame names and UIParent, makes no write without explicit opt-in, avoids unchanged
writes, and unregisters when hidden/disabled/out of play. It uses the optional getter
to confirm state when available. No fallback alters native UI strata or game screens.

No rune coordinate feed, armory/star/mark data, complete native allied spell API or
new portrait model API was discovered or invented. No automatic talent spending,
card choice, action, chat sending, polling process or external program was added.

## Tests and live acceptance

Automated tests run actual addon constructors/callbacks under Lua 5.0.3 and 5.1.
They cover view/rate fidelity, pinned detail, effects filters/counts, absence of
refresh allocations, pause handling, sizing/collapse, overlay allowlisting and
idempotence, error/missing API fallback, revive rows, lair identity, raw affixes,
warning bounds/deduplication, unsubscribe, run boundaries and event ordering.
A serialized reload checks the meter view, own overlays and dimensions, rejecting
foreign overlay names. Existing privacy/layout/combat/co-op fixtures still pass.
An additional local integration run loaded the extracted 0.130.1 API template
alongside the actual addon modules and injected synthetic messages. Effects,
revives, schedules, banners, healing and overlay registration/removal passed.
The template's native HUD placeholder was neutralized in that offline harness.
These are **synthetic/offline** checks, not live game success or FPS measurements.

Before merging or publishing:

1. Install the candidate in the launched client, restart, confirm version and EN/FR.
2. Compare Damage/Healing/Boss to the native meter. Check HPS and details, then
   drag/resize/collapse/reload. Native proc colors and old windows must stay intact.
3. Enable Effects on relevant classes: actual totems, permanent/temporary summons,
   cooldowns, card choices, pause, expiration and next run. No imaginary sample rows.
4. Test revive on host and guest: down, progress, interrupted revive, completion,
   leaving party and phase exit; original UI remains interactive.
5. Repeatedly enable/disable warnings; verify duplicate suppression, expiry, next
   boss threshold, pause, final/endless arrivals and restored state after a new run.
6. In Normal and Heroic III/V, collect raw affixes on host/guest before assuming
   any format; confirm unknown data remains labelled. Check the flagged-lair row.
7. Opt a small window into foreground above level/jewelry choices. Check clicks,
   disabling and phase exit, including at small resolution. Do not infer death-modal support.

The installed candidate is for maintainer testing, not a public release. No game
save, executable, MPQ, account enable file or manually edited saved variable is needed.
