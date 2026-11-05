# FieldKit 0.4.2-review.2 — Diagnostics & compatibility recipe

This candidate builds on the maintainer-accepted 0.4.2-review.1 chat stabilization without changing chat or HUD drag code.

## Purpose

Observe *how often* existing work is scheduled and whether a fixed, read-only list of optional native APIs is present. Avoid unsupported claims of measured FPS, CPU time or API correctness. No real combat benchmark has been conducted yet.

## Commands

- `/fieldkit diag on` — enable counters for this game session; resets the counters.
- `/fieldkit diag report` or `/fieldkit diag` — display frame callback counts, accumulated reported frame delta, maximum frame delta, snapshot ticks, scan ticks, layout passes, and nameplate operations.
- `/fieldkit diag api` — show the count of present native API functions and a fixed list of missing names. Presence does not mean behavioral support.
- `/fieldkit diag reset` — reset all counters, keep recording if active.
- `/fieldkit diag off` — disable and clear counters.

Diagnostics are disabled by default and are not persisted in FieldKitDB. The counters are in-memory only, have a fixed size and do not inspect players' data, messages or other addon frames. Reports are local chat messages only. There is no outbound traffic.

## Architecture and limitations

The existing FieldKit controller update loop records an opt-in count for the current callbacks and scheduled work. No new OnUpdate ticker or native API hooks are installed. Disabled diagnostics short-circuit immediately. The maximum frame delta reports a frame interval received by Lua, not addon CPU consumption or an accurate FPS meter.

The native API report uses 12 named function probes. Any missing symbol is normal on an older client and does not cause an error. These probes cannot confirm live co-op delivery, data freshness, or native API semantics.

## Manual recipe

1. Back up the installed addon directory and SavedVariables. Install the review ZIP and restart.
2. Confirm the header reads `0.4.2-review.2`, no Lua error and unchanged chat/HUD presentation.
3. Run `/fieldkit diag`: should report OFF, zero counters. Play briefly; verify remains OFF.
4. Run `/fieldkit diag on`. Wait a few seconds in an active run, then `/fieldkit diag report`: counters should rise. Save or screenshot the output.
5. Run `/fieldkit diag api`: no Lua error, fixed set of optional native functions. A missing function is a reported limitation, not a failure.
6. Run `/fieldkit diag reset`, then report: counters zero. Run `/fieldkit diag off`, verify no counters are recorded afterwards.
7. Check chat font family/size, width/height, off/on recovery, text colors, copy button, and `/reload`.
8. Drag Mode, Damage and Lairs together; confirm mouse release and saved positions. Verify Accessories and Statistics unchanged.
9. If possible, compare perceived smoothness and reported counters in a busy run with diagnostics OFF versus ON. Do not report a numeric FPS gain without an independent frame-rate measurement.

## Automated validation

The toolchain runs static Lua capability checks, Python-driven Lua 5.1 fixtures and packaged distributable verification. The optional separate native Lua 5.0 path loads Diagnostics.lua and executes the diagnostic fixture as well.

**Not a release** until maintainer accepts the client test and existing PR chain is consolidated.
