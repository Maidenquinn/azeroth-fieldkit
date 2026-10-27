# Release procedure

## Private review candidate

1. Update Runtime.lua, the controller version and TOC consistently, then changelog.
2. Run static audit, Lua 5.1/prototype tests and the available native Lua 5.0.3 run.
3. Copy the validation report into docs/validation.json for the review snapshot.
4. Commit the runtime, tests and documentation in this dedicated repository.
5. Run package.py. It refuses stale runtime validation or texture inventory.
6. Repeat package.py without changes and compare SHA-256 to prove reproducibility
   on that build environment. ZIP metadata/order are fixed; compression-library
   versions can still affect bit identity across different environments.
7. Create the review tag pointing at the tested commit. Keep the repository
   private and create a **draft/prerelease** with runtime ZIP, SHA256SUMS,
   manifest and validation evidence. No executables or developer dependencies.
8. Give reviewers access only through the appropriate authorization process.
   Do not advertise the candidate as approved or publish to an addon list yet.

## Public release prerequisites

- Recorded applicable upstream code permission/license and asset/data rights.
- Actual game-developer approval bound to the reviewed version/package/hash.
- Authorized current-client in-game acceptance, including minimap/native hooks,
  action bar, old Lua behavior and live performance.
- All remaining review findings explicitly accepted, fixed or features removed.
- Complete credit/licensing notices and accurate installation/removal guidance.

Only then choose the public version/license compatible with the permissions,
rerun verification, package the final commit and publish its exact tag/artifacts.
Checksums establish file identity, not trustworthiness or developer approval.

There is no automatic updater. GitHub Actions validates/packages source changes
but does not create a public release or change repository visibility.
