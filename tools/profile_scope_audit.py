"""Static coverage gate for persisted FieldKitDB preferences.

A new persisted setting must be either a slot-scoped preference or listed
explicitly as intentionally shared gameplay/operational state. This catches
silent additions that would otherwise leak between HUD profile slots.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothFieldKit"
config = (ADDON / "Config.lua").read_text(encoding="utf8")
profile = (ADDON / "Profiles.lua").read_text(encoding="utf8")
defaults_block = config.split("local defaults={", 1)[1].split(
    "-- Single audited source of defaults", 1)[0]
default_keys = set(re.findall(r"\b([A-Za-z_]\w*)\s*=", defaults_block))
def block(name, until):
    return profile.split("local " + name + "={", 1)[1].split(until, 1)[0]
extras = set(re.findall(r'"([^"]+)"', block("extra", "local tableKeys=")))
tables = set(re.findall(r'"([^"]+)"', block("tableKeys", "local keys,")))
# Optional combat settings are included dynamically from C.defaults. For
# auditing, read the C.defaults literal to prove they are declared.
combat = (ADDON / "CombatText.lua").read_text(encoding="utf8")
combat_defaults = combat.split("C.defaults={", 1)[1].split(
    "\n-- Read and clamp", 1)[0]
combat_keys = set(re.findall(r"\b([A-Za-z_]\w*)\s*=", combat_defaults))
scoped = default_keys | extras | tables | combat_keys
shared = {
    # Addon state, saved run telemetry and learned classifications.
    "known", "lastStats", "chestsOpened",
    # Navigation and view history, not gameplay/interface settings.
    "uiSchema", "uiPage", "panelSection", "panelTab", "windowPage",
    # Profile storage and migration itself.
    "schema", "activeHudProfile", "interfaceProfiles", "profilePendingSlot",
    # Technical bookkeeping for native game-owned overlays. These are derived
    # from individual display options, never copied as user preferences.
    "hudBossesHidden", "hudMeterHidden", "hudTallyHidden", "moneyDockRepair",
}
discovered = set()
for path in ADDON.glob("*.lua"):
    if path.name == "Profiles.lua":
        continue
    source = path.read_text(encoding="utf8")
    discovered.update(re.findall(r"\bFieldKitDB\.([A-Za-z_]\w*)", source))
    if path.name == "FieldKit.lua":
        discovered.update(re.findall(r"\bDB\.([A-Za-z_]\w*)", source))
unknown = discovered - scoped - shared
assert not unknown, "Unclassified FieldKitDB fields: " + ", ".join(sorted(unknown))
assert not (scoped & shared), "Profile/shared scope overlap: " + ", ".join(sorted(scoped & shared))
print(
    f"Profile scope audit: {len(scoped)} declared preferences and "
    f"{len(shared)} explicitly shared/operational fields; "
    f"{len(discovered)} static field references classified."
)
