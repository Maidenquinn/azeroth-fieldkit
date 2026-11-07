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
-- In-place chat RGB is immutable on classic ScrollingMessageFrame: switching
-- must explicitly replay fully observed history to recolor EXISTING lines.
d.chatStyle=true
d.chatOverrideText=true;d.chatTextColor=4
FieldKit.ApplyChatStyle();FieldKit.RecolorDisplayedChat()
assert(FieldKitProfiles.Save(1))
d.chatOverrideText=true;d.chatTextColor=3
assert(FieldKitProfiles.Save(2))
assert(FieldKitProfiles.Load(1))
assert(visible[1].r==.69 and visible[1].g==.93 and visible[1].b==.77,
 "profile 1 historical chat color not applied")
assert(FieldKitProfiles.Load(2))
assert(visible[1].r==1 and visible[1].g==.82 and visible[1].b==.49,
 "profile 2 historical chat color leaked from profile 1")
assert(table.getn(visible)==3 and visible[3].text=="after switching")
-- A reset returns to original native geometry and anchor, but keeps palette
-- and native messages intact. No save/export history is recreated here.
d.chatStyle=true;d.chatWidth=730;d.chatHeight=350
d.chatAnchor={x=340,y=280}
FieldKit.ApplyChatStyle()
assert(FieldKit.ResetChatLayout())
assert(d.chatAnchor==nil and d.chatWidth==280 and d.chatHeight==100)
assert(d.chatTextColor==3 and d.chatOverrideText==true)
assert(table.getn(visible)==3)


-- Zone compaction must preserve native messages even when setters clear them.
local countBefore=table.getn(visible)
assert(FieldKit.ResizeChatPreservingHistory(320,66))
assert(table.getn(visible)==countBefore and visible[countBefore].text=="after switching")
local info=ChatFrame1.GetMessageInfo
ChatFrame1.GetMessageInfo=nil
FieldKit.ClearChatRenderHistory()
local widthBefore=ChatFrame1:GetWidth()
assert(not FieldKit.ResizeChatPreservingHistory(321,67))
assert(ChatFrame1:GetWidth()==widthBefore and table.getn(visible)==countBefore)
ChatFrame1.GetMessageInfo=info

-- Font changes are destructive on this native model, just like resizing.
ChatFrame1.GetMessageInfo=function(self,i) local m=visible[i];return m.text,m.r,m.g,m.b,m.id end
assert(FieldKit.ThemeChatFont("Interface\\AddOns\\AzerothFieldKit\\media\\AzerothSans.ttf",12,""))
assert(table.getn(visible)==countBefore and visible[countBefore].text=="after switching")
local fontSetter=ChatFrame1.SetFont;local fontCalls=0
ChatFrame1.SetFont=function(self,...) fontCalls=fontCalls+1;return fontSetter(self,unpack(arg)) end
assert(FieldKit.ThemeChatFont("Interface\\AddOns\\AzerothFieldKit\\media\\AzerothSans.ttf",12,""))
assert(fontCalls==0,"Unchanged theme font must never call a destructive setter")
FieldKit.ClearChatRenderHistory();ChatFrame1.GetMessageInfo=nil
assert(not FieldKit.ThemeChatFont("Fonts\\FRIZQT__.TTF",14,""))
assert(fontCalls==0 and table.getn(visible)==countBefore,"Unknown chat history must remain intact")
