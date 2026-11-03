# Azeroth FieldKit v0.4.0 — UI, localization, combat text and previews

Changes **since the published v0.3.4 prerelease** (2026-11-02). Maintained by Maidenhead; derived from **MASH by Malk**.

## User interface and navigation
- Refined the dark/gold Warcraft-style interface across settings, with clearer group navigation, selected states, tabs, button hierarchy and spacing.
- Improved long settings pages, compact action controls and footer positioning.
- Fixed overlap between the Undo and Reset HUD positions controls, including adaptive footer placement.

## French and English
- Extended bilingual coverage across navigation, settings, action buttons, dynamic descriptions and labels.
- Language changes refresh bound UI text without restarting the addon.
- Combat-text simulation spell/event samples now follow the selected language.
- Fixed mixed-language section headings and several hardcoded French labels in English mode.

## Combat text and customization
- Three configurable combat-text profiles (Balanced, Quiet, All), with more visible active state and profile-specific resets.
- Improved simulation display and controls, reduced redundant refresh work, and guarded simulation updates after interruptions.
- Preserved saved preferences and real combat calculations.

## HUD previews and layout
- Improved inspector and position controls for HUD cards.
- Representative **demo/sample data** for 19 preview types, including Damage, Revive, Statistics, Bosses, Player/Target health and more.
- Fixed missing or blank preview content, health bar value synchronization and incompatible UI button methods.
- Preview samples are deliberately separate from live player data and do not write to game statistics or SavedVariables.

## Stability and compatibility
- Defensive handling of incomplete combat profiles and invalid display fields.
- C9 code audit and C10 visual/UX polish; 38 Lua modules and all 38 TOC references checked in the local release candidate.
- Maintainer reports successful in-game functional and preview testing. Static checks are not game-engine certification.

## Installation
Download **AzerothFieldKit-0.4.0.zip** from the release **Assets** (not GitHub's automatic Source code ZIP). Back up SavedVariables, replace the old AzerothFieldKit folder in the actual game client's Interface/AddOns folder, disable legacy MASH if active, restart the client and open `/fieldkit`.

## Credits / provenance
Azeroth FieldKit is a maintained derivative of **MASH by Malk**. Previous rights/asset notices and publication limitations remain in effect; see `NOTICE.md`, `LICENSE.md` and `docs/PUBLICATION.md`.
