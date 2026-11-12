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
-- Compact boosts only: keep "+12% crit" as-is, and rewrite short Equip prose
-- that only embeds a percentage into "+72% chance" instead of dropping it.
function L.IsStat(text)
 if type(text)~="string" or text=="" then return false end
 if string.find(text,"^[Ee]quip%s*:") or string.find(text,"^[Uu]se%s*:") then return false end
 if string.find(text,"^[ÉéEe]quip[ée]*s?%s*:") or string.find(text,"^[Uu]tiliser%s*:") then return false end
 if string.find(text,"^[Rr]equires%s") or string.find(text,"^[Nn][ée]cessite%s") then return false end
 if string.len(text)>48 then return false end
 if string.find(text,"[%+%-]%s*%d") then return true end
 if string.find(text,"^%d+%.?%d*%s*%%") then return true end
 return false
end
function L.CompactBonus(text)
 if type(text)~="string" or text=="" then return nil end
 if string.find(text,"^[Rr]equires%s") or string.find(text,"^[Nn][ée]cessite%s") then return nil end
 if L.IsStat(text) then return N.Text(text,120) end
 local _,_,pct=string.find(text,"(%d+%.?%d*)%%")
 if not pct or string.len(text)>72 then return nil end
 -- Lua 5.0 lower()/classes do not handle UTF-8 accents; use ASCII-safe fragments.
 local lower=string.lower(text)
 local tag=""
 if string.find(lower,"crit") then tag=" crit"
 elseif string.find(lower,"haste") or string.find(lower,"te de") then tag=" haste"
 elseif string.find(lower,"vie") or string.find(lower,"health") or string.find(lower,"hit point") then tag=" HP"
 elseif string.find(lower,"damage") or string.find(lower,"ts subis") or string.find(lower,"ts de") or string.find(lower,"ts.") then tag=" dmg"
 elseif string.find(lower,"recharge") or string.find(lower,"cooldown") then tag=" CD"
 elseif string.find(lower,"chance") or string.find(lower,"luck") then tag=" chance"
 elseif string.find(lower,"cible") or string.find(lower,"target") then tag=" cible"
 elseif string.find(lower,"experience") or string.find(lower,"rience") then tag=" XP"
 elseif string.find(lower,"gold") or string.find(lower,"l'or") or string.find(lower,"d'or") then tag=" gold"
 end
 local sign="+"
 if string.find(lower,"duit") or string.find(lower,"reduc") or string.find(lower,"decreas") or string.find(lower,"moins") then
  sign="-"
 end
 return sign..pct.."%"..tag
end
function L.RankColor(rank)
 if not rank or rank<2 then return .78,.78,.82 end
 if rank>=20 then return 1,.45,.12 end
 if rank>=10 then return 1,.75,.2 end
 if rank>=5 then return .35,.75,1 end
 return .45,1,.55
end
function L.ExpandStats(lines)
 local out={}
 for _,line in ipairs(lines or {}) do
  local plain=string.gsub(tostring(line or ""),"^%s+","");plain=string.gsub(plain,"%s+$","")
  plain=string.gsub(plain,"^[Ee]quip%s*:%s*","");plain=string.gsub(plain,"^[Uu]se%s*:%s*","")
  plain=string.gsub(plain,"^[ÉéEe]quip[ée]*s?%s*:%s*","");plain=string.gsub(plain,"^[Uu]tiliser%s*:%s*","")
  local at=1;local count=0
  while at<=string.len(plain) and count<16 do
   local finish=string.find(plain,"[,;\n]",at) or string.len(plain)+1
   local part=string.gsub(string.gsub(string.sub(plain,at,finish-1),"^%s+",""),"%s+$","")
   count=count+1;at=finish+1
   local compact=L.CompactBonus(part)
   if compact then table.insert(out,compact) end
  end
 end
 return out
end
function L.BonusText(lines)
 local parts=L.ExpandStats(lines)
 if table.getn(parts)==0 then return "",0 end
 return table.concat(parts,"\n"),table.getn(parts)
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
      if value then for _,part in ipairs(L.ExpandStats({value})) do table.insert(bonus,part) end
      elseif improvement then for _,part in ipairs(L.ExpandStats({improvement})) do table.insert(upgrades,part) end
      elseif method=="SetInventoryItem" and text~="" and L.Green(raw,left) then
       for _,part in ipairs(L.ExpandStats({text})) do table.insert(bonus,part) end
      end
     end
    end
   end
  end
 end
 tip:Hide();return bonus,title,rank,upgrades
end
function L.EnsureAssetIcons()
 if L.assetIcons then return end
 L.assetIcons={}
 for _,asset in pairs(FieldKitSpellAssets or {}) do
  if type(asset)=="table" and type(asset.name)=="string" and type(asset.icon)=="string" then
   L.assetIcons[L.Key(asset.name)]=asset.icon
  end
 end
 -- Native meter labels are often localized; keep exact French/English aliases.
 local alias={
  saccager="Interface\\Icons\\Ability_Warrior_Charge",
  rampage="Interface\\Icons\\Ability_Warrior_Charge",
  rafale="Interface\\Icons\\Ability_GhoulFrenzy",
  flurry="Interface\\Icons\\Ability_GhoulFrenzy",
  blessuresprofondes="Interface\\Icons\\Ability_BackStab",
  deepwounds="Interface\\Icons\\Ability_BackStab",
  -- French meter labels ↔ English combat-log / Spell.dbc icons (join hits & kills).
  execution="Interface\\Icons\\INV_Sword_48",
  ["exécution"]="Interface\\Icons\\INV_Sword_48",
  tourbillon="Interface\\Icons\\Ability_Whirlwind",
  whirlwind="Interface\\Icons\\Ability_Whirlwind",
  enchainement="Interface\\Icons\\Ability_Warrior_Cleave",
  ["enchaînement"]="Interface\\Icons\\Ability_Warrior_Cleave",
  cleave="Interface\\Icons\\Ability_Warrior_Cleave",
  sanguinaire="Interface\\Icons\\Spell_Nature_BloodLust",
  bloodthirst="Interface\\Icons\\Spell_Nature_BloodLust",
  heurtbouclier="Interface\\Icons\\INV_Shield_05",
  shieldslam="Interface\\Icons\\INV_Shield_05",
  coupdetonnerre="Interface\\Icons\\Spell_Nature_ThunderClap",
  thunderclap="Interface\\Icons\\Spell_Nature_ThunderClap",
  mele="Interface\\Icons\\INV_Sword_04",
  ["mêlée"]="Interface\\Icons\\INV_Sword_04",
  melee="Interface\\Icons\\INV_Sword_04",
 }
 for key,icon in pairs(alias) do L.assetIcons[L.Key(key)]=icon end
end
function L.Icon(name)
 if name=="Melee" or name=="Mêlée" then return "Interface\\Icons\\INV_Sword_04" end
 L.EnsureAssetIcons()
 local key=L.Key(name)
 return L.icons[key] or L.assetIcons[key]
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
-- Did the learned-spell packet change (keys, ranks)? Compared in place with the last one seen: no allocation.
L.sigKeys,L.sigRanks,L.sigCount={},{},0
function L.SpellsChanged()
 local list=type(AZS_SPELLS)=="table" and AZS_SPELLS or nil
 local count=list and math.min(32,table.getn(list)) or 0
 local changed=count~=L.sigCount
 for i=1,count do
  local s=list[i];local key,rank=type(s)=="table" and s.key,type(s)=="table" and s.rank
  if L.sigKeys[i]~=key or L.sigRanks[i]~=rank then L.sigKeys[i]=key;L.sigRanks[i]=rank;changed=true end
 end
 L.sigCount=count
 return changed
end
-- What the card shows, as one string: when a rescan finds the same text the card is not redrawn.
function L.ContentKey()
 local parts={};local n=0
 for i=1,table.getn(L.spells) do
  local e=L.spells[i];n=n+1
  parts[n]=tostring(e.key)..":"..tostring(e.rank)..":"..tostring(e.name)..":"..tostring(e.icon)..":"..table.concat(e.bonuses or {},"|")..":"..table.concat(e.upgrades or {},"|")
 end
 for _,slot in ipairs({2,13,14,11,12}) do
  local it=L.items[slot];n=n+1
  parts[n]=slot..":"..tostring(it and it.name)..":"..table.concat(it and it.bonuses or {},"|")
 end
 return table.concat(parts,";;")
end
-- Native events that can change what the scan reads. They only mark the scan as due.
L.eventFrame=CreateFrame("Frame")
for _,name in ipairs({"UNIT_INVENTORY_CHANGED","ACTIONBAR_SLOT_CHANGED","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB","PLAYER_ENTERING_WORLD"}) do L.eventFrame:RegisterEvent(name) end
L.eventFrame:SetScript("OnEvent",function()
 if event=="UNIT_INVENTORY_CHANGED" and arg1~="player" then return end
 L.dirty=true
end)
L.RESCAN_GAP=1.5   -- shortest delay between two scans caused by changes
L.IDLE_RESCAN=30   -- safety net: a full rescan at least this often, whatever happened (a missed event is repaired within it)
function L.Scan()
 -- Tooltip walks across the action bar are very expensive (spell book + up to 72 action slots + tooltips). Rescan only when
 -- something changed: first scan, run boundary, a different learned-spell packet, a native event (equipment, action bar, spells),
 -- or the slow safety net. Before, a fresh packet meant "scan every 1.5 s" for the whole run.
 local now=GetTime()
 local first=not L.scanned
 local changed=false
 if N.Fresh("AZSSPELLS") then changed=L.SpellsChanged() end
 if changed then L.dirty=true end
 local due=first or now>=L.scanAt
 if not due and L.dirty then
  if now>=(L.lastScan or 0)+L.RESCAN_GAP then due=true end
 end
 if not due then return false end
 local force=true
 L.scanAt=now+L.IDLE_RESCAN;L.lastScan=now;L.dirty=false
 L.scanned=true
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
 -- After a run boundary, Fresh("AZSSPELLS") is false until a new packet arrives.
 if N.Fresh("AZSSPELLS") and type(AZS_SPELLS)=="table" then
  for i=1,math.min(32,table.getn(AZS_SPELLS)) do
   local s=AZS_SPELLS[i];local rank=type(s)=="table" and FieldKit.Number(s.rank,nil,1,100000)
   if rank and type(s.key)=="string" then
    local asset=FieldKitSpellAssets[tonumber(s.spell)] or book[L.Key(s.key)]
    local e={key=s.key,name=asset and asset.name or N.Text(s.key),icon=asset and asset.icon,rank=string.format(FieldKit_L("Rank %d"),rank),rankValue=rank,bonuses={},upgrades={}}
    table.insert(L.spells,e)
    if e.icon then
     L.icons[L.Key(e.name)]=e.icon
     local key=L.TextureKey(e.icon)
     if byTexture[key]~=nil then byTexture[key]=false else byTexture[key]=e end
    end
   end
  end
 end
 -- Prefer the visible main bar (1-12) plus a short extra sweep; full 1-120 every
 -- second freezes the client when many action slots exist.
 if type(HasAction)=="function" and type(GetActionTexture)=="function" then
  local limit=force and 72 or 12
  for slot=1,limit do
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
 -- redraw the card only if the scan found something different
 local key=L.ContentKey()
 if key==L.contentKey then return false end
 L.contentKey=key
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
  row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.label:SetJustifyH("LEFT");row.label:SetJustifyV("TOP")
  row.value=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.value:SetJustifyH("RIGHT");row.value:SetJustifyV("TOP")
  row.bonus=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.bonus:SetTextColor(.3,1,.4)
  row.bonus:SetJustifyH("LEFT");row.bonus:SetJustifyV("TOP")
  if row.bonus.SetNonSpaceWrap then row.bonus:SetNonSpaceWrap(true) end
  row:RegisterForDrag("LeftButton");row:SetScript("OnDragStart",function() frame:GetScript("OnDragStart")() end);row:SetScript("OnDragStop",function() frame:GetScript("OnDragStop")() end)
  row:SetScript("OnEnter",function() L.Tip(this,this.entry) end);row:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
end
function L.Render(frame)
 local spells=FieldKitDB.loadoutTab==2;local rows=spells and frame.spellRows or frame.slots
 local n=spells and math.min(9,table.getn(L.spells)) or 5;local totalH=0
 for _,row in ipairs(spells and frame.slots or frame.spellRows) do row:Hide() end
 for i=1,math.max(1,n) do
  local row=rows[i];local entry=spells and L.spells[i] or L.items[({2,13,14,11,12})[i]]
  local source=entry and entry.bonuses or {}
  if spells and entry and table.getn(source)==0 then source=entry.upgrades or {} end
  local text,lines=L.BonusText(source);row.bonus:SetText(text);row.fieldkitBonusLines=lines
  local rowH=16+math.max(0,lines)*12;row.fieldkitRowHeight=rowH;totalH=totalH+rowH
  if spells then
   row.entry=entry;row.label:SetText(entry and entry.name or FieldKit_L("No spells yet"));row.value:SetText(entry and entry.rank or "")
   row.value:SetTextColor(L.RankColor(entry and entry.rankValue))
   L.Decorate(row,entry and entry.name);row.fieldkitSpellIcon:ClearAllPoints();row.fieldkitSpellIcon:SetPoint("TOPLEFT",row,"TOPLEFT",2,-1);row:SetValue(0)
  else
   local name,texture=L.readSlot(({2,13,14,11,12})[i])
   local slot=({"Amulet","Trinket 1","Trinket 2","Ring 1","Ring 2"})[i]
   -- Once equipped, the item name replaces the slot label; no need to repeat "Amulet".
   if name then row.label:SetText(name);row.value:SetText("");row.value:SetTextColor(.85,.85,.9)
   else FieldKit_Text(row.label,slot);row.value:SetText(FieldKit_L("empty"));row.value:SetTextColor(.65,.7,.7) end
   row.icon:SetTexture(texture)
   if texture then row.icon:Show() else row.icon:Hide() end
   if not name and not texture then row.bonus:SetText("");row.fieldkitBonusLines=0;row.fieldkitRowHeight=16;totalH=totalH-rowH+16 end
  end
 end
 frame.fieldkitLayoutRows=rows;frame.fieldkitDenseLoadout=false
 local collapsed=FieldKitDB.gearCollapsed
 FieldKitCardLayout.Rows(frame,40+math.max(totalH,16),math.max(1,n),"loadout",collapsed)
 local y=0
 for i=1,table.getn(rows) do
  local row=rows[i]
  if i<=math.max(1,n) and not collapsed then
   local rowH=row.fieldkitRowHeight or 16;local lines=row.fieldkitBonusLines or 0
   row:SetHeight(rowH-2)
   row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",18,0)
   row.label:SetJustifyH("LEFT");row.label:SetJustifyV("TOP")
   row.label:SetWidth(spells and frame:GetWidth()-96 or frame:GetWidth()-36);row.label:SetHeight(14)
   row.value:ClearAllPoints();row.value:SetPoint("TOPRIGHT",row,"TOPRIGHT",-2,0)
   row.value:SetJustifyH("RIGHT")
   row.value:SetWidth(spells and 68 or 48);row.value:SetHeight(14)
   row.bonus:ClearAllPoints();row.bonus:SetPoint("TOPLEFT",row,"TOPLEFT",18,-14)
   row.bonus:SetJustifyH("LEFT");row.bonus:SetJustifyV("TOP")
   row.bonus:SetHeight(math.max(12,lines*12));row.bonus:SetWidth(frame:GetWidth()-32)
   if row.GetParent then
    row:ClearAllPoints();row:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-28-y);row:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-28-y)
   end
   y=y+rowH;row:Show()
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
 if not N.Active() then L.scanAt=0;L.scanned=nil;L.items={};L.spells={};L.icons={};L.contentKey=nil;return end
 if L.serial~=N.serial then L.scanAt=0;L.scanned=nil;L.contentKey=nil;L.serial=N.serial end
 if L.Scan() and L.refresh then L.refresh() end
end
