# Matériaux de la correction visuelle 0.6.0-alpha.2

Les PNG sources sont conservés ici ; les TGA RGBA utilisés par le client sont
dans `AzerothFieldKit/media/ZoneThemes`. Les empreintes sont dans
`data/theme-assets.json`. Ce sont des créations assistées par génération
d’image, pas des assets officiels Blizzard.

Références : les maquettes Minimaliste approuvées, conservées dans
`H:/Users/kevin/Desktop/AzerothFieldKit_0.6.0_Concepts/03_HUD_Concepts`.

Les cadres carrés servent au découpage en neuf régions : acier givré/cyan pour
Naxxramas, cuir vert/bois/laiton pour Elwynn. Les socles transparents reprennent
les bustes intégrés et un plateau central vide. Aucun nombre, texte, sort,
pourcentage ou jauge rempli n’est peint dans ces textures. Les sept boutons,
les PV, la ressource et l’XP restent des composants vivants du jeu.

Conversion uniquement de format et de résolution : PNG RGBA vers TGA RGBA,
512×512 pour les matériaux, 512×256 pour les socles. Pas de détourage par code.

La géométrie des six variantes est définie dans ThemeHUD/ThemeMinimap ; les
illustrations ne constituent pas une capture du rendu natif ni une preuve de
recette. Les captures prises réellement dans le client sont livrées séparément.
