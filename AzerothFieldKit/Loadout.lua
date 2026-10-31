-- Independent read-only native tooltip adapter. Action tooltips contain the
-- run-specific bonuses; spellbook entries are used only as additional icon hints.
-- Render equipment and learned spells as tabs in the existing Accessories card.
FieldKitLoadout={spells={},items={},icons={},scanAt=0}
local L=FieldKitLoadout
local N=FieldKitNative
function L.Plain(text,limit)
 if type(text)~="string" then return nil end
 return N.Text(string.gsub(string.gsub(text,"|c%x%x%x%x%x%x%x%x",""),"|r",""),limit or 240)
end
function L.Key(text) return string.lower(string.gsub(text or "","[%s_%p]","")) end
function L.TextureKey(text)
 return type(text)=="string" and string.lower(string.gsub(text,"^.*[\\/]","")) or nil
end
function L.Green(raw,region)
 local r,g,b
 if region.GetTextColor then r,g,b=region:GetTextColor() end
 if type(r)=="number" and type(g)=="number" and type(b)=="number" and g>.65 and r<.6 and b<.6 then return true end
 local _,_,hex=string.find(raw,"|c(%x%x%x%x%x%x%x%x)")
 if hex then return tonumber(string.sub(hex,5,6),16)>170 and tonumber(string.sub(hex,3,4),16)<150 and tonumber(string.sub(hex,7,8),16)<150 end
 return false
end
function L.Tooltip(method,a,b)
 if not L.tip then L.tip=CreateFrame("GameTooltip","FieldKitLoadoutScan",UIParent,"GameTooltipTemplate") end
 local tip=L.tip;if not tip[method] then return {},nil,nil,{} end
 tip:SetOwner(UIParent,"ANCHOR_NONE");tip:ClearLines()
 local ok=pcall(tip[method],tip,a,b)
 local bonus,upgrades,title,rank={},{},nil,nil
 if ok then
  for i=1,math.min(24,tip.NumLines and tip:NumLines() or 0) do
   local left=getglobal("FieldKitLoadoutScanTextLeft"..i);local raw=left and left:GetText()
   if type(raw)=="string" then
    if i==1 then title=L.Plain(raw)
    else
     -- Split embedded newlines before looking for labels. The client can put
     -- description, improvements and green bonuses in a single font region.
     local plain=string.gsub(string.gsub(string.sub(raw,1,4096),"|c%x%x%x%x%x%x%x%x",""),"|r","");local at=1;local count=0
     while at<=string.len(plain) and count<32 do
      local finish=string.find(plain,"\n",at, true) or string.len(plain)+1
      local text=string.gsub(string.sub(plain,at,finish-1),"^%s+","");count=count+1;at=finish+1
      local _,_,value=string.find(text,"^Your bonuses%s*:%s*(.+)$")
      if not value then _,_,value=string.find(text,"^Vos bonus%s*:%s*(.+)$") end
      local _,_,improvement=string.find(text,"^Upgrades%s*:%s*(.+)$")
      if not improvement then _,_,improvement=string.find(text,"^Improvements%s*:%s*(.+)$") end
      if not improvement then _,_,improvement=string.find(text,"^Améliorations%s*:%s*(.+)$") end
      if value then table.insert(bonus,N.Text(value,240))
      elseif improvement then table.insert(upgrades,N.Text(improvement,240))
      elseif method=="SetInventoryItem" and text~="" and L.Green(raw,left) then table.insert(bonus,N.Text(text,240)) end
     end
    end
   end
  end
 end
 tip:Hide();return bonus,title,rank,upgrades
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
 local now=GetTime();if now<L.scanAt then return false end;L.scanAt=now+1
 L.spells={};L.items={};L.icons={}
 local book={}
 if type(GetSpellName)=="function" and type(GetSpellTexture)=="function" then
  for i=1,128 do
   local ok,name=pcall(GetSpellName,i,BOOKTYPE_SPELL or "spell");if not ok or type(name)~="string" or name=="" then break end
   local success,texture=pcall(GetSpellTexture,i,BOOKTYPE_SPELL or "spell")
   if success and type(texture)=="string" then book[L.Key(name)]={name=L.Plain(name),icon=texture};L.icons[L.Key(name)]=texture end
  end
 end
 -- Only the native learned list defines rows and rank. No unlearned grimoire
 -- abilities, racial ordering assumptions, or fabricated rank-one entries.
 local byTexture={}
 if N.Fresh("AZSSPELLS") and type(AZS_SPELLS)=="table" then
  for i=1,math.min(32,table.getn(AZS_SPELLS)) do
   local s=AZS_SPELLS[i];local rank=type(s)=="table" and FieldKit.Number(s.rank,nil,1,100000)
   if rank and type(s.key)=="string" then
    local asset=FieldKitSpellAssets[tonumber(s.spell)] or book[L.Key(s.key)]
    local e={key=s.key,name=asset and asset.name or N.Text(s.key),icon=asset and asset.icon,rank=string.format(FieldKit_L("Rank %d"),rank),bonuses={},upgrades={}}
    table.insert(L.spells,e)
    if e.icon then
     L.icons[L.Key(e.name)]=e.icon
     local key=L.TextureKey(e.icon)
     if byTexture[key]~=nil then byTexture[key]=false else byTexture[key]=e end
    end
   end
  end
 end
 if type(HasAction)=="function" and type(GetActionTexture)=="function" then
  for slot=1,120 do
   local ok,has=pcall(HasAction,slot)
   if ok and has then
    local success,texture=pcall(GetActionTexture,slot)
    if success and type(texture)=="string" then
     local bonus,name,_,upgrades=L.Tooltip("SetAction",slot)
     if name then L.icons[L.Key(name)]=texture end
     local entry=byTexture[L.TextureKey(texture)]
     -- An icon shared by different native abilities cannot identify an action.
     if entry and not entry.action then
      entry.action=slot;entry.bonuses=bonus;entry.upgrades=upgrades;entry.name=name or entry.name
     end
    end
   end
  end
 end
 for _,slot in ipairs({2,13,14,11,12}) do
  local bonuses,name=L.Tooltip("SetInventoryItem","player",slot)
  L.items[slot]={name=name,bonuses=bonuses}
 end
 return true
end
function L.Tip(owner,entry)
 if not entry then return end
 GameTooltip:SetOwner(owner,"ANCHOR_LEFT");GameTooltip:SetText(entry.name or "?")
 if entry.rank then GameTooltip:AddLine(entry.rank,.8,.8,.8) end
 for _,line in ipairs(entry.upgrades or {}) do GameTooltip:AddLine(line,1,1,1,true) end
 for _,line in ipairs(entry.bonuses) do GameTooltip:AddLine(line,.3,1,.4,true) end
 if table.getn(entry.bonuses)==0 and table.getn(entry.upgrades or {})==0 then GameTooltip:AddLine(FieldKit_L("Bonus details not provided"),.65,.7,.7,true) end
 GameTooltip:Show()
end
function L.Attach(frame,readSlot,refresh)
 L.frame=frame;L.readSlot=readSlot;L.refresh=refresh;frame.spellRows={};frame.fieldkitHeaderHeight=12
 frame.loadoutTabs={}
 for i=1,2 do
  local index=i
  frame.loadoutTabs[i]=FieldKitTheme.Button(frame,nil,i==1 and "Accessories" or "Spells",6,5,100,22,function() FieldKitDB.loadoutTab=index;refresh() end)
 end
 for i=1,9 do
  local row=CreateFrame("StatusBar",nil,frame);frame.spellRows[i]=row
  row:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");row:SetMinMaxValues(0,1);row:SetValue(0);row:EnableMouse(true)
  row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.value=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.value:SetJustifyH("RIGHT")
  row.bonus=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.bonus:SetTextColor(.3,1,.4)
  row:RegisterForDrag("LeftButton");row:SetScript("OnDragStart",function() frame:GetScript("OnDragStart")() end);row:SetScript("OnDragStop",function() frame:GetScript("OnDragStop")() end)
  row:SetScript("OnEnter",function() L.Tip(this,this.entry) end);row:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
end
function L.Render(frame)
 local spells=FieldKitDB.loadoutTab==2;local rows=spells and frame.spellRows or frame.slots
 local n=spells and math.min(9,table.getn(L.spells)) or 5;local dense=not spells
 for _,row in ipairs(spells and frame.slots or frame.spellRows) do row:Hide() end
 for i=1,math.max(1,n) do
  local row=rows[i];local entry=spells and L.spells[i] or L.items[({2,13,14,11,12})[i]]
  local text=entry and table.concat(entry.bonuses," · ") or ""
  if spells and entry and text=="" then text=table.concat(entry.upgrades," · ") end
  row.bonus:SetText(text);if text~="" then dense=false end
  if spells then
   row.entry=entry;row.label:SetText(entry and entry.name or FieldKit_L("Spell data not provided"));row.value:SetText(entry and entry.rank or "")
   L.Decorate(row,entry and entry.name);row.fieldkitSpellIcon:ClearAllPoints();row.fieldkitSpellIcon:SetPoint("TOPLEFT",row,"TOPLEFT",2,0);row:SetValue(0)
  else
   local name,texture=L.readSlot(({2,13,14,11,12})[i])
   FieldKit_Text(row.label,({"Amulet","Trinket 1","Trinket 2","Ring 1","Ring 2"})[i])
   row.value:SetText(name or FieldKit_L("empty"));row.icon:SetTexture(texture)
   if texture then row.icon:Show() else row.icon:Hide() end
   if not name and not texture then row.bonus:SetText("") end
  end
 end
 frame.fieldkitLayoutRows=rows;frame.fieldkitDenseLoadout=dense
 local collapsed=FieldKitDB.gearCollapsed
 FieldKitCardLayout.Rows(frame,40+(dense and 16 or 32)*math.max(1,n),math.max(1,n),"loadout",collapsed)
 for i=1,table.getn(rows) do
  local row=rows[i]
  if i<=math.max(1,n) and not collapsed then
   row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",18,0);row.label:SetWidth(spells and frame:GetWidth()-96 or 60);row.label:SetHeight(14)
   row.value:ClearAllPoints();row.value:SetPoint("TOPRIGHT",row,"TOPRIGHT",-2,0);row.value:SetWidth(spells and 68 or frame:GetWidth()-112);row.value:SetHeight(14)
   row.bonus:ClearAllPoints();row.bonus:SetPoint("TOPLEFT",row,"TOPLEFT",18,-15);row.bonus:SetHeight(12);row.bonus:SetWidth(frame:GetWidth()-32)
   row:Show()
  else row:Hide() end
 end
 for i,b in ipairs(frame.loadoutTabs) do
  b:SetWidth((frame:GetWidth()-34)/2);b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",6+(i-1)*(frame:GetWidth()-22)/2,-5)
  FieldKitTheme.State(b,i==(spells and 2 or 1));FieldKitTheme.Update(b);if collapsed then b:Hide() else b:Show() end
 end
 frame:Show()
end
function L.Update()
 if not FieldKitDB then return end
 if not N.Active() then L.scanAt=0;L.items={};L.spells={};L.icons={};return end
 if L.serial~=N.serial then L.scanAt=0;L.serial=N.serial end
 if L.Scan() and L.refresh then L.refresh() end
end
