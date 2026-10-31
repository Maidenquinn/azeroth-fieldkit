# Release procedure

## Update authorized 2026-10-31 — v0.3.0

The maintainer requested this native-tools release. Keep the branch → PR → CI →
main → immutable tag workflow. Build the merged commit twice and compare the ZIP
hash, publish ZIP/manifest/checksum/validation as a GitHub prerelease, and verify
uploaded assets before publication. Preserve older tags/assets. Prepare the Discord
changelog for manual posting; do not claim real game/network testing.


## Update authorized 2026-10-28 — v0.2.3

The maintainer accepted the UX work and requested merging all pending PRs and
publishing this update. Merge dependencies in order with checks passing; prepare
version/docs/evidence on a release branch and PR to main; tag the tested merged
commit. Publish a new immutable ZIP, manifest, checksum and validation report as a
GitHub prerelease. Never overwrite the old release or claim live peer transport.
The Discord draft is prepared for the maintainer to send manually.


## Historical publication status — initial announcement

On 2026-10-28 the maintainer reported permission to post FieldKit as a verified
addon. See PUBLICATION.md for scope and the retained package identity, and
DISCORD_ANNOUNCEMENT.md for the prepared message. Keep the existing ZIP/tag and
prerelease maturity label; do not silently replace them or change client checks.
The current permission does not resolve upstream licensing or authorize future
feature changes automatically.

## Original public technical-review procedure (historical)

The maintainer explicitly requested a public repository and review prerelease on
2026-10-27 to share the addon with DK, a game developer. Preserve the attribution,
unresolved licensing status and lack of game approval on every review release.
Public access does not settle author/asset permissions or authorize game-rule bypasses.

1. Update the TOC and Runtime.lua version, changelog and current review status.
2. Run static audit, Lua 5.1/prototype tests and available native Lua 5.0.3 fixtures.
3. Copy the local validation snapshot into docs/validation.json, then commit.
4. Run package.py; it rejects stale validation/inventory and dirty source trees.
5. Repeat the build and compare SHA-256 for reproducibility on those inputs.
6. Tag the tested commit and publish a **prerelease**, explicitly awaiting review.
   Include runtime ZIP, file manifest, SHA256SUMS and validation evidence.
7. Share the repository for examination. Do not call it approved or stable and
   do not change approval/version checks to make the client accept it.

## Approved general-use release prerequisites

- Resolve applicable upstream code permission/license and asset/data rights.
- Obtain game-developer approval tied to the exact version/package/hash.
- Complete authorized current-client integration/performance tests.
- Resolve, remove or explicitly accept the review findings and native effects.
- Keep accurate credits, licensing, installation and removal instructions.

Only then prepare an approved release and select a license compatible with the
permissions. Checksums establish file identity, not trustworthiness or approval.

There is no automatic updater. CI validates/packages source; publication and
repository-visibility changes require an explicit maintainer action.
