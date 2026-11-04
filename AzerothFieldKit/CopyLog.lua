-- Optional local chat copy. No capture until opt-in; never persisted or uploaded.
-- Whispers can be included. Copying to the OS clipboard remains a player action.
local history,hooked={},{}
local copyFrame,copyEdit
local active=false
local button, chatFrame, styleBefore, styleStamp
local copiedNative=false
local MAX_MESSAGES,MAX_BYTES=100,512

-- Prat-inspired native main-chat controls. Opt-in, reversible, bounded.
local function NativeChat()
 return getglobal("ChatFrame1") or DEFAULT_CHAT_FRAME
end
local function Clamp(v,default,minimum,maximum)
 v=tonumber(v)
 if not v or v~=v or v==math.huge or v==-math.huge then v=default end
 return math.floor(math.max(minimum,math.min(maximum,v))+.5)
end
function FieldKit.ApplyChatStyle()
 local f=NativeChat()
 if not f or not FieldKitDB then return end
 if not FieldKitDB.chatStyle then
  if styleBefore and chatFrame==f then
   if styleBefore.width then f:SetWidth(styleBefore.width) end
   if styleBefore.height then f:SetHeight(styleBefore.height) end
   if styleBefore.font and f.SetFont then f:SetFont(styleBefore.font,styleBefore.fontSize,styleBefore.flags) end
   if styleBefore.fading~=nil and f.SetFading then f:SetFading(styleBefore.fading) end
  end
  styleBefore=nil;styleStamp=nil;chatFrame=nil
  return
 end
 if not styleBefore or chatFrame~=f then
  local font,size,flags
  if f.GetFont then font,size,flags=f:GetFont() end
  styleBefore={width=f:GetWidth(),height=f:GetHeight(),font=font,fontSize=size,flags=flags,
   fading=f.GetFading and f:GetFading()}
  chatFrame=f;styleStamp=nil
 end
 local w=Clamp(FieldKitDB.chatWidth,440,280,800)
 local h=Clamp(FieldKitDB.chatHeight,180,100,450)
 local fontSize=Clamp(FieldKitDB.chatFontSize,12,10,20)
 local fading=FieldKitDB.chatFading==true
 local maxLines=Clamp(FieldKitDB.chatHistoryLines,200,100,500)
 local stamp=table.concat({w,h,fontSize,tostring(fading),maxLines},":")
 if styleStamp==stamp then return end
 f:SetWidth(w);f:SetHeight(h)
 if styleBefore.font and f.SetFont then f:SetFont(styleBefore.font,fontSize,styleBefore.flags) end
 if f.SetFading then f:SetFading(fading) end
 if f.SetMaxLines then f:SetMaxLines(maxLines) end
 styleStamp=stamp
end

-- Reuse the native chat frame as anchor, without replacing its handlers.
local function CopyButton()
 local f=NativeChat()
 if not f then return end
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
  button:SetPoint("BOTTOMRIGHT",f,"TOPRIGHT",0,2)
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

-- Hook only after opt-in. A fallback forwarding wrapper remains after opt-out,
-- so we do not overwrite hooks installed later by another addon.
local function Hook(index)
 local frame=getglobal("ChatFrame"..index)
 if not frame or hooked[frame] or type(frame.AddMessage)~="function" then return end
 hooked[frame]=true
 local captured=false
 if type(hooksecurefunc)=="function" then
  captured=pcall(function() hooksecurefunc(frame,"AddMessage",function(self,text) Capture(index,text) end) end)
 end
 if not captured then
  local original=frame.AddMessage
  frame.AddMessage=function(self,text,r,g,b,id)
   Capture(index,text)
   return original(self,text,r,g,b,id)
  end
 end
end

-- Reconcile one boolean preference. No messages are exported by this watcher.
function FieldKit.SyncChat()
 local enabled=FieldKitDB and FieldKitDB.chatCopy==true
 if not enabled then
  if active then FieldKit.ClearChat() end
  copiedNative=false;active=false
  CopyButton() -- Keep the shortcut discoverable; never record without consent.
  return
 end
 if not active then ImportVisible() end
 active=true;Hook(1)
 CopyButton()
 FieldKit.ApplyChatStyle()
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
