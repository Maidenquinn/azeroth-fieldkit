-- Context-free visual examples. Never write samples to native tables, meters,
-- saved gameplay data or party sharing. Only explicit placement/reset saves HUD
-- geometry. All example frames are separate from the live renderer's frame pool.
FieldKitPreview={frames={},roots={},included={},selected=2}
local P=FieldKitPreview
local T=FieldKitTheme

function P.Initialize(createBar,createBoss,place)
 P.createBar=createBar;P.createBoss=createBoss;P.place=place
 P.names={};P.labels={}
 for i=1,table.getn(FieldKitCardLayout.names) do
  P.names[i]=FieldKitCardLayout.names[i];P.labels[i]=FieldKitCardLayout.labels[i]
  P.included[i]=i<9 or i>12
 end
 P.bossIndex=table.getn(P.names)+1;P.playerIndex=P.bossIndex+1;P.targetIndex=P.bossIndex+2
 table.insert(P.names,"FieldKitBossFrame1");table.insert(P.labels,"Bosses");P.included[P.bossIndex]=true
 table.insert(P.names,"FieldKitPlayerBar");table.insert(P.labels,"Player health format")
 table.insert(P.names,"FieldKitTargetHealth");table.insert(P.labels,"Target health format")
 -- Health formats are available in the inspector. Existing player-bar dragging
 -- remains live; target text follows the native target frame.
end

function P.Group(index)
 if FieldKitDB.linkLeftCards and (index<=4) then return FieldKitHudStack.root end
 if FieldKitDB.linkRightCards and (index==5 or index==6) then return FieldKitCardLayout.root end
end

-- A proxy group owns sample positioning only. The live group's geometry is not
-- stretched to fit examples. Commit its native anchor after the user drags it.
function P.Root(source)
 local name=source:GetName();local root=P.roots[name]
 if not root then
  root=CreateFrame("Frame",nil,UIParent);P.roots[name]=root
  root.source=source;root:SetMovable(true);root:SetClampedToScreen(true)
 end
 root:SetWidth(source:GetWidth());root:SetHeight(source:GetHeight())
 if not root.moving then
  local a,b,c,x,y=source:GetPoint(1)
  if a then root:ClearAllPoints();root:SetPoint(a,b,c,x,y) end
 end
 return root
end

function P.Commit(proxy,source)
 local a,b,c,x,y=proxy:GetPoint(1)
 if a and (not b or b==UIParent or b=="UIParent") then
  local anchor={a,c or a,x,y}
  if FieldKitPositions.Valid(anchor) then
   FieldKitDB.frameAnchors[source:GetName()]=anchor;P.place(source)
   if source==FieldKitMoneyFrame then FieldKitDB.moneyDetached=true end
  end
 end
end

function P.Drag(frame,start)
 if P.mode~="place" or frame.index>=P.playerIndex then return end
 local source=P.Group(frame.index) or getglobal(P.names[frame.index])
 local proxy=P.Group(frame.index) and frame:GetParent() or frame
 if start then proxy.moving=true;proxy:StartMoving()
 elseif proxy.moving then
  proxy:StopMovingOrSizing();proxy.moving=nil;P.Commit(proxy,source)
 end
end

-- HP examples use their actual format helper and the player's bar dimensions.
-- The wrapper adds a sample label; the health bar, shield and buff strip remain
-- distinct regions. Target text deliberately has no independent placement action.
function P.HealthFrame()
 local f=CreateFrame("Frame",nil,UIParent);f:SetWidth(280);f:SetHeight(108)
 f.title=T.Label(f,"Preview — sample data",0,0,280,24,12,T.gold)
 f.healthInfo=T.Label(f,"",0,23,280,18,12,T.text)
 f.targetInfo=T.Label(f,"",0,78,280,18,11,T.muted)
 local bar=CreateFrame("StatusBar",nil,f);f.health=bar
 bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,-48);bar:SetHeight(9)
 bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");bar:SetStatusBarColor(.1,.9,.1)
 bar:SetMinMaxValues(0,12200);bar:SetValue(6705)
 f.hp=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.hp:SetPoint("BOTTOM",bar,"TOP",0,3)
 f.shield=bar:CreateTexture(nil,"OVERLAY");f.shield:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0);f.shield:SetHeight(9);f.shield:SetTexture(.55,.85,1,.75)
 f.buffs={}
 for i=1,3 do
  local icon=f:CreateTexture(nil,"ARTWORK");icon:SetWidth(18);icon:SetHeight(18)
  icon:SetPoint("TOPLEFT",bar,"BOTTOMLEFT",(i-1)*20,-5);icon:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude");f.buffs[i]=icon
 end
 return f
end

function P.Frame(index)
 if P.frames[index] then return P.frames[index] end
 local f
 if index>=P.playerIndex then f=P.HealthFrame()
 elseif index==P.bossIndex then
  f=P.createBoss(1,true)
  -- The native boss name/HP text may be hidden by live-HUD visibility
  -- controllers. Own a separate overlay with independent fixture values.
  f.previewOverlay=CreateFrame("Frame",nil,f)
  f.previewOverlay:SetAllPoints(f)
  f.previewOverlay:SetFrameLevel(f:GetFrameLevel()+15)
  f.previewName=T.Label(f.previewOverlay,"",104,9,210,18,12,T.gold)
  f.previewHealth=T.Label(f.previewOverlay,"",104,57,210,18,12,T.text)
  f.previewDetail=T.Label(f.previewOverlay,"",104,75,210,15,11,T.muted)
 else
  f=P.createBar("FieldKitPreviewCard"..index,P.labels[index],8)
  f.mashCollapseButton:Hide();f.mashCollapsed=false;FieldKit.CreateMeterColumns(f)
  -- Dedicated sample labels: native meter row visibility and layout are controlled
  -- by the live HUD, so preview data must not depend on that row pool.
  f.sampleLines={}
  for n=1,8 do
   local line=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   line:SetJustifyH("LEFT");line:SetTextColor(.92,.84,.63)
   line:SetPoint("TOPLEFT",f,"TOPLEFT",10,-27-(n-1)*18)
   line:SetHeight(16);f.sampleLines[n]=line
  end
  if index==5 then
   for _,row in ipairs(f.rows) do row.sampleBonus=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.sampleBonus:SetPoint("TOPLEFT",row,"TOPLEFT",3,-15);row.sampleBonus:SetHeight(12);row.sampleBonus:SetTextColor(.3,1,.4) end
  end
 end
 f.index=index;f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function() P.Drag(f,true) end)
 f:SetScript("OnDragStop",function() P.Drag(f,false) end)
 f:SetFrameStrata("DIALOG");f:SetFrameLevel(130)
 P.frames[index]=f;return f
end

-- Local deterministic examples, with familiar categories and non-player names.
-- Values are presentation fixtures, not a hypothetical damage attribution.
function P.Rows(index)
 local hp=FieldKit_FormatHealth(6705,12200,FieldKitDB.partyHealthMode)
 if index==1 then return {{"Heroic II","Example"},{"Bolstering","Example"},{"Next boss","1:24"}} end
 if index==2 then
  local mode=FieldKitMeters.Mode()
  if mode==2 then return {{"Healing",42000,1400,.7},{"Regeneration",18000,600,.3}} end
  return {{"Fireball",42000,1400,.7},{"Melee",12000,400,.2},{"Periodic damage",6000,200,.1}}
 end
 if index==3 then return {{"Monster melee",720,24,.6},{"Boss spells",360,12,.3},{"Elites",120,4,.1}} end
 if index==4 then return {{"Guardian","Awake"},{"Guardian","2:14"},{"Guardian","Asleep"},{"Guardian","0:32"}} end
 if index==5 and FieldKitDB.loadoutTab==2 then return {{"Fireball","Rank 3","+8% / -16%"},{"Melee","Rank 3","+4%"}} end
 if index==5 then return {{"Amulet","Example"},{"Trinket 1","Example"},{"Trinket 2","Example"},{"Ring 1","Example"},{"Ring 2","Example"}} end
 if index==6 then return {{"Damage","+120%"},{"Haste","+30%"},{"Crit Chance","25%"},{"Lifesteal","3%"}} end
 if index==7 then return {{"Gold","640"},{"Chest price","86"},{"Next chest","720"}} end
 if index==8 then return {{"Player A",42000,1400,.4},{"Player B",31500,1050,.3},{"Player C",21000,700,.2},{"Player D",10500,350,.1}} end
 if index>=9 and index<=12 then return {{"Health",hp,.55},{"Mana","65 / 100",.65},{"Damage / DPS","42000 / 1400"}} end
 if index==13 then
  local rows={}
  if FieldKitDB.effectTotems then table.insert(rows,{"Totems","2  /  12s"}) end
  if FieldKitDB.effectSummons then table.insert(rows,{"Summons","3  /  24s"}) end
  if FieldKitDB.effectTimers then table.insert(rows,{"Effects","8s"}) end
  if table.getn(rows)==0 then table.insert(rows,{"Filters","No categories selected"}) end
  return rows
 end
 if index==14 then return {{"You are down","Player B"},{"Revived by","65%",.65}} end
 if index==15 then return {{"Next boss","1:24"},{"Stored level-ups","3"}} end
 local rows={}
 if FieldKitDB.mechanicWarnings then table.insert(rows,{"Mechanic banner messages","Move away"}) end
 if FieldKitDB.bossBannerWarnings then table.insert(rows,{"Boss banner messages","Next boss"}) end
 if table.getn(rows)==0 then table.insert(rows,{"Filters","No categories selected"}) end
 return rows
end

function P.Render(index)
 local f=P.Frame(index);local source=getglobal(P.names[index])
 if index>=P.playerIndex then
  local player=index==P.playerIndex
  local mode=player and FieldKitDB.playerHealthMode or FieldKitDB.targetHealthMode
  f.health:SetWidth(player and FieldKitPlayerBar:GetWidth() or 180)
  f.health:SetMinMaxValues(0,12200);f.health:SetValue(6705)
  f.hp:SetText(FieldKit_FormatHealth(6705,12200,mode));FieldKit_Text(f.title,"Preview — sample data")
  f.healthInfo:SetText((player and FieldKit_L("Player") or FieldKit_L("Target")).."  ·  "..FieldKit_FormatHealth(6705,12200,mode))
  f.targetInfo:SetText(player and FieldKit_L("Shield").."  2,440  ·  "..FieldKit_L("Buffs").."  3" or FieldKit_L("Target").."  55%")
  f.shield:SetWidth(f.health:GetWidth()*.2)
  if player and FieldKitDB.playerShield then f.shield:Show() else f.shield:Hide() end
  for _,icon in ipairs(f.buffs) do if player and FieldKitDB.playerBuffs then icon:Show() else icon:Hide() end end
 elseif index==P.bossIndex then
  f.name:SetText(FieldKit_L("Boss").." · "..FieldKit_L("Preview"))
  f.hp:SetText(FieldKit_FormatHealth(6705,12200,FieldKitDB.bossHealthMode))
  f.bar:SetMinMaxValues(0,12200);f.bar:SetValue(6705);f.level:SetText("7")
  f.previewName:SetText(FieldKit_L("Boss").." · "..FieldKit_L("Preview").."  Lv. 7")
  f.previewHealth:SetText(FieldKit_FormatHealth(6705,12200,FieldKitDB.bossHealthMode).."  (55%)")
  f.previewDetail:SetText(FieldKit_L("Shield").."  1,250  ·  3 debuffs")
  FieldKit_Text(f.tag,"Preview — sample data")
  local data=FieldKit_PortraitCatalog.feralas and FieldKit_PortraitCatalog.feralas["Brute gordunni"]
  f.portrait:SetTexture(data and "Interface\\AddOns\\AzerothFieldKit\\Portraits\\"..data.key..".tga" or "Interface\\Icons\\INV_Misc_QuestionMark")
  local icons={"Spell_Shadow_ShadowWordPain","Ability_Rogue_Rupture","Spell_Frost_FrostShock"}
  for i=1,table.getn(f.debuffs) do
   local d=f.debuffs[i]
   if icons[i] then d:SetTexture("Interface\\Icons\\"..icons[i]);d:Show();d.time:SetText((i*3).."s");d.time:Show();d.count:SetText(i);d.count:Show()
   else d:Hide();d.time:Hide();d.count:Hide() end
  end
 else
  local rows=P.Rows(index);local size=FieldKitDB.cardSizes[P.names[index]]
  local width=math.max(280,size and size.width or source:GetWidth())
  if index==2 or index==8 or index==3 then width=math.max(width,FieldKit.MeterWidth(FieldKitDB.meterValues)) end
  local rowHeight=(index==5) and 32 or 14
  local nativeRows=f.rows and table.getn(f.rows) or 0
  -- All inspector cards use independent sample text. Live row widgets may be
  -- hidden/repositioned by HUD layout and must never suppress fixture data.
  local useSamples=true
  f:SetWidth(width);f:SetHeight(math.max(36+18*table.getn(rows),size and size.height or 0,94))
  for n=1,table.getn(f.sampleLines or {}) do
   local line=f.sampleLines[n]
   local d=useSamples and rows[n] or nil
   if d then
    line:SetWidth(width-20)
    local detail=FieldKit_L(tostring(d[2]))
    if type(d[2])=="number" then
     detail=tostring(d[2])
     if type(d[3])=="number" then detail=detail.."  /  "..tostring(d[3]).." DPS" end
    end
    line:SetText(FieldKit_L(d[1]).."    "..detail)
    line:Show()
   else line:Hide() end
  end
  FieldKit_Text(f.title,"Preview");f.title:SetWidth(width*.28)
  FieldKit_Text(f.total,P.labels[index]);f.total:SetWidth(width*.6)
  for i=1,table.getn(f.rows) do
   local row=f.rows[i];local d=useSamples and nil or rows[i]
   if d then
    row:ClearAllPoints();row:SetPoint("TOPLEFT",f,"TOPLEFT",6,-22-(i-1)*math.min(32,(f:GetHeight()-28)/table.getn(rows)))
    row:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-22-(i-1)*math.min(32,(f:GetHeight()-28)/table.getn(rows)))
    if row.sampleBonus then row.sampleBonus:SetWidth(width-24);row.sampleBonus:SetText(type(d[3])=="string" and d[3] or "+8%") end
    row:SetHeight(12);row.label:SetText(FieldKit_L(d[1]));row.value:Show()
    if type(d[2])=="number" then
     row.meterMode=nil
     FieldKit.UpdateMeterColumns(row,{name=d[1],dmg=d[2],dps=d[3],share=d[4]},FieldKitDB.meterValues,width,index==2 and FieldKitMeters.Mode()==2 and FieldKit_L("hps") or nil)
    else
     if row.meterColumns then for j=1,3 do row.meterColumns[j]:Hide() end end
     row.meterMode=nil;row.label:ClearAllPoints();row.label:SetPoint("LEFT",row,"LEFT",3,0);row.label:SetWidth(width*.48);row.value:SetWidth(width*.45);row.value:SetText(FieldKit_L(d[2]));row.value:SetJustifyH("RIGHT")
    end
    row:SetValue(d[4] or (type(d[3])=="number" and d[3]) or 0)
    row:SetStatusBarColor(index==3 and .8 or .25,index==3 and .2 or .5,index==3 and .2 or .8,.55);row:Show()
   else row:Hide() end
  end
  T.Update(f)
  -- Keep fixture labels above the native card artwork after theme updates.
  for n=1,table.getn(f.sampleLines) do
   if n<=table.getn(rows) then f.sampleLines[n]:Show() end
  end
 end
 -- Sample label is inside every frame's bounds. It cannot be cropped offscreen.
 if P.mode=="inspect" then
  f:SetParent(P.inspector);f:SetClampedToScreen(false)
  f:ClearAllPoints();f:SetPoint("TOPLEFT",P.inspector,"TOPLEFT",12,-144)
  local scale=math.min(1,(P.inspector:GetWidth()-24)/f:GetWidth(),260/f:GetHeight())
  f:SetScale(scale)
 else
  f:SetScale(1)
  local group=P.Group(index);local parent=group and P.Root(group) or UIParent
  f:SetParent(parent);f:SetClampedToScreen(not group)
  if not f.moving and not parent.moving then
   f:ClearAllPoints()
   if group then
    local a,b,c,x,y=source:GetPoint(1)
    if b==group then f:SetPoint(a,parent,c,x,y) else f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0) end
   else
    local a,b,c,x,y=source:GetPoint(1)
    if a then f:SetPoint(a,b,c,x,y) else f:SetPoint("CENTER",UIParent,"CENTER",0,0) end
   end
  end
 end
 f:Show()
end

-- Compose selected grouped examples with their sample heights, including modules
-- disabled in the real HUD. Native grouping anchors and visibility stay intact.
function P.Stack(first,last,source)
 local root=source and P.roots[source:GetName()]
 if not root then return end
 local y,width=0,1
 for i=first,last do
  local f=P.frames[i]
  if P.included[i] and f and f:IsShown() then
   if not root.moving then f:ClearAllPoints();f:SetPoint("TOPLEFT",root,"TOPLEFT",0,-y) end
   y=y+f:GetHeight()+6;width=math.max(width,f:GetWidth())
  end
 end
 root:SetWidth(width);root:SetHeight(math.max(1,y-6))
end

function P.Refresh()
 if not P.mode then return end
 for i=1,table.getn(P.names) do
  if (P.all and i<P.playerIndex and P.included[i]) or (not P.all and i==P.selected) then P.Render(i)
  elseif P.frames[i] then P.frames[i]:Hide() end
 end
 if P.all then
  if FieldKitDB.linkLeftCards then P.Stack(1,4,FieldKitHudStack.root) end
  if FieldKitDB.linkRightCards then P.Stack(5,6,FieldKitCardLayout.root) end
 end
 FieldKitPreviewVisibility.Update()
 if P.inspector then
  local health=P.selected>=P.playerIndex
  FieldKit_Text(P.inspector.place,health and "Preview only" or "Place this window")
  FieldKit_Text(P.inspector.reset,health and "No position to reset" or P.Group(P.selected) and "Ungroup to reset" or "Reset this window position")
  if health then P.inspector.place:Disable() else P.inspector.place:Enable() end
  if health or P.Group(P.selected) then P.inspector.reset:Disable() else P.inspector.reset:Enable() end
  if P.inspector.help then
   FieldKit_Text(P.inspector.help,health and "Health preview only; drag the active player bar directly" or "Examples only. No combat data is recorded or shared.")
  end
 end
end

-- Stop is idempotent and also finishes a drag interrupted by Escape/Done.
function P.Stop()
 for _,f in pairs(P.frames) do
  if f.moving then P.Drag(f,false) end
  f:Hide()
 end
 for _,root in pairs(P.roots) do
  if root.moving then root:StopMovingOrSizing();root.moving=nil;P.Commit(root,root.source) end
 end
 P.mode=nil;P.all=nil;FieldKitPreviewVisibility.Clear()
 if P.inspector then
  P.inspector.choice.menu:Hide();P.inspector:StopMovingOrSizing();P.inspector:Hide()
 end
end

function P.Start(all)
 P.Stop();P.mode="place";P.all=all;P.Refresh()
end

function P.Reset()
 if P.Group(P.selected) then return end
 if P.selected>=P.playerIndex then return end
 local source=getglobal(P.names[P.selected]);local d=source and source.azsDefault
 if not d then return end
 FieldKitDB.frameAnchors[source:GetName()]=nil;FieldKitDB.pos[source:GetName()]={d[1],d[2]}
 if source==FieldKitMoneyFrame then FieldKitDB.moneyDetached=true end
 P.place(source);P.Refresh()
end

-- One reusable inspector, intentionally independent of module enable flags.
-- Closing it never changes a preference or closes the normal settings panel.
function P.Open(index)
 if FieldKit.layoutEditing then FieldKitUI.SetLayoutEditing(false,true) end
 P.Stop();P.selected=index or P.selected
 if not P.inspector then
  local f=CreateFrame("Frame","FieldKitPreviewInspector",UIParent);P.inspector=f
  f:SetWidth(440);f:SetHeight(510);f:SetFrameStrata("DIALOG");f:SetFrameLevel(125)
  f:SetMovable(true);f:SetClampedToScreen(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton");T.Surface(f,"window")
  f:SetScript("OnDragStart",function() f:StartMoving() end);f:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
  T.Label(f,"Preview — sample data",12,12,390,28,18,T.gold,true)
  f.help=T.Label(f,"Examples only. No combat data is recorded or shared.",12,43,410,32,12,T.muted)
  local x=CreateFrame("Button",nil,f,"UIPanelCloseButton");x:SetWidth(24);x:SetHeight(24);x:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4);x:SetScript("OnClick",P.Stop)
  f.choice=FieldKitUI.Choice(f,"FieldKitPreviewChoice","Test display",12,90,416,P.labels,function() return P.selected end,function(v) P.selected=v;if v<=table.getn(FieldKitCardLayout.names) then FieldKitCardLayout.selected=v;FieldKitUI.Refresh() end;P.Refresh() end,P.Refresh)
  f.include=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");f.include:SetWidth(24);f.include:SetHeight(24);f.include:SetPoint("TOPLEFT",f,"TOPLEFT",12,-414)
  T.Label(f,"Include in interface composition",42,414,380,24,12)
  f.include:SetScript("OnClick",function() if P.selected<P.playerIndex then P.included[P.selected]=this:GetChecked() and true or false else this:SetChecked(false) end end)
  f.place=T.Button(f,nil,"Place this window",12,448,202,26,function() if P.selected<P.playerIndex then FieldKitUI.SetLayoutEditing(true,false);P.Start(false) end end)
  f.reset=T.Button(f,nil,"Reset this window position",12,480,416,24,P.Reset)
  f.all=T.Button(f,nil,"Compose interface",226,448,202,26,function() FieldKitUI.SetLayoutEditing(true,false) end)
  local elapsed=0
  f:SetScript("OnUpdate",function() elapsed=elapsed+(arg1 or 0);if elapsed<.15 then return end;elapsed=0
   if P.mode=="inspect" then P.Refresh();f.choice.Refresh();f.include:SetChecked(P.included[P.selected]) end
  end)
  f:SetScript("OnHide",function() if P.mode=="inspect" then P.Stop() end end)
  if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"FieldKitPreviewInspector") end
 end
 local f=P.inspector
 f:ClearAllPoints();f:SetPoint("TOPLEFT",FieldKitUI.frame,"TOPRIGHT",8,0)
 f:SetScale(math.min(1,UIParent:GetWidth()/480,UIParent:GetHeight()/540));f:Show()
 P.mode="inspect";P.all=false;f.choice.Refresh();f.include:SetChecked(P.included[P.selected]);P.Refresh()
end
