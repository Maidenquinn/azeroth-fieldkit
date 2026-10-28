# Optional party spell sharing — 0.2.2-review.4

Current published update: **0.2.3** (GitHub prerelease). The protocol below is unchanged; controls now live under **Windows → Co-op / test**.

## What changed

The inspected 0.123.0 API exposes only `top` and `topdps` for each peer in
AZSPARTY, not a per-peer spell list or damage for that top spell. The new option
asks another consenting FieldKit client for its **own native meter snapshot**.
This is a new communication capability, not an extension of the game's API.
The maintainer explicitly authorized optional entirely in-game synchronization
on 2026-10-28. That authorization is not a game-team approval of this changed ZIP.

## Required real-client test

1. Both players install the same version (currently 0.2.3) and restart the client.
2. Both enable **Windows → Co-op / test → Share spell breakdowns with group**. It is off by default.
3. Join the same co-op run. Hover the other player's Group damage row and wait
   several seconds for the requested snapshot. Repeat in the other direction.
4. On both clients, run `/fieldkit sync`. `txAccepted` means only that the native
   function accepted a call. `seen` counts this prefix reaching the event handler,
   `rx` counts structurally eligible packets, and `complete` counts assembled,
   validated responses. A received shared card must show its receipt age.
5. Compare the shared spell list/damage/DPS with that player's own native meter.
   Test a new run, roster changes, opt-out, hovering and switching style/opacity.

**Transport is not confirmed in real co-op.** A SendAddonMessage binding is
present in the inspected executable; the available older engine source sends
through the WoW network command path. Neither proves that the current standalone
co-op forwards it. The offline two-client test simulates delivery explicitly.
An accepted call, an installed addon or the Discord role is not delivery proof.
If both updated, opted-in clients remain at `seen=0`/`complete=0`, report both
diagnostic lines; do not advertise full peer details as working. A native peer
detail export or a game-supported addon transport would then be needed.

No companion program is required. No visible chat fallback is used: unsupported
transport must not flood party chat with encoded statistics.

## Protocol and boundaries

- Fixed prefix `AFKDETAIL1`, distribution **PARTY** only, never guild/whisper/HTTP.
- `Q:id:encodedTarget:runTime` requests the named player's own snapshot.
- `R:id:part:count:chunk` carries printable ASCII fragments. Names are percent
  escaped, including reserved separators, non-ASCII bytes and WoW pipe escapes.
- At most 230 bytes per body and four native calls/second through Runtime.lua.
  At most 80 queued bodies, 64 response fragments, 12,000 reassembled bytes,
  128 spell sources and one assembly per requested roster peer.
- A peer accepts only requests addressed to itself, from a current party member,
  with a nearby native run clock. Responses require a pending request nonce,
  matching sender/channel, valid bounds and a complete parsed snapshot.
- Per-peer requests/responses are limited to one every ten seconds. Received
  snapshots expire after twenty seconds; pending batches also expire at twenty.
  Requests are driven by hover, not continuous broadcasts of every player's data.
- Partial safety-capped snapshots are labelled partial. Numeric damage is sent
  with sufficient precision for the bounded native integers, never derived from DPS.
- No eval, arbitrary command, target/cast/movement action, chat history, world
  location, account identifier, save or credential belongs to the protocol.
- Data stays in bounded in-memory caches. Only the opt-in preference persists.
  Opt-out, run boundaries and departing roster members clear applicable state.

The receiving sender field is supplied by the game; it is not a cryptographic
signature. Other addons sharing the Lua VM can falsify globals or events. Peers
can misreport their own data. This feature is not an anti-cheat or authentication
system, and earlier no-messaging claims do not describe this optional capability.

## Presentation

The hover card now follows Classic/Decorative and card background opacity.
Full shared snapshots use the same damage/DPS/share columns as the local view,
with a receipt-age label. Without shared data, native fallback shows the top
spell's **known DPS only**, not empty damage/share columns pretending to be a
complete breakdown. Settings continue using their separate opaque surfaces.
