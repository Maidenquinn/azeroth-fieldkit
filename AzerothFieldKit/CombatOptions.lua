-- Compact editor embedded in the existing /fieldkit Combat text page.
local C=FieldKitCombat
local serial=0
-- Generate distinct editor frame names without overwriting native globals.
local function Name() serial=serial+1;return "FieldKitCombatOption"..serial end
-- Build the single five-page combat editor and its live preview controls.
function FieldKit_CreateCombatOptions(parent)
 C.InitProfiles()
 local width=parent:GetWidth()-6
 local T=FieldKitTheme
 local layout={}
 local profileButtons={}
 -- Store proportional horizontal geometry; resize existing widgets, never rebuild.
 local function Track(widget,x,w) table.insert(layout,{widget=widget,x=x/width,w=w/width});return widget end
 local ui=CreateFrame("Frame",nil,parent);ui:SetWidth(width);ui:SetHeight(505);ui:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-48)
 ui.widgets={};ui.pages={};ui.menus={};ui.selected=1;ui.eventKind="out";ui.previewProfile=C.ActiveProfile()
 -- Create one localized editor label.
 local function Text(p,label,x,y,width)
  local t=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
  t:SetWidth(width or (parent:GetWidth()-6));t:SetHeight(44);t:SetJustifyH("LEFT");t:SetJustifyV("TOP");T.Font(t,13,T.text);FieldKit_Text(t,label);Track(t,x,width or (parent:GetWidth()-6));return t
 end
 -- Attach localized tooltip callbacks to an addon-owned control.
 local function Tip(button,text)
  button:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L(text),1,1,1);GameTooltip:Show() end)
  button:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 -- Create a localized explicit-action editor button.
 local function Button(p,label,x,y,w,callback)
  local b=T.Button(p,Name(),label,x,-y,w,27,callback);Track(b,x,w);return b
 end
 -- Build a boolean control with separate refresh/get and click/set paths.
 local function Check(p,label,y,get,set,tip)
  local b=CreateFrame("CheckButton",Name(),p,"UICheckButtonTemplate");b:SetWidth(22);b:SetHeight(22);b:SetPoint("TOPLEFT",p,"TOPLEFT",0,y)
  Text(p,label,25,y-4,width-25);b.get=get;b.set=set;b.label=label;b.controlKind="check"
  b.Refresh=function() b:SetChecked(get() and 1 or nil) end
  b:SetScript("OnClick",function() set(this:GetChecked() and true or false);ui.Refresh() end)
  if tip then Tip(b,tip) end
  table.insert(ui.widgets,b);return b
 end
 -- Bind a checkbox to one combat DB option.
 local function Flag(p,label,y,key,tip)
  return Check(p,label,y,function() return FieldKitDB[key] end,function(v) FieldKitDB[key]=v end,tip)
 end
 -- Build a bounded numeric control, suppressing callbacks during UI refresh.
 local function Slider(p,label,y,min,max,get,set,format)
  local name=Name();local s=CreateFrame("Slider",name,p,"OptionsSliderTemplate")
  Track(s,9,width-20);s:SetWidth(width-20);s:SetHeight(17);s:SetPoint("TOPLEFT",p,"TOPLEFT",9,y-16);s:SetMinMaxValues(min,max);s:SetValueStep(1)
  if getglobal(name.."Low") then FieldKit_Text(getglobal(name.."Low"),tostring(min));FieldKit_Text(getglobal(name.."High"),tostring(max)) end
  s.get=get;s.set=set;s.label=label;s.controlKind="slider"
  if getglobal(name.."Text") then T.Font(getglobal(name.."Text"),13,T.gold) end
  s.Refresh=function()
   local v=get();s:SetValue(v);if getglobal(name.."Text") then FieldKit_Text(getglobal(name.."Text"),FieldKit_L(label)..": "..(format and FieldKit_L(format(v)) or v)) end
  end
  s:SetScript("OnValueChanged",function()
   local v=math.floor(this:GetValue()+.5)
   if not ui.refreshing then set(v) end
   if getglobal(name.."Text") then FieldKit_Text(getglobal(name.."Text"),FieldKit_L(label)..": "..(format and FieldKit_L(format(v)) or v)) end
  end)
  table.insert(ui.widgets,s);return s
 end
 -- Bind a numeric slider to one validated combat option.
 local function Number(p,label,y,key,min,max,format)
  return Slider(p,label,y,min,max,function() return C.Number(key,C.defaults[key],min,max) end,function(v) FieldKitDB[key]=v end,format)
 end
 -- Create a bounded choice popup; capture the selected value per entry.
 local function Choice(p,label,y,values,get,set)
  Text(p,label,0,y,width)
  local b=FieldKitUI.Choice(p,Name(),label,0,18-y,width,values,get,set,function() ui.Refresh() end)
  b.label=label;b.controlKind="choice";Track(b,0,width)
  table.insert(ui.menus,b.menu);table.insert(ui.widgets,b);return b
 end
 function ui.Refresh()
  if not C.Ensure() then return end
  ui.refreshing=true;for i=1,table.getn(ui.widgets) do ui.widgets[i].Refresh() end;ui.refreshing=false
  if ui.RefreshPreview then ui.RefreshPreview() end
  if C.SaveActiveProfile then C.SaveActiveProfile() end
  -- C10.1: expose the active preset without relying on hover state.
  local active=C.ActiveProfile()
  for key,button in pairs(profileButtons) do
   button.fieldkitSelected=(key==active)
   T.State(button,button.fieldkitSelected)
   if button.fieldkitLabel then
    local color=button.fieldkitSelected and T.text or T.gold
    button.fieldkitLabel:SetTextColor(color[1],color[2],color[3])
   end
  end
  if ui.sample then
   local color={C.Color(ui.eventKind)};ui.sample:SetTextColor(color[1],color[2],color[3])
   FieldKit_Text(ui.sample,FieldKit_L(C.byKind[ui.eventKind][4] or C.byKind[ui.eventKind][2])..(C.byKind[ui.eventKind][4] and "" or " 123"))
  end
 end
 local labels={"Essentials","Events","Fonts","Filters","Areas","Game","Advanced"};ui.tabs={}
 local descriptions={
  "Enable text, choose a profile and try the previews.",
  "Choose which damage, healing and events appear.",
  "Adjust fonts, sizes and readability.",
  "Hide unwanted events or abilities.",
  "Move areas and adjust scrolling.",
  "Manage native game combat text options.",
  "Adjust advanced combat text settings."
 }
 -- Small persistent navigation status, updated when switching subpages.
 local navStatus=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 navStatus:SetPoint("TOPRIGHT",ui,"TOPRIGHT",0,17)
 navStatus:SetWidth(width);navStatus:SetHeight(16);navStatus:SetJustifyH("RIGHT")
 T.Font(navStatus,11,T.text)
 FieldKit_RefreshLanguage(function()
  navStatus:SetText(ui.selected.." / 7  -  "..FieldKit_L(labels[ui.selected]))
  if ui:IsVisible() then ui.Refresh() end
 end)
 -- Show one editor subpage and hide its other pages/menus.
 local function Select(index)
  ui.selected=index
  navStatus:SetText(index.." / 7  -  "..FieldKit_L(labels[index]))
  for i=1,table.getn(ui.menus) do ui.menus[i]:Hide() end
  for i=1,7 do if i==index then ui.pages[i]:Show() else ui.pages[i]:Hide() end end
  for i=1,7 do
   local selected=i==index
   ui.tabs[i].fieldkitSelected=selected
   T.State(ui.tabs[i],selected)
   -- Keep the selected label readable without relying on the hover texture.
   local label=ui.tabs[i].fieldkitLabel
   if label then
    local color=selected and T.text or T.gold
    label:SetTextColor(color[1],color[2],color[3])
   end
   if ui.tabs[i].fieldkitAccent then
    if selected then ui.tabs[i].fieldkitAccent:Show() else ui.tabs[i].fieldkitAccent:Hide() end
   end
  end
  ui.Refresh()
 end
 for i=1,7 do
  local p=CreateFrame("Frame",nil,ui);p:SetWidth(width);p:SetHeight(465);p:SetPoint("TOPLEFT",ui,"TOPLEFT",0,-34);ui.pages[i]=p
  local index=i;ui.tabs[i]=Button(ui,labels[i],(i-1)*(width/7),0,width/7-4,function() Select(index) end);T.Font(ui.tabs[i].fieldkitLabel,12,T.gold)
  ui.tabs[i].fieldkitLabel:SetJustifyH("CENTER")
  Tip(ui.tabs[i],descriptions[i])
  -- A restrained gold underline keeps the current tab recognizable at a glance.
  local accent=ui.tabs[i]:CreateTexture(nil,"OVERLAY")
  accent:SetTexture(T.gold[1],T.gold[2],T.gold[3])
  accent:SetPoint("BOTTOMLEFT",ui.tabs[i],"BOTTOMLEFT",7,2)
  accent:SetPoint("BOTTOMRIGHT",ui.tabs[i],"BOTTOMRIGHT",-7,2)
  accent:SetHeight(2);accent:Hide()
  ui.tabs[i].fieldkitAccent=accent
 end
 local p=ui.pages[1]
 Flag(p,"Enable FieldKit combat text",0,"combatText")
 Flag(p,"Merge hits from the same ability",-29,"combatTextGroup","Les critiques et les dégâts normaux restent séparés.")
 Flag(p,"Anchor to world (AS 0.138+)",-58,"combatTextWorld","Les nombres restent sur le point d'impact / de mort via AZS_GetCombatTextEvents. Sans l'API, le mode chat classique reste actif.")
 Text(p,"Choose a profile, then customize its options if needed.",0,-100)
 profileButtons["balanced"] = Button(p,"Balanced",0,-146,width/3-4,function() C.SelectProfile("balanced");ui.previewProfile=C.ActiveProfile();ui.Refresh() end)
 profileButtons["quiet"] = Button(p,"Quiet",width/3,-146,width/3-4,function() C.SelectProfile("quiet");ui.previewProfile="quiet";ui.Refresh() end)
 profileButtons["all"] = Button(p,"All",2*width/3,-146,width/3-4,function() C.SelectProfile("all");ui.previewProfile="all";ui.Refresh() end)
 -- Reset requires a second click within five seconds; no other profile is affected.
 local resetPendingUntil=0
 local resetButton
 resetButton=Button(p,"Reset this profile",0,-178,math.min(230,width),function()
  local now=GetTime and GetTime() or 0
  if now>resetPendingUntil then
   resetPendingUntil=now+5
   FieldKit_Text(resetButton.fieldkitLabel,"Confirm reset (5 s)")
   return
  end
  resetPendingUntil=0
  C.ResetActiveProfile();ui.previewProfile=C.ActiveProfile();ui.Refresh()
  FieldKit_Text(resetButton.fieldkitLabel,"Reset this profile")
 end)
 resetButton:SetScript("OnUpdate",function()
  if resetPendingUntil>0 and GetTime and GetTime()>resetPendingUntil then
   resetPendingUntil=0
   FieldKit_Text(resetButton.fieldkitLabel,"Reset this profile")
  end
 end)
 Button(p,"Start / pause simulation",0,-215,math.min(280,width),function() ui.ToggleSimulation() end)
 -- The overlay uses actual combat text slots, so positions, font, opacity,
 -- fade and direction are identical to a real encounter.
 local overlayRunning=false;local overlayElapsed=0;local overlayStep=0
 Button(p,"On-screen preview: start / stop",0,-251,math.min(320,width),function()
  overlayRunning=not overlayRunning;overlayElapsed=0
  if not overlayRunning then C.Clear() end
 end)
 -- Live synthetic combat feed. This is UI-only: it never calls the combat
 -- ingestion pipeline, changes run statistics or sends game events.
 local panel=CreateFrame("Frame",nil,p);panel:SetPoint("TOPLEFT",p,"TOPLEFT",0,-287);panel:SetWidth(width);panel:SetHeight(125)
 panel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
 panel:SetBackdropColor(.025,.055,.075,.94);panel:SetBackdropBorderColor(.48,.35,.16,.8)
 local heading=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");heading:SetPoint("TOPLEFT",panel,"TOPLEFT",12,-8)
 local feed={};local lines={};local elapsed=0;local counter=0;local running=true
 local examples={{"out","Thunder Clap",1245},{"out","Cleave",468},{"crit","CRITICAL!",3860},{"heal","Healing +",920},{"incoming","Damage taken -",486},{"block","Block",350},{"outPeriodic","Bleeding",157}}
 for i=1,10 do
  local fs=panel:CreateFontString(nil,"OVERLAY","GameFontNormal")
  fs:SetPoint("TOP",panel,"TOP",0,-25);fs:SetWidth(width-28);fs:SetHeight(36);fs:SetJustifyH("CENTER");fs:Hide();lines[i]=fs
 end
 local function Eligible(kind)
  local event=C.Event(kind)
  if not FieldKitDB.combatText or not event or not event.enabled then return false end
  if kind=="heal" then return FieldKitDB.combatTextHealing end
  if kind=="incoming" or kind=="incomingCrit" then return FieldKitDB.combatTextIncoming end
  return FieldKitDB.combatTextOutgoing
 end
 local function Spawn()
  counter=counter+1
  local valid={}
  for i=1,table.getn(examples) do if Eligible(examples[i][1]) then table.insert(valid,examples[i]) end end
  if table.getn(valid)==0 then return end
  local item=valid[math.mod(counter-1,table.getn(valid))+1]
  local now=GetTime();local window=C.Number("combatTextWindow",25,5,75)/100
  local last=feed[table.getn(feed)]
  if FieldKitDB.combatTextGroup and last and last.kind==item[1] and last.label==item[2] and now-last.time<=window then
   last.amount=last.amount+item[3];last.count=last.count+1;last.time=now
  else
   table.insert(feed,{kind=item[1],label=item[2],amount=item[3],count=1,time=now})
  end
 end
 ui.RefreshPreview=function()
  if not FieldKitDB then return end
  local now=GetTime();local duration=C.Number("combatTextDuration",18,6,50)/10
  local limit=C.Number("combatTextMax",5,1,10)
  for i=table.getn(feed),1,-1 do
   if now-feed[i].time>=duration or not Eligible(feed[i].kind) then table.remove(feed,i) end
  end
  while table.getn(feed)>limit do table.remove(feed,1) end
  local direction=C.Number("combatTextDirection",1,1,2)
  local normal=C.Number("combatTextFont",1,1,4);local critical=C.Number("combatTextCritFont",0,0,4)
  local outline=({"","OUTLINE","THICKOUTLINE"})[C.Number("combatTextOutline",2,1,3)]
  local opacity=C.Number("combatTextOpacity",100,10,100)/100
  local spacing=math.min(32,math.max(13,C.Number("combatTextSpacing",27,18,60)))
  local visible=math.min(table.getn(feed),limit,math.floor(92/spacing)+1)
  for i=1,10 do
   local fs=lines[i];local v=feed[table.getn(feed)-i+1]
   if i<=visible and v then
    local crit=v.kind=="crit" or v.kind=="incomingCrit"
    local event=C.Event(v.kind)
    local size=tonumber(event and event.size) or C.Number(crit and "combatTextCritSize" or "combatTextFontSize",crit and 20 or 16,10,40)
    size=math.min(40,math.max(10,size))
    local font=crit and critical>0 and critical or normal
    local ok,result=pcall(fs.SetFont,fs,C.fonts[font][2],size,outline)
    if not ok or result==false then fs:SetFont(C.fonts[1][2],size,"OUTLINE") end
    local r,g,b=C.Color(v.kind);fs:SetTextColor(r,g,b)
    local age=now-v.time;local fade=math.min(1,math.max(0,(duration-age)/(duration/3)))
    fs:SetAlpha(opacity*fade)
    local label=FieldKitDB.combatTextNames and (FieldKit_L(v.label).." ") or ""
    fs:SetText(label..v.amount..(FieldKitDB.combatTextCounts and v.count>1 and (" x"..v.count) or ""))
    fs:ClearAllPoints()
    local offset=(i-1)*spacing
    local rise=math.min(9,age*5)
    fs:SetPoint("TOP",panel,"TOP",0,-28-offset+(direction==1 and rise or -rise))
    fs:Show()
   else fs:Hide() end
  end
  heading:SetText(FieldKit_L(running and "SIMULATION ACTIVE" or "SIMULATION PAUSED").."  -  "..FieldKit_L(C.ActiveProfile()=="quiet" and "Quiet" or C.ActiveProfile()=="all" and "All" or "Balanced"))
 end
 local previewRefreshElapsed=0
 panel:SetScript("OnUpdate",function()
  if not ui:IsVisible() or not ui.pages[1]:IsVisible() then
   -- Do not accumulate a stale preview clock while the options are hidden.
   elapsed=0;overlayElapsed=0;previewRefreshElapsed=0
   if overlayRunning then overlayRunning=false;C.Clear() end
   return
  end
  local dt=arg1 or 0;elapsed=elapsed+dt
  if running and elapsed>=.35 then
   -- A delayed frame must not trigger a burst of synthetic events.
   elapsed=0;Spawn()
  end
  if overlayRunning then
   overlayElapsed=overlayElapsed+dt
   if overlayElapsed>=.42 then
    overlayElapsed=0;overlayStep=overlayStep+1
    local sample=examples[math.mod(overlayStep-1,table.getn(examples))+1]
    if Eligible(sample[1]) then C.PreviewEmit(sample[1],sample[3],sample[2]) end
   end
  end
  -- C9: limit expensive font/color/layout updates to 20 Hz.
  -- The real combat renderer is untouched.
  previewRefreshElapsed=previewRefreshElapsed+dt
  if previewRefreshElapsed>=.05 then
   previewRefreshElapsed=0
   ui.RefreshPreview()
  end
 end)
 -- The existing preview button toggles this isolated feed, not real combat text.
 ui.ToggleSimulation=function()
  running=not running
  if running then elapsed=.35 else feed={} end
  ui.RefreshPreview()
 end
 Text(p,"Les profils conservent vos polices, couleurs et positions.",0,-422)
 p=ui.pages[7]
 Text(p,"Ajustements fins du texte de combat",0,0)
 Number(p,"Messages simultanés (toutes zones)",-53,"combatTextMax",1,10)
 Number(p,"Durée d'affichage",-106,"combatTextDuration",6,50,function(v) return string.format("%.1f s",v/10) end)
 Number(p,"Fenêtre de regroupement",-159,"combatTextWindow",5,75,function(v) return string.format("%.2f s",v/100) end)
 do
  local item=FieldKitUI.nativeTextOptions and FieldKitUI.nativeTextOptions[1]
  if item then Check(p,item.label,-220,item.get,item.set,item.tip) end
 end
 Button(p,"Utiliser seulement ce texte",0,-264,width,function() if FieldKit_UseCombatTextOnly then FieldKit_UseCombatTextOnly();ui.Refresh() end end)
 Text(p,"Ce bouton désactive le texte de dégâts natif. L'ancrage au monde nécessite AS 0.138+.",0,-310)
 Button(p,"Retour aux réglages essentiels",0,-378,width,function() Select(1) end)
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
 local normalFontChoice=Choice(p,"Police normale",0,fonts,function() return C.Number("combatTextFont",1,1,4) end,function(v) FieldKitDB.combatTextFont=v end)
 local critFonts={"Identique à la normale"};for i=1,table.getn(fonts) do table.insert(critFonts,fonts[i]) end
 local critFontChoice=Choice(p,"Police des critiques",-62,critFonts,function() return C.Number("combatTextCritFont",0,0,4)+1 end,function(v) FieldKitDB.combatTextCritFont=v-1 end)
 -- Each option is rendered in its actual font, including the collapsed selection.
 local function StyleFontChoice(choice,offset)
  for i=1,table.getn(choice.choiceButtons) do
   local item=choice.choiceButtons[i];local fontIndex=i-offset
   if fontIndex>=1 and fontIndex<=table.getn(C.fonts) then item.fieldkitLabel:SetFont(C.fonts[fontIndex][2],14,"OUTLINE") end
  end
  local old=choice.Refresh
  choice.Refresh=function()
   old();local selected=choice.get()-offset
   if selected>=1 and selected<=table.getn(C.fonts) then choice.fieldkitLabel:SetFont(C.fonts[selected][2],14,"OUTLINE")
   else choice.fieldkitLabel:SetFont(C.fonts[1][2],13,"OUTLINE") end
  end
  choice.Refresh()
 end
 StyleFontChoice(normalFontChoice,0);StyleFontChoice(critFontChoice,1)
 Choice(p,"Contour",-124,{"Aucun","Fin","Épais"},function() return C.Number("combatTextOutline",2,1,3) end,function(v) FieldKitDB.combatTextOutline=v end)
 Number(p,"Taille normale",-191,"combatTextFontSize",10,32,function(v) return v.." px" end)
 Number(p,"Taille des critiques",-244,"combatTextCritSize",10,40,function(v) return v.." px" end)
 Number(p,"Opacité",-297,"combatTextOpacity",10,100,function(v) return v.."%" end)
 Flag(p,"Afficher le nom des compétences",-350,"combatTextNames")
 Flag(p,"Afficher le nombre de frappes regroupées",-379,"combatTextCounts")
 Button(p,"Preview",0,-421,width,function() C.Preview() end)
 p=ui.pages[4]
 Flag(p,"Outgoing damage and actions",0,"combatTextOutgoing")
 Flag(p,"Incoming damage and actions",-29,"combatTextIncoming")
 Flag(p,"Soins reçus",-58,"combatTextHealing")
 Number(p,"Dégât minimum (par frappe)",-102,"combatTextMin",0,500)
 Number(p,"Soin minimum (par mise à jour)",-155,"combatTextHealMin",0,500)
 Text(p,"Hidden abilities: one game-provided name per line. Example: Backstab. Maximum 32 names.",0,-213)
 local edit=CreateFrame("EditBox",Name(),p);edit:SetWidth(width-10);edit:SetHeight(90);edit:SetPoint("TOPLEFT",p,"TOPLEFT",5,-253)
 Track(edit,5,width-10);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject("ChatFontNormal")
 edit:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8})
 if edit.SetMaxLetters then edit:SetMaxLetters(2000) end
 edit:SetScript("OnEscapePressed",function() this:ClearFocus() end)
 Button(p,"Reload list",0,-358,width/2-5,function() edit:SetText(FieldKitDB.combatTextIgnore or "");edit:ClearFocus() end)
 Button(p,"Apply list",width/2+5,-358,width/2-5,function() FieldKitDB.combatTextIgnore=C.LimitText(edit:GetText() or "",2000);edit:ClearFocus() end)
 p:SetScript("OnShow",function() edit:SetText(FieldKitDB and FieldKitDB.combatTextIgnore or "") end)
 ui.ignoreEdit=edit
 Text(p,"Matches the name received from the game, without the healing prefix. Small hits are filtered before merging. Partially blocked hits remain one damage message.",0,-404)
 p=ui.pages[5]
 Flag(p,"Separate incoming / healing and outgoing",0,"combatTextSplit")
 Choice(p,"Scroll direction",-41,{"Upward","Downward"},function() return C.Number("combatTextDirection",1,1,2) end,function(v) FieldKitDB.combatTextDirection=v end)
 Button(p,"Show drag handles",0,-104,width,function() FieldKitUI.StartLayout(true) end)
 Button(p,"Hide handles",0,-137,width,function() C.HideAnchors() end)
 Number(p,"Line spacing",-186,"combatTextSpacing",18,60,function(v) return v.." px" end)
 Choice(p,"Position to edit",-245,{"Outgoing area","Incoming / healing area"},function() return ui.positionArea or 1 end,function(v) ui.positionArea=v end)
 -- Select the outgoing or incoming/healing saved offset key.
 local function PositionKey(axis) return (ui.positionArea==2 and "combatTextIncoming" or "combatText")..axis end
 Slider(p,"Horizontal offset",-310,-600,600,function() local key=PositionKey("X");return C.Number(key,C.defaults[key],-600,600) end,function(v) FieldKitDB[PositionKey("X")]=v end,function(v) return v.." px" end)
 Slider(p,"Vertical offset",-363,-300,300,function() local key=PositionKey("Y");return C.Number(key,C.defaults[key],-300,300) end,function(v) FieldKitDB[PositionKey("Y")]=v end,function(v) return v.." px" end)
 Text(p,"Offsets are measured from the screen center. Drag handles also save these values.",0,-421)
 p=ui.pages[6]
 for i=1,table.getn(FieldKitUI.nativeTextOptions) do
  local item=FieldKitUI.nativeTextOptions[i];Check(p,item.label,-(i-1)*58,item.get,item.set,item.tip)
 end
 Text(p,"The native text is independent of FieldKit scrolling text. Disable duplicate displays here.",0,-200)
 function ui.Reflow(newWidth)
  width=newWidth;ui:SetWidth(width);navStatus:SetWidth(width)
  for i=1,table.getn(ui.pages) do ui.pages[i]:SetWidth(width) end
  for i=1,table.getn(layout) do
   local entry=layout[i];local widget=entry.widget
   local point,relative,rp,x,y=widget:GetPoint()
   widget:ClearAllPoints();widget:SetPoint(point,relative,rp,entry.x*width,y);widget:SetWidth(entry.w*width)
   if widget.Reflow then widget.Reflow(entry.w*width) end
   if widget.fieldkitLabel then widget.fieldkitLabel:SetWidth(math.max(20,entry.w*width-20)) end
   T.Update(widget)
  end
 end
 FieldKit_RefreshLanguage(function()
  navStatus:SetText(ui.selected.." / 7  -  "..FieldKit_L(labels[ui.selected]))
  ui.Refresh()
 end)
 parent.combatEditor=ui;parent:SetScript("OnShow",function() for i=1,table.getn(ui.menus) do ui.menus[i]:Hide() end;ui.Refresh() end)
 Select(1);return ui
end
