-- Rendering only: native action buttons, real unit/XP values and existing detail routes.
FieldKitThemeHUD={saved={},buttons={},tipRows={}}
local H=FieldKitThemeHUD
local T=FieldKitTheme
local slots={1,2,3,4,5,6,12}
local validPoints={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
function H.Points(frame)
 local rows={};local count=frame.GetNumPoints and FieldKit.Number(frame:GetNumPoints(),1,0,8) or 1
 for i=1,count do
  local p,relative,rp,x,y=frame:GetPoint(i)
  if validPoints[p or ""] then
   -- Benilla returns relative frame names; SetPoint requires the frame object.
   if type(relative)=="string" then relative=getglobal(relative) or UIParent end
   table.insert(rows,{p,relative or UIParent,validPoints[rp or ""] and rp or p,FieldKit.Number(x,0),FieldKit.Number(y,0)})
  end
 end
 return rows
end
function H.Hidden()
 if not H.storage then H.storage=CreateFrame("Frame","FieldKitThemeStorage",UIParent);H.storage:Hide() end
 return H.storage
end
function H.Save(frame)
 if not frame or H.saved[frame] then return end
 local points=H.Points(frame)
 H.saved[frame]={parent=frame:GetParent(),points=points,width=frame:GetWidth(),height=frame:GetHeight(),alpha=frame:GetAlpha(),scale=frame.GetScale and frame:GetScale() or 1,mouse=frame.IsMouseEnabled and frame:IsMouseEnabled(),strata=frame.GetFrameStrata and frame:GetFrameStrata(),level=frame.GetFrameLevel and frame:GetFrameLevel()}
end
function H.Anchor(frame,point,relative,rp,x,y,force)
 if not frame or frame.azsMoving or frame.fieldkitHudDragging then return end
 H.Save(frame);if not force and frame.fieldkitThemeRevision==FieldKitZoneThemes.revision then return end
 frame.fieldkitThemeRevision=FieldKitZoneThemes.revision;frame:ClearAllPoints();frame:SetPoint(point,relative,rp,x,y)
end
function H.RestoreOne(f)
 local r=H.saved[f];if not r then return end
 local reparented=f:GetParent()~=r.parent
  f.fieldkitThemeRevision=nil;if f.SetParent then f:SetParent(r.parent) end;
  if r.strata and f.SetFrameStrata then f:SetFrameStrata(r.strata) end
  if r.level and f.SetFrameLevel then f:SetFrameLevel(r.level) end;f:ClearAllPoints()
  for i=1,table.getn(r.points) do local a=r.points[i];f:SetPoint(a[1],a[2],a[3],a[4],a[5]) end
  f:SetWidth(r.width);f:SetHeight(r.height);f:SetAlpha(r.alpha)
  if f.SetScale then f:SetScale(r.scale) end
  if r.mouse~=nil then f:EnableMouse(r.mouse) end
 -- Benilla keeps a native visibility cache after leaving a hidden parent.
 -- Refresh only frames still logically shown; never resurrect a hidden target.
 if reparented and f:IsShown() then f:Hide();f:Show() end
 H.saved[f]=nil
end
function H.Restore()
 for f in pairs(H.saved) do H.RestoreOne(f) end
 H.saved={};H.pinned=false
 for _,f in ipairs({H.dock,H.nav,H.header,H.tip,H.micro}) do if f then f:Hide() end end
end
function H.Tip(owner,title,lines,pinned)
 if H.pinned and not pinned then return end
 if not H.tip then
  local f=CreateFrame("Frame","FieldKitThemeTooltip",UIParent);H.tip=f
  f:SetFrameStrata("TOOLTIP");f:EnableMouse(true);T.Surface(f,"window")
  H.tipTitle=T.Label(f,"",12,8,316,26,16,T.gold,true)
  for i=1,18 do H.tipRows[i]=T.Label(f,"",12,38+(i-1)*36,316,34,12,T.text) end
  T.Button(f,nil,"Close",244,8,84,24,function() H.tip:Hide();H.pinned=false end)
  f:SetScript("OnMouseDown",function() H.pinned=not H.pinned end)
 end
 H.tipTitle:SetText(title or "FieldKit");H.tip:SetWidth(340)
 local count=math.min(18,table.getn(lines or {}))
 local y=38
 for i=1,18 do local row=H.tipRows[i];if i<=count then
  row:SetText(lines[i]);row:SetHeight(140);local height=math.min(140,math.max(22,(row.GetStringHeight and row:GetStringHeight() or math.ceil(string.len(tostring(lines[i]))/40)*17)+6))
  row:ClearAllPoints();row:SetPoint("TOPLEFT",H.tip,"TOPLEFT",12,-y);row:SetHeight(height);y=y+height;row:Show()
 else row:Hide() end end
 H.tip:SetHeight(y+12);T.Update(H.tip);H.tip:ClearAllPoints()
 H.tip:SetPoint("TOPLEFT",owner,"BOTTOMLEFT",0,-6);H.tip:SetClampedToScreen(true)
 H.tipOwner=owner;H.pinned=pinned and true or false;H.tip:Show()
end
function H.HideTip() if H.tip and not H.pinned then H.tip:Hide() end end
function H.ModeTip(owner,pinned)
 local rank=FieldKit.GetHeroicLevel()
 local lines={FieldKit_L("Difficulty screen values"),rank and rank>0 and (FieldKit_L("Heroic").." "..rank) or (rank==0 and FieldKit_L("Normal") or FieldKit_L("Mode not provided"))}
 local data=FieldKitRunMode.chart[rank or -1]
 if data then for _,line in ipairs(FieldKitRunMode.ChartLines(rank)) do table.insert(lines,line) end end
 for i=0,5 do
  if i~=rank then
  local entry=FieldKitRunMode.chart[i]
  local translated={};for _,line in ipairs(entry.lines) do table.insert(translated,FieldKit_L(line)) end
  table.insert(lines,(i==0 and FieldKit_L("Normal") or (FieldKit_L("Heroic").." "..i))..": "..table.concat(translated," / "))
  end
 end
 local affixes=FieldKitRunMode.Affixes();if affixes then table.insert(lines,affixes) end
 table.insert(lines,FieldKit_L("Click to pin; click the panel to unpin."))
 H.Tip(owner,FieldKit_L("Game mode"),lines,pinned)
end
local function Open(kind) FieldKitZoneThemes.Open(kind) end
local function NavButton(parent,key,index)
 local kind=key
 return T.Button(parent,nil,FieldKit_L(key),0,0,96,27,function() Open(kind) end)
end
function H.Create()
 if H.dock then return end
 local dock=CreateFrame("Frame","FieldKitThemeDock",UIParent);H.dock=dock
 dock:SetFrameStrata("MEDIUM");dock:SetWidth(600);dock:SetHeight(150);T.Surface(dock,"card",true)
 H.left=dock:CreateTexture(nil,"ARTWORK");H.right=dock:CreateTexture(nil,"ARTWORK")
 for _,t in ipairs({H.left,H.right}) do t:SetWidth(128);t:SetHeight(128) end
 H.left:SetPoint("BOTTOMRIGHT",dock,"BOTTOMLEFT",20,0);H.right:SetPoint("BOTTOMLEFT",dock,"BOTTOMRIGHT",-20,0)
 H.name=T.Label(dock,"",80,5,420,24,15,T.text,true)
 H.player=CreateFrame("Button",nil,dock);H.player:SetPoint("TOP",dock,"TOP",0,-29);H.player:SetWidth(420);H.player:SetHeight(20)
 H.player:SetFrameLevel(dock:GetFrameLevel()+12);H.player:RegisterForClicks("LeftButtonUp","RightButtonUp")
 H.player:SetScript("OnClick",function()
  local source=getglobal("PlayerFrame");local callback=source and (source:GetScript("OnClick") or source:GetScript("OnMouseUp"))
  if callback then local previous=this;this=source;pcall(callback);this=previous end
 end)
 H.player:SetScript("OnEnter",function()
  H.Tip(this,UnitName("player"),{FieldKit_L("Health")..": "..tostring(UnitHealth("player")).." / "..tostring(UnitHealthMax("player")),FieldKit_L("Shield")..": "..tostring(type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.sh) or "?"),FieldKit_L("Left / right click: native player menu.")})
 end)
 H.player:SetScript("OnLeave",H.HideTip)
 H.resource=CreateFrame("StatusBar",nil,dock);H.resource:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");H.resource:SetStatusBarColor(.65,.15,.18)
 H.resource:SetPoint("TOP",dock,"TOP",0,-58);H.resource:SetWidth(400);H.resource:SetHeight(14)
 local rbg=H.resource:CreateTexture(nil,"BACKGROUND");rbg:SetAllPoints(H.resource);T.Solid(rbg,{.12,.06,.08})
 H.resourceText=T.Label(H.resource,"",0,0,400,14,11,T.text)
 H.resourceText:SetJustifyH("CENTER")
 H.xp=CreateFrame("StatusBar",nil,dock);H.xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");H.xp:SetStatusBarColor(.6,.24,.88)
 local xpbg=H.xp:CreateTexture(nil,"BACKGROUND");xpbg:SetAllPoints(H.xp);T.Solid(xpbg,{.12,.08,.18});H.xp:SetHeight(9);H.xp:SetPoint("BOTTOMLEFT",dock,"BOTTOMLEFT",18,44);H.xp:SetPoint("BOTTOMRIGHT",dock,"BOTTOMRIGHT",-18,44)
 H.xpText=T.Label(dock,"",18,149,560,18,11,T.text)
 H.counters=T.Label(dock,"",18,170,560,18,12,T.gold)
 H.xp:EnableMouse(true)
 H.xp:SetScript("OnEnter",function() H.Tip(this,"XP",{H.xpDetail or "?",FieldKit_L("Click to pin; click the panel to unpin.")}) end)
 H.xp:SetScript("OnLeave",H.HideTip)
 H.xp:SetScript("OnMouseDown",function() H.Tip(this,"XP",{H.xpDetail or "?"},true) end)
 local nav=CreateFrame("Frame","FieldKitThemeNavigation",UIParent);H.nav=nav
 nav:SetWidth(700);nav:SetHeight(30);nav:SetFrameStrata("HIGH")
 for i,key in ipairs({"Damage","Lairs","Accessories","Effects","Stats","Journal","FieldKit"}) do H.buttons[i]=NavButton(nav,key,i) end
 local header=CreateFrame("Frame","FieldKitThemeHeader",UIParent);H.header=header
 header:SetWidth(550);header:SetHeight(48);header:SetFrameStrata("MEDIUM");T.Surface(header,"card",true)
 H.zone=T.Label(header,"",12,2,220,22,16,T.gold,true)
 H.clock=T.Label(header,"",240,2,290,22,14,T.text)
 H.next=T.Label(header,"",240,24,290,22,13,T.gold)
 H.timeline=T.Button(header,nil,"",240,2,290,22,function() Open("Timeline") end)
 H.reminders=T.Button(header,nil,"",240,24,290,22,function() Open("Reminders") end)
 H.clock:Hide();H.next:Hide();H.clock=H.timeline.fieldkitLabel;H.next=H.reminders.fieldkitLabel
 H.mode=T.Button(header,nil,"Game mode",12,25,210,22,function() H.ModeTip(H.mode,true) end)
 H.mode:SetScript("OnEnter",function() H.ModeTip(this,false) end);H.mode:SetScript("OnLeave",H.HideTip)
 local micro=CreateFrame("Frame","FieldKitThemeMicro",nav);H.micro=micro;micro:SetWidth(700);micro:SetHeight(25)
 micro:SetPoint("BOTTOM",nav,"TOP",0,4)
 local names={"CharacterMicroButton","SpellbookMicroButton","TalentMicroButton","QuestLogMicroButton","SocialsMicroButton","MainMenuMicroButton"}
 local labels={"Character","Spells","Talents","Quests","Social","Game menu"}
 for i=1,table.getn(names) do
  local native=getglobal(names[i]);local handler=native and native:GetScript("OnClick")
  if handler then
   local source,callback=native,handler
   local b=T.Button(micro,nil,FieldKit_L(labels[i]),(i-1)*108,0,104,22,function()
    local previous=this;this=source;local ok=pcall(callback);this=previous;return ok
   end)
  end
 end
 for _,frame in ipairs({H.dock,H.nav,H.header}) do FieldKitZoneThemes.Bind(frame) end
end
function H.Update(variant,zone)
 H.Create()
 H.xp:SetStatusBarColor(T.gold[1],T.gold[2],T.gold[3])
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight();local scale=math.min(1,sw/1300)
 if not H.dock.azsMoving then H.dock:SetScale(scale) end
 if not H.nav.azsMoving then H.nav:SetScale(scale) end
 if not H.header.azsMoving then H.header:SetScale(scale) end
 local dock=H.dock;if not dock.azsMoving then dock:SetHeight(190) end
 if variant=="alternative" then FieldKitZoneThemes.Place(dock,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",180,80)
 else FieldKitZoneThemes.Place(dock,"BOTTOM",UIParent,"BOTTOM",0,80) end
 if variant=="alternative" then FieldKitZoneThemes.Place(H.nav,"TOPRIGHT",UIParent,"TOPRIGHT",-18,-20) else FieldKitZoneThemes.Place(H.nav,"BOTTOM",UIParent,"BOTTOM",0,12) end
 for i=1,7 do H.buttons[i]:ClearAllPoints();H.buttons[i]:SetPoint("TOPLEFT",H.nav,"TOPLEFT",(i-1)*99,0) end
 H.micro:ClearAllPoints()
 if variant=="alternative" then H.micro:SetPoint("TOP",H.nav,"BOTTOM",0,-4) else H.micro:SetPoint("BOTTOM",H.nav,"TOP",0,4) end
 if variant=="alternative" then FieldKitZoneThemes.Place(H.header,"TOPLEFT",UIParent,"TOPLEFT",20,-96) else FieldKitZoneThemes.Place(H.header,"TOP",UIParent,"TOP",0,-18) end
 local nativeZone=type(AZS_ZONE)=="table" and AZS_ZONE.zname
 if type(nativeZone)~="string" or nativeZone=="" then
  local key=type(AZS_ZONE)=="table" and AZS_ZONE.zone
  nativeZone=FieldKitZoneRegistry[key or ""] and FieldKit_L(FieldKitZoneRegistry[key].name) or FieldKit_L("Zone not provided")
 end
 H.zone:SetText(FieldKitNative.Text(nativeZone))
 local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase()
 local time=FieldKitNative.Time();H.clock:SetText(time and FieldKitNative.Clock(time) or "—")
 local nextBoss=FieldKitNativeTools.NextBoss();H.next:SetText(nextBoss and (nextBoss.name.." · "..FieldKitNative.Clock(nextBoss.left)) or FieldKit_L("No upcoming boss"))
 local rank=FieldKit.GetHeroicLevel()
 FieldKit_Text(H.mode,(FieldKit.GetHeroicLabel() or FieldKit_L("Mode not provided")).." · ?")
 local level=UnitLevel("player");H.name:SetText((UnitName("player") or "?").." · "..tostring(level or "?"))
 if not FieldKitDB.playerBar then H.name:SetText(UnitName("player") or "?");H.player:Hide() else H.player:Show() end
 local health=getglobal("FieldKitPlayerBar")
 if health and FieldKitDB.playerBar then FieldKitZoneThemes.Place(health,"TOP",dock,"TOP",0,-29);health:SetParent(dock);health:SetFrameStrata("MEDIUM");health:SetFrameLevel(dock:GetFrameLevel()+2);health:SetWidth(420);health:SetHeight(20);health:SetScale(1)
  if health.healthText then H.Anchor(health.healthText,"CENTER",health,"CENTER",0,0) end end
 local boss=getglobal("FieldKitBossFrame1");if boss then FieldKitZoneThemes.Place(boss,"TOPLEFT",UIParent,"TOP",-155,variant=="alternative" and -175 or -114) end
 local buffs=getglobal("FieldKitPlayerBuffs")
 if buffs then FieldKitZoneThemes.Place(buffs,"BOTTOM",dock,"TOP",0,3) end
 for i=1,7 do
  local button=getglobal("ActionButton"..slots[i])
  if button then
   H.Save(button);button:SetParent(dock);button:ClearAllPoints();button:SetPoint("TOPLEFT",dock,"TOPLEFT",84+(i-1)*62,-78)
   button:SetWidth(56);button:SetHeight(56)
  end
 end
 local cur,max=FieldKit.Number(UnitXP("player")),FieldKit.Number(UnitXPMax("player"))
 if max and max>0 and cur then
  H.xp:SetMinMaxValues(0,max);H.xp:SetValue(cur);H.xpText:SetText("XP · "..math.floor(cur/max*100).."%")
  H.xpDetail="XP "..cur.." / "..max.." · "..math.max(0,max-cur).." "..FieldKit_L("remaining")
 else H.xp:SetValue(0);H.xpText:SetText("XP · ?");H.xpDetail=FieldKit_L("Native data unavailable") end
 local proc=type(AZS_RUN)=="table" and AZS_RUN.proc
 local mana=type(UnitMana)=="function" and FieldKit.Number(UnitMana("player"))
 local manaMax=type(UnitManaMax)=="function" and FieldKit.Number(UnitManaMax("player"))
 local procNames={bloodrage="Rage",seal_fate="Combo points",soul_fire="Soul shards",lightwell="Lightwell"}
 if phase and procNames[proc] then mana=FieldKit.Number(AZS_RUN.pv);manaMax=FieldKit.Number(AZS_RUN.pm) end
 if mana and manaMax and manaMax>0 then
  H.resource:SetMinMaxValues(0,manaMax);H.resource:SetValue(mana);H.resource:Show()
  local kind=type(UnitPowerType)=="function" and UnitPowerType("player")
  local names={[0]="Mana",[1]="Rage",[2]="Focus",[3]="Energy"}
  H.resourceText:SetText(FieldKit_L(procNames[proc] or names[kind] or "Resource").." "..mana.." / "..manaMax)
 else H.resource:Hide();H.resourceText:SetText("") end
 local run=type(AZS_RUN)=="table" and AZS_RUN or {}
 if phase then
  H.counters:SetText(FieldKit_L("Kills").." "..tostring(FieldKit.Number(run.kills) or "?").." · "..FieldKit_L("Gold").." "..tostring(FieldKit.Number(run.gold) or "?").." · "..FieldKit_L("Cache price").." "..tostring(FieldKit.Number(run.chest) or "?"))
 else H.counters:SetText(FieldKit_L("No active run data")) end
 if H.artZone~=zone then
 H.artZone=zone
 H.artAccepted=H.left:SetTexture(T.media.."ZoneThemes\\"..zone.."Ornaments512.tga");H.left:SetTexCoord(0,.5,0,1)
 H.right:SetTexture(T.media.."ZoneThemes\\"..zone.."Ornaments512.tga");H.right:SetTexCoord(.5,1,0,1)
 end
 for _,t in ipairs({H.left,H.right}) do
  t:SetWidth(175);t:SetHeight(175)
  if FieldKitDB.zoneThemeArt then t:Show() else t:Hide() end
 end
 for _,name in ipairs({"FieldKitCompactBar","FieldKitMoneyFrame","MainMenuBar","PlayerFrame"}) do
  local f=getglobal(name)
  if f and (name~="PlayerFrame" or (health and FieldKitDB.playerBar)) then H.Save(f);f:SetParent(H.Hidden());f:SetAlpha(0) end
 end
 dock:Show();H.header:Show();H.nav:Show();H.micro:Show()
 T.Update(dock);T.Update(H.header)
end
