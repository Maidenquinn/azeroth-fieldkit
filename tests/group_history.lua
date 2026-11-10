-- Group action history: parsing of the client's own localized combat-log formats, bounded memory, independent options,
-- roster hygiene, FR/EN, the runtime probe and a performance budget. Synthetic: the real delivery of the events is what
-- /fieldkit groupprobe events measures in the game.
local members={party1="Denza",party2="Lockpin",party3=nil,party4=nil}
function UnitExists(unit) return unit=="player" or members[unit]~=nil end
function UnitName(unit) if unit=="player" then return "Maiden" end return members[unit] end
date=function() return "12:00:00" end
-- the English vanilla formats, provided the way the client provides them (globals)
SPELLLOGOTHEROTHER="%s's %s hits %s for %d."
SPELLLOGCRITOTHEROTHER="%s's %s crits %s for %d."
SPELLLOGSCHOOLOTHEROTHER="%s's %s hits %s for %d %s damage."
PERIODICAURADAMAGEOTHEROTHER="%s suffers %d %s damage from %s's %s."
HEALEDOTHEROTHER="%s's %s heals %s for %d."
HEALEDCRITOTHEROTHER="%s's %s critically heals %s for %d."
PERIODICAURAHEALOTHEROTHER="%s gains %d health from %s's %s."
SPELLCASTOTHERSTART="%s begins to cast %s."
SPELLINTERRUPTOTHEROTHER="%s interrupts %s's %s."
AURAADDEDOTHERHELPFUL="%s gains %s."
AURAREMOVEDOTHER="%s fades from %s."
FieldKitDB=nil
fire(FieldKitFrame,"VARIABLES_LOADED")
local H=FieldKitGroupHistory
H.formats=nil
H.Clear()

-- defaults and bounds
assert(FieldKitDB.partyHistory==false and FieldKitDB.partyHistoryCount==5 and FieldKitDB.partyShow==true and FieldKitDB.partyPlayerCard==false and FieldKitDB.partyDetail==2 and FieldKitDB.partyCardScale==100,"option defaults")
assert(FieldKitDB.partyHistoryBuffs and FieldKitDB.partyHistoryCombat and FieldKitDB.partyHistoryIcons,"independent option defaults")

-- compile: plain and positional (localized) formats
local pattern,order=H.Compile("%s's %s hits %s for %d.")
assert(pattern=="^(.-)'s (.-) hits (.-) for (%d+)%.$" and order[1]==1 and order[4]==4,"pattern "..tostring(pattern))
local p2,o2=H.Compile("%2$s de %1$s touche %3$s pour %4$d.")
assert(o2[1]==2 and o2[2]==1 and o2[3]==3 and o2[4]==4,"positional order is kept")
assert(H.Compile("")==nil and H.Compile(nil)==nil,"no format, no pattern")

-- option off: nothing is registered and nothing is kept
H.Sync();assert(not H.registered,"history off: no event registered")
assert(H.Handle("CHAT_MSG_SPELL_PARTY_DAMAGE","Denza's Frostbolt hits Boar for 40.")==false,"history off: not recorded")
assert(table.getn(H.Recent("Denza"))==0)

-- option on: events registered
FieldKitDB.partyHistory=true;H.Sync()
assert(H.registered,"events registered")
for _,e in ipairs({"CHAT_MSG_SPELL_PARTY_DAMAGE","CHAT_MSG_SPELL_PARTY_BUFF","CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE","CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS","CHAT_MSG_SPELL_AURA_GONE_PARTY"}) do assert(H.frame.events[e],e.." is registered") end

-- kinds
assert(H.Handle("x","Denza's Frostbolt hits Boar for 40."))
assert(H.Handle("x","Denza's Frostbolt crits Boar for 80."))
assert(H.Handle("x","Denza's Fireball hits Boar for 55 Fire damage."))
assert(H.Handle("x","Boar suffers 12 Nature damage from Denza's Sting."),"periodic damage is attributed to the caster")
assert(H.Handle("x","Lockpin's Flash Heal heals Denza for 300."))
assert(H.Handle("x","Lockpin's Flash Heal critically heals Denza for 600."))
assert(H.Handle("x","Denza gains 25 health from Lockpin's Renew."),"hot attributed to the caster")
assert(H.Handle("x","Denza begins to cast Frostbolt."))
assert(H.Handle("x","Lockpin interrupts Boar's Heal."))
assert(H.Handle("x","Denza gains Arcane Intellect."),"buff attributed to the one who gains it")
assert(H.Handle("x","Arcane Intellect fades from Denza."))
local r=H.Recent("Denza",20)
assert(table.getn(r)==5 and r[1].kind=="fade","count is bounded by the option (5) and newest first ("..table.getn(r)..")")
local h=H.log.Lockpin;assert(h[1].kind=="heal" and h[1].amount==300 and h[1].target=="Denza" and h[1].spell=="Flash Heal" and h[2].crit==true,"heal fields")
assert(h[table.getn(h)].kind=="interrupt" and h[table.getn(h)].target=="Boar" and h[table.getn(h)].spell=="Heal","interrupt: author, target and the interrupted spell")
assert(r[1].stamp=="12:00:00","timestamp from the client's date()")

-- nothing invented, nothing from strangers
local before=H.stats.matched
assert(H.Handle("x","Some text that matches no known format")==false and H.stats.unmatched>0,"unmatched message is counted, not guessed")
assert(H.Handle("x","Stranger's Frostbolt hits Boar for 40.")==false,"someone who is not in the group is ignored")
assert(H.Handle("x","Denza's Pet Bite hits Boar for 4.")==true,"member name matched")
assert(H.Handle("x","Boarpet's Bite hits Denza for 4.")==false,"pets and monsters are ignored")
assert(H.Handle("x",nil)==false,"nil message")

-- independent options
FieldKitDB.partyHistoryBuffs=false;local n=table.getn(H.log.Denza)
assert(H.Handle("x","Denza gains Mark of the Wild.")==false and table.getn(H.log.Denza)==n,"buffs off: not recorded")
assert(H.Handle("x","Denza's Frostbolt hits Boar for 41.")==true,"damage still recorded")
FieldKitDB.partyHistoryBuffs=true;FieldKitDB.partyHistoryCombat=false
assert(H.Handle("x","Denza's Frostbolt hits Boar for 42.")==false,"damage and healing off: not recorded")
assert(H.Handle("x","Denza gains Mark of the Wild.")==true,"buffs still recorded")
FieldKitDB.partyHistoryCombat=true

-- count option shrinks the history
FieldKitDB.partyHistoryCount=2;H.Handle("x","Denza's Frostbolt hits Boar for 43.");assert(table.getn(H.log.Denza)==2,"count of 2 respected")
FieldKitDB.partyHistoryCount=5

-- left the group: no memory kept
members.party2=nil;H.Prune();assert(H.log.Lockpin==nil,"a member who left leaves no history")
members.party2="Lockpin"

-- icons only from the local spellbook
local book={{"Frostbolt","Interface\\Icons\\Spell_Frost_FrostBolt02"}}
GetSpellName=function(i) return book[i] and book[i][1] end
GetSpellTexture=function(i) return book[i] and book[i][2] end
H.icons=nil
assert(H.Icon("Frostbolt")=="Interface\\Icons\\Spell_Frost_FrostBolt02","icon of a spell the local player knows")
assert(H.Icon("Renew")==nil,"no icon for a spell that is not in the local spellbook: nothing invented")
GetSpellName=nil;GetSpellTexture=nil;H.icons=nil;assert(H.Icon("Frostbolt")==nil,"no spell API, no icon")

-- tooltip lines, FR/EN
local lines={};local tip={AddLine=function(_,text) table.insert(lines,text) end}
FieldKit_SetLanguage("en");H.Tooltip(tip,"Denza");assert(table.getn(lines)==2 and string.find(lines[1],"Frostbolt",1,true),"tooltip lists the recent actions")
lines={};H.Tooltip(tip,"Nobody");assert(lines[1]=="No action received yet","empty history says so")
FieldKit_SetLanguage("fr");lines={};H.Tooltip(tip,"Nobody");assert(lines[1]=="Aucune action reçue pour le moment","FR")
assert(FieldKit_L("Show group cards")=="Afficher les cartes de groupe" and FieldKit_L("Card detail")=="Niveau de détail" and FieldKit_L("Action history")=="Historique des actions","FR option labels")
FieldKit_SetLanguage("en")

-- localized (French-style, positional) formats parse through the client's own strings
SPELLLOGOTHEROTHER="%2$s de %1$s touche %3$s pour %4$d."
H.Build();H.Clear();FieldKitDB.partyHistoryCount=5
assert(H.Handle("x","Frappe de Denza touche Sanglier pour 40.")==true and H.log.Denza[1].spell=="Frappe" and H.log.Denza[1].target=="Sanglier" and H.log.Denza[1].amount==40,"positional localized format maps back to caster / spell / target / amount")
SPELLLOGOTHEROTHER="%s's %s hits %s for %d."

-- a client that provides none of the formats: nothing breaks, nothing is recorded
local saved={};for _,c in ipairs(H.candidates) do saved[c[1]]=_G[c[1]];_G[c[1]]=nil end
H.formats=nil;H.Clear();assert(table.getn(H.Build())==0 and H.Handle("x","Denza's Frostbolt hits Boar for 40.")==false,"no format string: no parse, no error")
for k,v in pairs(saved) do _G[k]=v end;H.formats=nil

-- disabling clears memory and unregisters
FieldKitDB.partyHistory=false;H.Sync();assert(not H.registered and next(H.log)==nil,"off: unregistered and cleared")
FieldKitDB.partyHistory=true;H.Sync()

-- performance and memory budget
local clock=type(os)=="table" and os.clock
local start=clock and os.clock() or 0
for i=1,6000 do H.Handle("x",(math.mod(i,3)==0) and "Denza's Frostbolt hits Boar for "..i.."." or (math.mod(i,3)==1 and "Lockpin's Flash Heal heals Denza for "..i.."." or "no known format "..i)) end
if clock then local took=os.clock()-start;assert(took<8,"6000 messages parsed in "..took.." s") end
local total=0;for _,list in pairs(H.log) do total=total+table.getn(list) end
assert(total<=2*5,"memory stays bounded by members x count after 6000 messages ("..total..")")

-- probe: reports even when functions are missing, never errors
local said={};local oldAdd=DEFAULT_CHAT_FRAME.AddMessage;DEFAULT_CHAT_FRAME.AddMessage=function(_,m) table.insert(said,m) end
H.Probe("groupprobe");local text=table.concat(said,"\n")
assert(string.find(text,"functions MISSING",1,true) and string.find(text,"message formats",1,true) and string.find(text,"party1",1,true),"api probe reports functions, formats and units")
said={};H.Probe("groupprobe items");text=table.concat(said,"\n");assert(string.find(text,"NOT detectable",1,true),"item probe states that item use is not detectable")
said={};H.Probe("groupprobe events 5");assert(H.probe and H.probeFrame.events.CHAT_MSG_SPELL_PARTY_DAMAGE,"event probe listens")
event="CHAT_MSG_SPELL_PARTY_DAMAGE";arg1="Denza's Frostbolt hits Boar for 40.";this=H.probeFrame;H.probeFrame.scripts.OnEvent()
NOW=NOW+10;this=H.probeFrame;H.probeFrame.scripts.OnUpdate()
text=table.concat(said,"\n");assert(string.find(text,"CHAT_MSG_SPELL_PARTY_DAMAGE",1,true) and string.find(text,"1 event",1,true) and H.probe==nil,"event probe reports the counts and samples, then stops")
DEFAULT_CHAT_FRAME.AddMessage=oldAdd
FieldKitDB.partyHistory=false;H.Sync()
print("Group history: formats, kinds, options, bounds, roster, icons, FR/EN, probe and performance passed (synthetic)")
