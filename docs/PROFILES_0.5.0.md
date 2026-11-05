# Azeroth FieldKit v0.5.0-alpha.1 — HUD profile foundations

This first alpha builds on the officially published v0.4.2 and introduces **three named-by-number, manual HUD layout slots**.

## Commands

- `/fieldkit profile list` — show which slots are saved.
- `/fieldkit profile save 1` — store the current HUD layout in slot 1; replace with slot 2 or 3 as needed.
- `/fieldkit profile load 1` — queue slot 1 for application at the next `/reload`. Does not change the live game while a run is active.
- `/fieldkit profile undo` — cancel a queued switch **before** reloading.
- `/fieldkit profile delete 1` — delete the stored slot.

## Safety and scope

Included: FieldKit card grouping/visibility, style/opacity, selected HUD toggles, per-card sizes, collapsed windows, and saved HUD positions.

Explicitly excluded: native chat customization and history, game statistics, equipment, movement/abilities, co-op sharing permissions and transport, and native CVars. Profiles cannot modify non-FieldKit frames.

A saved profile is bounded to three slots. Position tables are copied, not shared with the current live settings. The normal Config.lua validators repair restored layout data before the HUD is initialized.

Slot loading is **staged**. The current window state remains unchanged until `/reload`. `undo` only cancels a queued switch, not a profile already applied on a previous reload. Existing SavedVariables are retained.

## Client test recipe

1. Back up SavedVariables and the existing addon folder, then install alpha.1. Confirm version in FieldKit UI and zero Lua errors.
2. With your current HUD arranged, run `/fieldkit profile save 1`; confirm `profile list` reports slot 1 saved.
3. Move or resize one HUD card, change FieldKit card opacity and grouping. Keep the native chat visible.
4. Run `/fieldkit profile load 1` — the current HUD should **not jump immediately**. Use `profile undo` to cancel once and confirm `/reload` keeps the current layout.
5. Queue slot 1 again, then `/reload`. Confirm the previously saved HUD layout and opacity return.
6. Verify that native chat size/font/messages and co-op permissions have **not** changed.
7. Repeat with slots 2 and 3, including deleting a saved slot. Test an empty/invalid slot; it must report a nonfatal error.
8. Drag the linked Mode/Damage/Lairs group to confirm the 0.4.2 mouse-release fix still works, and test Accessories and Statistics.
9. Confirm `/fieldkit diag compat` and diagnostic ON/OFF still work.

## Boundaries

No new visible profile picker in this alpha. Commands first prove safe persistence and switching. A future v0.5.0 lot can add an in-game profile manager, previews and export/import after the save/load contract is accepted.

Not published or merged into main. The v0.4.2 release remains official.
