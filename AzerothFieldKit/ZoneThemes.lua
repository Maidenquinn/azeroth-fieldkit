-- Opt-in presentation controller. No native telemetry or saved layouts are copied.
FieldKitZoneThemes={active=false,open={},revision=0}
local C=FieldKitZoneThemes
local H=FieldKitThemeHUD
local T=FieldKitTheme
local routes={Damage={"FieldKitMeterFrame","meterFrame"},Lairs={"FieldKitLairFrame","lairFrame"},
 Accessories={"FieldKitGearFrame","gearFrame"},Effects={"FieldKitEffectsFrame","effectsFrame"},
 Stats={"FieldKitStatsFrame","statsFrame"},Timeline={"FieldKitBossTimelineFrame","bossTimeline"},Reminders={"FieldKitEncounterFrame","nextBossCard"}}
local hidden={"FieldKitModeFrame","FieldKitMicroMenu"}
C.layoutKeys={"elwynn:minimal","elwynn:complete","elwynn:alternative","naxx:minimal","naxx:complete","naxx:alternative"}
C.positionNames={"FieldKitThemeIdentity","FieldKitThemeVitality","FieldKitThemeExperience","FieldKitThemeCounters","FieldKitThemeSchedule","FieldKitThemeDock","FieldKitThemeNavigation","FieldKitThemeHeader","FieldKitThemeMap","FieldKitThemeTargetFrame","FieldKitPlayerBar","FieldKitPlayerBuffs","FieldKitBossFrame1"}
for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do table.insert(C.positionNames,"FieldKitThemeSummary"..kind) end
for _,zone in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"minimal","complete","alternative"}) do table.insert(C.layoutKeys,zone..":"..variant..":reference") end end
for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do table.insert(C.positionNames,"FieldKitReferencePanel"..kind) end
table.insert(C.positionNames,"FieldKitReferenceChat")
table.insert(C.positionNames,"FieldKitReferenceXP")
table.insert(C.positionNames,"FieldKitThemeUtility")
for _,name in ipairs(FieldKitCardLayout.names) do table.insert(C.positionNames,name) end
-- Sizes are scoped exactly like positions: one zone, composition and profile.
C.elementNames={FieldKitThemeDock="Action bar",FieldKitThemeIdentity="Zone / mode",FieldKitThemeHeader="Timeline",FieldKitThemeVitality="Health / resource",FieldKitThemeNavigation="Quick access",FieldKitThemeMap="Square minimap",FieldKitReferenceChat="Chat",FieldKitReferenceXP="Experience",FieldKitThemeUtility="FieldKit",FieldKitThemeTargetFrame="Target",FieldKitReferencePanelDamage="Damage",FieldKitReferencePanelLairs="Lairs",FieldKitReferencePanelAccessories="Equipment",FieldKitReferencePanelStats="Statistics",FieldKitReferencePanelEffects="Effects"}
function C.NormalizeScales(value)
 local out={};if type(value)~="table" then return out end
 for _,key in ipairs(C.layoutKeys) do if type(value[key])=="table" then
  local layout={};out[key]=layout
  for name in pairs(C.elementNames) do local n=FieldKit.Number(value[key][name]);if n then layout[name]=math.floor(math.max(50,math.min(130,n))+.5) end end
 end end
 return out
end
function C.ElementScale(name)
 local all=FieldKitDB.zoneThemeElementScales;local layout=type(all)=="table" and all[C.currentLayout or ""]
 return FieldKit.Number(type(layout)=="table" and layout[name],100,50,130)/100
end
function C.SetElementScale(name,value)
 if not C.active or not C.elementNames[name] or not C.currentLayout then return end
 local old=C.ElementScale(name);local n=math.floor(FieldKit.Number(value,100,50,130)/5+.5)*5
 local all=FieldKitDB.zoneThemeElementScales;if type(all)~="table" then all={};FieldKitDB.zoneThemeElementScales=all end
 all[C.currentLayout]=all[C.currentLayout] or {};all[C.currentLayout][name]=n
 -- Saved SetPoint offsets are in the scaled frame's units. Keep its anchor
 -- on the same screen pixel when the scale changes, including dragged frames.
 local positions=FieldKitDB.zoneThemePositions[C.currentLayout];local a=positions and positions[name]
 if a then a[3]=a[3]*old/(n/100);a[4]=a[4]*old/(n/100) end
 if name=="FieldKitThemeBosses" and positions then for i=1,4 do local a=positions["FieldKitBossFrame"..i];if a then a[3]=a[3]*old/(n/100);a[4]=a[4]*old/(n/100) end end end
 C.Refresh(true)
end
function C.Elements()
 local R=FieldKitReferenceHUD;local d=R and R.active and R.layout;local out={}
 if not d then return out end
 local function Add(name,label) table.insert(out,{name=name,label=label or C.elementNames[name]}) end
 Add("FieldKitThemeDock",d.integratedVitals and "Actions, health and ornaments" or "Actions and ornaments")
 Add("FieldKitThemeIdentity",not d.rects.mapArt and "Map, zone and mode" or nil);Add("FieldKitThemeHeader")
 if not d.integratedVitals then Add("FieldKitThemeVitality") end
 if d.rects.mapArt then Add("FieldKitThemeMap") end
 if d.rects.nav then Add("FieldKitThemeNavigation") end
 Add("FieldKitReferenceChat")
 if d.rects.xpArt then Add("FieldKitReferenceXP") end
 if d.utilityRect or d.rects.utility then Add("FieldKitThemeUtility") end
 for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do if d.rects[kind] then Add("FieldKitReferencePanel"..kind) end end
 Add("FieldKitThemeTargetFrame");Add("FieldKitThemeBosses","Tracked bosses")
 return out
end
C.elementNames.FieldKitThemeBosses="Tracked bosses"
function C.BossScales(restore)
 C.bossBefore=C.bossBefore or {}
 if restore then for f,scale in pairs(C.bossBefore) do f:SetScale(scale) end;C.bossBefore={};return end
 for i=1,4 do for _,suffix in ipairs({"","Compact"}) do local f=getglobal("FieldKitBossFrame"..i..suffix)
  if f then if not C.bossBefore[f] then C.bossBefore[f]=f:GetScale() end;f:SetScale(C.ElementScale("FieldKitThemeBosses")) end
 end end
end
function C.NormalizePositions(value)
 local out={};if type(value)~="table" then return out end
 for _,key in ipairs(C.layoutKeys) do
  local source=value[key]
  if type(source)=="table" then
   local layout={};out[key]=layout
   for _,name in ipairs(C.positionNames) do
    local a=source[name]
    if FieldKitPositions.Valid(a) then layout[name]={a[1],a[2],a[3],a[4]} end
   end
  end
 end
 return out
end
function C.Position(frame)
 local all=FieldKitDB.zoneThemePositions
 local layout=type(all)=="table" and all[C.currentLayout or ""]
 local a=type(layout)=="table" and layout[frame:GetName()]
 return FieldKitPositions.Valid(a) and a or nil
end
function C.Place(frame,p,r,rp,x,y,force)
 if not frame then return end
 local a=C.Position(frame)
 if a then H.Anchor(frame,a[1],UIParent,a[2],a[3],a[4],force)
 else H.Anchor(frame,p,r,rp,x,y,force) end
end
function C.Remember(frame)
 if not C.active or not C.currentLayout or not frame then return false end
 local name=frame:GetName();local allowed=false
 for _,key in ipairs(C.positionNames) do if key==name then allowed=true end end
 if not allowed then return false end
 local a=H.Points(frame)[1]
 if a and (a[2]~=UIParent or a[1]~="TOPLEFT") and frame.GetLeft and frame:GetLeft() and frame:GetTop() then
  -- Always store a card by its top-left corner (cards that change height, like Bonuses, grow downward), and when the
  -- engine leaves it anchored to the scaled canvas store the same
  -- on-screen spot against UIParent (BOTTOMLEFT origin) so the position can be saved and restored.
  frame:ClearAllPoints();frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",frame:GetLeft(),frame:GetTop());a=H.Points(frame)[1]
 end
 if not a or a[2]~=UIParent then return false end
 local value={a[1],a[3],a[4],a[5]}
 if not FieldKitPositions.Valid(value) then return false end
 local all=FieldKitDB.zoneThemePositions
 if type(all)~="table" then all={};FieldKitDB.zoneThemePositions=all end
 if type(all[C.currentLayout])~="table" then all[C.currentLayout]={} end
 all[C.currentLayout][name]=value
 if FieldKitReferenceHUD and FieldKitReferenceHUD.NoteMoved then FieldKitReferenceHUD.NoteMoved(name) end
 H.Anchor(frame,value[1],UIParent,value[2],value[3],value[4],true)
 return true
end
function C.Finish(frame)
 if not frame.azsMoving then return end
 frame.azsMoving=nil;frame:StopMovingOrSizing();C.Remember(frame)
end
function C.Bind(frame)
 if frame.fieldkitZoneDrag then return end
 frame.fieldkitZoneDrag=true;C.bound=C.bound or {};table.insert(C.bound,frame)
 frame:SetMovable(true);frame:SetClampedToScreen(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
 frame:SetScript("OnDragStart",function()
  if C.active and not FieldKitDB.windowsLocked then this.azsMoving=true;this:StartMoving() end
 end)
 frame:SetScript("OnDragStop",function() C.Finish(this) end)
 frame:SetScript("OnMouseUp",function() C.Finish(this) end)
 frame:SetScript("OnHide",function() C.Finish(this) end)
end
-- Detailed readers are movable even while the combat HUD is locked.
function C.DetailHandle(frame)
 C.detailHandles=C.detailHandles or {}
 local handle=C.detailHandles[frame]
 if not handle then
  handle=CreateFrame("Button",frame:GetName().."ThemeDrag",frame);C.detailHandles[frame]=handle
  handle:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",4,4);handle:SetHeight(26)
  T.Surface(handle,"button",true);handle.fieldkitLabel=T.Label(handle,"Drag window",8,0,180,26,12,T.muted)
  handle:SetFrameLevel(frame:GetFrameLevel()+20);handle:EnableMouse(true);handle:RegisterForDrag("LeftButton")
  frame:SetMovable(true);frame:SetClampedToScreen(true)
  C.bound=C.bound or {};table.insert(C.bound,frame)
  local function Start() if C.active then frame.azsMoving=true;frame:StartMoving() end end
  handle:SetScript("OnMouseDown",Start);handle:SetScript("OnDragStart",Start)
  handle:SetScript("OnDragStop",function() C.Finish(frame) end)
  handle:SetScript("OnMouseUp",function() C.Finish(frame) end)
  handle:SetScript("OnHide",function() C.Finish(frame) end)
 end
 handle:SetWidth(math.max(80,frame:GetWidth()-190));handle.fieldkitLabel:SetWidth(handle:GetWidth()-16);T.Update(handle);handle:Show()
 return handle
end
function C.Resolve()
 if not FieldKitDB or not FieldKitDB.zoneThemes then return nil end
 local key=FieldKitDB.zoneThemeMode
 if key=="auto" then key=type(AZS_ZONE)=="table" and AZS_ZONE.zone end
 if key=="elwynn" or key=="naxx" then return key end
end
function C.Suspend()
 for _,handle in pairs(C.detailHandles or {}) do handle:Hide() end
 C.BossScales(true)
 C.nativeMeterOpen=nil;C.NativeRestore()
 if FieldKitReferenceHUD then FieldKitReferenceHUD.Stop() end
 if not C.active then return end
 C.active=false;FieldKitThemeTarget.Stop();H.Restore();FieldKitReferenceHUD.Stop();FieldKitThemeMinimap.Restore()
 local stats=getglobal("FieldKitStatsFrame")
 if stats and stats.fieldkitNaturalHeight then FieldKitCardLayout.Rows(stats,stats.fieldkitNaturalHeight,stats.fieldkitRowCount or 0,"stats",FieldKitDB.statsCollapsed);T.Update(stats) end
 C.open={};C.placed={};C.signature=nil
 T.SetZone("classic")
 if FieldKitUI and FieldKitUI.frame then FieldKitUI.referenceZone=nil;FieldKitUI.Reflow() end
end
-- Persist only seven restoration booleans so a reload cannot forget prior CVars.
function C.NativeRestore()
 local saved=FieldKitDB and FieldKitDB.zoneThemeNativeBefore
 if type(saved)~="table" then return end
 for _,key in ipairs({"clock","tally","build","banners","bosses","meter","levels"}) do
  if type(saved[key])=="boolean" then FieldKit.SetHudShown(key,saved[key]) end
 end
 FieldKitDB.zoneThemeNativeBefore=nil
end
function C.NativeReplace()
 if type(AZS_IsHudShown)~="function" then return end
 if type(FieldKitDB.zoneThemeNativeBefore)~="table" then FieldKitDB.zoneThemeNativeBefore={} end
 local saved=FieldKitDB.zoneThemeNativeBefore
 if saved.banners==nil then local ok,value=pcall(AZS_IsHudShown,"banners");if ok and type(value)=="boolean" then saved.banners=value end end
 if type(saved.banners)=="boolean" then
  local editing=FieldKitUI and FieldKitUI.frame and FieldKitUI.frame:IsShown() and not (FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen())
  local wanted=not editing and saved.banners or false
  local ok,current=pcall(AZS_IsHudShown,"banners");if ok and current~=wanted then FieldKit.SetHudShown("banners",wanted) end
 end
 for _,key in ipairs({"clock","tally","build","bosses","meter","levels"}) do
  if (key~="bosses" or type(AZS_UNITS)=="table") and (key~="levels" or (type(AZS_GetStoredLevels)=="function" and type(AZS_OpenStoredLevels)=="function")) then
  if saved[key]==nil then
   local ok,value=pcall(AZS_IsHudShown,key)
   if ok and type(value)=="boolean" then saved[key]=value end
  end
  if type(saved[key])=="boolean" and not (key=="meter" and C.nativeMeterOpen) then
   local ok,current=pcall(AZS_IsHudShown,key);if ok and current==true then FieldKit.SetHudShown(key,false) end
  end
 end
 end
end
function C.Mask(frame,hidden)
 if not frame then return end
 local wasStored=frame:GetParent()==H.storage
 H.Save(frame);frame:SetParent(hidden and H.Hidden() or H.saved[frame].parent);frame:SetAlpha(hidden and 0 or H.saved[frame].alpha)
 if wasStored and not hidden and frame:IsShown() then frame:Hide();frame:Show() end
end
function C.Refresh(force)
 if not FieldKit.zoneThemeReady or not FieldKitDB or not getglobal("FieldKitPlayerBar") then return end
 if C.ui then for _,item in ipairs(C.ui) do
  local selected=item.value=="toggle" and FieldKitDB[item.key]==true or FieldKitDB[item.key]==item.value
  item.frame.fieldkitSelected=selected;T.State(item.frame,selected)
 end end
 for _,item in ipairs(C.previewCards or {}) do
  local zone=C.Resolve() or "elwynn";item.button.preview:SetTexture(T.media.."ReferenceHUD\\"..zone.."_"..item.key.."_preview.tga")
  item.button.badge:SetText(FieldKitDB.zoneThemeVariant==item.key and FieldKit_L("Active") or "")
 end
 C.sliderRefresh=true
 for _,item in ipairs(C.uiSliders or {}) do item.slider:SetValue(FieldKitDB[item.key] or 100);item.title:SetText(FieldKit_L(item.label).." : "..tostring(FieldKitDB[item.key] or 100).." %") end
 C.sliderRefresh=false
 if C.statusLabel then
  C.statusLabel:SetText(FieldKit_L(FieldKitDB.zoneThemes and "Enabled" or "Disabled").." · "..FieldKit_L(FieldKitDB.zoneThemeMode).." · "..FieldKit_L(FieldKitDB.zoneThemeVariant).."\n"..FieldKit_L("Square minimap")..": "..FieldKit_L(FieldKitDB.zoneThemeMinimap and "Enabled" or "Disabled").." · "..FieldKit_L("Character ornaments")..": "..FieldKit_L(FieldKitDB.zoneThemeArt and "Enabled" or "Disabled"))
 end
 local zone=C.Resolve()
 if not zone then C.Suspend();T.SetZone("classic");if C.RefreshElementUI then C.RefreshElementUI() end;return end
 if FieldKit.layoutEditing or (FieldKitPreview and FieldKitPreview.mode) then C.Suspend();T.SetZone(zone);return end
 local variant=FieldKitDB.zoneThemeVariant
 C.currentLayout=zone..":"..variant..(FieldKitReferenceHUD.Has(zone,variant) and ":reference" or "")
 local signature=zone..variant..UIParent:GetWidth()..":"..UIParent:GetHeight()
 if C.signature~=signature then
  C.Suspend();C.active=true;C.signature=signature;C.revision=C.revision+1;C.placed={}
 end
 C.active=true;T.SetZone(zone)
 C.BossScales(false)
 -- Yield completely to native choice cards. No writes to card priority or game data.
 if FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen() then
  FieldKitThemeTarget.Stop();FieldKitReferenceHUD.Stop();C.NativeReplace()
  for _,name in ipairs({"MainMenuBar","PlayerFrame","FieldKitPlayerBar","FieldKitCompactBar","FieldKitMoneyFrame"}) do C.Mask(getglobal(name),true) end
  for _,f in pairs(H.summaries or {}) do f:Hide() end
  for _,f in ipairs({H.dock,H.header,H.nav,H.identity,H.healthRoot,H.xpRoot,H.counterRoot,H.utility,H.micro,H.schedule,H.back}) do f:Hide() end;H.pinned=false;H.HideTip()
  return
 end
 H.Update(variant,zone);if FieldKitReferenceHUD.Has(zone,variant) then FieldKitReferenceHUD.Update(variant,zone) else FieldKitReferenceHUD.Stop() end;FieldKitThemeTarget.Update(variant)
 C.NativeReplace()
 if FieldKitDB.zoneThemeMinimap then FieldKitThemeMinimap.Apply(variant) else FieldKitThemeMinimap.Restore() end
 H.back:Hide()
 local leftY=(variant=="complete" and zone=="elwynn") and -350 or -112
 local rightY=(zone=="naxx" and variant~="alternative") and -312 or -116
 for _,kind in ipairs({"Damage","Lairs","Effects","Accessories","Stats","Timeline","Reminders"}) do
  local r=routes[kind];local frame=getglobal(r[1])
  local visible=C.open[kind]
  C.Mask(frame,not visible)
  if frame and visible then
   C.DetailHandle(frame)
   if kind=="Stats" then FieldKitCardLayout.Rows(frame,frame.fieldkitNaturalHeight or frame:GetHeight(),frame.fieldkitRowCount or table.getn(frame.rows),"stats",FieldKitDB.statsCollapsed);T.Update(frame) end
   local right=kind=="Accessories" or kind=="Stats" or (kind=="Effects" and zone=="naxx") or variant=="alternative"
   local y=right and rightY or leftY;local previous=C.placed[frame]
   if not previous or previous.y~=y or previous.height~=frame:GetHeight() then
    if FieldKitReferenceHUD.active then frame:SetFrameStrata("DIALOG");C.Place(frame,"CENTER",UIParent,"CENTER",0,70,true) else C.Place(frame,right and "TOPRIGHT" or "TOPLEFT",UIParent,right and "TOPRIGHT" or "TOPLEFT",right and -20 or 20,y,true) end
   end
   if right then rightY=rightY-frame:GetHeight()-14 else leftY=leftY-frame:GetHeight()-14 end
   local record=previous or {};record.y=y;record.height=frame:GetHeight();C.placed[frame]=record
   H.back:ClearAllPoints();H.back:SetPoint("BOTTOMRIGHT",frame,"TOPRIGHT",0,4);H.back:Show();T.Update(H.back)
  end
 end
 if FieldKitReferenceHUD.active then FieldKitReferenceHUD.Panels(variant,zone) else H.Summaries(variant,zone) end
 if C.RefreshElementUI then C.RefreshElementUI() end
 for _,name in ipairs(hidden) do C.Mask(getglobal(name),true) end
 -- Keep native target, boss, group, alerts and chat behaviors intact.
 if FieldKitScreenLayers then FieldKitScreenLayers.ApplyChoice() end
 if FieldKitUI and FieldKitUI.frame and FieldKitUI.referenceZone~=zone then FieldKitUI.referenceZone=zone;FieldKitUI.Reflow() end
end
-- /fieldkit mapfocus: for 8 seconds, record which frame really receives the pointer (hover the map buttons meanwhile).
function C.Sample()
 local now=GetTime()
 if now>C.focusUntil then
  DEFAULT_CHAT_FRAME:AddMessage("mapfocus: "..table.getn(C.focusLog).." change(s)")
  for _,line in ipairs(C.focusLog) do DEFAULT_CHAT_FRAME:AddMessage("  "..line) end
  C.focusUntil=nil;return
 end
 if now<(C.focusNext or 0) then return end;C.focusNext=now+.15
 local f=type(GetMouseFocus)=="function" and GetMouseFocus()
 local name=f and f.GetName and f:GetName() or (f and tostring(f.GetObjectType and f:GetObjectType())) or "none"
 local parent=f and f.GetParent and f:GetParent();local pn=parent and parent.GetName and parent:GetName() or "?"
 local line=string.format("%s (parent %s) strata=%s level=%s",tostring(name),tostring(pn),tostring(f and f.GetFrameStrata and f:GetFrameStrata()),tostring(f and f.GetFrameLevel and f:GetFrameLevel()))
 if line~=C.focusLast then C.focusLast=line;if table.getn(C.focusLog)<24 then table.insert(C.focusLog,line) end end
end
-- /fieldkit mapstack N: after N seconds, list EVERY shown mouse-enabled frame under the pointer, topmost first.
local STRATA={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
function C.Stack()
 local x,y=GetCursorPosition();local found={}
 local function Walk(frame,depth)
  if depth>14 then return end
  for _,child in ipairs({frame:GetChildren()}) do
   if child.IsShown and child:IsShown() and child.IsMouseEnabled and child:IsMouseEnabled() and child.GetLeft and child:GetLeft() then
    local es=child:GetEffectiveScale()
    if x>=child:GetLeft()*es and x<=child:GetRight()*es and y>=child:GetBottom()*es and y<=child:GetTop()*es then
     local parent=child.GetParent and child:GetParent()
     table.insert(found,{name=child:GetName() or ("<"..tostring(child:GetObjectType())..">"),parent=parent and parent.GetName and parent:GetName() or "?",
      strata=child:GetFrameStrata(),level=child:GetFrameLevel()})
    end
   end
   Walk(child,depth+1)
  end
 end
 Walk(UIParent,0)
 table.sort(found,function(p,q) local sp,sq=STRATA[p.strata] or 0,STRATA[q.strata] or 0;if sp~=sq then return sp>sq end return p.level>q.level end)
 local focus=type(GetMouseFocus)=="function" and GetMouseFocus()
 DEFAULT_CHAT_FRAME:AddMessage("mapstack: engine focus = "..tostring(focus and focus.GetName and focus:GetName()).." | "..table.getn(found).." mouse frame(s) under the pointer, topmost first:")
 for i=1,math.min(10,table.getn(found)) do local f=found[i];DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. %s (parent %s) %s/%d",i,f.name,f.parent,f.strata,f.level)) end
end
-- /fieldkit mapprobe events on: log the mouse events the AzerothHub gear really receives (its own handlers still run).
function C.GearEvents(on)
 local gear=getglobal("AzerothHubMinimapButton");if not gear then DEFAULT_CHAT_FRAME:AddMessage("mapprobe events: no AzerothHub gear");return end
 C.gearOriginal=C.gearOriginal or {}
 for _,event in ipairs({"OnEnter","OnLeave","OnMouseDown","OnMouseUp","OnClick","OnDragStart","OnDragStop"}) do
  if on and not C.gearOriginal[event] then
   local original=gear:GetScript(event);C.gearOriginal[event]={original}
   local name=event;gear:SetScript(event,function() DEFAULT_CHAT_FRAME:AddMessage("gear "..name.." button="..tostring(arg1));if original then original() end end)
  elseif not on and C.gearOriginal[event] then gear:SetScript(event,C.gearOriginal[event][1]);C.gearOriginal[event]=nil end
 end
end
function C.Tick()
 if C.stackAt and GetTime()>=C.stackAt then C.stackAt=nil;C.Stack() end
 if C.focusUntil then C.Sample() end
 if type(IsMouseButtonDown)=="function" and not IsMouseButtonDown("LeftButton") then
  for _,frame in ipairs(C.bound or {}) do C.Finish(frame) end
 end
 local now=GetTime()
 if C.deadline and now<C.deadline then return end
 C.deadline=now+.2;C.Refresh()
end
function C.Set(key,value)
 local allowed={zoneThemes=true,zoneThemeMode=true,zoneThemeVariant=true,zoneThemeMinimap=true,zoneThemeArt=true,zoneThemeOverlap=true,zoneThemeScale=true,cardOpacity=true}
 if not allowed[key] then return end
 C.Suspend();FieldKitDB[key]=value
 if FieldKit.ApplyHUDProfileLive then FieldKit.ApplyHUDProfileLive() end
 C.Refresh(true)
end
function C.ToggleNativeMeter()
 C.nativeMeterOpen=not C.nativeMeterOpen
 FieldKit.SetHudShown("meter",C.nativeMeterOpen);C.Refresh(true)
end
function C.Open(kind)
 if kind=="FieldKit" then
  H.pinned=false;H.HideTip()
  SlashCmdList.FieldKit("");if FieldKitUI.frame then FieldKitUI.Select("look") end;return
 end
 if kind=="Journal" then
  if SlashCmdList.AZEROTHSTATS then SlashCmdList.AZEROTHSTATS("")
  else H.Tip(H.nav,FieldKit_L("Journal"),{FieldKit_L("Career history requires Azeroth Stats."),FieldKit_L("FieldKit retains all current-run detail views.")},true) end
  return
 end
 local route=routes[kind];if not route then return end
 local opening=not C.open[kind];if opening and FieldKitReferenceHUD.active then C.open={} end;C.open[kind]=opening
 if C.open[kind] then FieldKitDB[route[2]]=true end
 C.placed={};C.Refresh(true)
 local frame=getglobal(route[1]);if C.open[kind] and frame then frame:Show() end
end
function C.Command(msg)
 local arg=string.lower(string.gsub(msg or "","^%s*(.-)%s*$","%1"))
 if arg=="status" then
  DEFAULT_CHAT_FRAME:AddMessage("FieldKit "..tostring(C.signature).." | art="..tostring(FieldKitDB.zoneThemeArt).." | accepted="..tostring(H.artAccepted).." | texture="..tostring(H.left and H.left:GetTexture()).." | map="..tostring(FieldKitThemeMinimap.reason or FieldKitThemeMinimap.active))
  for _,name in ipairs({"PlayerFrame","MainMenuBar","FieldKitCompactBar","ActionButton1"}) do
   local f=getglobal(name)
   if f then local p=f:GetParent();DEFAULT_CHAT_FRAME:AddMessage(name.." parent="..tostring(p and p:GetName()).." alpha="..tostring(f:GetAlpha()).." shown="..tostring(f:IsShown())) end
  end
 elseif arg=="cardprobe" then
  for _,line in ipairs(FieldKitReferenceHUD.Probe()) do DEFAULT_CHAT_FRAME:AddMessage(line) end
 elseif string.find(arg,"^dragdiag") then
  FieldKitReferenceHUD.dragDiag=not string.find(arg,"off");DEFAULT_CHAT_FRAME:AddMessage("dragdiag "..(FieldKitReferenceHUD.dragDiag and "on: drop a card, then read the 2 lines" or "off"))
 elseif string.find(arg,"^mapstack") then
  local seconds=tonumber((string.gsub(arg,"^mapstack%s*",""))) or 5
  C.stackAt=GetTime()+seconds;DEFAULT_CHAT_FRAME:AddMessage("mapstack: place the pointer on the gear, report in "..seconds.." s")
 elseif string.find(arg,"^mapprobe") then
  local _,_,part,state=string.find(arg,"^mapprobe%s+(%a+)%s+(%a+)")
  local M=FieldKitThemeMinimap
  if part and M.probe[part]~=nil and (state=="on" or state=="off") then M.probe[part]=(state=="on");C.Refresh(true)
  elseif part=="events" and (state=="on" or state=="off") then C.GearEvents(state=="on") end
  local line="mapprobe:";for _,k in ipairs({"ring","rim","proxies","follower"}) do line=line.." "..k.."="..(M.probe[k] and "on" or "off") end
  DEFAULT_CHAT_FRAME:AddMessage(line.." (usage: /fieldkit mapprobe <ring|rim|proxies|follower|events> <on|off>)")
 elseif arg=="mapfocus" then C.focusUntil=GetTime()+8;C.focusLog={};C.focusLast=nil;DEFAULT_CHAT_FRAME:AddMessage("mapfocus: move the pointer over the map buttons for 8 seconds")
 elseif arg=="clickdiag" then
  for _,d in ipairs(FieldKitReferenceHUD.diagButtons or {}) do DEFAULT_CHAT_FRAME:AddMessage(d.label..": down "..d.down.." up "..d.up.." click "..d.click.." hide "..d.hide) end
 elseif arg=="mapdiag" then
  local M=FieldKitThemeMinimap
  local focus=type(GetMouseFocus)=="function" and GetMouseFocus();DEFAULT_CHAT_FRAME:AddMessage("mouse focus="..tostring(focus and focus.GetName and focus:GetName()).." handle="..tostring(M.dragHandle and (M.dragHandle:GetFrameStrata().."/"..M.dragHandle:GetFrameLevel())).." minimap level="..tostring(Minimap and Minimap:GetFrameLevel()))
  for _,line in ipairs(M.log or {}) do DEFAULT_CHAT_FRAME:AddMessage("  "..line) end
  DEFAULT_CHAT_FRAME:AddMessage("map active="..tostring(M.active).." ring="..tostring(M.ringHalf and M.ringHalf[1]).."x"..tostring(M.ringHalf and M.ringHalf[2]))
  if Minimap and Minimap.GetChildren then for _,f in ipairs({Minimap:GetChildren()}) do
   local name=f.GetName and f:GetName()
   if name then local p,rel,rp,x,y=f:GetPoint();local parked=(x==-4000)
    DEFAULT_CHAT_FRAME:AddMessage(name.." alpha="..tostring(f:GetAlpha()).." shown="..tostring(f:IsShown()).." mouse="..tostring(f.IsMouseEnabled and f:IsMouseEnabled())..string.format(" pt=%s %s %s",tostring(p),tostring(x),tostring(y)).." ring="..tostring(M.ring and M.ring[f]~=nil).." parked="..tostring(parked)) end
  end end
 elseif arg=="off" then C.Set("zoneThemes",false)
 elseif arg=="on" then C.Set("zoneThemes",true)
 elseif arg=="auto" or arg=="elwynn" or arg=="naxx" then C.Set("zoneThemeMode",arg);C.Set("zoneThemes",true)
 elseif arg=="minimal" or arg=="complete" or arg=="alternative" then C.Set("zoneThemeVariant",arg)
 else
  SlashCmdList.FieldKit("");if FieldKitUI.frame then FieldKitUI.Select("look") end
 end
end
function FieldKitThemeUI(parent,offset)
 local page=CreateFrame("Frame",nil,parent);page:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-offset);page:SetHeight(835)
 local note=T.Label(page,"One theme for HUD, windows and tooltips.",0,0,950,30,18,T.text)
 C.ui={};C.previewCards={}
 local function Button(key,value,label,x,y,w,h)
  local button=T.Button(page,nil,label,x,y,w,h or 32,function()
   if value=="toggle" then C.Set(key,not FieldKitDB[key]) else C.Set(key,value) end
  end)
  table.insert(C.ui,{frame=button,key=key,value=value});return button
 end
 local variants={}
 for i,key in ipairs(FieldKitZoneVariants) do
  local b=Button("zoneThemeVariant",key,FieldKit_L(key),(i-1)*270,45,260,224);variants[i]=b
  b.fieldkitLabel:ClearAllPoints();b.fieldkitLabel:SetPoint("TOPLEFT",b,"TOPLEFT",16,-8);b.fieldkitLabel:SetWidth(220);b.fieldkitLabel:SetHeight(32);T.Font(b.fieldkitLabel,23,T.text,true)
  b.preview=b:CreateTexture(nil,"ARTWORK");b.preview:SetPoint("TOPLEFT",b,"TOPLEFT",8,-49);b.preview:SetWidth(244);b.preview:SetHeight(122)
  b.hint=T.Label(b,({"Essentials within reach.","Detailed tracking and quick access.","Reorganized map and actions."})[i],12,179,236,34,15,T.text)
  b.badge=T.Label(b,nil,164,12,78,25,14,T.gold,true);C.previewCards[i]={button=b,key=key}
 end
 local modes={}
 for i,key in ipairs({"auto","elwynn","naxx"}) do modes[i]=Button("zoneThemeMode",key,FieldKit_L(key),(i-1)*270,286,260) end
 local enabled=Button("zoneThemes","toggle","Enable / disable themes",0,334,260)
 local map=Button("zoneThemeMinimap","toggle","Square minimap",274,334,260)
 local art=Button("zoneThemeArt","toggle","Character ornaments",548,334,260)
 local overlap=Button("zoneThemeOverlap","toggle","Allow card overlap",822,334,200)
 local sliders={}
 for i,key in ipairs({"zoneThemeScale","cardOpacity"}) do
  local title=T.Label(page,nil,(i-1)*420,384,400,26,18,T.text,true)
  local slider=CreateFrame("Slider","FieldKitThemeSlider"..key,page,"OptionsSliderTemplate");slider:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*420+8,-424);slider:SetWidth(390);slider:SetHeight(18);slider:SetMinMaxValues(i==1 and 75 or 30,i==1 and 110 or 100);slider:SetValueStep(5);T.Control(slider,"slider")
  for _,suffix in ipairs({"Low","High","Text"}) do local part=getglobal("FieldKitThemeSlider"..key..suffix);if part then part:Hide() end end
  slider:SetValue(FieldKitDB[key] or 100);local pref=key;local label=i==1 and "HUD scale" or "Panel opacity"
  title:SetText(FieldKit_L(label).." : "..tostring(FieldKitDB[key] or 100).." %")
  slider:SetScript("OnValueChanged",function() if not C.sliderRefresh then local value=math.floor((this:GetValue() or 100)/5+.5)*5;title:SetText(FieldKit_L(label).." : "..value.." %");C.Set(pref,value) end end)
  sliders[i]={slider=slider,title=title,key=key,label=label}
 end
 C.uiSliders=sliders
 C.statusLabel=T.Label(page,nil,0,467,950,48,14,T.muted)
 local reset=T.Button(page,nil,"Reset theme positions",0,535,310,32,function()
  if C.currentLayout then FieldKitDB.zoneThemePositions[C.currentLayout]=nil;C.revision=C.revision+1;C.placed={};C.Refresh(true) end
 end)
 local profiles=T.Button(page,nil,"Manage profiles",330,535,260,32,function() FieldKitUI.Select("profiles") end)
 local elementTitle=T.Label(page,"Size by element",0,590,810,28,20,T.text,true)
 local selected=T.Button(page,nil,"",48,630,520,34,function() C.CycleElement(1) end)
 local previous=T.Button(page,nil,"<",0,630,38,34,function() C.CycleElement(-1) end)
 local following=T.Button(page,nil,">",578,630,38,34,function() C.CycleElement(1) end)
 local elementValue=T.Label(page,nil,0,679,810,26,17,T.text)
 local elementSlider=CreateFrame("Slider","FieldKitThemeElementScale",page,"OptionsSliderTemplate");elementSlider:SetPoint("TOPLEFT",page,"TOPLEFT",8,-718);elementSlider:SetWidth(540);elementSlider:SetHeight(18);elementSlider:SetMinMaxValues(50,130);elementSlider:SetValueStep(5);T.Control(elementSlider,"slider")
 for _,suffix in ipairs({"Low","High","Text"}) do local part=getglobal("FieldKitThemeElementScale"..suffix);if part then part:Hide() end end
 elementSlider:SetScript("OnValueChanged",function() if not C.elementSliderRefresh and C.selectedElement then C.SetElementScale(C.selectedElement,this:GetValue()) end end)
 local elementReset=T.Button(page,nil,"Reset element size",575,706,235,34,function() if C.selectedElement then C.SetElementScale(C.selectedElement,100) end end)
 local sizeNote=T.Label(page,"Each size is saved for this zone, layout and profile. Shared frames resize together. Unlock windows to move them.",0,757,810,64,15,T.muted)
 function C.CycleElement(delta)
  local elements=C.Elements();local index=1
  for i,e in ipairs(elements) do if e.name==C.selectedElement then index=i end end
  if table.getn(elements)>0 then index=math.mod(index-1+delta+table.getn(elements),table.getn(elements))+1;C.selectedElement=elements[index].name end
  C.RefreshElementUI()
 end
 function C.RefreshElementUI()
  local elements=C.Elements();local found
  for _,e in ipairs(elements) do if e.name==C.selectedElement then found=e end end
  found=found or elements[1];C.selectedElement=found and found.name
  selected.fieldkitLabel:SetText(found and FieldKit_L(found.label) or FieldKit_L("Enable themes to resize elements"))
  local value=found and math.floor(C.ElementScale(found.name)*100+.5) or 100
  elementValue:SetText(FieldKit_L("Element scale").." : "..value.." %  (50–130 %)")
  C.elementSliderRefresh=true;elementSlider:SetValue(value);C.elementSliderRefresh=false
  for _,f in ipairs({selected,previous,following,elementReset}) do T.Update(f) end
 end
 C.RefreshElementUI()
 page.Reflow=function(w)
  page:SetWidth(w);note:SetWidth(w);C.statusLabel:SetWidth(w)
  for i,item in ipairs(sliders) do local half=(w-26)/2;item.title:ClearAllPoints();item.title:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*(half+26),-384);item.title:SetWidth(half);item.slider:ClearAllPoints();item.slider:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*(half+26)+8,-424);item.slider:SetWidth(half-16);T.Update(item.slider) end
  local bw=(w-26)/3
  for i,b in ipairs(variants) do
   b:ClearAllPoints();b:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*(bw+13),-45);b:SetWidth(bw);b.preview:SetWidth(bw-16);b.preview:SetHeight(122);b.fieldkitLabel:SetWidth(bw-30);b.hint:SetWidth(bw-24);b.badge:ClearAllPoints();b.badge:SetPoint("TOPRIGHT",b,"TOPRIGHT",-10,-18);T.Update(b)
  end
  for _,group in ipairs({modes,{enabled,map,art}}) do for i,b in ipairs(group) do local _,_,_,_,y=b:GetPoint(1);b:ClearAllPoints();b:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*(bw+13),y);b:SetWidth(bw);b.fieldkitLabel:SetWidth(bw-20);T.Update(b) end end
  elementTitle:SetWidth(w);elementValue:SetWidth(w);sizeNote:SetWidth(w)
  selected:SetWidth(w-96);selected.fieldkitLabel:SetWidth(w-120);following:ClearAllPoints();following:SetPoint("TOPLEFT",page,"TOPLEFT",w-38,-630)
  elementSlider:SetWidth(w-278);elementReset:ClearAllPoints();elementReset:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,-706);elementReset:SetWidth(235)
 end
 table.insert(parent.flow,{frame=page,y=offset})
 return offset+835
end
