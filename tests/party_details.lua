-- Verify honest provenance and the actual hover/paging handlers, not fictitious
-- peer spell packets. The local table deliberately exceeds the meter's 8 rows.
function UnitExists(unit) return unit=="player" or unit=="party1" end
function UnitName(unit) return unit=="player" and "Maiden" or (unit=="party1" and "Denza") end
local spells={}
for i=1,23 do table.insert(spells,{name="Actual spell "..i,dmg=2400-i*10,dps=240-i,share=.04,proc=i==2 and 1 or 0}) end
function AZS_GetMeter() return spells,123456,321 end
AZS_PARTY={{name="Maiden",dmg=5000,dps=500,share=.8},{name="Denza",dmg=1000,dps=100,share=.2,top="Shadow Bolt",topdps=40}}
function AZS_GetPartyMeter() return AZS_PARTY,6000,600 end
FieldKitDB={partyMeter=true,cardOpacity=0}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSPARTY");update(FieldKitFrame,.3)
local P,D=FieldKitCoop,FieldKitPartyDetails
local own,peer=P.meter.rows[1],P.meter.rows[2]
local function enter(frame) this=frame;frame:GetScript("OnEnter")() end
local function leave(frame) this=frame;frame:GetScript("OnLeave")() end
enter(own)
assert(D.frame:IsShown() and D.member=="Maiden" and D.data.own)
assert(table.getn(D.data.rows)==23 and D.data.damage==123456 and D.data.dps==321)
assert(D.summary:GetText()=="Damage: 123456   DPS: 321")
assert(D.frame.rows[1].label:GetText()=="Actual spell 1")
assert(D.frame.rows[1].meterColumns[1]:GetText()=="2390")
assert(D.frame.rows[1].meterColumns[2]:GetText()=="239 dps")
assert(D.frame.rows[1].label:GetWidth()+3<=D.frame.rows[1]:GetWidth()-131-92)
assert(D.frame.fieldkitSkin.base:GetAlpha()==1,"HUD opacity made the hover card unreadable")
assert(D.next:IsShown() and D.footer:GetText()=="Spells 1–10 / 23")
this=own;arg1=-1;own:GetScript("OnMouseWheel")();assert(D.offset==3)
this=own;arg1=1;own:GetScript("OnMouseWheel")();assert(D.offset==0)
click(D.next);assert(D.offset==10 and D.frame.rows[1].label:GetText()=="Actual spell 11")
this=D.frame;arg1=-1;D.frame:GetScript("OnMouseWheel")()
assert(D.offset==13 and D.footer:GetText()=="Spells 14–23 / 23")
click(D.previous);assert(D.offset==3)

-- Crossing onto the card keeps it open so wheel/buttons can be used.
leave(own);enter(D.frame);NOW=NOW+1;this=D.frame;arg1=.3;D.frame:GetScript("OnUpdate")()
assert(D.frame:IsShown())
leave(D.frame);NOW=NOW+.3;this=D.frame;D.frame:GetScript("OnUpdate")()
assert(not D.frame:IsShown() and D.data==nil)

-- A peer gets only their real top spell/rate. No self spells or inferred damage.
enter(peer)
assert(not D.data.own and table.getn(D.data.rows)==1)
assert(D.frame.rows[1].label:GetText()=="Shadow Bolt")
assert(D.frame.rows[1].meterColumns[1]:GetText()=="?")
assert(D.frame.rows[1].meterColumns[2]:GetText()=="40 dps")
assert(D.frame.rows[1].meterColumns[3]:GetText()=="?")
assert(D.data.rows[1].dmg==nil and D.data.rows[1].share==nil)
assert(D.hint:GetText()=="Allies: only their top spell is exposed. Full breakdown unavailable.")
assert(not D.next:IsShown())
local created=table.getn(objects)
D.Close();enter(own);D.Close();enter(peer)
assert(table.getn(objects)==created,"Re-hover allocated another detail panel")

-- The anchor chooses the other side near the screen edge. The native clamp
-- handles vertical bounds; no SavedVariables or persisted position is involved.
function peer:GetRight() return UIParent:GetWidth()-5 end
D.Render();local point,relative,rp=D.frame:GetPoint()
assert(point=="TOPRIGHT" and relative==peer and rp=="TOPLEFT" and D.frame.clamped)
UIParent.width=800;UIParent.height=600;D.Render()
assert(D.frame:GetWidth()<=776 and D.frame:GetHeight()<600)
UIParent.width=1920;UIParent.height=1080

-- A row changing rank must not retain the former occupant's spell breakdown.
D.Close();enter(own)
AZS_PARTY={{name="Denza",dmg=9000,dps=900,share=.9,top="Fire Blast",topdps=80},{name="Maiden",dmg=5000,dps=500,share=.1}}
fire(FieldKitFrame,"CHAT_MSG_ADDON","AZSPARTY");update(FieldKitFrame,.3)
assert(D.member=="Denza" and not D.data.own and D.frame.rows[1].label:GetText()=="Fire Blast")
AZS_PARTY[1].top=nil;AZS_PARTY[1].topdps=nil;update(FieldKitFrame,.3)
assert(table.getn(D.data.rows)==0 and D.footer:GetText()=="No spell detail provided")

-- Close when the owner disappears/collapses or placement begins.
click(P.meter.mashCollapseButton);update(FieldKitFrame,.3)
assert(not D.frame:IsShown())
click(P.meter.mashCollapseButton);enter(P.meter.rows[2])
FieldKitUI.SetLayoutEditing(true,false);assert(not D.frame:IsShown())
enter(P.meter.rows[1]);assert(not D.frame:IsShown())
FieldKitUI.SetLayoutEditing(false,true)

-- Safety truncation is explicit; missing APIs never create a substitute list.
for i=24,520 do table.insert(spells,{name="Actual spell "..i,dmg=i,dps=1}) end
local data=D.Data("Maiden");assert(data.truncated and table.getn(data.rows)==512)
local original=AZS_GetMeter;AZS_GetMeter=function() error("not available") end
data=D.Data("Maiden");assert(data.unavailable and table.getn(data.rows)==0)
AZS_GetMeter=original
FieldKit_SetLanguage("fr");assert(FieldKit_L("Spell")=="Sort")
assert(FieldKit_L("Allies: only their top spell is exposed. Full breakdown unavailable.")=="Alliés : seul leur meilleur sort est fourni. Détail complet indisponible.")
print("Party hover provenance, full local list, honest peer fallback, paging and lifetime fixtures passed")
