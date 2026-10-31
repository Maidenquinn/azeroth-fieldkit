# Azeroth FieldKit 0.3.0 — native effects, co-op support and new meter views

Changes since **0.2.3**, based on a read-only audit of the installed **0.130.1**
client API. Maintainer accepted for publication on 2026-10-31; GitHub prerelease
maturity is retained. FieldKit remains a maintained fork of **MASH by Malk**.

## What's new

- **Effects tracker:** native totem counts/caps and soonest expiration, grouped
  permanent/temporary summons, and published talent/item cooldowns. Contextual,
  filtered and bounded; no imaginary rows for unsupported effects.
- **Healing and Boss Damage:** choose Damage / Healing / Boss damage in the existing
  local meter. Native HPS and boss-fight rates remain distinct from whole-run DPS.
  Browse and pin their per-source details using the existing HUD style.
- **Co-op revive progress:** passive native local progress and the ally involved.
  The original revive interface stays available; no automatic actions.
- **Warnings and reminders:** filtered native boss/mechanic banners, duplicate
  suppression, configurable warnings before observed boss arrivals, stored-level
  count and native flagged-lair emphasis. No boss attack prediction.
- **Foreground windows:** explicitly opt selected FieldKit windows or pinned detail
  above level-up/jewelry choices using the client's new API. This does not guarantee
  coverage of death or other modal screens.
- **Received affixes:** recognized literal names can appear in the mode card.
  Unknown numeric/string formats stay labelled as raw data, with no calendar guesses.
- **Integration:** individual sizes, movement locks, collapse, themes and EN/FR are
  preserved. New panels and warnings start OFF. `/fieldkit native` reports local
  API capabilities and raw affixes without sending a network message.

## Enable the tools

Open `/fieldkit`:

- **Windows → Display:** Effects tracker, next-boss/stored-level reminders and the
  local meter view selector. **Health & buffs:** effects category filters.
- **Windows → Co-op / test:** revive progress.
- **Alerts:** native message filters, arrival warnings and lead time.
- **Windows → Layout:** foreground option for the selected window.
- **Windows → Appearance:** foreground for pinned detail.
- **Minimap:** highlight the lair selected by the native flag.

[Full activation/limits guide](https://github.com/Maidenquinn/azeroth-fieldkit/blob/v0.3.0/docs/NATIVE_TOOLS_0_130.md).

## Update and evidence

Download **AzerothFieldKit-0.3.0.zip** from Assets, not the Source code ZIP. Back up
and replace the existing FieldKit folder in the launched client's AddOns directory,
keep your saved preferences and restart. Disable legacy MASH if still enabled.
No external program or extra addon is required.

Static inventory, full native Lua **5.0.3** / Lua **5.1** behavioral and prototype
checks pass. An additional offline integration loaded the extracted client API
alongside FieldKit with synthetic packets. No new in-game rendering, performance,
real affix encoding or co-op transport test is claimed.

Counts/timings include only data supplied by the client. Native allied spell lists
remain limited unless optional sharing works between consenting peers; that transport
is still unconfirmed. Ground runes, armory/star/mark progression and new dynamic
portrait sources are not fabricated. Existing credits and rights notes are retained.
