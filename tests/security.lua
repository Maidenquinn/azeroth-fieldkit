-- Assert the properties relevant to review, using actual production callbacks.
assert(FieldKitDB.chatCopy==false and FieldKitDB.compactBar==false)
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
local original=function(self,text,r,g,b,id) forwarded=forwarded+1;return "forwarded" end
ChatFrame1.AddMessage=original
ChatFrame2=CreateFrame("Frame","ChatFrame2",UIParent);ChatFrame2.AddMessage=original
FieldKit.SyncChat();assert(ChatFrame1.AddMessage==original)
ChatFrame1:AddMessage("private before consent")
SlashCmdList.FieldKitLOG("on")
assert(ChatFrame2.AddMessage==original)
assert(ChatFrame1:AddMessage("opted in")=="forwarded")
for i=1,120 do ChatFrame1:AddMessage("test"..i..string.rep("x",1000)) end
SlashCmdList.FieldKitLOG("")
local text=FieldKitCopyLogEdit:GetText()
assert(not string.find(text,"private before consent",1,true))
assert(string.len(text)<=51300)
local _,lines=string.gsub(text,"\n","\n");assert(lines==99)
SlashCmdList.FieldKitLOG("off")
assert(FieldKitCopyLogEdit:GetText()=="" and not FieldKitCopyLogFrame:IsShown())
ChatFrame1:AddMessage("after opt out")
SlashCmdList.FieldKitLOG("on");SlashCmdList.FieldKitLOG("")
assert(FieldKitCopyLogEdit:GetText()=="")
SlashCmdList.FieldKitLOG("off")
assert(forwarded==123)
local d=FieldKitDB
FieldKitDB={known="bad",pos={broken="bad",nan={0/0,1}},collapsedWindows=true,cameraMax="bad",targetHealthMode=1/0,lowHealthPct=-10,talentToggles={bad=true}}
FieldKit.InitializeSettings({"crit"})
assert(type(FieldKitDB.known)=="table" and FieldKitDB.pos.broken==nil and FieldKitDB.pos.nan==nil)
assert(FieldKitDB.cameraMax==nil and FieldKitDB.targetHealthMode==1 and FieldKitDB.lowHealthPct==10)
assert(FieldKitDB.talentToggles==nil and AZS_TALENT_TOGGLES==sentinel)
FieldKitDB=d
