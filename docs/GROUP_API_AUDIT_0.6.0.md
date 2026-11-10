# Group, spell and item API audit (0.6.0-alpha.32)

Evidence level legend: **S** = static, string found in `AzerothSurvivors.exe` (151 677 952 bytes, read-only scan);
**R** = must be confirmed at runtime in the game (`/fieldkit groupprobe ...`); **T** = covered by a synthetic test only.
A string present in the executable proves the client knows the name. It does not prove that the event reaches addons
with the arguments we expect: that is what the runtime probe measures.

## 1. Events

| Item | S | Notes |
|---|---|---|
| CHAT_MSG_SPELL_PARTY_DAMAGE | yes | party spell damage message |
| CHAT_MSG_SPELL_PARTY_BUFF | yes | party heals and buff messages |
| CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE | yes | periodic damage |
| CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS | yes | periodic heals / auras gained |
| CHAT_MSG_SPELL_AURA_GONE_PARTY | yes | aura faded |
| CHAT_MSG_COMBAT_PARTY_HITS / MISSES | yes | melee, not used (spam) |
| CHAT_MSG_SPELL_PET_DAMAGE / PET_BUFF | yes | pets, deliberately ignored |
| UNIT_SPELLCAST_START / STOP / FAILED / INTERRUPTED | **no (0 occurrence)** | there is no per-unit cast event in this client: a teammate's cast start/stop cannot be observed that way. Only chat messages exist |
| UNIT_AURA, UNIT_HEALTH, UNIT_MANA, UNIT_INVENTORY_CHANGED, PARTY_MEMBERS_CHANGED, BAG_UPDATE, CHAT_MSG_LOOT | yes | state events, no per-action detail |
| INSPECT_READY | no | inspect results cannot be waited for by event |
| COMBAT_LOG_EVENT (unfiltered) | no | the structured combat log of later clients does not exist here |

Arguments: for every `CHAT_MSG_*` event `arg1` is the message text (R: confirm with `groupprobe events`). The author and
the target are NOT arguments: they are inside the text. They are extracted with the client's own localized format strings.

## 2. Message formats and localization

The format strings (`SPELLLOGOTHEROTHER`, `HEALEDOTHEROTHER`, `SPELLINTERRUPTOTHEROTHER`, `AURAADDEDOTHERHELPFUL`,
`PERIODICAURADAMAGEOTHEROTHER`, ...) are **not** in the executable (0 occurrence): they are in the game data. Whether
they are provided as Lua globals is a runtime fact (R): `groupprobe api` lists the formats provided and missing. The
history module compiles each provided format (handling positional `%2$s` forms) so it follows the client language (FR/EN)
with no table of its own, and parses only what the client provides (T).

Limits that follow:
- only messages that match a provided format are recorded; anything else is counted as unmatched and shown by `groupprobe stats`, never guessed;
- the author of a damage / heal / cast / interrupt is the caster named in the text; for a buff gained or faded it is the
  one who gains it (the text carries no caster);
- direct damage, periodic damage, heals (direct / periodic) and buffs have separate formats, so they are distinguished;
- "begins to cast" is a cast start, not a completed cast;
- an interruption is detected only when the client prints the interrupt message for a teammate (R);
- resists, misses, absorbs, dispels are not recorded (no format used).

## 3. Spells and icons

`GetSpellName`, `GetSpellTexture`, `GetSpellCooldown` exist (S) but index the **local player's spellbook** only. A teammate's
spell has no icon API: an icon is shown only when the same spell name is in the local spellbook (T); otherwise no icon
is displayed and none is invented. Cooldowns of other players are not available.

## 4. Items

| API | S | Meaning |
|---|---|---|
| GetItemInfo, GetItemQualityColor | yes | item data from an item link/id |
| GetInventoryItemLink / Texture / Count / Cooldown / Quality / Broken | yes | take a unit token; whether `party1..4` return equipped items without an inspect is a runtime fact (R: `groupprobe items`) |
| CanInspect, CheckInteractDistance, NotifyInspect, ClearInspectPlayer | yes | inspect path; `groupprobe items notify` tests it (R) |
| GetContainerItem*, BAG_UPDATE, CHAT_MSG_LOOT | yes | local bags and loot messages |

Worn gear, consumables, items used in combat and merely looted items are four different things:
- **worn gear** of a teammate: only if `groupprobe items` shows readable slots (R);
- **loot**: `CHAT_MSG_LOOT` text only, says an item was picked up, nothing else;
- **consumable / item use**: no event in this client's list reports another player's item use. It is **not detectable** and is not claimed;
- **cooldowns of other players' items**: not available.

## 5. Unit state

Present (S): UnitIsDead, UnitIsGhost, UnitIsDeadOrGhost, UnitIsConnected, UnitIsVisible, UnitLevel, UnitClass,
UnitPowerType, SetPortraitTexture, UnitBuff, UnitDebuff. **UnitInRange is absent**: "out of range" is not displayed.
(`UnitIsVisible` / `CheckInteractDistance` are not range indicators for a whole group and are not used as such.)

## 6. Verification matrix

| Check | Result |
|---|---|
| Static audit of the executable | PASS (above) |
| Runtime delivery of the 5 chat events and their `arg1` | NOT RUN: needs the game. Command: `/fieldkit groupprobe events 60` |
| Client format strings provided | NOT RUN: `/fieldkit groupprobe api` |
| `party1..4` equipped items readable | NOT RUN: `/fieldkit groupprobe items [notify]` |
| Parser, kinds, options, bounds, roster hygiene, FR/EN, positional formats (synthetic) | PASS (tests/group_history.lua) |
| Performance: 20 000 messages | PASS (budget asserted; bounded memory members x count) |
| Group card component: fixed geometry, states, options (synthetic) | PASS (tests/zone_themes.lua) |
| Rendering in the game | NOT RUN: native recette required |
