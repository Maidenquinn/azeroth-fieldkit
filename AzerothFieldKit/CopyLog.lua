-- Optional local chat copy. No capture until opt-in; never persisted or uploaded.
-- Whispers can be included. Copying to the OS clipboard remains a player action.
local history,hooked={},{}
local displayHistory={}
-- Keep a bounded in-memory render journal across temporary style toggles.
-- This is distinct from the opt-in copy buffer and never saved to disk.
local styleWasEnabled=false
local replaying=false
local DISPLAY_LIMIT=500
local copyFrame,copyEdit
local active=false
local button, chatFrame, styleBefore, chatBackdrop, moveHandle
local moving=false;local themedMove=nil
-- true while the theme owns the chat geometry (defined first: the move handle needs it)
local function Themed() return FieldKitReferenceHUD and FieldKitReferenceHUD.active and FieldKitReferenceHUD.chat and true or false end
local copiedNative=false
local lastPositionStamp
local geometryStamp
local fontStamp
local MAX_MESSAGES,MAX_BYTES=100,512

local backgrounds={
 {0.035,0.045,0.055}, -- charcoal
 {0.012,0.015,0.023}, -- obsidian
 {0.035,0.065,0.11}, -- midnight blue
 {0.13,0.085,0.055}, -- warm brown
 {0.035,0.09,0.075}, -- forest
 {0,0,0}, -- black
}
local foregrounds={
 {1,1,1}, {.95,.92,.83}, {1,.82,.49},
 {.69,.93,.77}, {.69,.85,1}, {.76,.77,.78},
}
local fontFiles={
 nil, -- retain the user's native font, even if customized by another addon
 "Fonts\\FRIZQT__.TTF",
 "Fonts\\ARIALN.TTF",
 "Fonts\\MORPHEUS.TTF",
 "Fonts\\SKURRI.TTF",
}

-- Native chat only. These controls never replace chat tabs or channel logic.
local function NativeChat()
 return getglobal("ChatFrame1") or DEFAULT_CHAT_FRAME
end
local function Clamp(v,default,minimum,maximum)
 v=tonumber(v)
 if not v or v~=v then v=default end
 return math.floor(math.max(minimum,math.min(maximum,v))+.5)
end
local function ApplyAnchor(f)
 local anchor=FieldKitDB and FieldKitDB.chatAnchor
 if not anchor or type(anchor)~="table" or moving then return end
 local x=tonumber(anchor.x);local y=tonumber(anchor.y)
 if not x or not y or x~=x or y~=y then return end
 local maxX=math.max(0,UIParent:GetWidth()-f:GetWidth())
 local maxY=math.max(0,UIParent:GetHeight()-f:GetHeight())
 x=math.max(0,math.min(x,maxX));y=math.max(0,math.min(y,maxY))
 local stamp=tostring(x)..":"..tostring(y)..":"..tostring(f:GetWidth())..":"..tostring(f:GetHeight())
 if lastPositionStamp==stamp then return end
 lastPositionStamp=stamp
 f:ClearAllPoints()
 f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
end
local function SaveAnchor(f)
 if not FieldKitDB then return end
 local x=f.GetLeft and f:GetLeft()
 local y=f.GetBottom and f:GetBottom()
 if type(x)~="number" or type(y)~="number" then
  local point,relative,relPoint,offX,offY=f:GetPoint()
  if point=="BOTTOMLEFT" and relPoint=="BOTTOMLEFT" and relative==UIParent then
   x=offX;y=offY
  end
 end
 if type(x)=="number" and type(y)=="number" then
  lastPositionStamp=nil
  FieldKitDB.chatAnchor={
   x=Clamp(x,0,0,UIParent:GetWidth()),
   y=Clamp(y,0,0,UIParent:GetHeight())
  }
 end
end
local function FinishMove()
 if not moving then return end
 moving=false
 if themedMove then
  themedMove=nil;local card=FieldKitReferenceHUD and FieldKitReferenceHUD.chat
  if card then FieldKitZoneThemes.Finish(card) end
  return
 end
 local f=NativeChat()
 if f then
  f:StopMovingOrSizing()
  SaveAnchor(f)
 end
 if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
end
local function MoveControl()
 local f=NativeChat()
 if not f then return end
 if not moveHandle then
  moveHandle=CreateFrame("Button","FieldKitChatMoveHandle",UIParent)
  moveHandle:SetWidth(112);moveHandle:SetHeight(19)
  moveHandle:SetFrameStrata("MEDIUM")
  moveHandle:EnableMouse(true)
  moveHandle:RegisterForDrag("LeftButton")
  moveHandle:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
   edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,
   edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
  moveHandle:SetBackdropColor(.015,.025,.037,.95)
  moveHandle:SetBackdropBorderColor(.50,.41,.25,.8)
  local title=moveHandle:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  title:SetPoint("CENTER",moveHandle,"CENTER",0,0)
  FieldKit_Text(title,"Move chat")
  moveHandle:SetScript("OnDragStart",function()
   if not FieldKitDB or not FieldKitDB.chatStyle or not FieldKitDB.chatMove then return end
   local frame=NativeChat();if not frame then return end
   if Themed() then
    local card=FieldKitReferenceHUD.chat;if not card then return end
    themedMove=true;moving=true;card.azsMoving=true;card:StartMoving();return
   end
   frame:SetMovable(true)
   if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
   moving=true
   frame:StartMoving()
  end)
  moveHandle:SetScript("OnDragStop",FinishMove)
  moveHandle:SetScript("OnMouseUp",FinishMove)
  moveHandle:SetScript("OnHide",FinishMove)
 end
 local anchorFrame=(Themed() and FieldKitReferenceHUD.chat) or f
 if moveHandle.fieldkitAnchor~=anchorFrame then
  moveHandle:ClearAllPoints()
  moveHandle:SetPoint("BOTTOMLEFT",anchorFrame,"TOPLEFT",56,2)
  moveHandle.fieldkitAnchor=anchorFrame
 end
 if FieldKitDB and FieldKitDB.chatStyle and FieldKitDB.chatMove then moveHandle:Show()
 else moveHandle:Hide() end
end
-- Reset only chat geometry/anchor, keeping the current profile palette,
-- font and existing messages. Prefer the native dimensions measured before
-- FieldKit styling; fall back to the validated default dimensions.
function FieldKit.ResetChatLayout()
 local db=FieldKitDB
 if not db then return false end
 local baseline=styleBefore
 db.chatWidth=Clamp(baseline and baseline.width,440,280,800)
 db.chatHeight=Clamp(baseline and baseline.height,180,100,450)
 FieldKit.ResetChatPosition()
 if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
 return true
end

function FieldKit.ResetChatPosition()
 FinishMove()
 if FieldKitDB then FieldKitDB.chatAnchor=nil end
 lastPositionStamp=nil
 local f=NativeChat()
 if not f then return end
 -- GetPoint may return nil or a partial anchor in this client.
 local p=styleBefore and styleBefore.point
 if p and type(p[1])=="string" and p[1]~="" then
  local relative=p[2] or UIParent
  local relativePoint=p[3] or p[1]
  local x=tonumber(p[4]) or 0
  local y=tonumber(p[5]) or 0
  f:ClearAllPoints()
  f:SetPoint(p[1],relative,relativePoint,x,y)
 end
 if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
end
-- Stage 1 of the in-game isolation recipe: capture, movement and a separate
-- backdrop ONLY. Do not touch native message rendering, font, history, sizing,
-- fading, or AddMessage color hooks until each is validated on the real client.
-- ---------------------------------------------------------------------------------------------------------------------
-- Theme integration. With a themed HUD the native ChatFrame1 lives inside the theme's chat card. The card (position, size,
-- fill) and the text frame inside it are driven by the user's chat preferences through FieldKitReferenceHUD.ChatPlan: the theme
-- only dresses the chat, it never replaces a preference. While themed, this module does not touch the native geometry, font or
-- anchor itself (two writers would fight); it keeps the move handle and the message hooks.
FieldKit.ChatThemed=Themed
function FieldKit.ChatBackground(index) local c=backgrounds[Clamp(index,1,1,table.getn(backgrounds))];return {c[1],c[2],c[3]} end
-- Font and size the themed chat must use: the user's choice when customization is on (face 1 = the theme's own font).
function FieldKit.ChatFontWanted(themePath,themeSize)
 local db=FieldKitDB
 if not db or not db.chatStyle then return themePath,themeSize end
 local face=Clamp(db.chatFontFace,1,1,5)
 return (face==1 and themePath) or fontFiles[face] or themePath,Clamp(db.chatFontSize,12,10,20)
end
-- Chat geometry helpers (UIParent-relative anchors only): where the frame would be on the screen.
local function Frac(point)
 local px,py=.5,.5
 if string.find(point or "","LEFT") then px=0 elseif string.find(point or "","RIGHT") then px=1 end
 if string.find(point or "","TOP") then py=1 elseif string.find(point or "","BOTTOM") then py=0 end
 return px,py
end
function FieldKit.ChatRect(point,relPoint,x,y,width,height,scale)
 if type(point)~="string" or type(width)~="number" or type(height)~="number" then return nil end
 scale=scale or 1;local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 local rx,ry=Frac(relPoint or point);local fx,fy=Frac(point)
 local px,py=rx*sw+(tonumber(x) or 0)*scale,ry*sh+(tonumber(y) or 0)*scale
 local left,bottom=px-fx*width*scale,py-fy*height*scale
 return left,bottom,left+width*scale,bottom+height*scale
end
-- Visible = most of the chat is on the screen (a drag may legitimately overhang by a few pixels).
function FieldKit.ChatVisible(left,bottom,right,top)
 if not left then return false end
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 local w,h=right-left,top-bottom;if w<=0 or h<=0 then return false end
 local across=math.min(right,sw)-math.max(left,0);local depth=math.min(top,sh)-math.max(bottom,0)
 return across>=w*.6 and depth>=h*.6
end
-- Native chat geometry remembered while the chat is NOT themed (additive key chatNative, never rewritten while themed).
function FieldKit.ChatNativeCapture()
 local f=NativeChat();if not f or not FieldKitDB then return false end
 if f.GetParent and f:GetParent()~=UIParent then return false end -- already themed: nothing native to remember
 local point,relative,relPoint,x,y=f:GetPoint()
 if type(point)~="string" or point=="" then return false end
 if relative~=nil and relative~=UIParent and relative~="UIParent" then return false end
 local scale=f.GetScale and f:GetScale() or 1
 local l,b,r,t=FieldKit.ChatRect(point,relPoint or point,x,y,f:GetWidth(),f:GetHeight(),scale)
 if not FieldKit.ChatVisible(l,b,r,t) then return false end
 FieldKitDB.chatNative={point=point,relPoint=relPoint or point,x=tonumber(x) or 0,y=tonumber(y) or 0,width=f:GetWidth(),height=f:GetHeight(),scale=scale}
 return true
end
-- Put the chat back where it is visible: the points the theme saved if they are valid, else the remembered native geometry,
-- else the default place; then the guard.
function FieldKit.ChatRestoreNative(f,saved)
 local db=FieldKitDB;local choice
 local function Try(point,relative,relPoint,x,y,width,height,scale)
  if type(point)~="string" or (relative~=UIParent and relative~=nil) then return nil end
  local l,b,r,t=FieldKit.ChatRect(point,relPoint or point,x,y,width,height,scale)
  if FieldKit.ChatVisible(l,b,r,t) then return {point=point,relPoint=relPoint or point,x=x,y=y,width=width,height=height,scale=scale or 1} end
 end
 local first=saved and saved.points and saved.points[1]
 if first then choice=Try(first[1],first[2],first[3],first[4],first[5],saved.width,saved.height,saved.scale) end
 if not choice and db and type(db.chatNative)=="table" then local n=db.chatNative;choice=Try(n.point,UIParent,n.relPoint,n.x,n.y,n.width,n.height,n.scale) end
 if not choice then choice={point="BOTTOMLEFT",relPoint="BOTTOMLEFT",x=32,y=95,width=(saved and saved.width) or 440,height=(saved and saved.height) or 180,scale=(saved and saved.scale) or 1} end
 f:ClearAllPoints();f:SetPoint(choice.point,UIParent,choice.relPoint,choice.x,choice.y)
 if not FieldKit.ResizeChatPreservingHistory or not FieldKit.ResizeChatPreservingHistory(choice.width,choice.height) then
  if f:GetWidth()~=choice.width then f:SetWidth(choice.width) end;if f:GetHeight()~=choice.height then f:SetHeight(choice.height) end
 end
 local font=saved and saved.font;if font and f.SetFont then if FieldKit.ThemeChatFont then FieldKit.ThemeChatFont(font[1],font[2],font[3]) else pcall(f.SetFont,f,font[1],font[2],font[3]) end end
 geometryStamp=nil;fontStamp=nil;lastPositionStamp=nil
 -- customization on: the preferences (size, font, position) apply to the native chat right away, then the guard
 if FieldKit.ApplyChatStyle then FieldKit.ApplyChatStyle() end
 FieldKit.ChatGuard(f)
 return true
end
-- Never leave the chat off the screen: after any restore, any themed -> native change or any style application.
function FieldKit.ChatGuard(f)
 f=f or NativeChat();if not f or Themed() then return false end
 local point,relative,relPoint,x,y=f:GetPoint()
 local scale=f.GetScale and f:GetScale() or 1;local w,h=f:GetWidth(),f:GetHeight()
 local l,b,r,t
 if f.GetLeft and f:GetLeft() and f.GetBottom and f:GetBottom() and f.GetRight and f:GetRight() and f.GetTop and f:GetTop() then l,b,r,t=f:GetLeft(),f:GetBottom(),f:GetRight(),f:GetTop()
 elseif relative==UIParent or relative=="UIParent" then l,b,r,t=FieldKit.ChatRect(point,relPoint or point,x,y,w,h,scale) end
 if FieldKit.ChatVisible(l,b,r,t) then return false end
 -- off the screen (or unmeasurable): bring it back to the remembered / default place, kept fully inside the screen
 local n=FieldKitDB and FieldKitDB.chatNative
 local px,py=32,95
 if type(n)=="table" and n.point=="BOTTOMLEFT" and n.relPoint=="BOTTOMLEFT" then px,py=tonumber(n.x) or 32,tonumber(n.y) or 95 end
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 px=math.max(0,math.min(px,math.max(0,sw-w*scale)))/scale;py=math.max(0,math.min(py,math.max(0,sh-h*scale)))/scale
 f:ClearAllPoints();f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",px,py);lastPositionStamp=nil
 return true
end
-- The themed chat card is planned from these preferences only (R.ChatPlan, ChatFontWanted). The chat watcher calls ApplyChatStyle
-- five times a second: the theme is told to refresh only when one of them CHANGED (it used to be forced twice per tick, i.e. a full
-- theme refresh ten times a second). The theme's own periodic refresh recomputes the plan anyway, so a missed change is applied
-- within a fifth of a second even without this call.
local themedChatKeys={"chatStyle","chatWidth","chatHeight","chatBackgroundOpacity","chatBackgroundColor","chatFontFace","chatFontSize"}
local themedChatSeen={}
local themedChatKnown=false
local function ThemedChatChanged()
 local db=FieldKitDB;local changed=not themedChatKnown
 for i=1,table.getn(themedChatKeys) do
  local key=themedChatKeys[i];local value=db[key]
  if themedChatSeen[key]~=value then themedChatSeen[key]=value;changed=true end
 end
 themedChatKnown=true
 return changed
end
function FieldKit.ApplyChatStyle()
 local f=NativeChat()
 if not f or not FieldKitDB then return end
 if Themed() then
  -- the theme owns the geometry while it is active; keep the handle and the hooks, never restore a native snapshot onto a themed chat
  if chatBackdrop then chatBackdrop:Hide() end
  MoveControl()
  if ThemedChatChanged() and FieldKitReferenceHUD.ChatSync then FieldKitReferenceHUD.ChatSync() end
  return
 end
 themedChatKnown=false -- the next themed pass synchronises once
 if not FieldKitDB.chatStyle then
  if moving then FinishMove() end
  if chatBackdrop then chatBackdrop:Hide() end
  if moveHandle then moveHandle:Hide() end
  if styleBefore and chatFrame==f then
   local snap=styleBefore
   local count=f.GetNumMessages and f:GetNumMessages() or nil
   -- Only invoke native destructive setters when all displayed messages are
   -- known, or when the chat is empty. Untracked lines are never cleared.
   local recoverable=type(count)=="number"
    and (count==0 or (count==table.getn(displayHistory) and count<=DISPLAY_LIMIT))
   if recoverable then
    if snap.width and f.SetWidth and f:GetWidth()~=snap.width then f:SetWidth(snap.width) end
    if snap.height and f.SetHeight and f:GetHeight()~=snap.height then f:SetHeight(snap.height) end
    if snap.maxLines and f.SetMaxLines and
     (not f.GetMaxLines or f:GetMaxLines()~=snap.maxLines) then f:SetMaxLines(snap.maxLines) end
    if snap.font and snap.fontSize and f.SetFont then f:SetFont(snap.font,snap.fontSize,snap.flags) end
    if count>0 and f.GetNumMessages and f:GetNumMessages()<count then FieldKit.RestoreDisplayedChat() end
   end
   if snap.point and type(snap.point[1])=="string" and type(snap.point[3])=="string" then
    local p=snap.point
    f:ClearAllPoints()
    f:SetPoint(p[1],p[2] or UIParent,p[3],p[4] or 0,p[5] or 0)
   end
  end
  styleBefore=nil;chatFrame=nil;lastPositionStamp=nil
  geometryStamp=nil;fontStamp=nil
  return
 end
 if not styleBefore or chatFrame~=f then
  local point,relative,relativePoint,x,y=f:GetPoint()
  if type(point)=="string" and point~="" then
   styleBefore={point={point,relative or UIParent,relativePoint or point,tonumber(x) or 0,tonumber(y) or 0},width=f:GetWidth(),height=f:GetHeight(),maxLines=f.GetMaxLines and f:GetMaxLines() or nil}
  else
   styleBefore={width=f:GetWidth(),height=f:GetHeight(),maxLines=f.GetMaxLines and f:GetMaxLines() or nil}
  end
  if f.GetFont then
   styleBefore.font,styleBefore.fontSize,styleBefore.flags=f:GetFont()
  end
  if not styleBefore.font and ChatFontNormal and ChatFontNormal.GetFont then
   styleBefore.font,styleBefore.fontSize,styleBefore.flags=ChatFontNormal:GetFont()
  end
  geometryStamp=nil; fontStamp=nil
  chatFrame=f
 end
 local opacity=Clamp(FieldKitDB.chatBackgroundOpacity,0,0,100)
 local bg=Clamp(FieldKitDB.chatBackgroundColor,1,1,table.getn(backgrounds))
 if opacity>0 then
  if not chatBackdrop then
   chatBackdrop=f:CreateTexture(nil,"BACKGROUND")
   chatBackdrop:SetAllPoints(f)
   chatBackdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
  end
  local c=backgrounds[bg]
  chatBackdrop:SetVertexColor(c[1],c[2],c[3],opacity/100)
  chatBackdrop:Show()
 elseif chatBackdrop then chatBackdrop:Hide() end
 -- Preserve the native scrolling frame. The client's SetMaxLines,
 -- SetFont and size setters can empty its visible lines. Apply only on changes,
 -- then recover the messages observed since styling was enabled.
 local face=Clamp(FieldKitDB.chatFontFace,1,1,5)
 local size=Clamp(FieldKitDB.chatFontSize,12,10,20)
 local width,height=Clamp(FieldKitDB.chatWidth,440,280,800),Clamp(FieldKitDB.chatHeight,180,100,450)
 local lines=Clamp(FieldKitDB.chatHistoryLines,200,100,500)
 local requestedFont=(face==1 and styleBefore.font) or fontFiles[face] or styleBefore.font
 local wanted=tostring(width)..":"..tostring(height)..":"..tostring(lines)..":"..tostring(requestedFont)..":"..tostring(size)
 if geometryStamp~=wanted then
  local before=f.GetNumMessages and f:GetNumMessages() or nil
  -- Never suppress interactive width/height/font controls. The bounded
  -- journal is kept across temporary style toggles so messages received while
  -- disabled can be reconstructed if these native setters clear the display.
  if f.SetWidth and f:GetWidth()~=width then f:SetWidth(width) end
  if f.SetHeight and f:GetHeight()~=height then f:SetHeight(height) end
  if f.SetMaxLines and (not f.GetMaxLines or f:GetMaxLines()~=lines) then f:SetMaxLines(lines) end
  if f.SetFont and requestedFont and (fontStamp~=tostring(requestedFont)..":"..tostring(size)) then
   local ok=f:SetFont(requestedFont,size,styleBefore.flags)
   if ok~=false then fontStamp=tostring(requestedFont)..":"..tostring(size) end
  end
  geometryStamp=wanted
  lastPositionStamp=nil
  if before and before>0 and f.GetNumMessages and f:GetNumMessages()<before then
   FieldKit.RestoreDisplayedChat()
  end
 end
 ApplyAnchor(f)
 MoveControl()
 return
end

-- Reuse the native chat frame as anchor, without replacing its handlers.
local function CopyButton()
 local f=NativeChat()
 if not f then return end
 if button and FieldKitDB and FieldKitDB.chatShowCopyButton==false then button:Hide();return end
 if FieldKitDB and FieldKitDB.chatShowCopyButton==false then return end
 if not button then
  button=CreateFrame("Button","FieldKitChatCopyButton",UIParent)
  button:SetWidth(48);button:SetHeight(18)
  button:SetFrameStrata("MEDIUM");button:SetFrameLevel(f:GetFrameLevel()+5)
  button:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
  button:SetBackdropColor(.025,.045,.065,.85)
  button:SetBackdropBorderColor(.48,.38,.22,.8)
  local label=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  label:SetPoint("CENTER",button,"CENTER",0,0);FieldKit_Text(label,"Copy")
  button:SetScript("OnClick",function() FieldKit.OpenChatCopy() end)
  button:SetScript("OnEnter",function()
   if GameTooltip then
    GameTooltip:SetOwner(this,"ANCHOR_TOP")
    GameTooltip:SetText(FieldKit_L("Open chat copy"))
    GameTooltip:Show()
   end
  end)
  button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 end
 if button.fieldkitChatAnchor~=f then
  button:ClearAllPoints()
  button:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,2)
  button.fieldkitChatAnchor=f
 end
 button:Show()
end

-- Only newer client variants expose read access to the rendered chat buffer.
-- Vanilla 1.12 lacks this API; no fabricated retroactive text is inserted.

-- Remove display markup and bound each retained message, UTF-8 safely.
local function Clean(text)
 if type(text)~="string" then return "" end
 text=string.sub(text,1,4096)
 text=string.gsub(text,"|c%x%x%x%x%x%x%x%x","");text=string.gsub(text,"|r","")
 text=string.gsub(text,"|H([^|]*)|h([^|]*)|h","%2");text=string.gsub(text,"|T([^|]*)|t","")
 return FieldKitCombat.LimitText(string.gsub(text,"[\r\n]"," "),MAX_BYTES)
end

-- Installed post-hooks also call this after opt-out; the guard prevents retention.
local function Capture(index,text)
 if not FieldKitDB or not FieldKitDB.chatCopy or type(text)~="string" then return end
 local list=history[index] or {};history[index]=list
 if table.getn(list)>=MAX_MESSAGES then table.remove(list,1) end
 table.insert(list,Clean(text))
end

local function ImportVisible()
 if copiedNative then return end
 local f=NativeChat()
 if not f or type(f.GetNumMessages)~="function" or type(f.GetMessageInfo)~="function" then return end
 local ok,n=pcall(function() return f:GetNumMessages() end)
 if not ok or type(n)~="number" then return end
 copiedNative=true
 for i=math.max(1,n-MAX_MESSAGES+1),n do
  local success,line=pcall(function() return f:GetMessageInfo(i) end)
  if success and type(line)=="string" and line~="" then Capture(1,line) end
 end
end

-- Clear both memory and any text already visible in the local copy editbox.
function FieldKit.ClearChat()
 history={}
 if copyEdit then copyEdit:SetText("") end
 if copyFrame then copyFrame:Hide() end
end

-- The only local observation of native AddMessage. Its forwarding wrapper
-- preserves message order, return value, channel colors and links.
-- Render history is in-memory only and cleared when styling is disabled.
local function Hook(index)
 local frame=getglobal("ChatFrame"..index)
 if not frame or hooked[frame] or type(frame.AddMessage)~="function" then return end
 hooked[frame]=true
 local original=frame.AddMessage
 frame.AddMessage=function(self,text,r,g,b,id)
  if not replaying then
   Capture(index,text)
   if FieldKitDB and (FieldKitDB.chatStyle or FieldKitDB.zoneThemes or styleWasEnabled) and type(text)=="string" then
    if table.getn(displayHistory)>=DISPLAY_LIMIT then table.remove(displayHistory,1) end
    table.insert(displayHistory,{text=text,r=r,g=g,b=b,id=id})
   end
  end
  if FieldKitDB and FieldKitDB.chatStyle and FieldKitDB.chatOverrideText and type(text)=="string" then
   local color=foregrounds[Clamp(FieldKitDB.chatTextColor,1,1,table.getn(foregrounds))]
   -- Replace only display color markup. Preserve hyperlinks and text.
   text=string.gsub(text,"|c%x%x%x%x%x%x%x%x","")
   text=string.gsub(text,"|r","")
   r,g,b=color[1],color[2],color[3]
  end
  return original(self,text,r,g,b,id)
 end
end

-- Explicit reset for session boundaries and diagnostics. The bounded render
-- journal is not the opt-in chat-copy history, and is never persisted.
function FieldKit.ClearChatRenderHistory()
 displayHistory={}
end

-- Some native clients clear scrolling text on resize. Never compact an
-- existing chat unless its entire displayed history can be restored.
function FieldKit.ResizeChatPreservingHistory(width,height)
 local f=NativeChat()
 if not f then return false end
 if f:GetWidth()==width and f:GetHeight()==height then return true end
 if not f.GetNumMessages then return false end
 local count=f:GetNumMessages()
 if type(count)~="number" then return false end
 if count>0 and count~=table.getn(displayHistory) then
  if type(f.GetMessageInfo)~="function" then return false end
  local snapshot={}
  for i=1,count do
   local ok,text,r,g,b,id=pcall(f.GetMessageInfo,f,i)
   if not ok or type(text)~="string" then return false end
   table.insert(snapshot,{text=text,r=r,g=g,b=b,id=id})
  end
  displayHistory=snapshot
 end
 if f:GetWidth()~=width then f:SetWidth(width) end
 if f:GetHeight()~=height then f:SetHeight(height) end
 if count>0 and f:GetNumMessages()<count then FieldKit.RestoreDisplayedChat() end
 return true
end

-- Rebuild only when a native layout setter demonstrably discards lines.
-- Never recapture replayed messages and never touch the local copy buffer.
function FieldKit.RestoreDisplayedChat()
 local f=NativeChat()
 if not f or not f.AddMessage or replaying then return end
 local count=table.getn(displayHistory)
 if count==0 then return end
 replaying=true
 if f.Clear then f:Clear() end
 for i=1,count do
  local m=displayHistory[i]
  f:AddMessage(m.text,m.r,m.g,m.b,m.id)
 end
 replaying=false
end

-- Color changes cannot mutate existing ScrollingMessageFrame lines in place.
-- Re-render ONLY when every visible line is represented in our bounded
-- in-memory history; otherwise clearing would irreversibly destroy messages
-- that arrived before FieldKit started observing the chat.
function FieldKit.RecolorDisplayedChat()
 if not FieldKitDB or replaying then return false end
 local f=NativeChat()
 if not f or not f.GetNumMessages or not f.Clear then return false end
 local known=table.getn(displayHistory)
 local visible=f:GetNumMessages()
 if type(visible)~="number" or visible<1 then return false end
 -- The legacy chat might contain lines predating the addon. If the client
 -- exposes GetMessageInfo, take a complete snapshot first and avoid dropping
 -- those lines. Do not assume this newer API exists on a 1.12 client.
 if visible~=known then
  if type(f.GetMessageInfo)~="function" then return false end
  local snapshot={}
  for i=1,visible do
   local ok,text,r,g,b,id=pcall(f.GetMessageInfo,f,i)
   if not ok or type(text)~="string" then return false end
   table.insert(snapshot,{text=text,r=r,g=g,b=b,id=id})
  end
  if table.getn(snapshot)~=visible then return false end
  -- Recolor all currently available messages. No data is appended to the
  -- copy/export buffer and no message is duplicated in the display.
  replaying=true
  f:Clear()
  for i=1,table.getn(snapshot) do
   local m=snapshot[i]
   f:AddMessage(m.text,m.r,m.g,m.b,m.id)
  end
  replaying=false
  return true
 end
 if known==0 then return false end
 FieldKit.RestoreDisplayedChat()
 return true
end

-- Reconcile one boolean preference. No messages are exported by this watcher.
function FieldKit.SyncChat()
 local enabled=FieldKitDB and FieldKitDB.chatCopy==true
 if not enabled then
  if active then FieldKit.ClearChat() end
  copiedNative=false;active=false
  CopyButton() -- Shortcut does not imply logging consent.
 else
  if not active then ImportVisible() end
  active=true;Hook(1)
  CopyButton()
 end
 if FieldKitDB and FieldKitDB.chatStyle then
  styleWasEnabled=true
  Hook(1)
  FieldKit.ApplyChatStyle()
 else
  -- Do not discard the only recoverable display copy on opt-out. Keep
  -- observing new native lines without changing their colors or copying them
  -- to the opt-in export buffer. The journal stays bounded at DISPLAY_LIMIT.
  if not styleWasEnabled then displayHistory={} end
 end
end

-- The only export is a user-opened editbox. Ctrl+C is performed by the player.
local function OpenCopy()
 FieldKit.SyncChat()
 if not active then
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(FieldKit_L("Local chat copy is disabled. Enable it in Interface or use /fieldkitlog on.")) end
  return
 end
 if not copyFrame then
  local f=CreateFrame("Frame","FieldKitCopyLogFrame",UIParent)
  f:SetWidth(670);f:SetHeight(435);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG")
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  FieldKitTheme.Surface(f,"window")
  local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",f,"TOPLEFT",16,-15)
  FieldKitTheme.Font(title,22,FieldKitTheme.gold,true);FieldKit_Text(title,"FieldKit - Copy chat")
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  close:SetWidth(26);close:SetHeight(26);close:SetFrameLevel(f:GetFrameLevel()+10)
  close:SetScript("OnClick",function() copyFrame:Hide() end)
  local scroll=CreateFrame("ScrollFrame","FieldKitCopyLogScroll",f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",f,"TOPLEFT",16,-50);scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-36,45)
  scroll:SetWidth(618);scroll:SetHeight(340)
  local e=CreateFrame("EditBox","FieldKitCopyLogEdit",scroll)
  e:SetWidth(605);e:SetHeight(320);e:SetMultiLine(true);e:SetAutoFocus(false);e:SetMaxLetters(52000);e:SetFontObject("ChatFontNormal")
  e:SetScript("OnEscapePressed",function() this:ClearFocus();copyFrame:Hide() end);scroll:SetScrollChild(e)
  local hint=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",16,14)
  FieldKit_Text(hint,"Ctrl+A puis Ctrl+C - texte sans codes de couleur")
  FieldKitTheme.Font(hint,12,FieldKitTheme.muted)
  copyFrame=f;copyEdit=e;f.fieldkitHint=hint
 end
 ImportVisible()
 local text=table.concat(history[1] or {},"\n")
 if copyFrame and copyFrame.fieldkitHint then
  if text=="" then FieldKit_Text(copyFrame.fieldkitHint,"No captured messages yet. Enable recording and wait for new chat messages.")
  else FieldKit_Text(copyFrame.fieldkitHint,"Ctrl+A, then Ctrl+C to copy these captured messages.") end
 end
 copyEdit:SetText(text);local _,lines=string.gsub(text,"\n","\n")
 copyEdit:SetHeight(math.max(320,(lines+1)*16+20));copyFrame:Show();copyEdit:SetFocus();copyEdit:HighlightText()
end

-- Public action for the Interface button and chat shortcut; recording is still opt-in.
function FieldKit.OpenChatCopy()
 OpenCopy()
end

-- Poll only the preference, at 5 Hz. No per-frame chat traversal or copy buttons.
local watcher=CreateFrame("Frame","FieldKitChatWatcher",UIParent)
local elapsed=0
watcher:SetScript("OnUpdate",function()
 elapsed=elapsed+(arg1 or 0);if elapsed<.2 then return end
 elapsed=0;FieldKit.SyncChat()
 if FieldKitDB and FieldKitDB.chatStyle then FieldKit.ApplyChatStyle() end
end)
SLASH_FieldKitLOG1="/fieldkitlog"
SlashCmdList.FieldKitLOG=function(message)
 if not FieldKitDB then return end
 if message=="on" then FieldKitDB.chatCopy=true;FieldKit.SyncChat();return end
 if message=="off" then FieldKitDB.chatCopy=false;FieldKit.SyncChat();return end
 if message=="clear" then FieldKit.ClearChat();return end
 OpenCopy()
end

-- Native SetFont can clear every visible line. Theme changes use the same
-- complete-history gate as resizing, and never repeat an unchanged setter.
function FieldKit.ThemeChatFont(path,size,flags)
 local f=NativeChat();if not f or not f.GetFont or not f.SetFont or not f.GetNumMessages then return false end
 local old,oldSize,oldFlags=f:GetFont();flags=flags or ""
 if old==path and oldSize==size and (oldFlags or "")==flags then return true end
 local count=f:GetNumMessages();if type(count)~="number" then return false end
 if count>0 and count~=table.getn(displayHistory) then
  if type(f.GetMessageInfo)~="function" then return false end
  local snapshot={}
  for i=1,count do local ok,text,r,g,b,id=pcall(f.GetMessageInfo,f,i);if not ok or type(text)~="string" then return false end;table.insert(snapshot,{text=text,r=r,g=g,b=b,id=id}) end
  displayHistory=snapshot
 end
 local ok=pcall(f.SetFont,f,path,size,flags)
 if count>0 and f:GetNumMessages()<count then FieldKit.RestoreDisplayedChat() end
 return ok
end
