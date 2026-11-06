# FieldKit v0.5.0 — Lot A: reliability hardening gate

Baseline: v0.4.2 public release; alpha.12 accepted in-game. All hardening changes are on a draft branch, not released.

## Confirmed source-level observations
- `Profiles.lua` stores three slots in `FieldKitDB.interfaceProfiles`, with flat `FieldKitDB` as the live renderer contract.
- `P.Load` captures the outgoing state, autosaves the outgoing slot, applies the incoming snapshot, then refreshes the native HUD.
- `P.Init` migrates legacy snapshots in place. Migrated schema-2 slots should not require a new baseline capture on each call.
- Snapshot copy is bounded to 3,200 entries, depth 7 and 512 bytes per string; these limits protect memory but currently can silently omit unsupported values.
- Failed native HUD updates are only best-effort reversible: native client effects may outlive a Lua rollback.
- `tools/verify.py` covers mock Lua fixtures, serialization, profile isolation, UI, chat, compatibility and security. The mock is not a substitute for in-game acceptance.

## Changes in this draft
1. Explicitly restore active slot metadata on failed native HUD application.
2. Add a test that injects native apply failure and checks live values and active slot.
3. Skip full baseline capture in `P.Init` when every saved slot already has schema 2 and nil tombstones.
4. Add a test that asserts the already-migrated initialization path does not perform a numeric snapshot copy.

## Remaining risks before closing Lot A
- **P1:** bounded deep copy can omit data silently. Design an atomic, fail-closed capture before changing its semantics; ensure existing snapshots remain readable.
- **P1:** legacy migration mutates saved snapshots in place and invalid slots are removed. Evaluate non-destructive quarantine/backup before changing migration behavior.
- **P1:** native frame state may not be completely restored after an exception.
- **P2:** full snapshots are still taken on saves and profile switches; benchmark real-world impact before further optimization.
- **P2:** static preference registry is partially duplicated and dynamic keys are not formally covered.

## Verification and acceptance
- GitHub Actions: run the review-candidate workflow on the latest commit; require green before acceptance.
- Lua: run `python tools/verify.py` and native Lua 5.0 compatibility fixture where available.
- Game: back up `FieldKitDB`; test 1→2→3→1, Undo, rename, chat colors/size/history, HUD positions, logout/reload persistence, FR/EN, compact native bar limitation.
- Simulated failures must not be induced in a production SavedVariables file.
- No merge, release, or claim of completed performance audit until all gates are passed.
