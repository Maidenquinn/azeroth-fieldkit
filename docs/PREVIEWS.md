# Context-free preview guide — 0.3.2-review.3

Unpublished branch candidate. No actual game rendering test by the agent.

## Parcours utilisateur

1. `/fieldkit` → Vie et effets / Boss suivis / Alertes / Fenêtres → Disposition ou Coop.
2. **Tester l’affichage** ouvre un petit inspecteur déplaçable. Son menu propose
   19 exemples, même en solo et avec les modules désactivés. Les compteurs ont des
   lignes remplies ; le groupe montre quatre joueurs fictifs. Les PV joueur/cible
   ont leur propre exemple. Les noms et valeurs sont explicitement fictifs.
3. Gardez cet inspecteur visible et modifiez les options dans les paramètres :
   style, opacité, dimensions, colonnes du compteur, formats des PV et filtres
   des effets/alertes. La sélection Disposition est liée à celle de l’inspecteur.
4. **Placer cette fenêtre** masque les paramètres et montre uniquement cet
   exemple. Les groupes restent des groupes : déplacez leur ancre commune.
   **Terminer** rétablit les données réelles et la préférence de verrouillage.
5. Pendant le placement, seuls les exemples sont visibles par défaut.
   **Afficher les autres éléments de l’interface** réaffiche le HUD du jeu et des
   autres addons, mais garde les vrais panneaux FieldKit masqués. Le même bouton
   permet de les masquer à nouveau. Terminer/Échap restaure l’affichage normal.
6. **Inclure dans la composition** choisit les cartes montrées par **Composer
   l’interface**. Cette sélection dure jusqu’au rechargement ; elle n’active pas
   les modules. Les quatre cartes équipiers sont sélectionnables individuellement.
7. **Réinitialiser la position de cette fenêtre** ne touche qu’à la fenêtre
   indépendante sélectionnée. Dégroupez d’abord son côté si nécessaire. Les
   dimensions, les autres fenêtres et les options ne sont pas réinitialisées.

Les exemples de PV joueur/cible sont consultatifs : déplacez directement la vraie
barre joueur comme auparavant. Le texte cible suit le cadre cible natif.
Le texte de combat conserve son bouton Aperçu et ses zones déplaçables dans son
éditeur ; ses exemples portent déjà une marque explicite.

## Implementation and limits for reviewers

`Preview.lua` owns a lazy, bounded pool (19 examples, at most eight rows per card),
a single inspector and up to two noninteractive group proxies. No frames are
allocated by steady-state refresh. Work runs at most every 150ms while the
inspector/composition dock is visible; there is no additional background loop.

Card examples reuse the bar-window constructor, HUD theme and numeric columns;
filled card contents are representative layouts, not copies of live data. Boss
examples reuse the actual boss-frame constructor, static verified portrait
catalog, health formatting and debuff regions. Player/target examples use their
shared HP formatter; shields/buffs are schematic. No native unit token is needed.
No minimap/world-coordinate samples are fabricated.

Live frames continue receiving real updates. During explicit placement their visual
alpha is temporarily zero; sample frames never replace the live data model. Nothing is inserted into
`AZS_*`, FieldKitMeters, FieldKitCoop.party or PartySync. The inspector never calls
native CVar/HUD/overlay setters, emits chat or sends packets. Geometry saves use
real owned frame names, never sample-frame names; only explicit drag/reset saves
positions. Closing a preview does not persist any sample values or enable flags.

Grouped composition lays out samples on a separate proxy; it does not enlarge
real groups to fit disabled cards. Their live stack contracts naturally when
examples stop. Resetting one grouped card is deliberately refused with an explicit
ungrouping hint rather than resetting the entire side.

The candidate is not confirmation of live party transport, modal layering or
exact pixel rendering. These remain game tests. Existing public 0.3.0 is unchanged.

## In-game validation checklist

- Open examples in solo, before a run and during combat; disabled modules stay off.
- Try four group totals and each teammate card with no party; nothing is shared.
- Try boss portrait/debuffs without a target; changing targets does not affect it.
- Change Classic/Decorative and opacity while viewing a card; settings stay opaque.
- Change Damage/Healing/Boss view, all column formats, card dimensions and HP format.
- Position individual and grouped examples at every screen edge; Done, Escape and
  closing settings remove all examples. Normal unlocked dragging still works.
- Unlink one side and reset only one window; confirm other positions stay intact.
- Test small window/resolution and EN/FR; move the inspector if it overlaps settings.
- Restart: geometry persists, sample state does not, feature flags are unchanged.

Offline regression tests exercise actual Lua constructors and callbacks under
Lua 5.0.3 and 5.1, including missing context, disabled modules, no native writes,
data identity, pooled allocations, column values, theme scope, HP formats, group
positions, scoped reset, inspector selection, popup cleanup and Escape paths.

## Placement isolation implementation (review.2)

PreviewVisibility.lua temporarily masks owned live displays and, initially, other
Lua UIParent children/regions. The dock, samples, group proxies and combat-area
handles remain visible. UIParent and WorldFrame are never masked. This does not
cover UI drawn outside the Lua frame tree or independent non-UIParent surfaces.
The button affects Lua UI, not the rendered world or client settings.

Alpha and available mouse-enabled state are captured once and restored on Done,
Escape, opening settings, inspector transition, or an interrupted drag. Mouse
interaction on descendants is suspended where the legacy API exposes its state.
No Show/Hide, parent, foreign method/script, native CVar or saved preference is
changed by masking. Hidden/shown state can keep changing normally during the
preview, so exiting does not resurrect a window hidden by its owner. Initial alpha
is restored exactly; other addons remain responsible for subsequent animations.
New UIParent roots are discovered at the existing 150ms preview refresh; traversal
is bounded. A renderer actively rewriting its own alpha between refreshes can
override the mask briefly; no foreign method interception is installed.

Offline tests include non-default/zero alpha, live FieldKit always masked, other-UI
toggle, descendant input, owner visibility changes, and Done/Escape restoration.
Actual addon-specific rendering and interactions still need game validation.

The Accessories example follows the selected equipment/spell tab in the real
card. There is no separate Spells frame in review.2.
