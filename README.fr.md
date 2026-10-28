# Azeroth FieldKit

Outils de combat et d’interface entièrement en jeu pour Azeroth Survivors.
Maintenu par **Kevin Radlowski / Maidenhead**, dérivé de **MASH par Malk**.

[English](README.md) · [Historique](CHANGELOG.md) · [Dossier de revue](docs/REVIEW.md)

## Version à utiliser

- **Version publique :** [0.2.1-review.3](https://github.com/Maidenquinn/azeroth-fieldkit/releases/tag/v0.2.1-review.3).
- **Cette branche :** `0.2.3-review.1`, candidate de simplification UX, non fusionnée.
  Elle inclut les candidates précédentes de disposition et de coop ; aucune nouvelle
  release publique n’est annoncée.
- Le 28 octobre 2026, le mainteneur a rapporté l’autorisation de publier l’addon
  comme vérifié. Cette autorisation ne constitue pas une validation de cette nouvelle
  candidate et ne règle pas les droits hérités. Voir [publication](docs/PUBLICATION.md),
  [crédits](NOTICE.md) et [licence](LICENSE.md).

## Installation

1. Sauvegardez le dossier FieldKit existant. Téléchargez le ZIP nommé de la version
   dans **Assets** de la release, pas l’archive automatique des sources GitHub.
2. Placez son dossier `AzerothFieldKit` dans les AddOns du **client réellement lancé**.
   Vérifiez `AddOns/AzerothFieldKit/AzerothFieldKit.toc`, sans double dossier imbriqué.
   Désactivez l’ancien MASH pour éviter les comportements en double.
3. Activez FieldKit dans le sélecteur du client puis redémarrez le jeu.

Le téléchargement public conserve son ancienne interface ; le ZIP candidat est
séparé. Aucun programme externe ni addon compagnon n’est nécessaire. FieldKit
n’importe pas automatiquement MASHDB et ne modifie pas vos sauvegardes de partie.

## Prise en main

Ouvrez `/fieldkit` ou cliquez sur sa boussole de minicarte. La langue se choisit dans
**Interface**. Les noms de sorts et créatures restent dans la langue du jeu.

Les fenêtres actives **se déplacent directement par défaut**. **Fenêtres → Disposition**
permet de verrouiller leurs positions, grouper/séparer les cartes de gauche ou de
droite et régler les dimensions d’une carte. Le verrouillage est conservé au
rechargement. `/fieldkit lock`, `/fieldkit unlock` et le clic droit sur la boussole
modifient le même choix sans ouvrir de panneau.

**Aperçus** sert à organiser les cartes masquées et les zones de texte. Ce mode
outrepasse temporairement le verrouillage ; Terminer rétablit votre préférence.

**Vue d’ensemble → Affichage essentiel** affiche dégâts, antres, or et totaux du groupe,
et masque statistiques, accessoires, mode et dégâts subis. Seule la visibilité change :
positions, dimensions, style et autres addons sont conservés. **Annuler le préréglage**
rétablit vos choix précédents jusqu’au prochain rechargement.

## Où trouver les réglages

- **Texte de combat :** un éditeur pour événements, filtres, polices, couleurs,
  regroupement, animations, durée, zones et texte natif. Facultatif, sans MSBT externe.
- **Vie et effets / Boss suivis / Alertes :** formats des PV, bouclier, effets,
  portraits indépendants et alerte de vie basse. Le catalogue statique des portraits
  ne garantit pas automatiquement les futures cartes ou apparences.
- **Fenêtres → Affichage :** cartes visibles. Le compteur natif reste disponible ;
  choisissez votre affichage préféré dans ses propres options pour éviter les doublons.
- **Fenêtres → Disposition :** verrouillage, groupes et dimensions individuelles.
  Les minima suivent la carte et ses lignes visibles. Agrandir augmente l’espacement,
  pas la police ; une grande hauteur peut laisser de l’espace vide.
- **Fenêtres → Apparence :** style Travaillé/Classique, opacité du fond du HUD et
  colonnes dégâts/DPS/contribution. Paramètres et menus restent lisibles.
- **Fenêtres → Coop / tests :** cartes passives facultatives, format des PV et partage
  expérimental des sorts. Les cadres natifs restent interactifs par défaut. Les masquer
  explicitement retire leurs interactions de ciblage, menus et effets jusqu’à restauration.
- **Minicarte / Barres ennemies / Interface :** marqueurs indépendants des coffres et
  antres, filtre facultatif, langue, caméra, barre compacte et copie locale du chat.

Survolez un sort de votre compteur ou un joueur du compteur de groupe pour le détail.
**Épingler** maintient le détail du même joueur pendant le défilement et les changements
de classement. Détacher, Échap ou la croix le libère. Le détail se ferme lorsque son
compteur source disparaît ou que la partie se termine.

## Données et limites

Les dégâts viennent des compteurs natifs, jamais du DPS multiplié par le temps.
Les dégâts subis peuvent inclure un reste **Non attribués (total natif)**. Une valeur
manquante reste inconnue. Un total de soins ne prouve pas chaque tick individuel.

Le client fournit les totaux du groupe et au plus le meilleur sort allié. Le partage
expérimental est **désactivé par défaut**. Les deux joueurs doivent l’activer ; seuls
leurs propres compteurs de sorts sont envoyés sur demande, par messages PARTY bornés
`AFKDETAIL1`. Le transport en coop réelle reste **non confirmé**. L’état indique les
relevés reçus récemment ; un appel d’envoi réussi ne prouve pas la réception.
Voir [protocole et limites](docs/PARTY_SYNC.md).

La carte du mode reste compacte et se masque par défaut si la difficulté native manque.
Les règles au survol sont une **référence 0.121**, pas des mécaniques actuelles vérifiées
ni des multiplicateurs mesurés en direct. Aucun affixe actif, marque ou étoile n’est
inventé. Les runes au sol ne sont pas suivies ; les antres ne donnent pas la position
mobile des gardiens.

## Commandes et confidentialité

- `/fieldkit`, `/fieldkitcombat` : paramètres et éditeur de combat.
- `/fieldkit lock`, `/fieldkit unlock` : verrouillage persistant sans panneau.
- `/fieldkit money` : rattacher la barre d’or/prix du coffre aux sorts.
- `/fieldkit coop`, `/fieldkit sync` : diagnostic local de coop.
- `/fieldkitlog on`, `off`, `clear` : copie facultative du chat en mémoire. Elle peut
  contenir des messages privés ; désactiver efface le tampon. Rien n’est sauvegardé
  ni transmis par cette fonction.

Aucun code téléchargé n’est exécuté. Les écritures natives sont limitées aux effets
visuels documentés et aux actions facultatives de la barre. Certaines CVars peuvent
persister après désactivation : rétablissez-les dans le jeu si nécessaire.
Voir [effets natifs](docs/API_SURFACE.md), [sécurité](SECURITY.md) et les conflits possibles.

## Vérification et contribution

Les tests hors jeu couvrent Lua 5.0.3/5.1, les upvalues, les préférences invalides,
la persistance, les sources natives, les déplacements et les replis coop. Ils ne
certifient ni le rendu en jeu, ni les performances, ni la livraison des messages.

```text
python tools/audit.py
python tools/verify.py --lua50 CHEMIN_LUA_5_0_3
python tools/package.py
```

Le paquet exige des sources commitées et des preuves de validation à jour.
Voir [contribuer](CONTRIBUTING.md), [guide du code](docs/CODE_GUIDE.md),
[tests](docs/TESTING.md) et [validation de la candidate](docs/UX_SIMPLIFICATION.md).
Cette branche attend une validation en jeu avant toute fusion ou release.
