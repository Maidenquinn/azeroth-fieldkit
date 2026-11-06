# FieldKit 0.5.0-alpha.7 — Named profile slots

**Status:** unpublished test build, stacked on the maintainer-approved alpha.6. Official v0.4.2 remains available.

## What's new
- Up to three independent configuration profiles can optionally have human-friendly names such as "Donjons FR", "Solo" or "Co-op".
- Open /fieldkit > Interface > Profiles and click Rename on any existing slot. Type a name and press Enter to save or Escape to cancel.
- Slot names are displayed on the manager card and in Home quick-access controls. The persistent header remains 1 / 2 / 3 to preserve narrow-screen layout.
- Slash fallback: `/fieldkit profile name 1 Donjons FR`.
- Names are metadata belonging to each slot; they are not copied from one profile to another. Deleting a slot also deletes its name. Save, SaveActive, profile switches and /reload preserve names.
- Name validation: 1–40 bytes, no control characters or WoW color escape separators, never interpreted as Lua or addon commands. A 40-byte cap is intentional to avoid truncating multibyte characters.

## Client checks
1. Back up SavedVariables, install alpha.7 and verify the version; no Lua errors.
2. Open the Profiles page. Rename slot 1 to "Donjons FR", slot 2 to "Exploration".
3. Verify both labels appear correctly on the manager cards and the Home quick profile buttons.
4. Switch profiles 1 → 2 → 1; verify names persist, and all chat settings, existing messages and HUD layout stay isolated.
5. Change slot 1, save it again, and verify its name is not lost. Repeat after /reload or restart.
6. Escape from editing without saving: the previous name must remain.
7. Attempt invalid input (empty or >40 bytes): rename must not overwrite the old name.
8. Delete slot 2 with the existing two-click confirmation; its name should disappear with the slot, not from slot 1.
9. Confirm FR/EN navigation, instant selection, Undo, linked Mode/Damage/Lairs drag and chat color history are still correct.

## Future roadmap
The next lots after alpha.7 are visual profile summaries/previews, optional collapsing of FieldKit-owned panels and alignment aids. They must pass native client QA without destabilizing profile isolation, chat, or mouse drag.
