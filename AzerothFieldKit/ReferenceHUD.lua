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
  f.rateLabel=T.Label(f,nil,0,0,110,30,17,R.body)
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
   local route=kind;row:RegisterForClicks("LeftButtonUp","RightButtonUp");row:SetScript("OnClick",function() if this.buffIndex and arg1=="RightButton" and type(CancelPlayerBuff)=="function" then CancelPlayerBuff(this.buffIndex) else FieldKitZoneThemes.Open(route) end end)
  end
  local route=kind
  f:EnableMouse(true)
  local start=f:GetScript("OnDragStart");local finish=f:GetScript("OnMouseUp")
  f:SetScript("OnMouseDown",function() this.referenceDragged=false end)
  f:SetScript("OnDragStart",function() this.referenceDragged=true;if start then start() end end)
  f:SetScript("OnMouseUp",function() local moved=this.referenceDragged;if finish then finish() end;if not moved then FieldKitZoneThemes.Open(route) end end)
  f.collapse=T.Button(f,nil,"−",0,0,18,18,function()
   local native=getglobal(({Damage="FieldKitMeterFrame",Lairs="FieldKitLairFrame",Accessories="FieldKitGearFrame",Stats="FieldKitStatsFrame",Effects="FieldKitEffectsFrame"})[route]);if native and native.mashCollapseButton then native.mashCollapseButton:Click();FieldKitZoneThemes.Refresh(true) end
  end)
  f.more=T.Button(f,nil,"",0,0,300,28,function() FieldKitZoneThemes.Open(route) end);Blank(f.more)
  f.pager=T.Label(f,nil,0,0,96,20,13,R.body);f.pager:ClearAllPoints();f.pager:SetPoint("TOPRIGHT",f,"TOPRIGHT",-34,-18);f.pager:SetJustifyH("RIGHT");f.pager:Hide()
  f.referenceKind=kind;f:EnableMouseWheel(true)
  local function Wheel() local p=this.referenceKind and this or this:GetParent();R.scroll=R.scroll or {};R.scroll[p.referenceKind]=(R.scroll[p.referenceKind] or 0)-(arg1 or 0);FieldKitZoneThemes.Refresh(true) end
  f:SetScript("OnMouseWheel",Wheel);for _,row in ipairs(f.rows) do row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",Wheel) end
 end
 R.counts={};R.counterButtons={};R.countIcons={}
 for i=1,3 do
  R.counts[i]=T.Label(H.counterRoot,nil,0,0,150,27,18,R.color,true)
  local b=CreateFrame("Button",nil,H.counterRoot);local index=i;R.counterButtons[i]=b
  R.countIcons[i]=H.counterRoot:CreateTexture(nil,"ARTWORK")
  b:SetScript("OnEnter",function() H.Tip(this,FieldKit_L(({"Kills","Gold","Chest price"})[index]),{R.counterValues and R.counterValues[index] or "?"}) end)
  b:SetScript("OnLeave",H.HideTip);b:SetScript("OnClick",function() H.Tip(this,FieldKit_L(({"Kills","Gold","Chest price"})[index]),{R.counterValues and R.counterValues[index] or "?"},true) end)
 end
 R.stored=T.Button(R.canvas,"FieldKitReferenceStoredLevels","",0,0,240,30,function() if type(AZS_OpenStoredLevels)=="function" then pcall(AZS_OpenStoredLevels) end end);R.stored:SetFrameStrata("HIGH");R.stored:Hide()
 -- The live portrait sits in a frame one level BELOW the card art: the art's rim masks it to the socket shape, over a dark backing, so no square corners or world show through.
 R.portraitFrame=CreateFrame("Frame",nil,H.healthRoot);R.portraitFrame:SetAllPoints(H.healthRoot)
 R.portraitBack=R.portraitFrame:CreateTexture(nil,"BACKGROUND");T.Solid(R.portraitBack,{.03,.05,.07})
 R.portrait=R.portraitFrame:CreateTexture(nil,"ARTWORK")
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
-- A uniform viewport fit preserves the reference; each owned component can
-- then shrink independently around its nearest screen-edge anchor.
function R.Geometry(frame,rect)
 if not rect or frame.azsMoving then return end
 local s=FieldKitZoneThemes.ElementScale(frame:GetName())
 if frame.referenceGeometryKey==R.key and frame.referenceGeometryRevision==FieldKitZoneThemes.revision and frame.referenceRect==rect and frame:GetParent()==R.canvas and frame:GetScale()==s then if frame:GetAlpha()~=1 then frame:SetAlpha(1) end;return end
 frame:SetParent(R.canvas);frame:SetAlpha(1);frame:SetFrameLevel(R.canvas:GetFrameLevel()+2);frame:SetScale(s);frame:SetWidth(rect[3]);frame:SetHeight(rect[4])
 local d=R.layout;local cx=rect[1]+rect[3]/2;local cy=rect[2]+rect[4]/2
 local x=cx<d.size[1]/3 and 0 or (cx>d.size[1]*2/3 and rect[3] or rect[3]/2)
 local y=cy<d.size[2]/3 and 0 or (cy>d.size[2]*2/3 and rect[4] or rect[4]/2)
 local point=(y==0 and "TOP" or (y==rect[4] and "BOTTOM" or ""))..(x==0 and "LEFT" or (x==rect[3] and "RIGHT" or ""));if point=="" then point="CENTER" end
 FieldKitZoneThemes.Place(frame,point,R.canvas,"TOPLEFT",(rect[1]+x)/s,-(rect[2]+y)/s,true)
 frame.referenceRect=rect
 frame.referenceGeometryKey=R.key;frame.referenceGeometryRevision=FieldKitZoneThemes.revision
end
function R.Child(frame,parent,rect)
 if not rect then frame:Hide();return end
 local a=frame.referenceRect
 if frame.referenceChildKey==R.key and frame:GetParent()==parent and a and a[1]==rect[1] and a[2]==rect[2] and a[3]==rect[3] and a[4]==rect[4] then if frame.GetAlpha and frame:GetAlpha()~=1 then frame:SetAlpha(1) end;if not frame:IsShown() then frame:Show() end;return end
 frame:SetParent(parent);if frame.SetAlpha then frame:SetAlpha(1) end;if frame.SetFrameLevel then frame:SetFrameLevel(parent:GetFrameLevel()+2) end;if frame.SetScale then frame:SetScale(1) end;frame:ClearAllPoints()
 local p=parent.referenceRect or {0,0}
 frame:SetWidth(rect[3]);frame:SetHeight(rect[4]);frame:SetPoint("TOPLEFT",parent,"TOPLEFT",rect[1]-p[1],p[2]-rect[2]);frame:Show()
 frame.referenceRect=rect
 frame.referenceChildKey=R.key
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
   t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",a[2],-a[3]);t:SetWidth(a[4]);t:SetHeight(a[5]);if component=="header" and R.key=="elwynn_complete" then local ratio=1+180/R.layout.rects.header[3];t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",a[2]*ratio,-a[3]);t:SetWidth(a[4]*ratio) end;t:SetTexCoord(0,a[4]/a[6],0,a[5]/a[7]);t:SetAlpha((component=="Damage" or component=="Lairs" or component=="Accessories" or component=="Stats" or component=="Effects" or component=="chat") and FieldKit.Number(FieldKitDB.cardOpacity,100,30,100)/100 or 1);t:Show()
  else t:Hide() end
 end
end
local function Label(label,parent,rect,size,heading,justify,face)
 if R.key=="naxx_minimal" and (label==H.clock or label==H.next) then size=20;face="NotoSerif-Regular.ttf" end
 R.Child(label,parent,rect);T.Font(label,size,R.body,heading,face);label:SetJustifyH(justify or "LEFT")
end
local function Button(button,parent,rect)
 R.Child(button,parent,rect);button:SetFrameLevel(parent:GetFrameLevel()+20);Blank(button)
end
-- The native renderer does not reliably clip FontStrings to their owner.
-- Fit after the final live SetText, not before it. Keep the complete value for
-- hover/readers; UTF-8 truncation never cuts an accented character in half.
function R.Fit(label,size,minimum)
 if not label or not label.GetStringWidth then return end
 local text=tostring(label:GetText() or "");label.referenceFullText=text
 local path,old,flags;if label.GetFont then path,old,flags=label:GetFont() end
 local fit=label.fieldkitFit;size=size or (fit and fit.path==path and fit.baseSize) or old or 17;minimum=minimum or 12
 local rawWidth=label:GetWidth();local width=rawWidth-8;local height=label:GetHeight();if width<=0 then return end
 if fit and fit.full==text and fit.width==rawWidth and fit.height==height and fit.baseSize==size and fit.minimum==minimum and fit.path==path and old==fit.renderSize then
  if text~=fit.display then label:SetText(fit.display) end;return
 end
 local baseSize=size;local requestedMinimum=minimum
 if label.SetWordWrap then pcall(label.SetWordWrap,label,false) end
 if label.SetNonSpaceWrap then pcall(label.SetNonSpaceWrap,label,false) end
 local lines=1;for _ in string.gfind(text,"\n") do lines=lines+1 end
 size=math.min(size,math.max(8,height/lines-1));minimum=math.min(minimum,size)
 if path and old~=size then label:SetFont(path,size,flags or "");old=size end
 local measured=tonumber(label:GetStringWidth()) or 0
 if measured>width and path then size=math.max(minimum,size*width/measured);if old~=size then label:SetFont(path,size,flags or "") end end
 if (tonumber(label:GetStringWidth()) or 0)>width then
  local cut=text;local attempts=0
  repeat cut=string.gsub(cut,"[%z\1-\127\194-\244][\128-\191]*$","");label:SetText(cut.."…");attempts=attempts+1 until cut=="" or (tonumber(label:GetStringWidth()) or 0)<=width or attempts>512
 end
 label.fieldkitFit={path=path,baseSize=baseSize,minimum=requestedMinimum,renderSize=size,width=rawWidth,height=height,full=text,display=label:GetText()}
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
  if d.rects[entry[2]] then if entry[2]~="vitality" or not d.integratedVitals then R.Geometry(entry[1],d.rects[entry[2]]) end;Blank(entry[1]);if entry[2]~="vitality" or not d.integratedVitals then R.Art(entry[1],entry[2]) else R.Art(entry[1],"none") end;entry[1]:Show() else entry[1]:Hide() end
 end
 if d.integratedVitals then R.Child(H.healthRoot,H.dock,d.rects.vitality);H.healthRoot:EnableMouse(false) else H.healthRoot:EnableMouse(true) end
 if key=="elwynn_complete" then local a=d.rects.header;R.Geometry(H.header,{a[1]-90,a[2],a[3]+180,a[4]}) end
 H.sculpture:Hide();H.left:Hide();H.right:Hide();H.namePlate:Hide();H.schedule:Hide()
 for _,rim in ipairs(H.actionRims) do rim:Hide() end
 Label(H.zone,H.identity,d.zone,variant=="complete" and 23 or 20,true,"CENTER")
 Button(H.mode,H.identity,d.mode);Label(H.mode.fieldkitLabel,H.mode,d.mode,17,true,"CENTER")
 if d.heroic then Label(R.heroic,H.identity,d.heroic,variant=="alternative" and 18 or 19,true,nil,variant=="alternative" and "NotoSerif-Regular.ttf" or nil);R.heroic:SetText((FieldKit.GetHeroicLabel() or "?")..(variant=="alternative" and " · "..FieldKit_L("Mode") or ""));H.mode.fieldkitLabel:SetText(variant=="alternative" and "" or FieldKit_L("Mode"))
 else R.heroic:Hide();H.mode.fieldkitLabel:SetText((FieldKit.GetHeroicLabel() or "?")..(zone=="elwynn" and " · "..FieldKit_L("Mode") or "")) end
 if zone=="elwynn" and variant~="alternative" then local a=d.mode;Label(H.mode.fieldkitLabel,H.mode,{a[1]+3,a[2],a[3]-30,a[4]},14,true,"CENTER","NotoSerif-Regular.ttf") end
 H.mode:SetScript("OnEnter",function() if not H.micro:IsShown() then H.ModeTip(this,false) end end);H.mode:RegisterForClicks("LeftButtonUp","RightButtonUp");H.mode.callback=function() if arg1=="RightButton" then H.pinned=false;H.HideTip(); if H.micro:IsShown() then H.micro:Hide() else H.micro:Show() end else H.ModeTip(H.mode,true) end end
 local clockRect=d.clock;local nextRect=d.next;if key=="elwynn_complete" then clockRect={d.clock[1]-45,d.clock[2],d.clock[3]+10,d.clock[4]};nextRect={d.next[1],d.next[2],d.next[3]+85,d.next[4]} end
 Button(H.timeline,H.header,clockRect);Label(H.clock,H.timeline,clockRect,25,true)
 Button(H.reminders,H.header,nextRect);Label(H.next,H.reminders,nextRect,zone=="elwynn" and 18 or (d.nextSize or 23),true)
 if zone=="naxx" and variant=="minimal" then
  local b=FieldKitNativeTools.NextBoss();H.clock:SetText(FieldKit_L("Elapsed time").." : "..FieldKitNative.Clock(FieldKitNative.Time()));H.next:SetText(b and FieldKit_L("Next").." : "..b.name.." · "..FieldKitNative.Clock(b.left) or FieldKit_L("No upcoming boss"))
 end
 if d.steps then
  local upcoming=FieldKitNative.Read("AZS_GetUpcomingBosses") or {}
  H.schedule:SetParent(H.header);H.schedule:SetScale(1);H.schedule:ClearAllPoints();H.schedule:SetPoint("TOPLEFT",H.header,"TOPLEFT",0,0);H.schedule:SetWidth(H.header:GetWidth());H.schedule:SetHeight(H.header:GetHeight());H.schedule.referenceRect=H.header.referenceRect;Blank(H.schedule);H.schedule:Show()
  for i=1,5 do local b=H.steps[i];local a=d.steps[i];if a then
   Button(b,H.schedule,a);Label(b.fieldkitLabel,b,a,19,true,"CENTER");b.fieldkitLabel:SetText(upcoming[i] and tostring(upcoming[i].index or i) or "")
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
  R.portraitFrame:SetFrameLevel(math.max(0,H.healthRoot:GetFrameLevel()-1));R.portraitFrame:Show()
  -- One undistorted square that covers the whole measured socket opening (not the nominal 88 px box):
  -- the art rim above masks the overflow, so no transparent strip remains and the face is never stretched.
  local hole=d.portraitHole or {a[1],a[2],a[3],a[3]};local size=math.max(hole[3],hole[4])+2
  local px,py=hole[1]+hole[3]/2-size/2,hole[2]+hole[4]/2-size/2
  R.portraitBack:ClearAllPoints();R.portraitBack:SetPoint("TOPLEFT",H.healthRoot,"TOPLEFT",px-p[1],p[2]-py);R.portraitBack:SetWidth(size);R.portraitBack:SetHeight(size);R.portraitBack:Show()
  R.portrait:ClearAllPoints();R.portrait:SetPoint("TOPLEFT",H.healthRoot,"TOPLEFT",px-p[1],p[2]-py);R.portrait:SetWidth(size);R.portrait:SetHeight(size)
  if R.portraitKey~=key then
   local ok=false;if type(SetPortraitTexture)=="function" then ok=pcall(SetPortraitTexture,R.portrait,"player") end
   if not ok then R.portrait:SetTexture("Interface\\Icons\\INV_Helmet_74") end
   R.portraitKey=key
  end
  R.portrait:Show()
 else R.portrait:Hide();R.portraitBack:Hide();R.portraitFrame:Hide() end
 for i=1,7 do
  local a=d.actions;local b=getglobal("ActionButton"..slots[i]);if b then
   local redraw=b:GetParent()~=H.dock or b.referenceKey~=key or b.referenceSerial~=FieldKitNative.serial;local shown=b:IsShown()
   b:SetParent(H.dock);b:SetAlpha(1);b:SetFrameStrata("HIGH");b:SetScale(1);b:ClearAllPoints();b:SetWidth(a[3]-8);b:SetHeight(a[3]-8);b:SetPoint("TOPLEFT",H.dock,"TOPLEFT",a[1]-d.rects.dock[1]+(i-1)*a[4]+4,d.rects.dock[2]-a[2]-4);
   local icon=getglobal("ActionButton"..slots[i].."IconTexture") or getglobal("ActionButton"..slots[i].."Icon");if icon then H.Save(icon);icon:ClearAllPoints();icon:SetAllPoints(b) end;b:SetFrameLevel(H.dock:GetFrameLevel()+8)
   if redraw and shown then b:Hide();b:Show() end;b.referenceKey=key;b.referenceSerial=FieldKitNative.serial
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
 if d.rects.xpBadge then R.Child(R.xpBadge,R.xpArt,d.rects.xpBadge);R.Art(R.xpBadge,"xpBadge");R.xpBadge:SetFrameLevel(H.xp:GetFrameLevel()+3);R.xpBadge:Show();H.xpText:SetParent(R.xpBadge);H.xpText:ClearAllPoints();H.xpText:SetPoint("CENTER",R.xpBadge,"CENTER",0,0);H.xpText:SetWidth(d.rects.xpBadge[3]-16) else R.xpBadge:Hide() end
 R.Child(H.counterRoot,H.dock,{0,0,d.size[1],d.size[2]});Blank(H.counterRoot);H.counterRoot:EnableMouse(false);H.counters:Hide()
 local run=type(AZS_RUN)=="table" and AZS_RUN or {}
 local values={tostring(FieldKit.Number(run.kills) or "?").." "..FieldKit_L("victims"),tostring(FieldKit.Number(run.gold) or "?").." "..FieldKit_L("gold"),FieldKit_L("Cache").." : "..tostring(FieldKit.Number(run.chest) or "?")}
 R.counterValues=values
 for i=1,3 do Label(R.counts[i],H.counterRoot,d.counts[i],d.counts[i][3]<150 and 14 or 18,true,nil,"NotoSerif-Regular.ttf");R.counts[i]:SetText(i==3 and string.gsub(values[i]," : "," ") or values[i]);R.Child(R.counterButtons[i],H.counterRoot,d.counts[i]) end
 for i,t in ipairs(R.countIcons) do if zone=="elwynn" and variant=="minimal" then
  local a=d.counts[i];t:ClearAllPoints();t:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",a[1]-39,-a[2]+2);t:SetWidth(19);t:SetHeight(19);t:SetTexture(i==1 and "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" or (i==2 and "Interface\\MoneyFrame\\UI-MoneyIcons" or T.media.."WorldMarkers\\cache.tga"));t:SetTexCoord(0,i==2 and .25 or 1,0,1);t:Show()
 else t:Hide() end end
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
 for _,b in ipairs(H.buttons) do b:Hide();b.fieldkitLabel:Hide() end
 for i,a in ipairs(d.navButtons) do
  local b=H.buttons[i];local route=a[1]
  Button(b,H.nav,{a[2],a[3],a[4],a[5]});Label(b.fieldkitLabel,b,{a[2],a[3],a[4],a[5]},variant=="minimal" and 15 or 17,true,"CENTER","NotoSerif-Regular.ttf");FieldKit_Text(b,route=="Accessories" and (a[4]<90 and "Equip" or "Equipment") or route);b:RegisterForClicks("LeftButtonUp","RightButtonUp");b.callback=function() if route=="FieldKit" and arg1=="RightButton" then if H.micro:IsShown() then H.micro:Hide() else H.micro:Show() end else FieldKitZoneThemes.Open(route) end end
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
 R.Geometry(R.chat,d.rects.chat);R.Art(R.chat,"none");R.chat.fieldkitArtOnly=nil;T.Surface(R.chat,"card",true);T.State(R.chat,false);R.chat:Show()
 for i,b in ipairs(R.chatActions) do if zone=="naxx" and variant=="complete" then b:SetFrameLevel(R.chat:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",R.chat,"TOPLEFT",14+(i-1)*98,-3);b:SetWidth(90);b.fieldkitLabel:SetWidth(80);T.Font(b.fieldkitLabel,14,R.body);b:Show() else b:Hide() end end
 if zone=="naxx" and variant=="complete" then R.chatEntry:SetFrameLevel(R.chat:GetFrameLevel()+15);R.chatEntry:ClearAllPoints();R.chatEntry:SetPoint("BOTTOMLEFT",R.chat,"BOTTOMLEFT",14,20);R.chatEntry:SetWidth(d.rects.chat[3]-30);R.chatEntry:Show() else R.chatEntry:Hide() end
 if d.rate then Label(R.rate,R.chat,d.rate,18,true) end
 if zone=="naxx" and variant=="alternative" then R.Child(R.counts[1],R.chat,d.counts[1]);R.Child(R.counterButtons[1],R.chat,d.counts[1]) end
 local chat=getglobal("ChatFrame1")
 if chat and d.chatText then
  H.Save(chat);local a=d.chatText;if zone=="elwynn" then a={d.rects.chat[1]+14,d.rects.chat[2]+9,d.rects.chat[3]-28,d.rects.chat[4]-18} end;chat:SetParent(R.chat);if FieldKit.ThemeChatFont then FieldKit.ThemeChatFont(T.media.."AzerothSans.ttf",12,"") end
  if FieldKit.ResizeChatPreservingHistory then FieldKit.ResizeChatPreservingHistory(a[3],a[4]) end
  chat:ClearAllPoints();chat:SetPoint("TOPLEFT",R.chat,"TOPLEFT",a[1]-d.rects.chat[1],d.rects.chat[2]-a[2])
 end
 for _,name in ipairs({"ChatFrame1UpButton","ChatFrame1DownButton","ChatFrame1BottomButton","ChatFrame1MenuButton","ChatFrameMenuButton","FieldKitChatCopyButton"}) do local f=getglobal(name);if f then FieldKitZoneThemes.Mask(f,true) end end
 Label(R.footer,R.canvas,{d.size[1]-305,d.size[2]-27,290,20},11,false,"RIGHT");R.footer:SetText("FIELDKIT "..FieldKit.version.." · "..string.upper(zone))
 for _,label in ipairs({H.zone,H.mode.fieldkitLabel,R.heroic,H.clock,H.next,H.name,R.level,H.hp,H.resourceText,H.xpText}) do if label:IsShown() then R.Fit(label) end end
 for _,label in ipairs(R.counts) do R.Fit(label,nil,10) end
 for _,b in ipairs(H.buttons) do if b:IsShown() then R.Fit(b.fieldkitLabel,nil,10) end end
end
-- Re-draw only the art tiles' strip around the map opening on a non-interactive frame above the native map.
function R.MapRim(M,hole)
 local rects=R.layout.rects;local name=rects.mapArt and "mapArt" or "identity";local comp=rects.mapArt and M.root or H.identity
 local origin=rects[name];local tiles=R.layout.tiles[name]
 if not comp or not origin or not tiles then if M.rim then M.rim:Hide() end;return end
 if not M.rim then M.rim=CreateFrame("Frame",nil,comp);M.rimTex={} end
 M.rim:SetParent(comp);M.rim:EnableMouse(false);M.rim:ClearAllPoints();M.rim:SetPoint("TOPLEFT",comp,"TOPLEFT",0,0);M.rim:SetWidth(origin[3]);M.rim:SetHeight(origin[4])
 M.rim:SetFrameLevel(Minimap:GetFrameLevel()+2)
 local margin=10;local zl,zt=hole[1]-margin-origin[1],hole[2]-margin-origin[2];local zr,zb=zl+hole[3]+2*margin,zt+hole[4]+2*margin
 local used=0
 for _,tile in ipairs(tiles) do
  local x0,y0=math.max(tile[2],zl),math.max(tile[3],zt);local x1,y1=math.min(tile[2]+tile[4],zr),math.min(tile[3]+tile[5],zb)
  if x1>x0 and y1>y0 then
   used=used+1;local t=M.rimTex[used]
   if not t then t=M.rim:CreateTexture(nil,"ARTWORK");M.rimTex[used]=t end
   t:SetTexture(T.media.."ReferenceHUD\\"..tile[1]);t:SetTexCoord((x0-tile[2])/tile[6],(x1-tile[2])/tile[6],(y0-tile[3])/tile[7],(y1-tile[3])/tile[7])
   t:ClearAllPoints();t:SetPoint("TOPLEFT",M.rim,"TOPLEFT",x0,-y0);t:SetWidth(x1-x0);t:SetHeight(y1-y0);t:Show()
  end
 end
 for i=used+1,table.getn(M.rimTex) do M.rimTex[i]:Hide() end
 M.rim:Show()
end
function R.Map()
 local M=FieldKitThemeMinimap;local a=R.layout.map
 if R.layout.rects.mapArt then R.Geometry(M.root,R.layout.rects.mapArt) else R.Child(M.root,H.identity,{a[1],a[2],a[3],a[3]}) end;Blank(M.root);R.Art(M.root,"mapArt")
 local p=M.root.referenceRect
 -- The native map stays square (no stretching): it covers the whole opening of the frame art, and the
 -- art's own rim is redrawn above it (R.MapRim) so any overflow is masked instead of leaving black bands.
 local hole=R.layout.mapHole or {a[1],a[2],a[3],a[3]};local side=math.max(hole[3],hole[4])
 local hx,hy=hole[1]+hole[3]/2-side/2,hole[2]+hole[4]/2-side/2
 Minimap:ClearAllPoints();Minimap:SetPoint("TOPLEFT",M.root,"TOPLEFT",hx-p[1],p[2]-hy);Minimap:SetWidth(side);Minimap:SetHeight(side);R.MapRim(M,hole);local owner=R.layout.rects.mapArt and M.root or H.identity;local stamp=tostring(owner:GetLeft())..":"..tostring(owner:GetTop())..":"..tostring(owner:GetEffectiveScale());if M.screenStamp~=stamp then Minimap:Hide();Minimap:Show();M.screenStamp=stamp end
 local queue=getglobal("MiniMapBattlefieldFrame");if queue and R.queueClick then FieldKitZoneThemes.Mask(queue,true) end
 local world=getglobal("MiniMapWorldMapButton");if world and R.worldClick then FieldKitZoneThemes.Mask(world,true) end
 local clock=getglobal("GameTimeFrame");if clock then FieldKitZoneThemes.Mask(clock,true) end
 M.root:Show()
 if not M.dragHandle then
  local handle=CreateFrame("Button",nil,M.root);M.dragHandle=handle;handle:SetMovable(true);handle:EnableMouse(true);handle:RegisterForDrag("LeftButton");handle:SetFrameStrata("HIGH")
  handle:SetScript("OnDragStart",function() local target=R.layout.rects.mapArt and M.root or H.identity;M.dragOwner=target;target.azsMoving=true;target:StartMoving() end)
  local function Finish() if M.dragOwner then FieldKitZoneThemes.Finish(M.dragOwner);M.dragOwner=nil;M.screenStamp=nil;FieldKitZoneThemes.Refresh(true) end end
  handle:SetScript("OnDragStop",Finish);handle:SetScript("OnMouseUp",Finish)
 end
 R.Child(M.dragHandle,M.root,{a[1],a[2],a[3],a[3]});M.dragHandle:SetFrameLevel(M.root:GetFrameLevel()+50)
 Minimap:EnableMouse(FieldKitDB.windowsLocked and true or false);if FieldKitDB.windowsLocked then M.dragHandle:Hide() else M.dragHandle:Show() end
 M.launcherProxies=M.launcherProxies or {}
 for i,name in ipairs({"FieldKitMinimapButton","AzerothStatsMinimap","AzerothOneMinimapButton"}) do
  local original=getglobal(name)
  if original then
   local proxy=M.launcherProxies[i]
   if not proxy then
    proxy=CreateFrame("Button",nil,M.root);proxy:SetWidth(30);proxy:SetHeight(30);proxy.icon=proxy:CreateTexture(nil,"ARTWORK");proxy.icon:SetAllPoints(proxy);proxy:RegisterForClicks("LeftButtonUp","RightButtonUp")
    local target=original;proxy:SetScript("OnClick",function() local handler=target:GetScript("OnClick");if handler then local old=this;this=target;handler();this=old end end)
    proxy:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:AddLine(name);GameTooltip:Show() end);proxy:SetScript("OnLeave",function() GameTooltip:Hide() end)
    M.launcherProxies[i]=proxy
   end
   local texture=original.icon or original.texture;local path=texture and texture.GetTexture and texture:GetTexture();if not path and original.GetNormalTexture then local n=original:GetNormalTexture();path=type(n)=="string" and n or (n and n.GetTexture and n:GetTexture()) end
   proxy.icon:SetTexture(path or (i==1 and T.media.."ChronicleSeal.tga" or "Interface\\Icons\\INV_Misc_Book_09"));proxy:ClearAllPoints();local left=a[1]<R.layout.size[1]/2;proxy:SetPoint(left and "TOPLEFT" or "TOPRIGHT",M.root,left and "TOPRIGHT" or "TOPLEFT",left and 5 or -5,-8-(i-1)*36);proxy:SetFrameStrata("HIGH");proxy:SetFrameLevel(M.root:GetFrameLevel()+80);proxy:Show();FieldKitZoneThemes.Mask(original,true)
  end
 end
 local over=type(MouseIsOver)=="function" and (MouseIsOver(Minimap) or MouseIsOver(M.zoomOut) or MouseIsOver(M.zoomIn))
 for i,b in ipairs({M.zoomOut,M.zoomIn}) do
  local x,y=a[1]+a[3]-29,a[2]+a[3]-(i==1 and 28 or 60)
  if T.zone=="elwynn" and R.key=="elwynn_minimal" then x=a[1]+a[3]-16 end
  if T.zone=="elwynn" and R.key=="elwynn_complete" then x=a[1]+a[3]-24;y=a[2]+a[3]-(i==1 and 42 or 74) end
  R.Child(b,M.root,{x,y,24,25});b:SetFrameStrata("DIALOG");b:SetFrameLevel(80);Blank(b);T.Font(b.fieldkitLabel,18,T.gold,true);b.fieldkitLabel:SetText((R.key=="elwynn_minimal" or R.key=="elwynn_complete") and "" or (i==1 and "-" or "+"))
  if T.zone=="elwynn" or over then b:Hide();b:Show() else b:Hide() end
 end
 return true
end
local function Row(f,i,x,y,w,h)
 local r=f.rows[i];r.fontSize=nil;r.fontMin=nil;r.labelTint=nil;r.valueTint=nil;r.buffIndex=nil;r:SetFrameLevel(f:GetFrameLevel()+5);r.bar:SetFrameLevel(r:GetFrameLevel()+1);r:SetAlpha(1);r:ClearAllPoints();r:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y);r:SetWidth(w);r:SetHeight(h);r:Show();r.icon:Hide();r.bar:Hide();if r.trough then r.trough:Hide() end;if r.lamp then r.lamp:Hide() end;r.entry=nil
 r.label:ClearAllPoints();r.label:SetPoint("TOPLEFT",r,"TOPLEFT",0,0);r.label:SetWidth(w-96);r.label:SetHeight(h);r.value:ClearAllPoints();r.value:SetPoint("TOPRIGHT",r,"TOPRIGHT",0,0);r.value:SetWidth(94);r.value:SetHeight(h);return r
end
-- Damage categories: 3x2 grid of contiguous hit areas. Layout is applied only when it changes: re-levelling or
-- re-anchoring a button on every refresh can cancel a click that is in progress in this client.
function R.DamageTabs(f,a,zone,index)
 local tabW=(a[3]-48)/3;local top=zone=="naxx" and 92 or 46
 for i,b in ipairs(R.tabs) do
  local key=table.concat({a[3],zone,index==i and 1 or 0,tostring(FieldKitDB.language),tostring(f:GetFrameLevel())},":")
  if b.layoutKey~=key then
   b.layoutKey=key;local col,row=math.mod(i-1,3),math.floor((i-1)/3)
   b:SetFrameLevel(f:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",24+col*tabW,-(top+row*25));b:SetWidth(tabW);b:SetHeight(25)
   b.fieldkitLabel:SetWidth(tabW-10);b.fieldkitLabel:SetJustifyH("CENTER");T.Font(b.fieldkitLabel,13,index==i and {1,.82,.12} or R.body,true);b.fieldkitSelected=index==i;Blank(b)
   if not b.underline then b.underline=b:CreateTexture(nil,"ARTWORK");b.underline:SetHeight(2);b.underline:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",3,1);b.underline:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-3,1) end
   T.Solid(b.underline,{1,.82,.12});if index==i then b.underline:Show() else b.underline:Hide() end
  end
  b:Show()
 end
end
-- Scrolling window over a list that can outgrow its fixed art card; the wheel moves it, a pager shows position.
function R.Window(f,kind,total,capacity)
 R.scroll=R.scroll or {}
 local top=math.max(0,total-capacity);local offset=math.min(top,math.max(0,R.scroll[kind] or 0));R.scroll[kind]=offset
 f.pager:ClearAllPoints()
 if kind=="Accessories" then f.pager:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,16) else f.pager:SetPoint("TOPRIGHT",f,"TOPRIGHT",-34,-18) end
 if total>capacity then f.pager:SetText((offset+1).."-"..math.min(total,offset+capacity).." / "..total);f.pager:Show() else f.pager:Hide() end
 return offset
end
-- Flat text tabs inside a card (same language as the meter tabs: gold underline on the active one).
function R.CardTabs(f,a,active,keys,pick)
 f.cardTabs=f.cardTabs or {}
 -- Tabs live in the card header (where the title was): from x=62 to the collapse button, full header height.
 local left,top,height=62,9,36
 local width=(a[3]-left-34)/table.getn(keys)
 for i,key in ipairs(keys) do
  local b=f.cardTabs[i]
  if not b then
   local index=i;b=T.Button(f,nil,key,0,0,100,26,function() pick(index) end);f.cardTabs[i]=b
   b.rule=b:CreateTexture(nil,"ARTWORK");b.rule:SetHeight(1);b.rule:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);b.rule:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,0)
   b.underline=b:CreateTexture(nil,"OVERLAY");b.underline:SetHeight(2);b.underline:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);b.underline:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,0)
  end
  T.Solid(b.rule,{1,.82,.12},.3);b.rule:Show()
  local stamp=table.concat({a[3],active==i and 1 or 0,tostring(FieldKitDB.language),tostring(f:GetFrameLevel())},":")
  if b.layoutKey~=stamp then
   b.layoutKey=stamp
   FieldKit_Text(b,key);b:SetFrameLevel(f:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",left+(i-1)*width,-top);b:SetWidth(width);b:SetHeight(height)
   b.fieldkitLabel:SetWidth(width-10);b.fieldkitLabel:SetJustifyH("CENTER");T.Font(b.fieldkitLabel,18,active==i and {1,.82,.12} or R.body,true);R.Fit(b.fieldkitLabel,18,12);b.fieldkitSelected=active==i;Blank(b)
   T.Solid(b.underline,{1,.82,.12});if active==i then b.underline:Show() else b.underline:Hide() end
  end
  b:Show()
 end
end
function R.MaskBuffs(want)
 for _,name in ipairs({"BuffFrame","TemporaryEnchantFrame"}) do
  local frame=getglobal(name)
  if frame then
   if want and frame:GetParent()~=H.storage then FieldKitZoneThemes.Mask(frame,true)
   elseif not want and R.buffsMasked and frame:GetParent()==H.storage then FieldKitZoneThemes.Mask(frame,false) end
  end
 end
 R.buffsMasked=want and true or nil
end
-- Guardians as the native lair reader orders them: nearest first, with state/delay and distance.
function R.LairList(lairs)
 local list={}
 local tints={awake={1,.42,.35},asleep={.55,.9,.55},waiting={.86,.73,.42},empty={.62,.62,.62}}
 local function Tint(state)
  if state==FieldKit_L("awake") then return tints.awake elseif state==FieldKit_L("asleep") then return tints.asleep
  elseif string.find(state,FieldKit_L("back in "),1,true)==1 then return tints.waiting end
  return tints.empty
 end
 local source=getglobal("FieldKitLairFrame")
 for k=1,(source and source.rows and table.getn(source.rows) or 0) do
  local row=source.rows[k];local text=row.label and row.label:GetText()
  if text and text~="" and row:IsShown() then
   local state=row.value and row.value:GetText() or "";local name=string.gsub(text,"^> ","")
   table.insert(list,{name=name,state=state,dist=row.dist and row.dist:GetText() or "",tint=Tint(state)})
  end
 end
 if table.getn(list)==0 and type(lairs)=="table" then
  for _,e in ipairs(lairs) do
   if type(e)=="table" and type(e.name)=="string" then
    local state
    if e.state=="awake" then state=FieldKit_L("awake")
    elseif e.state=="asleep" then state=FieldKit_L("asleep")
    elseif FieldKit.Number(e.left) and e.left>0 then state=FieldKit_L("back in ")..FieldKitNative.Clock(e.left)
    else state=FieldKit_L("empty") end
    table.insert(list,{name=FieldKitNative.Text(e.name),state=state,dist="",tint=Tint(state)})
   end
  end
 end
 return list
end
function R.Panels(variant,zone)
 for _,f in pairs(H.summaries or {}) do f:Hide() end
 local detail=false;for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do if FieldKitZoneThemes.open[kind] then detail=true end end
 for _,f in pairs(R.frames) do f:Hide() end
 if variant~="complete" then R.MaskBuffs(false);return end
 R.effectBuffs=false
 local d=R.layout
 if not FieldKitNative.Active() and (not R.readyAt or GetTime()>R.readyAt or R.readySerial~=FieldKitNative.serial) then
  R.readyItems={};R.readyAt=GetTime()+5;R.readySerial=FieldKitNative.serial
  if FieldKitLoadout.readSlot then for _,id in ipairs({2,13,14,11,12}) do local ok,name=pcall(FieldKitLoadout.readSlot,id);if ok then R.readyItems[id]={name=name,bonuses={}} end end end
 end
 local prefs={Damage="meterFrame",Lairs="lairFrame",Accessories="gearFrame",Stats="statsFrame",Effects="effectsFrame"}
 for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local f=R.frames[kind];local a=d.rects[kind]
  local nativeName=({Damage="FieldKitMeterFrame",Lairs="FieldKitLairFrame",Accessories="FieldKitGearFrame",Stats="FieldKitStatsFrame",Effects="FieldKitEffectsFrame"})[kind];local folded=(kind=="Stats" and FieldKitDB.statsCollapsed) or (kind=="Accessories" and FieldKitDB.gearCollapsed) or (FieldKitDB.collapsedWindows and FieldKitDB.collapsedWindows[nativeName])
  if a and FieldKitDB[prefs[kind]] and not folded and not (kind=="Damage" and FieldKitZoneThemes.nativeMeterOpen) then
   R.Geometry(f,a);R.Art(f,kind);f:Show();f.collapse:ClearAllPoints();f.collapse:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-8);f.collapse:SetFrameLevel(f:GetFrameLevel()+25);f.collapse:Show()
   if f.bodyWash then f.bodyWash:Hide() end

   f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",65,-14);f.title:SetWidth(a[3]-78);f.title:SetHeight(30);T.Font(f.title,21,R.color,true)
   local titles={Damage="DAMAGE",Lairs="LAIRS",Accessories="EQUIPMENT",Stats="BONUSES",Effects="EFFECTS"};FieldKit_Text(f.title,titles[kind])
   if f.footerPatch then f.footerPatch:Hide() end
   if kind~="Accessories" then
    if not f.cleanBody then f.cleanBody=f:CreateTexture(nil,"BORDER") end
    local t=f.cleanBody;t:SetTexture(T.media.."ReferenceHUD\\"..zone.."_card_body_v9.tga");t:SetTexCoord(0,1,0,1);t:ClearAllPoints();t:SetPoint("TOPLEFT",f,"TOPLEFT",17,-44);t:SetWidth(a[3]-34);t:SetHeight(a[4]-60);t:Show()
   end
   f.more:Show();f.more:SetFrameLevel(f:GetFrameLevel()+15);f.more:ClearAllPoints();f.more:SetPoint("BOTTOM",f,"BOTTOM",-5,zone=="elwynn" and 20 or 8);f.more:SetWidth(a[3]-42);f.more:SetHeight(28);f.more.fieldkitLabel:SetWidth(a[3]-42);f.more.fieldkitLabel:SetJustifyH("CENTER");T.Font(f.more.fieldkitLabel,17,{1,.82,.12},true)
   if f.emptySocket then f.emptySocket:Hide() end;f.total:Hide();f.rateLabel:Hide();f.pager:Hide();if f.cardTabs then for _,b in ipairs(f.cardTabs) do b:Hide() end end;for _,r in ipairs(f.rows) do r:Hide();r.icon:Hide();r.bar:Hide();if r.trough then r.trough:Hide() end end
   if kind=="Damage" then
    if f.liveBody then f.liveBody:Hide();f.liveGrain:Hide() end
    FieldKit_Text(f.more,"All spells");f.more.fieldkitLabel:SetText(FieldKit_L("All spells").." →");local view,index=FieldKitMeterSuite.View();local lines,total,rate,known=FieldKitMeterLedger.Read(view)
    FieldKit_Text(f.title,({"DAMAGE","HEALING","BOSS DAMAGE","DAMAGE TAKEN","PARTY DPS","KILLS"})[index] or "DAMAGE")
    f.total:ClearAllPoints();f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-30,-11);f.total:SetWidth(a[3]-200);f.total:SetHeight(25);f.total:SetJustifyH("RIGHT");if index==6 then FieldKit_Text(f.title,"Kills short") end;f.total:SetText(Short(total)..(rate and (" · "..Short(rate)..(index==2 and " HPS" or (index==6 and " /s" or " DPS"))) or ""));f.total:Show();f.title:SetWidth(125)
    if zone=="naxx" then
     f.total:ClearAllPoints();f.total:SetPoint("TOPLEFT",f,"TOPLEFT",29,-53);f.total:SetWidth(155);f.total:SetHeight(34);f.total:SetJustifyH("LEFT");f.total:SetText(Short(total));T.Font(f.total,30,R.body,true)
     f.rateLabel:ClearAllPoints();f.rateLabel:SetPoint("TOPRIGHT",f,"TOPRIGHT",-23,-58);f.rateLabel:SetWidth(110);f.rateLabel:SetHeight(27);f.rateLabel:SetJustifyH("RIGHT");f.rateLabel:SetText(Short(rate)..(index==2 and " HPS" or (index==6 and " /s" or " DPS")));T.Font(f.rateLabel,17,R.body);f.rateLabel:Show();R.Fit(f.rateLabel,17,12)
     f.title:SetWidth(a[3]-100);f.more:Hide()
    else T.Font(f.total,16,R.color,true) end
    R.DamageTabs(f,a,zone,index)
    for i=1,4 do local r=Row(f,i,82,(zone=="naxx" and 146 or 98)+(i-1)*(zone=="naxx" and 46 or 33),a[3]-100,29);local e=lines[i];if not e and i>1 then r:Hide() end
     r.label:SetWidth(a[3]-165);r.value:SetWidth(55);r.label:SetHeight(19)
     r.label:SetText(e and (e.displayName or e.name) or (i==1 and FieldKit_L("No combat data") or ""));r.value:SetText(e and e.share and string.format("%.0f%%",e.share*100) or "")
     if e then
      if not r.trough then r.trough=r:CreateTexture(nil,"BACKGROUND") end
      r.trough:ClearAllPoints();r.trough:SetPoint("TOPLEFT",r,"TOPLEFT",0,-20);r.trough:SetWidth(a[3]-160);r.trough:SetHeight(8);T.Solid(r.trough,{.12,.14,.08});r.trough:Show()
      r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-45,0);r.icon:SetTexture(e.icon or FieldKitLoadout.Icon(e.name));r.icon:Show();r.bar:ClearAllPoints();r.bar:SetPoint("TOPLEFT",r,"TOPLEFT",0,-20);r.bar:SetWidth(a[3]-160);r.bar:SetMinMaxValues(0,1);r.bar:SetValue(0);r.bar:SetValue(math.max(0,math.min(1,e.share or 0)));r.bar:SetStatusBarColor(zone=="elwynn" and .65 or .1,zone=="elwynn" and .55 or .75,zone=="elwynn" and .18 or .85);r.bar:Show() end
    end
    if not lines[1] then
     -- Empty state: centred in the content area between the tab rows and the card foot, not in the whole frame.
     local top=zone=="naxx" and 146 or 98;local bottom=zone=="naxx" and a[4]-30 or a[4]-52
     local r=Row(f,1,24,top,a[3]-48,bottom-top);r.label:SetWidth(a[3]-48);r.label:SetHeight(bottom-top);r.label:SetJustifyH("CENTER");r.label:SetJustifyV("MIDDLE")
     r.label:SetText(FieldKit_L("No combat data"));r.value:SetText("");r.value:SetWidth(0)
    end
   elseif kind=="Lairs" then
    FieldKit_Text(f.more,"View list");f.more.fieldkitLabel:SetText(FieldKit_L("View list").." →");local lairs=FieldKitNative.Read("AZS_GetLairs");local active=0;for _,e in ipairs(type(lairs)=="table" and lairs or {}) do if e.state=="awake" then active=active+1 end end
    local list=R.LairList(lairs);local total=table.getn(list);local capacity=4
    f.title:SetWidth(a[3]-175)
    if total>0 then
     -- Every guardian is listed (four rows in both zones); more than four scroll with the wheel, never hidden behind "+N".
     f.more:Hide();local offset=R.Window(f,"Lairs",total,capacity)
     for i=1,math.min(capacity,total-offset) do
      local e=list[offset+i]
      local r=zone=="naxx" and Row(f,i,52,53+(i-1)*31,a[3]-77,28) or Row(f,i,40,44+(i-1)*21,a[3]-66,20)
      -- Value column = measured width of state/delay/distance; the name gets everything that is left.
      local rowW=zone=="naxx" and a[3]-77 or a[3]-66
      r.label:SetJustifyH("LEFT");r.value:SetJustifyH("RIGHT");r.label:SetText(e.name);r.value:SetText(e.state..(e.dist~="" and ("  "..e.dist) or ""))
      local want=(r.value.GetStringWidth and r.value:GetStringWidth() or 100)+8
      local vw=math.min(rowW*.55,math.max(60,want));r.value:SetWidth(vw);r.label:SetWidth(rowW-vw-10)
      r.fontSize=zone=="naxx" and 16 or 14;r.fontMin=11;r.labelTint=e.tint;r.valueTint=e.tint
     end
    elseif zone=="naxx" then
     f.more:Hide()
     for i=1,4 do local r=Row(f,i,52,53+(i-1)*31,a[3]-77,28);r.label:SetWidth(a[3]-138);r.label:SetJustifyH("LEFT");r.label:SetText(i==1 and FieldKit_L("No active lair") or "");r.value:SetWidth(53);r.value:SetText("") end
    else local r=Row(f,1,30,52,a[3]-60,28);r.label:SetWidth(a[3]-60);r.label:SetJustifyH("CENTER");r.label:SetText(type(lairs)~="table" and "?" or FieldKit_L("No active lair"));r.value:SetText("");r.value:SetWidth(0) end
   elseif kind=="Accessories" then
    FieldKit_Text(f.more,"Equipment / spells");f.more:Hide();f.title:Hide()
    local tab=FieldKitDB.loadoutTab==2 and 2 or 1
    R.CardTabs(f,a,tab,{"Equipment","Spells"},function(i) FieldKitDB.loadoutTab=i;R.scroll=R.scroll or {};R.scroll.Accessories=0;FieldKitZoneThemes.Refresh(true) end)
    if tab==1 then
     local ids={2,13,14,11,12};local names={"Amulet","Trinket 1","Trinket 2","Ring 1","Ring 2"}
     for i=1,5 do local r=Row(f,i,72,54+(i-1)*34,a[3]-94,30);local e=FieldKitLoadout.items[ids[i]] or (R.readyItems and R.readyItems[ids[i]]);r.entry=e;local occupied=e and e.name and e.name~="" and e.name~=FieldKit_L("Empty");if occupied then r.label:SetText(e.name);r.value:SetText("");r.label:SetWidth(a[3]-98);r.value:SetWidth(0) else FieldKit_Text(r.label,names[i]);r.value:SetText(e and FieldKit_L("Empty") or "?");r.label:SetWidth(126);r.value:SetWidth(a[3]-228) end
      local texture=type(GetInventoryItemTexture)=="function" and GetInventoryItemTexture("player",ids[i]);if texture then r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-42,0);r.icon:SetTexture(texture);r.icon:Show() end
      r.fontSize=16;r.fontMin=16
     end
    else
     local spells=FieldKitLoadout.spells or {};local total=table.getn(spells);local offset=R.Window(f,"Accessories",total,5)
     if total==0 then local r=Row(f,1,72,54,a[3]-94,30);r.label:SetWidth(a[3]-98);r.label:SetText(FieldKit_L("No spells yet"));r.value:SetText("");r.value:SetWidth(0);r.fontSize=16;r.fontMin=12 end
     for i=1,math.min(5,total-offset) do
      local e=spells[offset+i];local r=Row(f,i,72,54+(i-1)*34,a[3]-94,30);r.entry=e
      r.label:SetText(e.name or "?");r.value:SetText(e.rank or "");r.value:SetWidth(78);r.label:SetWidth(a[3]-98-82)
      local icon=FieldKitLoadout.Icon(e.name);if icon then r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-42,0);r.icon:SetTexture(icon);r.icon:Show() end
      r.fontSize=16;r.fontMin=12;local cr,cg,cb=FieldKitLoadout.RankColor(e.rankValue);r.valueTint={cr,cg,cb}
     end
    end
   elseif kind=="Stats" then
    FieldKit_Text(f.more,"All statistics");f.more.fieldkitLabel:SetText(FieldKit_L("All statistics").." →");local source=getglobal("FieldKitStatsFrame");local labels={"Damage","Haste","Crit Chance","Lifesteal"}
    if zone=="naxx" then f.more:Hide() end
    for i,name in ipairs(labels) do local r=Row(f,i,zone=="naxx" and 72 or 31,49+(i-1)*(zone=="naxx" and 27 or 29),a[3]-(zone=="naxx" and 100 or 65),27);FieldKit_Text(r.label,name=="Crit Chance" and "Critique" or name);local value="?"
     for _,s in ipairs(source and source.rows or {}) do if s.label:GetText()==FieldKit_L(name) then value=s.value:GetText() or "?" end end;r.value:SetText(value)
    end
   else
    FieldKit_Text(f.more,"All effects");f.more:Hide();f.title:SetWidth(a[3]-175)
    local source=FieldKitNativeTools and FieldKitNativeTools.frames[1];local list=source and source.lastRows or {}
    local total=table.getn(list);local capacity=2
    if total==0 then list={{label=FieldKit_L("No active effect"),value=""}};total=1 end
    local offset=R.Window(f,"Effects",total,capacity)
    for i=1,math.min(capacity,total-offset) do
     local e=list[offset+i];local r=Row(f,i,72,44+(i-1)*29,a[3]-99,27)
     r.label:SetText(e.label or "");r.value:SetText(e.value or "");r.buffIndex=e.buffIndex
     if e.buffIndex then R.effectBuffs=true end
     local available=a[3]-99;local vw=r.value:GetText()~="" and math.min(110,math.max(60,(r.value.GetStringWidth and r.value:GetStringWidth() or 100)+4)) or 0;r.value:SetWidth(vw);r.label:SetWidth(available-vw-8)
     if e.icon and e.icon~="" then r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-40,2);r.icon:SetWidth(24);r.icon:SetHeight(24);r.icon:SetTexture(e.icon);r.icon:Show() end
     r.fontSize=16;r.fontMin=11
    end
   end
   R.Fit(f.title,21,12);if f.total:IsShown() then R.Fit(f.total,zone=="naxx" and 30 or 16,12) end
   for _,r in ipairs(f.rows) do if r:IsShown() then
    local size=r.fontSize or 16;local least=r.fontMin or (kind=="Accessories" and 16 or 12)
    T.Font(r.label,size,r.labelTint or R.body,false);T.Font(r.value,size,r.valueTint or r.labelTint or R.body,false);R.Fit(r.label,size,least);R.Fit(r.value,size,least)
    r.fullLines={r.label.referenceFullText or "",r.value.referenceFullText or ""}
    r:SetScript("OnEnter",function() if this.entry and FieldKitLoadout then FieldKitLoadout.Tip(this,this.entry) elseif this.buffIndex and GameTooltip.SetPlayerBuff then GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetPlayerBuff(this.buffIndex);GameTooltip:Show() else H.Tip(this,f.title:GetText(),this.fullLines) end end);r:SetScript("OnLeave",function() GameTooltip:Hide();H.HideTip() end)
   end end
  end
 end
 R.MaskBuffs(R.effectBuffs and R.frames.Effects:IsShown())
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
