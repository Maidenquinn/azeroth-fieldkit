# UX simplification candidate — 0.2.3-review.1

Branch: `codex/ux-simplification`, based on `codex/default-window-drag`.
This is a separate review candidate, not a merged/public release. The installed
client is deliberately not overwritten while review is pending.

## Accepted audit findings addressed

- Nine main pages retained. Windows has Display, Layout, Appearance and Co-op / test
  subpages. The selected subpage persists; the viewport resets when switching.
- Active dragging stays the default; a saved lock is optional. Previews describes
  the distinct hidden-frame/combat-area arrangement action. Updated EN/FR help.
- Passive teammate cards do not hide native interactions by default. The explicit
  advanced replacement option is off by default, including existing configurations.
  Missing HP hides the passive card and restores the native frame.
- Experimental sharing has its own section and observed status. No claim that an
  available send function or queued packet proves live transport delivery.
- Mode HUD is compact (rank/zone), hidden without native rank by default. Historical
  rules remain a labelled 0.121 tooltip; they were not updated without new evidence.
- Selected-card dimension sliders expose actual minimum ranges; height states its
  readability minimum. Fonts are not stretched and all visible rows remain available.
- Optional Essential HUD preset changes only eight visibility choices. In-memory
  Undo restores the previous choices, including disabled money. Existing explicit tally-replacement preference is respected; the preset does not enable it.
- Local spell details are accessible from the own meter without requiring a group.
  Pin retains a player identity through rank changes and pointer exit; Escape,
  close, run exit, source collapse/hiding and arrangement release the detail.
- Original option descriptors use stable ids instead of fragile positional indices.
- Both READMEs now describe the current journey, commands, data limits and candidate
  versus public package. Historical version changes remain in CHANGELOG.md.

## Automated evidence

`tests/ux_simplification.lua` exercises real constructors and UI handlers for
subpage routing/hidden controls, small-screen scrolling, bounded widget allocation,
no native writes during navigation, reversible visibility preset, reordered schema,
mode fallback, EN/FR labels, pinned identity and solo details. Python adds saved-state
reload of the selected subpage; native Lua 5.0 runs the same fixture.
Existing behavioral, provenance, privacy, Lua compatibility and layout tests remain.
No live game, frame-rate or real peer-transport result is claimed.

## In-game acceptance before merge

1. Confirm `0.2.3-review.1` in the candidate; test both languages at 1920×1080 and
   around 800×600, including tab labels, text clipping, scrolling and close controls.
2. Drag active cards without settings; lock/unlock, group/unlink, resize to the
   displayed minima, collapse and reload. Verify source positions remain yours.
3. Switch all four Windows subpages, close and reopen, then restart. Verify the
   selected subpage, dimensions, opacity and grouping persist.
4. Apply Essential HUD, inspect the visible set, Undo. Other addons, styles and
   anchors must remain unchanged. Check interactions with the native meter/ASBuilder.
5. In solo, hover local spell rows, Pin, move the pointer away, scroll and press
   Escape; reopen. In co-op, pin an ally and change rank: identity must not switch.
6. Enable teammate cards. Native unit interactions must remain available by default.
   If testing explicit replacement, disable it to recover originals; test missing HP,
   leave/rejoin, host and guest. No duplicate unknown-health card should remain.
7. Inspect mode rank/zone and unknown-mode hiding; historical mechanics remain
   explicitly labelled. Do not treat them as current affix detection.
8. Only if testing sharing: both players opt in; compare received snapshots against
   the originating native counters. Collect `/fieldkit sync` if nothing arrives.
   Unconfirmed delivery remains a release limitation, not a passed feature.

Approval of this branch and any release remains the maintainer's decision after
these checks. Do not merge, tag or replace the public package automatically.
