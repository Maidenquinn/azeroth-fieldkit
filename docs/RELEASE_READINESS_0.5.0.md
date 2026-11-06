# Azeroth FieldKit v0.5.0 — release readiness

## Accepted in-game

- Three independent HUD profiles and live switching (user-accepted earlier in the alpha cycle).
- Profile preview and return flow (user-accepted Lot C).
- Collapsed windows moved to bottom-right dock, including mode, effects and reminders (user-accepted Lot D).
- Dock drag, per-profile saved position and `/reload` persistence (user-accepted on CI #628).

## Automated verification before publication

- [ ] Latest candidate CI is green; inspect test and packaging jobs.
- [ ] Profile regression tests pass, including dock position and collapsed states.
- [ ] Lua syntax and compatibility checks pass on packaged sources.
- [ ] Validate fresh installation and migration from stable v0.4.2 using copies of SavedVariables.
- [ ] Verify no lost keys in profile preference capture (combat text, gryphons, money).
- [ ] Review FR/EN labels and any hardcoded new dock text.
- [ ] Confirm ZIP folder structure, .toc version and manifest, hashes and no development-only files.
- [ ] Confirm that the release candidate is tested in-game (not just Lua 5.1 CI).

## Publication gates

1. Review stacked draft PRs and base branches; do not merge them out of order.
2. Prepare v0.5.0 changelog from actual merged changes.
3. Produce a clearly versioned release-candidate ZIP and request final in-game approval.
4. Merge, tag and publish only after explicit user authorization.
5. Keep the future HUD redesign and performance expansion for the version after v0.5.0.

**Status:** release preparation, not authorized for public release.
