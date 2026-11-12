-- The new API covers level-up/jewelry screens, not every native modal.
-- Register only named FieldKit HUD frames, only while explicitly opted in/shown.
-- During choosing, all other FieldKit HUD yields (alpha/mouse) so cards stay on top.
FieldKitScreenLayers={registered={},choiceMasked={},choiceOn=false}
local S=FieldKitScreenLayers

local CHOICE_EXTRA={"FieldKitReferenceCanvas","FieldKitThemeBack","FieldKitThemeSummaryDamage","FieldKitThemeSummaryLairs","FieldKitThemeSummaryAccessories","FieldKitThemeSummaryStats","FieldKitThemeSummaryEffects","FieldKitThemeIdentity","FieldKitThemeVitality","FieldKitThemeExperience","FieldKitThemeCounters","FieldKitThemeSchedule","FieldKitThemeUtility","FieldKitThemeMicro","FieldKitThemeTargetFrame","FieldKitBossFrame1Compact","FieldKitBossFrame2Compact","FieldKitBossFrame3Compact","FieldKitBossFrame4Compact","FieldKitThemeDock","FieldKitThemeHeader","FieldKitThemeNavigation","FieldKitThemeTooltip","FieldKitThemeMap","FieldKitBossTimelineFrame","FieldKitLeftStack","FieldKitRightStack",
 "FieldKitBossFrame1","FieldKitBossFrame2","FieldKitBossFrame3","FieldKitBossFrame4",
 "FieldKitPlayerBar","FieldKitPlayerBuffs","FieldKitLegacyCritFrame","FieldKitCombatText",
 "FieldKitCompactBar","FieldKitMinimapButton","FieldKitPartyDetailsFrame",
 "FieldKitMeterExtra_damage","FieldKitMeterExtra_healing","FieldKitMeterExtra_boss",
 "FieldKitMeterExtra_taken","FieldKitMeterExtra_party","FieldKitMeterExtra_kills"}

local function ChoiceNames()
 local names={}
 if FieldKitCardLayout and FieldKitCardLayout.names then
  for i=1,table.getn(FieldKitCardLayout.names) do table.insert(names,FieldKitCardLayout.names[i]) end
 end
 for i=1,table.getn(CHOICE_EXTRA) do table.insert(names,CHOICE_EXTRA[i]) end
 return names
end

local function RestoreChoice(frame)
 local record=S.choiceMasked[frame]
 if not record then return end
 if record.alpha~=nil then pcall(frame.SetAlpha,frame,record.alpha) end
 if record.mouse~=nil and frame.EnableMouse then pcall(frame.EnableMouse,frame,record.mouse) end
 S.choiceMasked[frame]=nil
end

local function MaskChoice(frame,name)
 if not frame or not frame.SetAlpha or not frame.GetAlpha then return end
 -- Explicit "keep over cards" opt-in stays visible and clickable.
 if name and FieldKitDB and FieldKitDB.onTopWindows and FieldKitDB.onTopWindows[name] then return end
 if S.choiceMasked[frame] then
  pcall(frame.SetAlpha,frame,0)
  if frame.EnableMouse then pcall(frame.EnableMouse,frame,false) end
  return
 end
 local ok,alpha=pcall(frame.GetAlpha,frame)
 if not ok or type(alpha)~="number" then return end
 local record={alpha=alpha}
 if frame.IsMouseEnabled and frame.EnableMouse then
  local success,mouse=pcall(frame.IsMouseEnabled,frame)
  if success then record.mouse=mouse and true or false end
 end
 S.choiceMasked[frame]=record
 pcall(frame.SetAlpha,frame,0)
 if frame.EnableMouse then pcall(frame.EnableMouse,frame,false) end
end

function S.ClearChoice()
 local list={}
 for frame,_ in pairs(S.choiceMasked) do table.insert(list,frame) end
 for i=1,table.getn(list) do RestoreChoice(list[i]) end
 S.choiceOn=false
end

function S.ApplyChoice()
 local choosing=FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen()
 if choosing then
  S.choiceOn=true
  local names=ChoiceNames()
  for i=1,table.getn(names) do MaskChoice(getglobal(names[i]),names[i]) end
 else
  if S.choiceOn then S.ClearChoice() end
 end
end

function S.Update()
 if not FieldKitDB then return end
 S.ApplyChoice()
 local names={}
 for _,name in ipairs(FieldKitCardLayout.names) do table.insert(names,name) end
 table.insert(names,"FieldKitPartyDetailsFrame")
 for _,name in ipairs(names) do
  local frame=getglobal(name)
  local enabled=FieldKitDB.onTopWindows[name] and frame and frame:IsShown() and FieldKitNative.Active()
  if name=="FieldKitPartyDetailsFrame" then enabled=enabled and FieldKitPartyDetails.pinned end
  -- Never force a frame over native level-up/jewelry cards unless the user opted in.
  if FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen() and not FieldKitDB.onTopWindows[name] then enabled=false end
  if enabled and not S.registered[name] then
   if FieldKit.SetFrameOnTop(name,true) then S.registered[name]=true end
  elseif not enabled and S.registered[name] then
   if FieldKit.SetFrameOnTop(name,false) then S.registered[name]=nil end
  end
 end
end
