# Suggested message to game developers (not sent)

Hi! I'm preparing **Azeroth FieldKit**, a maintained fork of **MASH by Malk**,
for your manual addon review. I am not claiming that a rename makes the old
code approved or changes Malk's authorship. The specific reason for MASH's
untrusted classification has not been provided to me.

The public repository preserves the exact inspected MASH 1.3.9 snapshot and
the subsequent changes, with a detailed README, native API effects inventory,
source comments, security findings and reproducible runtime ZIP/manifest/hash.

The candidate removes native talent-state restoration and automatic chat capture.
Chat copying is now opt-in, memory-only and bounded. Native setting writes are
allowlisted. Nameplate filtering, minimap markers, native HUD replacement and
the compact action bar are off by default, but their capabilities remain fully
visible in the code for your decision. No external helper, telemetry, network
messages or dynamic execution is included in the runtime.

The remaining approval questions include native chest/lair markers, nameplate
reparenting, the camera range, compact-bar player-driven slot swapping and the
game-derived portrait assets. These are listed explicitly in docs/REVIEW.md.
Offline Lua 5.0.3/5.1 tests pass; the renamed candidate still needs authorized
in-game integration testing. It is published as a review prerelease, not as an approved/stable release.

Upstream code permission and game-asset redistribution rights also remain to be
clarified. Public access is provided for your technical review and does not imply that
those permissions or game approval have been obtained.
Could you specify the accepted feature boundaries and the process/build against
which you want the candidate reviewed? I can adjust or remove disputed modules
before any public distribution.
