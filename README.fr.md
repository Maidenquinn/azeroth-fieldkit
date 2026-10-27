# Azeroth FieldKit — dossier de revue

Outils de combat et d'interface **entièrement en jeu**, maintenus par Kevin
Radlowski / Maidenhead. **Fork de MASH, créé par Malk**, et non réécriture dont
Kevin posséderait tout le code. Le nouveau nom identifie la maintenance actuelle.

La version `0.1.0-review.2` est une candidate publique à examiner par les développeurs. Aucune approbation
des développeurs du jeu ou autorisation de l'auteur d'origine n'est annoncée.
Le [README anglais](README.md) décrit toutes les fonctionnalités et commandes.

## Ce qui change

- Réglages, frontière d'accès aux API et options séparés en modules documentés.
- Ancien affichage des critiques isolé ; l'éditeur complet reste unique.
- Mécanisme de sauvegarde/restauration des talents natifs retiré.
- Copie du chat désactivée par défaut, facultative et limitée ; désactiver efface
  le tampon. Elle peut contenir des messages privés si on l'active.
- Écritures de CVars limitées aux quatre paramètres visuels attendus.
- Filtre de nameplates désactivé par défaut ; il ne force plus WorldFrame lorsque
  désactivé et restaure les parents/échelles des frames qu'il a déplacées.
- Distances des antres issues des coordonnées monde natives, sans modifier la carte.
- Configuration sauvegardée normalisée et entrées bornées. Aucun code reçu exécuté.
- Nouveau nom, préfixes, commandes et `FieldKitDB` séparés de MASH. Aucun import
  automatique ni modification de `MASHDB`.
- Fonctions conservées : portraits indépendants, combat, PV, fenêtres repliables,
  or/prix des coffres, équipements, minimap, caméra et barre compacte optionnelle.

## Installation et usage

Tester uniquement dans le cadre autorisé par les développeurs. Désactiver MASH,
puis copier le dossier interne `AzerothFieldKit` dans AddOns et recharger le jeu.
`/fieldkit` ouvre la configuration ; `/fieldkitcombat` ouvre le texte de combat.
La langue se choisit dans Interface.

Sur une installation neuve, les marqueurs minimap, le filtre de nameplates, les
remplacements du HUD, la barre compacte, le texte de combat, le son d'alerte et
la copie du chat sont désactivés. Les fenêtres propres à l'addon restent actives.
Leur présence parmi les options ne préjuge pas de leur acceptation par le jeu.

`/fieldkitlog on`, `off`, `clear` contrôlent la copie du chat. Les messages restent
en mémoire, jamais en sauvegarde ou sur un serveur. Rien n'est envoyé dans le chat
et aucun programme externe n'est nécessaire.

## Limites et vérifications

Les tests hors jeu passent sous Lua 5.0.3 et 5.1. Ce n'est ni une certification de
sécurité, ni une validation dans le client en cours d'exécution. Le catalogue de
portraits est celui du client examiné ; il ne garantit pas les futures cartes.
Les antres ne sont pas les positions mobiles des gardiens. Les runes au sol ne
sont pas suivies. Les relevés de soins ne prouvent pas chaque tick individuel.

Le filtre de nameplates et la barre compacte modifient des frames natives et
peuvent entrer en conflit avec d'autres addons. Le glisser-déposer de la barre
compacte échange réellement deux emplacements d'action. Les CVars de caméra,
dégâts et visibilité du HUD peuvent persister après désactivation : rétablir ses
préférences dans les réglages natifs si nécessaire.

Le [dossier de revue](docs/REVIEW.md), l'[audit](SECURITY.md), les
[effets natifs](docs/API_SURFACE.md), le [guide du code](docs/CODE_GUIDE.md) et le
[plan de test](docs/TESTING.md) servent de base aux développeurs pour décider.
Les crédits et droits non résolus figurent dans [NOTICE](NOTICE.md) et
[LICENSE](LICENSE.md). Le dépôt et la préversion sont publics pour faciliter la revue. Cet accès public
ne confirme ni les permissions de redistribution ni l’approbation du jeu.
