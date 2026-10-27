-- Presentation-only additions. Native creature/spell names are never translated.
local fr=FieldKitLocale.fr
local labels={
 ["Overview"]="Vue d'ensemble",["Start here"]="Pour commencer",["Combat & health"]="Combat et survie",["Your interface"]="Votre interface",
 ["Health & buffs"]="Vie et effets",["Bosses"]="Boss suivis",["Alerts"]="Alertes de survie",["Minimap"]="Minicarte",
 ["Numbers"]="Valeurs numériques",["Percentage"]="Pourcentage",["Numbers + percentage"]="Valeurs et pourcentage",
 ["Player health format"]="Format de vie du joueur",["Target health format"]="Format de vie de la cible",["Boss health format"]="Format de vie des boss",
 ["Gold and chest price"]="Or et prix du coffre",["Enabled"]="Activé",["Disabled"]="Désactivé",["Configure"]="Configurer",
 ["Choose your tools, then arrange your interface. Only enable what you need."]="Choisissez vos outils, puis placez vos fenêtres. Activez uniquement ce qui vous est utile.",
 ["Animated damage and healing, with your own filters."]="Dégâts et soins animés, avec vos propres filtres.",
 ["Readable player and target health, shields and buffs."]="Vie du joueur et de la cible, boucliers et améliorations.",
 ["Independent portraits and health for tracked enemies."]="Portraits indépendants et vie des ennemis suivis.",
 ["Choose chest and guardian-lair markers separately."]="Choisissez séparément les repères de coffres et d'antres.",
 ["Arrange your HUD"]="Organisez vos fenêtres",["Move windows"]="Déplacer",["Reset HUD positions"]="Positions par défaut",["Undo"]="Annuler",["Close"]="Fermer",["Done"]="Terminer",["Reload UI"]="Recharger l'interface",
 ["Move enabled windows without the settings panel covering them."]="Déplacez vos fenêtres sans être gêné par les paramètres.",
 ["Changes apply immediately. Your preferences are kept."]="Les changements sont immédiats. Vos préférences sont conservées.",
 ["Compact bar saved. Reload UI when you are ready."]="Barre compacte enregistrée. Rechargez quand vous êtes prêt.",
 ["Combat and interface tools"]="Outils de combat et d'interface",["Max camera distance"]="Distance maximale de la caméra",
 ["Camera changes apply immediately; other settings stay unchanged."]="La distance s'applique immédiatement, sans modifier vos autres réglages.",
 ["Saved now. Use Reload UI below to apply the compact bar; your current run is not reloaded automatically."]="Réglage enregistré. Utilisez Recharger l'interface pour appliquer la barre compacte. Aucun rechargement automatique.",
 ["Show the separate gold and next-chest strip. Hiding it restores the native tally if FieldKit replaced it."]="Affiche la barre d'or et du prochain coffre. La masquer rétablit le compteur du jeu si FieldKit le remplaçait.",
 ["Move your enabled windows"]="Déplacez les fenêtres actives",["Drag a window or a combat area, then choose Done."]="Déplacez une fenêtre ou une zone de texte, puis cliquez sur Terminer.",
 ["Native text is independent of FieldKit scrolling text. Disable duplicate displays here."]="Le texte du jeu est indépendant du texte FieldKit. Désactivez les affichages en double ici.",
 ["Game text"]="Jeu",["Move windows, then choose Done to return to settings."]="Déplacez les fenêtres, puis choisissez Terminer pour revenir aux paramètres.",
}
for key,value in pairs(labels) do fr[key]=value end
FieldKitLocale.en={};for en,value in pairs(fr) do FieldKitLocale.en[value]=en end
