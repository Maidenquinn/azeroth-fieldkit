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
 -- Schema ids remain stable when options are reordered or translated.
 local options={}
 for _,section in ipairs(sections) do
  for _,item in ipairs(section.items) do if item.id then options[item.id]=item end end
 end
 U.hudActions=actions
 options.meterFrame.label="Combat meter"
 U.nativeTextOptions={options.hideDamage,options.showCrits,options.groupCrits}
 local interface=old.Interface.items
 for i=1,table.getn(interface) do
  if interface[i].id=="compactBar" then
   interface[i].tip="Saved now. Use Reload UI below to apply the compact bar; your current run is not reloaded automatically."
  end
 end
 -- Chat deserves dedicated navigation rather than buried Preferences controls.
 local chatCopy,chatAppearance,chatColors,keep={},{},{},{}
 local copyKeys={["Enable local chat copy"]=true,["Show chat Copy button"]=true}
 local appearanceKeys={["Customize main chat"]=true,["Unlock chat position"]=true,
  ["Chat width"]=true,["Chat height"]=true,["Chat history lines"]=true}
 local colorKeys={["Chat font family"]=true,["Chat font size"]=true,
  ["Chat background color"]=true,["Chat background opacity"]=true,
  ["Override chat text colors"]=true,["Chat text color"]=true,
  ["Fade older chat lines"]=true}
 for _,item in ipairs(interface) do
  if copyKeys[item.label] then table.insert(chatCopy,item)
  elseif appearanceKeys[item.label] then table.insert(chatAppearance,item)
  elseif colorKeys[item.label] then table.insert(chatColors,item)
  else table.insert(keep,item) end
 end
 interface=keep
 table.insert(interface,{kind="camera"})
 table.insert(chatCopy,1,{kind="note",label="Local chat copy",tip="Capture new messages after opting in, then use the Copy button above chat or /fieldkitlog. Never uploads chat history."})
 table.insert(chatAppearance,1,{kind="note",label="Chat layout",tip="Unlock and drag the Move chat handle to any position. Lock it again to keep the saved layout."})
 table.insert(chatColors,1,{kind="note",label="Chat colors and typography",tip="Choose a font and a subtle background. Text overrides affect only NEW messages; leave off to preserve channel colors."})
 local cards={
  {kind="note",label="Which HUD cards to show",tip="Turn modules on or off here. Positions and sizes are under Layout & arrange."},
  {kind="check",label="Run mode card",tip="Native difficulty and zone with Difficulty-screen multipliers. Hover for the full chart.",
   get=function() return FieldKitDB.runModeCard end,set=function(v) FieldKitDB.runModeCard=v;actions.UpdateRunMode() end},
  {kind="check",label="Hide mode card without difficulty data",tip="Keep the HUD clear when the client does not supply the mode. Preview arrangement still shows the card.",
   get=function() return FieldKitDB.hideUnknownMode end,set=function(v) FieldKitDB.hideUnknownMode=v;actions.UpdateRunMode() end},
  options.statsFrame,
  {kind="check",label="Gold and chest price",tip="Show the separate gold and next-chest strip. Hiding it restores the native tally if FieldKit replaced it.",
   get=function() return FieldKitDB.moneyFrame end,set=function(v) FieldKitDB.moneyFrame=v;actions.SyncHudTally();actions.UpdateMoneyFrame() end},
  options.replaceTally,options.takenFrame,options.gearFrame,
  {kind="check",label="Effects tracker",tip="Contextual totems, summons and native talent timers. Hidden without relevant data; filters are in Health & buffs.",
   get=function() return FieldKitDB.effectsFrame end,set=function(v) FieldKitDB.effectsFrame=v;FieldKitNativeTools.Update() end},
  {kind="check",label="Next boss reminder",tip="Compact native arrival countdown, not a prediction of boss attacks. Hidden when no schedule is available.",
   get=function() return FieldKitDB.nextBossCard end,set=function(v) FieldKitDB.nextBossCard=v;FieldKitNativeTools.Update() end},
  {kind="check",label="Next boss in Lairs",tip="Show the next native scheduled boss and countdown in the lair card.",
   get=function() return FieldKitDB.lairNextBoss end,set=function(v) FieldKitDB.lairNextBoss=v;actions.UpdateLairFrame() end},
  {kind="check",label="Stored level-up reminder",tip="Show a count only while native stored level-ups are waiting. Does not open, spend or choose them.",
   get=function() return FieldKitDB.storedLevelsBadge end,set=function(v) FieldKitDB.storedLevelsBadge=v;FieldKitNativeTools.Update() end},
  {kind="check",label="Show received active affixes",tip="Display recognized names only when supplied by the client. Unknown formats stay labelled as raw data; no calendar guessing.",
   get=function() return FieldKitDB.showNativeAffixes end,set=function(v) FieldKitDB.showNativeAffixes=v;actions.UpdateRunMode() end},
  {kind="check",label="Group damage meter",tip="Native damage, DPS and contribution per player. Separate from your own spell breakdown. Missing group data is shown explicitly.",
   get=function() return FieldKitDB.partyMeter end,set=function(v) FieldKitDB.partyMeter=v;FieldKitCoop.Update() end},
 }
 local meter={
  {kind="note",label="Your combat meter",tip="Main meter, tabs, tooltips and optional detached windows. Which other HUD cards appear is under HUD cards."},
  options.meterFrame,
  {kind="choice",label="Local meter view",values={"Damage","Healing","Boss damage","Damage taken","Party DPS","Kills"},
   get=function()
    if FieldKitMeterSuite and FieldKitMeterSuite.View then local _,i=FieldKitMeterSuite.View();return i or 1 end
    return FieldKitMeters.Mode()
   end,
   set=function(v)
    local keys={"damage","healing","boss","taken","party","kills"}
    FieldKitDB.meterViewKey=keys[v] or "damage";FieldKitDB.meterView=math.min(v,3)
    if FieldKitPartyDetails then FieldKitPartyDetails.Close() end
    actions.UpdateMeterFrames(true)
   end},
  {kind="check",label="Meter tabs + reset",tip="Tabs for damage, healing, boss, taken, party and kills, with a mid-run Reset (native checkpoint when available).",
   get=function() return FieldKitDB.meterTabs~=false end,set=function(v) FieldKitDB.meterTabs=v and true or false;actions.UpdateMeterFrames(true) end},
  {kind="check",label="Spell hit tips on hover",tip="Show max hit/crit, hits, crit% and burst when hovering a meter row or an action-bar spell (Max Hit style).",
   get=function() return FieldKitDB.meterSpellTips~=false end,set=function(v) FieldKitDB.meterSpellTips=v and true or false end},
  {kind="choice",label="Damage meter values",values={"DPS + share","Damage + DPS","Damage + DPS + share"},
   get=function() return FieldKitDB.meterValues end,set=function(v) FieldKitDB.meterValues=v;actions.UpdateMeterFrames(true) end},
  {kind="check",label="Keep separate taken window",tip="Keep the classic Damage taken card visible even while the Taken tab or a detached Taken window is open.",
   get=function() return FieldKitDB.meterKeepTakenFrame and true or false end,set=function(v) FieldKitDB.meterKeepTakenFrame=v and true or false;actions.UpdateMeterFrames(true) end},
  {kind="check",label="Detach Damage window",tip="Open Damage in its own movable window. Right-click the Dmg tab does the same.",
   get=function() return FieldKitDB.meterDetach_damage and true or false end,
   set=function(v) if FieldKitMeterSuite then FieldKitMeterSuite.SetDetached("damage",v) else FieldKitDB.meterDetach_damage=v and true or nil;actions.UpdateMeterFrames(true) end end},
  {kind="check",label="Detach Healing window",tip="Open Healing in its own movable window.",
   get=function() return FieldKitDB.meterDetach_healing and true or false end,
   set=function(v) if FieldKitMeterSuite then FieldKitMeterSuite.SetDetached("healing",v) else FieldKitDB.meterDetach_healing=v and true or nil;actions.UpdateMeterFrames(true) end end},
  {kind="check",label="Detach Boss damage window",tip="Open Boss damage in its own movable window.",
   get=function() return FieldKitDB.meterDetach_boss and true or false end,
   set=function(v) if FieldKitMeterSuite then FieldKitMeterSuite.SetDetached("boss",v) else FieldKitDB.meterDetach_boss=v and true or nil;actions.UpdateMeterFrames(true) end end},
  {kind="check",label="Detach Damage taken window",tip="Open Damage taken in its own movable window.",
   get=function() return FieldKitDB.meterDetach_taken and true or false end,
   set=function(v) if FieldKitMeterSuite then FieldKitMeterSuite.SetDetached("taken",v) else FieldKitDB.meterDetach_taken=v and true or nil;actions.UpdateMeterFrames(true) end end},
  {kind="check",label="Detach Party DPS window",tip="Open Party DPS ranking in its own movable window.",
   get=function() return FieldKitDB.meterDetach_party and true or false end,
   set=function(v) if FieldKitMeterSuite then FieldKitMeterSuite.SetDetached("party",v) else FieldKitDB.meterDetach_party=v and true or nil;actions.UpdateMeterFrames(true) end end},
  {kind="check",label="Detach Kills window",tip="Open kills-per-spell in its own movable window.",
   get=function() return FieldKitDB.meterDetach_kills and true or false end,
   set=function(v) if FieldKitMeterSuite then FieldKitMeterSuite.SetDetached("kills",v) else FieldKitDB.meterDetach_kills=v and true or nil;actions.UpdateMeterFrames(true) end end},
 }
 local layout={
  {kind="preview",preview=0},
  {kind="note",label="Move and size your windows",tip="Drag windows in play by default. Use Arrange previews for hidden modules. Lock when the layout feels right."},
  {kind="check",label="Lock window positions",tip="Drag active windows during play by default. Locking keeps their current positions; grouping and dimensions stay unchanged.",
   get=function() return FieldKitDB.windowsLocked end,set=function(v) FieldKit.SetWindowsLocked(v) end},
  {kind="check",label="Align left HUD cards",tip="Move the left cards together. Turn off to move every card independently. Custom sizes are kept in both modes.",
   get=function() return FieldKitDB.linkLeftCards end,set=function(v) FieldKitDB.linkLeftCards=v;actions.UpdateHudStack() end},
  {kind="check",label="Group accessories and statistics",tip="Move the right cards together. Turn off to move each window independently.",
   get=function() return FieldKitDB.linkRightCards end,set=function(v) FieldKitDB.linkRightCards=v;FieldKitCardLayout.ApplyRight() end},
 }
 for _,item in ipairs(FieldKitCardLayout.Options()) do table.insert(layout,item) end
 local look={
  {kind="note",label="Visual style",tip="Chronicle look for FieldKit cards only. Does not change other addons."},
  {kind="choice",label="Card style",values={"Decorative","Classic"},get=function() return FieldKitDB.cardStyle end,
   set=function(v) FieldKitDB.cardStyle=v;T.Refresh() end},
  {kind="slider",label="Card background opacity",min=0,max=100,step=1,
   format=function(v) return FieldKit_L("Card background opacity")..": "..v.."%" end,
   get=function() return FieldKitDB.cardOpacity end,set=function(v) FieldKitDB.cardOpacity=v;T.Refresh() end},
  {kind="check",label="Keep pinned details above card choices",tip="Requires the recent native overlay API. Covers level-up and jewelry choices, not every modal.",
   get=function() return FieldKitDB.onTopWindows.FieldKitPartyDetailsFrame end,
   set=function(v) FieldKitDB.onTopWindows.FieldKitPartyDetailsFrame=v and true or nil;FieldKitScreenLayers.Update() end},
 }
 local health={{kind="preview",preview=18},options.playerBar,HealthChoice("playerHealthMode","Player health format",actions.UpdatePlayerBar),options.playerBuffs,options.playerShield,options.targetHealth,HealthChoice("targetHealthMode","Target health format",actions.UpdateTargetHealth)}
 for _,def in ipairs({{"effectTotems","Track totems"},{"effectSummons","Track summons"},{"effectTimers","Track native effect timers"}}) do
  local key,label=def[1],def[2]
  table.insert(health,{kind="check",label=label,tip="Filters the Effects tracker. Counts and remaining times come from the native API; unavailable data is never invented.",
   get=function() return FieldKitDB[key] end,set=function(v) FieldKitDB[key]=v;FieldKitNativeTools.Update() end})
 end
 local alerts=old.Warnings.items
 table.insert(alerts,1,{kind="preview",preview=16})
 for _,def in ipairs({{"nativeWarnings","Native mechanic warnings","Show filtered received boss/mechanic messages, with duplicates suppressed. The native banner display is unchanged."},
  {"bossBannerWarnings","Boss banner messages","Include received banners explicitly flagged as boss messages."},
  {"mechanicWarnings","Mechanic banner messages","Include received banners whose kind is mechanic."},
  {"partyBannerWarnings","Party revive banners","Include co-op downed / friend-down / revived banners."},
  {"nextBossAlert","Warn before the next boss","One warning before each observed arrival. Based on native scheduling; no attack prediction."}}) do
  local key,label,tip=def[1],def[2],def[3]
  table.insert(alerts,{kind="check",label=label,tip=tip,get=function() return FieldKitDB[key] end,
   set=function(v) FieldKitDB[key]=v;FieldKitNativeTools.Update() end})
 end
 table.insert(alerts,{kind="slider",label="Boss arrival warning",min=3,max=30,step=1,
  get=function() return FieldKitDB.bossWarningLead end,format=function(v) return string.format(FieldKit_L("Warn %ds before a boss"),v) end,
  set=function(v) FieldKitDB.bossWarningLead=v end})
 table.insert(old.Map.items,{kind="check",label="Highlight the flagged lair",tip="Mark the lair selected by the game's flag in the existing lair list. Does not track a moving guardian.",
  get=function() return FieldKitDB.highlightFlaggedLair end,set=function(v) FieldKitDB.highlightFlaggedLair=v;actions.UpdateLairFrame() end})
 local coop={
  {kind="preview",preview=8},
  {kind="note",label="Experimental co-op",tip="Full allied spell sharing depends on a client transport that has not been confirmed in live co-op. Native group totals remain available without sharing."},
  {kind="check",label="Co-op teammate cards",tip="Optional passive cards. Native teammate frames remain available for targeting and their usual interactions.",
   get=function() return FieldKitDB.partyCards end,set=function(v) FieldKitDB.partyCards=v;FieldKitCoop.Update() end},
  HealthChoice("partyHealthMode","Teammate health format",FieldKitCoop.Update),
  {kind="check",label="Co-op revive progress",tip="Show native local revive progress and the ally involved. Original revive HUD stays available; no automatic actions.",
   get=function() return FieldKitDB.reviveFrame end,set=function(v) FieldKitDB.reviveFrame=v;FieldKitNativeTools.Update() end},
  {kind="check",label="Hide native teammate frames",tip="Advanced: hide originals only while a card has valid health. Field cards do not provide native targeting, menus or buff interactions. Turn off to restore originals.",
   get=function() return FieldKitDB.replacePartyFrames end,set=function(v) FieldKitDB.replacePartyFrames=v;FieldKitCoop.Update() end},
  {kind="check",label="Share spell breakdowns with group",tip="Optional in-game PARTY addon messages. Both players need FieldKit and this option. Shares only your own spell damage/DPS on request. Client transport is not confirmed; use /fieldkit sync to check received snapshots.",
   get=function() return FieldKitDB.partyDetailSync end,set=function(v) FieldKitDB.partyDetailSync=v;FieldKitPartySync.Watch();FieldKitCoop.Update() end},
  {kind="syncStatus"},
 }
 return {
  {id="home",title="Overview",glyph=13,group="01  HOME",items={{kind="home"}}},
  {id="combat",title="Combat text",glyph=2,group="02  COMBAT",items={{kind="combat"}}},
  {id="health",title="Health & buffs",glyph=16,group="02  COMBAT",items=health},
  {id="bosses",title="Bosses",glyph=5,group="02  COMBAT",items={{kind="preview",preview=17},options.bossFrame,
   {kind="check",label="Boss schedule timeline",tip="Chronicle bar under the top of the screen with upcoming boss markers. Hides the native run clock while shown. Off by default.",
    get=function() return FieldKitDB.bossTimeline==true end,
    set=function(v) FieldKitDB.bossTimeline=v and true or false;if FieldKitBossTimeline then FieldKitBossTimeline.Update() end;if not v and FieldKitBossTimeline then FieldKitBossTimeline.RestoreHud() end end},
   {kind="choice",label="Boss frame appearance",values={"Chronicle classic","Compact","Chronicle Premium"},
    get=function()
     if FieldKitDB.bossStyle=="compact" then return 2 end
     if FieldKitDB.bossStyle=="premium" then return 3 end
     return 1
    end,
    set=function(v)
     FieldKitDB.bossStyle=(v==2 and "compact") or (v==3 and "premium") or "classic"
     actions.UpdateBossFrame()
    end},
   HealthChoice("bossHealthMode","Boss health format",actions.UpdateBossFrame)}},
  {id="alerts",title="Alerts",glyph=12,group="02  COMBAT",items=alerts},
  {id="cards",title="HUD cards",glyph=9,group="03  INTERFACE",items=cards},
  {id="meter",title="Combat meter",group="03  INTERFACE",glyph=8,items=meter},
  {id="layout",title="Layout & arrange",group="03  INTERFACE",glyph=14,items=layout},
  {id="look",title="Look",group="03  INTERFACE",glyph=4,items=look},
  {id="profiles",title="Profiles",group="03  INTERFACE",glyph=14,items={{kind="profiles"}}},
  {id="worldmarkers",title="World markers",glyph=6,group="04  WORLD",items={{kind="worldmarkers"}}},
  {id="map",title="Minimap",glyph=1,group="04  WORLD",items=old.Map.items},
  {id="nameplates",title="Nameplates",glyph=7,group="04  WORLD",items=old.Nameplates.items},
  {id="coop",title="Group & co-op",glyph=15,group="05  MULTIPLAYER",items=coop},
  {id="chat",title="Chat layout",glyph=11,group="06  CHAT",items=chatAppearance},
  {id="chatcolors",title="Chat colors & fonts",glyph=4,group="06  CHAT",items=chatColors},
  {id="chatcopy",title="Chat copy",glyph=12,group="06  CHAT",items=chatCopy},
  {id="interface",title="Preferences",glyph=11,group="07  PREFERENCES",items=interface},
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
 if item.button then action=T.Button(row,nil,item.button.text,0,1,132,26,item.button.onClick) end
 check.item=item;check.Refresh=function() check:SetChecked(item.get() and true or false) end
 check:SetScript("OnClick",function() item.set(this:GetChecked() and true or false);U.Refresh() end)
 check:SetScript("OnEnter",function() U.Tip(this,item.label,item.tip) end);check:SetScript("OnLeave",function() GameTooltip:Hide() end)
 row.Reflow=function(w)
  row:SetWidth(w);label:SetWidth(w-32-(action and 144 or 0));detail:SetWidth(w-32)
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
 s.item=item;s.label=item.label
 s:SetMinMaxValues(item.min or 15,item.max or 50);s:SetValueStep(item.step or 1)
 s.Refresh=function()
  local minimum=item.minimum and item.minimum() or item.min or 15
  s:SetMinMaxValues(minimum,item.max or 50)
  local minimumLabel=getglobal(name.."Low");if minimumLabel then minimumLabel:SetText(minimum) end
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

-- World marker gallery: category tabs, real texture preview and live saved settings.
local function BuildMarkerGallery(page,y)
 local M=FieldKitWorldMarkers
 local kinds={"boss","finalBoss","guardian","elite","cache","guardianLair","downedPartyMember"}
 local names={"Boss","Final boss","Guardian","Elite","Treasure","Spawn","Revive"}
 local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(720)
 local hint=T.Label(row,FieldKit_L("Choose an icon to preview and configure. Changes apply immediately."),0,0,560,38,13,T.muted)
 local tabs={};local selected="boss"
 local preview=CreateFrame("Frame",nil,row);preview:SetPoint("TOPLEFT",row,"TOPLEFT",8,-96);preview:SetWidth(156);preview:SetHeight(156)
 T.Surface(preview,"card")
 local aura=preview:CreateTexture(nil,"ARTWORK");aura:SetTexture(M.GetAuraTexture());aura:SetBlendMode("ADD");aura:SetPoint("CENTER",preview,"CENTER",0,0)
 local icon=preview:CreateTexture(nil,"OVERLAY");icon:SetPoint("CENTER",preview,"CENTER",0,0);icon:SetWidth(88);icon:SetHeight(88)
 local name=T.Label(row,"",182,112,330,32,19,T.gold,true)
 local info=T.Label(row,FieldKit_L("Preview uses the exact installed texture."),182,149,320,52,12,T.muted)
 local toggle=T.Button(row,nil,"",182,208,160,29,function()
  M.SetCategoryEnabled(selected,not M.GetCategoryEnabled(selected));row.Refresh()
 end)
 local sizeLabel=T.Label(row,FieldKit_L("Icon size"),0,278,500,24,14,T.gold)
 local sliderName="FieldKitMarkerScaleSlider"
 local slider=CreateFrame("Slider",sliderName,row,"OptionsSliderTemplate");slider:SetPoint("TOPLEFT",row,"TOPLEFT",8,-319);slider:SetHeight(18);slider:SetMinMaxValues(60,150);slider:SetValueStep(5)
 local low=getglobal(sliderName.."Low");if low then low:SetText("60%") end
 local high=getglobal(sliderName.."High");if high then high:SetText("150%") end
 local title=getglobal(sliderName.."Text");if title then title:Hide() end
 local lock=false
 slider:SetScript("OnValueChanged",function()
  if lock then return end
  M.SetCategoryScale(selected,math.floor(this:GetValue()/5+0.5)*5);row.Refresh()
 end)
 local rangeLabel=T.Label(row,"",0,365,500,24,14,T.gold)
 local rangeName="FieldKitMarkerRangeSlider"
 local rangeSlider=CreateFrame("Slider",rangeName,row,"OptionsSliderTemplate")
 rangeSlider:SetPoint("TOPLEFT",row,"TOPLEFT",8,-406)
 rangeSlider:SetHeight(18);rangeSlider:SetMinMaxValues(10,250);rangeSlider:SetValueStep(5)
 local rangeLow=getglobal(rangeName.."Low");if rangeLow then rangeLow:SetText("10 yd") end
 local rangeHigh=getglobal(rangeName.."High");if rangeHigh then rangeHigh:SetText("250 yd") end
 local rangeTitle=getglobal(rangeName.."Text");if rangeTitle then rangeTitle:Hide() end
 rangeSlider:SetScript("OnValueChanged",function()
  if lock then return end
  M.SetCategoryRange(selected,math.floor(this:GetValue()/5+0.5)*5);row.Refresh()
 end)
 local auraButton=T.Button(row,nil,"",0,456,166,30,function() M.SetAura(not M.GetAura());row.Refresh() end)
 local pulseButton=T.Button(row,nil,"",178,456,166,30,function() M.SetAuraPulse(not M.GetAuraPulse());row.Refresh() end)
 local intensity=T.Label(row,FieldKit_L("Aura intensity"),0,506,500,24,14,T.gold)
 local auraName="FieldKitMarkerAuraSlider"
 local auraSlider=CreateFrame("Slider",auraName,row,"OptionsSliderTemplate");auraSlider:SetPoint("TOPLEFT",row,"TOPLEFT",8,-549);auraSlider:SetHeight(18);auraSlider:SetMinMaxValues(0,100);auraSlider:SetValueStep(5)
 local lo=getglobal(auraName.."Low");if lo then lo:SetText("0%") end
 local hi=getglobal(auraName.."High");if hi then hi:SetText("100%") end
 local tx=getglobal(auraName.."Text");if tx then tx:Hide() end
 auraSlider:SetScript("OnValueChanged",function()
  if lock then return end
  M.SetAuraIntensity(math.floor(this:GetValue()/5+0.5)*5/100);row.Refresh()
 end)
 local reviveName=T.Button(row,nil,"",0,642,166,30,function() M.SetReviveNames(not M.GetReviveNames());row.Refresh() end)
 local reviveDistance=T.Button(row,nil,"",178,642,166,30,function() M.SetReviveDistance(not M.GetReviveDistance());row.Refresh() end)
 local enable=T.Button(row,nil,"",0,600,166,30,function() if M.IsEnabled() then M.Disable() else M.Enable() end;row.Refresh() end)
 local hints=T.Button(row,nil,"",178,600,166,30,function() M.SetLairHints(not M.GetLairHints());row.Refresh() end)
 FieldKit_RefreshLanguage(function()
  for i=1,table.getn(tabs) do if tabs[i] then FieldKit_Text(tabs[i],names[i]) end end
  FieldKit_Text(hint,"Choose an icon to preview and configure. Changes apply immediately.")
  if row:IsVisible() then row.Refresh() end
 end)
 function row.Refresh()
  lock=true
  for i=1,table.getn(kinds) do T.State(tabs[i],kinds[i]==selected) end
  icon:SetTexture(M.GetTexture(selected));icon:SetWidth(88*M.GetCategoryScale(selected)/100);icon:SetHeight(88*M.GetCategoryScale(selected)/100)
  aura:SetWidth(142*M.GetCategoryScale(selected)/100);aura:SetHeight(142*M.GetCategoryScale(selected)/100)
  if M.GetAura() then aura:SetVertexColor(0.85,0.6,1,M.GetAuraIntensity());aura:Show() else aura:Hide() end
  FieldKit_Text(name,names[({boss=1,finalBoss=2,guardian=3,elite=4,cache=5,guardianLair=6,downedPartyMember=7})[selected]])
  if selected=="guardianLair" then info:SetText(FieldKit_L("Spawn hints show a tooltip when you hover the world marker. They do not predict future spawns.")) else info:SetText(FieldKit_L("Preview uses the exact installed texture.")) end
  FieldKit_Text(toggle,M.GetCategoryEnabled(selected) and "Show marker: yes" or "Show marker: no")
  FieldKit_Text(auraButton,M.GetAura() and "Aura: on" or "Aura: off")
  FieldKit_Text(pulseButton,M.GetAuraPulse() and "Pulse: on" or "Pulse: off")
  FieldKit_Text(enable,M.IsEnabled() and "Engine: on" or "Engine: off")
  FieldKit_Text(hints,M.GetLairHints() and "Spawn hints: on" or "Spawn hints: off")
  if selected=="guardianLair" then hints:Show() else hints:Hide() end
  if selected=="downedPartyMember" then
   reviveName:Show();reviveDistance:Show()
   FieldKit_Text(reviveName,M.GetReviveNames() and "Ally name: on" or "Ally name: off")
   FieldKit_Text(reviveDistance,M.GetReviveDistance() and "Distance: on" or "Distance: off")
  else reviveName:Hide();reviveDistance:Hide() end
  FieldKit_Text(rangeLabel,"Marker visibility range: "..M.GetCategoryRange(selected).." yd")
  rangeSlider:SetValue(M.GetCategoryRange(selected))
  FieldKit_Text(sizeLabel,"Icon size: "..M.GetCategoryScale(selected).."%")
  FieldKit_Text(intensity,"Aura intensity: "..math.floor(M.GetAuraIntensity()*100+0.5).."%")
  slider:SetValue(M.GetCategoryScale(selected));auraSlider:SetValue(M.GetAuraIntensity()*100)
  lock=false
 end
 for i=1,table.getn(kinds) do
  local k=kinds[i]
  tabs[i]=T.Button(row,nil,names[i],0,49,88,29,function() selected=k;row.Refresh() end)
 end
 row.Reflow=function(w)
  row:SetWidth(w);hint:SetWidth(w)
  local tw=(w-10)/4
  for i=1,table.getn(tabs) do
   local b=tabs[i];b:ClearAllPoints();b:SetPoint("TOPLEFT",row,"TOPLEFT",math.mod(i-1,4)*(tw+4),-45-math.floor((i-1)/4)*34)
   b:SetWidth(tw);b.fieldkitLabel:SetWidth(tw-8);T.Update(b)
  end
  slider:SetWidth(w-20);rangeSlider:SetWidth(w-20);auraSlider:SetWidth(w-20)
 end
 row.Refresh();table.insert(page.flow,{frame=row,y=y});return y+730
end

-- Active profile highlight: gold borders resize with their owning frame
-- and do not capture mouse input or create textures on each switch.
local function ProfileActiveBorder(frame)
 local strips={}
 local glow=frame:CreateTexture(nil,"BACKGROUND")
 glow:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-2)
 glow:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
 glow:SetTexture(T.bronze[1],T.bronze[2],T.bronze[3])
 glow:SetAlpha(.22)
 glow:Hide()
 local anchors={
  {"TOPLEFT","TOPRIGHT"},
  {"BOTTOMLEFT","BOTTOMRIGHT"},
  {"TOPLEFT","BOTTOMLEFT"},
  {"TOPRIGHT","BOTTOMRIGHT"},
 }
 for i=1,4 do
  local t=frame:CreateTexture(nil,"OVERLAY")
  t:SetTexture(T.gold[1],T.gold[2],T.gold[3])
  local c=anchors[i]
  t:SetPoint(c[1],frame,c[1],0,0)
  t:SetPoint(c[2],frame,c[2],0,0)
  if i<=2 then t:SetHeight(2) else t:SetWidth(2) end
  t:Hide()
  strips[i]=t
 end
 return function(active)
  if active then glow:Show() else glow:Hide() end
  for i=1,4 do if active then strips[i]:Show() else strips[i]:Hide() end end
 end
end

-- Three-slot HUD profile manager. Updates text only; only explicit button
-- clicks can save, queue, cancel or delete. Confirm overwrites and deletions.
local function BuildProfileManager(page,y)
 local P=FieldKitProfiles
 local row=CreateFrame("Frame",nil,page)
 row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y)
 row:SetWidth(610);row:SetHeight(636)
 local intro=T.Label(row,"Save all FieldKit preferences per profile, including chat. Game stats and message history stay shared.",0,0,600,38,13,T.muted)
 local pending=T.Label(row,"",0,42,600,25,13,T.gold)
 local cancel=T.Button(row,nil,"Undo last switch",0,74,210,29,function()
  P.Undo();row.Refresh();U.Refresh()
 end)
 local slots={}
 for i=1,3 do
  local idx=i
  local card=CreateFrame("Frame",nil,row)
  card:SetPoint("TOPLEFT",row,"TOPLEFT",0,-(120+(i-1)*152))
  card:SetHeight(144);card:SetWidth(600);T.Surface(card,"card")
  local label=T.Label(card,"Profile "..i,14,8,530,27,18,T.gold,true)
  local summary=T.Label(card,"",14,35,530,29,12,T.muted)
  local activeTag=T.Label(card,"",420,8,163,24,13,T.green,true)
  local showActiveBorder=ProfileActiveBorder(card)
  -- Native InputBoxTemplate on this Benilla build creates shared visual
  -- regions for anonymous EditBoxes. The decoration of slot 2/3 can show
  -- up on slot 1. Use one fully-owned, untemplated EditBox per card instead.
  local editor=CreateFrame("Frame",nil,card)
  editor:SetPoint("TOPLEFT",card,"TOPLEFT",14,-36)
  editor:SetWidth(305);editor:SetHeight(30)
  T.Surface(editor,"button")
  local edit=CreateFrame("EditBox",nil,editor)
  edit:SetPoint("TOPLEFT",editor,"TOPLEFT",10,-4)
  edit:SetWidth(285);edit:SetHeight(22)
  edit:SetFont("Fonts\\FRIZQT__.TTF",14,"")
  edit:SetTextColor(T.text[1],T.text[2],T.text[3])
  edit:SetAutoFocus(false);edit:SetMaxLetters(40)
  editor:Hide()
  local hint=T.Label(card,"",314,38,268,27,12,T.muted)
  hint:Hide()
  local rename=T.Button(card,nil,"Rename",474,80,112,29,function()
   if not FieldKitDB.interfaceProfiles[idx] then return end
   row.CloseEditors(idx)
   edit:SetText(P.Name(idx) or "")
   row.editing=idx
   row.Refresh()
   edit:SetFocus()
  end)
  local commit=T.Button(card,nil,"Save name",14,80,148,29,function()
   if P.Rename(idx,edit:GetText()) then
    row.editing=nil
    edit:ClearFocus()
    row.Refresh();U.Refresh()
   else FieldKit_Text(hint,"Invalid name (1–40 bytes).") end
  end)
  local abort=T.Button(card,nil,"Cancel",174,80,148,29,function()
   row.editing=nil
   edit:ClearFocus()
   row.Refresh()
  end)
  edit:SetScript("OnEnterPressed",function() commit.callback() end)
  edit:SetScript("OnEscapePressed",function() abort.callback() end)
  local save=T.Button(card,nil,"Save current HUD",14,80,155,29,function()
   if FieldKitDB.interfaceProfiles[idx] and row.confirmSave~=idx then
    row.confirmSave=idx;row.confirmDelete=nil
   else P.Save(idx);row.confirmSave=nil end
   row.Refresh()
  end)
  local loadButton=T.Button(card,nil,"Apply now",179,80,160,29,function()
   P.Load(idx);row.confirmDelete=nil;row.confirmSave=nil;row.Refresh();U.Refresh()
  end)
  local del=T.Button(card,nil,"Delete",349,80,120,29,function()
   if row.confirmDelete==idx then
    P.Delete(idx);row.confirmDelete=nil
   else row.confirmDelete=idx;row.confirmSave=nil end
   row.Refresh()
  end)
  slots[i]={frame=card,label=label,summary=summary,activeTag=activeTag,showActiveBorder=showActiveBorder,save=save,loadButton=loadButton,delete=del,rename=rename,editor=editor,edit=edit,hint=hint,commit=commit,abort=abort}
 end
 function row.Refresh()
  local d=FieldKitDB
  if not d then return end
  local active=d.activeHudProfile
  FieldKit_Text(pending,active and string.format(FieldKit_L("Active profile: %d"),active) or "No active profile.")
  FieldKit_Text(cancel,"Undo last switch")
  if P.undo then cancel:Show() else cancel:Hide() end
  for i=1,3 do
   local item=slots[i]
   local saved=d.interfaceProfiles and d.interfaceProfiles[i]
   local values=saved and saved.values or nil
   local anchors=saved and saved.tables and saved.tables.frameAnchors
   local count=0
   if type(anchors)=="table" then for _ in pairs(anchors) do count=count+1 end end
   FieldKit_Text(item.label,P.Name(i) or string.format(FieldKit_L("Profile %d"),i))
   FieldKit_Text(item.activeTag,"✓ "..FieldKit_L("Current"))
   local selected=active==i and saved~=nil
   item.showActiveBorder(selected)
   if selected then item.activeTag:Show() else item.activeTag:Hide() end
   if saved then
    FieldKit_Text(item.summary,string.format(FieldKit_L("Saved · %d positions · opacity %d%%"),count,(values and values.cardOpacity) or 100))
   else FieldKit_Text(item.summary,"Empty slot — save your current HUD to start.") end
   FieldKit_Text(item.save,row.confirmSave==i and "Confirm overwrite" or "Save current HUD")
   FieldKit_Text(item.loadButton,active==i and "Active" or "Apply now")
   FieldKit_Text(item.delete,row.confirmDelete==i and "Confirm delete" or "Delete")
   FieldKit_Text(item.rename,"Rename")
   if saved and row.editing==i then
    item.summary:Hide();item.editor:Show();item.hint:Show()
    FieldKit_Text(item.hint,"Enter to save · Esc to cancel")
    item.save:Hide();item.loadButton:Hide();item.delete:Hide();item.rename:Hide()
    item.commit:Show();item.abort:Show()
   else
    item.summary:Show();item.editor:Hide();item.hint:Hide()
    item.commit:Hide();item.abort:Hide();item.save:Show()
    if saved then item.loadButton:Show();item.delete:Show();item.rename:Show()
    else item.loadButton:Hide();item.delete:Hide();item.rename:Hide() end
   end
  end
 end
 row.Reflow=function(w)
  row:SetWidth(w);intro:SetWidth(w-12);pending:SetWidth(w-12)
  local cw=w-6
  for i=1,3 do
   local item=slots[i];item.frame:SetWidth(cw);T.Update(item.frame)
   item.label:SetWidth(cw-198);item.summary:SetWidth(cw-24)
   item.activeTag:ClearAllPoints()
   item.activeTag:SetPoint("TOPRIGHT",item.frame,"TOPRIGHT",-14,-8)
   item.activeTag:SetWidth(160)
   local bw=(cw-70)/4
   for j,b in ipairs({item.save,item.loadButton,item.delete,item.rename}) do
    b:ClearAllPoints();b:SetPoint("TOPLEFT",item.frame,"TOPLEFT",14+(j-1)*(bw+12),-80)
    b:SetWidth(bw);b.fieldkitLabel:SetWidth(bw-18);T.Update(b)
   end
   -- Reserve actual space between editor shell and hint. Native glyph
   -- rendering can overrun a Frame edge even when nominal anchors differ.
   local editW=math.min(250,cw*.42)
   item.editor:SetWidth(editW+20);item.edit:SetWidth(editW)
   T.Update(item.editor)
   local hintX=14+editW+20+28
   item.hint:ClearAllPoints()
   item.hint:SetPoint("TOPLEFT",item.frame,"TOPLEFT",hintX,-42)
   item.hint:SetWidth(math.max(110,cw-hintX-18))
   local actionW=math.min(148,(cw-42)/2)
   item.commit:SetWidth(actionW);item.abort:SetWidth(actionW)
   item.abort:ClearAllPoints()
   item.abort:SetPoint("TOPLEFT",item.frame,"TOPLEFT",26+actionW,-80)
   item.commit.fieldkitLabel:SetWidth(actionW-18)
   item.abort.fieldkitLabel:SetWidth(actionW-18)
   T.Update(item.commit);T.Update(item.abort)
  end
 end
 function row.CloseEditors(except)
  if row.editing and row.editing~=except then
   slots[row.editing].edit:ClearFocus()
   row.editing=nil
  end
 end
 row.slots=slots;row.cancel=cancel;row.Refresh()
 U.profileView=row
 table.insert(page.flow,{frame=row,y=y})
 return y+644
end

-- A small visibility preset only. Existing geometry/style and other addons are
-- untouched; its in-memory Undo lasts until reload and is never auto-applied.
function U.EssentialHud(undo)
 local keys={statsFrame=false,gearFrame=false,runModeCard=false,takenFrame=false,meterFrame=true,moneyFrame=true,lairFrame=true,partyMeter=true}
 if undo then keys=U.previousHud;if not keys then return end;U.previousHud=nil
 else
  if not U.previousHud then
   U.previousHud={};for key in pairs(keys) do U.previousHud[key]=FieldKitDB[key] end
  end
 end
 for key,value in pairs(keys) do FieldKitDB[key]=value end
 local a=U.hudActions
 a.UpdateStatsFrame();a.UpdateGearFrame();a.UpdateRunMode();a.SyncHudTally();a.UpdateMoneyFrame();a.UpdateMeterFrames(true);a.UpdateLairFrame();FieldKitCoop.Update()
 U.Refresh()
end

-- Small cards lead to the relevant page; no implicit presets/native changes.
local function BuildHome(page)
 page.intro=T.Label(page,"Choose a feature to customize. Your settings are saved.",0,48,650,48,14,T.muted)
 FieldKit_Text(page.intro,"Choose a feature to customize. Your settings are saved.")
 local defs={{"Combat text","Choose which damage and healing messages appear.",2,"combat","combatText"},
  {"Health and buffs","Health bars, shields and buffs.",16,"health","playerBar"},
  {"Tracked bosses","Portraits, health bars and timeline.",5,"bosses","bossFrame"},
  {"World markers","Chests, bosses, runes and revives.",6,"worldmarkers","worldMarkersEnabled"}}
 for i=1,4 do
  local d=defs[i];local c=CreateFrame("Frame",nil,page);c:SetHeight(142);T.Surface(c,"card")
  T.Glyph(c,d[3],14,16,32)
  c.title=T.Label(c,d[1],58,14,230,28,18,T.gold,true);FieldKit_Text(c.title,d[1])
  c.state=T.Label(c,"",58,45,230,20,12,T.muted)
  c.detail=T.Label(c,d[2],16,72,280,38,12,T.muted);FieldKit_Text(c.detail,d[2])
  c.open=T.Button(c,nil,"Configure",16,110,260,25,function() U.Select(d[4]) end);FieldKit_Text(c.open,"Configure")
  c.key=d[5];table.insert(U.homeCards,c)
 end
 page.layoutCard=CreateFrame("Frame",nil,page);page.layoutCard:SetHeight(96);T.Surface(page.layoutCard,"card")
 page.layoutTitle=T.Label(page.layoutCard,"Arrange your HUD",16,12,400,26,19,T.gold,true);FieldKit_Text(page.layoutTitle,"Arrange your HUD")
 page.layoutHint=T.Label(page.layoutCard,"Drag active windows directly. Arrange hidden previews and combat areas here.",16,44,400,38,12,T.muted);FieldKit_Text(page.layoutHint,"Drag active windows directly. Arrange hidden previews and combat areas here.")
 page.layoutAction=T.Button(page.layoutCard,nil,"Arrange previews",0,32,164,30,function() U.SetLayoutEditing(true,false) end);FieldKit_Text(page.layoutAction,"Arrange previews")
 page.presetHint=T.Label(page,"Essential HUD: damage, lairs, gold and group totals. Other addons are unchanged.",0,540,650,46,12,T.muted);FieldKit_Text(page.presetHint,"Essential HUD: damage, lairs, gold and group totals. Other addons are unchanged.")
 page.essential=T.Button(page,nil,"Use essential HUD",0,594,190,30,function() U.EssentialHud(false) end);FieldKit_Text(page.essential,"Use essential HUD")
 page.undoPreset=T.Button(page,nil,"Undo HUD preset",202,594,190,30,function() U.EssentialHud(true) end);FieldKit_Text(page.undoPreset,"Undo HUD preset")
 U.presetUndo=page.undoPreset
 page.quickTitle=T.Label(page,"Quick profiles",0,654,380,27,19,T.gold,true)
 page.quickHint=T.Label(page,"Switch complete FieldKit settings instantly. Empty slots open the profile manager.",0,684,600,24,12,T.muted)
 page.quickActiveFrame=CreateFrame("Frame",nil,page)
 page.quickActiveFrame:SetPoint("TOPLEFT",page,"TOPLEFT",0,-755)
 page.quickActiveFrame:SetWidth(620);page.quickActiveFrame:SetHeight(42)
 T.Surface(page.quickActiveFrame,"button")
 page.quickActiveBorder=ProfileActiveBorder(page.quickActiveFrame)
 page.quickActive=T.Label(page.quickActiveFrame,"",12,10,592,22,13,T.gold,true)
 page.quickButtons={}
 for i=1,3 do
  local slot=i
  page.quickButtons[i]=T.Button(page,nil,"",0,719,152,31,function()
   if FieldKitDB.interfaceProfiles and FieldKitDB.interfaceProfiles[slot] then
    FieldKitProfiles.Load(slot);U.Refresh()
   else U.Select("profiles") end
  end)
 end
 U.quickProfileButtons=page.quickButtons
 U.quickProfileActive=page.quickActive
 U.quickProfileActiveFrame=page.quickActiveFrame
 U.quickProfileActiveBorder=page.quickActiveBorder
 page.contentHeight=805
end

-- Each window subpage has its own content height and stable saved id. Reading a
-- page never applies preferences; only its visible controls are interactive.
function U.SelectWindowTab(page,id)
 local selected=page.windowTabs[1]
 for _,tab in ipairs(page.windowTabs) do if tab.id==id then selected=tab end end
 FieldKitDB.windowPage=selected.id;page.windowSelected=selected.id
 for _,tab in ipairs(page.windowTabs) do T.State(tab.button,tab==selected) end
 for _,entry in ipairs(page.flow) do
  if entry.windowTab==selected.id then entry.frame:Show() else entry.frame:Hide() end
 end
 page.contentHeight=selected.height;page:SetHeight(math.max(page.contentHeight,page.scroll:GetHeight()))
 if page.scroll.SetVerticalScroll then page.scroll:SetVerticalScroll(0) end
 U.CloseMenus()
end

-- Every page owns a scroll viewport, so smaller screens retain full-size text.
function U.BuildPage(section,index)
 local scroll=CreateFrame("ScrollFrame","FieldKitJourneyScroll"..index,U.frame,"UIPanelScrollFrameTemplate")
 local page=CreateFrame("Frame","FieldKitPanelPage"..index,scroll);page:SetWidth(700);page.flow={};page.section=section
 scroll:SetScrollChild(page);page.scroll=scroll;U.Wheel(scroll,page)
 page.heading=T.Label(page,section.title,0,0,640,36,26,T.gold,true);FieldKit_Text(page.heading,section.title)
 local y=56
 local items=section.items
 if section.windowTabs then
  items={};page.windowTabs=section.windowTabs;U.windowPage=page
  for _,tab in ipairs(page.windowTabs) do
   local tabId=tab.id
   tab.button=T.Button(page,nil,tab.title,0,50,120,32,function() U.SelectWindowTab(page,tabId) end)
   for _,item in ipairs(tab.items) do item.windowTab=tab.id;table.insert(items,item) end
  end
 end
 local previous
 for i=1,table.getn(items) do
  local item=items[i];local before=table.getn(page.flow)
  if section.windowTabs and previous~=item.windowTab then y=104;previous=item.windowTab end
  if item.kind=="home" then BuildHome(page);y=page.contentHeight
  elseif item.kind=="preview" then
   local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(76)
   local hint=T.Label(row,"Test without a party, boss or active module.",0,0,500,26,12,T.muted)
   local example=T.Button(row,nil,"Test display",0,32,190,28,function() FieldKitPreview.Open(item.preview>0 and item.preview or FieldKitCardLayout.selected) end)
   local compose=T.Button(row,nil,"Compose interface",202,32,190,28,function() U.SetLayoutEditing(true,false) end)
   row.Reflow=function(w) row:SetWidth(w);hint:SetWidth(w) end
   table.insert(page.flow,{frame=row,y=y});y=y+84
  elseif item.kind=="note" or item.kind=="syncStatus" then
   local row=CreateFrame("Frame",nil,page);row:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y);row:SetHeight(104)
   local label=T.Label(row,item.label or "Sharing status",0,0,500,24,15,T.gold,true)
   local detail=T.Label(row,item.tip or "",0,30,500,68,12,T.muted)
   row.Reflow=function(w) row:SetWidth(w);label:SetWidth(w);detail:SetWidth(w) end
   if item.kind=="syncStatus" then U.syncStatus=detail end
   table.insert(page.flow,{frame=row,y=y});y=y+110
  elseif item.kind=="combat" then FieldKit_CreateCombatOptions(page);y=570
  elseif item.kind=="worldmarkers" then y=BuildMarkerGallery(page,y)
  elseif item.kind=="profiles" then y=BuildProfileManager(page,y)
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
  if section.windowTabs then
   for j=before+1,table.getn(page.flow) do page.flow[j].windowTab=item.windowTab end
   for _,tab in ipairs(page.windowTabs) do if tab.id==item.windowTab then tab.height=y+16 end end
  end
 end
 page.contentHeight=y+48;U.pages[index]=page
 if section.windowTabs then U.SelectWindowTab(page,FieldKitDB.windowPage) end
 return page
end

-- Refresh is pure UI except for explicit user setters invoked elsewhere.
function U.UpdateRunContext()
 if not U.subtitle then return end
 local label=FieldKit_L("Combat and interface tools")
 local heroic=FieldKit.GetHeroicLabel()
 if heroic then label=label.." · "..heroic end
 if U.runContext~=label then U.runContext=label;FieldKit_Text(U.subtitle,label) end
end
function U.UpdateSharingStatus()
 if U.syncStatus then FieldKit_Text(U.syncStatus,FieldKitPartySync.Status()) end
end
function U.Refresh()
 if not U.frame or not FieldKitDB then return end
 U.UpdateRunContext();U.UpdateSharingStatus()
 if U.profileView and U.profileView.Refresh then U.profileView.Refresh() end
 U.refreshing=true
 for i=1,table.getn(U.controls) do U.controls[i].Refresh() end
 for i=1,table.getn(U.homeCards) do
  local c=U.homeCards[i];local enabled=FieldKitDB[c.key]
  if c.key=="chestPins" then enabled=enabled or FieldKitDB.guardianPins end
  if c.key=="playerBar" then enabled=enabled or FieldKitDB.targetHealth end
  FieldKit_Text(c.state,enabled and "Enabled" or "Disabled")
  local color=enabled and T.green or T.muted;c.state:SetTextColor(color[1],color[2],color[3])
 end
 if U.headerProfileButtons then
  for i=1,3 do
   local b=U.headerProfileButtons[i]
   local saved=FieldKitDB.interfaceProfiles and FieldKitDB.interfaceProfiles[i]
   -- Show user names here too; the compact header remains responsive.
   -- FontStrings are width-constrained so long names never cover neighbours.
   local label=saved and (FieldKitProfiles.Name(i) or
    string.format(FieldKit_L("Profile %d"),i)) or
    string.format(FieldKit_L("Profile %d · empty"),i)
   local active=FieldKitDB.activeHudProfile==i
   FieldKit_Text(b,active and ("✓ "..label) or label)
   b.fieldkitSelected=active
   T.State(b,active)
   if b.fieldkitShowSelected then b.fieldkitShowSelected(active) end
  end
 end
 if U.quickProfileButtons then
  for i=1,3 do
   local saved=FieldKitDB.interfaceProfiles and FieldKitDB.interfaceProfiles[i]
   local active=FieldKitDB.activeHudProfile==i
   local label=saved and (FieldKitProfiles.Name(i) or string.format(FieldKit_L("Profile %d"),i)) or
     string.format(FieldKit_L("Profile %d · empty"),i)
    if active then label=label.." ✓" end
   FieldKit_Text(U.quickProfileButtons[i],label)
   U.quickProfileButtons[i].fieldkitSelected=active
   T.State(U.quickProfileButtons[i],active)
  end
 end
 if U.quickProfileActive then
  local active=FieldKitDB.activeHudProfile
  local saved=active and FieldKitDB.interfaceProfiles and FieldKitDB.interfaceProfiles[active]
  local name=saved and (FieldKitProfiles.Name(active) or string.format(FieldKit_L("Profile %d"),active))
  FieldKit_Text(U.quickProfileActive,name and (FieldKit_L("In use: ")..name) or FieldKit_L("No active profile."))
  if U.quickProfileActiveBorder then U.quickProfileActiveBorder(name~=nil) end
 end
 if U.languageRow then
  local en=FieldKit_Language()=="en"
  local fr=FieldKit_Language()=="fr"
  -- Unlike a momentary hover, selected buttons must stay selected after
  -- OnLeave and show an unambiguous visible check mark.
  U.languageRow.en.fieldkitSelected=en
  U.languageRow.fr.fieldkitSelected=fr
  T.State(U.languageRow.en,en)
  T.State(U.languageRow.fr,fr)
  FieldKit_Text(U.languageRow.en,en and "✓ English" or "English")
  FieldKit_Text(U.languageRow.fr,fr and "✓ Français" or "Français")
 end
 local reload=(FieldKitDB.compactBar==true)~=(FieldKit.appliedCompactBar==true)
 U.reloadNeeded=reload
 if U.contentWidth then U.status:SetWidth(reload and U.contentWidth-166 or U.contentWidth) end
 if reload then U.reload:Show() else U.reload:Hide() end
 if U.undoPositions then U.undo:Show() else U.undo:Hide() end
 if U.presetUndo then if U.previousHud then U.presetUndo:Show() else U.presetUndo:Hide() end end
 FieldKit_Text(U.status,reload and "Compact bar saved. Reload UI when you are ready." or "Changes apply immediately. Your preferences are kept.")
 U.refreshing=false
end

-- Persist stable page ids; old numeric selections are migrated in Config.lua.
function U.Select(id)
 if type(id)=="number" then id=U.sections[id] and U.sections[id].id end
 local selected=1
 for i=1,table.getn(U.sections) do if U.sections[i].id==id then selected=i end end
 U.CloseMenus()
 if U.navGroups then
  for i=1,table.getn(U.navOrder) do
   local group=U.navGroups[U.navOrder[i]]
   if group.sectionIds[U.sections[selected].id] and U.navOpen~=group.name then
    U.navOpen=group.name;U.LayoutNavigation();break
   end
  end
 end
 for i=1,table.getn(U.pages) do
  local page=U.pages[i];local tab=U.frame.tabs[i];local active=i==selected
  if active then page.scroll:Show();page:Show() else page:Hide();page.scroll:Hide() end
  tab.fieldkitSelected=active;T.State(tab,active)
 end
 -- Keep the selected category in view after direct navigation from home.
 if U.navigation and U.navigation.SetVerticalScroll then
  local tab=U.frame.tabs[selected]
  -- Lua 5.0 sandbox does not necessarily expose the global select().
  -- T.Button anchors navigation tabs to the scroll child using TOPLEFT.
  local pointY=nil
  if tab and tab.GetPoint then local point,relativeTo,relativePoint,pointX,y=tab:GetPoint(1);pointY=y end
  if type(pointY)=="number" then
   local top=-pointY
   local offset=U.navigation:GetVerticalScroll() or 0
   local height=U.navigation:GetHeight() or 0
   if height>0 then
    if top<offset then U.navigation:SetVerticalScroll(math.max(0,top-12))
    elseif top+34>offset+height then U.navigation:SetVerticalScroll(math.max(0,top+46-height)) end
   end
  end
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
 if U.navigation then
  U.navigation:SetWidth(sidebar+6)
  U.navigation:SetHeight(math.max(180,h-236))
  U.navigationBody:SetWidth(sidebar-16)
 end
 U.header:SetWidth(w-64);U.headerLine:SetWidth(w-44)
 U.title:SetWidth(w-220);U.subtitle:SetWidth(w-230)
 -- Always anchor the whole selector as one unit away from the title,
 -- close button and panel header's drag hit area.
 -- Fit three named buttons inside a single fixed-width header band.
 -- Avoid the window close icon, title and native draggable header region.
 local selectorWidth=math.min(386,math.max(218,w*.40))
 U.headerProfileLayer:SetWidth(selectorWidth)
 U.headerProfileLayer:ClearAllPoints()
 U.headerProfileLayer:SetPoint("TOPRIGHT",U.frame,"TOPRIGHT",-34,-72)
 local labelWidth=36
 local gap=7
 local buttonWidth=(selectorWidth-labelWidth-gap*3-6)/3
 U.headerProfiles:SetWidth(labelWidth)
 for i=1,3 do
  local b=U.headerProfileButtons[i]
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT",U.headerProfileLayer,"TOPLEFT",
   labelWidth+gap+(i-1)*(buttonWidth+gap),-5)
  b:SetWidth(buttonWidth)
  b.fieldkitLabel:SetWidth(buttonWidth-12)
  T.Update(b)
 end
 U.status:ClearAllPoints();U.status:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-(h-78));U.contentWidth=content;U.status:SetWidth(U.reloadNeeded and content-166 or content)
 local y=h-44
 -- C10.4: reserve the close button first; distribute footer actions within
 -- the remaining width. Undo is optional, but must never cover Close.
 local closeWidth=90
 local available=content-closeWidth-14
 local gap=8
 local previewWidth=math.min(120,math.max(88,available*.23))
 local resetWidth=math.min(190,math.max(140,available*.43))
 local undoWidth=75
 if previewWidth+resetWidth+undoWidth+gap*2>available then
  resetWidth=math.max(120,available-previewWidth-undoWidth-gap*2)
 end
 U.move:ClearAllPoints();U.move:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-y);U.move:SetWidth(previewWidth)
 U.reset:ClearAllPoints();U.reset:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x+previewWidth+gap,-y);U.reset:SetWidth(resetWidth)
 U.undo:ClearAllPoints();U.undo:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x+previewWidth+gap+resetWidth+gap,-y);U.undo:SetWidth(undoWidth)
 U.close:ClearAllPoints();U.close:SetPoint("TOPRIGHT",U.frame,"TOPRIGHT",-22,-y)
 U.move.fieldkitLabel:SetWidth(previewWidth-20)
 U.reset.fieldkitLabel:SetWidth(resetWidth-16)
 U.undo.fieldkitLabel:SetWidth(undoWidth-16)
 T.Update(U.move);T.Update(U.reset);T.Update(U.undo)
 U.reload:ClearAllPoints();U.reload:SetPoint("TOPRIGHT",U.frame,"TOPRIGHT",-22,-(h-80))
 for i=1,table.getn(U.pages) do
  local page=U.pages[i];local scroll=page.scroll
  scroll:ClearAllPoints();scroll:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-132)
  scroll:SetWidth(content);scroll:SetHeight(h-232);page:SetWidth(content-10);page:SetHeight(math.max(page.contentHeight,h-232))
  page.heading:SetWidth(content-14)
  for j=1,table.getn(page.flow) do page.flow[j].frame.Reflow(content-16) end
  if page.windowTabs then
   local tw=(content-22)/4
   for j,tab in ipairs(page.windowTabs) do
    tab.button:ClearAllPoints();tab.button:SetPoint("TOPLEFT",page,"TOPLEFT",(j-1)*(tw+2),-50)
    tab.button:SetWidth(tw);tab.button.fieldkitLabel:SetWidth(tw-10);T.Update(tab.button)
   end
  end
  if page.combatEditor and page.combatEditor.Reflow then page.combatEditor.Reflow(content-16) end
  local tab=U.frame.tabs[i];tab:SetWidth(sidebar-24);tab.fieldkitLabel:SetWidth(sidebar-69);T.Update(tab)
  if page.intro then
   page.intro:SetWidth(content-16);page.presetHint:SetWidth(content-16)
   local cw=(content-28)/2
   for j=1,4 do
    local c=U.homeCards[j];c:ClearAllPoints();c:SetPoint("TOPLEFT",page,"TOPLEFT",math.mod(j-1,2)*(cw+12),-108-math.floor((j-1)/2)*154)
    c:SetWidth(cw);c.title:SetWidth(cw-70);c.state:SetWidth(cw-70);c.detail:SetWidth(cw-32)
    c.open:SetWidth(cw-32);c.open.fieldkitLabel:SetWidth(cw-52);T.Update(c);T.Update(c.open)
   end
   page.layoutCard:ClearAllPoints();page.layoutCard:SetPoint("TOPLEFT",page,"TOPLEFT",0,-426);page.layoutCard:SetWidth(content-16)
   page.layoutTitle:SetWidth(content-204);page.layoutHint:SetWidth(content-204)
   page.layoutAction:ClearAllPoints();page.layoutAction:SetPoint("TOPRIGHT",page.layoutCard,"TOPRIGHT",-16,-32);T.Update(page.layoutCard)
    if page.quickButtons then
     page.quickHint:SetWidth(content-20)
     page.quickActiveFrame:SetWidth(content-20)
     page.quickActive:SetWidth(content-44)
     T.Update(page.quickActiveFrame)
     local qw=(content-40)/3
     for i=1,3 do
      local b=page.quickButtons[i]
      b:ClearAllPoints();b:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*(qw+12),-719)
      b:SetWidth(qw);b.fieldkitLabel:SetWidth(qw-20);T.Update(b)
     end
    end
  end
 end
 U.CloseMenus()
end

-- Hide settings during arrangement so the large panel cannot cover movable frames.
function U.SetLayoutEditing(enabled,returnToSettings)
 FieldKit.layoutEditing=enabled and true or false
 if enabled then
  U.routingLayout=true;U.frame:Hide();U.routingLayout=nil
  U.context.unlock(true);U.context.bosses();FieldKitCardLayout.UpdateDock();U.dock:Show();FieldKitPreview.Start(true)
  if FieldKitDB.combatText then FieldKitCombat.ShowAnchors() end
 else
  FieldKitPreview.Stop();U.dock:Hide();U.context.unlock(false);FieldKitCombat.HideAnchors();U.context.bosses()
  if returnToSettings then U.Reflow();U.frame:Show();U.Refresh() end
 end
 FieldKitCoop.Update()
end

function U.StartLayout(combat)
 U.SetLayoutEditing(true,false);if combat then FieldKitCombat.ShowAnchors() end
end

-- Position reset has a bounded, immediate Undo; feature/style preferences are untouched.
function U.ResetPositions()
 local snapshot={pos={},anchors={},detached=FieldKitDB.moneyDetached,
  chatWidth=FieldKitDB.chatWidth,chatHeight=FieldKitDB.chatHeight,
  chatAnchor=FieldKitDB.chatAnchor and
   {x=FieldKitDB.chatAnchor.x,y=FieldKitDB.chatAnchor.y} or nil}
 for name,p in pairs(FieldKitDB.pos) do snapshot.pos[name]={p[1],p[2]} end
 for name,a in pairs(FieldKitDB.frameAnchors) do snapshot.anchors[name]={a[1],a[2],a[3],a[4]} end
 U.undoPositions=snapshot;U.context.reset();U.Refresh()
end

function U.UndoPositions()
 local saved=U.undoPositions;if not saved then return end
 FieldKitDB.pos=saved.pos;FieldKitDB.moneyDetached=saved.detached
 FieldKitDB.frameAnchors=saved.anchors
 FieldKitDB.chatWidth=saved.chatWidth
 FieldKitDB.chatHeight=saved.chatHeight
 FieldKitDB.chatAnchor=saved.chatAnchor
 -- ApplyAnchor uses a cached stamp. Reset it through the public chat
 -- placement helper without discarding the saved anchor.
 if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
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
 U.subtitle=T.Label(frame,"Combat and interface tools",119,69,600,22,13,T.muted);FieldKit_Text(U.subtitle,"Combat and interface tools")
 U.version=T.Label(frame,"v"..FieldKit.version,810,19,146,20,11,T.muted)
 U.version:ClearAllPoints();U.version:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-48,-22)
 local line=frame:CreateTexture(nil,"ARTWORK");line:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-111);line:SetWidth(956);line:SetHeight(1);line:SetTexture(.54,.44,.27);U.headerLine=line
 local header=CreateFrame("Frame",nil,frame);header:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-12);header:SetWidth(900);header:SetHeight(92);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
 U.header=header
 header:SetScript("OnDragStart",function() frame:StartMoving() end)
 header:SetScript("OnDragStop",function() frame:StopMovingOrSizing() end)
 local x=CreateFrame("Button","FieldKitPanelClose",frame,"UIPanelCloseButton");x:SetWidth(26);x:SetHeight(26);x:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-10,-10);x:SetFrameLevel(120);x:SetScript("OnClick",function() frame:Hide() end)
 -- Keep quick controls on a dedicated transparent layer ABOVE the drag
 -- capture frame. Otherwise native Benilla 1.12 can route clicks to the
 -- header's drag handler and make buttons appear inert.
 U.headerProfileLayer=CreateFrame("Frame",nil,frame)
 U.headerProfileLayer:SetWidth(386);U.headerProfileLayer:SetHeight(35)
 U.headerProfileLayer:SetFrameLevel(header:GetFrameLevel()+12)
 U.headerProfileLayer:EnableMouse(false)
 U.headerProfiles=T.Label(U.headerProfileLayer,"PROF",0,6,38,23,12,T.muted)
 U.headerProfileButtons={}
 for i=1,3 do
  local slot=i
  local button=T.Button(U.headerProfileLayer,nil,tostring(i),40+(i-1)*110,5,104,27,function()
   if FieldKitDB.interfaceProfiles and FieldKitDB.interfaceProfiles[slot] then
    FieldKitProfiles.Load(slot);U.Refresh()
   else U.Select("profiles") end
  end)
  button:SetFrameLevel(U.headerProfileLayer:GetFrameLevel()+1)
  button.fieldkitShowSelected=ProfileActiveBorder(button)
  U.headerProfileButtons[i]=button
 end
 -- The navigation has its own scroll viewport. On 768px screens all pages
 -- remain reachable without shrinking labels or covering the footer.
 local nav=CreateFrame("ScrollFrame","FieldKitV2Navigation",frame)
 nav:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-126)
 nav:SetWidth(208);nav:SetHeight(520)
 local navBody=CreateFrame("Frame","FieldKitV2NavigationContent",nav)
 navBody:SetWidth(190);navBody:SetHeight(600)
 nav:SetScrollChild(navBody)
 -- C7 polish: wheel scrolling without the intrusive native scrollbar.
 U.Wheel(nav,navBody)
 U.navigation=nav;U.navigationBody=navBody
 -- V2-C1: one expanded category at a time. Every existing page remains intact.
 U.navGroups={};U.navOrder={};U.navOpen=nil
 frame.tabs={}
 local lastGroup=nil
 for i=1,table.getn(sections) do
  local section=sections[i];local id=section.id
  local group=section.group or "Other"
  if not U.navGroups[group] then
   U.navGroups[group]={items={},name=group}
   table.insert(U.navOrder,group)
  end
  local b=T.Button(navBody,"FieldKitPanelTab"..i,section.title,8,0,180,32,function() U.Select(id) end);FieldKit_Text(b,section.title)
  b.section=section;b.fieldkitNavigation=true;T.State(b,false)
  b.fieldkitLabel:ClearAllPoints();b.fieldkitLabel:SetPoint("LEFT",b,"LEFT",37,0);b.fieldkitLabel:SetWidth(137)
  T.Glyph(b,section.glyph,7,6,21);b.page=U.BuildPage(section,i);frame.tabs[i]=b
  table.insert(U.navGroups[group].items,b)
  U.navGroups[group].firstId=U.navGroups[group].firstId or id
  U.navGroups[group].sectionIds=U.navGroups[group].sectionIds or {}
  U.navGroups[group].sectionIds[id]=true
 end
 function U.LayoutNavigation()
  local y=0
  for i=1,table.getn(U.navOrder) do
   local group=U.navGroups[U.navOrder[i]]
   if not group.header then
    local name=group.name
    group.header=T.Button(navBody,nil,name,8,0,180,30,function()
     if U.navOpen==name then return end
     U.navOpen=name
     U.LayoutNavigation()
     U.Select(group.firstId)
    end)
   end
   local header=group.header
   header:ClearAllPoints();header:SetPoint("TOPLEFT",navBody,"TOPLEFT",8,-y)
   header:SetWidth(180);header:SetHeight(30)
   T.State(header,U.navOpen==group.name)
   y=y+33
   for j=1,table.getn(group.items) do
    local tab=group.items[j]
    if U.navOpen==group.name then
     tab:ClearAllPoints();tab:SetPoint("TOPLEFT",navBody,"TOPLEFT",8,-y)
     tab:Show();y=y+34
    else tab:Hide() end
   end
   y=y+4
  end
  navBody:SetHeight(y+12);U.navigationHeight=y+12
 end
 local initialId=FieldKitDB and FieldKitDB.uiPage or sections[1].id
 for i=1,table.getn(U.navOrder) do
  local group=U.navGroups[U.navOrder[i]]
  if group.sectionIds[initialId] then U.navOpen=group.name end
 end
 U.navOpen=U.navOpen or U.navOrder[1]
 U.LayoutNavigation()
 U.status=T.Label(frame,"",240,680,650,24,12,T.muted)
 U.move=T.Button(frame,"FieldKitMoveWindows","Previews",240,716,120,28,function() U.SetLayoutEditing(true,false) end);FieldKit_Text(U.move,"Previews")
 U.reset=T.Button(frame,"FieldKitPanelReset","Reset HUD positions",372,716,190,28,U.ResetPositions);FieldKit_Text(U.reset,"Reset HUD positions");U.reset.fieldkitLabel:SetWidth(170);T.Font(U.reset.fieldkitLabel,12,T.gold)
 U.undo=T.Button(frame,nil,"Undo",574,716,75,28,U.UndoPositions);FieldKit_Text(U.undo,"Undo")
 U.close=T.Button(frame,nil,"Close",874,716,90,28,function() frame:Hide() end);FieldKit_Text(U.close,"Close")
 U.reload=T.Button(frame,nil,"Reload UI",824,680,150,26,function() if U.reloadNeeded then context.reload() end end)
 local dock=CreateFrame("Frame","FieldKitLayoutDock",UIParent);U.dock=dock
 dock:SetWidth(560);dock:SetHeight(172);dock:SetPoint("TOP",UIParent,"TOP",0,-30);dock:SetFrameStrata("DIALOG");dock:SetFrameLevel(150);T.Surface(dock,"window")
 T.Label(dock,"Preview — sample data",18,12,380,26,20,T.gold,true)
 T.Label(dock,"Drag examples to place windows. Done restores live data.",18,44,370,30,12,T.muted)
 U.done=T.Button(dock,"FieldKitLayoutDone","Done",438,29,100,30,function() U.SetLayoutEditing(false,true) end)
 U.groupLeft=T.Button(dock,nil,"",18,88,166,28,function()
  FieldKitDB.linkLeftCards=not FieldKitDB.linkLeftCards;FieldKitHudStack.Apply();FieldKitCardLayout.UpdateDock()
 end)
 U.groupRight=T.Button(dock,nil,"",192,88,166,28,function()
  FieldKitDB.linkRightCards=not FieldKitDB.linkRightCards;FieldKitCardLayout.ApplyRight();FieldKitCardLayout.UpdateDock()
 end)
 U.sizes=T.Button(dock,nil,"Adjust sizes",366,88,172,28,function()
  U.SetLayoutEditing(false,true);U.Select("layout")
 end)
 U.otherUI=T.Button(dock,"FieldKitPreviewOtherUI","Show other interface elements",18,126,520,28,FieldKitPreviewVisibility.Toggle)
 local previewElapsed=0
 dock:SetScript("OnUpdate",function() if not dock:IsShown() then previewElapsed=0;return end;previewElapsed=previewElapsed+(arg1 or 0);if previewElapsed>=.15 then previewElapsed=0;FieldKitPreview.Refresh() end end)
 dock:SetScript("OnHide",function() if FieldKit.layoutEditing then U.SetLayoutEditing(false,false) end end);dock:Hide()
 frame:SetScript("OnShow",function() U.Refresh() end)
 frame:SetScript("OnHide",function()
  U.CloseMenus()
  if context.dismiss then context.dismiss() end
  if not U.routingLayout then FieldKitPreview.Stop();FieldKit.layoutEditing=false;context.unlock(false);FieldKitCombat.HideAnchors();context.bosses() end
 end)
 local elapsed=0
 frame:SetScript("OnUpdate",function()
  elapsed=elapsed+(arg1 or 0);if elapsed<.25 then return end;elapsed=0
  U.UpdateRunContext();U.UpdateSharingStatus()
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
