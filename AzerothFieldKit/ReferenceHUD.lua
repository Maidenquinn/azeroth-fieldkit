-- Live widgets inside the approved artwork's measured component rectangles.
-- No scene, text, action icon, map or filled gauge is baked into the skin.
FieldKitReferenceHUD={frames={},color={.96,.92,.81},body={.96,.95,.90}}
local R=FieldKitReferenceHUD
local H=FieldKitThemeHUD
local T=FieldKitTheme
local slots={1,2,3,4,5,6,12}
local function Short(n) if not n then return "?" end;if math.abs(n)>=1000000 then return string.format("%.1f m",n/1000000) elseif math.abs(n)>=1000 then return string.format("%.1f k",n/1000) else return string.format("%.0f",n) end end
-- Compact amounts: exact below 10 000 (grouped), then one decimal in thousands (k) or millions (M); the decimal and group
-- separators follow the language. nil in, "?" out: a missing value is never turned into a number.
function R.Amount(n)
 if type(n)~="number" then return "?" end
 local fr=FieldKitDB and FieldKitDB.language=="fr"
 local dec=fr and "," or ".";local group=fr and " " or ","
 local a=math.abs(n);local sign=n<0 and "-" or ""
 if a>=1000000 then return sign..string.gsub(string.format("%.1f",a/1000000),"%.",dec).." M" end
 if a>=10000 then return sign..string.gsub(string.format("%.1f",a/1000),"%.",dec).." k" end
 local text=string.format("%d",math.floor(a+.5))
 if string.len(text)==4 then text=string.sub(text,1,1)..group..string.sub(text,2) end
 return sign..text
end
-- Chat tools of the themed chat card. Nothing is re-implemented: they call the native chat frame's own scroll methods (the
-- native buttons are masked, so their own handlers, which act on their parent, cannot be used) and FieldKit's copy window.
R.chatToolDefs={{key="copy",label="C",tip="Open chat copy"},{key="up",label="^",tip="Scroll up (Shift: top)",icon="ChatFrame1UpButton"},
 {key="down",label="v",tip="Scroll down (Shift: bottom)",icon="ChatFrame1DownButton"},{key="bottom",label="v|",tip="Jump to the latest message",icon="ChatFrame1BottomButton"}}
function R.ChatTool(key)
 if key=="copy" then if FieldKit.OpenChatCopy then FieldKit.OpenChatCopy() end;return end
 local chat=getglobal("ChatFrame1");if not chat then return end
 local shift=type(IsShiftKeyDown)=="function" and IsShiftKeyDown()
 if key=="up" then if shift and chat.ScrollToTop then chat:ScrollToTop() elseif chat.PageUp then chat:PageUp() end
 elseif key=="down" then if shift and chat.ScrollToBottom then chat:ScrollToBottom() elseif chat.PageDown then chat:PageDown() end
 elseif key=="bottom" then if chat.ScrollToBottom then chat:ScrollToBottom() end end
end
-- Info icon baked into the Elwynn foot art, measured on elwynn_complete_identity_1.tga (ring pixels x 227..246 of the tile): button-local
-- x 204..224 (the button is the 252 px foot). textLeft = right edge of the art's left cap.
R.MODE_ICON={elwynn_complete={left=204,right=224,margin=6,textLeft=14}}
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
  for i=1,(kind=="Stats" and 30 or ((kind=="Accessories" or kind=="Damage") and 24 or 6)) do
   local row=CreateFrame("Button",nil,f);f.rows[i]=row;row:SetWidth(300);row:SetHeight(34)
   row.label=T.Label(row,nil,0,0,210,28,17,R.body);pcall(row.label.SetFont,row.label,T.media.."NotoSerif-Regular.ttf",17,"")
   row.value=T.Label(row,nil,212,0,78,28,17,R.body);row.value:SetJustifyH("RIGHT")
   row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(26);row.icon:SetHeight(26)
   row.bar=CreateFrame("StatusBar",nil,row);row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");row.bar:SetMinMaxValues(0,1);row.bar:SetHeight(8)
   row.bar:SetFrameLevel(row:GetFrameLevel()+1)
   row:SetScript("OnEnter",function() if this.entry and FieldKitLoadout then FieldKitLoadout.Tip(this,this.entry) end end)
   row:SetScript("OnLeave",function() GameTooltip:Hide() end)
   local route=kind;row:RegisterForClicks("LeftButtonUp","RightButtonUp");row:SetScript("OnClick",function() if this.buffIndex and arg1=="RightButton" and type(CancelPlayerBuff)=="function" then CancelPlayerBuff(this.buffIndex) elseif route=="Stats" then R.ToggleStats() elseif route~="Damage" then FieldKitZoneThemes.Open(route) end end)
  end
  local route=kind
  f:EnableMouse(true)
  local start=f:GetScript("OnDragStart");local finish=f:GetScript("OnMouseUp")
  f:SetScript("OnMouseDown",function() this.referenceDragged=false end)
  f:SetScript("OnDragStart",function() this.referenceDragged=true;if start then start() end end)
  f:SetScript("OnMouseUp",function() local moved=this.referenceDragged;if finish then finish() end;if not moved then if route=="Stats" then R.ToggleStats() elseif route~="Damage" then FieldKitZoneThemes.Open(route) end end end)
  f.collapse=T.Button(f,nil,"−",0,0,18,18,function()
   local native=getglobal(({Damage="FieldKitMeterFrame",Lairs="FieldKitLairFrame",Accessories="FieldKitGearFrame",Stats="FieldKitStatsFrame",Effects="FieldKitEffectsFrame"})[route]);if native and native.mashCollapseButton then native.mashCollapseButton:Click();FieldKitZoneThemes.Refresh(true) end
  end)
  f.more=T.Button(f,nil,"",0,0,300,28,function() if route=="Stats" then R.ToggleStats() else FieldKitZoneThemes.Open(route) end end);Blank(f.more)
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
  local b=T.Button(R.frames.Damage,nil,({"Damage","Healing","Boss","Taken","Groups","Kills short"})[i],0,0,54,30,function() FieldKitMeterSuite.SetView(view);R.scroll=R.scroll or {};R.scroll.Damage=0;FieldKitZoneThemes.Refresh(true) end)
  Blank(b);R.tabs[i]=b;R.DiagHook(b,"damage tab "..i)
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
 local extra=frame.referenceExtra or 0;local split=frame.referenceSplit or 0
 local pieces={}
 for _,a in ipairs(tiles) do
  local dx,dy,iw,ih,tw,th=a[2],a[3],a[4],a[5],a[6],a[7]
  local rep=frame.referenceRepeat;local endTop=rep and rep.at+rep.h
  if rep and rep.cut then
   -- Fewer rows than the art holds: whole row slices are removed between two separator lines (never stretched): the top part
   -- ends after a separator, the rest of the art (last row(s) and the foot) follows it directly.
   local c=rep.cut
   table.insert(pieces,{a[1],dx,dy,iw,c.topEnd-dy,iw/tw,0,(c.topEnd-dy)/th})
   table.insert(pieces,{a[1],dx,c.topEnd,iw,dy+ih-c.restFrom,iw/tw,(c.restFrom-dy)/th,ih/th})
  elseif rep and rep.count>0 and endTop>dy and endTop<dy+ih then
   -- Extra rows: the art row slice [at,at+h) is repeated `count` times, so sockets and separators stay periodic.
   table.insert(pieces,{a[1],dx,dy,iw,endTop-dy,iw/tw,0,(endTop-dy)/th})
   for c=0,rep.count-1 do table.insert(pieces,{a[1],dx,endTop+c*rep.h,iw,rep.h,iw/tw,(rep.at-dy)/th,(endTop-dy)/th}) end
   table.insert(pieces,{a[1],dx,endTop+rep.count*rep.h,iw,dy+ih-endTop,iw/tw,(endTop-dy)/th,ih/th})
  elseif extra>0 and split>dy and split<dy+ih then
   table.insert(pieces,{a[1],dx,dy,iw,split-dy,iw/tw,0,(split-dy)/th})
   table.insert(pieces,{a[1],dx,split,iw,extra,iw/tw,(split-dy-4)/th,(split-dy+4)/th})
   table.insert(pieces,{a[1],dx,split+extra,iw,dy+ih-split,iw/tw,(split-dy)/th,ih/th})
  else
   table.insert(pieces,{a[1],dx,(extra>0 and dy>=split) and dy+extra or dy,iw,ih,iw/tw,0,ih/th})
  end
 end
 for i=1,math.max(table.getn(pieces),table.getn(frame.referenceTiles)) do
  local t=frame.referenceTiles[i]
  if not t then t=frame:CreateTexture(nil,"BACKGROUND");frame.referenceTiles[i]=t end
  local a=pieces[i]
  if a then
   local asset=T.media.."ReferenceHUD\\"..a[1]
   if t.referenceAsset~=asset then t:SetTexture(asset);t.referenceAsset=asset end
   t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",a[2],-a[3]);t:SetWidth(a[4]);t:SetHeight(a[5])
   if component=="header" and R.key=="elwynn_complete" then local ratio=1+180/R.layout.rects.header[3];t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",a[2]*ratio,-a[3]);t:SetWidth(a[4]*ratio) end
   t:SetTexCoord(0,a[6],a[7],a[8])
   t:SetAlpha((component=="Damage" or component=="Lairs" or component=="Accessories" or component=="Stats" or component=="Effects" or component=="chat") and FieldKit.Number(FieldKitDB.cardOpacity,100,30,100)/100 or 1);t:Show()
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
 R.active=false;R.PartyRestoreAll()
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
 if zone=="elwynn" and variant~="alternative" then
  local a=d.mode;local icon=R.MODE_ICON[R.key]
  -- The info icon ("i" in a gold ring) is part of the foot art, at the right end of the button: the label stays in the free
  -- area to its left (art left cap .. icon - margin) instead of running under it. The whole button stays the click target.
  if icon then Label(H.mode.fieldkitLabel,H.mode,{a[1]+icon.textLeft,a[2],icon.left-icon.margin-icon.textLeft,a[4]},14,true,"CENTER","NotoSerif-Regular.ttf")
  else Label(H.mode.fieldkitLabel,H.mode,{a[1]+3,a[2],a[3]-30,a[4]},14,true,"CENTER","NotoSerif-Regular.ttf") end
 end
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
 R.BarTestApply()
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
  R.chatTools={}
  for i,def in ipairs(R.chatToolDefs) do
   local tool=def
   local b=T.Button(R.chat,nil,def.label,0,0,22,19,function() R.ChatTool(tool.key) end);b.fieldkitChatTool=def.key;R.chatTools[i]=b
   b.fieldkitLabel:ClearAllPoints();b.fieldkitLabel:SetPoint("CENTER",b,"CENTER",0,0);b.fieldkitLabel:SetWidth(22);b.fieldkitLabel:SetJustifyH("CENTER");T.Font(b.fieldkitLabel,12,T.gold,true)
   b:SetScript("OnEnter",function() T.State(this,true);GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(FieldKit_L(tool.tip));GameTooltip:Show() end)
   b:SetScript("OnLeave",function() T.State(this,this.fieldkitSelected);GameTooltip:Hide() end)
  end
 end
 R.Geometry(R.chat,d.rects.chat);R.Art(R.chat,"none");R.chat.fieldkitArtOnly=nil;T.Surface(R.chat,"card",true);T.State(R.chat,false);R.chat:Show()
 for i,b in ipairs(R.chatActions) do if zone=="naxx" and variant=="complete" then b:SetFrameLevel(R.chat:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",R.chat,"TOPLEFT",14+(i-1)*98,-3);b:SetWidth(90);b.fieldkitLabel:SetWidth(80);T.Font(b.fieldkitLabel,14,R.body);b:Show() else b:Hide() end end
 if zone=="naxx" and variant=="complete" then R.chatEntry:SetFrameLevel(R.chat:GetFrameLevel()+15);R.chatEntry:ClearAllPoints();R.chatEntry:SetPoint("BOTTOMLEFT",R.chat,"BOTTOMLEFT",14,20);R.chatEntry:SetWidth(d.rects.chat[3]-30);R.chatEntry:Show() else R.chatEntry:Hide() end
 if d.rate then Label(R.rate,R.chat,d.rate,18,true) end
 if zone=="naxx" and variant=="alternative" then R.Child(R.counts[1],R.chat,d.counts[1]);R.Child(R.counterButtons[1],R.chat,d.counts[1]) end
 local chat=getglobal("ChatFrame1")
 -- The four chat controls come back inside the Elwynn chat card: one column when the card is tall enough, else two columns.
 local toolCols=0
 if zone=="elwynn" and d.rects.chat then
  local inner=d.rects.chat[4]-24;toolCols=(inner>=4*19+6) and 1 or 2
 end
 R.chatToolCols=toolCols
 for i,b in ipairs(R.chatTools or {}) do
  if toolCols>0 then
   local rows=math.ceil(4/toolCols);local col,row=math.floor((i-1)/rows),math.mod(i-1,rows)
   local x=d.rects.chat[3]-12-4-22-(toolCols-1-col)*24;local y=12+row*21
   b:SetFrameLevel(R.chat:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",R.chat,"TOPLEFT",x,-y);b:SetWidth(22);b:SetHeight(19);b:Show()
   R.chatToolRects=R.chatToolRects or {};R.chatToolRects[i]={x,y,x+22,y+19}
  else b:Hide() end
 end
 if chat and d.chatText then
  H.Save(chat);local a=d.chatText;if zone=="elwynn" then a={d.rects.chat[1]+14,d.rects.chat[2]+9,d.rects.chat[3]-28-toolCols*24,d.rects.chat[4]-18} end;chat:SetParent(R.chat);if FieldKit.ThemeChatFont then FieldKit.ThemeChatFont(T.media.."AzerothSans.ttf",12,"") end
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
 if M.probe.rim==false then if M.rim then M.rim:Hide() end;return end
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
 if M.Lift then M.Lift() end
end
-- Tooltip title of a launcher proxy: the addon's readable name, never its technical frame name. The parked original is
-- off screen, so its own tooltip cannot be reused.
function R.LauncherLabel(name)
 local label=string.gsub(name or "","MinimapButton$","")
 label=string.gsub(label,"Minimap$","")
 if label=="" then label=name or "?" end
 return label
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
 if not M.follower then
  -- The client caches the native map geometry: while the card (or the whole identity group) is being dragged, refresh
  -- the map each time its owner has moved, so the map texture cannot lag behind (or leave) its frame.
  local follower=CreateFrame("Frame");M.follower=follower;follower.t=0
  follower:SetScript("OnUpdate",function()
   local owner=(M.root and M.root.azsMoving and M.root) or (H.identity and H.identity.azsMoving and H.identity) or (M.dragOwner and M.dragOwner.azsMoving and M.dragOwner)
   if not owner or M.probe.follower==false then M.followStamp=nil;return end
   follower.t=follower.t+(arg1 or 0);if follower.t<.03 then return end;follower.t=0
   local stamp=tostring(owner:GetLeft())..":"..tostring(owner:GetTop())
   if stamp~=M.followStamp then M.followStamp=stamp;Minimap:Hide();Minimap:Show() end
  end)
 end
 -- No FieldKit frame covers the map any more: the old drag handle sat over the native map and the map's own buttons, and
 -- the native map's mouse was switched off while the HUD was unlocked. The group is moved from the identity card or the
 -- art frame (rim, title, foot); the map interior and every button on it keep the client's native hit testing.
 if M.dragHandle then M.dragHandle:Hide();M.dragHandle:EnableMouse(false) end
 M.root:EnableMouse(M.GroupOwner()==M.root)
 M.launcherProxies=M.launcherProxies or {}
 if M.probe.proxies==false then for _,proxy in pairs(M.launcherProxies) do proxy:Hide() end;M.Unpark() end
 for i,name in ipairs({"FieldKitMinimapButton","AzerothStatsMinimap","AzerothOneMinimapButton"}) do
  local original=M.probe.proxies~=false and getglobal(name)
  if original then
   local proxy=M.launcherProxies[i]
   if not proxy then
    proxy=CreateFrame("Button",nil,M.root);proxy:SetWidth(30);proxy:SetHeight(30);proxy.icon=proxy:CreateTexture(nil,"ARTWORK");proxy.icon:SetAllPoints(proxy);proxy:RegisterForClicks("LeftButtonUp","RightButtonUp")
    local launcherName=name -- Lua 5.0: a generic-for variable captured by a closure is nil once the loop ends
    proxy:SetScript("OnClick",function() local target=getglobal(launcherName);local handler=target and target.GetScript and target:GetScript("OnClick");if handler then local old=this;this=target;handler();this=old end end) -- the owner's CURRENT frame, looked up at click time
    proxy:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:AddLine(R.LauncherLabel(launcherName),1,.85,.55);GameTooltip:AddLine(FieldKit_L("Click to open"),.8,.8,.8);GameTooltip:Show() end);proxy:SetScript("OnLeave",function() GameTooltip:Hide() end)
    M.launcherProxies[i]=proxy
   end
   local texture=original.icon or original.texture;local path=texture and texture.GetTexture and texture:GetTexture();if not path and original.GetNormalTexture then local n=original:GetNormalTexture();path=type(n)=="string" and n or (n and n.GetTexture and n:GetTexture()) end
   proxy.icon:SetTexture(path or (i==1 and T.media.."ChronicleSeal.tga" or "Interface\\Icons\\INV_Misc_Book_09"));proxy:ClearAllPoints();local left=a[1]<R.layout.size[1]/2;proxy:SetPoint(left and "TOPLEFT" or "TOPRIGHT",M.root,left and "TOPRIGHT" or "TOPLEFT",left and 5 or -5,-8-(i-1)*36);proxy:SetFrameStrata("HIGH");proxy:SetFrameLevel(M.root:GetFrameLevel()+80);M.Park(original);if original:GetAlpha()>.01 then proxy:Show() else proxy:Hide() end
  end
 end
 M.root:SetMovable(M.GroupOwner()==M.root);M.Layers()
 if M.probe.ring then local band,keep=R.RingGeometry(R.layout,hole);M.Ring(hole[3]/2,hole[4]/2,band,keep) else M.RingRestore() end
 local over=type(MouseIsOver)=="function" and (MouseIsOver(Minimap) or MouseIsOver(M.zoomOut) or MouseIsOver(M.zoomIn))
 for i,b in ipairs({M.zoomOut,M.zoomIn}) do
  local x,y=R.ZoomXY(i,a)
  R.Child(b,M.root,{x,y,24,25});R.Stable(b,"z"..R.key..":"..M.root:GetFrameLevel(),function() b:SetFrameStrata("DIALOG");b:SetFrameLevel(80);b:Hide();b:Show() end);Blank(b);T.Font(b.fieldkitLabel,18,T.gold,true);b.fieldkitLabel:SetText((R.key=="elwynn_minimal" or R.key=="elwynn_complete") and "" or (i==1 and "-" or "+"))
  if T.zone=="elwynn" or over then if not b:IsShown() then b:Show() end else b:Hide() end
 end
 return true
end
-- Effects list geometry comes from the measured art (rows of the Effects tile): the header rule ends at y 44 (Elwynn) / 49 (Naxx)
-- and the bottom border starts at y 99 / 105. The list lives between them: top = rule + 2, bottom = card height - inset
-- (Elwynn 17, Naxx 20), two rows share that height, the icon is centred on its row with equal padding above and below.
R.EFFECT={x=64,rightPad=27,gap=8,iconMax=20,zones={elwynn={top=46,bottom=17},naxx={top=51,bottom=20}}}
R.EFFECT_ICON={size=20,gap=8}
function R.EffectBox(zone,height)
 local z=R.EFFECT.zones[zone] or R.EFFECT.zones.elwynn
 local bottom=height-z.bottom
 local rowH=math.floor((bottom-z.top-1)/2)
 return {top=z.top,bottom=bottom,rowH=rowH,step=rowH+1}
end
function R.EffectIcon(r,texture)
 local k=R.EFFECT;local h=r:GetHeight();local size=math.min(k.iconMax,h-4)
 R.EFFECT_ICON.size=size;R.EFFECT_ICON.gap=k.gap
 r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-(size+k.gap),-math.floor((h-size)/2))
 r.icon:SetWidth(size);r.icon:SetHeight(size);r.icon:SetTexCoord(.07,.93,.07,.93);r.icon:SetVertexColor(1,1,1,1);r.icon:SetTexture(texture);r.icon:Show()
end
function R.AmountParts(r)
 if r.amount then return end
 r.amount=r:CreateFontString(nil,"OVERLAY","GameFontNormal");T.Font(r.amount,14,T.muted)
 r.amountSep=r:CreateTexture(nil,"ARTWORK");T.Solid(r.amountSep,{1,.82,.12},.3)
end
local function Row(f,i,x,y,w,h,hidden)
 local r=f.rows[i];r.label:SetJustifyH("LEFT");r.label:SetJustifyV("MIDDLE");r.value:SetJustifyH("RIGHT");r.fieldkitLine=nil;r.fieldkitSpell=nil;r.fontSize=nil;r.fontMin=nil;r.labelTint=nil;r.valueTint=nil;r.buffIndex=nil;r.fieldkitUsed=true
 -- Re-levelling / re-anchoring a button on every refresh can cancel a click in progress: only when it changes.
 R.Stable(r,table.concat({x,y,w,h,f:GetFrameLevel()},":"),function() r:SetFrameLevel(f:GetFrameLevel()+5);r.bar:SetFrameLevel(r:GetFrameLevel()+1);r:ClearAllPoints();r:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y);r:SetWidth(w);r:SetHeight(h) end)
 r:SetAlpha(1);if not hidden then r:Show() end;r.icon:Hide();r.bar:Hide();if r.trough then r.trough:Hide() end;if r.lamp then r.lamp:Hide() end;r.entry=nil
 if r.amount then r.amount:SetText("");r.amountSep:Hide() end
 r.label:ClearAllPoints();r.label:SetPoint("TOPLEFT",r,"TOPLEFT",0,0);r.label:SetWidth(w-96);r.label:SetHeight(h);r.value:ClearAllPoints();r.value:SetPoint("TOPRIGHT",r,"TOPRIGHT",0,0);r.value:SetWidth(94);r.value:SetHeight(h);return r
end
-- Damage categories: 3x2 grid of contiguous hit areas. Layout is applied only when it changes: re-levelling or
-- re-anchoring a button on every refresh can cancel a click that is in progress in this client.
R.listTop=90 -- Elwynn: first list row (below the navigation row)
R.tabTips={"Damage","Healing","Boss","Damage taken","Groups","Kills"}
function R.DamageTabs(f,a,zone,index)
 local elwynn=zone=="elwynn"
 local top=elwynn and 50 or 92
 local cols=elwynn and 6 or 3
 local tabW=(a[3]-48)/cols;local tabH=elwynn and 30 or 25
 local x0=24
 if elwynn then tabW=math.floor(tabW);x0=24+math.floor((a[3]-48-cols*tabW)/2) end -- whole pixels: contiguous cells, no sub-pixel gaps
 -- Banner structure (drawn once per geometry): thin separator under the title row, darker navigation strip behind the
 -- categories, thin rule under it, hairline dividers between the six cells.
 local bandKey=table.concat({a[3],zone,top,x0,tabW},":")
 if f.bandKey~=bandKey then
  f.bandKey=bandKey
  if not f.navBand then f.navBand=f:CreateTexture(nil,"ARTWORK");f.headRule=f:CreateTexture(nil,"ARTWORK");f.navRule=f:CreateTexture(nil,"ARTWORK");f.navDividers={} end
  local bandH=elwynn and tabH+4 or 54
  T.Solid(f.navBand,{0,0,0},.30);f.navBand:ClearAllPoints();f.navBand:SetPoint("TOPLEFT",f,"TOPLEFT",20,-(top-2));f.navBand:SetWidth(a[3]-40);f.navBand:SetHeight(bandH);f.navBand:Show()
  T.Solid(f.navRule,{1,.82,.12},.45);f.navRule:ClearAllPoints();f.navRule:SetPoint("TOPLEFT",f,"TOPLEFT",20,-(top-2+bandH));f.navRule:SetWidth(a[3]-40);f.navRule:SetHeight(1);f.navRule:Show()
  if elwynn then T.Solid(f.headRule,{1,.82,.12},.55);f.headRule:ClearAllPoints();f.headRule:SetPoint("TOPLEFT",f,"TOPLEFT",20,-(top-4));f.headRule:SetWidth(a[3]-40);f.headRule:SetHeight(1);f.headRule:Show() else f.headRule:Hide() end
  for n=1,5 do
   local d=f.navDividers[n];if not d then d=f:CreateTexture(nil,"ARTWORK");f.navDividers[n]=d end
   if elwynn then T.Solid(d,{1,.82,.12},.22);d:ClearAllPoints();d:SetPoint("TOPLEFT",f,"TOPLEFT",x0+n*tabW,-(top+4));d:SetWidth(1);d:SetHeight(tabH-8);d:Show() else d:Hide() end
  end
 end
 for i,b in ipairs(R.tabs) do
  local key=table.concat({a[3],zone,index==i and 1 or 0,tostring(FieldKitDB.language),tostring(f:GetFrameLevel())},":")
  if b.layoutKey~=key then
   b.layoutKey=key;local col,row=math.mod(i-1,cols),math.floor((i-1)/cols)
   b:SetFrameLevel(f:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",x0+col*tabW,-(top+row*25));b:SetWidth(tabW);b:SetHeight(tabH)
   b.fieldkitLabel:ClearAllPoints();b.fieldkitLabel:SetPoint("CENTER",b,"CENTER",0,elwynn and 1 or 0);b.fieldkitLabel:SetWidth(tabW-6);b.fieldkitLabel:SetHeight(tabH-4);b.fieldkitLabel:SetJustifyH("CENTER")
   T.Font(b.fieldkitLabel,elwynn and 12 or 13,index==i and {1,.82,.12} or R.body,true);b.fieldkitSelected=index==i;Blank(b)
   if elwynn and R.Fit then R.Fit(b.fieldkitLabel,12,9) end
   if not b.underline then b.underline=b:CreateTexture(nil,"ARTWORK");b.underline:SetHeight(2);b.underline:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",3,1);b.underline:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-3,1) end
   T.Solid(b.underline,{1,.82,.12});if index==i then b.underline:Show() else b.underline:Hide() end
   if not b.activeTile then b.activeTile=b:CreateTexture(nil,"BACKGROUND") end
   T.Solid(b.activeTile,{1,.82,.12},.14);b.activeTile:ClearAllPoints();b.activeTile:SetPoint("TOPLEFT",b,"TOPLEFT",2,-1);b.activeTile:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2);if index==i then b.activeTile:Show() else b.activeTile:Hide() end
   -- full category name in the tooltip (the sixth label is an abbreviation in the narrow cell)
   local tip=R.tabTips[i];local base=b:GetScript("OnEnter")
   b:SetScript("OnEnter",function() T.State(this,true);if GameTooltip then GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(FieldKit_L(tip));GameTooltip:Show() end end)
   b:SetScript("OnLeave",function() T.State(this,this.fieldkitSelected);if GameTooltip then GameTooltip:Hide() end end)
  end
  b:Show()
 end
end
-- Socket geometry measured on the approved Equipment art (reference px, card-local): icons are centred in them.
local SOCKETS={elwynn={x=32,y=51,step=36,w=28,h=28},naxx={x=32,y=57,step=34.75,w=38,h=30}}
function R.SocketY(zone,i,n) local s=SOCKETS[zone] or SOCKETS.elwynn
 local cut=n and n<5 and R.AccCut(zone,n)
 if cut then
  -- shrunk card: the rows kept in the top part keep their place, the rows of the art's tail follow the removed height
  if i<=cut.rowsTop then return math.floor(s.y+s.step*(i-1)+.5) end
  if zone=="naxx" then return math.floor(161.5+35*(i-cut.rowsTop-1)+cut.delta+.5) end
  return math.floor(195+cut.delta+.5)
 end
 if zone=="naxx" and i>3 then return math.floor(126.5+35*(i-3)+.5) end -- rows 4+ come from the repeated 35 px art slice
 return math.floor(s.y+s.step*(i-1)+.5) end
function R.SocketH(zone) return (SOCKETS[zone] or SOCKETS.elwynn).h end
function R.SocketIcon(r,zone,texture)
 local s=SOCKETS[zone] or SOCKETS.elwynn;local size=math.min(s.w,s.h)-4
 r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",s.x+(s.w-size)/2-72,-(s.h-size)/2);r.icon:SetWidth(size);r.icon:SetHeight(size)
 r.icon:SetTexCoord(.07,.93,.07,.93);r.icon:SetTexture(texture);r.icon:Show()
end
-- Click accounting for the native recette (/fieldkit clickdiag): presses, releases, clicks and hides per tab.
function R.DiagHook(b,label)
 if b.fieldkitDiag then return end
 local d={label=label,down=0,up=0,click=0,hide=0};b.fieldkitDiag=d
 R.diagButtons=R.diagButtons or {};table.insert(R.diagButtons,d)
 local callback=b.callback;b.callback=function() d.click=d.click+1;if callback then callback() end end
 b:SetScript("OnMouseDown",function() d.down=d.down+1 end);b:SetScript("OnMouseUp",function() d.up=d.up+1 end);b:SetScript("OnHide",function() d.hide=d.hide+1 end)
end
-- Full hover tooltip for a meter line: what the client's own GameTooltip and the hit ledger really know, nothing invented.
function R.DamageTip(row)
 local e=row.fieldkitLine;if not e then return false end
 local ledger=FieldKitMeterLedger
 local st=ledger and ledger.Stats and FieldKitDB.meterSpellTips~=false and ledger.Stats(e.name,e.spellId,e.icon) or nil
 local share,dps,dmg=FieldKit.Number(e.share),FieldKit.Number(e.dps),FieldKit.Number(e.dmg)
 local white,soft={1,1,1},{.85,.85,.85}
 local function Add(list,label,value,color) list[table.getn(list)+1]={FieldKit_L(label)..": "..value,color or soft} end
 local damage,crits,other={},{},{}
 if dmg then Add(damage,"Total",string.format("%d",math.floor(dmg+.5)),white) end
 if dps then Add(damage,"DPS",string.format("%.1f",dps)) end
 if st then
  if st.avg>0 then Add(damage,"Average",string.format("%.0f",st.avg)) end
  if st.maxHit>0 then Add(damage,"Maximum",string.format("%d",st.maxHit)) end
  if st.burst>0 then Add(damage,"Burst (1s)",string.format("%d",st.burst),{.7,.85,1}) end
  if st.crits>0 then Add(crits,"Critical hits",tostring(st.crits),{1,.65,.3}) end
  if st.hits>0 then Add(crits,"Crit rate",string.format("%.0f%%",st.critPct),{1,.65,.3}) end
  if st.maxCrit>0 then Add(crits,"Max crit",string.format("%d",st.maxCrit),{1,.55,.2}) end
  if st.hits>0 then Add(other,"Hits",tostring(st.hits)) end
  if st.kills>0 then Add(other,"Kills",tostring(st.kills),{.9,.75,.4}) end
 end
 H.RichTip(row,{icon=e.icon or (FieldKitLoadout and FieldKitLoadout.Icon and FieldKitLoadout.Icon(e.name)),title=tostring(e.displayName or e.name or "?"),
  sub=share and (FieldKit_L("Share of total")..": "..string.format("%.1f%%",share*100)) or nil,
  sections={{head=FieldKit_L("Damage"),lines=damage},{head=FieldKit_L("Critical hits"),lines=crits},{head=FieldKit_L("Other"),lines=other}}})
 return true
end
-- "All statistics" opens the Bonuses card in place: it grows downward by exactly what the rows need, the Effects card
-- below follows (unless the user moved it), and the growth stops at the screen edge; beyond that the rows scroll.
function R.ToggleStats() R.statsOpen=not R.statsOpen;R.scroll=R.scroll or {};R.scroll.Stats=0;FieldKitZoneThemes.Refresh(true) end
function R.StatsCapFor(zone,base,extra)
 local step,head,foot=zone=="naxx" and 27 or 29,49,zone=="naxx" and 44 or 56
 return math.max(1,math.floor((base[4]+extra-head-foot)/step))
end
function R.StatsPlan(zone,d)
 R.statsExtra=0;R.statsCap=nil;R.statsN=0
 local base=d.rects.Stats;if not base then return end
 local source=getglobal("FieldKitStatsFrame");local n=0
 for _,s in ipairs(source and source.rows or {}) do if s.label:IsShown() then n=n+1 end end
 R.statsN=n;if not R.statsOpen then return end
 local step,head,foot=zone=="naxx" and 27 or 29,49,zone=="naxx" and 44 or 56
 R.statsExtra=math.max(0,head+n*step+foot-base[4]);R.statsCap=R.StatsCapFor(zone,base,R.statsExtra)
end
-- Spells tab: up to seven rows; the card grows by the missing socket rows (art slice repeated).
local GROW={elwynn_complete={Damage={top=0,extra=68,split=110},Lairs={top=0,extra=8,split=70}}}
-- Damage: the approved card holds six lines; every further line adds one row step. The extra height uses the same plain body
-- band the approved layout already stretches (Elwynn 110, Naxx 200: measured, side borders identical along the band).
local DMG={elwynn={step=29,split=110,base=6},naxx={step=30,split=200,base=6}}
function R.DmgZone() return R.key=="naxx_complete" and "naxx" or "elwynn" end
function R.DmgDelta(n) local k=DMG[R.DmgZone()];return math.max(0,(n or k.base)-k.base)*k.step end
-- Equipment / Spells: the card height follows the content of the active tab. The art holds five rows. More rows repeat the
-- art's row slice (as before); fewer rows remove whole row slices between two separators; corners, ornaments and borders are
-- never stretched. Cut points were measured on the art (the separator lines): Elwynn keeps rows 1..n-1 in the top part and the
-- last row in the tail (min 1 row), Naxx keeps rows 1..n-2 and its two tail rows (min 3 rows).
local ACC_CUT={elwynn={top={[0]=44,[1]=83,[2]=119,[3]=156},restFrom=191,tailRows=1,minRows=1,base=191},
 naxx={top={[1]=87,[2]=121},restFrom=156,tailRows=2,minRows=3,base=156}}
function R.AccZone(zone) return zone or (R.key=="naxx_complete" and "naxx" or "elwynn") end
function R.AccMin(zone) return ACC_CUT[R.AccZone(zone)].minRows end
function R.AccCut(zone,n)
 local c=ACC_CUT[R.AccZone(zone)];local rowsTop=n-c.tailRows;local topEnd=c.top[rowsTop]
 if not topEnd then return nil end
 return {topEnd=topEnd,restFrom=c.restFrom,rowsTop=rowsTop,delta=topEnd-c.base}
end
function R.AccDelta(zone,n)
 zone=R.AccZone(zone);local step=zone=="naxx" and 35 or 36
 if n>5 then return (n-5)*step end
 if n<5 then local c=R.AccCut(zone,n);return c and c.delta or 0 end
 return 0
end
function R.AccShape(zone,n)
 zone=R.AccZone(zone);n=n or R.accN or 5
 if n==5 then R.accShape=nil;return nil end
 local step=zone=="naxx" and 35 or 36
 if n>5 then R.accShape={delta=(n-5)*step,rep={at=zone=="naxx" and 121 or 155,h=step,count=n-5}}
 else local c=R.AccCut(zone,n);R.accShape=c and {delta=c.delta,rep={at=0,h=0,count=0,cut=c}} or nil end
 return R.accShape
end
function R.AccPlan(zone,d)
 R.accShape=nil;R.accN=5;R.accWanted=5;R.accScroll=false
 if FieldKitDB.loadoutTab~=2 then return end
 zone=R.AccZone(zone)
 local total=table.getn(FieldKitLoadout.spells or {})
 local want=math.max(R.AccMin(zone),math.min(24,total))
 R.accWanted=want;R.accN=want
 if d and d.rects.Accessories then R.accN=math.max(R.AccMin(zone),math.min(want,R.AccMaxRows(zone,d))) end
 R.accScroll=total>R.accN
 R.AccShape(zone,R.accN)
end
-- Damage: all the lines of the active category when the screen has room for the grown card (read once per refresh and reused
-- by the renderer: the ledger is not recomputed).
function R.DmgPlan(zone,d)
 R.dmgN=6;R.dmgRead=nil;R.dmgScroll=false
 if not d or not d.rects.Damage or not (R.key=="elwynn_complete" or R.key=="naxx_complete") then return end
 local view=FieldKitMeterSuite.View()
 local lines,total,rate,known=FieldKitMeterLedger.Read(view)
 R.dmgRead={view=view,lines=lines,total=total,rate=rate,known=known}
 local count=table.getn(lines or {})
 R.dmgWanted=math.max(6,math.min(24,count));R.dmgN=R.dmgWanted
 if R.dmgWanted>6 then R.dmgN=math.max(6,math.min(R.dmgWanted,R.DmgMaxRows(d))) end
 R.dmgScroll=count>R.dmgN
end
-- ===== Placement: preferred position (default rectangle or the user's saved spot) vs displayed position. =====
-- Pure function of the preferred layout, the visible card sizes and the protected HUD rectangles: nothing is stored,
-- so a card returns to its preferred place as soon as the room is free again, and the search cannot oscillate.
local CARDS={"Damage","Lairs","Accessories","Stats","Effects"}
local OBSTACLES={"header","chat","identity","nav","vitality","mapArt"}
local GAP,TOLERANCE=4,6 -- visual gap after a push; overlaps up to 6 px are the approved art's own and are left alone
-- Opaque insets (left, top, right, bottom) measured on the approved art: collisions use what is really drawn.
local OPAQUE={
 elwynn_complete={header={8,12,8,10},chat={4,9,0,11},identity={7,8,10,7},nav={0,11,7,0},vitality={6,9,8,8},
  Damage={10,6,0,6},Lairs={10,9,9,7},Accessories={8,5,8,6},Stats={8,7,7,8},Effects={8,5,7,11}},
 naxx_complete={header={11,10,11,11},chat={8,7,0,13},identity={8,9,11,0},vitality={0,0,0,0},mapArt={9,9,11,5},
  Damage={4,1,6,5},Lairs={7,2,5,9},Accessories={9,0,11,0},Stats={10,0,11,0},Effects={9,3,9,10}}}
local PREFS={Damage="meterFrame",Lairs="lairFrame",Accessories="gearFrame",Stats="statsFrame",Effects="effectsFrame"}
local NATIVE={Damage="FieldKitMeterFrame",Lairs="FieldKitLairFrame",Accessories="FieldKitGearFrame",Stats="FieldKitStatsFrame",Effects="FieldKitEffectsFrame"}
local function Inset(name) local t=OPAQUE[R.key];return (t and t[name]) or {6,6,6,6} end
function R.CardVisible(kind,d)
 local folded=(kind=="Stats" and FieldKitDB.statsCollapsed) or (kind=="Accessories" and FieldKitDB.gearCollapsed) or (FieldKitDB.collapsedWindows and FieldKitDB.collapsedWindows[NATIVE[kind]])
 return d.rects[kind] and FieldKitDB[PREFS[kind]] and not folded and not (kind=="Damage" and FieldKitZoneThemes.nativeMeterOpen)
end
-- Preferred rectangle in canvas reference px, with the same corner rule as R.Geometry.
-- Geometry of the ring around the map opening, from the real art (layout rectangles): the thickness of the decorative border
-- is the smallest gap between the opening and the opaque edge of the frame that holds it (the title and foot are far larger
-- gaps, so the minimum is the border itself), and the title, the foot and the zoom buttons are keep-out rectangles.
function R.ZoomXY(i,a)
 local x,y=a[1]+a[3]-29,a[2]+a[3]-(i==1 and 28 or 60)
 if T.zone=="elwynn" and R.key=="elwynn_minimal" then x=a[1]+a[3]-16 end
 if T.zone=="elwynn" and R.key=="elwynn_complete" then x=a[1]+a[3]-24;y=a[2]+a[3]-(i==1 and 42 or 74) end
 return x,y
end
function R.RingGeometry(d,hole)
 local name=d.rects.mapArt and "mapArt" or "identity";local r=d.rects[name];local band=1000000
 if r then
  local n=Inset(name);local l,t,rr,b=r[1]+n[1],r[2]+n[2],r[1]+r[3]-n[3],r[2]+r[4]-n[4]
  for _,gap in ipairs({hole[1]-l,hole[2]-t,rr-(hole[1]+hole[3]),b-(hole[2]+hole[4])}) do if gap>0 and gap<band then band=gap end end
 end
 if band>=1000000 then band=0 end
 local cx,cy=hole[1]+hole[3]/2,hole[2]+hole[4]/2;local keep={}
 local function Add(x,y,w,h) table.insert(keep,{l=x-cx,r=x+w-cx,top=cy-y,bottom=cy-(y+h)}) end
 if d.zone then Add(d.zone[1],d.zone[2],d.zone[3],d.zone[4]) end
 if d.mode then Add(d.mode[1],d.mode[2],d.mode[3],d.mode[4]) end
 for i=1,2 do local x,y=R.ZoomXY(i,d.map);Add(x,y,24,25) end
 return band,keep
end
function R.Preferred(kind,d)
 local rect=R.CardRect(kind,d,true);local s=FieldKitZoneThemes.ElementScale("FieldKitReferencePanel"..kind) or 1
 local w,h=rect[3]*s,rect[4]*s;local cx,cy=rect[1]+rect[3]/2,rect[2]+rect[4]/2
 local x=cx>d.size[1]*2/3 and rect[1]+rect[3]-w or (cx<d.size[1]/3 and rect[1] or rect[1]+(rect[3]-w)/2)
 local y=cy>d.size[2]*2/3 and rect[2]+rect[4]-h or (cy<d.size[2]/3 and rect[2] or rect[2]+(rect[4]-h)/2)
 return x,y,w,h
end
-- A card the user placed: its live rectangle in canvas reference px (nil when it cannot be measured yet).
function R.LiveRect(frame)
 local c=R.canvas
 if not (frame.GetLeft and c and c.GetLeft and frame:GetLeft() and c:GetLeft() and frame.GetEffectiveScale and c.GetEffectiveScale) then return nil end
 local cs,fs=c:GetEffectiveScale(),frame:GetEffectiveScale();if not cs or cs<=0 then return nil end
 local l,t=(frame:GetLeft()*fs-c:GetLeft()*cs)/cs,(c:GetTop()*cs-frame:GetTop()*fs)/cs
 return l,t,frame:GetWidth()*fs/cs,frame:GetHeight()*fs/cs
end
-- Priority (documented): 1) the Bonuses card while expanded, 2) the card the user moved last, 3) top-to-bottom,
-- left-to-right, then fixed card order. A card that must give way is moved: down first, then up, then sideways.
function R.NoteMoved(name)
 local kind=nil
 for _,k in ipairs(CARDS) do if "FieldKitReferencePanel"..k==name then kind=k end end
 if not kind then
  local i=nil;for n=0,4 do if name==(n==0 and "FieldKitPlayerCard" or "FieldKitPartyCard"..n) then i=n end end
  if i then local f=getglobal(name);R.lastParty="Party"..i;if f then f.fieldkitApplied=nil;f.fieldkitDX,f.fieldkitDY=nil,nil end;if R.shift then R.shift["Party"..i]=nil end;if R.shiftX then R.shiftX["Party"..i]=nil end end
  return
 end
 R.lastMoved=kind;local f=R.frames[kind];if f then f.fieldkitDX,f.fieldkitDY=nil,nil end
 local before=R.dragDiag and FieldKitZoneThemes.Position(f) and {FieldKitZoneThemes.Position(f)[3],FieldKitZoneThemes.Position(f)[4]}
 R.ClampToScreen(kind)
 if R.dragDiag and before then local a=FieldKitZoneThemes.Position(f);R.dragReport=kind
  DEFAULT_CHAT_FRAME:AddMessage(string.format("dragdiag drop %s: saved %.0f,%.0f -> after screen clamp %.0f,%.0f",kind,before[1],before[2],a[3],a[4])) end
 if R.shift then R.shift[kind]=nil end;if R.shiftX then R.shiftX[kind]=nil end
end
-- The canvas is the reference rectangle fitted into the screen; the real screen can extend past it (other aspect ratios).
-- Returns left, top, right, bottom of the REAL screen in canvas reference px (the canvas itself when it cannot be measured).
-- Real screen size in pixels. UIParent:GetWidth()*scale is NOT reliable on this client (the right and top limits it fed were
-- ~10% short: left/bottom, which do not use it, were correct), so several independent sources are compared and the largest
-- is used (a limit that is too small blocks cards; one that is a little too large only lets a drop go beyond the edge).
function R.ScreenSize()
 local candidates={}
 local function Add(name,w,h) if type(w)=="number" and type(h)=="number" and w>0 and h>0 then table.insert(candidates,{name=name,w=w,h=h}) end end
 local us=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
 Add("UIParent*scale",UIParent:GetWidth()*us,UIParent:GetHeight()*us)
 if WorldFrame and WorldFrame.GetWidth then local es=WorldFrame.GetEffectiveScale and WorldFrame:GetEffectiveScale() or 1;Add("WorldFrame",WorldFrame:GetWidth()*es,WorldFrame:GetHeight()*es) end
 if type(GetScreenWidth)=="function" and type(GetScreenHeight)=="function" then Add("GetScreen*scale",GetScreenWidth()*us,GetScreenHeight()*us) end
 local best
 for _,c in ipairs(candidates) do if not best or c.w*c.h>best.w*best.h then best=c end end
 return best and best.w or nil,best and best.h or nil,candidates,best
end
-- The canvas is the reference rectangle fitted (and scaled by the theme size setting) into the screen: the real screen can
-- extend past it. Returns left, top, right, bottom of the REAL screen in canvas reference px (the canvas itself if unmeasurable).
function R.ScreenBounds(d)
 local c=R.canvas
 if c and c.GetLeft and c.GetTop and c:GetLeft() and c:GetTop() and c.GetEffectiveScale then
  local cs=c:GetEffectiveScale();local w,h=R.ScreenSize()
  if cs and cs>0 and w then return -c:GetLeft(),(c:GetTop()*cs-h)/cs,(w-c:GetLeft()*cs)/cs,c:GetTop() end
 end
 return 0,0,d.size[1],d.size[2]
end
-- A card is clamped by what is drawn, not by its technical rectangle: the transparent margins may leave the screen.
function R.ApplyClamp(f,kind)
 -- The client keeps the whole TECHNICAL rectangle (its transparent margins included) on screen when SetClampedToScreen is on,
 -- and SetClampRectInsets is not a reliable way out on this client: the clamp is simply off for the cards, and the drop
 -- (R.ClampToScreen) brings the DRAWN art flush with the real edge if it was left beyond it.
 if f.fieldkitClampOff then return end
 f.fieldkitClampOff=true;f:SetClampedToScreen(false)
end
-- At the drop: if the drawn art is beyond the real screen, bring it back flush with the edge (its saved position follows).
function R.ClampToScreen(kind)
 local f=R.frames[kind];local a=f and FieldKitZoneThemes.Position(f);if not a then return end
 local lx,ly,w,h=R.LiveRect(f);if not lx then return end
 local n=Inset(kind);local L,T,Rg,B=R.ScreenBounds(R.layout)
 local l,t,r,b=lx+n[1],ly+n[2],lx+w-n[3],ly+h-n[4];local dx,dy=0,0
 if l<L then dx=L-l elseif r>Rg then dx=Rg-r end
 if t<T then dy=T-t elseif b>B then dy=B-b end
 if dx==0 and dy==0 then return end
 local cs=R.canvas.GetEffectiveScale and R.canvas:GetEffectiveScale() or 1;local fe=f.GetEffectiveScale and f:GetEffectiveScale() or 1
 local k=(fe and fe>0 and cs) and cs/fe or 1
 a[3]=a[3]+dx*k;a[4]=a[4]-dy*k;f:ClearAllPoints();f:SetPoint(a[1],UIParent,a[2],a[3],a[4])
end
-- Opaque rectangles of the protected (non-card) HUD parts, taken from where those frames REALLY are (the user moves them:
-- the identity card, the player block, the navigation...). The layout's default rectangle is only a fallback for a frame
-- that is not shown or cannot be measured yet, so a part that was moved no longer leaves an invisible obstacle behind.
local OBSTACLE_FRAME={header=function() return H.header end,chat=function() return R.chat end,identity=function() return H.identity end,
 nav=function() return H.nav end,vitality=function() return H.healthRoot end,mapArt=function() return FieldKitThemeMinimap and FieldKitThemeMinimap.root end}
local function FixedObstacles(d,report)
 local list={}
 for _,name in ipairs(OBSTACLES) do
  local r=d.rects[name]
  if r then
   local n=Inset(name);local f=OBSTACLE_FRAME[name] and OBSTACLE_FRAME[name]()
   local x,y,w,h
   if f and f.IsShown and f:IsShown() then x,y,w,h=R.LiveRect(f) end
   local source="live"
   if not x or w<=1 or h<=1 then x,y,w,h=r[1],r[2],r[3],r[4];source="default" end
   table.insert(list,{x+n[1],y+n[2],x+w-n[3],y+h-n[4],name=name,source=source})
   if report then table.insert(report,string.format("%-9s %s opaque %.0f,%.0f -> %.0f,%.0f",name,source,x+n[1],y+n[2],x+w-n[3],y+h-n[4])) end
  end
 end
 return list
end
-- Preferred position of a card: default rectangle, or where the user's saved card really is minus our displacement.
function R.PreferredAny(kind,d)
 local f=R.frames[kind]
 if f and FieldKitZoneThemes.Position(f) then
  local lx,ly=R.LiveRect(f)
  if not lx then return nil end
  local rect=R.CardRect(kind,d,true);local s=FieldKitZoneThemes.ElementScale("FieldKitReferencePanel"..kind) or 1
  return lx-(f.fieldkitDX or 0),ly-(f.fieldkitDY or 0),rect[3]*s,rect[4]*s,true
 end
 local x,y,w,h=R.Preferred(kind,d);return x,y,w,h,false
end
-- How far Bonuses may grow before it would meet a protected part of the HUD or the real screen edge: beyond that it scrolls
-- instead of pushing the other cards around.
function R.StatsRoom(d)
 local was=R.statsExtra;R.statsExtra=0
 local x,y,w,h=R.PreferredAny("Stats",d);R.statsExtra=was
 if not x then return 0 end
 local n=Inset("Stats");local l,r,top=x+n[1],x+w-n[3],y+n[2]
 local _,_,_,sb=R.ScreenBounds(d);local limit=sb-8
 for _,o in ipairs(FixedObstacles(d)) do
  if math.min(r,o[3])-math.max(l,o[1])>0 and o[4]>top and o[2]>top then limit=math.min(limit,o[2]-GAP) end
 end
 local s=FieldKitZoneThemes.ElementScale("FieldKitReferencePanelStats") or 1
 return math.max(0,(limit+n[4]-y)/s-d.rects.Stats[4])
end
-- Vertical room for a card that grows (Equipment / Spells, Damage): the free span around its column between a protected part
-- above and the bottom of the screen (or a protected part below). The card may be displayed higher than its preferred top
-- (display only, by the engine) so a card moved low by the user still shows every row; cards below move out of its way.
function R.GrowSpan(kind,d)
 local x,y,w,h=R.PreferredAny(kind,d);if not x then return nil end
 local n=Inset(kind);local l,r,top=x+n[1],x+w-n[3],y+n[2]
 local sl,st,sr,sb=R.ScreenBounds(d);local limit=sb-8;local upper=st+8
 for _,o in ipairs(FixedObstacles(d)) do
  if math.min(r,o[3])-math.max(l,o[1])>0 then
   if o[4]<=top then upper=math.max(upper,o[4]+GAP) elseif o[2]>top then limit=math.min(limit,o[2]-GAP) end
  end
 end
 local s=FieldKitZoneThemes.ElementScale("FieldKitReferencePanel"..kind) or 1
 return (limit-upper+n[2]+n[4])/s
end
function R.AccMaxRows(zone,d)
 local was=R.accShape;R.accShape=nil
 local span=R.GrowSpan("Accessories",d);R.accShape=was
 if not span then return 5 end
 local best=R.AccMin(zone)
 for count=R.AccMin(zone),24 do if d.rects.Accessories[4]+R.AccDelta(zone,count)<=span then best=count else break end end
 return best
end
function R.DmgMaxRows(d)
 local was=R.dmgN;R.dmgN=6
 local span=R.GrowSpan("Damage",d);R.dmgN=was
 if not span then return 6 end
 local base=d.rects.Damage[4]+((GROW[R.key] and GROW[R.key].Damage and GROW[R.key].Damage.extra) or 0)
 local best=6
 for count=6,24 do if base+R.DmgDelta(count)<=span then best=count else break end end
 return best
end
-- Temporary comparison aid (runtime only, never saved): /fieldkit barprobe test <0-100> holds the player's bar at that percentage
-- for 30 s (each refresh re-applies it; the label keeps showing the real health) so 100 / 99 / 80 / 50 / 0 % can be compared with
-- the native texture and with the flat fill (/fieldkit barprobe fill native|flat). /fieldkit barprobe test off cancels it.
function R.BarTestApply()
 local t=R.barTest;if not t then return end
 if GetTime()>t.untilAt then R.barTest=nil;return end
 local bar=H.health;if not bar then return end
 bar:SetMinMaxValues(0,100);bar:SetValue(t.pct)
end
function R.BarTest(pct)
 if pct==nil then R.barTest=nil;return "bar test cancelled" end
 R.barTest={pct=math.max(0,math.min(100,pct)),untilAt=GetTime()+30};R.BarTestApply()
 return string.format("player bar held at %d %% for 30 s (fill %s); the label still shows the real health",R.barTest.pct,tostring(H.health and H.health.fieldkitFillMode))
end
-- /fieldkit barprobe: the PLAYER's own life bar in the Aethus frame (H.health, a StatusBar anchored on H.player inside
-- H.healthRoot). Read-only: nothing is moved, resized or re-filled. Works without a group, with the local character only.
local function Num(v,decimals) if type(v)~="number" then return tostring(v) end return string.format("%."..(decimals or 2).."f",v) end
local function FName(f)
 if not f then return "nil" end
 local ok,name=pcall(function() return f.GetName and f:GetName() end)
 local kind=pcall(function() return f.GetObjectType end) and f.GetObjectType and f:GetObjectType() or "?"
 return (ok and name or "anonymous").."("..tostring(kind)..")"
end
local function Points(f)
 local out={}
 for i=1,8 do
  local ok,p,rel,rp,x,y=pcall(function() return f:GetPoint(i) end)
  if not ok or not p then break end
  local relName=type(rel)=="table" and FName(rel) or tostring(rel)
  table.insert(out,string.format("%s -> %s %s (%s, %s)",tostring(p),relName,tostring(rp),Num(x),Num(y)))
  if i>1 and out[i]==out[i-1] then table.remove(out);break end
 end
 return table.concat(out,"  |  ")
end
local function Size(f) if not f then return "nil" end return Num(f:GetWidth()).." x "..Num(f:GetHeight()) end
local function Call(f,method) if f and f[method] then return f[method](f) end return nil end
local function Edges(f) if not f or not f.GetLeft then return "n/a" end return "L "..Num(Call(f,"GetLeft")).." R "..Num(Call(f,"GetRight")).." T "..Num(Call(f,"GetTop")).." B "..Num(Call(f,"GetBottom")) end
local function Scale(f) if not f then return "nil" end return "scale "..Num(f.GetScale and f:GetScale(),3).." effective "..Num(f.GetEffectiveScale and f:GetEffectiveScale(),3) end
function R.PlayerBarProbe(refill)
 local out={};local function Add(line) table.insert(out,line) end
 local d=R.layout
 Add(string.format("PLAYER BAR | theme %s | layout %s | canvas %s",tostring(R.active),tostring(R.key),R.canvas and Scale(R.canvas) or "none"))
 local bar=H.health
 if not bar or not H.player or not H.healthRoot then Add("the themed player frame does not exist (theme never activated)");return out end
 if not R.active or not bar:IsShown() then Add("the themed player frame is not active/shown now: enable the theme (Elwynn Complete) and run the command again") end
 -- names
 Add("fill mode: "..tostring(bar.fieldkitFillMode).." (flat = opaque WHITE8X8 tinted green, native = stock UI-StatusBar) | test "..tostring(R.barTest and (R.barTest.pct.." %") or "off"))
 Add("note    : the fill texture GetWidth() is its INTRINSIC size (64 in the native probe), not what is drawn; compare the edges, and the picture with /fieldkit barprobe fill native|flat")
 Add("frame   : root "..FName(H.healthRoot).." | player button "..FName(H.player).." | bar "..FName(bar).." parent "..FName(bar:GetParent()))
 Add("levels  : root strata "..tostring(H.healthRoot:GetFrameStrata()).." level "..tostring(H.healthRoot:GetFrameLevel()).." | player level "..tostring(H.player:GetFrameLevel()).." | bar strata "..tostring(bar:GetFrameStrata()).." level "..tostring(bar:GetFrameLevel()))
 -- data
 local cur=type(UnitHealth)=="function" and UnitHealth("player") or nil;local max=type(UnitHealthMax)=="function" and UnitHealthMax("player") or nil
 local frac=(type(cur)=="number" and type(max)=="number" and max>0) and cur/max or nil
 local lo,hi=0,0;if bar.GetMinMaxValues then lo,hi=bar:GetMinMaxValues() end
 local value=bar.GetValue and bar:GetValue()
 local barFrac=(type(value)=="number" and type(hi)=="number" and hi>lo) and (value-lo)/(hi-lo) or nil
 Add(string.format("data    : UnitHealth %s / %s | fraction %s | bar min %s max %s value %s -> bar fraction %s | label \"%s\"",tostring(cur),tostring(max),Num(frac,6),tostring(lo),tostring(hi),tostring(value),Num(barFrac,6),tostring(H.hp and H.hp:GetText())))
 -- sizes and scales
 local expected=d and d.health and d.health[3];local expectedH=d and d.health and d.health[4]
 Add("sizes   : root "..Size(H.healthRoot).." | player "..Size(H.player).." | bar "..Size(bar).." | layout slot "..tostring(expected).." x "..tostring(expectedH).." (reference px)")
 Add("scales  : canvas "..(R.canvas and Scale(R.canvas) or "none").." | root "..Scale(H.healthRoot).." | player "..Scale(H.player).." | bar "..Scale(bar))
 local barPx=(bar:GetWidth() or 0)*(bar.GetEffectiveScale and bar:GetEffectiveScale() or 1)
 local cs=R.canvas and R.canvas.GetEffectiveScale and R.canvas:GetEffectiveScale() or 1
 Add(string.format("pixels  : bar %s screen px | expected from the layout %s screen px (%s ref px x canvas scale %s) | ratio %s",Num(barPx),expected and Num(expected*cs) or "?",tostring(expected),Num(cs,3),expected and Num(barPx/(expected*cs),4) or "?"))
 -- anchors and margins
 Add("anchors : root  "..Points(H.healthRoot))
 Add("anchors : player "..Points(H.player))
 Add("anchors : bar   "..Points(bar))
 Add("edges   : root "..Edges(H.healthRoot).." | player "..Edges(H.player).." | bar "..Edges(bar))
 local bl,pl,br,pr,bt,pt,bb,pb=Call(bar,"GetLeft"),Call(H.player,"GetLeft"),Call(bar,"GetRight"),Call(H.player,"GetRight"),Call(bar,"GetTop"),Call(H.player,"GetTop"),Call(bar,"GetBottom"),Call(H.player,"GetBottom")
 if bl and pl and br and pr and bt and pt and bb and pb then
  Add(string.format("margins : bar inside player: left %s right %s top %s bottom %s",Num(bl-pl),Num(pr-br),Num(pt-bt),Num(bb-pb)))
 end
 -- fill texture
 local tex=bar.GetStatusBarTexture and bar:GetStatusBarTexture();local fillW
 if type(tex)=="table" then
  fillW=tex:GetWidth()
  local tc={pcall(function() return tex:GetTexCoord() end)}
  Add("fill    : texture "..tostring(tex.GetTexture and tex:GetTexture()).." | size "..Size(tex).." | edges "..Edges(tex).." | layer "..tostring(tex.GetDrawLayer and tex:GetDrawLayer()))
  Add("fill    : points "..Points(tex).." | texcoord "..table.concat({tostring(tc[2]),tostring(tc[3]),tostring(tc[4]),tostring(tc[5]),tostring(tc[6]),tostring(tc[7]),tostring(tc[8]),tostring(tc[9])}," "))
  if tex.GetVertexColor then local r,g,b,a=tex:GetVertexColor();Add(string.format("fill    : color %s %s %s alpha %s | shown %s",Num(r),Num(g),Num(b),Num(a),tostring(tex:IsShown()))) end
 else Add("fill    : GetStatusBarTexture returned "..tostring(tex)..": the texture object is not exposed by this client") end
 -- expected vs filled
 local barW=bar:GetWidth() or 0
 local wantFill=barFrac and barW*barFrac or nil
 if fillW and wantFill then
  Add(string.format("COMPARE : expected fill %s (bar width %s x fraction %s) | real fill %s | missing on the right %s px (%s%% of the bar)%s",Num(wantFill),Num(barW),Num(barFrac,6),Num(fillW),Num(wantFill-fillW),barW>0 and Num((wantFill-fillW)/barW*100,1) or "?",(barFrac and barFrac>=0.9999) and " <- full bar" or ""))
  local trr,brr=Call(tex,"GetRight"),Call(bar,"GetRight");if trr and brr then Add(string.format("COMPARE : bar right edge %s | fill right edge %s | gap %s (screen units)",Num(brr),Num(trr),Num(brr-trr))) end
 else Add("COMPARE : not available (no fill width or no fraction)") end
 -- every other texture / child inside the bar (background, shield, text)
 local regions={pcall(function() return bar:GetRegions() end)}
 for i=2,table.getn(regions) do
  local r=regions[i]
  if r and r~=tex then
   local kind=r.GetObjectType and r:GetObjectType() or "?"
   local line="region  : "..tostring(kind).." "..Size(r).." shown "..tostring(r.IsShown and r:IsShown()).." layer "..tostring(r.GetDrawLayer and r:GetDrawLayer()).." points "..Points(r)
   if kind=="Texture" and r.GetVertexColor then local rr,gg,bb,aa=r:GetVertexColor();line=line.." color "..Num(rr)..","..Num(gg)..","..Num(bb)..","..Num(aa) end
   Add(line)
  end
 end
 if H.shield then Add("shield  : "..Size(H.shield).." shown "..tostring(H.shield:IsShown()).." points "..Points(H.shield)) end
 for _,c in ipairs({pcall(function() return bar:GetChildren() end)}) do if type(c)=="table" then Add("child   : "..FName(c).." "..Size(c).." "..Scale(c)) end end
 -- the art slot this bar must fill, from the approved layout (reference px, relative to the vitality art)
 if d and d.health and d.rects and d.rects.vitality then
  local v=d.rects.vitality;Add(string.format("art slot: x %s..%s y %s..%s inside the vitality art %s x %s (slot width %s ref px)",tostring(d.health[1]-v[1]),tostring(d.health[1]-v[1]+d.health[3]),tostring(d.health[2]-v[2]),tostring(d.health[2]-v[2]+d.health[4]),tostring(v[3]),tostring(v[4]),tostring(d.health[3])))
 end
 -- opt-in: force the fill to be recomputed at the current size and read again (the value is restored by the next update)
 if refill and bar.SetValue then
  local keep=bar:GetValue();bar:SetValue(lo);bar:SetValue(keep)
  local tex2=bar.GetStatusBarTexture and bar:GetStatusBarTexture()
  Add("REFILL  : value toggled "..tostring(lo).." -> "..tostring(keep).." ; fill width before "..Num(fillW).." after "..Num(type(tex2)=="table" and tex2:GetWidth() or nil).." (bar width "..Num(barW)..")")
 end
 return out
end
-- Text report for /fieldkit cardprobe: what the engine sees (screen bounds, the obstacles it really uses, every card).
function R.Probe()
 local out={};local d=R.layout;if not d then return {"no reference layout active"} end
 local l,t,r,b=R.ScreenBounds(d)
 table.insert(out,string.format("layout %s | screen in ref px %.0f,%.0f -> %.0f,%.0f | canvas %dx%d | overlap option %s",tostring(R.key),l,t,r,b,d.size[1],d.size[2],tostring(FieldKitDB.zoneThemeOverlap)))
 local _,_,cands,best=R.ScreenSize()
 for _,c in ipairs(cands or {}) do table.insert(out,string.format("  screen source %-16s %.0f x %.0f%s",c.name,c.w,c.h,c==best and "  <- used" or "")) end
 local cv=R.canvas;if cv and cv.GetEffectiveScale then table.insert(out,string.format("  canvas scale %.3f left %s top %s | UIParent scale %s",cv:GetEffectiveScale() or 0,tostring(cv:GetLeft()),tostring(cv:GetTop()),tostring(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()))) end
 local obstacles={};FixedObstacles(d,obstacles);for _,line in ipairs(obstacles) do table.insert(out,"  obstacle "..line) end
 -- Rows: what the grown cards hold and why (never confuse rows created, rows the card holds and rows visible)
 local spells=table.getn(FieldKitLoadout.spells or {});local created=table.getn(R.frames.Accessories.rows);local vis=0;for _,r in ipairs(R.frames.Accessories.rows) do if r:IsShown() then vis=vis+1 end end
 table.insert(out,string.format("  Equipment/Spells: tab %s spells %s | rows created %s wanted %s held %s visible %s | scroll %s | frame height %.0f",tostring(FieldKitDB.loadoutTab),tostring(spells),tostring(created),tostring(R.accWanted),tostring(R.accN),tostring(vis),tostring(R.accScroll),R.frames.Accessories:GetHeight() or 0))
 local dl=R.dmgRead and table.getn(R.dmgRead.lines or {}) or 0;local dvis=0;for _,r in ipairs(R.frames.Damage.rows) do if r:IsShown() and r.fieldkitLine then dvis=dvis+1 end end
 table.insert(out,string.format("  Damage: lines %s | rows created %s wanted %s held %s visible %s | scroll %s | frame height %.0f | room %s",tostring(dl),tostring(table.getn(R.frames.Damage.rows)),tostring(R.dmgWanted),tostring(R.dmgN),tostring(dvis),tostring(R.dmgScroll),R.frames.Damage:GetHeight() or 0,tostring(R.DmgMaxRows(d))))
 table.insert(out,string.format("  Equipment room (rows) %s",tostring(R.AccMaxRows(R.DmgZone(),d))))
 for _,kind in ipairs(CARDS) do
  local f=R.frames[kind];local a=FieldKitZoneThemes.Position(f)
  local lx,ly,lw,lh=R.LiveRect(f)
  table.insert(out,string.format("%-11s shown=%s saved=%s live=%s shift=%s,%s clamp=%s clampAPI=%s",kind,tostring(f:IsShown()),a and string.format("%s/%s %.0f,%.0f",a[1],a[2],a[3],a[4]) or "default",
   lx and string.format("%.0f,%.0f %.0fx%.0f",lx,ly,lw,lh) or "?",tostring(R.shift and R.shift[kind]),tostring(R.shiftX and R.shiftX[kind]),tostring(f.IsClampedToScreen and f:IsClampedToScreen()),tostring(f.SetClampRectInsets~=nil)))
 end
 return out
end
-- Co-op teammate cards (FieldKitPartyCard1-4) in the common placement engine. Their saved position is the one the themed HUD
-- already keeps for every movable card (zoneThemePositions[layout][name]); nothing is migrated or rewritten. The engine only
-- adds a DISPLAY displacement on top of the preferred position, never saved, and never while the card is being dragged.
local function PartySame(a,b) return a and b and a[1]==b[1] and a[2]==b[2] and math.abs(a[3]-b[3])<.01 and math.abs(a[4]-b[4])<.01 end
function R.PartyFrames() local out={};for i=0,4 do local f=getglobal(i==0 and "FieldKitPlayerCard" or "FieldKitPartyCard"..i);if f then table.insert(out,{i,f}) end end;return out end
-- Puts the card on its PREFERRED anchor (saved themed position, else wherever the legacy code left it) and returns the
-- displacement (canvas px) the engine currently applies on top of it.
function R.PartyPrepare(f)
 local p,rel,rp,x,y=f:GetPoint();if not p then return 0,0 end
 local cur={p,rp,x,y}
 if f.fieldkitApplied and PartySame(cur,f.fieldkitApplied) then return f.fieldkitDX or 0,f.fieldkitDY or 0 end
 f.fieldkitApplied=nil;f.fieldkitDX,f.fieldkitDY=nil,nil
 local a=FieldKitZoneThemes.Position(f)
 if a then
  if not PartySame(cur,{a[1],a[2],a[3],a[4]}) then f:ClearAllPoints();f:SetPoint(a[1],UIParent,a[2],a[3],a[4]) end
  f.fieldkitBase={a[1],a[2],a[3],a[4],UIParent}
 else f.fieldkitBase={p,rp,x,y,rel} end
 return 0,0
end
function R.PartyApply(f,dx,dy)
 local base=f.fieldkitBase;if not base then return end
 local cs=R.canvas.GetEffectiveScale and R.canvas:GetEffectiveScale() or 1;local fe=f.GetEffectiveScale and f:GetEffectiveScale() or 1
 local k=(fe and fe>0 and cs) and cs/fe or 1
 local tx,ty=base[3]+dx*k,base[4]-dy*k
 local p,_,rp,x,y=f:GetPoint()
 if not PartySame({p,rp,x,y},{base[1],base[2],tx,ty}) then f:ClearAllPoints();f:SetPoint(base[1],base[5],base[2],tx,ty) end
 if dx==0 and dy==0 then f.fieldkitApplied=nil;f.fieldkitDX,f.fieldkitDY=nil,nil
 else f.fieldkitApplied={base[1],base[2],tx,ty};f.fieldkitDX,f.fieldkitDY=dx,dy end
end
-- Gives the card its preferred place back (card hidden, theme off, layout not complete).
function R.PartyRestore(f)
 if f.fieldkitApplied and f.fieldkitBase and not f.azsMoving then R.PartyApply(f,0,0) end
 f.fieldkitApplied=nil;f.fieldkitDX,f.fieldkitDY=nil,nil
end
function R.PartyRestoreAll() for _,e in ipairs(R.PartyFrames()) do R.PartyRestore(e[2]) end end
-- After the plan: shown cards get their displacement, hidden ones release theirs at once.
function R.PartyPass()
 for _,e in ipairs(R.PartyFrames()) do
  local i,f=e[1],e[2]
  if f:IsShown() and not f.azsMoving then
   R.PartyPrepare(f);R.PartyApply(f,(R.shiftX and R.shiftX["Party"..i]) or 0,(R.shift and R.shift["Party"..i]) or 0)
  else R.PartyRestore(f) end
 end
end
function R.Resolve(zone,d)
 for _,kind in ipairs(CARDS) do if R.frames[kind] and R.frames[kind].azsMoving then return end end -- never rearrange under a drag
 for _,e in ipairs(R.PartyFrames()) do if e[2].azsMoving then return end end
 R.shift={};R.shiftX={};R.noRoom=false;R.overflow=0
 if FieldKitDB.zoneThemeOverlap then return end
 -- Automatic placement keeps a visual margin from the REAL screen edges; manual placement has none (see "pinned" below).
 local sl,st,sr,sb=R.ScreenBounds(d)
 local bottomLimit,topLimit,leftLimit,rightLimit=sb-8,st+8,sl+4,sr-4
 local function Opaque(name,x,y,w,h) local n=Inset(name);return {x+n[1],y+n[2],x+w-n[3],y+h-n[4]} end
 local fixed=FixedObstacles(d)
 local items={}
 for index,kind in ipairs(CARDS) do
  if R.CardVisible(kind,d) then
   local f=R.frames[kind];local x,y,w,h
   if FieldKitZoneThemes.Position(f) then
    -- A card the user placed: its PREFERRED rectangle is where it really is minus the displacement we applied.
    local lx,ly=R.LiveRect(f)
    if lx then local rect=R.CardRect(kind,d,true);local s=FieldKitZoneThemes.ElementScale("FieldKitReferencePanel"..kind) or 1
     x,y,w,h=lx-(f.fieldkitDX or 0),ly-(f.fieldkitDY or 0),rect[3]*s,rect[4]*s end
   else x,y,w,h=R.Preferred(kind,d) end
   if x then
    local grower=(kind=="Accessories" and (R.accN or 5)>5) or (kind=="Damage" and (R.dmgN or 6)>6)
    local item={kind=kind,x=x,y=y,w=w,h=h,index=index,inset=Inset(kind),pinned=FieldKitZoneThemes.Position(f) and true or false,grower=grower}
    -- a grown card that would leave the screen is not held at its saved top: it is displayed higher (never saved)
    if grower and y+h-item.inset[4]>bottomLimit then item.pinned=false end
    table.insert(items,item)
   end
  end
 end
  for _,e in ipairs(R.PartyFrames()) do
  local pi,pf=e[1],e[2]
  if pf:IsShown() and not pf.azsMoving then
   local pdx,pdy=R.PartyPrepare(pf);local lx,ly,w,h=R.LiveRect(pf)
   if lx then table.insert(items,{kind="Party"..pi,x=lx-pdx,y=ly-pdy,w=w,h=h,index=100+pi,inset={0,0,0,0},pinned=true,party=true}) end
  end
 end
-- Priority: protected parts (fixed), then the visible teammate cards (the one moved last first), then the main cards.
 -- A teammate card keeps its preferred place; a main card that meets it looks for a free place (display only, never saved).
 local function Rank(c) if c.party then return c.kind==R.lastParty and -2 or -1 end if c.kind=="Stats" and R.statsOpen then return 0 elseif c.kind==R.lastMoved then return 1 end return 2 end
 table.sort(items,function(p,q)
  local rp,rq=Rank(p),Rank(q);if rp~=rq then return rp<rq end
  if p.y~=q.y then return p.y<q.y end if p.x~=q.x then return p.x<q.x end return p.index<q.index end)
 local placed={};local deepest=0
 -- Tier 1 also refuses spots that sit on the PREFERRED place of a card not yet handled (no cascade of displacements);
 -- tier 2 (only if tier 1 finds nothing) accepts them.
 local soft={};for _,c in ipairs(items) do c.done=false;if not c.party then table.insert(soft,{c.x+c.inset[1],c.y+c.inset[2],c.x+c.w-c.inset[3],c.y+c.h-c.inset[4],owner=c}) end end
 local function Free(c,x,y,strict)
  local l,t,r,b=x+c.inset[1],y+c.inset[2],x+c.w-c.inset[3],y+c.h-c.inset[4]
  local function Hit(o) local across=math.min(r,o[3])-math.max(l,o[1]);local depth=math.min(b,o[4])-math.max(t,o[2]);return across>0 and depth>TOLERANCE end
  for _,list in ipairs({fixed,placed}) do for _,o in ipairs(list) do if Hit(o) then return false end end end
  if strict then for _,o in ipairs(soft) do if o.owner~=c and not o.owner.done and Hit(o) then return false end end end
  return true
 end
 local function SearchY(c,x,strict)
  local ys={c.y}
  if c.grower then table.insert(ys,bottomLimit-c.h+c.inset[4]) end -- flush with the bottom limit
  for _,list in ipairs({fixed,placed,soft}) do for _,o in ipairs(list) do
   if math.min(x+c.w-c.inset[3],o[3])-math.max(x+c.inset[1],o[1])>0 then table.insert(ys,o[4]+GAP-c.inset[2]);table.insert(ys,o[2]-GAP-c.h+c.inset[4]) end
  end end
  table.sort(ys)
  for _,y in ipairs(ys) do if y>=c.y and y+c.h-c.inset[4]<=bottomLimit and Free(c,x,y,strict) then return y end end
  for n=table.getn(ys),1,-1 do local y=ys[n];if y<c.y and y+c.inset[2]>=topLimit and Free(c,x,y,strict) then return y end end
  return nil
 end
 local function Search(c,strict)
  local by=SearchY(c,c.x,strict);if by then return c.x,by end
  local xs={}
  for _,list in ipairs({fixed,placed,soft}) do for _,o in ipairs(list) do
   table.insert(xs,o[1]-GAP-(c.w-c.inset[3]));table.insert(xs,o[3]+GAP-c.inset[1])
  end end
  table.sort(xs,function(p,q) local dp,dq=math.abs(p-c.x),math.abs(q-c.x);if dp~=dq then return dp<dq end return p<q end)
  for _,x in ipairs(xs) do
   if x+c.inset[1]>=leftLimit and x+c.w-c.inset[3]<=rightLimit then local y=SearchY(c,x,strict);if y then return x,y end end
  end
  return nil
 end
 for _,c in ipairs(items) do
  -- A card the user put somewhere stays there whenever nothing is in its way, even against the very edge of the screen.
  local bx,by
  -- (a card handled earlier keeps its place whenever nothing PLACED or fixed is in its way; later cards are the ones that yield)
  if Free(c,c.x,c.y) and (c.pinned or (c.y+c.h-c.inset[4]<=bottomLimit and c.y+c.inset[2]>=topLimit)) then bx,by=c.x,c.y
  else bx,by=Search(c,true);if not bx then bx,by=Search(c,false) end end
  if not bx then bx,by=c.x,c.y;R.noRoom=true end
  local dx,dy=math.floor(bx-c.x+.5),math.floor(by-c.y+.5)
  R.shift[c.kind]=dy;R.shiftX[c.kind]=dx;c.done=true
  table.insert(placed,{c.x+dx+c.inset[1],c.y+dy+c.inset[2],c.x+dx+c.w-c.inset[3],c.y+dy+c.h-c.inset[4]});deepest=math.max(deepest,c.y+dy+c.h-c.inset[4])
 end
 R.overflow=math.max(0,deepest-bottomLimit);if R.noRoom then R.overflow=math.max(R.overflow,1) end
 if R.dragReport then local k=R.dragReport;R.dragReport=nil
  DEFAULT_CHAT_FRAME:AddMessage(string.format("dragdiag after resolve %s: shift dy=%s dx=%s noRoom=%s",k,tostring(R.shift[k]),tostring(R.shiftX[k]),tostring(R.noRoom))) end
end
-- A card the user placed keeps its saved anchor; the automatic displacement is applied on top of it (and only at display time).
function R.ApplyShift(f,kind)
 local a=FieldKitZoneThemes.Position(f);if not a or f.azsMoving then return end
 local dx,dy=(R.shiftX and R.shiftX[kind]) or 0,(R.shift and R.shift[kind]) or 0
 local cs=R.canvas.GetEffectiveScale and R.canvas:GetEffectiveScale() or 1;local fe=f.GetEffectiveScale and f:GetEffectiveScale() or 1
 local k=(fe and fe>0 and cs) and cs/fe or 1
 local ex,ey=a[3]+dx*k,a[4]-dy*k
 local _,_,_,x,y=f:GetPoint()
 if not x or math.abs(x-ex)>.01 or math.abs(y-ey)>.01 then f:ClearAllPoints();f:SetPoint(a[1],UIParent,a[2],ex,ey) end
 f.fieldkitDX,f.fieldkitDY=dx,dy
end
-- One layout pass: sizes first, then placement. A Bonuses card that cannot fit loses rows (scrolls) instead of overlapping.
function R.PlanLayout(zone,d)
 R.StatsPlan(zone,d);R.AccPlan(zone,d);R.DmgPlan(zone,d);R.shift=R.shift or {};R.shiftX=R.shiftX or {}
 if R.statsOpen and R.statsExtra>0 then R.statsExtra=math.min(R.statsExtra,math.floor(R.StatsRoom(d)));R.statsCap=R.StatsCapFor(zone,d.rects.Stats,R.statsExtra) end
 for pass=1,24 do
  R.Resolve(zone,d)
  if R.overflow<=0 then break end
  if R.statsOpen and R.statsExtra>0 then
   R.statsExtra=math.max(0,R.statsExtra-math.max(R.overflow,24,R.noRoom and math.floor(R.statsExtra/4) or 0));R.statsCap=R.StatsCapFor(zone,d.rects.Stats,R.statsExtra)
  elseif (R.accN or 5)>R.AccMin(zone) and FieldKitDB.loadoutTab==2 and (R.accN or 5)>5 then
   -- the grown Equipment / Spells card pushes the cards under it off the screen: take back rows (the list then scrolls)
   local step=zone=="naxx" and 35 or 36
   R.accN=math.max(R.AccMin(zone),R.accN-math.max(1,math.ceil(R.overflow/step)));R.accScroll=table.getn(FieldKitLoadout.spells or {})>R.accN;R.AccShape(zone,R.accN)
  elseif (R.dmgN or 6)>6 then
   local step=DMG[R.DmgZone()].step
   R.dmgN=math.max(6,R.dmgN-math.max(1,math.ceil(R.overflow/step)));R.dmgScroll=table.getn(R.dmgRead and R.dmgRead.lines or {})>R.dmgN
  else break end
 end
end
-- Fixed icon column: a real icon, or a neutral socket of the same size (never a guessed icon, never a shifted text).
function R.RowIcon(r,texture)
 r.icon:ClearAllPoints();r.icon:SetPoint("TOPLEFT",r,"TOPLEFT",-45,-1);r.icon:SetWidth(26);r.icon:SetHeight(26)
 if texture then r.icon:SetTexCoord(.07,.93,.07,.93);r.icon:SetVertexColor(1,1,1,1);r.icon:SetTexture(texture)
 else r.icon:SetTexCoord(0,1,0,1);r.icon:SetTexture("Interface\Buttons\WHITE8X8");r.icon:SetVertexColor(.16,.14,.1,.85) end
 r.icon:Show()
end
function R.Stable(frame,key,apply) if frame.fieldkitStable~=key then frame.fieldkitStable=key;apply(frame) end end
function R.HideUnwanted() for _,f in pairs(R.frames) do if not f.fieldkitWanted and not f.azsMoving then f:Hide() end end end
-- Taller cards without new artwork: the art is cut at `split` (inside the uniform body) and a thin mid band is
-- stretched, so borders stay crisp. top = vertical shift, extra = added height (reference px).
function R.CardRect(kind,d,noShift)
 local base=d.rects[kind];local grow=base and GROW[R.key] and GROW[R.key][kind]
 if base and kind=="Damage" and (R.dmgN or 6)>6 and (R.key=="elwynn_complete" or R.key=="naxx_complete") then
  local k=DMG[R.DmgZone()];grow={top=0,extra=((grow and grow.extra) or 0)+R.DmgDelta(R.dmgN),split=k.split}
 end
 if base and kind=="Stats" and (R.statsExtra or 0)>0 then grow={top=0,extra=R.statsExtra,split=100}
 elseif base and kind=="Accessories" and R.accShape then
  local sh=R.accShape;grow={top=0,extra=sh.delta,split=0,rep=sh.rep}
 end
 if not base then return nil,0,0 end
 local pinned=R.frames[kind] and FieldKitZoneThemes.Position(R.frames[kind])
 local top=(grow and grow.top or 0)+((not noShift and not pinned and R.shift and R.shift[kind]) or 0)
 local left=(not noShift and not pinned and R.shiftX and R.shiftX[kind]) or 0
 if not grow and top==0 and left==0 then return base,0,0 end
 grow=grow or {top=0,extra=0,split=0}
 R.rectCache=R.rectCache or {};local key=R.key..":"..kind..":"..top..":"..left..":"..grow.extra..":"..(grow.rep and grow.rep.count or 0);local c=R.rectCache[key]
 if not c or c.base~=base then c={base=base,rect={base[1]+left,base[2]+top,base[3],base[4]+grow.extra}};R.rectCache[key]=c end
 return c.rect,(grow.rep and 0 or grow.extra),grow.split,grow.rep
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
function R.CardTabs(f,a,active,keys,pick,suffix)
 f.cardTabs=f.cardTabs or {}
 -- Tabs live in the card header (where the title was): from x=62 to the collapse button, full header height.
 local left,top,height=62,9,36
 local width=(a[3]-left-34)/table.getn(keys)
 for i,key in ipairs(keys) do
  local b=f.cardTabs[i]
  if not b then
   local index=i;b=T.Button(f,nil,key,0,0,100,26,function() pick(index) end);f.cardTabs[i]=b;R.DiagHook(b,"card tab "..key)
   b.rule=b:CreateTexture(nil,"ARTWORK");b.rule:SetHeight(1);b.rule:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);b.rule:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,0)
   b.underline=b:CreateTexture(nil,"OVERLAY");b.underline:SetHeight(2);b.underline:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);b.underline:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,0)
  end
  T.Solid(b.rule,{1,.82,.12},.3);b.rule:Show()
  local stamp=table.concat({a[3],active==i and 1 or 0,tostring(FieldKitDB.language),tostring(f:GetFrameLevel()),tostring(suffix and suffix[i])},":")
  if b.layoutKey~=stamp then
   b.layoutKey=stamp
   FieldKit_Text(b,key);if suffix and suffix[i] then b.fieldkitLabel:SetText(FieldKit_L(key).."  "..suffix[i]) end
   b:SetFrameLevel(f:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",left+(i-1)*width,-top);b:SetWidth(width);b:SetHeight(height)
   b.fieldkitLabel:SetWidth(width-10);b.fieldkitLabel:SetJustifyH("CENTER");T.Font(b.fieldkitLabel,18,active==i and {1,.82,.12} or R.body,true);R.Fit(b.fieldkitLabel,18,11);b.fieldkitSelected=active==i;Blank(b)
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
 -- A card under the mouse must not be hidden by the 0.2 s refresh: OnHide ends the drag (C.Bind -> C.Finish).
 for _,f in pairs(H.summaries or {}) do if not f.azsMoving then f:Hide() end end
 local detail=false;for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do if FieldKitZoneThemes.open[kind] then detail=true end end
 for _,f in pairs(R.frames) do f.fieldkitWanted=nil end
 if variant~="complete" then R.PartyRestoreAll();R.HideUnwanted();R.MaskBuffs(false);return end
 R.effectBuffs=false
 local d=R.layout;R.PlanLayout(zone,d);R.PartyPass()
 if not FieldKitNative.Active() and (not R.readyAt or GetTime()>R.readyAt or R.readySerial~=FieldKitNative.serial) then
  R.readyItems={};R.readyAt=GetTime()+5;R.readySerial=FieldKitNative.serial
  if FieldKitLoadout.readSlot then for _,id in ipairs({2,13,14,11,12}) do local ok,name=pcall(FieldKitLoadout.readSlot,id);if ok then R.readyItems[id]={name=name,bonuses={}} end end end
 end
 local prefs={Damage="meterFrame",Lairs="lairFrame",Accessories="gearFrame",Stats="statsFrame",Effects="effectsFrame"}
 for _,kind in ipairs({"Damage","Lairs","Accessories","Stats","Effects"}) do
  local f=R.frames[kind];local a,extra,split,rep=R.CardRect(kind,d);f.referenceExtra=extra;f.referenceSplit=split;f.referenceRepeat=rep
  local nativeName=({Damage="FieldKitMeterFrame",Lairs="FieldKitLairFrame",Accessories="FieldKitGearFrame",Stats="FieldKitStatsFrame",Effects="FieldKitEffectsFrame"})[kind];local folded=(kind=="Stats" and FieldKitDB.statsCollapsed) or (kind=="Accessories" and FieldKitDB.gearCollapsed) or (FieldKitDB.collapsedWindows and FieldKitDB.collapsedWindows[nativeName])
  if a and R.CardVisible(kind,d) then
   R.Geometry(f,a);R.ApplyShift(f,kind);R.ApplyClamp(f,kind);R.Art(f,kind);f:Show();f.fieldkitWanted=true
   R.Stable(f.collapse,"c"..f:GetFrameLevel(),function(b) b:ClearAllPoints();b:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-8);b:SetFrameLevel(f:GetFrameLevel()+25) end);f.collapse:Show()
   if f.bodyWash then f.bodyWash:Hide() end

   f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",65,-14);f.title:SetWidth(a[3]-78);f.title:SetHeight(30);T.Font(f.title,21,R.color,true)
   local titles={Damage="DAMAGE",Lairs="LAIRS",Accessories="EQUIPMENT",Stats="BONUSES",Effects="EFFECTS"};FieldKit_Text(f.title,titles[kind])
   if f.footerPatch then f.footerPatch:Hide() end
   if kind~="Accessories" then
    if not f.cleanBody then f.cleanBody=f:CreateTexture(nil,"BORDER") end
    local t=f.cleanBody;t:SetTexture(T.media.."ReferenceHUD\\"..zone.."_card_body_v9.tga");t:SetTexCoord(0,1,0,1);t:ClearAllPoints();t:SetPoint("TOPLEFT",f,"TOPLEFT",17,-44);t:SetWidth(a[3]-34);t:SetHeight(a[4]-60);t:Show()
   end
   f.more:Show();R.Stable(f.more,table.concat({a[3],a[4],zone,f:GetFrameLevel()},":"),function(b) b:SetFrameLevel(f:GetFrameLevel()+15);b:ClearAllPoints();b:SetPoint("BOTTOM",f,"BOTTOM",-5,zone=="elwynn" and 20 or 8);b:SetWidth(a[3]-42);b:SetHeight(28) end);f.more.fieldkitLabel:SetWidth(a[3]-42);f.more.fieldkitLabel:SetJustifyH("CENTER");T.Font(f.more.fieldkitLabel,17,{1,.82,.12},true)
   if f.emptySocket then f.emptySocket:Hide() end;f.total:Hide();f.rateLabel:Hide();f.pager:Hide();for _,r in ipairs(f.rows) do r.fieldkitUsed=nil;r.icon:Hide();r.bar:Hide();if r.trough then r.trough:Hide() end end
   if kind=="Damage" then
    if f.liveBody then f.liveBody:Hide();f.liveGrain:Hide() end
    FieldKit_Text(f.more,"All spells");f.more.fieldkitLabel:SetText(FieldKit_L("All spells").." →");local view,index=FieldKitMeterSuite.View();local lines,total,rate,known
    if R.dmgRead and R.dmgRead.view==view then lines,total,rate,known=R.dmgRead.lines,R.dmgRead.total,R.dmgRead.rate,R.dmgRead.known else lines,total,rate,known=FieldKitMeterLedger.Read(view) end
    FieldKit_Text(f.title,({"DAMAGE","HEALING","BOSS DAMAGE","DAMAGE TAKEN","PARTY DPS","KILLS"})[index] or "DAMAGE")
    f.total:ClearAllPoints();f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-30,-11);f.total:SetWidth(a[3]-200);f.total:SetHeight(25);f.total:SetJustifyH("RIGHT");if index==6 then FieldKit_Text(f.title,"Kills short") end;f.total:SetText(R.Amount(total));f.total:Show();f.title:SetWidth(125)
    local unit=index==2 and " HPS" or (index==6 and " /s" or " DPS");local rateText=rate and (R.Amount(rate)..unit) or nil
    if zone=="naxx" then
     f.total:ClearAllPoints();f.total:SetPoint("TOPLEFT",f,"TOPLEFT",29,-53);f.total:SetWidth(155);f.total:SetHeight(34);f.total:SetJustifyH("LEFT");f.total:SetText(R.Amount(total));T.Font(f.total,30,R.body,true)
     f.rateLabel:ClearAllPoints();f.rateLabel:SetPoint("TOPRIGHT",f,"TOPRIGHT",-23,-58);f.rateLabel:SetWidth(110);f.rateLabel:SetHeight(27);f.rateLabel:SetJustifyH("RIGHT");f.rateLabel:SetText(R.Amount(rate)..(index==2 and " HPS" or (index==6 and " /s" or " DPS")));T.Font(f.rateLabel,17,R.body);f.rateLabel:Show();R.Fit(f.rateLabel,17,12)
     f.title:SetWidth(a[3]-100);f.more:Hide()
     if not (type(total)=="number" and total>0) then f.total:Hide();f.rateLabel:Hide() end
    else
     -- Elwynn header: amount (gold) on the first line, rate (muted) under it, both right-aligned inside the banner
     -- First line: title (left, art icon at its left) and, on the SAME line at the right, the amount (gold) then the rate (muted).
     -- With no data nothing is written there (no lone "0" over "0 DPS"): the list below says "No combat data".
     local hasData=type(total)=="number" and total>0
     local rateW=rateText and 92 or 0
     f.total:ClearAllPoints();f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-(30+rateW),-12);f.total:SetWidth(90);f.total:SetHeight(24);f.total:SetJustifyH("RIGHT");T.Font(f.total,20,R.color,true)
     f.rateLabel:ClearAllPoints();f.rateLabel:SetPoint("TOPRIGHT",f,"TOPRIGHT",-30,-16);f.rateLabel:SetWidth(88);f.rateLabel:SetHeight(18);f.rateLabel:SetJustifyH("RIGHT");T.Font(f.rateLabel,12,T.muted)
     f.rateLabel:SetText(rateText or "")
     if hasData then f.total:Show();if rateText then f.rateLabel:Show() else f.rateLabel:Hide() end else f.total:Hide();f.rateLabel:Hide() end
    end
    R.DamageTabs(f,a,zone,index)
    -- Content area ends above the foot button: 3 rows on Elwynn (4 on Naxx, which has no foot); longer lists scroll.
    local capacity=R.dmgN or 6;local offset=R.Window(f,"Damage",table.getn(lines),capacity)
    if zone=="elwynn" then
     -- The foot button carries the scroll position, so the rows keep the whole content area.
     f.pager:Hide();local count=table.getn(lines)
     if count>capacity then f.more.fieldkitLabel:SetText(FieldKit_L("All spells").." →   "..(offset+1).."-"..math.min(count,offset+capacity).." / "..count) end
    end
    local pctW,amountW=nil,nil;local shownRows={}
    for i=1,capacity do local e=lines[offset+i];local r=Row(f,i,82,(zone=="naxx" and 144 or R.listTop)+(i-1)*(zone=="naxx" and 30 or 29),a[3]-100,28,not e and i>1);if not e and i>1 then r:Hide() end;table.insert(shownRows,r)
     r.label:SetHeight(19)
     r.label:SetText(e and (e.displayName or e.name) or (i==1 and FieldKit_L("No combat data") or ""))
     -- Two distinct pieces on one right-aligned line: the share (bright, readable) and the real amount (muted) after a thin
     -- separator. Both come from the existing ledger line (share, dmg), nothing recomputed; a missing one is simply absent.
     local pct=e and e.share and string.format("%.0f %%",e.share*100) or nil;local amount=e and type(e.dmg)=="number" and R.Amount(e.dmg) or nil
     R.AmountParts(r);r.value:SetText(pct or "");r.amount:SetText(amount or "")
     if e then r.fontSize=16;r.fontMin=12 end
     local function Wide(fs) return (fs.GetStringWidth and fs:GetStringWidth() or 60)+10 end -- R.Fit keeps an 8 px margin
     if pct then pctW=math.max(pctW or 0,Wide(r.value)) end
     if amount then amountW=math.max(amountW or 0,Wide(r.amount)) end
     if e then r.fieldkitLine=e;r.fieldkitSpell=e.name end
     if e or i==1 then r:SetHitRectInsets(-48,0,0,0) end
     if not e then r.icon:Hide() end
     if e then
      if not r.trough then r.trough=r:CreateTexture(nil,"BACKGROUND") end
      r.trough:ClearAllPoints();r.trough:SetPoint("TOPLEFT",r,"TOPLEFT",0,-20);r.trough:SetWidth(a[3]-160);r.trough:SetHeight(8);T.Solid(r.trough,{.12,.14,.08});r.trough:Show()
      R.RowIcon(r,e.icon or FieldKitLoadout.Icon(e.name));r.bar:ClearAllPoints();r.bar:SetPoint("TOPLEFT",r,"TOPLEFT",0,-20);r.bar:SetWidth(a[3]-160);r.bar:SetMinMaxValues(0,1);r.bar:SetValue(0);r.bar:SetValue(math.max(0,math.min(1,e.share or 0)));r.bar:SetStatusBarColor(zone=="elwynn" and .65 or .1,zone=="elwynn" and .55 or .75,zone=="elwynn" and .18 or .85);r.bar:Show() end
    end
    -- one pair of columns for every row (right-aligned): [name ........ share | amount]; the name takes the rest of the row
    local rowW=a[3]-100;local colA=math.min(rowW*.3,amountW or 0);local colP=math.min(rowW*.25,pctW or 0)
    local gap=(colA>0 and colP>0) and 10 or 0
    for _,r in ipairs(shownRows) do if r.fieldkitLine then
     r.amount:ClearAllPoints();r.amount:SetPoint("TOPRIGHT",r,"TOPRIGHT",0,0);r.amount:SetWidth(math.max(1,colA));r.amount:SetHeight(r:GetHeight());r.amount:SetJustifyH("RIGHT")
     r.value:ClearAllPoints();r.value:SetPoint("TOPRIGHT",r,"TOPRIGHT",-(colA+gap),0);r.value:SetWidth(math.max(1,colP));r.value:SetHeight(r:GetHeight());r.value:SetJustifyH("RIGHT")
     r.amountSep:ClearAllPoints();r.amountSep:SetPoint("TOPRIGHT",r,"TOPRIGHT",-(colA+gap/2),-6);r.amountSep:SetHeight(12);r.amountSep:SetWidth(1)
     if colA>0 and colP>0 and r.value:GetText()~="" and r.amount:GetText()~="" then r.amountSep:Show() else r.amountSep:Hide() end
     r.label:SetWidth(rowW-colA-colP-gap-10)
     if R.Fit then R.Fit(r.value,16,12);R.Fit(r.amount,14,11) end
    end end
    if not lines[1] then
     -- Empty state: centred in the content area between the tab rows and the card foot, not in the whole frame.
     local top=zone=="naxx" and 144 or R.listTop;local bottom=zone=="naxx" and a[4]-30 or a[4]-52
     local r=Row(f,1,24,top,a[3]-48,bottom-top);r.label:SetWidth(a[3]-48);r.label:SetHeight(bottom-top);r.label:SetJustifyH("CENTER");r.label:SetJustifyV("MIDDLE")
     r.label:SetText(FieldKit_L("No combat data"));r.value:SetText("");r.value:SetWidth(0)
    end
   elseif kind=="Lairs" then
    FieldKit_Text(f.more,"View list");f.more.fieldkitLabel:SetText(FieldKit_L("View list").." →");local lairs=FieldKitNative.Read("AZS_GetLairs");local active=0;for _,e in ipairs(type(lairs)=="table" and lairs or {}) do if e.state=="awake" then active=active+1 end end
    local list=R.LairList(lairs);local total=table.getn(list);local capacity=4
    f.title:SetWidth(a[3]-175)
    if total>0 then
     -- Every guardian is listed (four rows in both zones); more than four scroll with the wheel, never hidden behind "+N".
     f.more:Hide();local offset=R.Window(f,"Lairs",total,capacity);local lairRows=nil
     for i=1,math.min(capacity,total-offset) do
      local e=list[offset+i]
      local r=zone=="naxx" and Row(f,i,60,57+(i-1)*31,a[3]-110,28) or Row(f,i,48,47+(i-1)*21,a[3]-96,20)
      -- Value column = measured width of state/delay/distance; the name gets everything that is left.
      local rowW=zone=="naxx" and a[3]-110 or a[3]-96
      -- Columns, by priority: 1) state and delay, 2) the complete distance, 3) the name (fitted only if it must be).
      -- Fonts are applied BEFORE measuring, so the widths are those of the text as it is drawn; the margin is the one R.Fit keeps.
      local size=zone=="naxx" and 16 or 14
      R.AmountParts(r);r.fontSize=size;r.fontMin=11;r.labelTint=e.tint;r.valueTint=e.tint
      T.Font(r.label,size,e.tint,false);T.Font(r.value,size,e.tint,false);T.Font(r.amount,size,e.tint,false)
      r.label:SetJustifyH("LEFT");r.value:SetJustifyH("RIGHT");r.amount:SetJustifyH("RIGHT")
      r.label:SetText(e.name);r.value:SetText(e.state);r.amount:SetText(e.dist or "")
      r.fieldkitLairRowW=rowW;lairRows=lairRows or {};table.insert(lairRows,r)
     end
     if lairRows then
      local function Wide(fs) return (fs.GetStringWidth and fs:GetStringWidth() or 0)+10 end
      local rowW=lairRows[1].fieldkitLairRowW;local gap=8
      local stateW,distW
      -- State/delay and the complete distance come first; the name takes what is left. If the name would get less than 70 px the
      -- three columns are drawn a point smaller (down to 11) before the name is shortened.
      for size=(zone=="naxx" and 16 or 14),11,-1 do
       stateW,distW=0,0
       for _,r in ipairs(lairRows) do
        r.fontSize=size;T.Font(r.label,size,r.labelTint,false);T.Font(r.value,size,r.valueTint,false);T.Font(r.amount,size,r.valueTint,false)
        stateW=math.max(stateW,Wide(r.value));if r.amount:GetText()~="" then distW=math.max(distW,Wide(r.amount)) end
       end
       if rowW-stateW-(distW>0 and distW+gap or 0)-gap>=70 then break end
      end
      for _,r in ipairs(lairRows) do
       r.amount:ClearAllPoints();r.amount:SetPoint("TOPRIGHT",r,"TOPRIGHT",0,0);r.amount:SetWidth(math.max(1,distW));r.amount:SetHeight(r:GetHeight())
       r.value:ClearAllPoints();r.value:SetPoint("TOPRIGHT",r,"TOPRIGHT",-(distW>0 and distW+gap or 0),0);r.value:SetWidth(stateW);r.value:SetHeight(r:GetHeight())
       r.label:SetWidth(math.max(1,rowW-stateW-(distW>0 and distW+gap or 0)-gap))
       r.amountSep:Hide()
      end
     end
    elseif zone=="naxx" then
     f.more:Hide()
     for i=1,4 do local r=Row(f,i,60,57+(i-1)*31,a[3]-110,28);r.label:SetWidth(a[3]-171);r.label:SetJustifyH("LEFT");r.label:SetText(i==1 and FieldKit_L("No active lair") or "");r.value:SetWidth(53);r.value:SetText("") end
    else local r=Row(f,1,48,52,a[3]-96,28);r.label:SetWidth(a[3]-96);r.label:SetJustifyH("CENTER");r.label:SetText(type(lairs)~="table" and "?" or FieldKit_L("No active lair"));r.value:SetText("");r.value:SetWidth(0) end
   elseif kind=="Accessories" then
    FieldKit_Text(f.more,"Equipment / spells");f.more:Hide();f.title:Hide()
    local tab=FieldKitDB.loadoutTab==2 and 2 or 1
    -- The scroll position lives in the Spells tab label (header): the card body keeps every socket row free.
    local spells=FieldKitLoadout.spells or {};local total=table.getn(spells);local offset,range=0,nil
    if tab==2 then offset=R.Window(f,"Accessories",total,R.accN or 5);if f.pager:IsShown() then range=string.gsub(f.pager:GetText()," / ","/") end;f.pager:Hide() end
    R.CardTabs(f,a,tab,{"Equipment","Spells"},function(i) FieldKitDB.loadoutTab=i;R.scroll=R.scroll or {};R.scroll.Accessories=0;FieldKitZoneThemes.Refresh(true) end,{[2]=range})
    if tab==1 then
     local ids={2,13,14,11,12};local names={"Amulet","Trinket 1","Trinket 2","Ring 1","Ring 2"}
     for i=1,5 do local r=Row(f,i,72,R.SocketY(zone,i),a[3]-94,R.SocketH(zone));local e=FieldKitLoadout.items[ids[i]] or (R.readyItems and R.readyItems[ids[i]]);r.entry=e;local occupied=e and e.name and e.name~="" and e.name~=FieldKit_L("Empty");if occupied then r.label:SetText(e.name);r.value:SetText("");r.label:SetWidth(a[3]-98);r.value:SetWidth(0) else FieldKit_Text(r.label,names[i]);r.value:SetText(e and FieldKit_L("Empty") or "?");r.label:SetWidth(126);r.value:SetWidth(a[3]-228) end
      local texture=type(GetInventoryItemTexture)=="function" and GetInventoryItemTexture("player",ids[i]);if texture then R.SocketIcon(r,zone,texture) end
      r.fontSize=16;r.fontMin=16
     end
    else
     if total==0 then local r=Row(f,1,72,R.SocketY(zone,1,R.accN),a[3]-94,R.SocketH(zone));r.label:SetWidth(a[3]-98);r.label:SetText(FieldKit_L("No spells yet"));r.value:SetText("");r.value:SetWidth(0);r.fontSize=16;r.fontMin=12 end
     for i=1,math.min(R.accN or 5,total-offset) do
      local e=spells[offset+i];local r=Row(f,i,72,R.SocketY(zone,i,R.accN),a[3]-94,R.SocketH(zone));r.entry=e
      r.label:SetText(e.name or "?");r.value:SetText(e.rank or "");r.value:SetWidth(78);r.label:SetWidth(a[3]-98-82)
      local icon=FieldKitLoadout.Icon(e.name);if icon then R.SocketIcon(r,zone,icon) end
      r.fontSize=16;r.fontMin=12;local cr,cg,cb=FieldKitLoadout.RankColor(e.rankValue);r.valueTint={cr,cg,cb}
     end
    end
   elseif kind=="Stats" then
    FieldKit_Text(f.more,"All statistics");f.more.fieldkitLabel:SetText(FieldKit_L("All statistics").." →");local source=getglobal("FieldKitStatsFrame");local labels={"Damage","Haste","Crit Chance","Lifesteal"}
    if zone=="naxx" and not R.statsOpen then f.more:Hide() end
    local sx,sw,step=zone=="naxx" and 72 or 31,a[3]-(zone=="naxx" and 100 or 65),zone=="naxx" and 27 or 29
    if R.statsOpen then
     -- Expanded in place: every row the statistics frame really holds, read live from it (no second calculation).
     local shown={};for _,s in ipairs(source and source.rows or {}) do if s.label:IsShown() then table.insert(shown,s) end end
     local total=table.getn(shown);local capacity=math.min(total,R.statsCap or total);local offset=R.Window(f,"Stats",total,capacity)
     f.more.fieldkitLabel:SetText("← "..FieldKit_L("Show less")..(total>capacity and ("   "..(offset+1).."-"..math.min(total,offset+capacity).."/"..total) or ""));f.more:Show();f.pager:Hide()
     for i=1,capacity do local s=shown[offset+i];local r=Row(f,i,sx,49+(i-1)*step,sw,27);r.label:SetText(s.label:GetText() or "?");r.value:SetText(s.value:GetText() or "?") end
    else
    for i,name in ipairs(labels) do local r=Row(f,i,sx,49+(i-1)*step,sw,27);FieldKit_Text(r.label,name=="Crit Chance" and "Critique" or name);local value="?"
     for _,s in ipairs(source and source.rows or {}) do if s.label:GetText()==FieldKit_L(name) then value=s.value:GetText() or "?" end end;r.value:SetText(value)
    end
    end
   else
    FieldKit_Text(f.more,"All effects");f.more:Hide();f.title:SetWidth(a[3]-175)
    local source=FieldKitNativeTools and FieldKitNativeTools.frames[1];local list=source and source.lastRows or {}
    local total=table.getn(list);local capacity=2
    if total==0 then list={{label=FieldKit_L("No active effect"),value=""}};total=1 end
    local offset=R.Window(f,"Effects",total,capacity)
    for i=1,math.min(capacity,total-offset) do
     local box=R.EffectBox(zone,a[4]);local ex=R.EFFECT
     local e=list[offset+i];local r=Row(f,i,ex.x,box.top+(i-1)*box.step,a[3]-ex.x-ex.rightPad,box.rowH)
     r.label:SetText(e.label or "");r.value:SetText(e.value or "");r.buffIndex=e.buffIndex
     if e.buffIndex then R.effectBuffs=true end
     local available=a[3]-ex.x-ex.rightPad;local vw=r.value:GetText()~="" and math.min(110,math.max(60,(r.value.GetStringWidth and r.value:GetStringWidth() or 100)+4)) or 0;r.value:SetWidth(vw);r.label:SetWidth(available-vw-8)
     if e.icon and e.icon~="" then R.EffectIcon(r,e.icon) end
     r.fontSize=16;r.fontMin=11
    end
   end
   for _,r in ipairs(f.rows) do if not r.fieldkitUsed then r:Hide() end end
   if kind~="Accessories" and f.cardTabs then for _,b in ipairs(f.cardTabs) do b:Hide() end end
   R.Fit(f.title,21,12);if f.total:IsShown() then R.Fit(f.total,zone=="naxx" and 30 or 16,12) end
   for _,r in ipairs(f.rows) do if r:IsShown() then
    local size=r.fontSize or 16;local least=r.fontMin or (kind=="Accessories" and 16 or 12)
    T.Font(r.label,size,r.labelTint or R.body,false);T.Font(r.value,size,r.valueTint or r.labelTint or R.body,false);R.Fit(r.label,size,least);R.Fit(r.value,size,least)
    r.fullLines={r.label.referenceFullText or "",r.value.referenceFullText or ""}
    if kind=="Lairs" and r.amount and r.amount:GetText()~="" then T.Font(r.amount,size,r.valueTint or R.body,false);R.Fit(r.amount,size,least);table.insert(r.fullLines,r.amount.referenceFullText or "") end
    r:SetScript("OnEnter",function() if this.entry and FieldKitLoadout then FieldKitLoadout.Tip(this,this.entry) elseif this.fieldkitLine and R.DamageTip(this) then -- complete tooltip, nothing to click
  elseif this.buffIndex and GameTooltip.SetPlayerBuff then GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetPlayerBuff(this.buffIndex);GameTooltip:Show() else H.Tip(this,f.title:GetText(),this.fullLines) end end);r:SetScript("OnLeave",function() GameTooltip:Hide();H.HideTip() end)
   end end
  end
 end
 R.HideUnwanted();R.MaskBuffs(R.effectBuffs and R.frames.Effects:IsShown())
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
