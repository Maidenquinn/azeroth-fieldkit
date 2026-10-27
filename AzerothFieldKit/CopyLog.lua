-- MASH chat integration: compatible with legacy WoW Lua.
-- Do not replace chat frame AddMessage: preserve original message routing and colors.
local historyByFrame = {}
local maxMessages = 350
local copyFrame, copyEdit
local buttons = {}
local function clean(s)
 if type(s) ~= "string" then return "" end
 s=string.gsub(s,"|c%x%x%x%x%x%x%x%x","")
 s=string.gsub(s,"|r","")
 s=string.gsub(s,"|H([^|]*)|h([^|]*)|h","%2")
 s=string.gsub(s,"|T([^|]*)|t","")
 return string.gsub(s,"[\r\n]"," ")
end
local function stamp()
 if type(date)=="function" then return date("%H:%M:%S") end
 return "--:--:--"
end
local function add(idx,msg)
 if type(msg)~="string" then return end
 local h=historyByFrame[idx]
 if not h then h={};historyByFrame[idx]=h end
 h[table.getn(h)+1]="["..stamp().."] "..clean(msg)
 local n=table.getn(h)
 if n>maxMessages then
  for j=1,n-1 do h[j]=h[j+1] end
  h[n]=nil
 end
end
local function ensureCopyFrame()
 if copyFrame then return end
 local f=CreateFrame("Frame","MASHCopyLogFrame",UIParent)
 f:SetWidth(670);f:SetHeight(435)
 f:SetPoint("CENTER",UIParent,"CENTER",0,0)
 f:SetFrameStrata("DIALOG")
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=5,right=5,top=5,bottom=5}})
 f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function() this:StartMoving() end)
 f:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
 local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 title:SetPoint("TOPLEFT",f,"TOPLEFT",16,-15)
 MASH_Text(title,"MASH - Copier le chat")
 local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
 close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
 local scroll=CreateFrame("ScrollFrame","MASHCopyLogScroll",f,"UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT",f,"TOPLEFT",16,-50)
 scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-36,45)
 local e=CreateFrame("EditBox","MASHCopyLogEdit",scroll)
 e:SetWidth(605);e:SetHeight(320);e:SetMultiLine(true);e:SetAutoFocus(false)
 e:SetFontObject("ChatFontNormal")
 e:SetScript("OnEscapePressed",function() this:ClearFocus() end)
 scroll:SetScrollChild(e)
 local hint=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",16,14)
 MASH_Text(hint,"Ctrl+A puis Ctrl+C - texte sans codes de couleur")
 copyFrame=f;copyEdit=e;f:Hide()
end
local function openCopy(idx)
 ensureCopyFrame()
 local txt
 txt=table.concat(historyByFrame[idx] or {},"\n")
 copyEdit:SetText(txt)
 local _,newlines=string.gsub(txt,"\n","\n")
 copyEdit:SetHeight(math.max(320,(newlines+1)*16+20))
 copyFrame:Show();copyEdit:SetFocus();copyEdit:HighlightText()
end
-- Capture only via hooksecurefunc when supported, otherwise wrap once.
local function setup(idx)
 local frame=getglobal("ChatFrame"..idx)
 if not frame or frame.MASHNativeChatHooked then return end
 local original=frame.AddMessage
 if type(original)~="function" then return end
 local captured=false
 if type(hooksecurefunc)=="function" then
  local ok=pcall(function()
   hooksecurefunc(frame,"AddMessage",function(self,msg) add(idx,msg) end)
  end)
  captured=ok
 end
 if not captured then
  frame.AddMessage=function(self,msg,r,g,b,id)
   add(idx,msg)
   return original(self,msg,r,g,b,id)
  end
 end
 frame.MASHNativeChatHooked=true
 local button=CreateFrame("Button","MASHChatCopyButton"..idx,frame,"UIPanelButtonTemplate")
 button:SetWidth(52);button:SetHeight(18);MASH_Text(button,"Copier")
 -- Anchor INSIDE the chat frame: never float outside the chat area.
 button:SetPoint("BOTTOMRIGHT",frame,"TOPRIGHT",0,-3)
 button:SetFrameStrata("MEDIUM")
 button:SetScript("OnClick",function() openCopy(idx) end)
 button:Hide()
 frame.MASHCopyButton=button
 buttons[idx]={frame=frame,button=button}
end
for i=1,7 do setup(i) end
-- Follow native chat fade and hover. No independent always-visible button.
local watcher=CreateFrame("Frame")
local elapsed=0
watcher:SetScript("OnUpdate",function()
 elapsed=elapsed+(arg1 or 0)
 if elapsed<0.12 then return end
 elapsed=0
 for i=1,7 do
  local data=buttons[i]
  if data then
   local f=data.frame
   local b=data.button
   local alpha=f:GetAlpha() or 1
   -- Azeroth Survivors/Vanilla does not implement Frame:IsMouseOver().
   -- MouseIsOver is optional too: use focus ancestry as a safe fallback.
   local hovered=false
   if type(MouseIsOver)=="function" then
    hovered=MouseIsOver(f) or MouseIsOver(b)
   elseif type(GetMouseFocus)=="function" then
    local focus=GetMouseFocus()
    local depth=0
    while focus and depth<12 do
     if focus==f or focus==b then hovered=true;break end
     if type(focus.GetParent)~="function" then break end
     focus=focus:GetParent()
     depth=depth+1
    end
   end
   if f:IsVisible() and alpha>0.08 and hovered then
    b:SetAlpha(alpha)
    b:Show()
   else b:Hide() end
  end
 end
end)
SLASH_MASHLOG1="/mashlog"
SlashCmdList["MASHLOG"]=function(msg)
 msg=string.lower(msg or "")
 if string.find(msg,"clear") then historyByFrame={};return end
 openCopy(1)
end
