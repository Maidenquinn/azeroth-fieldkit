# Azeroth FieldKit 0.3.4 — chronicle HUD, meter suite and settings split

Changes since **0.3.2**. Maintainer accepted for publication on 2026-11-02; GitHub
prerelease maturity is retained. FieldKit remains a maintained fork of **MASH by Malk**.
Saved preferences and run data formats are unchanged (V1/V2 roundtrip preserved).

## What's new

- **Combat meter suite:** tabbed damage / healing / boss / taken / party / kills,
  optional mid-run Reset (native checkpoint when available), column sort, hide rows,
  heal done vs received, party drill-down, pet/DoT combat-log hits, Max Hit–style
  spell tips. Same-name ranks merge via native `abilityKey` / key stripping.
- **Boss schedule timeline (opt-in):** Chronicle rail with zone title, run clocks,
  upcoming seals only, large next-boss countdown (replaces the native run clock
  while shown; off by default so fresh installs leave the native clock alone).
- **Boss frames:** FieldKit Chronicle chrome, portraits, name/HP above the bar,
  role tags under the bar, no text overflow outside the plate.
- **Settings journey:** mega Windows page replaced by thin HUD sections — HUD cards,
  Combat meter, Layout & arrange, Look, Co-op — under clear sidebar groups.
- **Stability:** Effects window no longer sticks to the mouse during timer refresh;
  choice screens still yield the FieldKit HUD; guardian/timeline clock handoff kept.
- **Combat text:** optional native “Show Target Damage” switch surfaced in Combat text.

## Update and evidence

Download **AzerothFieldKit-0.3.4.zip** from Assets, not the Source code ZIP. Back up
and replace the existing FieldKit folder in the launched client's AddOns directory,
keep your saved preferences and restart. Disable legacy MASH if still enabled.
No external program or extra addon is required.

Static inventory and Lua **5.0.3** / **5.1** behavioral checks pass. No new
agent-performed in-game rendering, performance, affix-encoding or co-op transport
test is claimed. Existing credits and rights notes are retained.
