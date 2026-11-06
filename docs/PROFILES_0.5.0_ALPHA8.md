# Azeroth FieldKit 0.5.0-alpha.8 — Profile naming UX polish

This test build uses the same accepted profile isolation and instant switching introduced in alpha.6 and the naming behavior tested in alpha.7.

## What changed
- The Rename action now switches that profile card into a dedicated edit state instead of placing the input over the saved summary text.
- The input has its own horizontal row. Normal Save/Apply/Delete/Rename actions are temporarily replaced by **Save name** and **Cancel**, preventing overlapping text and click targets.
- Press Enter to save or Escape to cancel. Invalid names keep the editor open and display a short hint.
- FR/EN actions and guidance have proper translations. The actual profile name remains unchanged until Save name or Enter.
- Existing saved names, slots, chats, gameplay data, positions, and profile quick-switching are unchanged.

## Native-client recipe
1. Back up SavedVariables, install alpha.8 and open Interface → Profiles.
2. Click Rename on a saved profile. Confirm the summary disappears, the text input is fully readable, and only Save name/Cancel remain on the card's action row.
3. Rename slot 1 to `Donjons FR` and slot 2 to `Coop` using Save name and Enter respectively. The Home quick labels should match.
4. Click Rename again, type a different name, press Cancel or Escape: the old saved name should remain.
5. Submit an empty name. The editor should stay open and show validation feedback without corrupting the old name.
6. Change FR/EN, scroll the page, and check the edit controls don't overlap text or other buttons. Check responsive reflow when moving/resizing the settings panel.
7. Verify names survive /reload, profile 1→2→1 switches, and original chat font/color/geometry behavior remains.
8. Test linked Mode/Damage/Lairs dragging, immediate undo, and the native chat history. No new Lua errors.

PR remains draft; official v0.4.2 is unchanged.
