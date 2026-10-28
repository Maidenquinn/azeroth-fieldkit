# Verified-addon publication record

## Current update — 0.2.3

On 2026-10-28 the maintainer accepted the UX changes and explicitly requested the
pending PRs be merged into main, followed by a public update and a prepared Discord
changelog. This records maintainer authorization, not a new game-team or independent
security certification. Live peer-message forwarding remains unconfirmed.

- Release: https://github.com/Maidenquinn/azeroth-fieldkit/releases/tag/v0.2.3
- Asset: `AzerothFieldKit-0.2.3.zip`.
- Maturity: GitHub prerelease, consistent with the existing publication workflow.
- Source commit and per-file hashes: release `MANIFEST.json`.
- Archive checksum: release `SHA256SUMS.txt` (kept outside the self-containing ZIP).
- Offline validation: release `validation.json`; no agent-performed in-game test.
- Notes: [RELEASE_0.2.3.md](RELEASE_0.2.3.md). Discord draft:
  [DISCORD_ANNOUNCEMENT.md](DISCORD_ANNOUNCEMENT.md). No Discord message was sent.

The older package record below is historical; its ZIP and tag remain immutable.


## Reported authorization — 2026-10-28

Kevin / Maidenhead reports permission from the Azeroth Survivors team to post
Azeroth FieldKit as a verified addon, and receipt of the relevant Discord role.
Source: the maintainer's direct instruction in this project's working conversation.
No verbatim team message, named approver, version/hash binding, feature-specific
conditions or permission applying automatically to future updates was provided.
Do not invent any of those details or describe this as a security certification.

## Historical package — 0.2.1-review.3

- Version: **0.2.1-review.3**. The suffix remains the actual version; there is no 1.0 release.
- Release: https://github.com/Maidenquinn/azeroth-fieldkit/releases/tag/v0.2.1-review.3
- Asset: `AzerothFieldKit-0.2.1-review.3.zip` (5,806,371 bytes).
- SHA-256: `8b3d99a0d3375fca93eded03b6020c815aa91dffb4952b68d2c41085928b43f3`.
- Source: `7b54fa035410280c4ac7d54e7d4e800eba330310`.

Do not replace the asset or move its tag. This documentation update changes no
runtime code, defaults, saved data or installed addon. Its updated documentation
is on the repository; the ZIP retains its historical documentation and metadata.
The old `approval: not approved` fields describe the audit/package creation time,
before the maintainer reported permission. They are not a live policy lookup.

GitHub's prerelease flag remains: publication eligibility and technical maturity
are separate. The final edge-drag correction still requires in-game confirmation.
Lua 5.0.3/5.1 checks are offline tests; no live performance benchmark is claimed.
Game-team publication permission does not by itself grant an upstream MASH
license or game-asset rights. Keep NOTICE.md and LICENSE.md unchanged.

## Historical 0.2.1-review.3 posting checklist

1. Use the English text in DISCORD_ANNOUNCEMENT.md. Its main block fits one
   standard 2,000-character Discord message. Copy its contents, not the fences.
2. Post in the team's designated verified-addon channel using the granted role.
   Follow any channel-specific template or instructions given by the team.
3. Link the release and repository. If attaching a ZIP, attach the exact asset
   above; verify its checksum first. Source archives are not the runtime package.
4. Optional screenshots: settings Overview, combat editor and HUD. Avoid private
   chat, account details or unrelated addons; do not imply unshown features.
5. After posting, optionally record the Discord post link here. No post was sent
   by the preparation tools, and no Discord link has been invented.

## Player support

Issues: https://github.com/Maidenquinn/azeroth-fieldkit/issues

Ask for addon version, client version, language, resolution/UI scale, enabled
modules, steps, expected/actual behavior and exact Lua error if any. Screenshots
should exclude private chat. Never request game saves, account.txt or credentials.
For overlap problems, first disable MASH or an addon replacing the same UI.
To stop using FieldKit, disable it and restart. Native visual settings it changed
may persist; restore camera/damage/HUD preferences in the game's own settings.

## Future updates

Keep the branch → PR → CI → merge → immutable tag → checksum release workflow.
Describe native API/feature changes so the team can assess them. Follow its
current review policy before promoting later packages; permission for future
changes is not assumed from this report.
