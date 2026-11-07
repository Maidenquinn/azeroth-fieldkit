-- Opt-in presentation controller. No native telemetry or saved layouts are copied.
FieldKitZoneThemes={active=false,open={},revision=0}
local C=FieldKitZoneThemes
local H=FieldKitThemeHUD
local T=FieldKitTheme
local routes={Damage={"FieldKitMeterFrame","meterFrame"},Lairs={"FieldKitLairFrame","lairFrame"},
 Accessories={"FieldKitGearFrame","gearFrame"},Effects={"FieldKitEffectsFrame","effectsFrame"},
 Stats={"FieldKitStatsFrame","statsFrame"},Timeline={"FieldKitBossTimelineFrame","bossTimeline"},Reminders={"FieldKitEncounterFrame","nextBossCard"}}
local hidden={"FieldKitModeFrame","FieldKitCollapseDock","FieldKitMicroMenu"}
C.layoutKeys={"elwynn:minimal","elwynn:complete","elwynn:alternative","naxx:minimal","naxx:complete","naxx:alternative"}
C.positionNames={"FieldKitThemeIdentity","FieldKitThemeVitality","FieldKitThemeExperience","FieldKitThemeCounters","FieldKitThemeSchedule","FieldKitThemeDock","FieldKitThemeNavigation","FieldKitThemeHeader","FieldKitThemeMap","FieldKitThemeTargetFrame","FieldKitPlayerBar","FieldKitPlayerBuffs","FieldKitBossFrame1"}
for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do table.insert(C.positionNames,"FieldKitThemeSummary"..kind) end
for _,name in ipairs(FieldKitCardLayout.names) do table.insert(C.positionNames,name) end
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
 if not a or a[2]~=UIParent then return false end
 local value={a[1],a[3],a[4],a[5]}
 if not FieldKitPositions.Valid(value) then return false end
 local all=FieldKitDB.zoneThemePositions
 if type(all)~="table" then all={};FieldKitDB.zoneThemePositions=all end
 if type(all[C.currentLayout])~="table" then all[C.currentLayout]={} end
 all[C.currentLayout][name]=value
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
function C.Resolve()
 if not FieldKitDB or not FieldKitDB.zoneThemes then return nil end
 local key=FieldKitDB.zoneThemeMode
 if key=="auto" then key=type(AZS_ZONE)=="table" and AZS_ZONE.zone end
 if key=="elwynn" or key=="naxx" then return key end
end
function C.Suspend()
 C.NativeRestore()
 if not C.active then return end
 C.active=false;FieldKitThemeTarget.Stop();H.Restore();FieldKitThemeMinimap.Restore()
 local stats=getglobal("FieldKitStatsFrame")
 if stats and stats.fieldkitNaturalHeight then FieldKitCardLayout.Rows(stats,stats.fieldkitNaturalHeight,stats.fieldkitRowCount or 0,"stats",FieldKitDB.statsCollapsed);T.Update(stats) end
 C.open={};C.placed={};C.signature=nil
 T.SetZone("classic")
end
-- Persist only five restoration booleans so a reload cannot forget prior CVars.
function C.NativeRestore()
 local saved=FieldKitDB and FieldKitDB.zoneThemeNativeBefore
 if type(saved)~="table" then return end
 for _,key in ipairs({"clock","tally","build","banners","bosses"}) do
  if type(saved[key])=="boolean" then FieldKit.SetHudShown(key,saved[key]) end
 end
 FieldKitDB.zoneThemeNativeBefore=nil
end
function C.NativeReplace()
 if type(AZS_IsHudShown)~="function" then return end
 if type(FieldKitDB.zoneThemeNativeBefore)~="table" then FieldKitDB.zoneThemeNativeBefore={} end
 local saved=FieldKitDB.zoneThemeNativeBefore
 for _,key in ipairs({"clock","tally","build","bosses"}) do
  if key~="bosses" or type(AZS_UNITS)=="table" then
  if saved[key]==nil then
   local ok,value=pcall(AZS_IsHudShown,key)
   if ok and type(value)=="boolean" then saved[key]=value end
  end
  if type(saved[key])=="boolean" then
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
 if C.statusLabel then
  C.statusLabel:SetText(FieldKit_L(FieldKitDB.zoneThemes and "Enabled" or "Disabled").." · "..FieldKit_L(FieldKitDB.zoneThemeMode).." · "..FieldKit_L(FieldKitDB.zoneThemeVariant).."\n"..FieldKit_L("Square minimap")..": "..FieldKit_L(FieldKitDB.zoneThemeMinimap and "Enabled" or "Disabled").." · "..FieldKit_L("Character ornaments")..": "..FieldKit_L(FieldKitDB.zoneThemeArt and "Enabled" or "Disabled"))
 end
 local zone=C.Resolve()
 if not zone then C.Suspend();T.SetZone("classic");return end
 if FieldKit.layoutEditing or (FieldKitPreview and FieldKitPreview.mode) then C.Suspend();T.SetZone(zone);return end
 local variant=FieldKitDB.zoneThemeVariant
 C.currentLayout=zone..":"..variant
 local signature=zone..variant..UIParent:GetWidth()..":"..UIParent:GetHeight()
 if C.signature~=signature then
  C.Suspend();C.active=true;C.signature=signature;C.revision=C.revision+1;C.placed={}
 end
 C.active=true;T.SetZone(zone)
 -- Yield completely to native choice cards. No writes to card priority or game data.
 if FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen() then
  FieldKitThemeTarget.Stop()
  for _,f in pairs(H.summaries or {}) do f:Hide() end
  for _,f in ipairs({H.dock,H.header,H.nav,H.identity,H.healthRoot,H.xpRoot,H.counterRoot,H.utility,H.micro,H.schedule,H.back}) do f:Hide() end;H.pinned=false;H.HideTip()
  return
 end
 H.Update(variant,zone);FieldKitThemeTarget.Update(variant)
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
   if kind=="Stats" then FieldKitCardLayout.Rows(frame,frame.fieldkitNaturalHeight or frame:GetHeight(),frame.fieldkitRowCount or table.getn(frame.rows),"stats",FieldKitDB.statsCollapsed);T.Update(frame) end
   local right=kind=="Accessories" or kind=="Stats" or (kind=="Effects" and zone=="naxx") or variant=="alternative"
   local y=right and rightY or leftY;local previous=C.placed[frame]
   if not previous or previous.y~=y or previous.height~=frame:GetHeight() then
    C.Place(frame,right and "TOPRIGHT" or "TOPLEFT",UIParent,right and "TOPRIGHT" or "TOPLEFT",right and -20 or 20,y,true)
   end
   if right then rightY=rightY-frame:GetHeight()-14 else leftY=leftY-frame:GetHeight()-14 end
   local record=previous or {};record.y=y;record.height=frame:GetHeight();C.placed[frame]=record
   H.back:ClearAllPoints();H.back:SetPoint("BOTTOMRIGHT",frame,"TOPRIGHT",0,4);H.back:Show();T.Update(H.back)
  end
 end
 H.Summaries(variant,zone)
 for _,name in ipairs(hidden) do C.Mask(getglobal(name),true) end
 -- Keep native target, boss, group, alerts and chat behaviors intact.
 if FieldKitScreenLayers then FieldKitScreenLayers.ApplyChoice() end
end
function C.Tick()
 if type(IsMouseButtonDown)=="function" and not IsMouseButtonDown("LeftButton") then
  for _,frame in ipairs(C.bound or {}) do C.Finish(frame) end
 end
 local now=GetTime()
 if C.deadline and now<C.deadline then return end
 C.deadline=now+.2;C.Refresh()
end
function C.Set(key,value)
 local allowed={zoneThemes=true,zoneThemeMode=true,zoneThemeVariant=true,zoneThemeMinimap=true,zoneThemeArt=true}
 if not allowed[key] then return end
 C.Suspend();FieldKitDB[key]=value
 if FieldKit.ApplyHUDProfileLive then FieldKit.ApplyHUDProfileLive() end
 C.Refresh(true)
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
 C.open[kind]=not C.open[kind]
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
 elseif arg=="off" then C.Set("zoneThemes",false)
 elseif arg=="on" then C.Set("zoneThemes",true)
 elseif arg=="auto" or arg=="elwynn" or arg=="naxx" then C.Set("zoneThemeMode",arg);C.Set("zoneThemes",true)
 elseif arg=="minimal" or arg=="complete" or arg=="alternative" then C.Set("zoneThemeVariant",arg)
 else
  SlashCmdList.FieldKit("");if FieldKitUI.frame then FieldKitUI.Select("look") end
 end
end
function FieldKitThemeUI(parent,offset)
 local page=CreateFrame("Frame",nil,parent);page:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-offset);page:SetHeight(380)
 local title=T.Label(page,"Zone themes",0,0,660,28,20,T.gold,true)
 local note=T.Label(page,"Themes apply to the HUD and all FieldKit settings. Saved positions remain intact.",0,38,660,44,13,T.text)
 C.ui={}
 local function Button(key,value,label,x,y,w)
  local button=T.Button(page,nil,label,x,y,w,30,function()
   if value=="toggle" then C.Set(key,not FieldKitDB[key]) else C.Set(key,value) end
  end)
  table.insert(C.ui,{frame=button,key=key,value=value});return button
 end
 Button("zoneThemes","toggle","Enable / disable themes",0,90,300)
 local modes,variants={},{}
 for i,key in ipairs({"auto","elwynn","naxx"}) do modes[i]=Button("zoneThemeMode",key,FieldKit_L(key),(i-1)*210,132,200) end
 for i,key in ipairs(FieldKitZoneVariants) do variants[i]=Button("zoneThemeVariant",key,FieldKit_L(key),(i-1)*210,174,200) end
 Button("zoneThemeMinimap","toggle","Square minimap",0,216,240)
 Button("zoneThemeArt","toggle","Character ornaments",252,216,240)
 C.statusLabel=T.Label(page,nil,0,258,660,64,13,T.muted)
 page.Reflow=function(w)
  page:SetWidth(w);title:SetWidth(w);note:SetWidth(w);C.statusLabel:SetWidth(w)
  for _,group in ipairs({modes,variants}) do
   local bw=(w-20)/3
   for i,b in ipairs(group) do
    local point,relative,rp,x,y=b:GetPoint(1);b:ClearAllPoints();b:SetPoint("TOPLEFT",page,"TOPLEFT",(i-1)*(bw+10),y)
    b:SetWidth(bw);b.fieldkitLabel:SetWidth(bw-20);T.Update(b)
   end
  end
 end
 table.insert(parent.flow,{frame=page,y=offset})
 T.Button(page,nil,"Reset theme positions",0,326,300,30,function()
  if C.currentLayout then FieldKitDB.zoneThemePositions[C.currentLayout]=nil;C.revision=C.revision+1;C.placed={};C.Refresh(true) end
 end)
 return offset+380
end
