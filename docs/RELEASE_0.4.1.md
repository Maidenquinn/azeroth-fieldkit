# Azeroth FieldKit v0.4.1 — Native chat customization and HUD drag fixes

Date: 2026-11-05. The maintainer confirmed the integrated v0.4.1 in-game recipe, including chat, HUD drag, French/English settings and persistence.

## Changes since 0.4.0

### Main native chat
- Chat presentation now controls native ChatFrame1 without adding a second chat surface.
- Move with the compact handle, lock and restore its position; saved placement survives reload.
- Change width, height, maximum retained lines, font face/size, background color and opacity.
- Optional text-color override for incoming lines; the native per-channel colors remain available when disabled.
- Native layout/font setters may discard rendered lines. FieldKit tracks a bounded temporary history of incoming messages and restores known lines without duplicate copy capture.
- Recoloring existing visible lines is **conditional**: it is permitted only if every visible line can be reconstructed from captured history or a complete native GetMessageInfo snapshot. The 1.12-derived client may not expose GetMessageInfo. Untracked old messages are preserved rather than destroyed.
- Local copy remains opt-in; button next to chat; no external uploads.

### Left HUD drag
- Linked Mode, Damage, Damage Taken and Lairs cards move together from a mouse-down/up gesture. The root's position is updated from cursor deltas rather than native StartMoving on the proxy.
- Mode's interactive rows forward mouse release, and live Mode refresh is suppressed during a linked drag.
- Linked group releases and saved placement are protected by automated tests, including a simulated client without IsMouseButtonDown.

### Localization
- Added the French translation for the new chat history/color description. No native creature, skill or protocol strings are translated.

## Final in-game smoke test

1. Back up the previous addon folder and SavedVariables; install the 0.4.1 candidate and restart Azeroth Survivors.
2. Confirm /fieldkit displays 0.4.1; change UI language EN → FR → EN.
3. Write several messages; check they remain visible while adjusting width, height, history count, font face and size.
4. Check background color and opacity; switch text colors for new messages, toggle native channel colors, and ensure older untracked messages do not disappear.
5. Open Copy, confirm recent captured messages appear once and cannot be automatically uploaded.
6. Drag the linked left HUD from Mode's header **and text rows**, Damage and Lairs. Confirm mouse release detaches immediately, all windows remain aligned and /reload preserves position.
7. Lock positions, attempt to drag again, unlock and repeat. Test independent placement if link-left is disabled.
8. Confirm Accessories/Statistics still move normally and no Lua error appears during a full run.

## Validation boundary and release procedure

Automated CI verifies source/runtime structure and simulated Lua fixtures. It does not reproduce all native UI/mouse events. The maintainer confirmed all seven integrated smoke checks on the current client on 2026-11-05. Simulated CI remains distinct from native client testing.

Publication: merge the consolidated source to main after CI and publish an immutable v0.4.1 prerelease with the runtime ZIP, MANIFEST.json, SHA256SUMS.txt and validation.json as separate assets. Preserve v0.4.0 and its assets.

Credits and rights notices: maintained derivative of MASH by Malk. See NOTICE.md, LICENSE.md and docs/PUBLICATION.md.
