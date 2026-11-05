-- Assert the properties relevant to review, using actual production callbacks.
assert(FieldKitDB.chatCopy==false and FieldKitDB.compactBar==false)
assert(FieldKitDB.partyDetailSync==false)
assert(FieldKitDB.chestPins==false and FieldKitDB.guardianPins==false)
assert(FieldKitDB.hidePlates==false and FieldKitDB.bossFrame==false)
-- A disabled filter must not overwrite transparency set by another UI component.
WorldFrame:SetAlpha(.6);update(FieldKitFrame,.1);assert(WorldFrame:GetAlpha()==.6)
FieldKitDB.hidePlates=true;update(FieldKitFrame,.1);assert(WorldFrame:GetAlpha()==0)
FieldKitDB.hidePlates=false;update(FieldKitFrame,.1);assert(WorldFrame:GetAlpha()==.6)
assert(FieldKit.Number("NaN")==nil and FieldKit.Number(1/0)==nil)
assert(FieldKit.Number(0/0)==nil and FieldKit.Number("12")==12)
local writes=0
SetCVar=function() writes=writes+1 end
assert(not FieldKit.SetCVar("spendLevels",1))
assert(not FieldKit.SetCVar("storeLevels",0))
assert(not FieldKit.SetCVar("cameraDistanceMaxFactor",99))
assert(not FieldKit.SetCVar("CombatDamage",2))
assert(writes==0)
assert(FieldKit.SetCVar("CombatDamage","0") and writes==1)
GetCVar=function() error("unknown CVar") end
assert(FieldKit.GetCVar("rotateMinimap")==nil)
GetCVar=function() return "0" end
local sentinel={sentinel=true};AZS_TALENT_TOGGLES=sentinel
fire(FieldKitFrame,"VARIABLES_LOADED")
assert(AZS_TALENT_TOGGLES==sentinel)
-- No chat wrapper or frame is installed until opt-in, and no old messages replay.
ChatFrame1=CreateFrame("Frame","ChatFrame1",UIParent)
local forwarded=0
local lastMessage
local original=function(self,text,r,g,b,id) forwarded=forwarded+1;lastMessage={text=text,r=r,g=g,b=b};return "forwarded" end
ChatFrame1.AddMessage=original
ChatFrame2=CreateFrame("Frame","ChatFrame2",UIParent);ChatFrame2.AddMessage=original
FieldKit.SyncChat();assert(ChatFrame1.AddMessage==original)
local visible={}
local underlying=ChatFrame1.AddMessage
ChatFrame1.AddMessage=function(self,text,r,g,b,id)
 table.insert(visible,{text=text,r=r,g=g,b=b,id=id})
 return underlying(self,text,r,g,b,id)
end
ChatFrame1:AddMessage("private before consent")
SlashCmdList.FieldKitLOG("on")
assert(ChatFrame2.AddMessage==original)
assert(FieldKitChatCopyButton and FieldKitChatCopyButton:IsShown(),"copy shortcut must be next to main chat")
assert(ChatFrame1:AddMessage("opted in")=="forwarded")
assert(FieldKit.OpenChatCopy and type(FieldKit.OpenChatCopy)=="function")
-- Full restoration: simulate the real client's destructive scrolling-frame
-- setters and verify messages are replayed once, without duplicate capture.
ChatFrame1.Clear=function() visible={} end
ChatFrame1.GetNumMessages=function() return table.getn(visible) end
ChatFrame1.GetMaxLines=function(self) return self.maxLines or 200 end
ChatFrame1.GetFont=function(self) return self.fontPath or "Fonts\\\\FRIZQT__.TTF",self.fontSize or 12,"" end
ChatFrame1.SetFont=function(self,path,size,flags)
 self.fontPath=path;self.fontSize=size;self.fontFlags=flags
 self:Clear();return true
end
local nativeOps=0
local function unexpectedNativeMutation() nativeOps=nativeOps+1;error("native fading mutated") end
ChatFrame1.SetTimeVisible=unexpectedNativeMutation
ChatFrame1.SetFading=unexpectedNativeMutation
ChatFrame1.SetFadeDuration=unexpectedNativeMutation
local oldWidth,oldHeight=ChatFrame1:GetWidth(),ChatFrame1:GetHeight()
local rawSetWidth,rawSetHeight=ChatFrame1.SetWidth,ChatFrame1.SetHeight
ChatFrame1.SetWidth=function(self,value) rawSetWidth(self,value);self:Clear() end
ChatFrame1.SetHeight=function(self,value) rawSetHeight(self,value);self:Clear() end
ChatFrame1.SetMaxLines=function(self,value)
 assert(value>=100 and value<=500);self.maxLines=value;self:Clear()
end
-- The baseline layout tests begin with an empty native frame: changing native
-- dimensions with untracked preexisting lines must now defer instead.
ChatFrame1:Clear()
FieldKitDB.chatWidth=510;FieldKitDB.chatHeight=230
FieldKitDB.chatHistoryLines=400;FieldKitDB.chatFontSize=15
FieldKitDB.chatFontFace=2;FieldKitDB.chatStyle=true
FieldKit.SyncChat()
assert(ChatFrame1:GetWidth()==510 and ChatFrame1:GetHeight()==230 and ChatFrame1.maxLines==400)
assert(ChatFrame1.fontSize==15 and string.find(ChatFrame1.fontPath,"FRIZQT",1,true))
assert(ChatFrame1:AddMessage("survive layout",.2,.4,.6)=="forwarded")
assert(table.getn(visible)==1 and visible[1].text=="survive layout")
FieldKitDB.chatWidth=570;FieldKitDB.chatHeight=260;FieldKitDB.chatHistoryLines=350
FieldKitDB.chatFontSize=18;FieldKitDB.chatFontFace=3
FieldKit.ApplyChatStyle()
assert(ChatFrame1:GetWidth()==570 and ChatFrame1:GetHeight()==260 and ChatFrame1.maxLines==350)
assert(ChatFrame1.fontSize==18 and string.find(ChatFrame1.fontPath,"ARIALN",1,true))
assert(table.getn(visible)==1 and visible[1].text=="survive layout","layout lost text or replayed twice")
assert(visible[1].r==.2 and visible[1].g==.4 and visible[1].b==.6)
assert(nativeOps==0)
-- Opting out restores native dimensions/font only when all visible lines were
-- captured. This client mock empties chat on every native setter.
FieldKitDB.chatStyle=false;FieldKit.ApplyChatStyle()
assert(ChatFrame1:GetWidth()==oldWidth and ChatFrame1:GetHeight()==oldHeight,
 "safe chat opt-out should restore original dimensions")
assert(ChatFrame1.maxLines==200 and ChatFrame1.fontSize==12,
 "safe chat opt-out should restore original font and history length")
assert(table.getn(visible)==1 and visible[1].text=="survive layout",
 "restoring native chat must not erase or duplicate visible messages")
FieldKitDB.chatStyle=true;FieldKit.SyncChat()
assert(ChatFrame1:GetWidth()==570 and ChatFrame1:GetHeight()==260,
 "re-enabling chat styling should restore selected configuration")
assert(table.getn(visible)==1 and visible[1].text=="survive layout")
-- Real-client regression: the settings remain responsive after temporary
-- opt-out even when additional native messages arrive while styling is off.
-- The display journal must remain intact across the SyncChat 5 Hz ticker.
FieldKitDB.chatStyle=false;FieldKit.ApplyChatStyle();FieldKit.SyncChat()
ChatFrame1:AddMessage("native message while styling off",.3,.6,.9)
local retained=table.getn(visible)
assert(retained==2,"native off-mode line must remain visible")
FieldKitDB.chatWidth=620;FieldKitDB.chatHeight=275
FieldKitDB.chatFontSize=17;FieldKitDB.chatFontFace=4
FieldKitDB.chatHistoryLines=425
FieldKitDB.chatStyle=true;FieldKit.SyncChat()
assert(ChatFrame1:GetWidth()==620 and ChatFrame1:GetHeight()==275,
 "chat width and height must remain adjustable on re-enable")
assert(ChatFrame1.fontSize==17 and string.find(ChatFrame1.fontPath,"MORPHEUS",1,true),
 "chat font size and family must apply on re-enable")
assert(ChatFrame1.maxLines==425,"chat history size must remain adjustable")
assert(table.getn(visible)==retained,"re-enable lost an off-mode message")
assert(visible[1].text=="survive layout" and visible[2].text=="native message while styling off",
 "re-enable reordered or erased chat lines")
-- The same four controls must also work on subsequent changes, with
-- messages still visible even though native setters clear their display.
FieldKitDB.chatWidth=590;FieldKitDB.chatHeight=295
FieldKitDB.chatFontSize=16;FieldKitDB.chatFontFace=3
FieldKit.ApplyChatStyle()
assert(ChatFrame1:GetWidth()==590 and ChatFrame1:GetHeight()==295)
assert(ChatFrame1.fontSize==16 and string.find(ChatFrame1.fontPath,"ARIALN",1,true))
assert(table.getn(visible)==retained and visible[2].text=="native message while styling off")
ChatFrame1:AddMessage("still receiving after reenable",.4,.7,.9)
assert(table.getn(visible)==retained+1 and visible[retained+1].text=="still receiving after reenable")
-- Reset the independent test scenario without clearing any real client data.
FieldKitDB.chatStyle=false;FieldKit.SyncChat()
ChatFrame1:Clear()
FieldKitDB.chatStyle=true;FieldKit.SyncChat()
ChatFrame1:AddMessage("survive layout",.2,.4,.6)
assert(table.getn(visible)==1)
FieldKitDB.chatOverrideText=true;FieldKitDB.chatTextColor=3
ChatFrame1:AddMessage("|cffff0000Color sample|r",.1,.1,.1)
assert(table.getn(visible)==2 and visible[2].text=="Color sample")
assert(visible[2].r==1 and visible[2].g==.82 and visible[2].b==.49)
FieldKitDB.chatOverrideText=false
-- Simulate an older native line not observed by FieldKit.
table.insert(visible,1,{text="legacy not captured",r=.3,g=.3,b=.3})
-- Existing native lines that predate capture must never be cleared for recolor.
local beforeUnsafe=table.getn(visible)
assert(FieldKit.RecolorDisplayedChat()==false)
assert(table.getn(visible)==beforeUnsafe)
-- An optional newer-client read API allows full lossless reconstruction.
-- The legacy client without it uses the conservative no-op above.
ChatFrame1.GetMessageInfo=function(self,i)
 local m=visible[i]
 if m then return m.text,m.r,m.g,m.b,m.id end
end
FieldKitDB.chatTextColor=5
FieldKitDB.chatOverrideText=true
assert(FieldKit.RecolorDisplayedChat()==true)
assert(table.getn(visible)==beforeUnsafe,"native snapshot recolor duplicated or lost lines")
assert(visible[1].text=="legacy not captured")
assert(visible[1].r==.69 and visible[1].g==.85 and visible[1].b==1)
ChatFrame1.GetMessageInfo=nil
FieldKitDB.chatOverrideText=false
-- Controlled full-history case: simulate a native chat reset / fresh UI session.
FieldKitDB.chatStyle=false;FieldKit.SyncChat()
ChatFrame1:Clear()
FieldKit.ClearChatRenderHistory()
FieldKitDB.chatStyle=true;FieldKit.SyncChat()
ChatFrame1:AddMessage("historical A",.25,.5,.75)
ChatFrame1:AddMessage("|cffff0000historical B|r",.1,.2,.3)
assert(table.getn(visible)==2)
FieldKitDB.chatTextColor=4
FieldKitDB.chatOverrideText=true
assert(FieldKit.RecolorDisplayedChat()==true)
assert(table.getn(visible)==2 and visible[1].text=="historical A" and visible[2].text=="historical B")
assert(visible[1].r==.69 and visible[1].g==.93 and visible[2].b==.77)
FieldKitDB.chatOverrideText=false
assert(FieldKit.RecolorDisplayedChat()==true)
assert(table.getn(visible)==2 and visible[1].r==.25 and visible[1].g==.5)
assert(visible[2].text=="|cffff0000historical B|r" and visible[2].r==.1)
-- The actual settings palette setter must refresh safely recoverable visible
-- history, not just recolor messages arriving after a palette change.
local chatSchema={{title="Interface",items={}}}
FieldKit_AddSettingsSections(chatSchema)
local palette
for _,item in ipairs(chatSchema[1].items) do
 if item.label=="Chat text color" then palette=item end
end
assert(palette and type(palette.set)=="function")
palette.set(2)
assert(FieldKitDB.chatOverrideText==true)
assert(table.getn(visible)==2 and visible[1].text=="historical A"
 and visible[2].text=="historical B","palette change must preserve messages and order")
assert(visible[1].r==.95 and visible[2].g==.92 and visible[2].b==.83,
 "palette setter failed to recolor existing fully-tracked lines")
FieldKitDB.chatOverrideText=false
assert(FieldKit.RecolorDisplayedChat()==true)
-- Real client regression: reset can be called when the chat has no native
-- GetPoint anchor. SetPoint must never receive nil/partial argument lists.
local strictSetPoint=ChatFrame1.SetPoint
ChatFrame1.SetPoint=function(self,point,relative,relPoint,x,y)
 assert(type(point)=="string" and type(relPoint)=="string")
 assert(relative and type(x)=="number" and type(y)=="number")
 return strictSetPoint(self,point,relative,relPoint,x,y)
end
FieldKitDB.chatStyle=false;FieldKit.ApplyChatStyle()
ChatFrame1:ClearAllPoints()
FieldKitDB.chatStyle=true;FieldKit.ApplyChatStyle()
FieldKit.ResetChatPosition()
assert(ChatFrame1:AddMessage("after empty-anchor reset")=="forwarded")
ChatFrame1:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",50,70)
FieldKitDB.chatStyle=false;FieldKit.ApplyChatStyle()
FieldKitDB.chatStyle=true;FieldKit.ApplyChatStyle()
FieldKit.ResetChatPosition()
assert(ChatFrame1:AddMessage("after valid-anchor reset")=="forwarded")
ChatFrame1.SetPoint=strictSetPoint
-- The player can drag the real chat and preserve its position without replacing it.
FieldKitDB.chatStyle=true;FieldKitDB.chatMove=true;FieldKit.ApplyChatStyle()
assert(FieldKitChatMoveHandle and FieldKitChatMoveHandle:IsShown())
this=FieldKitChatMoveHandle;FieldKitChatMoveHandle:GetScript("OnDragStart")()
ChatFrame1.left=210;ChatFrame1.bottom=150
FieldKitChatMoveHandle:GetScript("OnDragStop")()
assert(FieldKitDB.chatAnchor and FieldKitDB.chatAnchor.x==210 and FieldKitDB.chatAnchor.y==150,"Chat anchor: "..tostring(FieldKitDB.chatAnchor and FieldKitDB.chatAnchor.x)..","..tostring(FieldKitDB.chatAnchor and FieldKitDB.chatAnchor.y))
FieldKitDB.chatMove=false;FieldKit.ApplyChatStyle()
assert(not FieldKitChatMoveHandle:IsShown())
FieldKitDB.chatBackgroundOpacity=45;FieldKitDB.chatBackgroundColor=3
FieldKitDB.chatFontFace=2;FieldKitDB.chatTextColor=3;FieldKit.ApplyChatStyle()
assert(ChatFrame1:GetWidth()==570 and FieldKitDB.chatBackgroundColor==3)
-- Safe mode must not rewrite the native message content or channel colors.
FieldKitDB.chatStyle=true;FieldKitDB.chatOverrideText=true;FieldKitDB.chatTextColor=3
FieldKit.SyncChat()
assert(ChatFrame1:AddMessage("|cffff0000Color sample|r",.1,.1,.1)=="forwarded")
assert(lastMessage.text=="Color sample" and lastMessage.r==1 and lastMessage.g==.82 and lastMessage.b==.49)
FieldKitDB.chatOverrideText=false
FieldKitDB.chatStyle=false;FieldKit.ApplyChatStyle()
-- Leave the native chat restored for the remaining security fixtures.
FieldKitDB.chatStyle=false;FieldKit.ApplyChatStyle()


for i=1,120 do ChatFrame1:AddMessage("test"..i..string.rep("x",1000)) end
assert(type(FieldKit.OpenChatCopy)=="function")
FieldKit.OpenChatCopy()
assert(FieldKitCopyLogFrame:IsShown())
local text=FieldKitCopyLogEdit:GetText()
assert(not string.find(text,"private before consent",1,true))
assert(string.len(text)<=51300)
local _,lines=string.gsub(text,"\n","\n");assert(lines==99)
SlashCmdList.FieldKitLOG("off")
assert(FieldKitCopyLogEdit:GetText()=="" and not FieldKitCopyLogFrame:IsShown())
assert(FieldKitChatCopyButton:IsShown(),"in-game chat copy action remains discoverable after opt-out")
ChatFrame1:AddMessage("after opt out")
SlashCmdList.FieldKitLOG("on");SlashCmdList.FieldKitLOG("")
assert(FieldKitCopyLogEdit:GetText()=="")
SlashCmdList.FieldKitLOG("off")
assert(forwarded>=127)
local d=FieldKitDB
FieldKitDB={known="bad",pos={broken="bad",nan={0/0,1}},collapsedWindows=true,cameraMax="bad",targetHealthMode=1/0,lowHealthPct=-10,talentToggles={bad=true}}
FieldKit.InitializeSettings({"crit"})
assert(type(FieldKitDB.known)=="table" and FieldKitDB.pos.broken==nil and FieldKitDB.pos.nan==nil)
assert(FieldKitDB.cameraMax==nil and FieldKitDB.targetHealthMode==1 and FieldKitDB.lowHealthPct==10)
assert(FieldKitDB.talentToggles==nil and AZS_TALENT_TOGGLES==sentinel)
FieldKitDB=d
