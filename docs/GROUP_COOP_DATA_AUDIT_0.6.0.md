# Spells and accessories of group members: data audit (0.6.0-alpha.33)

Goal: let the player consult the spells and accessories that group members really **selected**, without presenting
anything observed as selected and without inventing ranks, levels or items.

## 1. Native APIs (confirmed present in the executable, see GROUP_API_AUDIT_0.6.0.md)

| Need | Native source | Verdict |
|---|---|---|
| Local player spell list | `GetSpellName/GetSpellTexture` (local spellbook) | local player only |
| Another player's spellbook | none | **absent** |
| Another player's talent/spell choice | none | **absent** |
| Another player's equipped items | `GetInventoryItemLink("party1",slot)` exists; works only if the client allows it without inspect | **to be measured**: `/fieldkit groupprobe items [notify]` |
| Another player's item use | none | **absent** |

## 2. Lua structures filled by the game (AZS_*)

| Structure | Content | Scope |
|---|---|---|
| `AZS_SPELLS` (AZSSPELLS packet) | the local player's **learned** spells with rank (`key`, `spell`, `rank`) | local player only: used for the own card |
| `AZS_PARTY` / `AZS_GetPartyMeter()` | per player: name, damage, dps, share, `top` (top spell name), `topdps` | every group member, current run; the ONLY native per-teammate spell datum |
| `AZS_STATS`, `AZS_TALENT_TOGGLES`, gear packets | local player | local player only |

Conclusion: for a teammate the game gives exactly one spell name (`top`) and its dps. No spellbook, no rank, no accessory.

## 3. Combat events

Chat messages `CHAT_MSG_SPELL_*PARTY*` carry text about what was **seen**: a cast, a hit, a heal, a buff gained, an interruption.
They prove a spell was used, never that it was selected or at which rank. They are recorded as **Observed** only
(GroupHistory.lua). `UNIT_SPELLCAST_*` does not exist in this client.

## 4. Communication between compatible addons

`SendAddonMessage` (4 occurrences) and `CHAT_MSG_ADDON` (8) are in the executable, and PartySync.lua already implements an
opt-in PARTY-only protocol (prefix `AFKDETAIL1`, versioned, rate-limited, validated, in-memory) for the meter breakdown.
`docs/PARTY_SYNC.md` states that **delivery between two real clients has never been confirmed** (`seen=0` is the expected
failure signature, `/fieldkit sync` reports it). Therefore:

**Decision: no new spell / accessory protocol is developed in alpha.33.** The stop condition of the brief applies: "verify it is
really compatible with this client before developing it". The compatibility test already exists (`/fieldkit sync` on two
opted-in clients). If it shows `complete>0`, the architecture below can be built on the same transport.

Proposed architecture (NOT implemented): a second message type on the existing channel, `S1` = the sender's own learned
spells (name + rank from AZS_SPELLS) and `A1` = the sender's own accessories (slot + item name from its own inventory);
PARTY only; version byte; per-peer rate limit (one answer per 10 s, driven by hover); bounded sizes (32 spells, 8 items);
strict parsing (printable ASCII, escaped separators, numeric ranges, current party member only); in-memory only; off by
default behind the existing opt-in; no server, no account data. Data received this way would be shown as **Confirmed (shared by the player)**.

## 5. Information available only for the local player

Spells with rank (AZS_SPELLS) and accessories (own inventory) are shown **Confirmed** on the player's own card only.

## 6. What the consultation shows (alpha.33)

| Line | Teammate | Own card |
|---|---|---|
| Spells | Unknown (no API) | Confirmed (own client data) |
| Accessories | Unknown (not exposed; `groupprobe items` may change this) | Confirmed (own inventory) |
| Top spell this run | Confirmed (native group packet) when present, else Unknown | n/a |
| Recent actions | Observed (combat-log messages) when the history option is on, else Unknown | Observed |

The three states are always labelled `[Confirmed]`, `[Observed]`, `[Unknown]` (FR: Confirmé / Observé / Inconnu).
**Not verified in the game: whether the group packet carries `top` for every teammate, whether the combat-log messages are
delivered to addons, whether party inventory is readable.** None of these is announced as working.
