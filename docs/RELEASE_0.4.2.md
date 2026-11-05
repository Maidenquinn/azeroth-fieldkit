# Azeroth FieldKit v0.4.2 — Chat stability and diagnostics

Released 2026-11-05. This version consolidates three in-game reviewed lots on Azeroth Survivors. The previously validated grouped HUD drag remains unchanged.

## Native chat
- Improved preservation of captured messages through temporary chat customization off/on cycles, using a bounded in-memory display journal (maximum 500 entries).
- Width, height, font size and font family work again after fixing the regression introduced during the review cycle.
- Existing messages are recolored only when the visible history is safely recoverable.
- Optional copy history (up to 100 messages) is independent of the display journal. Neither buffer is saved to disk or uploaded.
- Native lines predating capture may still be unrecoverable on older clients without a complete native history-read API.

## Opt-in runtime diagnostics
- `/fieldkit diag on`, `report`, `reset`, `off`: session-only counters for update-loop activity, snapshots, scans, HUD layout and nameplate refreshes.
- `/fieldkit diag api`: presence of 12 allowlisted native API methods.
- `/fieldkit diag compat`: passive native chat and linked HUD method/container checks.
- Disabled by default; no networking, persistence, invasive hooks or scheduling changes.
- Reported frame delta and counts do NOT measure exact addon CPU/FPS; presence does not prove functional compatibility or discover every addon conflict.

## Verification
- CI static capability audit, simulated Lua behaviors and distribution packaging.
- Maintainer confirmed the chat regression fix and diagnostics on the actual game client, including the compatibility command; previously validated HUD drag unchanged.
- English/French help text improved.

## Installation and attribution
Back up AddOns/AzerothFieldKit and SavedVariables, replace the addon folder from AzerothFieldKit-0.4.2.zip, and restart. v0.4.1 remains available.

Maintained derivative of MASH by Malk. Refer to NOTICE.md, LICENSE.md and docs/PUBLICATION.md. No independent security certification or game-team rights clearance is asserted.
