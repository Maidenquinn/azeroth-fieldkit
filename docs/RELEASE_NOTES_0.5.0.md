# Azeroth FieldKit 0.5.0 — Release notes (compared with 0.4.2)

> Prepared for publication. RC.1 has passed CI #659 and was accepted in-game by the maintainer. This is **not** a published release; distribution approval and real 0.4.2 save migration have not been independently verified.

## HUD profiles — new

- Three separately saved, optionally named HUD configurations.
- Apply an existing profile **instantly**, without a required `/reload` for supported settings.
- Quick access from Home and the persistent header selector, with clear active-state styling.
- Profile manager supports save, rename, preview, cancel/restore and undo flows.
- Automatically capture edits when leaving a profile and save the active profile at logout.
- Older 0.5.0 alpha layout-only profile snapshots can be upgraded to the expanded configuration schema.

## Per-profile configuration

- Isolate window positions, sizes, grouping, visibility, card appearance and collapsed states.
- Include combat text profiles, world marker settings, meter display, camera and accessibility preferences, party UI and sharing options.
- Include native chat appearance: size, position, font, background and message colors.
- Keep recorded combat/game statistics, live chat messages and navigation state **outside** HUD profile switching.

## Native chat and HUD quality of life

- Repaint recoverable existing chat messages when switching to a profile with different text colors, without clearing the chat history.
- Reset HUD positions restores the chat frame's original size and placement; undo also restores its previous dimensions.
- New movable bottom-right dock gathers collapsed windows, including mode, effects and reminders.
- Remember dock location and collapsed windows separately per profile, including across `/reload`.

## User interface and localization

- Dedicated profile management interface with independently scoped name editors and Save/Cancel actions.
- Active profile highlighted in the header, manager and Home; custom names shown in shortcuts.
- FR/EN strings for profile controls and dock interactions; language changes refresh supported UI labels.
- Improved input spacing, selection visuals and click targets.

## Stability, persistence and testing

- Validate incoming snapshots before applying and roll back failed profile switches.
- Preserve malformed profile slots for manual recovery; reject accidental overwrite and label them `damaged` in the CLI.
- Additional tests for profile isolation, native chat preservation, logout saves, rollback, UI controls and dock persistence.
- Automated CI #659 passed for the RC.1 runtime package. Maintainer confirmed the RC.1 works in-game.

## Upgrade instructions

1. **Back up** your current `SavedVariables` and `AzerothFieldKit` directory before replacing anything.
2. Install the versioned ZIP's `AzerothFieldKit` folder in the active client's AddOns directory.
3. Restart the game and open settings with `/fieldkit`.
4. Verify existing chat and HUD configuration, then create and switch profiles.

**Compatibility note:** No authentic 0.4.2 SavedVariables file was available for migration testing. Automated fixtures and an in-game RC.1 test are not equivalent to a real old-save migration test. Keep a backup and report any unexpected change.

**Publication status:** Release notes prepared, not a public GitHub release. Rights and package-specific distribution permission still require confirmation.
