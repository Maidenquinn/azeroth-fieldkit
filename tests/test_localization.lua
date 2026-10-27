-- Exercise live language changes through the real Interface buttons.
assert(FieldKitDB.language=="en")
assert(table.getn(FieldKitPanel.tabs)==9)
assert(FieldKitPanel.tabs[2].fieldkitLabel.text=="Combat text")
assert(FieldKitPanel.tabs[4].fieldkitLabel.text=="Bosses")
for i=1,table.getn(FieldKitPanel.tabs) do assert(FieldKitPanel.tabs[i].fieldkitLabel.text~="Text layout") end
local interface=FieldKitPanel.tabs[9].page
local en,fr=FieldKitUI.languageRow.en,FieldKitUI.languageRow.fr
for i=1,table.getn(interface.children) do
 local b=interface.children[i]
 if b.kind=="Button" and string.find(b.text or "","English",1,true) then en=b end
 if b.kind=="Button" and string.find(b.text or "","Français",1,true) then fr=b end
end
assert(en and fr)
local editor=FieldKitPanel.tabs[2].page.combatEditor
local x,y=FieldKitDB.combatTextX,FieldKitDB.combatTextIncomingX
local color=FieldKitDB.combatEvents.crit.color
local ignored=FieldKitDB.combatTextIgnore
local portrait=FieldKitBossFrame1.portrait.texture
local function button(p,text)
 for i=1,table.getn(p.children) do if p.children[i].kind=="Button" and p.children[i].text==FieldKit_L(text) then return p.children[i] end end
 error("Missing button: "..text)
end
local function widget(label)
 for i=1,table.getn(editor.widgets) do if editor.widgets[i].label==label then return editor.widgets[i] end end
 error(label)
end
for n=1,3 do
 click(fr)
 assert(FieldKitDB.language=="fr" and FieldKitPanel.tabs[2].fieldkitLabel.text=="Texte de combat")
 assert(FieldKitPanel.tabs[8].fieldkitLabel.text=="Barres ennemies")
 assert(FieldKitPanelReset.text=="Positions par défaut")
 assert(FieldKit_L("Show only elites and bosses")=="Afficher uniquement les élites et les boss")
 assert(FieldKit_L("Dégâts infligés")=="Dégâts infligés")
 assert(FieldKit_L("Backstab")=="Backstab" and FieldKit_L("Brute gordunni")=="Brute gordunni")
 assert(widget("Catégorie à personnaliser").text==FieldKit_L(FieldKitCombat.byKind[editor.eventKind][2]))
 click(en)
 assert(FieldKitDB.language=="en" and FieldKitPanel.tabs[2].fieldkitLabel.text=="Combat text")
 assert(FieldKitPanelReset.text=="Reset HUD positions")
 assert(FieldKit_L("Dégâts infligés")=="Outgoing damage")
 assert(editor.sample.text==FieldKit_L(FieldKitCombat.byKind[editor.eventKind][4] or FieldKitCombat.byKind[editor.eventKind][2])..(FieldKitCombat.byKind[editor.eventKind][4] and "" or " 123"))
end
-- Every UI catalog entry has a reversible English/French value.
for key,value in pairs(FieldKitLocale.fr) do
 assert(type(key)=="string" and type(value)=="string" and key~="" and value~="")
 FieldKitDB.language="fr";assert(FieldKit_L(key)==value,key)
 FieldKitDB.language="en";assert(FieldKit_L(value)==key,key)
end
-- Both sets of existing position preferences are edited in the Areas page.
click(button(editor,"Zones"))
local area=widget("Position to edit")
local horizontal=widget("Horizontal offset")
click(area);click(area.choiceButtons[2]);horizontal:SetValue(-251);this=horizontal;horizontal.scripts.OnValueChanged()
assert(FieldKitDB.combatTextIncomingX==-251 and FieldKitDB.combatTextX==x)
click(area);click(area.choiceButtons[1]);horizontal:SetValue(237);this=horizontal;horizontal.scripts.OnValueChanged()
assert(FieldKitDB.combatTextX==237 and FieldKitDB.combatTextIncomingX==-251)
FieldKitDB.combatTextX=x;FieldKitDB.combatTextIncomingX=y
assert(FieldKitDB.combatEvents.crit.color==color and FieldKitDB.combatTextIgnore==ignored)
assert(FieldKitBossFrame1.portrait.texture==portrait)
-- French changes labels, not event parsing or ability names / filters.
FieldKitCombat.Clear();FieldKitDB.combatText=true;FieldKitDB.combatTextGroup=false;FieldKitDB.combatTextIgnore="";FieldKitDB.combatTextMin=0
FieldKitDB.combatTextNames=true;FieldKitDB.combatEvents.out.enabled=true;FieldKitDB.combatTextOutgoing=true
click(fr)
fire(FieldKitCombatText,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Regen hits Wolf for 123.");update(FieldKitCombatText,.06)
local found=false
for i=1,table.getn(FieldKitCombatText.children) do
 local t=FieldKitCombatText.children[i];if t.kind=="FontString" and t:IsShown() and t.text=="Regen 123" then found=true end
end
assert(found,"Native ability names must not be translated")
FieldKitDB.combatTextIgnore=ignored
-- Leave French selected so reload persistence is tested too.
assert(FieldKitDB.language=="fr")
