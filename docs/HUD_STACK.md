# Run mode card and left-card alignment

Candidate 0.2.1-review.2. The user screenshots showed that the previous fix aligned
numeric columns but left whole card widths and lair anchors different. This change
addresses the card rectangles and their shared movement, not just row text.

## Geometry and interaction

One transparent one-point anchor owns the top-left of the linked HUD. Visible
cards are ordered Run mode, Damage, Damage taken, Lairs, all at the width selected
by the meter display mode. Six pixels separate visible cards. Collapsed cards use
their header height; hidden cards take no space. Geometry follows current heights
and reuses anchors when unchanged. It never reparents another addon's frames.

Drag handlers on any member forward to the same anchor while Move windows is
active. Original handlers remain available when unlinked. The initial anchor is
migrated from the saved damage card position; original individual coordinates
are preserved. New position uses `FieldKitDB.pos.FieldKitLeftStack`. Reset/Undo
includes this new UI position, with canonical defaults kept separately. The
group is clamped into the viewport when its full dimensions fit; it is not scaled
down to unreadable text. Exceptionally tall content can still exceed a very short
viewport; collapse/disable cards or use the independent layout in that case.

## Mode information: two distinct sources

- **Live native fields:** current rank from `AZS_ZONE.heroic` and zone name/key.
  Missing rank is displayed as unavailable; retained data outside a run is hidden.
- **Reference:** cumulative fixed mechanic descriptions from the supplied
  0.121.0 changelog, native client strings and difficulty screenshot. The card
  explicitly labels the reference version, shows up to four latest mechanics,
  and lists all cumulative mechanics in its tooltip. Tier I: warnings/packs;
  II: relentless/sentinels; III: purse/horde affix; IV: old mechanics/unforgiving;
  V: withering/council. This text is not a live measurement of mechanic state.

No current affix identity, enemy multiplier, reward amount or progression state
is inferred. The current screenshot's weekly affixes are not hardcoded: they
change, and the client API inspected has no confirmed live export for them. The
Elwynn multipliers shown in that menu are not silently applied to other zones or
co-op. The tooltip explicitly notes that these live values are not supplied.
Reference rules may require maintenance after subsequent client updates.

## Verification and limits

Actual constructors and callbacks execute in `tests/mode_stack.lua`, under Lua
5.0.3 and 5.1. Fixtures check common widths and exact anchors for all four cards,
collapse gap removal and immediate expansion, hiding/re-enabling mode, display
width changes, shared drag forwarding, retained coordinates on unlink, Heroic V
unknown affix identity, missing rank, Normal and out-of-run hiding. Existing
tests still cover native filtering, portraits, privacy, persistence and opacity.

In-game acceptance remains required: inspect all four card edges, collapse each
card, hide damage or mode, change number mode, drag the group through each card,
toggle linking, change language, resize and reload. Compare the mode rank and
reference rules with the native Difficulty screen. No new live-game test or
approval is claimed for this candidate.

## Edge correction in 0.2.1-review.3

The supplied 8-second video shows the accessories/stats group moving and then
repositioning on release near the screen edge. The old drag-stop handler read
frame/UIParent centers, subtracted them, then re-clamped and reapplied a center
position. This conversion is removed. The revised path retains native GetPoint
anchors and offsets, following the existing Azeroth Stats persistence pattern.
It avoids mixing those coordinate spaces and supports zero-offset edge anchors.

`FieldKitDB.frameAnchors` is validated independently of legacy `pos` entries and
wins on restoration after a new drag. Only UIParent/implicit-viewport anchors are
accepted; no external frame pointer is serialized. Unexpected anchor references
are left untouched rather than forcibly recentered. Reset/Undo includes native
records. Existing saved variables are never edited directly by installation.

The linked proxy now has the full group width/height, delegates bounds to the
native client and imposes no 12-pixel margin. Children disable their independent
clamps while linked. The proxy never receives mouse input; visible cards still
forward explicit layout drags. Native edge anchors retain their semantics;
vertical middle anchors can be stabilized against changing row counts.

This supersedes the one-point proxy/manual-inset description above. Tests replay
native anchors at all four corners and make GetCenter fail deliberately; verify
exact restoration, group dimensions, mouse/clamp flags, native right pinning,
reset/Undo and serialization/reload. They do not simulate or certify the client's
native clamp algorithm. The corrected build still needs in-game acceptance at
the viewport edges and at the user's actual UI scale/resolution.
