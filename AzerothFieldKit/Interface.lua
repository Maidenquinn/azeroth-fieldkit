-- User journey and owned configuration UI. Native effects stay in injected actions.
-- No settings setter runs while constructing/refreshing controls.
FieldKitUI={controls={},menus={},pages={},homeCards={}}
local U=FieldKitUI
local T=FieldKitTheme

-- Replace competing HP checkboxes with a single mutually exclusive choice.
local function HealthChoice(key,label,refresh)
 return {kind="choice",label=label,values={"Numbers","Percentage","Numbers + percentage"},
  get=function() return FieldKitDB[key] end,
  set=function(value) FieldKitDB[key]=value;if refresh then refresh() end end}
end

-- Reuse existing option actions/data; reorganize the journey without losing keys.
function FieldKit.BuildJourneySections(sections,actions)
 local old={};for i=1,table.getn(sections) do old[sections[i].title]=sections[i] end
 local player,target,combat=old.Player.items,old.Target.items,old.Combat.items
 U.nativeTextOptions={combat[2],combat[3],combat[4]}
 local interface=old.Interface.items
 for i=1,table.getn(interface) do
  if interface[i].label=="Compact action bar" then
   interface[i].set=function(value) FieldKitDB.compactBar=value end
   interface[i].tip="Saved now. Use Reload UI below to apply the compact bar; your current run is not reloaded automatically."
  end
 end
 table.insert(interface,{kind="camera"})
 local windows=old.Windows.items
 table.insert(windows,2,{kind="check",label="Gold and chest price",tip="Show the separate gold and next-chest strip. Hiding it restores the native tally if FieldKit replaced it.",
  get=function() return FieldKitDB.moneyFrame end,
  set=function(value) FieldKitDB.moneyFrame=value;actions.SyncHudTally();actions.UpdateMoneyFrame() end})
 return {
  {id="home",title="Overview",glyph=13,group="Start here",items={{kind="home"}}},
  {id="combat",title="Combat text",glyph=2,group="Combat & health",items={{kind="combat"}}},
  {id="health",title="Health & buffs",glyph=16,items={player[1],HealthChoice("playerHealthMode","Player health format",actions.UpdatePlayerBar),player[2],player[3],target[1],HealthChoice("targetHealthMode","Target health format",actions.UpdateTargetHealth)}},
  {id="bosses",title="Bosses",glyph=5,items={combat[1],HealthChoice("bossHealthMode","Boss health format",actions.UpdateBossFrame)}},
  {id="alerts",title="Alerts",glyph=12,items=old.Warnings.items},
  {id="windows",title="Windows",glyph=9,group="Your interface",items=windows},
  {id="map",title="Minimap",glyph=1,items=old.Map.items},
  {id="nameplates",title="Nameplates",glyph=7,items=old.Nameplates.items},
  {id="interface",title="Interface",glyph=11,items=interface},
 }
end

-- One owned tooltip; no chat/network output for normal configuration changes.
function U.Tip(owner,label,detail)
 GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L(label),1,.85,.55)
 if detail then GameTooltip:AddLine(FieldKit_L(detail),.8,.83,.8,true) end
 GameTooltip:Show()
end

-- Bound dropdown height, with native scrolling rather than a screen-sized list.
function U.Choice(parent,name,label,x,y,w,values,get,set,refresh)
 local button=T.Button(parent,name,"",x,y,w,30,nil)
 button.arrow=T.Glyph(button,1,w-23,8,14);button.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
 -- A popup belongs to UIParent so the page's scroll viewport cannot clip it.
 local menu=CreateFrame("Frame",name.."Menu",UIParent);menu:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-3)
 menu:SetWidth(w);menu:SetHeight(math.min(7,table.getn(values))*28+12);menu:SetFrameStrata("TOOLTIP");menu:SetFrameLevel(300)
 T.Surface(menu,"card")
 local scroll=CreateFrame("ScrollFrame",name.."Scroll",menu,"UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT",menu,"TOPLEFT",5,-5);scroll:SetWidth(w-30);scroll:SetHeight(menu:GetHeight()-10)
 local content=CreateFrame("Frame",nil,scroll);content:SetWidth(w-30);content:SetHeight(table.getn(values)*28)
 scroll:SetScrollChild(content);menu.scroll=scroll;menu.content=content;U.Wheel(scroll,content)
 button.choiceButtons={}
 for i=1,table.getn(values) do
  local index=i
  button.choiceButtons[i]=T.Button(content,nil,values[i],0,(i-1)*28,w-30,28,function() set(index);menu:Hide();if refresh then refresh() else U.Refresh() end end)
 end
 menu:Hide();table.insert(U.menus,menu);button.menu=menu
 button.callback=function()
  local shown=menu:IsShown();U.CloseMenus()
  if not shown then
   menu:ClearAllPoints()
   local bottom=button.GetBottom and button:GetBottom()
   if bottom and bottom<menu:GetHeight()+12 then menu:SetPoint("BOTTOMLEFT",button,"TOPLEFT",0,3)
   else menu:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-3) end
   menu:Show()
  end
 end
 button.get=get;button.label=label
 button.Refresh=function() FieldKit_Text(button,values[get()] or values[1]) end
 button.Reflow=function(width)
  button:SetWidth(width);button.fieldkitLabel:SetWidth(width-42);button.arrow:ClearAllPoints();button.arrow:SetPoint("RIGHT",button,"RIGHT",-6,0)
  menu:SetWidth(width);scroll:SetWidth(width-30);content:SetWidth(width-30)
  for i=1,table.getn(button.choiceButtons) do local b=button.choiceButtons[i];b:SetWidth(width-30);b.fieldkitLabel:SetWidth(width-50);T.Update(b) end
  T.Update(button);T.Update(menu)
 end
 button.Refresh();return button
end

function U.CloseMenus()
 for i=1,table.getn(U.menus) do U.menus[i]:Hide() end
end

-- Retain native scrollbar support; add a bounded wheel path where available.
function U.Wheel(scroll,content)
 if not scroll.EnableMouseWheel or not scroll.SetVerticalScroll then return end
 scroll:EnableMouseWheel(true)
 scroll:SetScript("OnMouseWheel",function()
  local current=scroll.GetVerticalScroll and scroll:GetVerticalScroll() or 0
  local maximum=math.max(0,content:GetHeight()-scroll:GetHeight())
  scroll:SetVerticalScroll(math.max(0,math.min(maximum,current-(arg1 or 0)*36)))
 end)
end

-- Live getters are separate from click setters, preventing initialization writes.
local function Checkbox(page,item,y)
 local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(76)
 local check=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate");check:SetWidth(24);check:SetHeight(24);check:SetPoint("TOPLEFT",row,"TOPLEFT",0,-2)
 local label=T.Label(row,item.label,30,1,500,24,14)
 local detail=T.Label(row,item.tip,30,29,500,44,12,T.muted)
 local action
 if item.button then action=T.Button(row,nil,item.button.text,0,1,98,26,item.button.onClick) end
 check.item=item;check.Refresh=function() check:SetChecked(item.get() and true or false) end
 check:SetScript("OnClick",function() item.set(this:GetChecked() and true or false);U.Refresh() end)
 check:SetScript("OnEnter",function() U.Tip(this,item.label,item.tip) end);check:SetScript("OnLeave",function() GameTooltip:Hide() end)
 row.Reflow=function(w)
  row:SetWidth(w);label:SetWidth(w-32-(action and 110 or 0));detail:SetWidth(w-32)
  if action then action:ClearAllPoints();action:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,-1) end
 end
 row.control=check;table.insert(U.controls,check);table.insert(page.flow,{frame=row,y=y})
 return y+76
end

local function Slider(page,item,y,camera)
 local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(camera and 100 or 78)
 local label=T.Label(row,item.label or "Max camera distance",0,0,500,24,14)
 local name="FieldKitJourneySlider"..(table.getn(U.controls)+1)
 local s=CreateFrame("Slider",name,row,"OptionsSliderTemplate");s:SetPoint("TOPLEFT",row,"TOPLEFT",8,-36);s:SetHeight(18)
 s:SetMinMaxValues(item.min or 15,item.max or 50);s:SetValueStep(item.step or 1)
 s.Refresh=function()
  local v=item.get();s:SetValue(v)
  FieldKit_Text(label,item.format and item.format(v) or (FieldKit_L(item.label)..": "..v..FieldKit_L(" yd")))
 end
 s:SetScript("OnValueChanged",function() if not U.refreshing then item.set(math.floor(this:GetValue()+.5));U.Refresh() end end)
 local low,high=getglobal(name.."Low"),getglobal(name.."High")
 if low then low:SetText(item.min or 15);T.Font(low,11,T.muted) end
 if high then high:SetText(item.max or 50);T.Font(high,11,T.muted) end
 local templateTitle=getglobal(name.."Text");if templateTitle then templateTitle:Hide() end
 local detail=camera and T.Label(row,"Camera changes apply immediately; other settings stay unchanged.",0,69,500,28,12,T.muted)
 row.Reflow=function(w) row:SetWidth(w);label:SetWidth(w);s:SetWidth(w-16);if detail then detail:SetWidth(w) end end
 table.insert(U.controls,s);table.insert(page.flow,{frame=row,y=y});return y+(camera and 106 or 84)
end

-- Small cards lead to the relevant page; no implicit presets/native changes.
local function BuildHome(page)
 page.intro=T.Label(page,"Choose your tools, then arrange your interface. Only enable what you need.",0,48,650,48,14,T.muted)
 local defs={{"Combat text","Animated damage and healing, with your own filters.",2,"combat","combatText"},
  {"Health & buffs","Readable player and target health, shields and buffs.",16,"health","playerBar"},
  {"Bosses","Independent portraits and health for tracked enemies.",5,"bosses","bossFrame"},
  {"Minimap","Choose chest and guardian-lair markers separately.",1,"map","chestPins"}}
 for i=1,4 do
  local d=defs[i];local c=CreateFrame("Frame",nil,page);c:SetHeight(142);T.Surface(c,"card")
  T.Glyph(c,d[3],14,16,32)
  c.title=T.Label(c,d[1],58,14,230,28,18,T.gold,true)
  c.state=T.Label(c,"",58,45,230,20,12,T.muted)
  c.detail=T.Label(c,d[2],16,72,280,38,12,T.muted)
  c.open=T.Button(c,nil,"Configure",16,110,260,25,function() U.Select(d[4]) end)
  c.key=d[5];table.insert(U.homeCards,c)
 end
 page.layoutCard=CreateFrame("Frame",nil,page);page.layoutCard:SetHeight(96);T.Surface(page.layoutCard,"card")
 page.layoutTitle=T.Label(page.layoutCard,"Arrange your HUD",16,12,400,26,19,T.gold,true)
 page.layoutHint=T.Label(page.layoutCard,"Move enabled windows without the settings panel covering them.",16,44,400,38,12,T.muted)
 page.layoutAction=T.Button(page.layoutCard,nil,"Move windows",0,32,164,30,function() U.SetLayoutEditing(true,false) end)
 page.contentHeight=520
end

-- Every page owns a scroll viewport, so smaller screens retain full-size text.
function U.BuildPage(section,index)
 local scroll=CreateFrame("ScrollFrame","FieldKitJourneyScroll"..index,U.frame,"UIPanelScrollFrameTemplate")
 local page=CreateFrame("Frame","FieldKitPanelPage"..index,scroll);page:SetWidth(700);page.flow={};page.section=section
 scroll:SetScrollChild(page);page.scroll=scroll;U.Wheel(scroll,page)
 page.heading=T.Label(page,section.title,0,0,640,36,26,T.gold,true)
 local y=56
 for i=1,table.getn(section.items) do
  local item=section.items[i]
  if item.kind=="home" then BuildHome(page);y=page.contentHeight
  elseif item.kind=="combat" then FieldKit_CreateCombatOptions(page);y=570
  elseif item.kind=="check" then y=Checkbox(page,item,y)
  elseif item.kind=="slider" then y=Slider(page,item,y)
  elseif item.kind=="choice" then
   local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(68)
   row.label=T.Label(row,item.label,0,0,650,22,14)
   local choice=U.Choice(row,"FieldKitHealthChoice"..index.."_"..i,item.label,0,30,620,item.values,item.get,item.set)
   row.Reflow=function(w) row:SetWidth(w);row.label:SetWidth(w);choice.Reflow(w) end
   table.insert(U.controls,choice);table.insert(page.flow,{frame=row,y=y});y=y+72
  elseif item.kind=="language" then
   local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(68)
   row.label=T.Label(row,"Language",0,0,300,22,14)
   row.en=T.Button(row,nil,"English",0,29,150,30,function() FieldKit_SetLanguage("en") end)
   row.fr=T.Button(row,nil,"Français",160,29,150,30,function() FieldKit_SetLanguage("fr") end)
   row.Reflow=function(w) row:SetWidth(w) end
   U.languageRow=row;table.insert(page.flow,{frame=row,y=y});y=y+84
  elseif item.kind=="camera" then
   y=Slider(page,{label="Max camera distance",get=function() return FieldKitDB.cameraMax or 15 end,
    set=function(v) U.context.camera(v) end},y,true)
  end
 end
 page.contentHeight=y+16;U.pages[index]=page
 return page
end

-- Refresh is pure UI except for explicit user setters invoked elsewhere.
function U.Refresh()
 if not U.frame or not FieldKitDB then return end
 U.refreshing=true
 for i=1,table.getn(U.controls) do U.controls[i].Refresh() end
 for i=1,table.getn(U.homeCards) do
  local c=U.homeCards[i];local enabled=FieldKitDB[c.key]
  if c.key=="chestPins" then enabled=enabled or FieldKitDB.guardianPins end
  if c.key=="playerBar" then enabled=enabled or FieldKitDB.targetHealth end
  FieldKit_Text(c.state,enabled and "Enabled" or "Disabled")
  local color=enabled and T.green or T.muted;c.state:SetTextColor(color[1],color[2],color[3])
 end
 if U.languageRow then
  T.State(U.languageRow.en,FieldKit_Language()=="en");T.State(U.languageRow.fr,FieldKit_Language()=="fr")
 end
 local reload=(FieldKitDB.compactBar==true)~=(FieldKit.appliedCompactBar==true)
 U.reloadNeeded=reload
 if U.contentWidth then U.status:SetWidth(reload and U.contentWidth-166 or U.contentWidth) end
 if reload then U.reload:Show() else U.reload:Hide() end
 if U.undoPositions then U.undo:Show() else U.undo:Hide() end
 FieldKit_Text(U.status,reload and "Compact bar saved. Reload UI when you are ready." or "Changes apply immediately. Your preferences are kept.")
 U.refreshing=false
end

-- Persist stable page ids; old numeric selections are migrated in Config.lua.
function U.Select(id)
 if type(id)=="number" then id=U.sections[id] and U.sections[id].id end
 local selected=1
 for i=1,table.getn(U.sections) do if U.sections[i].id==id then selected=i end end
 U.CloseMenus()
 for i=1,table.getn(U.pages) do
  local page=U.pages[i];local tab=U.frame.tabs[i];local active=i==selected
  if active then page.scroll:Show();page:Show() else page:Hide();page.scroll:Hide() end
  tab.fieldkitSelected=active;T.State(tab,active)
 end
 FieldKitDB.uiPage=U.sections[selected].id;FieldKitDB.panelTab=selected;FieldKitDB.panelSection=U.sections[selected].title
 U.Refresh()
end

-- Responsive width/reflow and vertical scrolling, not unreadable whole-window scaling.
function U.Reflow()
 if not U.frame then return end
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 local w,h=math.max(740,math.min(1000,sw-24)),math.max(560,math.min(760,sh-24))
 U.screenWidth=sw;U.screenHeight=sh;U.frame:SetWidth(w);U.frame:SetHeight(h)
 U.frame:SetScale(math.min(1,(sw-16)/w,(sh-16)/h));T.Update(U.frame)
 local sidebar=w<900 and 174 or 204;local x=sidebar+36;local content=w-x-34
 U.header:SetWidth(w-64);U.headerLine:SetWidth(w-44)
 U.title:SetWidth(w-220);U.subtitle:SetWidth(w-230)
 U.status:ClearAllPoints();U.status:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-(h-78));U.contentWidth=content;U.status:SetWidth(U.reloadNeeded and content-166 or content)
 local y=h-44
 U.move:ClearAllPoints();U.move:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-y)
 U.reset:ClearAllPoints();U.reset:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x+152,-y)
 U.undo:ClearAllPoints();U.undo:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x+320,-y)
 U.close:ClearAllPoints();U.close:SetPoint("TOPRIGHT",U.frame,"TOPRIGHT",-22,-y)
 U.reload:ClearAllPoints();U.reload:SetPoint("TOPRIGHT",U.frame,"TOPRIGHT",-22,-(h-80))
 for i=1,table.getn(U.pages) do
  local page=U.pages[i];local scroll=page.scroll
  scroll:ClearAllPoints();scroll:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-132)
  scroll:SetWidth(content);scroll:SetHeight(h-232);page:SetWidth(content-10);page:SetHeight(math.max(page.contentHeight,h-232))
  page.heading:SetWidth(content-14)
  for j=1,table.getn(page.flow) do page.flow[j].frame.Reflow(content-16) end
  if page.combatEditor and page.combatEditor.Reflow then page.combatEditor.Reflow(content-16) end
  local tab=U.frame.tabs[i];tab:SetWidth(sidebar-14);tab.fieldkitLabel:SetWidth(sidebar-59);T.Update(tab)
  if page.intro then
   page.intro:SetWidth(content-16)
   local cw=(content-28)/2
   for j=1,4 do
    local c=U.homeCards[j];c:ClearAllPoints();c:SetPoint("TOPLEFT",page,"TOPLEFT",math.mod(j-1,2)*(cw+12),-108-math.floor((j-1)/2)*154)
    c:SetWidth(cw);c.title:SetWidth(cw-70);c.state:SetWidth(cw-70);c.detail:SetWidth(cw-32)
    c.open:SetWidth(cw-32);c.open.fieldkitLabel:SetWidth(cw-52);T.Update(c);T.Update(c.open)
   end
   page.layoutCard:ClearAllPoints();page.layoutCard:SetPoint("TOPLEFT",page,"TOPLEFT",0,-426);page.layoutCard:SetWidth(content-16)
   page.layoutTitle:SetWidth(content-204);page.layoutHint:SetWidth(content-204)
   page.layoutAction:ClearAllPoints();page.layoutAction:SetPoint("TOPRIGHT",page.layoutCard,"TOPRIGHT",-16,-32);T.Update(page.layoutCard)
  end
 end
 U.CloseMenus()
end

-- Hide settings during arrangement so the large panel cannot cover movable frames.
function U.SetLayoutEditing(enabled,returnToSettings)
 FieldKit.layoutEditing=enabled and true or false
 if enabled then
  U.routingLayout=true;U.frame:Hide();U.routingLayout=nil
  U.context.unlock(true);U.context.bosses();U.dock:Show()
  if FieldKitDB.combatText then FieldKitCombat.ShowAnchors() end
 else
  U.dock:Hide();U.context.unlock(false);FieldKitCombat.HideAnchors();U.context.bosses()
  if returnToSettings then U.Reflow();U.frame:Show();U.Refresh() end
 end
end

function U.StartLayout(combat)
 U.SetLayoutEditing(true,false);if combat then FieldKitCombat.ShowAnchors() end
end

-- Position reset has a bounded, immediate Undo; feature/style preferences are untouched.
function U.ResetPositions()
 local snapshot={pos={},detached=FieldKitDB.moneyDetached}
 for name,p in pairs(FieldKitDB.pos) do snapshot.pos[name]={p[1],p[2]} end
 U.undoPositions=snapshot;U.context.reset();U.Refresh()
end

function U.UndoPositions()
 local saved=U.undoPositions;if not saved then return end
 FieldKitDB.pos=saved.pos;FieldKitDB.moneyDetached=saved.detached
 U.undoPositions=nil;U.context.positions();U.Refresh()
end

-- Build once. Only owned frames are skinned; all game-state actions are injected.
function U.Build(sections,context)
 U.sections=sections;U.context=context
 local frame=CreateFrame("Frame","FieldKitPanel",UIParent);U.frame=frame
 frame:SetWidth(1000);frame:SetHeight(760);frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
 frame:SetFrameStrata("DIALOG");frame:SetFrameLevel(100);frame:SetMovable(true);frame:EnableMouse(true)
 if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
 T.Surface(frame,"window")
 U.seal=frame:CreateTexture(nil,"ARTWORK");U.seal:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-16);U.seal:SetWidth(82);U.seal:SetHeight(82);U.seal:SetTexture(T.media.."ChronicleSeal.tga")
 U.title=T.Label(frame,"AZEROTH FIELDKIT",116,21,700,42,30,T.gold,true)
 U.subtitle=T.Label(frame,"Combat and interface tools",119,69,600,22,13,T.muted)
 U.version=T.Label(frame,"v"..FieldKit.version,810,19,146,20,11,T.muted)
 U.version:ClearAllPoints();U.version:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-48,-22)
 local line=frame:CreateTexture(nil,"ARTWORK");line:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-111);line:SetWidth(956);line:SetHeight(1);line:SetTexture(.54,.44,.27);U.headerLine=line
 local header=CreateFrame("Frame",nil,frame);header:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-12);header:SetWidth(900);header:SetHeight(92);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
 U.header=header
 header:SetScript("OnDragStart",function() frame:StartMoving() end)
 header:SetScript("OnDragStop",function() frame:StopMovingOrSizing() end)
 local x=CreateFrame("Button","FieldKitPanelClose",frame,"UIPanelCloseButton");x:SetWidth(26);x:SetHeight(26);x:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-10,-10);x:SetFrameLevel(120);x:SetScript("OnClick",function() frame:Hide() end)
 frame.tabs={};local y=128
 for i=1,table.getn(sections) do
  local section=sections[i];local id=section.id
  if section.group then T.Label(frame,section.group,26,y,174,20,11,T.muted);y=y+24 end
  local b=T.Button(frame,"FieldKitPanelTab"..i,section.title,22,y,190,32,function() U.Select(id) end)
  b.section=section;b.fieldkitNavigation=true;T.State(b,false);b.fieldkitLabel:ClearAllPoints();b.fieldkitLabel:SetPoint("LEFT",b,"LEFT",37,0)
  T.Glyph(b,section.glyph,7,6,21);b.page=U.BuildPage(section,i);frame.tabs[i]=b;y=y+34
 end
 U.status=T.Label(frame,"",240,680,650,24,12,T.muted)
 U.move=T.Button(frame,"FieldKitMoveWindows","Move windows",240,716,142,28,function() U.SetLayoutEditing(true,false) end)
 U.reset=T.Button(frame,"FieldKitPanelReset","Reset HUD positions",392,716,158,28,U.ResetPositions)
 U.undo=T.Button(frame,nil,"Undo",560,716,66,28,U.UndoPositions)
 U.close=T.Button(frame,nil,"Close",874,716,100,28,function() frame:Hide() end)
 U.reload=T.Button(frame,nil,"Reload UI",824,680,150,26,function() if U.reloadNeeded then context.reload() end end)
 local dock=CreateFrame("Frame","FieldKitLayoutDock",UIParent);U.dock=dock
 dock:SetWidth(560);dock:SetHeight(92);dock:SetPoint("TOP",UIParent,"TOP",0,-30);dock:SetFrameStrata("DIALOG");dock:SetFrameLevel(150);T.Surface(dock,"window")
 T.Label(dock,"Move your enabled windows",18,12,380,26,20,T.gold,true)
 T.Label(dock,"Drag a window or a combat area, then choose Done.",18,44,370,30,12,T.muted)
 U.done=T.Button(dock,"FieldKitLayoutDone","Done",438,29,100,30,function() U.SetLayoutEditing(false,true) end)
 dock:SetScript("OnHide",function() if FieldKit.layoutEditing then U.SetLayoutEditing(false,false) end end);dock:Hide()
 frame:SetScript("OnShow",function() U.Refresh() end)
 frame:SetScript("OnHide",function()
  U.CloseMenus()
  if context.dismiss then context.dismiss() end
  if not U.routingLayout then FieldKit.layoutEditing=false;context.unlock(false);FieldKitCombat.HideAnchors();context.bosses() end
 end)
 local elapsed=0
 frame:SetScript("OnUpdate",function()
  elapsed=elapsed+(arg1 or 0);if elapsed<.25 then return end;elapsed=0
  if U.screenWidth~=UIParent:GetWidth() or U.screenHeight~=UIParent:GetHeight() then U.Reflow() end
 end)
 if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"FieldKitPanel");table.insert(UISpecialFrames,"FieldKitLayoutDock") end
 FieldKit_RefreshLanguage(U.Refresh);U.Reflow();U.Select(FieldKitDB.uiPage or "home");frame:Hide()
 return frame
end

function U.Toggle()
 if FieldKit.layoutEditing then U.SetLayoutEditing(false,true)
 elseif U.frame:IsShown() then U.frame:Hide()
 else U.Reflow();U.frame:Show();U.Refresh() end
end
