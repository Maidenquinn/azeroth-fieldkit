# Attribution and provenance

## Original project

MASH — Malk Azeroth Survivor Helper was created by **Malk**. The original Discord
announcement and the inspected TOC identify Malk as its author. The baseline for
this fork is the locally installed **MASH 1.3.9** snapshot, not a pristine author
release: it already contains the community changes developed with Maidenhead.
The earliest local backup is itself a modified beta. We cannot attribute every
line in that historical snapshot to a particular contributor.

**No license file or explicit redistribution/modification permission was found
in the inspected local addon and supplied announcement. No author approval has
been obtained or inferred.** This is a provenance limitation, not an allegation
that MASH is malicious or a finding about why the game removed it.

## Maintained fork

**Azeroth FieldKit**, maintained by **Kevin Radlowski / Maidenhead**, introduces
the review-oriented changes described in CHANGELOG.md. Code and documentation
were developed with assistance from ChatGPT/Codex. A new title, repository or
namespace does not turn inherited code into exclusively owned new work.

The first Git commit preserves the exact inspected runtime snapshot. Its
`docs/UPSTREAM_MANIFEST.json` records relative file paths and SHA-256 hashes.
Subsequent commits identify the fork changes. The snapshot is available for
public technical review at the maintainer’s explicit request; no independently
licensed distribution or upstream permission is asserted.

## Game-derived assets and data

The 98 TGA portraits are static renders derived from native model/texture data.
The catalog contains client-derived creature/display identities and localized
names. Rights to game assets/data are not assigned to this project. Their inclusion
in a public distribution must be cleared with the relevant rights holders and the
game's maintainers. The old MASH branding icon is not shipped by the fork; its
minimap shortcut uses an existing native icon path instead.

The older portrait investigation is retained in docs/history/PORTRAITS.txt as
historical evidence. Its old filenames, dates, commands and validation claims
describe MASH at that time; use the current README and test report for FieldKit.
Old developer test scripts, native binaries and reverse-engineering tools are
not part of this repository or its addon package.

## Design/API references

- MikScrollingBattleText was consulted for configuration concepts (categories,
  fonts/colors, grouping and areas). No external MSBT installation is needed;
  no MSBT source, bundled libraries or fonts are shipped in FieldKit.
- LuckyOdds by cadoky was consulted during the earlier minimap API investigation.
  WorldPins.lua is a separate implementation and has no LuckyOdds dependency.

References: https://www.curseforge.com/wow/addons/mik-scrolling-battle-text and
https://github.com/cadoky/LuckyOdds. These are attribution references, not evidence
of permission from Malk, Blizzard or the Azeroth Survivors developers.
