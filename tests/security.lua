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
ChatFrame1:AddMessage("private before consent")
SlashCmdList.FieldKitLOG("on")
assert(ChatFrame2.AddMessage==original)
assert(FieldKitChatCopyButton and FieldKitChatCopyButton:IsShown(),"copy shortcut must be next to main chat")
assert(ChatFrame1:AddMessage("opted in")=="forwarded")
assert(FieldKit.OpenChatCopy and type(FieldKit.OpenChatCopy)=="function")
-- Stage 1 must leave native text rendering APIs entirely untouched.
local nativeOps=0
local function unexpectedNativeMutation() nativeOps=nativeOps+1;error("native chat rendering mutated") end
ChatFrame1.SetTimeVisible=unexpectedNativeMutation
ChatFrame1.SetFading=unexpectedNativeMutation
ChatFrame1.SetFadeDuration=unexpectedNativeMutation
ChatFrame1.SetFont=unexpectedNativeMutation
ChatFrame1.SetMaxLines=unexpectedNativeMutation
local oldWidth,oldHeight=ChatFrame1:GetWidth(),ChatFrame1:GetHeight()
local oldSetWidth,oldSetHeight=ChatFrame1.SetWidth,ChatFrame1.SetHeight
ChatFrame1.SetWidth=unexpectedNativeMutation
ChatFrame1.SetHeight=unexpectedNativeMutation
FieldKitDB.chatFading=true
FieldKitDB.chatWidth=510;FieldKitDB.chatHeight=230;FieldKitDB.chatFontSize=15
FieldKitDB.chatFontFace=2;FieldKitDB.chatHistoryLines=400
FieldKitDB.chatStyle=true
FieldKit.ApplyChatStyle()
assert(nativeOps==0 and ChatFrame1:GetWidth()==oldWidth and ChatFrame1:GetHeight()==oldHeight)
assert(ChatFrame1:AddMessage("should stay visible")=="forwarded")
ChatFrame1.SetWidth=oldSetWidth;ChatFrame1.SetHeight=oldSetHeight
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
assert(ChatFrame1:GetWidth()==oldWidth and FieldKitDB.chatBackgroundColor==3)
-- Safe mode must not rewrite the native message content or channel colors.
FieldKitDB.chatStyle=true;FieldKitDB.chatOverrideText=true;FieldKitDB.chatTextColor=3
FieldKit.SyncChat()
assert(ChatFrame1:AddMessage("|cffff0000Color sample|r",.1,.1,.1)=="forwarded")
assert(lastMessage.text=="|cffff0000Color sample|r" and lastMessage.r==.1 and lastMessage.g==.1 and lastMessage.b==.1)
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
assert(forwarded==127)
local d=FieldKitDB
FieldKitDB={known="bad",pos={broken="bad",nan={0/0,1}},collapsedWindows=true,cameraMax="bad",targetHealthMode=1/0,lowHealthPct=-10,talentToggles={bad=true}}
FieldKit.InitializeSettings({"crit"})
assert(type(FieldKitDB.known)=="table" and FieldKitDB.pos.broken==nil and FieldKitDB.pos.nan==nil)
assert(FieldKitDB.cameraMax==nil and FieldKitDB.targetHealthMode==1 and FieldKitDB.lowHealthPct==10)
assert(FieldKitDB.talentToggles==nil and AZS_TALENT_TOGGLES==sentinel)
FieldKitDB=d
