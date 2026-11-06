# Azeroth FieldKit v0.5.0 — release readiness

## Accepted in-game

- Three independent HUD profiles and live switching (user-accepted earlier in the alpha cycle).
- Profile preview and return flow (user-accepted Lot C).
- Collapsed windows moved to bottom-right dock, including mode, effects and reminders (user-accepted Lot D).
- Dock drag, per-profile saved position and `/reload` persistence (user-accepted on CI #628).

## Automated verification before publication

- [x] RC.1 CI #659 green; synthetic migration CI #673 green (commit f62f921).
- [x] Profile regression tests pass, including dock position and collapsed states (CI #652).
- [x] Automated Lua 5.1 fixture and source checks pass on CI #659. Native Lua 5.0 and game-specific behavior are not fully proven by CI.
- [x] Synthetic 0.4.2-style flat SavedVariables fixture preserves settings, creates and loads a profile, and survives simulated reload (CI #673).\n- [ ] Migration from an authentic stable v0.4.2 SavedVariables file remains unverified (no copy available).
- [x] Verify known preference keys in profile capture (combat text, gryphons, money); broader migration with a real v0.4.2 save remains open.
- [x] New dock and preview labels integrated into FR/EN dictionary (CI #636); final visual review remains open.
- [x] CI #659 produced RC.1 runtime ZIP with .toc/runtime version aligned; packaging gate excludes development files.
- [x] Maintainer reported RC.1 functioning in-game on 2026-11-06.

## Publication gates

1. Review stacked draft PRs and base branches; do not merge them out of order.
2. Prepare v0.5.0 changelog from actual merged changes.
3. Produce a clearly versioned release-candidate ZIP and request final in-game approval.
4. Merge, tag and publish only after explicit user authorization.
5. Keep the future HUD redesign and performance expansion for the version after v0.5.0.

**Status:** RC.1 accepted in-game; CI #673 synthetic migration passed. Authentic 0.4.2 migration and rights/permission review remain unresolved. No public release authorized.
