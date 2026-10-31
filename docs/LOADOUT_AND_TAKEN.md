# Loadout and observed taken details — 0.3.2-review.3

Unpublished development candidate. Azerloot was inspected read-only for the
behavior of its action-tooltip bonus display. Its code/data/translations/assets
are not copied or required. The readers below are independent and use native
client data and locally extracted DBC spell icon/name facts.

## Utilisation

- **Accessoires** garde les cinq emplacements et les couleurs de rareté. Une
  seconde ligne verte résume les bonus actuels lus dans l’infobulle du jeu. Le nom
  complet et son suffixe de niveau (III, IV…) restent ceux fournis par le client.
  Le survol garde l’infobulle native complète. Un rang de bijou n’est pas inventé
  lorsque le client ne le fournit pas : compter des changements de bonus ne
  prouverait pas le vrai niveau, notamment après un rechargement.
- **Accessoires / Sorts** sont deux onglets du même panneau existant. Aucune
  fenêtre supplémentaire n’est créée. Position, taille, repli, opacité et style
  restent ceux du panneau Accessoires. Sorts n’affiche que la liste apprise de
  `AZS_SPELLS`, avec son rang natif, son nom localisé de barre d’actions et ses
  bonus. Le survol donne aussi les améliorations reçues. Les cases inconnues du
  grimoire ne sont pas ajoutées. Les anciens réglages de fenêtre Sorts sont retirés.
- Les compteurs de dégâts/soins et leurs détails de groupe montrent les icônes
  natives connues à gauche du nom. Une icône non identifiée reste absente. Les
  colonnes numériques gardent leurs positions. Il n’y a aucune dépendance à
  AZSSpellMeter, ni catalogue d’icônes arbitrairement associées.
- **Antres** ajoute le prochain boss programmé et son compte à rebours dans une
  ligne de pied de carte. Le nom et le temps ont des colonnes séparées. Option :
  Fenêtres → Affichage → **Prochain boss dans Antres**. Indépendant de Rappels.
- Survolez **Mêlée des monstres** ou **Élites** dans Dégâts subis : le détail montre
  les coups de mêlée dont le message et l’identité sont réellement exploitables.
  Le reste est « non identifié ». Ce journal est partiel, pas le détail complet
  du total natif. Sans événement attribuable, l’infobulle le dit explicitement.

## Data contracts and limits

Only the fresh native AZS_SPELLS learned list defines spell rows and rank. Native
spell IDs resolve through SpellAssets.lua, generated independently from local
173-field Spell.dbc (name=120, icon=117, rank=129, family=160) and SpellIcon.dbc.
The generated index includes base class spells only; it is not a bonus formula.
Evidence/hashes are in data/spell-assets-evidence.json; rebuilding is optional.

Action textures match only a unique learned native ability. Action tooltip titles
provide localized names; bounded multiline text parsing reads Your bonuses / Vos
bonus and Upgrades / Improvements / Améliorations labels separately. Talents and
other unlabeled text do not become run bonuses. Shared textures are rejected as
ambiguous. Native ranks do not depend on English/French spellbook names. At most
32 learned entries, 128 icon hints, 120 actions and 24 tooltip regions are scanned
once per second; each multiline region is limited to 4096 bytes and 32 segments.
Equipment still uses native inventory tooltips. No rank-one or item-rank guess is
introduced. Up to nine spell rows are displayed inside the existing card.

Taken-category data exposes aggregate source totals. The optional named ledger
accepts exact supported English melee/critical templates and one French melee
form, and only for the creature-versus-self melee event. Other languages/formats,
spell damage, unknown identities and conflicting native kinds remain unassigned.
Classification uses fresh native unit/target snapshots, never the current target
unless its name exactly matches, static nameplate seeds, DPS or player HP loss.
Only normal/elite kinds are grouped. Bosses/guardians are not relabelled as elites.
Native totals and this log can arrive asynchronously; an observed excess is marked
as unsynchronized instead of adjusting totals or creating a negative remainder.
At most 128 named sources are kept in memory, reset across run/zone boundaries.
No ledger, tooltip text or observed damage is saved or sent to peers.

## Required in-game checks

1. Learn/upgrade a spell, equip/upgrade/swap/remove jewelry: green lines refresh
   within about one second; compare to the native tooltip and actual rank.
2. Check English and French game/UI combinations. Unavailable rank/icon stays
   unknown/absent. No name should be replaced by another player's spell.
3. Switch tabs and resize/reposition/collapse the Accessories/Spells card with Classic and Decorative
   styles. Preview mode still masks real HUD and restores it correctly.
4. Verify damage/Healing/Boss numeric columns and icons, including group hover.
5. Compare Lairs' next-boss countdown with the native timer, including no schedule,
   collapse, disabled option and a native endless countdown.
6. Receive melee hits from named normal/elite enemies; compare supported log lines
   to the hover. Partial/unknown damage must stay explicit, especially in co-op.
7. Restart or change zones/runs: no previous attacker ledger may be carried over.

Offline tests cover actual constructors/readers with synthetic tooltip fields,
rank precedence, unknown icons, geometry, independent reminder options, supported
melee names, conflicting identities and stale-run snapshots under Lua 5.0.3/5.1.
They do not claim visual rendering or event delivery in the running client.
