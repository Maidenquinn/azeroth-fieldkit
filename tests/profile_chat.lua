-- Integrated native chat regression across two complete FieldKit profiles.
fire(FieldKitFrame,"VARIABLES_LOADED")
ChatFrame1=CreateFrame("Frame","ChatFrame1",UIParent)
local visible={}
local original=function(self,text,r,g,b,id)
 table.insert(visible,{text=text,r=r,g=g,b=b,id=id})
 return "ok"
end
ChatFrame1.AddMessage=original
ChatFrame1.Clear=function() visible={} end
ChatFrame1.GetNumMessages=function() return table.getn(visible) end
ChatFrame1.GetFont=function(self) return self.fontPath or "Fonts\\FRIZQT__.TTF",self.fontSize or 12,"" end
ChatFrame1.GetMaxLines=function(self) return self.maxLines or 200 end
ChatFrame1.SetFont=function(self,path,size,flags)
 self.fontPath=path;self.fontSize=size;self.fontFlags=flags;self:Clear();return true
end
local width,height=ChatFrame1.SetWidth,ChatFrame1.SetHeight
ChatFrame1.SetWidth=function(self,n) width(self,n);self:Clear() end
ChatFrame1.SetHeight=function(self,n) height(self,n);self:Clear() end
ChatFrame1.SetMaxLines=function(self,n) self.maxLines=n;self:Clear() end
local d=FieldKitDB
d.chatStyle=true;d.chatCopy=false;d.chatFontFace=2;d.chatWidth=520
d.chatHeight=220;d.chatFontSize=14;d.chatBackgroundColor=3
FieldKit.SyncChat()
ChatFrame1:AddMessage("profile history A",.2,.6,.7)
assert(table.getn(visible)==1)
assert(FieldKitProfiles.Save(1))
d.chatFontFace=4;d.chatWidth=690;d.chatHeight=300;d.chatFontSize=19
d.chatBackgroundColor=5;d.chatStyle=false
assert(FieldKitProfiles.Save(2))
ChatFrame1:AddMessage("profile history B",.4,.7,.9)
assert(table.getn(visible)==2)
assert(FieldKitProfiles.Load(1))
assert(d.chatStyle and d.chatWidth==520 and d.chatHeight==220 and d.chatFontSize==14)
assert(d.chatFontFace==2 and d.chatBackgroundColor==3)
assert(ChatFrame1:GetWidth()==520 and ChatFrame1.fontSize==14)
assert(table.getn(visible)==2 and visible[1].text=="profile history A"
 and visible[2].text=="profile history B",
 "switch to slot 1 erased or duplicated native messages")
assert(FieldKitProfiles.Load(2))
assert(not d.chatStyle and d.chatWidth==690 and d.chatFontSize==19)
assert(table.getn(visible)==2,"slot 2 opt-out lost visible chat")
assert(ChatFrame1:AddMessage("after switching",.3,.5,.8)=="ok")
assert(table.getn(visible)==3)
assert(FieldKitProfiles.Load(1))
assert(table.getn(visible)==3 and visible[3].text=="after switching",
 "repeated native chat profile switching lost history")
assert(not d.chatCopy,"profile selection must not opt in to local copy unexpectedly")
