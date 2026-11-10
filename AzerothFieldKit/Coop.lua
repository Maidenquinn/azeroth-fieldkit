-- Read native party units and AZSPARTY. Optional peer spell snapshots are
-- handled separately by PartySync, not inferred from HP or native top DPS.
-- No target/cast actions or health-loss damage estimates are used.
FieldKitCoop={generation=0,takenGeneration=0,frames={},stock={}}
local P=FieldKitCoop
local colors={WARRIOR={.78,.61,.43},ROGUE={1,.96,.41},MAGE={.41,.8,.94},PRIEST={1,1,1},
 PALADIN={.96,.55,.73},SHAMAN={.2,.45,1},HUNTER={.67,.83,.45},WARLOCK={.58,.51,.79},
 DRUID={1,.49,.04},DEATHKNIGHT={.77,.12,.23}}

-- A source list can be absent/empty in co-op while the native run total exists.
-- Keep its unexplained remainder explicit. Never attribute it to a monster or
-- infer damage from HP drops (which mix healing, shields and maximum-HP changes).
function P.Taken()
 P.TrackRun()
 local lines,total={},0
 local fresh=P.takenGeneration~=P.readyTakenGeneration or AZS_TAKEN~=P.readyTakenSource or AZS_TAKEN_UPDATED~=P.readyTakenStamp
 if fresh and type(AZS_TAKEN)=="table" then
  for i=1,math.min(512,table.getn(AZS_TAKEN)) do
   local source=AZS_TAKEN[i]
   if type(source)=="table" then
    local amount=FieldKit.Number(source.dmg or source[2],nil,0)
    if amount and amount>0 then
     local name=source.source or source[1]
     table.insert(lines,{source=type(name)=="string" and string.sub(name,1,160) or "?",dmg=amount})
     total=total+amount
    end
   end
  end
 end
 local native=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.taken,nil,0)
 if native and native>total then table.insert(lines,{source="Unattributed (native total)",dmg=native-total});total=native end
 table.sort(lines,function(a,b) return a.dmg>b.dmg end)
 return lines,total,native~=nil or table.getn(lines)>0
end

-- Invalidate the previous run's packet at a phase boundary or clock regression.
-- Packet receipt is observed without parsing or executing message payloads.
function P.TrackRun()
 local active=type(AZS_GetPhase)=="function" and AZS_GetPhase()
 local time=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.t,nil,0)
 if (not active) or not P.phase or (time and P.runTime and time+1<P.runTime) then
  P.readyGeneration=P.generation;P.readyStamp=AZS_PARTY_UPDATED;P.readySource=AZS_PARTY
  P.readyTakenGeneration=P.takenGeneration;P.readyTakenStamp=AZS_TAKEN_UPDATED;P.readyTakenSource=AZS_TAKEN
  P.party={};P.partyTotal=nil;P.partyDps=nil
 end
 P.phase=active;P.runTime=time
 return active
end

function P.Packet(prefix)
 if prefix=="AZSRUN" then P.TrackRun()
 elseif prefix=="AZSPARTY" then P.generation=P.generation+1 end
 if prefix=="AZSTAKEN" then P.takenGeneration=P.takenGeneration+1 end
end

function P.Roster()
 local names={}
 local selfName=type(UnitName)=="function" and UnitName("player")
 if selfName then names[selfName]=true end
 local count=0
 for i=1,4 do
  local unit="party"..i
  if UnitExists(unit) then
   count=count+1;local name=UnitName(unit);if name then names[name]=true end
  end
 end
 return names,count
end

function P.ReadParty()
 local names,count=P.Roster()
 local roster={}
 for i=1,4 do local name=UnitExists("party"..i) and UnitName("party"..i);table.insert(roster,name or "") end
 local signature=table.concat(roster,"\031")
 if P.rosterSignature and signature~=P.rosterSignature then
  -- A changed roster cannot inherit the previous roster's last meter packet.
  if P.lastReadGeneration==P.generation and P.lastReadStamp==AZS_PARTY_UPDATED and P.lastReadSource==AZS_PARTY then
   P.readyGeneration=P.generation;P.readyStamp=AZS_PARTY_UPDATED;P.readySource=AZS_PARTY
  end
  P.party={};P.partyTotal=nil;P.partyDps=nil
 end
 P.rosterSignature=signature
 if count==0 then P.party={};P.partyTotal=nil;P.partyDps=nil;return end
 if P.generation==P.readyGeneration and AZS_PARTY_UPDATED==P.readyStamp and AZS_PARTY==P.readySource then return end
 local lines=AZS_PARTY
 if type(AZS_GetPartyMeter)=="function" then
  local ok,value=pcall(AZS_GetPartyMeter)
  if ok then lines=value end
 end
 P.party={};P.partyTotal=nil;P.partyDps=nil
 P.lastReadGeneration=P.generation;P.lastReadStamp=AZS_PARTY_UPDATED;P.lastReadSource=AZS_PARTY
 if type(lines)~="table" then return end
 local seen={};local total,rate=0,0;local ratesKnown=true
 for i=1,math.min(32,table.getn(lines)) do
  local line=lines[i]
  if type(line)=="table" and type(line.name)=="string" and names[line.name] and not seen[line.name] then
   local damage=FieldKit.Number(line.dmg,nil,0);local dps=FieldKit.Number(line.dps,nil,0)
   if damage then
    local item={name=string.sub(line.name,1,160),dmg=damage,dps=dps,share=FieldKit.Number(line.share,nil,0,1)}
    if type(line.top)=="string" and line.top~="" then item.top=string.sub(line.top,1,160) end
    item.topdps=FieldKit.Number(line.topdps,nil,0)
    table.insert(P.party,item);seen[line.name]=true;total=total+damage
    if dps then rate=rate+dps else ratesKnown=false end
   end
  end
 end
 table.sort(P.party,function(a,b) return a.dmg>b.dmg end)
 if table.getn(P.party)>0 then P.partyTotal=total;P.partyDps=ratesKnown and rate or nil end
end

function P.MemberDamage(name)
 for i=1,table.getn(P.party or {}) do if P.party[i].name==name then return P.party[i] end end
end

-- Hide only a confirmed stock PartyMemberFrame while its replacement has valid
-- unit HP. Preserve/restore its OnShow hook and never unregister native events.
function P.Stock(index,hide)
 local frame=getglobal("PartyMemberFrame"..index)
 local state=P.stock[index]
 if hide and frame then
  if not state then
   state={frame=frame,original=frame:GetScript("OnShow"),wanted=frame:IsShown()};P.stock[index]=state
   state.hook=function()
    if state.original then state.original() end
    state.wanted=true
    if state.active then frame:Hide() end
   end
   frame:SetScript("OnShow",state.hook)
  end
  state.active=true;frame:Hide()
 elseif state then
  state.active=false
  if state.frame:GetScript("OnShow")==state.hook then state.frame:SetScript("OnShow",state.original) end
  if state.wanted and UnitExists("party"..index) then state.frame:Show() end
  P.stock[index]=nil
 end
end

function P.Create(createWindow,fitRows,makeMovable)
 P.fitRows=fitRows
 local meter=createWindow("FieldKitPartyMeterFrame","Group damage",5);P.meter=meter
 FieldKit.CreateMeterColumns(meter);makeMovable(meter,-UIParent:GetWidth()/2+590,-270,true);meter:Hide()
 for i=1,table.getn(meter.rows) do FieldKitPartyDetails.BindRow(meter.rows[i]) end
 meter:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L("Group damage"),1,.85,.55)
  GameTooltip:AddLine(FieldKit_L("The header counts received players versus the current roster. Missing players or DPS stay unknown. Peer spell breakdowns are not provided by this API."),.8,.8,.8,true)
  GameTooltip:Show()
 end)
 meter:SetScript("OnLeave",function() GameTooltip:Hide() end)
 for i=1,4 do P.CreateMember(i,createWindow,makeMovable) end
 P.TrackRun()
end

function P.CreateMember(index,createWindow,makeMovable)
 local frame=createWindow("FieldKitPartyCard"..index,"Teammate",4)
 frame:SetWidth(280);frame.unit="party"..index;P.frames[index]=frame
 makeMovable(frame,-UIParent:GetWidth()/2+550,UIParent:GetHeight()/2-220-(index-1)*112,true)
 frame:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L("Teammate"),1,.85,.55)
  GameTooltip:AddLine(FieldKit_L("Native party-unit health and resources. Damage and DPS require a fresh group-meter sample. Drag cards directly. Native teammate frames remain interactive unless explicitly hidden."),.8,.8,.8,true)
  GameTooltip:Show()
 end)
 frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame:Hide()
end

function P.Row(frame,index,label,text,fraction,color)
 local row=frame.rows[index]
 FieldKit_Text(row.label,label);row.value:SetText(text)
 row.label:ClearAllPoints();row.label:SetPoint("LEFT",row,"LEFT",3,0)
 row.label:SetWidth(frame:GetWidth()*.3);row.label:SetHeight(14)
 row.value:SetWidth(frame:GetWidth()*.6);row.value:SetJustifyH("RIGHT");row.value:SetHeight(14)
 row:SetValue(fraction or 0);row:SetStatusBarColor(color[1],color[2],color[3],.55);row:Show()
end

-- With a themed HUD the teammate cards are the group display: they are shown and the native round frames are replaced
-- (state saved, restored as soon as the theme or the group goes away). The saved preferences are not modified.
function P.Themed() local R=FieldKitReferenceHUD;return R and R.active and true or false end
function P.CardsOn() return FieldKitDB.partyCards or P.Themed() end
function P.ReplaceOn() return FieldKitDB.replacePartyFrames or P.Themed() end
-- Health colour from the real fraction; greyed when the unit is dead, a ghost or offline.
function P.HealthColor(fraction,muted)
 if muted then return {.45,.45,.45} end
 if fraction>.5 then return {.22,.72,.3} elseif fraction>.25 then return {.88,.7,.18} end
 return {.82,.2,.16}
end
-- Compact themed card (290 x 56, 44 without a resource bar). The generic window rows are NOT used here: their stack made the
-- card tall and, worse, a parent's SetFrameLevel does not re-level its children on this client, so rows left at the old level
-- stayed under the card's opaque material. Every child below gets an explicit level above the card.
local COMPACT_W,COMPACT_H,COMPACT_H_NO_RESOURCE=290,56,44
P.compactSize={COMPACT_W,COMPACT_H,COMPACT_H_NO_RESOURCE}
local CLASS_ICON={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},HUNTER={0,.25,.25,.5},
 SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},PALADIN={0,.25,.5,.75}}
local function MakeBar(frame)
 local bar=CreateFrame("StatusBar",nil,frame)
 bar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar");bar:SetMinMaxValues(0,1);bar:SetValue(0)
 bar.back=bar:CreateTexture(nil,"BACKGROUND");bar.back:SetAllPoints(bar);bar.back:SetTexture(0,0,0,.55)
 bar.text=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");bar.text:SetPoint("CENTER",bar,"CENTER",0,0)
 return bar
end
function P.Style(frame,themed)
 local R=FieldKitReferenceHUD
 local level=themed and R.canvas and (R.canvas:GetFrameLevel()+20) or nil
 local key=(themed and "t" or "n")..tostring(level)
 if frame.fieldkitPartyStyle==key then return end
 frame.fieldkitPartyStyle=key
 if not frame.fieldkitOriginalLevel then frame.fieldkitOriginalLevel=frame:GetFrameLevel() end
 local collapse=getglobal(frame:GetName().."Collapse")
 if themed then
  frame:SetFrameStrata("MEDIUM");frame:SetFrameLevel(level)
  if not frame.portraitBack then
   frame.portraitBack=frame:CreateTexture(nil,"ARTWORK");frame.portraitBack:SetTexture(FieldKitTheme.gold[1],FieldKitTheme.gold[2],FieldKitTheme.gold[3])
   frame.portraitInner=frame:CreateTexture(nil,"ARTWORK");frame.portraitInner:SetTexture(0,0,0,1)
   frame.portrait=frame:CreateTexture(nil,"OVERLAY");frame.portrait:SetTexCoord(.08,.92,.08,.92)
   frame.hpBar=MakeBar(frame);frame.mpBar=MakeBar(frame)
  end
  -- children do not follow the parent's level: set them explicitly
  frame.hpBar:SetFrameLevel(level+2);frame.mpBar:SetFrameLevel(level+2)
  if collapse then collapse:Hide() end
  for _,row in ipairs(frame.rows or {}) do row:Hide() end
  frame.total:ClearAllPoints();frame.total:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-8,-8)
  frame.title:ClearAllPoints();frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",58,-7)
 else
  frame:SetFrameStrata("LOW");frame:SetFrameLevel(frame.fieldkitOriginalLevel)
  frame.title:ClearAllPoints();frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",9,-7)
  frame.total:ClearAllPoints();frame.total:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-25,-7)
  if frame.portrait then frame.portrait:Hide();frame.portraitBack:Hide();frame.portraitInner:Hide();frame.hpBar:Hide();frame.mpBar:Hide() end
  if collapse then collapse:Show() end
 end
end
-- Real portrait, else the class icon, else nothing (never a made-up face).
function P.Portrait(frame,unit,token)
 local now=GetTime()
 if frame.portraitKey==token and now<(frame.portraitAt or 0) and frame.portrait:IsShown() then return end
 frame.portraitKey=token;frame.portraitAt=now+5
 frame.portrait:SetTexCoord(.08,.92,.08,.92)
 local ok=type(SetPortraitTexture)=="function" and pcall(SetPortraitTexture,frame.portrait,unit)
 if not ok then
  local c=CLASS_ICON[token or ""]
  if c then frame.portrait:SetTexture("Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes");frame.portrait:SetTexCoord(c[1],c[2],c[3],c[4]);ok=true end
 end
 if ok then frame.portrait:Show() else frame.portrait:Hide() end
end
-- Lays the compact card out and fills it. d holds only values the client reported (nil = unavailable).
function P.Compact(frame,d)
 local width=FieldKitCardLayout.Width(frame,COMPACT_W)
 local hasResource=d.mana~=nil and d.manaMax~=nil and d.manaMax>0 and not d.muted
 local height=hasResource and COMPACT_H or COMPACT_H_NO_RESOURCE
 frame:SetWidth(width);frame:SetHeight(height)
 for _,row in ipairs(frame.rows or {}) do row:Hide() end
 frame.portraitBack:ClearAllPoints();frame.portraitBack:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-6);frame.portraitBack:SetWidth(height-12);frame.portraitBack:SetHeight(height-12)
 frame.portraitInner:ClearAllPoints();frame.portraitInner:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-8);frame.portraitInner:SetWidth(height-16);frame.portraitInner:SetHeight(height-16)
 frame.portrait:ClearAllPoints();frame.portrait:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-8);frame.portrait:SetWidth(height-16);frame.portrait:SetHeight(height-16)
 frame.portraitBack:Show();frame.portraitInner:Show()
 if d.preview then frame.portrait:Hide() else P.Portrait(frame,frame.unit,d.token or d.name) end
 local left=height-12+6+6
 frame.title:SetText(d.name);frame.title:SetWidth(width-left-96);frame.title:SetHeight(14)
 frame.total:SetText(d.detail);frame.total:SetWidth(96);frame.total:SetHeight(14);frame.total:SetJustifyH("RIGHT")
 if frame.total.SetTextColor then frame.total:SetTextColor(d.color[1],d.color[2],d.color[3]) end
 local barWidth=width-left-8
 local bar=frame.hpBar;bar:ClearAllPoints();bar:SetPoint("TOPLEFT",frame,"TOPLEFT",left,-24);bar:SetWidth(barWidth);bar:SetHeight(14)
 if d.fraction then bar:SetValue(d.fraction);bar:SetStatusBarColor(d.barColor[1],d.barColor[2],d.barColor[3],.95);bar.fieldkitColor=d.barColor;bar:Show()
 else bar:SetValue(0);bar:Show() end
 bar.text:SetText(d.hpText);if bar.text.SetTextColor then bar.text:SetTextColor(1,1,1) end
 local res=frame.mpBar
 if hasResource then
  res:ClearAllPoints();res:SetPoint("TOPLEFT",frame,"TOPLEFT",left,-40);res:SetWidth(barWidth);res:SetHeight(9)
  res:SetValue(math.min(d.mana/d.manaMax,1));res:SetStatusBarColor(d.powerColor[1],d.powerColor[2],d.powerColor[3],.9);res.fieldkitColor=d.powerColor
  res.text:SetText(string.format("%.0f / %.0f",d.mana,d.manaMax));res:Show()
 else res:Hide() end
end

function P.UpdateMember(index,active)
 local frame=P.frames[index];if not frame then return end
 local exists=active and UnitExists(frame.unit)
 local preview=not exists and FieldKit.layoutEditing
 local themed=P.Themed()
 if not P.CardsOn() or (not exists and not preview) then frame:Hide();P.Stock(index,false);return end
 local hp=type(UnitHealth)=="function" and FieldKit.Number(UnitHealth(frame.unit),nil,0)
 local max=type(UnitHealthMax)=="function" and FieldKit.Number(UnitHealthMax(frame.unit),nil,0)
 local known=not preview and hp~=nil and max and max>0
 if not known and not preview then frame:Hide();P.Stock(index,false);return end
 P.Style(frame,themed)
 local name=preview and FieldKit_L("Teammate").." "..index.." ("..FieldKit_L("Preview")..")" or (UnitName(frame.unit) or "?")
 local class,token
 if not preview and type(UnitClass)=="function" then class,token=UnitClass(frame.unit) end
 local level=not preview and type(UnitLevel)=="function" and FieldKit.Number(UnitLevel(frame.unit),nil,1)
 local color=colors[token] or {.4,.8,.5}
 if not themed then
  frame:SetWidth(FieldKitCardLayout.Width(frame,280))
  frame.title:SetText((FieldKit.layoutEditing and not preview and index..". " or "")..name);frame.title:SetWidth(frame:GetWidth()*.55)
  -- Level and class are shown only when the client provides them.
  frame.total:SetText(preview and FieldKit_L("Preview") or ((level and (FieldKit_L("Lvl").." "..level.." ") or "")..(class or "?")));frame.total:SetWidth(frame:GetWidth()*.3);frame.total:SetJustifyH("RIGHT")
 end
 local connected
 if not preview and type(UnitIsConnected)=="function" then connected=UnitIsConnected(frame.unit) and true or false end
 -- Dead / ghost only when the client reports it (optional API, never inferred from missing data).
 local ghost=not preview and type(UnitIsGhost)=="function" and UnitIsGhost(frame.unit) and true or false
 local dead=not preview and ghost or (not preview and (type(UnitIsDeadOrGhost)=="function" and UnitIsDeadOrGhost(frame.unit) or (type(UnitIsDead)=="function" and UnitIsDead(frame.unit))) and true or false)
 local muted=dead or connected==false
 local fraction=known and math.min(hp/max,1) or 0
 local barColor=themed and P.HealthColor(fraction,muted) or color
 P.Row(frame,1,"Health",known and FieldKit_FormatHealth(hp,max,FieldKitDB.partyHealthMode) or FieldKit_L("Not provided"),dead and 0 or fraction,barColor)
 local mana=type(UnitMana)=="function" and FieldKit.Number(UnitMana(frame.unit),nil,0)
 local manaMax=type(UnitManaMax)=="function" and FieldKit.Number(UnitManaMax(frame.unit),nil,0)
 if preview then mana=nil;manaMax=nil end
 local power=not preview and type(UnitPowerType)=="function" and UnitPowerType(frame.unit)
 local resource=power==0 and "Mana" or (power==1 and "Rage" or (power==3 and "Energy" or "Resource"))
 local powerColor=muted and {.45,.45,.45} or (power==1 and {.9,.2,.15} or (power==3 and {.9,.8,.15} or {.2,.5,.9}))
 P.Row(frame,2,resource,mana and manaMax and manaMax>0 and string.format("%.0f / %.0f",mana,manaMax) or FieldKit_L("Not provided"),mana and manaMax and manaMax>0 and not dead and math.min(mana/manaMax,1) or 0,powerColor)

 if themed then
  local status=connected==false and "Offline" or (ghost and "Ghost" or (dead and "Dead" or (known and hp==0 and "0 HP" or nil)))
  local hpText
  if status then hpText=FieldKit_L(status) elseif known then hpText=FieldKit_FormatHealth(hp,max,3) else hpText="" end
  P.Compact(frame,{name=(FieldKit.layoutEditing and not preview and index..". " or "")..name,preview=preview,token=token,color=color,
   detail=preview and FieldKit_L("Preview") or ((level and (FieldKit_L("Lvl").." "..level.." ") or "")..(class or "?")),
   fraction=known and (dead and 0 or fraction) or nil,barColor=barColor,hpText=hpText,muted=muted,
   mana=mana,manaMax=manaMax,powerColor=powerColor})
  frame:Show();P.Stock(index,P.ReplaceOn() and known and true or false);return
 end
 local line=P.MemberDamage(name)
 P.Row(frame,3,"Damage / DPS",line and FieldKit_FormatMeterValues(line,2) or FieldKit_L("Waiting for group data"),0,color)
 local status=connected==false and "Offline" or (ghost and "Ghost" or (dead and "Dead" or (known and hp==0 and "0 HP" or (connected and "Online" or "Not provided"))))
 P.Row(frame,4,"Status",FieldKit_L(status),0,color)
 P.fitRows(frame,4);frame:Show();P.Stock(index,P.ReplaceOn() and known and true or false)
end

function P.UpdateMeter(active)
 local frame=P.meter;if not frame then return end
 local _,count=P.Roster()
 if not FieldKitDB.partyMeter or ((not active or count==0) and not FieldKit.layoutEditing) then frame:Hide();return end
 frame:SetWidth(FieldKitCardLayout.Width(frame,FieldKit.MeterWidth(FieldKitDB.meterValues)))
 frame.total:SetText(P.partyTotal and string.format("%.0f / %s dps",P.partyTotal,P.partyDps and string.format("%.0f",P.partyDps) or "?") or FieldKit_L("Not provided"))
 local lines=P.party or {};local n=math.min(5,table.getn(lines));local top=lines[1] and lines[1].dmg or 1
 frame.title:SetText(FieldKit_L("Group damage").." ("..n.."/"..(count+1)..")")
 for i=1,n do
  local row=frame.rows[i];row.fieldkitMember=lines[i].name;row.label:SetText(lines[i].name)
  FieldKit.UpdateMeterColumns(row,lines[i],FieldKitDB.meterValues,frame:GetWidth())
  row:SetValue(lines[i].dmg/math.max(top,1));row:SetStatusBarColor(.25,.5,.85,.55);row:Show()
 end
 if n==0 then
  local row=frame.rows[1];row.fieldkitMember=nil;row.label:SetText(FieldKit_L("Waiting for group data"));row.label:SetWidth(frame:GetWidth()-20)
  for i=1,3 do row.meterColumns[i]:Hide() end
  row.meterMode=nil;row.value:Hide();row:SetValue(0);row:Show();n=1
 end
 for i=n+1,table.getn(frame.rows) do frame.rows[i].fieldkitMember=nil end
 P.fitRows(frame,n);frame:Show()
end

function P.Update()
 local active=P.TrackRun()
 if active then P.ReadParty() else P.party={} end
 P.UpdateMeter(active)
 for i=1,4 do P.UpdateMember(i,active) end
 -- A card that appeared or disappeared frees / takes its place in the HUD engine at the next tick, not 0.2 s later.
 local sig="";for i=1,4 do sig=sig..(P.frames[i] and P.frames[i]:IsShown() and "1" or "0") end
 if sig~=P.shownSig then P.shownSig=sig;if FieldKitZoneThemes then FieldKitZoneThemes.deadline=nil end end
 FieldKitPartyDetails.Sync()
end

function P.Diagnostic()
 local _,count=P.Roster();local lines,total,known=P.Taken()
 local raw=type(AZS_TAKEN)=="table" and table.getn(AZS_TAKEN) or 0
 DEFAULT_CHAT_FRAME:AddMessage("FieldKit coop: partyUnits="..count.." partyRows="..table.getn(P.party or {}).." packets="..P.generation.." rawTakenSources="..raw.." nativeTaken="..tostring(type(AZS_RUN)=="table" and AZS_RUN.taken).." shownTaken="..(known and tostring(total) or "unknown"))
end
