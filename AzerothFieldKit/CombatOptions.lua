-- Compact editor embedded in the existing /mash Combat text page.
local C=MASHCombat
local serial=0
local function Name() serial=serial+1;return "MASHCombatOption"..serial end
function MASH_CreateCombatOptions(parent)
 local width=parent:GetWidth()-6
 local ui=CreateFrame("Frame",nil,parent);ui:SetWidth(width);ui:SetHeight(505);ui:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-27)
 ui.widgets={};ui.pages={};ui.menus={};ui.selected=1;ui.eventKind="out"
 local function Text(p,label,x,y,width)
  local t=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
  t:SetWidth(width or (parent:GetWidth()-6));t:SetJustifyH("LEFT");MASH_Text(t,label);return t
 end
 local function Tip(button,text)
  button:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(MASH_L(text),1,1,1);GameTooltip:Show() end)
  button:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 local function Button(p,label,x,y,w,callback)
  local b=CreateFrame("Button",Name(),p,"UIPanelButtonTemplate");b:SetWidth(w);b:SetHeight(23);b:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);MASH_Text(b,label);b:SetScript("OnClick",callback);return b
 end
 local function Check(p,label,y,get,set,tip)
  local b=CreateFrame("CheckButton",Name(),p,"UICheckButtonTemplate");b:SetWidth(22);b:SetHeight(22);b:SetPoint("TOPLEFT",p,"TOPLEFT",0,y)
  Text(p,label,25,y-4,width-25);b.get=get;b.set=set;b.label=label;b.controlKind="check"
  b.Refresh=function() b:SetChecked(get() and 1 or nil) end
  b:SetScript("OnClick",function() set(this:GetChecked() and true or false);ui.Refresh() end)
  if tip then Tip(b,tip) end
  table.insert(ui.widgets,b);return b
 end
 local function Flag(p,label,y,key,tip)
  return Check(p,label,y,function() return MASHDB[key] end,function(v) MASHDB[key]=v end,tip)
 end
 local function Slider(p,label,y,min,max,get,set,format)
  local name=Name();local s=CreateFrame("Slider",name,p,"OptionsSliderTemplate")
  s:SetWidth(width-20);s:SetHeight(17);s:SetPoint("TOPLEFT",p,"TOPLEFT",9,y-16);s:SetMinMaxValues(min,max);s:SetValueStep(1)
  if getglobal(name.."Low") then MASH_Text(getglobal(name.."Low"),tostring(min));MASH_Text(getglobal(name.."High"),tostring(max)) end
  s.get=get;s.set=set;s.label=label;s.controlKind="slider"
  s.Refresh=function()
   local v=get();s:SetValue(v);if getglobal(name.."Text") then MASH_Text(getglobal(name.."Text"),MASH_L(label)..": "..(format and MASH_L(format(v)) or v)) end
  end
  s:SetScript("OnValueChanged",function()
   local v=math.floor(this:GetValue()+.5)
   if not ui.refreshing then set(v) end
   if getglobal(name.."Text") then MASH_Text(getglobal(name.."Text"),MASH_L(label)..": "..(format and MASH_L(format(v)) or v)) end
  end)
  table.insert(ui.widgets,s);return s
 end
 local function Number(p,label,y,key,min,max,format)
  return Slider(p,label,y,min,max,function() return C.Number(key,C.defaults[key],min,max) end,function(v) MASHDB[key]=v end,format)
 end
 local function Choice(p,label,y,values,get,set)
  Text(p,label,0,y,width)
  local menu=CreateFrame("Frame",nil,p);menu:SetWidth(width);menu:SetHeight(table.getn(values)*22+8)
  menu:SetFrameStrata("DIALOG");menu:SetFrameLevel(p:GetFrameLevel()+30)
  menu:SetPoint("TOPLEFT",p,"TOPLEFT",0,y-42)
  menu:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8});menu:SetBackdropColor(0,0,0,1)
  local backdrop=menu:CreateTexture(nil,"BACKGROUND");backdrop:SetAllPoints(menu);backdrop:SetTexture(.025,.025,.035,1)
  local b=Button(p,"",0,y-18,width,function()
   local shown=menu:IsShown();for i=1,table.getn(ui.menus) do ui.menus[i]:Hide() end
   if not shown then menu:Show() end
  end)
  b.choiceButtons={}
  for i=1,table.getn(values) do
   local index=i
   b.choiceButtons[i]=Button(menu,values[i],4,-4-(i-1)*22,width-8,function() set(index);menu:Hide();ui.Refresh() end)
  end
  menu:Hide();table.insert(ui.menus,menu)
  b.Refresh=function() MASH_Text(b,values[get()] or values[1]) end;b.label=label;b.controlKind="choice"
  Tip(b,"Cliquer pour choisir dans la liste.");table.insert(ui.widgets,b);return b
 end
 function ui.Refresh()
  if not C.Ensure() then return end
  ui.refreshing=true;for i=1,table.getn(ui.widgets) do ui.widgets[i].Refresh() end;ui.refreshing=false
  if ui.sample then
   local color={C.Color(ui.eventKind)};ui.sample:SetTextColor(color[1],color[2],color[3])
   MASH_Text(ui.sample,MASH_L(C.byKind[ui.eventKind][4] or C.byKind[ui.eventKind][2])..(C.byKind[ui.eventKind][4] and "" or " 123"))
  end
 end
 local labels={"Général","Événements","Police","Filtres","Zones"}
 local function Select(index)
  ui.selected=index
  for i=1,table.getn(ui.menus) do ui.menus[i]:Hide() end
  for i=1,5 do if i==index then ui.pages[i]:Show() else ui.pages[i]:Hide() end end
  ui.Refresh()
 end
 for i=1,5 do
  local p=CreateFrame("Frame",nil,ui);p:SetWidth(width);p:SetHeight(465);p:SetPoint("TOPLEFT",ui,"TOPLEFT",0,-34);ui.pages[i]=p
  local index=i;Button(ui,labels[i],(i-1)*(width/5),0,width/5-4,function() Select(index) end)
 end
 local p=ui.pages[1]
 Flag(p,"Activer le texte de combat MASH",0,"combatText")
 Flag(p,"Regrouper les frappes d'une compétence",-29,"combatTextGroup","Les critiques et les dégâts normaux restent séparés.")
 Number(p,"Messages simultanés (toutes zones)",-69,"combatTextMax",1,10)
 Number(p,"Durée d'affichage",-122,"combatTextDuration",6,50,function(v) return string.format("%.1f s",v/10) end)
 Number(p,"Fenêtre de regroupement",-175,"combatTextWindow",5,75,function(v) return string.format("%.2f s",v/100) end)
 Text(p,"Quick presets change filters, merging and message limits. Fonts, colors and positions are kept.",0,-233)
 Button(p,"Équilibré",0,-272,width/3-4,function() C.Preset("balanced");ui.Refresh() end)
 Button(p,"Discret",width/3,-272,width/3-4,function() C.Preset("quiet");ui.Refresh() end)
 Button(p,"Tout",2*width/3,-272,width/3-4,function() C.Preset("all");ui.Refresh() end)
 Button(p,"Aperçu (exemples fictifs)",0,-313,width,function() C.Preview() end)
 Button(p,"Utiliser seulement ce texte",0,-347,width,function() if MASH_UseCombatTextOnly then MASH_UseCombatTextOnly();ui.Refresh() end end)
 Text(p,"Enables MASH text and hides game damage numbers and the old critical display. Restore them in Combat. Preview uses marked sample data. Healing uses native totals.",0,-387)
 p=ui.pages[2]
 Choice(p,"Catégorie à personnaliser",0,(function() local t={};for i=1,table.getn(C.defs) do table.insert(t,C.defs[i][2]) end;return t end)(),
  function() for i=1,table.getn(C.defs) do if C.defs[i][1]==ui.eventKind then return i end end;return 1 end,
  function(v) ui.eventKind=C.defs[v][1] end)
 Check(p,"Afficher cette catégorie",-58,function() return C.Event(ui.eventKind).enabled end,function(v) C.Event(ui.eventKind).enabled=v end)
 ui.sample=Text(p,"",10,-96,width-20)
 local channelNames={"Rouge","Vert","Bleu"}
 for i=1,3 do
  local channel=i
  Slider(p,channelNames[i],-133-(i-1)*53,0,255,
   function() local c={C.Color(ui.eventKind)};return math.floor(c[channel]*255+.5) end,
   function(v) local e=C.Event(ui.eventKind);if type(e.color)~="table" then e.color={C.Color(ui.eventKind)} end;e.color[channel]=v/255;ui.Refresh() end)
 end
 Slider(p,"Taille de cette catégorie",-292,0,40,function() return tonumber(C.Event(ui.eventKind).size) or 0 end,
  function(v) C.Event(ui.eventKind).size=v<10 and 0 or v end,function(v) return v<10 and "héritée de Police" or (v.." px") end)
 Button(p,"Couleur / taille par défaut",0,-352,width,function() local e=C.Event(ui.eventKind);e.color=nil;e.size=nil;ui.Refresh() end)
 Button(p,"Aperçu de cette catégorie",0,-385,width,function() C.Preview(ui.eventKind) end)
 Text(p,"Avoidance events appear only when the client sends the corresponding message. < = incoming; > = your action.",0,-420)
 p=ui.pages[3]
 local fonts={};for i=1,table.getn(C.fonts) do table.insert(fonts,C.fonts[i][1]) end
 Choice(p,"Police normale",0,fonts,function() return C.Number("combatTextFont",1,1,4) end,function(v) MASHDB.combatTextFont=v end)
 local critFonts={"Identique à la normale"};for i=1,table.getn(fonts) do table.insert(critFonts,fonts[i]) end
 Choice(p,"Police des critiques",-62,critFonts,function() return C.Number("combatTextCritFont",0,0,4)+1 end,function(v) MASHDB.combatTextCritFont=v-1 end)
 Choice(p,"Contour",-124,{"Aucun","Fin","Épais"},function() return C.Number("combatTextOutline",2,1,3) end,function(v) MASHDB.combatTextOutline=v end)
 Number(p,"Taille normale",-191,"combatTextFontSize",10,32,function(v) return v.." px" end)
 Number(p,"Taille des critiques",-244,"combatTextCritSize",10,40,function(v) return v.." px" end)
 Number(p,"Opacité",-297,"combatTextOpacity",10,100,function(v) return v.."%" end)
 Flag(p,"Afficher le nom des compétences",-350,"combatTextNames")
 Flag(p,"Afficher le nombre de frappes regroupées",-379,"combatTextCounts")
 Button(p,"Aperçu",0,-421,width,function() C.Preview() end)
 p=ui.pages[4]
 Flag(p,"Dégâts et actions infligés",0,"combatTextOutgoing")
 Flag(p,"Dégâts et actions reçus",-29,"combatTextIncoming")
 Flag(p,"Soins reçus",-58,"combatTextHealing")
 Number(p,"Dégât minimum (par frappe)",-102,"combatTextMin",0,500)
 Number(p,"Soin minimum (par mise à jour)",-155,"combatTextHealMin",0,500)
 Text(p,"Hidden abilities: one game-provided name per line. Example: Backstab. Maximum 32 names.",0,-213)
 local edit=CreateFrame("EditBox",Name(),p);edit:SetWidth(width-10);edit:SetHeight(90);edit:SetPoint("TOPLEFT",p,"TOPLEFT",5,-253)
 edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject("ChatFontNormal")
 edit:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8})
 if edit.SetMaxLetters then edit:SetMaxLetters(2000) end
 edit:SetScript("OnEscapePressed",function() this:ClearFocus() end)
 local load=Button(p,"Recharger la liste",0,-358,width/2-5,function() edit:SetText(MASHDB.combatTextIgnore or "");edit:ClearFocus() end)
 Button(p,"Appliquer la liste",width/2+5,-358,width/2-5,function() MASHDB.combatTextIgnore=C.LimitText(edit:GetText() or "",2000);edit:ClearFocus() end)
 p:SetScript("OnShow",function() edit:SetText(MASHDB and MASHDB.combatTextIgnore or "") end)
 ui.ignoreEdit=edit
 Text(p,"Matches the name received from the game, without the healing prefix. Small hits are filtered before merging. Partially blocked hits remain one damage message.",0,-404)
 p=ui.pages[5]
 Flag(p,"Séparer reçus / soins et dégâts infligés",0,"combatTextSplit")
 Choice(p,"Sens du défilement",-41,{"Vers le haut","Vers le bas"},function() return C.Number("combatTextDirection",1,1,2) end,function(v) MASHDB.combatTextDirection=v end)
 Button(p,"Afficher les poignées de déplacement",0,-104,width,function() C.ShowAnchors() end)
 Button(p,"Masquer les poignées",0,-137,width,function() C.HideAnchors() end)
 Number(p,"Espacement des lignes",-186,"combatTextSpacing",18,60,function(v) return v.." px" end)
 Choice(p,"Position to edit",-245,{"Outgoing area","Incoming / healing area"},function() return ui.positionArea or 1 end,function(v) ui.positionArea=v end)
 local function PositionKey(axis) return (ui.positionArea==2 and "combatTextIncoming" or "combatText")..axis end
 Slider(p,"Horizontal offset",-310,-600,600,function() local key=PositionKey("X");return C.Number(key,C.defaults[key],-600,600) end,function(v) MASHDB[PositionKey("X")]=v end,function(v) return v.." px" end)
 Slider(p,"Vertical offset",-363,-300,300,function() local key=PositionKey("Y");return C.Number(key,C.defaults[key],-300,300) end,function(v) MASHDB[PositionKey("Y")]=v end,function(v) return v.." px" end)
 Text(p,"Offsets are measured from the screen center. Drag handles also save these values.",0,-421)
 MASH_RefreshLanguage(ui.Refresh)
 parent.combatEditor=ui;parent:SetScript("OnShow",function() for i=1,table.getn(ui.menus) do ui.menus[i]:Hide() end;ui.Refresh() end)
 Select(1);return ui
end
