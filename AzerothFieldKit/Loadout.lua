-- Read-only tooltip/grimoire enrichment. No dependency on AZSSpellMeter tables,
-- guessed item ranks, private memory, or fixed rank-to-bonus formula.
FieldKitLoadout={spells={},items={},icons={},scanAt=0}
local L=FieldKitLoadout
local N=FieldKitNative
function L.Plain(text)
 if type(text)~="string" then return nil end
 return N.Text(string.gsub(string.gsub(text,"|c%x%x%x%x%x%x%x%x",""),"|r",""),240)
end
function L.Key(text) return string.lower(string.gsub(text or "","[%s_%p]","")) end
function L.Tooltip(method,a,b)
 if not L.tip then L.tip=CreateFrame("GameTooltip","FieldKitLoadoutScan",UIParent,"GameTooltipTemplate") end
 local tip=L.tip;if not tip[method] then return {},nil,nil end
 tip:SetOwner(UIParent,"ANCHOR_NONE");tip:ClearLines()
 local ok=pcall(tip[method],tip,a,b)
 local out,title,rank={}
 if ok then
  for i=1,math.min(24,tip.NumLines and tip:NumLines() or 0) do
   local left=getglobal("FieldKitLoadoutScanTextLeft"..i)
   local right=getglobal("FieldKitLoadoutScanTextRight"..i)
   local raw=left and left:GetText();local text=L.Plain(raw)
   if i==1 then
    title=text;local r=right and L.Plain(right:GetText())
    if r and (string.find(string.lower(r),"rank",1,true) or string.find(string.lower(r),"rang",1,true)) then rank=r end
   elseif text and text~="" then
    local red,green,blue
    if left.GetTextColor then red,green,blue=left:GetTextColor() end
    local colored=type(green)=="number" and type(red)=="number" and type(blue)=="number" and green>.65 and red<.6 and blue<.6
    if raw and string.find(string.lower(raw),"|cff00ff00",1,true) then colored=true end
    if colored then table.insert(out,text) end
   end
  end
 end
 tip:Hide();return out,title,rank
end
function L.Icon(name)
 if name=="Melee" or name=="Mêlée" then return "Interface\\Icons\\INV_Sword_04" end
 return L.icons[L.Key(name)]
end
function L.ClearIcon(row)
 if row.fieldkitSpellIcon then row.fieldkitSpellIcon:Hide() end
 row.fieldkitIconInset=0;row.meterMode=nil
 row.label:ClearAllPoints();row.label:SetPoint("LEFT",row,"LEFT",3,0)
end
function L.Decorate(row,name)
 if not row.fieldkitSpellIcon then
  row.fieldkitSpellIcon=row:CreateTexture(nil,"ARTWORK");row.fieldkitSpellIcon:SetWidth(13);row.fieldkitSpellIcon:SetHeight(13)
  row.fieldkitSpellIcon:SetPoint("LEFT",row,"LEFT",2,0);row.fieldkitSpellIcon:SetTexCoord(.08,.92,.08,.92)
 end
 local icon=L.Icon(name);row.fieldkitIconInset=icon and 18 or 0
 if icon then row.fieldkitSpellIcon:SetTexture(icon);row.fieldkitSpellIcon:Show() else row.fieldkitSpellIcon:Hide() end
end
function L.Scan()
 local now=GetTime();if now<L.scanAt then return end;L.scanAt=now+1
 L.spells={};L.items={};L.icons={}
 local ranks={}
 if N.Fresh("AZSSPELLS") and type(AZS_SPELLS)=="table" then for i=1,math.min(32,table.getn(AZS_SPELLS)) do
  local s=AZS_SPELLS[i]
  if type(s)=="table" and type(s.key)=="string" then ranks[L.Key(s.key)]=FieldKit.Number(s.rank,nil,1,100000) end
 end end
 if type(GetSpellName)=="function" then
  for i=1,128 do
   local ok,name=pcall(GetSpellName,i,BOOKTYPE_SPELL or "spell")
   if not ok or type(name)~="string" or name=="" then break end
   local bonuses,title,rank=L.Tooltip("SetSpell",i,BOOKTYPE_SPELL or "spell")
   local texture
   if type(GetSpellTexture)=="function" then local success,value=pcall(GetSpellTexture,i,BOOKTYPE_SPELL or "spell");if success and type(value)=="string" then texture=value end end
   local nativeRank=ranks[L.Key(name)]
   if nativeRank then rank=string.format(FieldKit_L("Rank %d"),nativeRank) end
   local entry={name=L.Plain(name),icon=texture,rank=rank,bonuses=bonuses,index=i}
   table.insert(L.spells,entry);if texture then L.icons[L.Key(name)]=texture end
  end
 end
 if table.getn(L.spells)==0 and N.Fresh("AZSSPELLS") and type(AZS_SPELLS)=="table" then
  for i=1,math.min(32,table.getn(AZS_SPELLS)) do
   local s=AZS_SPELLS[i]
   if type(s)=="table" and type(s.key)=="string" then
    local rank=FieldKit.Number(s.rank,nil,1,100000)
    table.insert(L.spells,{name=N.Text(s.key),rank=rank and string.format(FieldKit_L("Rank %d"),rank),bonuses={}})
   end
  end
 end
 -- Read action headers as an additional native icon source (proc/item abilities
 -- need not appear in the spellbook). Never activate an action.
 if type(HasAction)=="function" and type(GetActionTexture)=="function" then
  for i=1,120 do
   local ok,has=pcall(HasAction,i)
   if ok and has then
    local _,name=L.Tooltip("SetAction",i)
    local success,texture=pcall(GetActionTexture,i)
    if name and success and type(texture)=="string" then L.icons[L.Key(name)]=texture end
   end
  end
 end
 for _,slot in ipairs({2,13,14,11,12}) do
  local bonuses,name,rank=L.Tooltip("SetInventoryItem","player",slot)
  L.items[slot]={name=name,bonuses=bonuses,rank=rank}
 end
end
function L.Tip(owner,entry)
 if not entry then return end
 GameTooltip:SetOwner(owner,"ANCHOR_LEFT");GameTooltip:SetText(entry.name or "?")
 if entry.rank then GameTooltip:AddLine(entry.rank,.8,.8,.8) end
 for _,line in ipairs(entry.bonuses) do GameTooltip:AddLine(line,.3,1,.4,true) end
 if table.getn(entry.bonuses)==0 then GameTooltip:AddLine(FieldKit_L("Bonus details not provided"),.65,.7,.7,true) end
 GameTooltip:Show()
end
function L.Create(create,move)
 local f=create("FieldKitSpellsFrame","Spells",9);L.frame=f
 f:SetWidth(280);move(f,UIParent:GetWidth()/2-450,50,true)
 for _,row in ipairs(f.rows) do
  row.bonus=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.bonus:SetPoint("TOPLEFT",row,"TOPLEFT",18,-15);row.bonus:SetHeight(12);row.bonus:SetTextColor(.3,1,.4)
  row:SetScript("OnEnter",function() L.Tip(this,this.entry) end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
end
function L.Update()
 if not FieldKitDB or not L.frame then return end
 if not N.Active() then L.frame:Hide();L.scanAt=0;L.items={};L.spells={};L.icons={};return end
 if L.serial~=N.serial then L.scanAt=0;L.serial=N.serial end
 L.Scan()
 local f=L.frame
 if not FieldKitDB.spellsFrame then f:Hide();return end
 local n=math.min(9,table.getn(L.spells));if n==0 then f:Hide();return end;f.mashVisibleRows=n
 FieldKitCardLayout.Rows(f,28+32*math.max(n,1),math.max(n,1),"spells",f.mashCollapsed)
 for i=1,9 do
  local row=f.rows[i];local entry=L.spells[i];row.entry=entry
  if entry and not f.mashCollapsed then
   L.Decorate(row,entry.name);row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",18,0)
   row.label:SetWidth(f:GetWidth()-100);row.label:SetHeight(14);row.label:SetText(entry.name)
   row.value:ClearAllPoints();row.value:SetPoint("TOPRIGHT",row,"TOPRIGHT",-2,0);row.value:SetWidth(68);row.value:SetText(entry.rank or "?")
   row.bonus:SetWidth(f:GetWidth()-32);row.bonus:SetText(table.concat(entry.bonuses," · "));row:SetValue(0);row:Show()
  else row:Hide() end
 end
 f.total:SetText(n.." / "..table.getn(L.spells));if f.mashCollapsed then f.total:Hide() else f.total:Show() end
 f:Show()
end
