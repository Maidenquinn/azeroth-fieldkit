# Verification and in-game acceptance

## Repeatable offline checks

Use Python 3.12+ and `pip install -r requirements-dev.txt`, then:

```sh
python tools/audit.py
python tools/verify.py
python tools/verify.py --lua50 /path/to/lua50
python tools/package.py
```

The optional Lua interpreter must be an independently available **Lua 5.0.3**
executable. It is not shipped, downloaded or launched by the addon. The local
maintainer run used both Lua 5.0.3 and lupa's Lua 5.1 runtime. CI runs Lua 5.1
through lupa and performs the structural/prototype checks; it does not claim
native Lua 5.0 or live-game coverage unless that job is explicitly added.

`audit.py` inspects all TOC Lua files, rejects selected dangerous runtime
capabilities and unsupported strings, checks data-only textures and generates
the function index/inventory. Its tokenizer deliberately rejects long literals
until reviewed. This token gate is a regression guard, not a formal proof of
safety or an adversarial malware scanner.

`verify.py` executes the actual runtime files in a mock, then checks:

- all settings tabs select their own pages; EN/FR switches and callbacks;
- target-independent portraits across 1,063 aliases / 100 definitions / 12 maps,
  unknown/conflicting displays and simultaneous instances;
- health formats, collapsed windows, positions and saved settings on reload;
- native gold/chest strip, intentional detachment and lost-anchor repair;
- chest/guardian toggles, native axes, edge pins, square-map option and absent CVar;
- combat categories, filtering, ability exclusions, style/font/position controls,
  grouping, saturated bursts, lifetime/fade and native-healing counter resets;
- opt-in/opt-out main-chat capture, 100-message bound, 512-byte message bound,
  clearing editbox/memory, unaffected other chat frames and original forwarding;
- both the legacy forwarding and simulated secure-hook paths under Lua 5.1;
- CVar allowlist, missing CVars, finite numeric validation and malformed DB shapes;
- disabled-filter WorldFrame noninterference and enable/disable restoration;
- no native talent-state overwrite during repeated initialization;
- native action-slot calls happen only for an explicit drag onto another button;
  idle updates and dropping outside make no slot changes in the mock;
- all nested Lua 5.1 prototypes fit the 32-upvalue limit (current maximum 23).

The official-API fixture additionally checks 5 snapshot batches per 20 simulated
50 ms ticks, 20 debuff refreshes, paused/choosing lair counts, native cache counts,
out-of-run stale-data suppression (including compact docking and shield), native
preparsed stats, changing total DPS without a changed meter stamp, and portrait
cache invalidation. These are mock call counts, not measured FPS gains.

Native Lua 5.0.3 runs the same core behavioral/privacy/UI fixtures in
`tests/native50.lua`. The Python-hosted reload test and secure-hook simulation
are additional Lua 5.1 checks. Tests use explicit mock native data; they are not
a recording of a real run or evidence that every client API behaves identically.

## What remains untested

The renamed candidate has not been tested inside the running game. In particular,
no claim is made about current-client menu approval, live frame strata/reparent
behavior, action-slot drag integration, every resolution/map, engine texture
decoder safety or FPS/memory use during dense combat. Old MASH user confirmations
must not be rebranded as FieldKit acceptance results.

## Authorized in-game checklist

1. Obtain authorization to load the review candidate, disable MASH, and record
   the exact client build, candidate hash, UI language and enabled options.
2. Fresh configuration: confirm sensitive features/audio/chat are off. Verify
   stock plates, HUD, camera, native damage numbers and stock action bar remain.
3. Open `/fieldkit`; click every tab and close button. Switch EN/FR, reopen,
   resize and reload. No text/layout options should duplicate the combat editor.
4. Move/collapse each addon window; inspect saved positions, collapse state and
   gold/chest strip after reload. Check native HP/shield against the addon display.
5. Preview combat categories (clearly marked samples), then test actual damage,
   healing, grouping, filters/exclusions, fonts, sizes and two scroll areas.
6. If approved, enable boss replacement. Change/clear target during boss combat;
   verify independent portrait and distinct HP for duplicate instances. Test
   unknown appearances and representative scheduled/final bosses on each map.
7. If approved, enable chest and lair pins separately. Check positions, edge
   directions, zoom, rotation, tooltip and respawn-confirmation behavior. A lair
   is not a moving guardian. No rune location should be invented.
8. If approved, enable nameplate filtering. Exercise V, spawning/reused plates,
   speech bubbles and disable again. Check native parent/scale/alpha restoration
   and conflicts with other authorized addons.
9. If approved, enable compact bar. Explicitly swap two native action slots by
   dragging; verify that a drop outside does nothing, native clicks still work,
   money/XP remain visible and disabling/reloading restores the stock layout.
10. Exercise optional camera/damage/audio switches. Record which native settings
    persist and restore player preferences before uninstalling.
11. Optional privacy test with non-sensitive sample text only: capture is off,
    enable it, open `/fieldkitlog`, verify older text absent, then disable and
    confirm clearing. Exit normally/reload: chat content must not be persisted.
12. Profile a dense authorized run. Record frame time/memory and any Lua errors.
    Report failures with minimal data; never attach private chat or game saves.

Update the acceptance record per candidate hash. Passing a previous candidate
does not approve a changed ZIP or establish author/asset distribution permission.

## 0.2 interface acceptance

0.2.2-review.6 supersedes the previous movement model: window_lock.lua now
asserts ordinary default dragging before settings have even been constructed,
no dock/preview from lock/unlock shortcuts, the saved Windows checkbox, stopping
active group/independent drags, and temporary explicit arrangement override.
The Python runner reloads the saved locked preference. In game, drag active
windows immediately after startup with settings closed; check saved groups,
then lock/unlock in options and verify persistence after reload. Hover details
should remain available at rest and close only when a drag actually begins.

0.2.2-review.5 window_lock.lua covers lazy settings construction, lock/unlock
commands, case normalization, minimap right/left clicks, internal versus external
Done, explicit sizing navigation, Escape and locking during group/individual/
combat-area drags. The existing edit gate remains session-only. In game, test
right-clicking the minimap shortcut and issuing commands during a drag; confirm
positions survive reload and no parameters panel appears after external Done.

0.2.2-review.4 adds party_sync.lua plus an explicit two-VM simulated PARTY relay
in tools/verify.py. Validate opt-out/default silence, fixed channel/prefix/rate,
ASCII escaping, large exact integers, out-of-order fragments, duplicate/replay
and malformed inputs, source/body caps, stale runs and shared-view rendering.
Hover surfaces must now follow both HUD presets and opacity, without changing
settings surfaces. These are protocol tests, not native-network tests. Follow
PARTY_SYNC.md with two opted-in real clients before claiming complete peer spells
work in this game's co-op. A successful native call without a response is not a pass.

For 0.2.2-review.3, party_details.lua checks a 23-source local list versus a
peer's sole top spell, unknown peer damage/share, paging by wheel/buttons, gap
crossing and delayed close, opaque materials, re-hover without new frames,
right-edge anchoring, rank reorder, collapse/layout close, missing API and the
explicit 512-source safety cap. In-game acceptance: hover each group member,
cross onto the card to scroll, use the name-row wheel, move the meter to screen
edges, change resolution/UI scale, let group ranking change and verify displayed
identity. Compare your own spells with the local native meter; do not treat an
ally's labelled top-spell-only view as their full damage breakdown.

The 0.2.2-review.2 `coop.lua` fixture covers missing/incomplete source buckets,
native total changes without source stamps, unknown versus zero, malformed data,
peer damage/DPS and missing rates, duplicate/departed players, new-run freshness,
offline/zero-HP cards, individual movement/size, opt-in original-frame hooks and
restoration. Execute it under both Lua versions. Native unit/network delivery and
real frame interactions are not mocked into a claim of in-game success.

Live co-op recipe: enable teammate cards in Health & buffs; inspect HP/resources
against the originals, drag/resize each slot, change roster, down/revive a peer,
disconnect/reconnect, start another run, and toggle the replacements off. Check
the group meter against native party totals and its received-player count. Check
Damage taken against the native total on host and guest clients. If either data
source is missing, retain the explicit unknown/unattributed state and collect
`/fieldkit coop`; never infer missing damage from healing or HP changes.

For 0.2.2-review.1, `individual_layout.lua` tests independent movement, left/right
group routing, bounded dimensions, every card's width/height controls, unchanged
native-meter refreshes, collapse, auto-size reset and retained native anchors.
The Python runner also serializes/reloads the settings. In the client, exercise
all seven cards at your UI scale: toggle each group, move cards to all four edges,
resize each card, change meter format and visible stats, collapse/reopen, reload,
and verify that totals, tooltips and settings opacity remain unchanged. Test both
compact-bar states; a detached money strip must not snap back. No live success
is claimed by these fixtures.

Follow [UX_REVIEW.md](UX_REVIEW.md) for the new page/layout journeys. The automated
interface fixture additionally verifies exclusive HP choice, no automatic reload,
no native writes during language/reflow, no resize allocations, wheel bounds,
reset/Undo and independent money-strip hiding. Native scrollbars, custom fonts,
visual clipping, keyboard focus and screen resizing still need in-game review.

For the unmerged 0.2.3-review.1 journey, use [UX_SIMPLIFICATION.md](UX_SIMPLIFICATION.md).
