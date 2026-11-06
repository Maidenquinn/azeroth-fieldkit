# Azeroth FieldKit 0.5.0-alpha.4 — Live HUD profile switching + header click fix

This is a **review build, not a public release**. It builds on the maintainer-accepted alpha.1/alpha.2 profile managers.

## Alpha.4 header selector check

Alpha.3 passed 8/9 reported in-game checks; the sole unconfirmed/KO item is the three header buttons. The alpha.4 change raises the selector above the draggable window header and gives it a stable top-right anchor. Test all three clicks with the panel open on Home, Interface and Chat; ensure a click changes profile without dragging or moving the settings panel. Empty slot opens the profile manager. On the native client, screenshot the header if buttons still do not appear or clicks are intercepted. The other accepted behaviors are not intentionally changed.

## One-click access

- Open FieldKit. The header now contains three small profile buttons (1/2/3) on **every page**. Click a saved slot to apply that HUD immediately, or click an empty slot to open the manager.
- The Home page includes a **Quick HUD profiles** section with the same one-click behavior.
- **03 INTERFACE > HUD profiles** remains the complete manager for Save, Confirm overwrite, Apply now, Confirm delete, and Undo last switch.
- Existing slash commands remain available: `/fieldkit profile list|save|load|delete 1-3, undo`. `load` now applies immediately.

## What changes live

FieldKit-owned HUD positions and grouping (left/right), visibility and enabled cards, panel dimensions, card style and background opacity, plus selected FieldKit-owned display preferences.

No saved chat appearance, chat messages, gameplay statistics or co-op communication permissions are loaded. The native compact action bar is **not** changed by live profile switches: this native layout still follows its own reload flow and is excluded from live profile application.

The live controller stops before applying if a FieldKit drag or layout editing is active. It does not call ReloadUI, reconstruct native chat, rebuild the native action bar, change CVars, or send addon messages. The previous HUD preferences are snapshotted for immediate Undo. If a UI refresh fails, the addon attempts to restore the previous preferences and layout. Full automatic rollback of every native frame mutation cannot be guaranteed on every Benilla build.

## In-game recipe

1. Back up both the installed addon folder and FieldKit SavedVariables, then install alpha.4. Check `0.5.0-alpha.4` and absence of Lua errors.
2. Save clearly different **left/right HUD positions, sizes, grouping, opacity and visibility** in slots 1 and 2.
3. Open the HUD manager and select **Apply now** on slot 1. The HUD should change **immediately**, without a reload or stuck mouse drag.
4. Select slot 2 immediately afterward, then select slot 1 again. Check both layouts and grouped Mode/Damage/Lairs movement; test independent mode too.
5. Click **Undo last switch**, confirm it immediately restores the previous layout.
6. Test the three header buttons from different settings pages, and the Home quick buttons. An empty slot should open the full manager.
7. Switch FR/EN. Saved summaries, empty slots, active labels and button captions must all translate correctly.
8. Save and overwrite a slot (requires two clicks) and delete a slot (requires two clicks); check no accidental mutations.
9. Repeat after `/reload` to verify that applied profiles persist and that the version does not unexpectedly reapply a pending alpha.2 request.
10. Confirm native chat width, height, family, size, text history and Copy remain untouched by switching; party sharing permissions and gameplay statistics remain unchanged.
11. Check the native compact action bar is unchanged, as documented; repeat `/fieldkit diag compat`.
12. Attempt a profile switch while actively dragging a FieldKit HUD window, then release the mouse and try again; it must not leave any window attached to the pointer.

## Decision gate

Require all client checks to pass before merging PR #32 into alpha.2 branch or publishing any 0.5.0 release. v0.4.2 remains the official version.
