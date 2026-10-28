# Azeroth FieldKit 0.2.3 — layout, co-op and simpler settings

This update brings the layout, co-op and UX improvements developed since
**0.2.1-review.3** into one package. The maintainer accepted it for publication;
the GitHub prerelease flag is retained. Credit to **Malk**, creator of MASH.

## What's changed

- **Move windows while playing:** drag active FieldKit windows directly, with no
  settings panel required. Lock positions in Windows → Layout, with `/fieldkit lock`
  or `/fieldkit unlock`, or by right-clicking the minimap compass.
- **Your layout:** group or separate left/right cards, move cards independently,
  resize their width/height, and retain anchors, dimensions and collapse preferences.
  Slider minima follow the visible content. Previews arranges hidden cards/text areas.
- **Readable meters:** real native damage, DPS and contribution in aligned columns.
  Damage taken uses native sources and an explicit unattributed remainder when needed.
- **Co-op:** group damage/DPS totals and optional individual teammate cards. Native
  teammate frames stay interactive by default; hiding them is an explicit advanced
  option because passive FieldKit cards do not implement native unit interactions.
- **Spell details:** hover your own spell rows or a group member, scroll the available
  breakdown, and Pin it. A pinned card stays on the selected player as ranks change.
- **Simpler settings:** Windows now has Display, Layout, Appearance and Co-op / test.
  An optional Essential HUD visibility preset has Undo. EN/FR guides and help updated.
- **Consistent visuals:** Classic/Decorative styling and HUD opacity also apply to
  detail cards; settings stay readable. The mode card is compact and can hide when
  difficulty is unavailable.
- **Experimental spell sharing:** opt-in in-game requests can exchange native spell
  snapshots between consenting FieldKit users, if the client forwards PARTY addon
  messages. Bounded protocol, receive status and `/fieldkit sync` diagnostics included.

## Update

Download **AzerothFieldKit-0.2.3.zip** from Assets, not the automatic Source code ZIP.
Back up the existing addon folder, then replace it in the AddOns directory of the
client you actually launch. Keep your saved preferences. Restart the game and open
`/fieldkit`. Disable legacy MASH to avoid competing replacements.

No external program or companion addon is required. This publication workflow does
not modify game saves, executables, MPQs, account enable files or the installed addon.

## Known limits and evidence

- Full native local spell details are available within the documented safety bound.
  Native allied data exposes totals and at most a top spell; full allied breakdowns
  require compatible opted-in peers **and working client transport**.
- **Live co-op forwarding is unconfirmed.** A successful send call is not delivery.
  The two-client protocol test uses simulated delivery. Sharing starts disabled.
- Ground runes are not tracked. Lair pins are fixed lairs, not moving guardians.
- Hovered Heroic rules remain explicitly a **0.121 reference**; no current weekly
  affixes, marks, star progression or missing mechanics are invented.
- Automated checks pass on **Lua 5.0.3 and 5.1**, including upvalue, persistence,
  malformed data, movement, UI-handler and protocol fixtures. No new agent in-game
  rendering, performance or network test is claimed.
- Publication permission reported by the maintainer is distinct from independent
  certification or package-specific game-team approval. Existing credits and rights
  notes remain in NOTICE.md and LICENSE.md.

Source: https://github.com/Maidenquinn/azeroth-fieldkit
Issues: https://github.com/Maidenquinn/azeroth-fieldkit/issues
