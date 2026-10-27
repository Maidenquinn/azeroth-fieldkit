# Contributing to the public review candidate

Read NOTICE.md and LICENSE.md before sharing the source. No inherited rights or
game approval have been established. Changes should help review, not evade the
client's addon checks or reproduce hidden data through another access channel.

Keep Lua 5.0 syntax, no dynamic execution/network/process code, and document each
new native effect in API_SURFACE.md. Avoid blanket API modernization and gratuitous
restructuring that would hide the behavioral diff. Keep option names, defaults,
EN/FR strings and tests in sync. Never add game saves or machine-specific paths.

Run audit/verification before packaging. Review callback upvalues and event-global
handling. Add tests for real behavior/failure boundaries, not a restatement of
the implementation. In-game tests require authorization and must be recorded as
such. Do not label an offline screenshot or mock as in-game validation.

See docs/RELEASING.md for the review/approved-release gates. Do not upload
external helpers, native binaries, third-party addon code or extracted game
resources beyond the explicitly declared portrait candidate without review.
