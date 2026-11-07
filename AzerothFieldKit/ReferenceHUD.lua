-- Live widgets inside the approved artwork's measured component rectangles.
-- No scene, text, action icon, map or filled gauge is baked into the skin.
FieldKitReferenceHUD={frames={},color={.96,.92,.81},body={.96,.95,.90}}
local R=FieldKitReferenceHUD
local H=FieldKitThemeHUD
local T=FieldKitTheme
local slots={1,2,3,4,5,6,12}
local function Short(n) if not n then return "?" end;if math.abs(n)>=1000000 then return string.format("%.1f m",n/1000000) elseif math.abs(n)>=1000 then return string.format("%.1f k",n/1000) else return string.format("%.0f",n) end end
function R.Has(zone,variant) return FieldKitReferenceArt[zone.."_"..variant]~=nil end
local function Blank(frame)
 frame.fieldkitArtOnly=true;T.State(frame,false)
end
local function Frame(name)
 local f=CreateFrame("Frame",name,UIParent);f:SetFrameStrata("MEDIUM");f:Hide();FieldKitZoneThemes.Bind(f);return f
end
local function NativeHandler(f)
 if not f or not f.GetScript then return end
 for _,event in ipairs({"OnClick","OnMouseUp"}) do local ok,fn=pcall(f.GetScript,f,event);if ok and type(fn)=="function" then return fn end end
end
function R.Create()
 if R.canvas then return end
 R.canvas=CreateFrame("Frame","FieldKitReferenceCanvas",UIParent);R.canvas:SetFrameStrata("MEDIUM");R.canvas:Hide()
 for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local f=Frame("FieldKitReferencePanel"..kind);R.frames[kind]=f
  f.title=T.Label(f,nil,0,0,300,30,21,R.color,true)
  f.total=T.Label(f,nil,0,0,300,30,16,R.body)
  f.rows={}
  for i=1,5 do
   local row=CreateFrame("Button",nil,f);f.rows[i]=row;row:SetWidth(300);row:SetHeight(34)
   row.label=T.Label(row,nil,0,0,210,28,17,R.body);pcall(row.label.SetFont,row.label,T.media.."NotoSerif-Regular.ttf",17,"")
   row.value=T.Label(row,nil,212,0,78,28,17,R.body);row.value:SetJustifyH("RIGHT")
   row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(26);row.icon:SetHeight(26)
   row.bar=CreateFrame("StatusBar",nil,row);row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");row.bar:SetMinMaxValues(0,1);row.bar:SetHeight(8)
   row.bar:SetFrameLevel(row:GetFrameLevel()+1)
   row:SetScript("OnEnter",function() if this.entry and FieldKitLoadout then FieldKitLoadout.Tip(this,this.entry) end end)
   row:SetScript("OnLeave",function() GameTooltip:Hide() end)
   local route=kind;row:SetScript("OnClick",function() FieldKitZoneThemes.Open(route) end)
  end
  local route=kind
  f:EnableMouse(true)
  local start=f:GetScript("OnDragStart");local finish=f:GetScript("OnMouseUp")
  f:SetScript("OnMouseDown",function() this.referenceDragged=false end)
  f:SetScript("OnDragStart",function() this.referenceDragged=true;if start then start() end end)
  f:SetScript("OnMouseUp",function() local moved=this.referenceDragged;if finish then finish() end;if not moved then FieldKitZoneThemes.Open(route) end end)
  f.more=T.Button(f,nil,"",0,0,300,28,function() FieldKitZoneThemes.Open(route) end);Blank(f.more)
 end
 R.counts={};R.counterButtons={}
 for i=1,3 do
  R.counts[i]=T.Label(H.counterRoot,nil,0,0,150,27,18,R.color,true)
  local b=CreateFrame("Button",nil,H.counterRoot);local index=i;R.counterButtons[i]=b
  b:SetScript("OnEnter",function() H.Tip(this,FieldKit_L(({"Kills","Gold","Chest price"})[index]),{R.counterValues and R.counterValues[index] or "?"}) end)
  b:SetScript("OnLeave",H.HideTip);b:SetScript("OnClick",function() H.Tip(this,FieldKit_L(({"Kills","Gold","Chest price"})[index]),{R.counterValues and R.counterValues[index] or "?"},true) end)
 end
 R.stored=T.Button(R.canvas,"FieldKitReferenceStoredLevels","",0,0,240,30,function() if type(AZS_OpenStoredLevels)=="function" then pcall(AZS_OpenStoredLevels) end end);R.stored:SetFrameStrata("HIGH");R.stored:Hide()
 R.portrait=H.healthRoot:CreateTexture(nil,"ARTWORK")
 local playerEnter=H.player:GetScript("OnEnter")
 H.player:SetScript("OnEnter",function() if playerEnter then playerEnter() end;R.Buffs(true) end)
 R.heroic=T.Label(H.identity,nil,0,0,240,28,17,R.body,true)
 R.level=T.Label(H.healthRoot,nil,0,0,60,50,30,R.body,true)
 R.rate=T.Label(R.canvas,nil,0,0,180,30,20,R.body,true)
 R.xpArt=Frame("FieldKitReferenceXP");R.xpBadge=Frame("FieldKitReferenceXPBadge")
 R.footer=T.Label(R.canvas,nil,0,0,330,22,11,{.61,.62,.55})
 H.micro:SetWidth(240);H.micro:SetHeight(420);H.micro:SetClampedToScreen(true)
 local world=getglobal("MiniMapWorldMapButton");local worldClick=NativeHandler(world);R.worldClick=worldClick
 if worldClick then T.Button(H.micro,nil,"World map",12,282,216,26,function() H.micro:Hide();local old=this;this=world;pcall(worldClick);this=old end) end
 local queue=getglobal("MiniMapBattlefieldFrame");local handler=NativeHandler(queue);R.queueClick=handler
 if handler then T.Button(H.micro,nil,"Battlefield",12,312,216,26,function() H.micro:Hide();local old=this;this=queue;pcall(handler);this=old end) end
 T.Button(H.micro,nil,"Native meter",12,342,216,26,function() H.micro:Hide();FieldKitZoneThemes.ToggleNativeMeter() end)
 R.extensionTitle=T.Label(H.micro,"Extensions",12,373,96,22,12,T.muted)
 for _,b in ipairs(H.microButtons) do local callback=b.callback;b.callback=function() H.micro:Hide();if callback then callback() end end end
 R.tabs={}
 for i,key in ipairs(FieldKitMeterLedger.views) do
  local view=key
  local b=T.Button(R.frames.Damage,nil,({"Damage","Healing","Boss","Taken","Groups","Kills short"})[i],0,0,54,30,function() FieldKitMeterSuite.SetView(view);FieldKitZoneThemes.Refresh(true) end)
  Blank(b);R.tabs[i]=b
 end
end
-- The canvas is fitted once to the viewport. Everything shares its scale.
function R.Geometry(frame,rect)
 if not rect or frame.azsMoving then return end
 frame:SetParent(R.canvas);frame:SetAlpha(1);frame:SetFrameLevel(R.canvas:GetFrameLevel()+2);frame:SetScale(1);frame:SetWidth(rect[3]);frame:SetHeight(rect[4])
 FieldKitZoneThemes.Place(frame,"TOPLEFT",R.canvas,"TOPLEFT",rect[1],-rect[2],true)
 frame.referenceRect=rect
end
function R.Child(frame,parent,rect)
 if not rect then frame:Hide();return end
 frame:SetParent(parent);if frame.SetAlpha then frame:SetAlpha(1) end;if frame.SetFrameLevel then frame:SetFrameLevel(parent:GetFrameLevel()+2) end;if frame.SetScale then frame:SetScale(1) end;frame:ClearAllPoints()
 local p=parent.referenceRect or {0,0}
 frame:SetWidth(rect[3]);frame:SetHeight(rect[4]);frame:SetPoint("TOPLEFT",parent,"TOPLEFT",rect[1]-p[1],p[2]-rect[2]);frame:Show()
 frame.referenceRect=rect
end
function R.Art(frame,component,layout)
 local tiles=(layout or R.layout).tiles[component]
 if component=="dock" and not FieldKitDB.zoneThemeArt then tiles=nil end
 if not tiles then for _,t in ipairs(frame.referenceTiles or {}) do t:Hide() end;return end
 frame.referenceTiles=frame.referenceTiles or {}
 for i=1,math.max(table.getn(tiles),table.getn(frame.referenceTiles)) do
  local t=frame.referenceTiles[i]
  if not t then t=frame:CreateTexture(nil,"BACKGROUND");frame.referenceTiles[i]=t end
  local a=tiles[i]
  if a then
   local asset=T.media.."ReferenceHUD\\"..a[1]
   if t.referenceAsset~=asset then t:SetTexture(asset);t.referenceAsset=asset end
   t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",a[2],-a[3]);t:SetWidth(a[4]);t:SetHeight(a[5]);t:SetTexCoord(0,a[4]/a[6],0,a[5]/a[7]);t:SetAlpha((component=="Damage" or component=="Lairs" or component=="Accessories" or component=="Stats" or component=="Effects" or component=="chat") and FieldKit.Number(FieldKitDB.cardOpacity,100,30,100)/100 or 1);t:Show()
  else t:Hide() end
 end
end
local function Label(label,parent,rect,size,heading,justify)
 R.Child(label,parent,rect);T.Font(label,size,R.body,heading);label:SetJustifyH(justify or "LEFT")
end
local function Button(button,parent,rect)
 R.Child(button,parent,rect);button:SetFrameLevel(parent:GetFrameLevel()+20);Blank(button)
end
function R.Stop()
 R.active=false
 if R.canvas then R.canvas:Hide() end
 if R.buffDrawer then R.buffDrawer:Hide() end
 -- Benilla caches native status bars independently of a hidden ancestor.
 for _,f in ipairs({H.health,H.resource,H.xp,R.xpArt,R.xpBadge,H.utility}) do if f then f:Hide() end end
 for _,f in ipairs({H.identity,H.header,H.healthRoot,H.dock,H.nav,R.xpArt,R.xpBadge,H.utility}) do if f then for _,t in ipairs(f.referenceTiles or {}) do t:Hide() end end end
end
function R.Update(variant,zone)
 local key=zone.."_"..variant;local d=FieldKitReferenceArt[key]
 if not d then R.Stop();return end
 R.Create();R.active=true;R.layout=d;R.key=key;H.health:Show();H.xp:Show()
 local scale=math.min(UIParent:GetWidth()/d.size[1],UIParent:GetHeight()/d.size[2])
 R.canvas:SetAlpha(1);R.canvas:SetWidth(d.size[1]);R.canvas:SetHeight(d.size[2]);local inherited=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1;R.canvas:SetScale(scale/math.max(.1,inherited)*(FieldKit.Number(FieldKitDB.zoneThemeScale,100,75,110)/100));R.canvas:ClearAllPoints();R.canvas:SetPoint("CENTER",UIParent,"CENTER",0,0);R.canvas:Show()
 for _,entry in ipairs({{H.identity,"identity"},{H.header,"header"},{H.healthRoot,"vitality"},{H.dock,"dock"},{H.nav,"nav"}}) do
  if d.rects[entry[2]] then R.Geometry(entry[1],d.rects[entry[2]]);Blank(entry[1]);if entry[2]~="vitality" or not d.integratedVitals then R.Art(entry[1],entry[2]) else R.Art(entry[1],"none") end;entry[1]:Show() else entry[1]:Hide() end
 end
 if d.integratedVitals then R.Child(H.healthRoot,H.dock,d.rects.vitality);H.healthRoot:EnableMouse(false) else H.healthRoot:EnableMouse(true) end
 H.sculpture:Hide();H.left:Hide();H.right:Hide();H.namePlate:Hide();H.schedule:Hide()
 for _,rim in ipairs(H.actionRims) do rim:Hide() end
 Label(H.zone,H.identity,d.zone,variant=="complete" and 23 or 20,true,"CENTER")
 local textWidth=H.zone.GetStringWidth and tonumber(H.zone:GetStringWidth());local fontSize=variant=="complete" and 23 or 20
 if textWidth and textWidth>d.zone[3] then pcall(H.zone.SetFont,H.zone,T.media.."AzerothSerif.ttf",math.max(14,fontSize*d.zone[3]/textWidth),"") end
 Button(H.mode,H.identity,d.mode);Label(H.mode.fieldkitLabel,H.identity,d.mode,17,true,"CENTER")
 if d.heroic then Label(R.heroic,H.identity,d.heroic,19,true);R.heroic:SetText((FieldKit.GetHeroicLabel() or "?")..(variant=="alternative" and " · "..FieldKit_L("Mode") or ""));H.mode.fieldkitLabel:SetText(variant=="alternative" and "" or FieldKit_L("Mode"));if variant=="alternative" then pcall(R.heroic.SetFont,R.heroic,T.media.."NotoSerif-Regular.ttf",18,"") end
 else R.heroic:Hide();H.mode.fieldkitLabel:SetText((FieldKit.GetHeroicLabel() or "?")..(zone=="elwynn" and " · "..FieldKit_L("Mode") or "")) end
 H.mode:SetScript("OnEnter",function() if not H.micro:IsShown() then H.ModeTip(this,false) end end);H.mode:RegisterForClicks("LeftButtonUp","RightButtonUp");H.mode.callback=function() if arg1=="RightButton" then H.pinned=false;H.HideTip(); if H.micro:IsShown() then H.micro:Hide() else H.micro:Show() end else H.ModeTip(H.mode,true) end end
 Button(H.timeline,H.header,d.clock);Label(H.clock,H.header,d.clock,25,true)
 Button(H.reminders,H.header,d.next);Label(H.next,H.header,d.next,d.nextSize or 23,true)
 local nextWidth=H.next.GetStringWidth and tonumber(H.next:GetStringWidth())
 if nextWidth and nextWidth>d.next[3] and not (zone=="naxx" and variant=="alternative") then pcall(H.next.SetFont,H.next,T.media.."AzerothSerif.ttf",math.max(12,(d.nextSize or 23)*d.next[3]/nextWidth),"") end
 if zone=="naxx" and variant=="minimal" then
  local b=FieldKitNativeTools.NextBoss();H.clock:SetText(FieldKit_L("Elapsed time").." : "..FieldKitNative.Clock(FieldKitNative.Time()));H.next:SetText(b and FieldKit_L("Next").." : "..b.name.." · "..FieldKitNative.Clock(b.left) or FieldKit_L("No upcoming boss"));pcall(H.clock.SetFont,H.clock,T.media.."NotoSerif-Regular.ttf",20,"");pcall(H.next.SetFont,H.next,T.media.."NotoSerif-Regular.ttf",20,"")
 end
 if d.steps then
  local upcoming=FieldKitNative.Read("AZS_GetUpcomingBosses") or {}
  H.schedule:SetParent(H.header);H.schedule:SetScale(1);H.schedule:ClearAllPoints();H.schedule:SetPoint("TOPLEFT",H.header,"TOPLEFT",0,0);H.schedule:SetWidth(H.header:GetWidth());H.schedule:SetHeight(H.header:GetHeight());H.schedule.referenceRect=H.header.referenceRect;Blank(H.schedule);H.schedule:Show()
  for i=1,5 do local b=H.steps[i];local a=d.steps[i];if a then
   Button(b,H.schedule,a);Label(b.fieldkitLabel,H.schedule,a,19,true,"CENTER");b.fieldkitLabel:SetText(upcoming[i] and tostring(upcoming[i].index or i) or "")
  else b:Hide() end end
 end
 if zone=="naxx" and variant=="alternative" then local b=FieldKitNativeTools.NextBoss();H.next:SetText(b and FieldKit_L("Next").."\n"..b.name.."\n"..FieldKitNative.Clock(b.left) or FieldKit_L("No upcoming boss"));H.next:SetJustifyH("CENTER") end
 Label(H.name,H.healthRoot,d.name,23,true)
 if d.level then Label(R.level,H.healthRoot,d.level,30,true,"CENTER");R.level:SetText(tostring(UnitLevel("player") or "?"));H.name:SetText(UnitName("player") or "?") else R.level:Hide() end
 Button(H.player,H.healthRoot,d.health);H.health:ClearAllPoints();H.health:SetAllPoints(H.player);H.health:SetFrameLevel(H.player:GetFrameLevel()+1)
 H.hp:SetParent(H.health);H.hp:ClearAllPoints();H.hp:SetPoint("CENTER",H.health,"CENTER",0,0);H.hp:SetWidth(d.health[3]);H.hp:SetHeight(d.health[4]);T.Font(H.hp,18,R.body,true)
 R.Child(H.resource,H.healthRoot,d.resource);H.resourceText:SetParent(H.resource);H.resourceText:ClearAllPoints();H.resourceText:SetPoint("CENTER",H.resource,"CENTER",0,0);H.resourceText:SetWidth(d.resource[3]);H.resourceText:SetHeight(18);T.Font(H.resourceText,15,R.body,true)
 H.resource:EnableMouse(true);H.resource:SetScript("OnEnter",function() H.Tip(this,FieldKit_L("Resource"),{R.resourceDetail or "?"}) end);H.resource:SetScript("OnLeave",H.HideTip);H.resource:SetScript("OnMouseDown",function() H.Tip(this,FieldKit_L("Resource"),{R.resourceDetail or "?"},true) end)
 R.resourceDetail=H.resourceText:GetText();H.resourceText:SetText(string.gsub(R.resourceDetail or ""," / .*$",""))
 local max=FieldKit.Number(UnitHealthMax("player"));local shield=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.sh)
 if shield and shield>0 and max and max>0 and FieldKitDB.playerShield then H.shield:SetWidth(d.health[3]*math.min(1,shield/max));H.shield:SetHeight(d.health[4]);H.shield:Show() else H.shield:Hide() end
 if d.portrait then
  local a=d.portrait;local p=d.rects.vitality
  R.portrait:ClearAllPoints();R.portrait:SetPoint("TOPLEFT",H.healthRoot,"TOPLEFT",a[1]-p[1],p[2]-a[2]);R.portrait:SetWidth(a[3]);R.portrait:SetHeight(a[3])
  if R.portraitKey~=key then
   local ok=false;if type(SetPortraitTexture)=="function" then ok=pcall(SetPortraitTexture,R.portrait,"player") end
   if not ok then R.portrait:SetTexture("Interface\\Icons\\INV_Helmet_74") end
   R.portraitKey=key
  end
  R.portrait:Show()
 else R.portrait:Hide() end
 for i=1,7 do
  local a=d.actions;local b=getglobal("ActionButton"..slots[i]);if b then
   b:SetParent(H.dock);b:SetScale(1);b:ClearAllPoints();b:SetWidth(a[3]);b:SetHeight(a[3]);b:SetPoint("TOPLEFT",H.dock,"TOPLEFT",a[1]-d.rects.dock[1]+(i-1)*a[4],d.rects.dock[2]-a[2]);b:SetFrameLevel(H.dock:GetFrameLevel()+8)
   -- The approved socket supplies the border; the native 32px normal texture
   -- otherwise leaves a second small square over the enlarged spell icon.
   local normal=b.GetNormalTexture and b:GetNormalTexture()
   if normal and type(normal)~="string" and normal.SetAlpha then H.Save(normal);normal:SetAlpha(0) end
   local cooldown=getglobal("ActionButton"..slots[i].."Cooldown")
   if cooldown then H.Save(cooldown);cooldown:ClearAllPoints();cooldown:SetAllPoints(b) end
  end
 end
 if d.rects.xpArt then R.Geometry(R.xpArt,d.rects.xpArt);R.Art(R.xpArt,"xpArt");R.xpArt:Show() else R.xpArt:Hide() end
 if d.integratedXP then R.Child(H.xpRoot,H.dock,d.xp) else R.Child(H.xpRoot,R.xpArt,d.xp) end;Blank(H.xpRoot)
 H.xpText:SetParent(H.xp);H.xpText:ClearAllPoints();H.xpText:SetPoint("CENTER",H.xp,"CENTER",0,0)
 H.xp:ClearAllPoints();H.xp:SetAllPoints(H.xpRoot);H.xp:SetFrameLevel(H.xpRoot:GetFrameLevel()+1);H.xpText:SetWidth(d.xp[3]);H.xpText:SetHeight(24);T.Font(H.xpText,17,R.body,true)
 if d.rects.xpBadge then R.Geometry(R.xpBadge,d.rects.xpBadge);R.Art(R.xpBadge,"xpBadge");R.xpBadge:SetFrameLevel(H.xp:GetFrameLevel()+3);R.xpBadge:Show();H.xpText:SetParent(R.xpBadge);H.xpText:ClearAllPoints();H.xpText:SetPoint("CENTER",R.xpBadge,"CENTER",0,0) else R.xpBadge:Hide() end
 R.Child(H.counterRoot,H.dock,{0,0,d.size[1],d.size[2]});Blank(H.counterRoot);H.counterRoot:EnableMouse(false);H.counters:Hide()
 local run=type(AZS_RUN)=="table" and AZS_RUN or {}
 local values={tostring(FieldKit.Number(run.kills) or "?").." "..FieldKit_L("victims"),tostring(FieldKit.Number(run.gold) or "?").." "..FieldKit_L("gold"),FieldKit_L("Cache").." : "..tostring(FieldKit.Number(run.chest) or "?")}
 R.counterValues=values
 for i=1,3 do Label(R.counts[i],H.counterRoot,d.counts[i],zone=="naxx" and variant=="alternative" and 17 or 18,true);R.counts[i]:SetText(values[i]);local width=R.counts[i].GetStringWidth and tonumber(R.counts[i]:GetStringWidth());if width and width>d.counts[i][3] then pcall(R.counts[i].SetFont,R.counts[i],T.media.."AzerothSerif.ttf",math.max(12,18*d.counts[i][3]/width),"") end;R.Child(R.counterButtons[i],H.counterRoot,d.counts[i]) end
 local stored=FieldKitNative.Read("AZS_GetStoredLevels")
 if type(stored)=="number" and stored>0 and type(AZS_OpenStoredLevels)=="function" and not (FieldKitUI and FieldKitUI.frame and FieldKitUI.frame:IsShown()) then
  R.stored:ClearAllPoints();local boss=getglobal("FieldKitBossFrame1Compact");R.stored:SetPoint("TOP",R.canvas,"TOP",0,(boss and boss:IsShown()) and -290 or -180);R.stored:SetWidth(240);R.stored:SetHeight(30);R.stored.fieldkitLabel:SetWidth(220);R.stored.fieldkitLabel:SetText(FieldKit_L("Stored levels").." : "..stored.." · Y");T.Update(R.stored);R.stored:Show()
 else R.stored:Hide() end
 R.Buffs(false)
 H.utility:Hide()
 if d.utilityRect or d.rects.utility then
  local a=d.utilityRect or d.rects.utility;R.Geometry(H.utility,a);Blank(H.utility);R.Art(H.utility,"utility");H.utility:SetFrameLevel(R.canvas:GetFrameLevel()+35);H.utility:Show();H.utility:RegisterForClicks("LeftButtonUp","RightButtonUp");H.utility.callback=function() if arg1=="RightButton" then if H.micro:IsShown() then H.micro:Hide() else H.micro:Show() end else FieldKitZoneThemes.Open("FieldKit") end end
  if d.utilityLabel then Label(H.utility.fieldkitLabel,H.utility,d.utilityLabel,20,true);H.utility.fieldkitLabel:SetText("FIELDKIT") else H.utility.fieldkitLabel:SetText("") end
 end
 for _,b in ipairs(H.buttons) do b:Hide() end
 for i,a in ipairs(d.navButtons) do
  local b=H.buttons[i];local route=a[1]
  Button(b,H.nav,{a[2],a[3],a[4],a[5]});Label(b.fieldkitLabel,H.nav,{a[2],a[3],a[4],a[5]},17,true,"CENTER");FieldKit_Text(b,route=="Accessories" and (a[4]<90 and "Equip" or "Equipment") or route);pcall(b.fieldkitLabel.SetFont,b.fieldkitLabel,T.media.."NotoSerif-Regular.ttf",variant=="minimal" and 15 or 17,"");b:RegisterForClicks("LeftButtonUp","RightButtonUp");b.callback=function() if route=="FieldKit" and arg1=="RightButton" then if H.micro:IsShown() then H.micro:Hide() else H.micro:Show() end else FieldKitZoneThemes.Open(route) end end
 end
 for i,name in ipairs({"FieldKitMinimapButton","AzerothStatsMinimap","AzerothOneMinimapButton","MiniMapTrackingFrame"}) do
  local f=getglobal(name)
  if f then
   H.Save(f);local changed=f:GetParent()~=H.micro;local shown=f:IsShown();f:SetParent(H.micro);f:ClearAllPoints();f:SetPoint("TOPLEFT",H.micro,"TOPLEFT",116+(i-1)*28,-373);f:SetFrameLevel(H.micro:GetFrameLevel()+5)
   if changed and shown then f:Hide();f:Show() end
  end
 end
 H.micro:SetParent(R.canvas);H.micro:SetFrameStrata("DIALOG");H.micro:SetFrameLevel(90);if H.micro.GetChildren then for _,child in ipairs({H.micro:GetChildren()}) do child:SetFrameLevel(95) end end;H.micro:SetWidth(240);H.micro:SetHeight(420);T.Update(H.micro);H.micro:SetScale(1);H.micro:ClearAllPoints();if d.rects.nav and d.rects.nav[2]>d.size[2]/2 then H.micro:SetPoint("BOTTOMRIGHT",H.nav,"TOPRIGHT",0,8)
 elseif d.rects.nav then H.micro:SetPoint("TOPRIGHT",H.nav,"BOTTOMRIGHT",0,-8)
 else H.micro:SetPoint("TOPLEFT",H.mode,"BOTTOMLEFT",0,-8) end
 -- Settings remain available in the same one-click menu as native micro buttons.

 if d.rate then local _,_,rate=FieldKitMeterLedger.Read("damage");Label(R.rate,R.canvas,d.rate,21,true);R.rate:SetText("DPS "..(rate and string.format("%.0f",rate) or "?")) else R.rate:Hide() end
 if not R.chat then
  R.chat=Frame("FieldKitReferenceChat");R.chatActions={}
  local callbacks={function() if type(ChatFrame_OpenChat)=="function" then ChatFrame_OpenChat("") end end,function() FieldKit.OpenChatCopy() end,function() SlashCmdList.FieldKit("");if FieldKitUI then FieldKitUI.Select("chat") end end}
  for i,key in ipairs({"Chat","Copy","Settings"}) do R.chatActions[i]=T.Button(R.chat,nil,key,0,0,90,28,callbacks[i]);Blank(R.chatActions[i]) end
  R.chatEntry=T.Button(R.chat,nil,"",0,0,300,35,callbacks[1]);Blank(R.chatEntry)
 end
 R.Geometry(R.chat,d.rects.chat);R.Art(R.chat,"chat");R.chat:Show()
 for i,b in ipairs(R.chatActions) do if zone=="naxx" and variant=="complete" then b:SetFrameLevel(R.chat:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",R.chat,"TOPLEFT",14+(i-1)*98,-3);b:SetWidth(90);b.fieldkitLabel:SetWidth(80);T.Font(b.fieldkitLabel,14,R.body);b:Show() else b:Hide() end end
 if zone=="naxx" and variant=="complete" then R.chatEntry:SetFrameLevel(R.chat:GetFrameLevel()+15);R.chatEntry:ClearAllPoints();R.chatEntry:SetPoint("BOTTOMLEFT",R.chat,"BOTTOMLEFT",14,20);R.chatEntry:SetWidth(d.rects.chat[3]-30);R.chatEntry:Show() else R.chatEntry:Hide() end
 if d.rate then Label(R.rate,R.chat,d.rate,18,true) end
 local chat=getglobal("ChatFrame1")
 if chat and d.chatText then
  H.Save(chat);local a=d.chatText;chat:SetParent(R.chat);if FieldKit.ThemeChatFont then FieldKit.ThemeChatFont(T.media.."AzerothSans.ttf",12,"") end
  if FieldKit.ResizeChatPreservingHistory then FieldKit.ResizeChatPreservingHistory(a[3],a[4]) end
  chat:ClearAllPoints();chat:SetPoint("TOPLEFT",R.chat,"TOPLEFT",a[1]-d.rects.chat[1],d.rects.chat[2]-a[2])
 end
 for _,name in ipairs({"ChatFrame1UpButton","ChatFrame1DownButton","ChatFrame1BottomButton","ChatFrame1MenuButton","ChatFrameMenuButton","FieldKitChatCopyButton"}) do local f=getglobal(name);if f then FieldKitZoneThemes.Mask(f,true) end end
 Label(R.footer,R.canvas,{d.size[1]-305,d.size[2]-27,290,20},11,false,"RIGHT");R.footer:SetText("FIELDKIT "..FieldKit.version.." · "..string.upper(zone))
end
function R.Map()
 local M=FieldKitThemeMinimap;local a=R.layout.map
 R.Geometry(M.root,R.layout.rects.mapArt or {a[1],a[2],a[3],a[3]});Blank(M.root);R.Art(M.root,"mapArt")
 local p=M.root.referenceRect
 Minimap:ClearAllPoints();Minimap:SetPoint("TOPLEFT",M.root,"TOPLEFT",a[1]-p[1],p[2]-a[2]);Minimap:SetWidth(a[3]);Minimap:SetHeight(a[3])
 local queue=getglobal("MiniMapBattlefieldFrame");if queue and R.queueClick then FieldKitZoneThemes.Mask(queue,true) end
 local world=getglobal("MiniMapWorldMapButton");if world and R.worldClick then FieldKitZoneThemes.Mask(world,true) end
 local clock=getglobal("GameTimeFrame");if clock then FieldKitZoneThemes.Mask(clock,true) end
 M.root:Show()
 local over=type(MouseIsOver)=="function" and (MouseIsOver(Minimap) or MouseIsOver(M.zoomOut) or MouseIsOver(M.zoomIn))
 for i,b in ipairs({M.zoomOut,M.zoomIn}) do
  R.Child(b,R.canvas,{a[1]+a[3]-29,a[2]+a[3]-(i==1 and 28 or 60),24,25});b:SetFrameStrata("DIALOG");b:SetFrameLevel(80);Blank(b);T.Font(b.fieldkitLabel,18,T.gold,true)
  if T.zone=="elwynn" or over then b:Hide();b:Show() else b:Hide() end
 end
 return true
end
local function Row(f,i,x,y,w,h)
 local r=f.rows[i];r:SetFrameLevel(f:GetFrameLevel()+5);r.bar:SetFrameLevel(r:GetFrameLevel()+1);r:SetAlpha(1);r:ClearAllPoints();r:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y);r:SetWidth(w);r:SetHeight(h);r:Show();r.icon:Hide();r.bar:Hide();r.entry=nil
 r.label:ClearAllPoints();r.label:SetPoint("TOPLEFT",r,"TOPLEFT",0,0);r.label:SetWidth(w-96);r.label:SetHeight(h);r.value:ClearAllPoints();r.value:SetPoint("TOPRIGHT",r,"TOPRIGHT",0,0);r.value:SetWidth(94);r.value:SetHeight(h);return r
end
function R.Panels(variant,zone)
 for _,f in pairs(H.summaries or {}) do f:Hide() end
 local detail=false;for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do if FieldKitZoneThemes.open[kind] then detail=true end end
 for _,f in pairs(R.frames) do f:Hide() end
 if variant~="complete" or detail then return end
 local d=R.layout
 if not FieldKitNative.Active() and (not R.readyAt or GetTime()>R.readyAt or R.readySerial~=FieldKitNative.serial) then
  R.readyItems={};R.readyAt=GetTime()+5;R.readySerial=FieldKitNative.serial
  if FieldKitLoadout.readSlot then for _,id in ipairs({2,13,14,11,12}) do local ok,name=pcall(FieldKitLoadout.readSlot,id);if ok then R.readyItems[id]={name=name,bonuses={}} end end end
 end
 local prefs={Damage="meterFrame",Lairs="lairFrame",Accessories="gearFrame",Stats="statsFrame",Effects="effectsFrame"}
 for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local f=R.frames[kind];local a=d.rects[kind]
  if a and FieldKitDB[prefs[kind]] and not (kind=="Damage" and FieldKitZoneThemes.nativeMeterOpen) then
   R.Geometry(f,a);R.Art(f,kind);f:Show()
   f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",kind=="Stats" and 65 or 65,-10);f.title:SetWidth(a[3]-78);f.title:SetHeight(30)
   local titles={Damage="DAMAGE",Lairs="LAIRS",Accessories="EQUIPMENT",Stats="BONUSES",Effects="EFFECTS"};FieldKit_Text(f.title,titles[kind])
   f.more:SetFrameLevel(f:GetFrameLevel()+15);f.more:ClearAllPoints();f.more:SetPoint("BOTTOM",f,"BOTTOM",-5,8);f.more:SetWidth(a[3]-42);f.more:SetHeight(28);f.more.fieldkitLabel:SetWidth(a[3]-42);f.more.fieldkitLabel:SetJustifyH("CENTER");T.Font(f.more.fieldkitLabel,17,{1,.82,.12},true)
   f.total:Hide();for _,r in ipairs(f.rows) do r:Hide() end
   if kind=="Damage" then
    FieldKit_Text(f.more,"All spells");local view,index=FieldKitMeterSuite.View();local lines,total,rate,known=FieldKitMeterLedger.Read(view)
    FieldKit_Text(f.title,({"DAMAGE","HEALING","BOSS DAMAGE","DAMAGE TAKEN","PARTY DPS","KILLS"})[index] or "DAMAGE")
    f.total:ClearAllPoints();f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-18,-11);f.total:SetWidth(220);f.total:SetHeight(25);f.total:SetJustifyH("RIGHT");f.total:SetText(Short(total).." · "..Short(rate).." DPS");f.total:Show();f.title:SetWidth(125)
    if zone=="naxx" then T.Font(f.total,24,R.body,true);f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-28,-55);f.total:SetWidth(a[3]-45);f.more:Hide() else T.Font(f.total,16,R.body) end
    for i,b in ipairs(R.tabs) do b:SetFrameLevel(f:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",18+(i-1)*(a[3]-36)/6,-46);b:SetWidth((a[3]-36)/6);b.fieldkitLabel:SetWidth((a[3]-36)/6);T.Font(b.fieldkitLabel,12,R.color);if zone=="naxx" then b:Hide() else b:Show() end end
    for i=1,4 do local r=Row(f,i,82,(zone=="naxx" and 108 or 83)+(i-1)*(zone=="naxx" and 53 or 33),a[3]-100,29);local e=lines[i]
     r.label:SetWidth(a[3]-165);r.value:SetWidth(55);r.label:SetHeight(19)
     r.label:SetText(e and e.name or (i==1 and FieldKit_L("No combat data") or ""));r.value:SetText(e and e.share and string.format("%.0f%%",e.share*100) or "")
     if e then r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-45,0);r.icon:SetTexture(e.icon or FieldKitLoadout.Icon(e.name));r.icon:Show();r.bar:ClearAllPoints();r.bar:SetPoint("TOPLEFT",r,"TOPLEFT",0,-20);r.bar:SetWidth(a[3]-160);r.bar:SetValue(e.share or 0);r.bar:SetStatusBarColor(zone=="elwynn" and .65 or .1,zone=="elwynn" and .55 or .75,zone=="elwynn" and .18 or .85);r.bar:Show() end
    end
   elseif kind=="Lairs" then
    FieldKit_Text(f.more,"View list");local lairs=FieldKitNative.Read("AZS_GetLairs");local active=0;for _,e in ipairs(type(lairs)=="table" and lairs or {}) do if e.state=="awake" then active=active+1 end end
    if zone=="naxx" then
     f.more:Hide();local source=getglobal("FieldKitLairFrame")
     for i=1,4 do local r=Row(f,i,52,53+(i-1)*31,a[3]-77,28);local e=type(lairs)=="table" and lairs[i];local native=source and source.rows and source.rows[i]
      r.label:SetWidth(a[3]-138);r.label:SetJustifyH("LEFT");r.label:SetText(e and FieldKitNative.Text(e.name) or (i==1 and FieldKit_L("No active lair") or ""));r.value:SetWidth(53);r.value:SetText(e and native and native.dist and native.dist:GetText() or "")
      if not r.lamp then r.lamp=r:CreateTexture(nil,"ARTWORK");r.lamp:SetWidth(9);r.lamp:SetHeight(9);r.lamp:SetPoint("LEFT",r,"LEFT",-23,0) end
      local color=e and (e.state=="awake" and {1,.25,.25} or (e.state=="asleep" and {.2,1,.2} or {.45,.45,.45})) or {.25,.25,.25};T.Solid(r.lamp,color);if e then r.lamp:Show() else r.lamp:Hide() end
     end
    else local r=Row(f,1,30,52,a[3]-60,28);r.label:SetWidth(a[3]-60);r.label:SetJustifyH("CENTER");r.label:SetText(type(lairs)~="table" and "?" or (active==0 and FieldKit_L("No active lair") or tostring(active).." "..FieldKit_L("active lairs")));r.value:SetText("") end
   elseif kind=="Accessories" then
    FieldKit_Text(f.more,"Equipment / spells");f.more:Hide()
    local ids={2,13,14,11,12};local names={"Amulet","Trinket 1","Trinket 2","Ring 1","Ring 2"}
    for i=1,5 do local r=Row(f,i,72,51+(i-1)*35,a[3]-94,30);local e=FieldKitLoadout.items[ids[i]] or (R.readyItems and R.readyItems[ids[i]]);r.entry=e;FieldKit_Text(r.label,names[i]);r.value:SetText(e and (e.name or FieldKit_L("Empty")) or "?");r.label:SetWidth(126);r.value:SetWidth(a[3]-228)
     local texture=type(GetInventoryItemTexture)=="function" and GetInventoryItemTexture("player",ids[i]);if texture then r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-42,0);r.icon:SetTexture(texture);r.icon:Show() end
    end
   elseif kind=="Stats" then
    FieldKit_Text(f.more,"All statistics");local source=getglobal("FieldKitStatsFrame");local labels={"Damage","Haste","Crit Chance","Lifesteal"}
    for i,name in ipairs(labels) do local r=Row(f,i,zone=="naxx" and 72 or 31,49+(i-1)*(zone=="naxx" and 31 or 29),a[3]-(zone=="naxx" and 100 or 65),27);FieldKit_Text(r.label,name=="Crit Chance" and "Critique" or name);local value="?"
     for _,s in ipairs(source and source.rows or {}) do if s.label:GetText()==FieldKit_L(name) then value=s.value:GetText() or "?" end end;r.value:SetText(value)
    end
   else
    FieldKit_Text(f.more,"All effects");f.more:Hide();local source=getglobal("FieldKitEffectsFrame");local e=source and source.rows[1];local r=Row(f,1,72,52,a[3]-99,31)
    r.label:SetText(e and e.label:GetText() and e.label:GetText()~="" and e.label:GetText() or FieldKit_L("No active effect"));r.value:SetText(e and e.value:GetText() or "");r.label:SetWidth(a[3]-100)
    if e and e.icon and e.icon:GetTexture() then r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-40,0);r.icon:SetTexture(e.icon:GetTexture());r.icon:Show() end
   end
  end
 end
end

-- One settings shell for every existing page; all controls retain their handlers.
function R.Settings(U)
 local d=FieldKitReferenceArt[FieldKitTheme.zone.."_settings"]
 if not U or not U.frame then return end
 if not d then
  U.seal:SetTexture(T.media.."ChronicleSeal.tga");U.frame.fieldkitArtOnly=nil;T.State(U.frame,false)
  for _,t in ipairs(U.frame.referenceTiles or {}) do t:Hide() end
  return
 end
 local a=d.rects.window
 R.Art(U.frame,"window",d)
 for i,tile in ipairs(d.tiles.window) do local t=U.frame.referenceTiles[i];t:ClearAllPoints();t:SetPoint("TOPLEFT",U.frame,"TOPLEFT",tile[2]*U.frame:GetWidth()/a[3],-tile[3]*U.frame:GetHeight()/a[4]);t:SetWidth(tile[4]*U.frame:GetWidth()/a[3]);t:SetHeight(tile[5]*U.frame:GetHeight()/a[4]) end
 U.seal:SetTexture(T.media.."ReferenceHUD\\"..T.zone.."_seal_v3.tga");U.seal:SetTexCoord(0,1,0,1);U.frame.fieldkitArtOnly=true;T.State(U.frame,false)
end


function R.Buffs(hover)
 local row=getglobal("FieldKitPlayerBuffs");if not row then return end
 if not R.buffDrawer then
  local f=CreateFrame("Frame","FieldKitReferenceBuffDrawer",R.canvas);R.buffDrawer=f;f:SetFrameStrata("TOOLTIP");f:EnableMouse(true);f:SetClampedToScreen(true);T.Surface(f,"card");f:Hide()
  f:SetScript("OnUpdate",function()
   local over=type(MouseIsOver)=="function" and (MouseIsOver(H.player) or MouseIsOver(this) or (H.tip and MouseIsOver(H.tip)))
   if over then R.buffUntil=GetTime()+.25 elseif GetTime()>(R.buffUntil or 0) then this:Hide() end
  end)
 end
 H.Save(row);row:SetParent(R.buffDrawer);row:ClearAllPoints();row:SetPoint("TOPLEFT",R.buffDrawer,"TOPLEFT",12,-8)
 if hover and FieldKitDB.playerBuffs and row:GetWidth()>1 then
  R.buffDrawer:SetWidth(math.max(220,row:GetWidth()+24));R.buffDrawer:SetHeight(46);R.buffDrawer:ClearAllPoints();R.buffDrawer:SetPoint("BOTTOMLEFT",H.tip or H.player,"TOPLEFT",0,4);T.Update(R.buffDrawer);R.buffUntil=GetTime()+.3;R.buffDrawer:Show()
 end
end
