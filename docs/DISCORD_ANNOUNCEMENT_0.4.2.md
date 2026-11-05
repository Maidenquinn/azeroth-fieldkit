# Discord announcement — Azeroth FieldKit v0.4.2

**Azeroth FieldKit v0.4.2 is out!**

This update focuses on native chat stability and optional diagnostics.

**Chat fixes**
- Improved preservation of captured messages when switching chat customization off and back on.
- Restored chat width, height, font family and font size settings after a regression in the preview builds.
- Safer recoloring of messages when the full visible history is recoverable.
- Clarified the difference between local opt-in chat copying and temporary display recovery.

**New diagnostic commands**
- `/fieldkit diag on` — start collecting session-only counters.
- `/fieldkit diag report` — view update activity.
- `/fieldkit diag api` — list availability of supported game APIs.
- `/fieldkit diag compat` — check native chat and linked HUD capabilities.
- `/fieldkit diag reset` or `off` — reset or stop diagnostics.

Diagnostics are disabled by default and do not measure precise addon CPU/FPS. The grouped Mode / Damage / Lairs drag behavior remains unchanged.

**Download and full changelog:** https://github.com/Maidenquinn/azeroth-fieldkit/releases/tag/v0.4.2

Back up the existing addon folder and SavedVariables, replace the folder, and restart the game.

Maintained derivative of MASH by Malk. Feedback is welcome.
