# Azeroth FieldKit 0.6.0

## Highlights
- New Elwynn-themed HUD layouts, interactive cards, native data integrations, placement and scaling controls.
- Improvements to chat styling, HUD profiles, minimap and launcher presentation.
- Performance optimizations: avoid unnecessary HUD teardown when changing scale; reduce redundant chat/theme refreshes; scan Loadout on changes rather than every frame; additional diagnostic controls.
- Existing SavedVariables remain in place; back up your settings before upgrading.

## Not included
- **Naxxramas is not released in 0.6.0.** Its unfinished theme is hidden from the player menu and blocked for ordinary selection. Development assets and internal regression fixtures remain in the source tree for a future update.

## Validation scope
- Maintainer reported no microfreezes during approximately five minutes of gameplay at x10 speed with the theme active, and accepted the other tested functionality.
- This does not establish long-session performance or a full native-client regression certification.
- Release must not be published until the CI verification suite and distribution manifest pass for the exact release commit.

## Install
1. Close Azeroth Survivors.
2. Back up the current `AzerothFieldKit` addon folder and `FieldKitDB` SavedVariables.
3. Replace only the `AzerothFieldKit` folder in your game's `AddOns` directory with the folder from the release ZIP.
4. Restart the game and open `/fieldkit`.

Source: https://github.com/Maidenquinn/azeroth-fieldkit
