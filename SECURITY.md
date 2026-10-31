# Security and player-risk assessment

**Assessment updated:** 2026-10-28. **Published update:** 0.2.3 (GitHub prerelease).
This is a maintainer's source review and automated verification, not an
independent security certification, a guarantee of no bugs or game approval.

## Scope and evidence

The hover card now follows HUD style/opacity. Native peer details remain limited,
so 0.2.2-review.4 adds an explicitly opted-in PARTY-only snapshot protocol in
PartySync.lua. Both players must enable it. Runtime.lua is the sole send boundary:
fixed AFKDETAIL1 prefix, PARTY channel, printable packets up to 230 bytes and at
most four calls per second. Only own per-spell damage/DPS/share is shared on
request. No chat text, positions, account information or saves are transmitted.
Payloads are never evaluated as Lua. Peer caches are memory-only and reset on
run exit/regression, opt-out and roster departure. Native sender membership and
request nonces are checked, but other addons in the same Lua VM can still forge
events or globals. The two-client test uses a simulated transport: real co-op
forwarding is unconfirmed. This new capability requires reviewer attention;
earlier publication permission is not an automatic approval of this candidate.

Co-op addition: `Coop.lua` reads native party-unit and group-meter snapshots.
With explicit user opt-in it wraps/hides only PartyMemberFrame1–4 while valid
replacements are available, preserving their original OnShow callback and
restoring it when disabled. No targeting, casting, gameplay-state write, external
helper or addon-message sending is introduced. These native UI hooks can conflict
with another party-frame addon; disable one replacement and reload to isolate it.
New freshness/fallback and restoration fixtures run offline under both Lua
versions; this is not a live multiplayer test or an independent security audit.

The baseline is the full installed MASH 1.3.9 folder, copied and hashed before
editing. Every TOC-loaded Lua file and catalog was inspected; portrait assets
are checked for expected uncompressed TGA format/size. The fork's full runtime
file list and hashes are in its generated release manifest. The exact baseline
is retained in Git history and docs/UPSTREAM_MANIFEST.json.

The scope excludes the host client's correctness, launcher approval engine,
other addons, old workspace experiments and game binaries. The reason the game
flagged MASH has **not** been provided: findings here must not be described as
the developers' reason for deleting it.

## Findings and changes

### F01 — Native talent state written during load (removed)

MASH saved `AZS_TALENT_TOGGLES` into its DB at logout, then could overwrite the
client-owned global during addon load. This was unrelated to HUD rendering and
could restore stale gameplay-selection state. No exploit or progression bypass
was demonstrated. FieldKit removes both lifecycle branches and the related
stored fields. Its runtime makes no assignments to native AZS_* globals.

### F02 — Unsolicited chat capture (changed to explicit opt-in)

MASH installed chat-message hooks at load and kept up to 350 messages per frame
in memory. There was no observed network upload or SavedVariables persistence,
but private text could be captured without an explicit privacy choice.

FieldKit installs the main-chat hook only after opt-in, retains at most 100 × 512
bytes, and clears the table/editbox on disable. Other chat windows are not hooked.
Messages received before opt-in or after opt-out are not retained. The settings
tooltip discloses whispers. The only export is a manually opened local editbox.
The legacy forwarding wrapper may remain installed after opt-out, but its capture
guard is inactive. It is intentionally not torn down over another addon's hooks.

### F03 — Shared WorldFrame/nameplate interference (mitigated; still sensitive)

The inherited filter changes WorldFrame alpha and reparents native frames to avoid
new-plate flicker. It formerly forced alpha even when filtering was disabled.
FieldKit defaults it off, does no WorldFrame writes while it remains off, and
restores the saved alpha/parent/scale for frames it moved when turned off.
The enabled filter still operates on shared native UI and wraps HideNameplates.
This remains an integration risk and an explicit approval question.

### F04 — Weak input/settings validation (hardened; not exhaustive)

Corrupt persisted values or malformed/oversized events could produce arithmetic
errors and expensive parsing. FieldKit normalizes the main DB shapes, health
modes and position tuples; rejects NaN/infinity/out-of-range numbers at key
boundaries; bounds combat/stats text, learned names and pending groups; and
retains bounded display pools. The old native map-calibration path and its
map-selection side effect were removed.

Native client tables are still expected to follow the documented AZS API row
shapes. This is not a complete hostile-table parser or a sandbox against another
addon that can replace functions/globals. Size bounds and fixtures do not prove
resilience to every possible mutated Lua object.

### F05 — Unavailable CVars causing UI errors (guarded)

Some custom clients throw for unknown CVars. Runtime.lua catches failures and
only allows writes to `cameraDistanceMaxFactor`, `CombatDamage`, `PetMeleeDamage`
and `PetSpellDamage`. Camera values are bounded; damage switches accept 0/1 only.
WorldPins handles unsupported rotation without an uncaught CVar error.

### F06 — Inherited ownership and asset rights (unresolved licensing issue)

No applicable upstream license or author permission was located in the inspected
material. Portraits/data derive from native game resources. Renaming does not
resolve either issue. NOTICE.md and LICENSE.md preserve the distinction between
Malk's original project, later community changes and this maintained fork.
The maintainer requested public technical review; the unresolved rights are
still disclosed and no upstream permission or license grant is asserted.

## Optional communication and capabilities not found

Party-only addon messages are now the one opt-in communication exception, as
documented above. The static gate allows the native send identifier only in
Runtime.lua; direct use in other modules remains forbidden. Tests cover opt-out,
channel/prefix/size/rate bounds, malformed fragments, replays, fresh-run nonces
and exact integer damage. Successful API calls are not labelled as delivery.

Source inspection and the static token gate find no network library, HTTP client,
visible chat sending, shell/process launch, process-memory reading, direct
filesystem I/O, runtime dependency loading, downloaded updates, dynamic code
evaluation or obfuscated executable payload. There are no executable/DLL files
or external helpers in the addon ZIP. TGA assets are images, not Lua chunks.

FieldKit does not invoke casts, UseAction, targeting, movement or item-equip
automation. **It does call PickupAction/PlaceAction to exchange two action slots
after an explicit player drag in the optional compact bar.** It is therefore
inaccurate to claim that it only reads game APIs or never changes native state.

Developer tooling uses Python, local files and Lua compilation to test/package
the project. Those capabilities are separate from the TOC runtime, and the
runtime ZIP excludes tools, tests, developer dependencies and historical files.

## Residual risks requiring a decision

- Native chest/lair information and independent boss-state displays may be
  considered an information advantage. API availability is not approval.
- Native UI hooks, scale/reparent changes and action-bar handlers can conflict
  with MASH or another addon. Do not enable MASH and FieldKit together.
- Camera/damage/HUD CVars may remain changed after disabling the addon. Restore
  preferred native options explicitly; there is no promised universal rollback.
- Wrong/stale native tables or future client changes can produce stale/missing
  text or portraits. The portrait catalog is version-specific.
- Combat messages can be localized/unrecognized; healing uses cumulative deltas.
  A display cannot recover events the client did not expose.
- The 20 Hz layout/debuff refresh, 5 Hz snapshot jobs and nameplate scans have not been profiled in a live dense
  run. Bounded tests are not an FPS/memory benchmark. Engine-owned frame caches
  can grow with native frame allocation even though text/pin pools are bounded.
- Another addon shares the same Lua environment; FieldKit is not isolated from it.

## Verification and reporting

See docs/TESTING.md and docs/validation.json. Tests include exact privacy opt-in,
clear-on-disable, forwarding behavior, CVar allowlist, malformed settings,
WorldFrame restoration and existing feature regressions under Lua 5.0.3/5.1.
No new test inside the running game is claimed for this candidate.

Report sensitive issues directly to the maintainer; use public issues only for
non-sensitive reproductions. Include
candidate version, client version, UI language and a minimal reproduction. Avoid
uploading game saves or private chat. For a privacy concern, disable chat capture
immediately and reload; no persistent chat history needs to be deleted.

## 0.3.0-review.1 development addition (2026-10-31)

New native tools are a development candidate, not accepted for publication. They add
passive reads and bounded native banner subscriptions. The only new native write is
explicit per-window foreground registration above level/jewelry choices, restricted
to owned names in Runtime.lua and reversed when hidden/disabled. No foreign frame,
UIParent, gameplay action, level spending, new network transport or process is added.
See [scope, defaults and remaining tests](docs/NATIVE_TOOLS_0_130.md). The older
assessment/version above remains the public 0.2.3 record.
