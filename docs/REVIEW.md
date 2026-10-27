# Manual approval dossier

**Azeroth FieldKit 0.1.0-review.3 — submitted candidate, not approved.**

Maintainer: Kevin Radlowski / Maidenhead. Origin: MASH by Malk. This dossier is
prepared for game developers to inspect; it has not been sent to them by a tool.

## Suggested review order

1. NOTICE.md / LICENSE.md: inheritance, missing upstream permission and game assets.
2. SECURITY.md: findings, fixes, remaining risks and limits of this assessment.
3. Runtime.lua / Config.lua: allowed native writes and conservative defaults.
4. API_SURFACE.md: every class of hook, native setting and player action.
5. FieldKit.lua / OptionsSchema.lua: native UI replacement and exact option actions.
6. WorldPins.lua / Portraits.lua: information exposed independently of target.
7. CopyLog.lua: explicit consent and the only local text-export mechanism.
8. tools/audit.py, tools/verify.py, docs/validation.json and release manifest.

## Decisions requested from developers

- Is showing native chest/lair coordinates and off-screen direction acceptable?
- Are boss/guardian status displays and independent static portraits acceptable?
- Is filtering nameplates through WorldFrame reparenting acceptable, or should
  that implementation be removed/replaced with a sanctioned client API?
- Are the existing camera range and native HUD CVar changes within allowed limits?
- Is the optional compact action bar, including player-driven action-slot swaps,
  acceptable? It never executes combat actions automatically.
- Is opt-in local main-chat copying acceptable? If not, this independent module
  can be removed with its TOC entry, option, command and tests in a future revision.
- May the client-derived portrait renders/catalog be redistributed in this addon?
- What client build, package format and hash/version procedure should approval bind?

Do not claim that disabling these options bypasses the need to approve the addon.
The entire shipped code and its available capabilities are disclosed.

## Release blockers

- Malk's modification/redistribution permission or an applicable upstream license
  has not been obtained from the examined material.
- Distribution rights for game-derived portraits/data remain unconfirmed.
- Current developer approval rules and any rejection explanation are not supplied.
- The renamed/refactored candidate has not been visually/integration-tested in
  the running game. Historical MASH user tests are not validation of this fork.

The maintainer has authorized a public repository and review prerelease so game
developers can inspect the candidate. This is not a certification, a license grant
or an approved replacement for MASH.

## Maintainer assurances supported by this work

- Original installed MASH is backed up, hashed and unmodified by this work.
- Death Recap, Azeroth Stats and other addons are outside scope and not edited.
- No executable, MPQ or game save has been altered; no external helper is required.
- Runtime source is visible, unobfuscated, bounded at key inputs and listed by TOC.
- No telemetry, outbound chat/messages or dynamic execution is present in the
  reviewed runtime. Native effects and exceptions to read-only behavior are listed.
- Tests are reproducible and their limitations are explicit. An approval decision
  must be made by the developers, not inferred from those tests.
