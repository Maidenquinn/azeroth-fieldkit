# Loadout and observed taken details — 0.3.2-review.1

Unpublished development candidate. AZSSpellMeter was inspected read-only for the
native tooltip/icon discovery approach. No files from that addon are modified,
required, or copied into FieldKit. No modern combat-log API is assumed.

## Utilisation

- **Accessoires** garde les cinq emplacements et les couleurs de rareté. Une
  seconde ligne verte résume les bonus actuels lus dans l’infobulle du jeu. Le nom
  complet et son suffixe de niveau (III, IV…) restent ceux fournis par le client.
  Le survol garde l’infobulle native complète. Un rang de bijou n’est pas inventé
  lorsque le client ne le fournit pas : compter des changements de bonus ne
  prouverait pas le vrai niveau, notamment après un rechargement.
- **Sorts** est une carte indépendante, déplaçable et repliable, avec icône, rang
  disponible et bonus natifs. Fenêtres → Affichage → **Rangs et bonus des sorts**
  l’active ou la masque. Disposition permet de la dimensionner ; les styles
  Classique/Travaillé et l’opacité s’appliquent. Son aperçu est disponible en solo.
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

Spellbook and hidden native tooltip readers supply current names, native textures,
Rank/Rang headers and green bonus lines (color or native green markup). Stable
native spell keys can match normalized names to AZS_SPELLS.rank. In another game
language the explicit native tooltip header is used when the key does not match.
No formula derives a bonus from rank, and no missing rank is assumed to be one.
If the spellbook API is absent, exposed spell keys/ranks remain a literal fallback.
No spell card is shown without spell data. Up to nine rows are displayed; the total
count makes a larger source list explicit. At most 128 book entries, 120 actions,
24 tooltip lines and five equipment slots are scanned once per second.

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
3. Resize/reposition/collapse Spells and Accessories with Classic and Decorative
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
