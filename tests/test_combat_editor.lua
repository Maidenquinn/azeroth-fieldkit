-- Runtime behavior and actual option callbacks, not copied implementation tests.
local C=FieldKitCombat
local savedX=FieldKitDB.combatTextX
local function visible()
 local result={}
 for i=1,table.getn(FieldKitCombatText.children) do
  local s=FieldKitCombatText.children[i];if s.kind=="FontString" and s:IsShown() then table.insert(result,s) end
 end
 return result
end
local function start()
 C.Clear();C.Preset("all");FieldKitDB.combatTextGroup=false;FieldKitDB.combatTextIgnore="";FieldKitDB.combatTextMin=0;FieldKitDB.combatTextHealMin=0
end
local function hit(message,ev) fire(FieldKitCombatText,ev or "CHAT_MSG_SPELL_SELF_DAMAGE",message);update(FieldKitCombatText,.06) end
start();C.Event("crit").enabled=false
hit("Your Backstab crits Wolf for 200.");assert(table.getn(visible())==0)
hit("Your Backstab hits Wolf for 30.");assert(visible()[1].text=="Backstab 30")
start();FieldKitDB.combatTextIgnore="  Backstab  \nRenew\nDodge Strike"
hit("Your Backstab hits Wolf for 10.");assert(table.getn(visible())==0)
hit("Your Dodge Strike misses Wolf.","CHAT_MSG_COMBAT_SELF_MISSES");assert(table.getn(visible())==0)
start();FieldKitDB.combatTextIncoming=false
hit("Wolf's Fireball hits you for 30.","CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE");assert(table.getn(visible())==0)
FieldKitDB.combatTextIncoming=true;hit("Wolf's Fireball hits you for 30.","CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
assert(visible()[1].text=="Fireball 30")
start();FieldKitDB.combatTextMin=50
hit("Your Backstab hits Wolf for 49.");assert(table.getn(visible())==0)
hit("Your Backstab hits Wolf for 50.");assert(table.getn(visible())==1)
start();FieldKitDB.combatTextHealMin=10
AZS_HEALING={{name="New Heal",dmg=100}};AZS_HEALING_UPDATED=101;update(FieldKitCombatText,.1)
AZS_HEALING[1].dmg=109;AZS_HEALING_UPDATED=102;update(FieldKitCombatText,.1);assert(table.getn(visible())==0)
AZS_HEALING[1].dmg=124;AZS_HEALING_UPDATED=103;update(FieldKitCombatText,.1);assert(visible()[1].text=="Heal: New Heal 15")
local cases={
 {"Your Dodge Strike misses Wolf.","miss"},
 {"Your Backstab was dodged by Wolf.","dodge"},
 {"Your Backstab was parried by Wolf.","parry"},
 {"Your Backstab was blocked by Wolf.","block"},
 {"Your Fireball was resisted by Wolf.","resist"},
 {"Your Fireball is absorbed by Wolf.","absorb"},
 {"Your Fireball failed. Wolf is immune.","immune"},
 {"Your Backstab was evaded by Wolf.","evade"}}
for i=1,table.getn(cases) do
 start();C.Event(cases[i][2]).color={.13,.27,.91};hit(cases[i][1],"CHAT_MSG_COMBAT_SELF_MISSES")
 local s=visible();assert(table.getn(s)==1,cases[i][1]);assert(s[1].color[3]==.91)
 assert(not string.find(s[1].text,"nil",1,true))
 C.Clear();C.Event(cases[i][2]).enabled=false;hit(cases[i][1],"CHAT_MSG_COMBAT_SELF_MISSES");assert(table.getn(visible())==0)
end
start();hit("Your Backstab hits Wolf for 30. (10 blocked)");assert(table.getn(visible())==1 and visible()[1].text=="Backstab 30")
start();FieldKitDB.combatTextGroup=true
fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Backstab hits Wolf for 100.")
C.Event("out").enabled=false;update(FieldKitCombatText,.4);assert(table.getn(visible())==0)
start();FieldKitDB.combatTextSplit=true;FieldKitDB.combatTextX=200;FieldKitDB.combatTextIncomingX=-220
hit("Your Backstab hits Wolf for 100.");hit("Wolf hits you for 50.","CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
local positions={};for _,s in ipairs(visible()) do positions[s.point[4]]=true end
assert(positions[200] and positions[-220])
start();FieldKitDB.combatTextFont=2;FieldKitDB.combatTextCritFont=4;FieldKitDB.combatTextCritSize=25
C.Event("crit").color={.2,.4,.6};hit("Your Backstab crits Wolf for 200.")
local s=visible()[1];assert(s.fontPath=="Fonts\\SKURRI.TTF" and s.fontSize==25 and s.color[2]==.4)
FieldKitDB.combatTextNames=false;FieldKitDB.combatTextOpacity=50;update(FieldKitCombatText,.06)
assert(s.text=="200" and s.alpha<=.5)
C.Event("crit").size="31";update(FieldKitCombatText,.06);assert(s.fontSize==31)
C.Clear();FieldKitDB.combatText=false;C.Preview("crit");update(FieldKitCombatText,.06)
assert(string.find(visible()[1].text,FieldKit_L("[Preview]"),1,true))
update(FieldKitCombatText,6);assert(table.getn(visible())==0)
-- Existing /mash entry point and all five subpages.
SlashCmdList.FieldKitCOMBAT();local editor
for i=1,table.getn(FieldKitPanel.tabs) do if FieldKitPanel.tabs[i].page.combatEditor then editor=FieldKitPanel.tabs[i].page.combatEditor end end
assert(editor)
local function button(parent,text)
 for i=1,table.getn(parent.children) do local b=parent.children[i];if b.kind=="Button" and b.text==FieldKit_L(text) then return b end end
 error("Button not found: "..text)
end
for i,label in ipairs({"Général","Événements","Police","Filtres","Zones"}) do
 click(button(editor,label));assert(editor.selected==i)
 for j=1,5 do assert(editor.pages[j]:IsShown()==(i==j)) end
end
local function widget(label)
 for i=1,table.getn(editor.widgets) do if editor.widgets[i].label==label then return editor.widgets[i] end end
 error("Widget not found: "..label)
end
click(button(editor,"Événements"));editor.eventKind="out";editor.Refresh()
click(widget("Catégorie à personnaliser"));click(widget("Catégorie à personnaliser").choiceButtons[2]);assert(editor.eventKind=="crit")
local red=widget("Rouge");red:SetValue(51);this=red;red.scripts.OnValueChanged();assert(math.abs(C.Event("crit").color[1]-.2)<.001)
editor.ignoreEdit:SetText("Backstab\nRenew");click(button(editor.pages[4],"Appliquer la liste"));assert(FieldKitDB.combatTextIgnore=="Backstab\nRenew")
C.ShowAnchors();assert(FieldKitCombatAnchor1:IsShown() and FieldKitCombatAnchor2:IsShown())
function FieldKitCombatAnchor1:GetCenter() return 650,450 end
this=FieldKitCombatAnchor1;FieldKitCombatAnchor1.scripts.OnDragStop();assert(FieldKitDB.combatTextX==150 and FieldKitDB.combatTextY==50)
this=FieldKitPanel;FieldKitPanel.scripts.OnHide();assert(not FieldKitCombatAnchor1:IsShown())
-- Persist event styles and ignored list without changing other modules' settings.
FieldKitDB.combatTextX=savedX;FieldKitDB.uiPage="health";FieldKitDB.panelTab=3;FieldKitDB.panelSection="Health & buffs";FieldKitDB.combatText=true
assert(FieldKitDB.moneyDockRepair==1 and FieldKitDB.guardianPins==false)

click(button(editor.pages[1],"Utiliser seulement ce texte"))
assert(FieldKitDB.combatText and FieldKitDB.hideDamage and FieldKitDB.showCrits==false)

FieldKitDB.showCrits=true;FieldKitDB.groupCrits=false
fire(FieldKitFrame,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Backstab crits Wolf for 100.")
update(FieldKitFrame,.1);assert(FieldKitLegacyCritFrame)
FieldKit_UseCombatTextOnly();update(FieldKitFrame,.1)
for i=1,table.getn(FieldKitLegacyCritFrame.children) do assert(not FieldKitLegacyCritFrame.children[i]:IsShown()) end

assert(C.LimitText("aaaaé",5)=="aaaa")
assert(C.LimitText("aaaaé",6)=="aaaaé")
assert(C.LimitText("é",0)=="")
