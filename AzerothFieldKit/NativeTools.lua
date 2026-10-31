-- Passive, bounded views over exposed native state. All modules are optional;
-- no casting, targeting, level spending, native HUD hiding or external process.
FieldKitNativeTools={frames={},recent={},warnings={},lastBoss={},rows=9}
local T=FieldKitNativeTools
local N=FieldKitNative
local function Count(value) local n=FieldKit.Number(value,nil,0,10000);return n and math.floor(n) end
function T.Create(create,fit,move)
 T.fit=fit
 local defs={{"FieldKitEffectsFrame","Effects",-430,-110},{"FieldKitReviveFrame","Revive",0,160},
  {"FieldKitEncounterFrame","Run reminders",430,-180}}
 for i,def in ipairs(defs) do
  local f=create(def[1],def[2],i==1 and T.rows or 3);T.frames[i]=f
  f:SetWidth(300);move(f,def[3],def[4],true);f:Hide()
 end
 for _,row in ipairs(T.frames[1].rows) do
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(14);row.icon:SetHeight(14)
  row.icon:SetPoint("LEFT",row,"LEFT",0,0)
  row:SetScript("OnEnter",function()
   if not this.nativeDetail then return end
   GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(this.nativeDetail,1,.85,.55)
   GameTooltip:AddLine(FieldKit_L("Native remaining time; grouped durations show the soonest expiration."),.8,.8,.8,true);GameTooltip:Show()
  end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 local warnings=CreateFrame("Frame","FieldKitNativeWarnings",UIParent);T.warningFrame=warnings
 warnings:SetWidth(440);warnings:SetHeight(108);move(warnings,0,240,true)
 FieldKitTheme.Surface(warnings,"card",true);warnings.rows={}
 for i=1,3 do
  local row=FieldKitTheme.Label(warnings,nil,12,8+(i-1)*32,416,30,14,FieldKitTheme.gold)
  table.insert(warnings.rows,row)
 end
 warnings:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L("Native warnings"),1,.85,.55)
  for _,data in ipairs(T.warnings) do GameTooltip:AddLine(data.text,.9,.9,.85,true) end
  GameTooltip:Show()
 end)
 warnings:SetScript("OnLeave",function() GameTooltip:Hide() end)
 warnings:Hide();N.Watch()
end
function T.ShowRows(frame,rows,total)
 if table.getn(rows)==0 and not FieldKit.layoutEditing then frame:Hide();return end
 if table.getn(rows)==0 then rows={{label=FieldKit_L("Preview"),value="?"}} end
 FieldKit_Text(frame.total,total or "")
 frame:SetWidth(FieldKitCardLayout.Width(frame,300))
 local count=math.min(table.getn(rows),table.getn(frame.rows))
 for i=1,count do
  local row,entry=frame.rows[i],rows[i]
  row.nativeDetail=entry.label;row.label:ClearAllPoints();row.value:ClearAllPoints()
  row.label:SetPoint("LEFT",row,"LEFT",entry.icon and 18 or 3,0)
  row.label:SetWidth(math.max(30,frame:GetWidth()-150));row.label:SetHeight(14)
  row.value:SetPoint("RIGHT",row,"RIGHT",-3,0);row.value:SetWidth(120);row.value:SetHeight(14);row.value:SetJustifyH("RIGHT")
  row.label:SetText(entry.label);row.value:SetText(entry.value or "?")
  row:SetValue(entry.fraction or 0);row:SetStatusBarColor(.25,.5,.65,.5)
  if row.icon then
   if entry.icon then row.icon:SetTexture(entry.icon);row.icon:Show() else row.icon:Hide() end
  end
  row:Show()
 end
 T.fit(frame,count);frame:Show()
end
function T.Effects()
 local frame=T.frames[1];if not FieldKitDB.effectsFrame then frame:Hide();return end
 local rows,available={},false
 local defs={{"effectTotems","AZS_GetTotems","AZSTOTEMS"},{"effectSummons","AZS_GetSummonGroups","AZSPETS"},{"effectTimers","AZS_GetTimers","AZSTIMERS"}}
 for _,def in ipairs(defs) do
  if FieldKitDB[def[1]] and N.Has(def[2]) then
   available=true
   local lines=N.Fresh(def[3]) and N.Read(def[2])
   if type(lines)=="table" then
    for i=1,math.min(64,table.getn(lines)) do
     local entry=lines[i]
     if type(entry)=="table" and type(entry.name)=="string" then
      local text,remaining= nil,FieldKit.Number(entry.remaining,nil,0)
      if def[1]=="effectTimers" then
       text=entry.ready==true and FieldKit_L("Ready") or N.Clock(remaining)
      else
       local count=Count(entry.count)
       if count and count>0 then
        local cap=Count(entry.cap)
        text=tostring(count)..(cap and " / "..cap or "").." · "..(remaining and N.Clock(remaining) or (def[1]=="effectSummons" and Count(entry.permanent)==count and FieldKit_L("Permanent") or "?"))
       end
      end
      if text then table.insert(rows,{label=N.Text(entry.name),value=text,icon=type(entry.icon)=="string" and N.Text(entry.icon,240) or nil}) end
     end
    end
   end
  end
 end
 if not available then rows={{label=FieldKit_L("Effects API unavailable"),value="?"}} end
 if table.getn(rows)>T.rows then
  local extra=table.getn(rows)-(T.rows-1)
  while table.getn(rows)>=T.rows do table.remove(rows) end
  table.insert(rows,{label=string.format(FieldKit_L("%d more effects (adjust filters)"),extra),value=""})
 end
 T.ShowRows(frame,rows)
end
function T.Revive()
 local frame=T.frames[2];if not FieldKitDB.reviveFrame then frame:Hide();return end
 local data=N.Fresh("AZSREVIVE") and N.Read("AZS_GetRevive")
 local rows={}
 if type(data)=="table" then
  if data.down==1 then
   local share=FieldKit.Number(data.share,nil,0,1)
   table.insert(rows,{label=FieldKit_L("You are down"),value=share and string.format("%.0f%%",share*100) or "?",fraction=share})
   if type(data.by)=="string" and data.by~="" then table.insert(rows,{label=FieldKit_L("Revived by"),value=N.Text(data.by,100)}) end
  elseif type(data.reviving)=="string" and data.reviving~="" then
   local share=FieldKit.Number(data.rshare,nil,0,1)
   table.insert(rows,{label=N.Text(data.reviving),value=share and string.format("%.0f%%",share*100) or "?",fraction=share})
  end
 end
 T.ShowRows(frame,rows)
end
function T.NextBoss()
 local lines=N.Read("AZS_GetUpcomingBosses");local chosen
 if type(lines)=="table" then
  for i=1,math.min(64,table.getn(lines)) do
   local boss=lines[i]
   if type(boss)=="table" and type(boss.name)=="string" then
    local left=FieldKit.Number(boss.left)
    if left and left>=0 and (not chosen or left<chosen.left) then chosen={name=N.Text(boss.name),left=left,key=tostring(boss.index or boss.name)} end
   end
  end
 end
 -- Native endless countdown, when present; never extrapolate a schedule.
 if not chosen and type(AZS_RUN)=="table" and type(AZS_RUN.nbn)=="string" and AZS_RUN.nbn~="" then
  local left=FieldKit.Number(AZS_RUN.nb,nil,0)
  if left then
   local stamp=FieldKit.Number(AZS_RUN_UPDATED)
   if N.Read("AZS_GetPhase")=="playing" and stamp then left=math.max(0,left-math.max(0,GetTime()-stamp)) end
   if not T.endless or T.endless.name~=AZS_RUN.nbn or left>T.endless.left+2 then T.endlessCycle=(T.endlessCycle or 0)+1 end
   T.endless={name=AZS_RUN.nbn,left=left}
   chosen={name=N.Text(AZS_RUN.nbn),left=left,key="endless:"..tostring(T.endlessCycle)}
  end
 end
 return chosen
end
function T.Reminders()
 local frame=T.frames[3];local rows={}
 local boss=(FieldKitDB.nextBossCard or FieldKitDB.nextBossAlert) and T.NextBoss()
 if FieldKitDB.nextBossCard and boss then table.insert(rows,{label=boss.name,value=N.Clock(boss.left)}) end
 if FieldKitDB.storedLevelsBadge then
  local count=Count(N.Read("AZS_GetStoredLevels"))
  if count and count>0 then table.insert(rows,{label=FieldKit_L("Stored level-ups"),value=tostring(count)}) end
 end
 if boss and FieldKitDB.nextBossAlert and N.Read("AZS_GetPhase")=="playing" and boss.left>0 and boss.left<=FieldKitDB.bossWarningLead then
  local key=tostring(N.serial)..":"..boss.key
  if not T.lastBoss[key] then
   T.lastBoss[key]=true
   T.bossKeys=T.bossKeys or {};table.insert(T.bossKeys,key)
   if table.getn(T.bossKeys)>128 then T.lastBoss[table.remove(T.bossKeys,1)]=nil end
   T.Push(string.format(FieldKit_L("%s arrives in %ds"),boss.name,math.ceil(boss.left)),"next:"..key)
  end
 end
 if FieldKitDB.nextBossCard or FieldKitDB.storedLevelsBadge then T.ShowRows(frame,rows) else frame:Hide() end
end
-- At most three short warnings; native message ids/content are not executable.
function T.Push(text,key)
 local now=GetTime();text=N.Text(text,240)
 for _,seen in ipairs(T.recent) do if (seen.key==key or seen.text==text) and now-seen.at<5 then return end end
 table.insert(T.recent,{text=text,key=key,at=now});while table.getn(T.recent)>32 do table.remove(T.recent,1) end
 table.insert(T.warnings,{text=text,at=now,kind=string.find(key,"^next:") and "next" or "native"});while table.getn(T.warnings)>3 do table.remove(T.warnings,1) end
end
function T.Banner(banner)
 if not FieldKitDB or not FieldKitDB.nativeWarnings or not N.Active() or type(banner)~="table" or type(banner.text)~="string" then return end
 local allowed=(banner.boss==true and FieldKitDB.bossBannerWarnings) or (banner.kind=="mechanic" and FieldKitDB.mechanicWarnings)
 if allowed then T.Push(banner.text,"banner:"..tostring(banner.id)) end
end
function T.Subscription()
 if FieldKitDB.nativeWarnings and type(AZS_RegisterBannerHandler)=="function" then
  if not T.subscribed then local ok=pcall(AZS_RegisterBannerHandler,T.Banner);T.subscribed=ok end
 elseif T.subscribed and type(AZS_UnregisterBannerHandler)=="function" then
  local ok=pcall(AZS_UnregisterBannerHandler,T.Banner);if ok then T.subscribed=false end
 end
end
function T.Warnings()
 local frame=T.warningFrame
 local size=FieldKitDB.cardSizes.FieldKitNativeWarnings
 frame.fieldkitMinimumHeight=108;frame.fieldkitExpandedHeight=math.max(108,size and size.height or 108)
 frame:SetWidth(FieldKitCardLayout.Width(frame,440));frame:SetHeight(frame.fieldkitExpandedHeight)
 for _,row in ipairs(frame.rows) do row:SetWidth(frame:GetWidth()-24) end
 FieldKitTheme.Update(frame)
 if not FieldKitDB.nativeWarnings and not FieldKitDB.nextBossAlert then T.warnings={} end
 local now=GetTime()
 for i=table.getn(T.warnings),1,-1 do
  local item=T.warnings[i]
  if now-item.at>=4 or (item.kind=="native" and not FieldKitDB.nativeWarnings) or (item.kind=="next" and not FieldKitDB.nextBossAlert) then table.remove(T.warnings,i) end
 end
 if table.getn(T.warnings)==0 then
  if FieldKit.layoutEditing and (FieldKitDB.nativeWarnings or FieldKitDB.nextBossAlert) then
   FieldKit_Text(frame.rows[1],"Preview");frame.rows[1]:Show();frame.rows[1]:SetAlpha(1)
   frame.rows[2]:Hide();frame.rows[3]:Hide();frame:Show()
  else frame:Hide() end
  return
 end
 for i=1,3 do
  local data=T.warnings[i];local row=frame.rows[i]
  if data then row:SetText(data.text);row:SetAlpha(math.min(1,4-(now-data.at)));row:Show() else row:Hide() end
 end
 frame:Show()
end
function T.Update()
 if not T.frames[1] then return end
 N.Watch();T.Subscription()
 if T.serial~=N.serial then T.serial=N.serial;T.warnings={};T.recent={};T.lastBoss={};T.bossKeys={};T.endless=nil;T.endlessCycle=0 end
 if not N.Active() and not FieldKit.layoutEditing then
  for _,frame in ipairs(T.frames) do frame:Hide() end
  T.warnings={};T.warningFrame:Hide();return
 end
 T.Effects();T.Revive();T.Reminders();T.Warnings()
end

-- Local diagnostic, deliberately excluding chat, player names and account data.
function T.Diagnostic()
 local affixes=type(AZS_ZONE)=="table" and AZS_ZONE.affixes
 DEFAULT_CHAT_FRAME:AddMessage("FieldKit native: phase="..tostring(N.Read("AZS_GetPhase"))..
  " totems="..tostring(N.Has("AZS_GetTotems")).." summons="..tostring(N.Has("AZS_GetSummonGroups"))..
  " timers="..tostring(N.Has("AZS_GetTimers")).." revive="..tostring(N.Has("AZS_GetRevive"))..
  " overlay="..tostring(FieldKit.FrameOverlayAvailable()).." affixes="..N.Text(tostring(affixes),120))
end
