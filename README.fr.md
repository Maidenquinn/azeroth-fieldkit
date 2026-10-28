# Azeroth FieldKit — dossier de revue

Outils de combat et d'interface **entièrement en jeu**, maintenus par Kevin
Radlowski / Maidenhead. **Fork de MASH, créé par Malk**, et non réécriture dont
Kevin posséderait tout le code. Le nouveau nom identifie la maintenance actuelle.

Le **28 octobre 2026**, le mainteneur a indiqué avoir reçu l'autorisation de
l'équipe pour publier FieldKit comme **addon vérifié**, avec le rôle Discord
correspondant. La [release 0.2.1-review.3](https://github.com/Maidenquinn/azeroth-fieldkit/releases/tag/v0.2.1-review.3)
conserve son nom et son ZIP existants. Cette autorisation de publication ne
constitue pas une nouvelle validation en jeu ni une permission de Malk.
Le [suivi de publication](docs/PUBLICATION.md) précise le périmètre et l'archive.
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

## Optimisations fondées sur la documentation officielle

Les traitements de données de partie passent de 20 à 5 Hz ; les durées des
debuffs gardent leur rafraîchissement rapide et les animations restent fluides.
Les portraits inchangés sont mis en cache. Les données de partie périmées sont
masquées hors partie, les antres ne décomptent plus du temps réel pendant une
pause et le nombre de coffres vient du compteur natif quand il est fourni.
Les tests de fréquence sont simulés ; aucun gain de FPS en jeu n’est annoncé.
Voir [OFFICIAL_API](docs/OFFICIAL_API.md).

## Installation et usage

Télécharger `AzerothFieldKit-0.2.1-review.3.zip` dans **Assets** sur la release
(pas les archives automatiques du code source). Désactiver MASH, puis copier le
dossier interne `AzerothFieldKit` dans le dossier AddOns du client réellement
lancé. Le fichier doit se trouver dans `AddOns/AzerothFieldKit/AzerothFieldKit.toc`.
Activer l'addon dans le sélecteur du jeu et redémarrer le client.
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
[LICENSE](LICENSE.md). L'autorisation de publication en addon vérifié est
désormais rapportée par le mainteneur ; les droits hérités restent distincts.
Les anciens rapports et le ZIP conservent les mentions de leur date de création.

## Nouveau parcours des paramètres

Ouvrez `/fieldkit` ou la boussole de la minicarte. L’accueil présente les outils
et leur état ; **Configurer** ouvre la page correspondante. Neuf rubriques
regroupent les usages, avec un seul choix de format de PV par unité.

**Texte de combat** regroupe Général, Événements, Police, Filtres, Zones et Jeu.
La page Jeu règle les affichages natifs pour éviter les doublons. **Déplacer**
masque les paramètres pour placer les fenêtres ; **Terminer** revient aux
réglages. **Positions par défaut** propose ensuite une annulation immédiate.
La barre compacte ne recharge l’interface qu’après un clic explicite.

Le thème ardoise et or reprend Azeroth Stats sans en dépendre. Les pages
défilent sur petit écran. Les préférences existantes sont conservées ; le détail
de l’audit et les vérifications en jeu sont dans [UX_REVIEW.md](docs/UX_REVIEW.md).
Cette refonte n’a pas encore été validée dans le jeu.

Dans **Fenêtres**, choisissez le style **Travaillé / Classique** et l’opacité du fond (0–100 %), sans diminuer celle des textes et bordures. Le compteur propose **DPS et contribution**, **Dégâts et DPS** ou **Dégâts, DPS et contribution**. Les dégâts sont le cumul natif exact par compétence, sans estimation à partir du DPS.

Correctif review.3 : style et opacité s’appliquent uniquement aux cartes du HUD en jeu. Les paramètres et menus restent opaques. Les dégâts, DPS et contributions occupent des colonnes fixes, alignées à droite ; changer de mode conserve le bord gauche du compteur.

## Jeu 0.121.0

Le contexte des paramètres affiche le rang Normal / Héroïque I–V lorsqu'il est
fourni par le client. Les bonus conservent leurs dixièmes, et le filtre des
monstres ordinaires préserve les barres des orbes explosives (la touche V reste
respectée). Les PV, dégâts et soins restent ceux du jeu, sans appliquer une
seconde fois les modificateurs Héroïques ou les étoiles.

Aucune API de marques, d'étoiles ou d'affixes actifs n'a été confirmée. Ces
valeurs ne sont donc pas simulées. Voir [preuves et limites](docs/GAME_0_121.md).

## Carte du mode et alignement à gauche

Le mode de jeu, les dégâts, les dégâts subis et les antres partagent désormais
une largeur et une pile avec six pixels d'espacement. Réduire ou masquer une
carte referme l'espace. Déplacez n'importe quelle carte en mode **Déplacer** pour
bouger le groupe. Dans **Fenêtres**, **Aligner les cartes de gauche** permet de
revenir aux positions individuelles conservées ; **Carte du mode de jeu** masque
ou affiche la nouvelle carte.

Le rang et la zone viennent du client. Les mécaniques sont marquées **Référence
0.121**, avec tous les détails au survol. Les quatre dernières règles restent
visibles ; les règles héritées supplémentaires sont comptées et détaillées dans
l'infobulle. Les noms des affixes actifs et les multiplicateurs PV/dégâts ne sont
pas inventés lorsqu'ils ne sont pas exposés. Voir [HUD_STACK.md](docs/HUD_STACK.md).

Le correctif review.3 conserve les ancrages natifs lors du déplacement, sans recalcul depuis le centre au relâchement. La marge de 12 pixels a été retirée ; le client limite la pile sur sa taille complète. Les ancrages natifs sont enregistrés séparément des anciennes positions et inclus dans Réinitialiser/Annuler.
