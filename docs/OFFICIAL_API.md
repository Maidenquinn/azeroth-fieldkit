# Alignment with the supplied official addon API

Source: **Azeroth Survivors: Addon API**, supplied as `addon_docs.md`, examined
2026-10-27. SHA-256 of the exact supplied document:

`aff3458784b492610c394693b57dadd9835f5cbfee84171ea305dbd893a8d9df`

The full document is not redistributed here. These notes describe how FieldKit
uses its contract. Source access, documentation and API availability do not
constitute specific addon approval or a grant of code/asset rights.

## Refresh cadence

The Raw addon messages section describes at most five updates per second, sent
when data changes. FieldKit therefore polls run snapshots at 0.2 seconds instead
of rebuilding money/pins/lair data at 0.05 seconds. It coalesces delayed frames
into a single current snapshot, without replaying a backlog of obsolete updates.

This rate is not applied indiscriminately. AZS_GetDebuffs(id) calculates remaining
time on each call, so its existing 0.05-second refresh is retained. Critical text
and the low-health pulse animate per frame. Native total DPS can change as the
run clock advances even when the damage-list stamp is unchanged; the getter is
still read at 5 Hz, while unchanged spell rows avoid reconstruction.

## Change stamps and static appearance

The Tables section defines `*_UPDATED` as the GetTime of the last change. Static
portrait selection is cached per frame only when a numeric unit stamp exists,
alongside native table identity, zone, name, kind, instance id and UI language.
Changing the stamp/table/identity/language invalidates the selection. Without a
numeric stamp the older uncached scan remains, including in-place display checks.
Every live entity retains its own frame identity/HP. No target-bound portrait or
new data source was introduced.

## Run lifetime and counters

The Limits and tips section warns that tables can retain values out of a run.
FieldKit checks the native phase before showing run-owned stats, equipment,
money, meters, lairs, pins and the run shield. It also guards compact-bar docking
so it cannot reshow the previous run's money strip. Ordinary unit HP and native
inventory APIs remain separate from the stale run-table problem.

The AZS_RUN section defines `ck` as caches opened. When available, that exact
count takes priority over historical gold-spending inference. The native next
price still takes priority. The bounded legacy fallback is retained for clients
that do not expose these fields.

## Time and pausing

The run-clock function stops while paused or choosing. Lair `left` is a native
remaining value updated when changing (once per second while awaiting a fill).
FieldKit displays that value directly instead of subtracting GetTime wall-clock
seconds. It does not predict a spawn or declare a return before confirmation.
Boss debuff timing continues to use the native getter, which handles run time.

## Already-parsed data

The Raw addon messages section says the game's parser is registered before addons.
The AZS stats listener uses AZS_STATS when available instead of parsing the same
payload again. The bounded parser remains only as an older-client fallback.
Timestamp/table checks and polling also tolerate a later table refresh.

## Limits that remain

- No unit GUID API or stable unit-token → spawn-id mapping is documented. The
  independent portrait solution remains a versioned static appearance catalog.
- Native chest positions and lair positions are explicitly exposed. A lair pin
  is a fixed lair location, not the guardian's moving position.
- Rune banners describe pickups. No table/API for live ground-rune positions is
  documented. No rune tracking has been added.
- Store-Level-Ups functions and example automation are outside this optimization;
  no gameplay/progression writes were added from the document's examples.

## Evidence and practical limits

`tests/official_api.lua` exercises the actual modules in the mock under Lua 5.1
and native Lua 5.0.3. In 20 simulated 50 ms ticks it observes five snapshot jobs
and twenty debuff refreshes. It checks frozen lair values during pause/choice,
exact cache counts, stale-data hiding, pre-parsed stats, native DPS refresh and
portrait-cache invalidation/fallback. These are behavior/call-count checks, not
an in-game performance measurement or certification of the current engine.
