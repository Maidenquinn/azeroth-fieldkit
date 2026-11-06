# Discord announcement draft — publish only after GitHub release

**Azeroth FieldKit v0.5.0 is here!**

This is a major HUD customization update compared with v0.4.2.

**HUD Profiles**
- Create, save and name up to three independent HUD setups.
- Switch profiles instantly without a reload for supported settings.
- Access your profiles from Home or the persistent header selector.
- Preview layouts, undo changes and see which profile is active.

**Your setup, your way**
- Each profile keeps its own HUD positions, sizes, collapsed windows, combat text, world markers and other display preferences.
- Chat appearance is profile-specific too: position, size, font, background and message colors.
- Switching chat palettes can update existing visible messages without wiping chat history.

**New collapsed-window dock**
- Fold windows into a movable dock in the bottom-right area.
- Move the dock wherever it works best for your layout.
- Dock position and collapsed states persist per profile, including after `/reload`.

**Polish and reliability**
- Cleaner profile management, custom names and clearer active-profile indicators.
- Improved French/English labels.
- Safer profile saves, validation and rollback to reduce the risk of losing settings.

**Before updating:** Back up your `SavedVariables` folder. Replace the old `AzerothFieldKit` addon folder, restart the game and open `/fieldkit`.

**Download:** [insert the published GitHub release URL]

Thanks for testing and reporting issues!

---
Internal note: do not post this announcement before the public release. A real v0.4.2 saved-data migration fixture and distribution rights review remain outstanding.
