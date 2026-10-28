-- Real constructors/callbacks: subpage routing, visibility-only preset Undo,
-- native interactions, pinned identity and honest transport state.
FieldKitDB={cardStyle=2,cardOpacity=37,windowsLocked=true,partyCards=false}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("");update(FieldKitFrame,.3)
local U=FieldKitUI
local page=U.windowPage
assert(page and table.getn(page.windowTabs)==4 and page.windowSelected=="display")
local objectsBefore=table.getn(objects)
local writes=0
local oldCvar,oldHud=SetCVar,AZS_SetHudShown
SetCVar=function() writes=writes+1 end;AZS_SetHudShown=function() writes=writes+1 end
for _,tab in ipairs(page.windowTabs) do
 click(tab.button)
 assert(page.windowSelected==tab.id and FieldKitDB.windowPage==tab.id)
 for _,flow in ipairs(page.flow) do assert(flow.frame:IsShown()==(flow.windowTab==tab.id)) end
 assert(page.contentHeight==tab.height)
end
assert(writes==0 and table.getn(objects)==objectsBefore)
U.Select("health");U.Select("windows");assert(page.windowSelected=="coop")
local sw,sh=UIParent.width,UIParent.height;UIParent.width=800;UIParent.height=600
U.Reflow();click(page.windowTabs[2].button)
assert(page.contentHeight>page.scroll:GetHeight())
UIParent.width=sw;UIParent.height=sh;U.Reflow()
-- A visibility preset is explicit and reversible, including prior opt-outs.
local before={}
for _,key in ipairs({"statsFrame","gearFrame","runModeCard","takenFrame","meterFrame","moneyFrame","lairFrame","partyMeter"}) do before[key]=FieldKitDB[key] end
FieldKitDB.moneyFrame=false;before.moneyFrame=false
local anchors=FieldKitDB.frameAnchors;local sizes=FieldKitDB.cardSizes
U.Select("home");local home=U.pages[1]
click(home.essential)
assert(not FieldKitDB.statsFrame and not FieldKitDB.gearFrame and not FieldKitDB.takenFrame and not FieldKitDB.runModeCard)
assert(FieldKitDB.moneyFrame and FieldKitDB.meterFrame and U.previousHud)
assert(FieldKitDB.frameAnchors==anchors and FieldKitDB.cardSizes==sizes)
assert(FieldKitDB.windowsLocked and FieldKitDB.cardStyle==2 and FieldKitDB.cardOpacity==37 and writes==0)
click(home.essential) -- repeated application must keep the original Undo snapshot
click(home.undoPreset)
for key,value in pairs(before) do assert(FieldKitDB[key]==value,key) end
assert(not U.previousHud)
SetCVar=oldCvar;AZS_SetHudShown=oldHud
-- Reordering the original schema cannot bind the boss page to a text option.
local schema=FieldKit.CreateOptionsSchema(U.hudActions)
FieldKit_AddSettingsSections(schema)
for _,section in ipairs(schema) do if section.title=="Combat" then
 local first=table.remove(section.items,1);table.insert(section.items,first)
end end
local rebuilt=FieldKit.BuildJourneySections(schema,U.hudActions)
assert(rebuilt[3].items[1].id=="playerBar" and rebuilt[4].items[1].id=="bossFrame")
assert(U.nativeTextOptions[1].id=="hideDamage" and U.nativeTextOptions[2].id=="showCrits")
-- Missing mode stays hidden by default, but the user can request the unknown card.
AZS_ZONE={};FieldKitRunMode.Update();assert(not FieldKitModeFrame:IsShown())
FieldKitDB.hideUnknownMode=false;FieldKitRunMode.Update();assert(FieldKitModeFrame:IsShown())
FieldKitDB.hideUnknownMode=true
-- Every newly visible label has a French equivalent.
for _,key in ipairs({"Display","Layout","Appearance","Co-op / test","Previews","Pin","Unpin","Use essential HUD","Sharing disabled","Hide native teammate frames"}) do
 assert(FieldKitLocale.fr[key] and FieldKitLocale.fr[key]~=key,key)
end
-- A pinned player remains selected when rows reorder or the mouse leaves.
function UnitExists(unit) return unit=="player" or unit=="party1" end
function UnitName(unit) return unit=="player" and "Maiden" or "Denza" end
function AZS_GetMeter() return {{name="Observed spell",dmg=100,dps=10,share=1}},100,10 end
AZS_PARTY={{name="Denza",dmg=200,dps=20,share=.66,top="Observed ally spell",topdps=20},{name="Maiden",dmg=100,dps=10,share=.33}}
function AZS_GetPartyMeter() return AZS_PARTY end
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSPARTY");update(FieldKitFrame,.3)
local D=FieldKitPartyDetails;local row=FieldKitCoop.meter.rows[1]
this=row;row:GetScript("OnEnter")();assert(D.member=="Denza")
click(D.pin);assert(D.pinned)
this=row;row:GetScript("OnLeave")();NOW=NOW+1;this=D.frame;D.frame:GetScript("OnUpdate")()
assert(D.frame:IsShown())
AZS_PARTY[1].dmg=50;update(FieldKitFrame,.3)
assert(D.member=="Denza" and D.data.rows[1].name=="Observed ally spell")
click(D.pin);assert(not D.pinned);D.Close()
-- Local detail is available without a party and is not truncated to eight rows.
function UnitExists(unit) return unit=="player" end
AZS_PARTY={};update(FieldKitFrame,.3)
local own=FieldKitMeterFrame.rows[1];this=own;own:GetScript("OnEnter")()
assert(D.frame:IsShown() and D.data.own and D.data.rows[1].dmg==100)
click(D.pin);D.frame:Hide();this=D.frame;D.frame:GetScript("OnHide")()
assert(not D.pinned)
this=own;own:GetScript("OnEnter")();assert(D.frame:IsShown())
click(D.pin);AZS_RUN.ph=nil;update(FieldKitFrame,.3);assert(not D.frame:IsShown())
assert(FieldKitPartySync.Status()=="Sharing disabled")
FieldKitDB.partyDetailSync=true;local transport=SendAddonMessage;SendAddonMessage=nil
assert(FieldKitPartySync.Status()=="Sharing unavailable: no addon-message API")
SendAddonMessage=transport
print("Simplified window subpages, reversible essential preset, stable option ids and pinned detail identity passed")
