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
 local font;if frame.GetFont and frame.SetFont then local ok,path,size,flags=pcall(frame.GetFont,frame);if ok and path then font={path,size,flags} end end
 local choice=FieldKitScreenLayers and FieldKitScreenLayers.choiceMasked[frame]
 H.saved[frame]={font=font,parent=frame:GetParent(),points=points,width=frame:GetWidth(),height=frame:GetHeight(),alpha=choice and choice.alpha or frame:GetAlpha(),scale=frame.GetScale and frame:GetScale() or 1,mouse=frame.IsMouseEnabled and frame:IsMouseEnabled(),strata=frame.GetFrameStrata and frame:GetFrameStrata(),level=frame.GetFrameLevel and frame:GetFrameLevel()}
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
  if f==getglobal("ChatFrame1") and FieldKit.ResizeChatPreservingHistory then FieldKit.ResizeChatPreservingHistory(r.width,r.height)
  else if f:GetWidth()~=r.width then f:SetWidth(r.width) end;if f:GetHeight()~=r.height then f:SetHeight(r.height) end end;f:SetAlpha(r.alpha)
  if r.font and f.SetFont then if f==getglobal("ChatFrame1") and FieldKit.ThemeChatFont then FieldKit.ThemeChatFont(r.font[1],r.font[2],r.font[3]) else pcall(f.SetFont,f,r.font[1],r.font[2],r.font[3]) end end
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
 for _,f in pairs(H.summaries or {}) do f:Hide() end
 for _,f in ipairs({H.dock,H.nav,H.header,H.tip,H.micro,H.identity,H.healthRoot,H.xpRoot,H.counterRoot,H.utility,H.schedule,H.back}) do if f then f:Hide() end end
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
 local zone=type(AZS_ZONE)=="table" and AZS_ZONE.zname;if type(zone)=="string" then table.insert(lines,1,FieldKitNative.Text(zone)) end
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
 table.insert(lines,FieldKit_L("Click to pin; click the panel to unpin."));table.insert(lines,FieldKit_L("Right click: quick menu and settings."))
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
 H.microButtons={}
 local names={"CharacterMicroButton","SpellbookMicroButton","TalentMicroButton","QuestLogMicroButton","SocialsMicroButton","MainMenuMicroButton"}
 local labels={"Character","Spells","Talents","Quests","Social","Game menu"}
 for i=1,table.getn(names) do
  local native=getglobal(names[i]);local handler=native and native:GetScript("OnClick")
  if handler then
   local source,callback=native,handler
   local b=T.Button(micro,nil,FieldKit_L(labels[i]),(i-1)*108,0,104,22,function()
    local previous=this;this=source;local ok=pcall(callback);this=previous;return ok
   end)
   table.insert(H.microButtons,b)
  end
 end
 for _,frame in ipairs({H.dock,H.nav,H.header}) do FieldKitZoneThemes.Bind(frame) end
end
-- The approved concepts have separate identity, chronology, vitality and action
-- groups. Every group below is live UI; no number is painted into an image.
function H.CompositionCreate()
 if H.identity then return end
 local function Root(name,w,h)
  local f=CreateFrame("Frame",name,UIParent);f:SetWidth(w);f:SetHeight(h);f:SetFrameStrata("MEDIUM");T.Surface(f,"card",true);FieldKitZoneThemes.Bind(f);return f
 end
 H.identity=Root("FieldKitThemeIdentity",270,64)
 H.zone:SetParent(H.identity);H.zone:ClearAllPoints();H.zone:SetPoint("TOPLEFT",H.identity,"TOPLEFT",14,-6);H.zone:SetWidth(244);H.zone:SetHeight(25);T.Font(H.zone,19,T.text,true)
 H.mode:SetParent(H.identity);H.mode:ClearAllPoints();H.mode:SetPoint("BOTTOMLEFT",H.identity,"BOTTOMLEFT",10,6);H.mode:SetWidth(250);T.Update(H.mode)
 H.healthRoot=Root("FieldKitThemeVitality",460,76);H.healthRoot.fieldkitArtOnly=true
 H.namePlate=CreateFrame("Frame",nil,H.healthRoot);H.namePlate:SetWidth(220);H.namePlate:SetHeight(26);H.namePlate:SetPoint("TOP",H.healthRoot,"TOP",0,0);T.Surface(H.namePlate,"card",true)
 H.name:SetParent(H.namePlate);H.name:ClearAllPoints();H.name:SetPoint("CENTER",H.namePlate,"CENTER",0,0);H.name:SetWidth(200);H.name:SetJustifyH("CENTER")
 H.player:SetParent(H.healthRoot);H.player:ClearAllPoints();H.player:SetPoint("TOP",H.healthRoot,"TOP",0,-27);H.player:SetWidth(430);H.player:SetHeight(23)
 T.Surface(H.player,"card",true)
 H.health=CreateFrame("StatusBar",nil,H.player);H.health:SetPoint("TOPLEFT",H.player,"TOPLEFT",6,-4);H.health:SetPoint("BOTTOMRIGHT",H.player,"BOTTOMRIGHT",-6,4);H.health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");H.health:SetStatusBarColor(.12,.76,.18)
 local bg=H.health:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(H.health);T.Solid(bg,{.015,.04,.02})
 H.hp=T.Label(H.health,"",0,0,430,23,14,T.text);H.hp:SetJustifyH("CENTER")
 H.shield=H.health:CreateTexture(nil,"OVERLAY");H.shield:SetPoint("TOPLEFT",H.health,"TOPLEFT",0,0);H.shield:SetHeight(23);T.Solid(H.shield,{.45,.8,1},.5)
 H.resource:SetParent(H.healthRoot);H.resource:ClearAllPoints();H.resource:SetPoint("TOP",H.healthRoot,"TOP",0,-54);H.resource:SetWidth(408);H.resource:SetHeight(14)
 H.xpRoot=Root("FieldKitThemeExperience",560,25)
 H.xp:SetParent(H.xpRoot);H.xp:ClearAllPoints();H.xp:SetPoint("TOPLEFT",H.xpRoot,"TOPLEFT",8,-6);H.xp:SetPoint("BOTTOMRIGHT",H.xpRoot,"BOTTOMRIGHT",-8,6);H.xp:SetHeight(13);H.xp:SetStatusBarColor(.55,.12,.86)
 H.xpText:SetParent(H.xp);H.xpText:ClearAllPoints();H.xpText:SetPoint("CENTER",H.xp,"CENTER",0,0);H.xpText:SetWidth(540);H.xpText:SetHeight(20);H.xpText:SetJustifyH("CENTER");T.Font(H.xpText,12,T.text)
 H.counterRoot=Root("FieldKitThemeCounters",480,29)
 H.counters:SetParent(H.counterRoot);H.counters:ClearAllPoints();H.counters:SetPoint("CENTER",H.counterRoot,"CENTER",0,0);H.counters:SetWidth(456);H.counters:SetJustifyH("CENTER")
 H.header:SetWidth(630);H.header:SetHeight(42)
 H.timeline:ClearAllPoints();H.timeline:SetPoint("TOPLEFT",H.header,"TOPLEFT",10,-7);H.timeline:SetWidth(190);H.timeline:SetHeight(28)
 H.reminders:ClearAllPoints();H.reminders:SetPoint("TOPRIGHT",H.header,"TOPRIGHT",-10,-7);H.reminders:SetWidth(400);H.reminders:SetHeight(28)
 H.clock:SetWidth(170);H.next:SetWidth(380);T.Font(H.clock,16,T.text,true);T.Font(H.next,15,T.text,true)
 H.utility=T.Button(UIParent,"FieldKitThemeUtility","FIELDKIT  +",0,0,130,34,nil)
 -- SetShown is not part of the 11200 contract.
 H.utility.callback=function() if H.micro:IsShown() then H.micro:Hide() else H.micro:Show() end end
 H.utility:SetFrameStrata("HIGH")
 H.back=T.Button(UIParent,"FieldKitThemeBack","Back to HUD",0,0,160,27,function() FieldKitZoneThemes.open={};FieldKitZoneThemes.Refresh(true) end);H.back:SetFrameStrata("DIALOG");H.back:Hide()
 H.micro:SetParent(UIParent);H.micro:SetFrameStrata("DIALOG");H.micro:SetWidth(240);H.micro:SetHeight(290);T.Surface(H.micro,"window")
 local children=H.microButtons;local row=0
 for _,b in ipairs(children) do if b.fieldkitLabel then b:ClearAllPoints();b:SetPoint("TOPLEFT",H.micro,"TOPLEFT",12,-12-row*30);b:SetWidth(216);b.fieldkitLabel:SetWidth(196);T.Update(b);row=row+1 end end
 T.Button(H.micro,nil,"Statistics",12,12+row*30,216,27,function() H.micro:Hide();Open("Stats") end);row=row+1
 T.Button(H.micro,nil,"Journal",12,12+row*30,216,27,function() H.micro:Hide();Open("Journal") end);row=row+1
 T.Button(H.micro,nil,"FieldKit",12,12+row*30,216,27,function() H.micro:Hide();Open("FieldKit") end)
 H.micro:Hide()
 H.schedule=Root("FieldKitThemeSchedule",180,260);H.steps={}
 for i=1,5 do H.steps[i]=T.Button(H.schedule,nil,"",10,12+(i-1)*47,160,39,function() Open("Timeline") end) end
 H.sculpture=H.dock:CreateTexture(nil,"BACKGROUND")
 H.actionRims={}
 for i=1,7 do local f=CreateFrame("Frame",nil,H.dock);f:SetFrameStrata("MEDIUM");f:SetWidth(62);f:SetHeight(62);T.Surface(f,"card",true);H.actionRims[i]=f end
end
local function Place(frame,p,r,rp,x,y)
 FieldKitZoneThemes.Place(frame,p,r,rp,x,y)
end
-- Reference compositions own their geometry. Running the fallback layout first
-- on every 5 Hz update made Benilla briefly reuse its old button clipping boxes
-- and left labels from a previous variant visible beside the new navigation.
function H.ReferenceValues()
 local cur,max=FieldKit.Number(UnitHealth("player")),FieldKit.Number(UnitHealthMax("player"))
 H.name:SetText((UnitName("player") or "?").." · "..tostring(UnitLevel("player") or "?"))
 if cur and max and max>0 then H.health:SetMinMaxValues(0,max);H.health:SetValue(cur);H.hp:SetText(FieldKit_FormatHealth(cur,max,FieldKitDB.playerHealthMode)) else H.hp:SetText("?") end
 local run=type(AZS_RUN)=="table" and AZS_RUN or {};local names={bloodrage="Rage",seal_fate="Combo points",soul_fire="Soul shards",lightwell="Lightwell"}
 local power,pm=FieldKit.Number(run.pv),FieldKit.Number(run.pm)
 if not names[run.proc] or not pm or pm<=0 then power=type(UnitMana)=="function" and FieldKit.Number(UnitMana("player"));pm=type(UnitManaMax)=="function" and FieldKit.Number(UnitManaMax("player")) end
 if power and pm and pm>0 then H.resource:SetMinMaxValues(0,pm);H.resource:SetValue(power);H.resource:Show();H.resourceText:SetText(FieldKit_L(names[run.proc] or ({[0]="Mana",[1]="Rage",[2]="Focus",[3]="Energy"})[type(UnitPowerType)=="function" and UnitPowerType("player")] or "Resource").." "..power.." / "..pm) else H.resource:Hide();H.resourceText:SetText("") end
 local xp,xpn=FieldKit.Number(UnitXP("player")),FieldKit.Number(UnitXPMax("player"))
 if xp and xpn and xpn>0 then H.xp:SetMinMaxValues(0,xpn);H.xp:SetValue(xp);H.xpText:SetText("XP · "..math.floor(xp/xpn*100).."%");H.xpDetail="XP "..xp.." / "..xpn.." · "..math.max(0,xpn-xp).." "..FieldKit_L("remaining") else H.xp:SetValue(0);H.xpText:SetText("XP · ?");H.xpDetail=FieldKit_L("Native data unavailable") end
 local nativeZone=type(AZS_ZONE)=="table" and AZS_ZONE.zname;local key=type(AZS_ZONE)=="table" and AZS_ZONE.zone
 if type(nativeZone)~="string" or nativeZone=="" then nativeZone=FieldKitZoneRegistry[key or ""] and FieldKit_L(FieldKitZoneRegistry[key].name) or FieldKit_L("Zone not provided") end
 H.zone:SetText(FieldKitNative.Text(nativeZone));H.clock:SetText(FieldKitNative.Clock(FieldKitNative.Time()));local boss=FieldKitNativeTools.NextBoss();H.next:SetText(boss and boss.name.." · "..FieldKitNative.Clock(boss.left) or FieldKit_L("No upcoming boss"))
 for _,slot in ipairs(slots) do local b=getglobal("ActionButton"..slot);H.Save(b)
  -- Native Rejouer/reload can recreate the build while our persisted native
  -- visibility override is active. Its transient alpha must not become the
  -- restored alpha when the user's original build was visible.
  if b and H.saved[b] and H.saved[b].alpha==0 and FieldKitDB.zoneThemeNativeBefore and FieldKitDB.zoneThemeNativeBefore.build==true then H.saved[b].alpha=1 end
 end
 for _,name in ipairs({"FieldKitCompactBar","FieldKitMoneyFrame","MainMenuBar","PlayerFrame","FieldKitPlayerBar"}) do FieldKitZoneThemes.Mask(getglobal(name),true) end
 local boss=getglobal("FieldKitBossFrame1");if boss then FieldKitZoneThemes.Place(boss,"TOP",UIParent,"TOP",0,-90/FieldKitZoneThemes.ElementScale("FieldKitThemeBosses"),true) end
end
function H.Update(variant,zone)
 H.Create();H.CompositionCreate()
 if FieldKitReferenceHUD and FieldKitReferenceHUD.Has(zone,variant) then H.ReferenceValues();return end
 local c=FieldKitZoneThemes;local sw=UIParent:GetWidth();local scale=math.min(1,sw/1600)
 for _,f in ipairs({H.dock,H.nav,H.header,H.identity,H.healthRoot,H.counterRoot,H.utility,H.schedule,H.micro}) do if not f.azsMoving then f:SetScale(scale) end end
 H.dock:SetWidth(500);H.dock:SetHeight(88)
 local alternative=variant=="alternative";local complete=variant=="complete"
 if alternative and zone=="elwynn" then Place(H.dock,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",300,70)
 elseif alternative then Place(H.dock,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-230,82)
 else Place(H.dock,"BOTTOM",UIParent,"BOTTOM",0,68) end
 for i=1,7 do
  local x=16+(i-1)*67;local rim=H.actionRims[i];rim:ClearAllPoints();rim:SetPoint("TOPLEFT",H.dock,"TOPLEFT",x,-10)
  local button=getglobal("ActionButton"..slots[i])
  if button then H.Save(button);button:SetParent(H.dock);button:ClearAllPoints();button:SetPoint("TOPLEFT",H.dock,"TOPLEFT",x+5,-15);button:SetWidth(52);button:SetHeight(52);button:SetFrameLevel(H.dock:GetFrameLevel()+4) end
 end
 if complete and zone=="elwynn" then Place(H.healthRoot,"TOPRIGHT",UIParent,"TOPRIGHT",-22,-20)
 elseif alternative and zone=="naxx" then Place(H.healthRoot,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",28,85)
 else Place(H.healthRoot,"BOTTOM",H.dock,"TOP",0,5) end
 local level=UnitLevel("player");H.name:SetText((UnitName("player") or "?").." · "..tostring(level or "?"))
 local cur,max=FieldKit.Number(UnitHealth("player")),FieldKit.Number(UnitHealthMax("player"))
 if cur and max and max>0 then H.health:SetMinMaxValues(0,max);H.health:SetValue(cur);H.hp:SetText(FieldKit_FormatHealth(cur,max,FieldKitDB.playerHealthMode)) else H.hp:SetText("?") end
 local shield=FieldKitDB.playerShield and type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.sh) or 0
 if shield and shield>0 and max and max>0 then H.shield:SetWidth(430*math.min(shield/max,1));H.shield:Show() else H.shield:Hide() end
 local run=type(AZS_RUN)=="table" and AZS_RUN or {};local proc=run.proc
 local names={bloodrage="Rage",seal_fate="Combo points",soul_fire="Soul shards",lightwell="Lightwell"}
 local power=FieldKit.Number(run.pv);local pm=FieldKit.Number(run.pm)
 if not names[proc] or not pm or pm<=0 then power=type(UnitMana)=="function" and FieldKit.Number(UnitMana("player"));pm=type(UnitManaMax)=="function" and FieldKit.Number(UnitManaMax("player")) end
 if power and pm and pm>0 then H.resource:SetMinMaxValues(0,pm);H.resource:SetValue(power);H.resource:Show();H.resourceText:SetText(FieldKit_L(names[proc] or ({[0]="Mana",[1]="Rage",[2]="Focus",[3]="Energy"})[type(UnitPowerType)=="function" and UnitPowerType("player")] or "Resource").." "..power.." / "..pm) else H.resource:Hide();H.resourceText:SetText("") end
 H.xpRoot:SetScale(alternative and 1 or scale);H.xpRoot:SetWidth(alternative and sw-40 or 560)
 if alternative then Place(H.xpRoot,zone=="elwynn" and "TOP" or "BOTTOM",UIParent,zone=="elwynn" and "TOP" or "BOTTOM",0,zone=="elwynn" and -6 or 14)
 elseif complete and zone=="elwynn" then Place(H.xpRoot,"BOTTOM",H.dock,"TOP",0,8)
 else Place(H.xpRoot,"TOP",H.dock,"BOTTOM",0,-2) end
 local xp,xpn=FieldKit.Number(UnitXP("player")),FieldKit.Number(UnitXPMax("player"))
 if xp and xpn and xpn>0 then H.xp:SetMinMaxValues(0,xpn);H.xp:SetValue(xp);H.xpText:SetText("XP · "..math.floor(xp/xpn*100).."%");H.xpDetail="XP "..xp.." / "..xpn.." · "..math.max(0,xpn-xp).." "..FieldKit_L("remaining") else H.xp:SetValue(0);H.xpText:SetText("XP · ?");H.xpDetail=FieldKit_L("Native data unavailable") end
 if alternative and zone=="naxx" then Place(H.counterRoot,"BOTTOM",H.dock,"TOP",0,5)
 elseif complete and zone=="naxx" then Place(H.counterRoot,"BOTTOM",H.healthRoot,"TOP",0,4)
 elseif complete then Place(H.counterRoot,"TOP",H.dock,"BOTTOM",0,-3)
 else Place(H.counterRoot,"TOP",alternative and H.dock or H.xpRoot,"BOTTOM",0,-3) end
 H.counters:SetText(FieldKit_L("Kills").." "..tostring(FieldKit.Number(run.kills) or "?").."   ·   "..FieldKit_L("Gold").." "..tostring(FieldKit.Number(run.gold) or "?").."   ·   "..FieldKit_L("Cache price").." "..tostring(FieldKit.Number(run.chest) or "?"))
 local mapCaption=(complete and zone=="elwynn") or (alternative and zone=="naxx")
 Place(H.identity,"TOPLEFT",UIParent,"TOPLEFT",22,mapCaption and -272 or (alternative and -42 or -18))
 local nativeZone=type(AZS_ZONE)=="table" and AZS_ZONE.zname;local key=type(AZS_ZONE)=="table" and AZS_ZONE.zone
 if type(nativeZone)~="string" or nativeZone=="" then nativeZone=FieldKitZoneRegistry[key or ""] and FieldKit_L(FieldKitZoneRegistry[key].name) or FieldKit_L("Zone not provided") end
 H.zone:SetText(FieldKitNative.Text(nativeZone));FieldKit_Text(H.mode,(FieldKit.GetHeroicLabel() or FieldKit_L("Mode not provided")).."   ·   "..FieldKit_L("Game mode"))
 local time=FieldKitNative.Time();H.clock:SetText(FieldKitNative.Clock(time));local nextBoss=FieldKitNativeTools.NextBoss();H.next:SetText(nextBoss and nextBoss.name.." · "..FieldKitNative.Clock(nextBoss.left) or FieldKit_L("No upcoming boss"))
 H.header:SetWidth(alternative and 360 or 630)
 if alternative and zone=="elwynn" then Place(H.header,"TOPLEFT",UIParent,"TOPLEFT",22,-130)
 elseif alternative then Place(H.header,"TOPRIGHT",UIParent,"TOPRIGHT",-24,-110) else Place(H.header,"TOP",UIParent,"TOP",0,-16) end
 H.header:SetWidth(alternative and 360 or 630);H.timeline:SetWidth(alternative and 100 or 190);H.reminders:SetWidth(alternative and 240 or 400);H.clock:SetWidth(alternative and 90 or 170);H.next:SetWidth(alternative and 220 or 380)
 H.timeline:ClearAllPoints();H.timeline:SetPoint("TOPLEFT",H.header,"TOPLEFT",10,-7);H.reminders:ClearAllPoints();H.reminders:SetPoint("TOPRIGHT",H.header,"TOPRIGHT",-10,-7);T.Update(H.timeline);T.Update(H.reminders)
 H.schedule:Hide()
 if alternative then
  if zone=="elwynn" then Place(H.schedule,"TOPLEFT",UIParent,"TOPLEFT",22,-180)
  else Place(H.schedule,"TOPRIGHT",UIParent,"TOPRIGHT",-24,-165) end
  local upcoming=FieldKitNative.Read("AZS_GetUpcomingBosses") or {}
  local skip=nextBoss and upcoming[1] and upcoming[1].name==nextBoss.name and 1 or 0
  for i=1,5 do local e=upcoming[i+skip];local b=H.steps[i];if type(e)=="table" then b.fieldkitLabel:SetText(tostring(e.index or (i+skip)).."  "..FieldKitNative.Text(e.name).."\n    "..FieldKitNative.Clock(e.left or (e.at and time and math.max(0,e.at-time))));b:Show() else b:Hide() end end
  if table.getn(upcoming)>skip then H.schedule:Show() end
 end
 if H.artZone~=zone then H.artZone=zone;H.artAccepted=H.sculpture:SetTexture(T.media.."ZoneThemes\\"..zone.."Dock512.tga") end
 H.left:Hide();H.right:Hide()
 H.sculpture:ClearAllPoints();H.sculpture:SetPoint("TOPLEFT",H.dock,"TOPLEFT",zone=="elwynn" and -170 or -200,zone=="elwynn" and 246 or 255);H.sculpture:SetWidth(zone=="elwynn" and 840 or 900);H.sculpture:SetHeight(zone=="elwynn" and 420 or 450)
 if FieldKitDB.zoneThemeArt then H.sculpture:Show() else H.sculpture:Hide() end
 H.dock.fieldkitArtOnly=FieldKitDB.zoneThemeArt;H.xpRoot.fieldkitArtOnly=FieldKitDB.zoneThemeArt and not alternative
 T.State(H.dock,false);T.State(H.healthRoot,false);T.State(H.xpRoot,false)
 -- Secondary native menus remain one click away, rather than a second permanent row.
 H.utility:ClearAllPoints();H.utility:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",18,20)
 H.micro:ClearAllPoints();H.micro:SetPoint("BOTTOMLEFT",H.utility,"TOPLEFT",0,6)
 H.nav:SetWidth(alternative and zone=="elwynn" and 700 or 440);H.nav:SetHeight(alternative and zone=="naxx" and 220 or 30)
 if alternative and zone=="naxx" then Place(H.nav,"TOPLEFT",UIParent,"TOPLEFT",22,-350)
 elseif alternative then Place(H.nav,"TOPRIGHT",UIParent,"TOPRIGHT",-20,-45)
 else Place(H.nav,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-18,48) end
 for i=1,7 do local b=H.buttons[i];local show=i<=4 or alternative and zone=="elwynn";b:ClearAllPoints()
  if alternative and zone=="naxx" then b:SetPoint("TOPLEFT",H.nav,"TOPLEFT",0,-(i-1)*48);b:SetWidth(160)
  else b:SetPoint("TOPLEFT",H.nav,"TOPLEFT",(i-1)*(alternative and 96 or 110),0);b:SetWidth(alternative and 92 or 106) end
  b.fieldkitLabel:SetWidth(b:GetWidth()-20);T.Update(b);if show then b:Show() else b:Hide() end
 end
 -- Compact the existing scrollable chat; all history and copy remain native.
 local chat=getglobal("ChatFrame1")
 if chat then
  H.Anchor(chat,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",54,64)
  if FieldKit.ResizeChatPreservingHistory then FieldKit.ResizeChatPreservingHistory(320,66) end
  if alternative and zone=="elwynn" then H.Anchor(chat,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-64,342,true)
  elseif alternative then H.Anchor(chat,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",54,206,true) end
 end
 local health=getglobal("FieldKitPlayerBar")
 for _,name in ipairs({"FieldKitCompactBar","FieldKitMoneyFrame","MainMenuBar","PlayerFrame","FieldKitPlayerBar"}) do local f=getglobal(name);if f then c.Mask(f,true) end end
 local buffs=getglobal("FieldKitPlayerBuffs");if buffs then Place(buffs,"BOTTOM",H.healthRoot,"TOP",0,4) end
 local boss=getglobal("FieldKitBossFrame1");if boss then Place(boss,"TOP",UIParent,"TOP",0,-90) end
 for _,f in ipairs({H.dock,H.header,H.identity,H.healthRoot,H.xpRoot,H.counterRoot,H.nav,H.utility}) do f:Show();T.Update(f) end
end

-- Compact, readable summaries project the existing view models; full tables,
-- gear tooltips and every category remain available through their detail route.
local summaryDefs={{"Damage","FieldKitMeterFrame","meterFrame"},{"Lairs","FieldKitLairFrame","lairFrame"},{"Accessories","FieldKitGearFrame","gearFrame"},{"Stats","FieldKitStatsFrame","statsFrame"},{"Effects","FieldKitEffectsFrame","effectsFrame"}}
function H.Summaries(variant,zone)
 H.summaries=H.summaries or {}
 local detail=false;for _,def in ipairs(summaryDefs) do if FieldKitZoneThemes.open[def[1]] then detail=true end end
 local left=(zone=="elwynn" and -354 or -110);local right=(zone=="naxx" and -312 or -116)
 for _,def in ipairs(summaryDefs) do
  local kind,source,pref=def[1],getglobal(def[2]),def[3]
  local f=H.summaries[kind]
  if not f then
   f=CreateFrame("Frame","FieldKitThemeSummary"..kind,UIParent);H.summaries[kind]=f
   f:SetWidth(310);f:SetFrameStrata("MEDIUM");T.Surface(f,"card",true);FieldKitZoneThemes.Bind(f)
   f.title=T.Label(f,kind,16,9,266,24,16,T.gold,true)
   f.rows={}
   for i=1,5 do
    local row={};f.rows[i]=row
    row.label=T.Label(f,"",16,40+(i-1)*31,160,26,13,T.text)
    row.value=T.Label(f,"",178,40+(i-1)*31,114,26,13,T.gold);row.value:SetJustifyH("RIGHT")
   end
   local route=kind
   f.more=T.Button(f,nil,"Full details",14,0,282,25,function() Open(route) end)
  end
  f:Hide()
  if variant=="complete" and not detail and source and FieldKitDB[pref] and not FieldKitZoneThemes.open[kind] then
   local count=0
   local rows=source.fieldkitLayoutRows or source.rows or source.slots or {}
   FieldKit_Text(f.title,kind=="Accessories" and FieldKitDB.loadoutTab==2 and "Spells" or kind)
   if kind=="Damage" then local view,index=FieldKitMeterSuite.View();rows=FieldKitMeterLedger.Read(view) or {};FieldKit_Text(f.title,FieldKitMeterLedger.labels[index] or kind) end
   for _,entry in ipairs(rows) do
    local label=entry.label
    if kind=="Damage" and count<4 then
     count=count+1;local r=f.rows[count];r.label:SetText(entry.name or "?");r.value:SetText(entry.dps and string.format("%.0f %s",entry.dps,FieldKit_L("dps")) or (entry.dmg and tostring(entry.dmg) or "?"));r.label:Show();r.value:Show()
    elseif label and label:IsShown() and (not entry.IsShown or entry:IsShown()) and count<5 then
     count=count+1;local r=f.rows[count];r.label:SetText(label:GetText() or "?")
     local value=entry.value and entry.value:GetText() or ""
     if entry.dist then value=value.."  "..(entry.dist:GetText() or "") end
     r.value:SetText(value);r.label:Show();r.value:Show()
    end
   end
   if count==0 then count=1;f.rows[1].label:SetText(FieldKit_L("No data yet"));f.rows[1].value:SetText("");f.rows[1].label:Show();f.rows[1].value:Show() end
   for i=count+1,5 do f.rows[i].label:Hide();f.rows[i].value:Hide() end
   local height=80+count*31;f:SetHeight(height)
   f.more:ClearAllPoints();f.more:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",14,12)
   local onRight=kind=="Accessories" or kind=="Stats" or kind=="Effects"
   FieldKitZoneThemes.Place(f,onRight and "TOPRIGHT" or "TOPLEFT",UIParent,onRight and "TOPRIGHT" or "TOPLEFT",onRight and -22 or 22,onRight and right or left,true)
   if onRight then right=right-height-12 else left=left-height-12 end
   f:SetScale(math.min(1,UIParent:GetWidth()/1600));f:Show();T.Update(f)
  end
 end
end
