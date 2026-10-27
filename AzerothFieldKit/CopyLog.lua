-- Optional local chat copy. No capture until opt-in; never persisted or uploaded.
-- Whispers can be included. Copying to the OS clipboard remains a player action.
local history,hooked={},{}
local copyFrame,copyEdit
local active=false
local MAX_MESSAGES,MAX_BYTES=100,512

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
  active=false;return
 end
 active=true;Hook(1) -- Only the main chat window is offered by the copy UI.
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
  copyFrame=f;copyEdit=e
 end
 local text=table.concat(history[1] or {},"\n")
 copyEdit:SetText(text);local _,lines=string.gsub(text,"\n","\n")
 copyEdit:SetHeight(math.max(320,(lines+1)*16+20));copyFrame:Show();copyEdit:SetFocus();copyEdit:HighlightText()
end

-- Poll only the preference, at 5 Hz. No per-frame chat traversal or copy buttons.
local watcher=CreateFrame("Frame","FieldKitChatWatcher",UIParent)
local elapsed=0
watcher:SetScript("OnUpdate",function()
 elapsed=elapsed+(arg1 or 0);if elapsed<.2 then return end
 elapsed=0;FieldKit.SyncChat()
end)
SLASH_FieldKitLOG1="/fieldkitlog"
SlashCmdList.FieldKitLOG=function(message)
 if not FieldKitDB then return end
 if message=="on" then FieldKitDB.chatCopy=true;FieldKit.SyncChat();return end
 if message=="off" then FieldKitDB.chatCopy=false;FieldKit.SyncChat();return end
 if message=="clear" then FieldKit.ClearChat();return end
 OpenCopy()
end
