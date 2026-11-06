-- All persisted data belongs to FieldKitDB only. No automatic MASHDB import:
-- old settings and game saves must not be overwritten by a renamed review build.
local defaults={lairNextBoss=true,windowsLocked=false,effectsFrame=false,effectTotems=true,effectSummons=true,effectTimers=true,reviveFrame=false,
 nextBossCard=false,nextBossAlert=false,bossTimeline=false,bossTimelineWidth=560,storedLevelsBadge=false,nativeWarnings=false,bossBannerWarnings=true,mechanicWarnings=true,partyBannerWarnings=true,
 highlightFlaggedLair=false,showNativeAffixes=true,hideUnknownMode=true,replacePartyFrames=false,partyDetailSync=false,partyCards=false,partyMeter=true,partyHealthMode=3,linkRightCards=true,linkLeftCards=true,runModeCard=true,moneyFrame=true,hidePlates=false,hideUnknown=false,targetHealth=true,playerBar=true,
 bossFrame=false,bossStyle="classic",statsFrame=true,playerBuffs=true,gearFrame=true,meterFrame=true,
 meterTabs=true,meterSpellTips=true,meterKeepTakenFrame=false,meterViewKey="damage",
 meterSortKey="dmg",meterSortAsc=false,meterHealDone=false,meterPartyOwner=nil,

 takenFrame=true,replaceTally=false,playerShield=true,chestPins=false,guardianPins=false,
 lairFrame=true,compactBar=false,lowHealth=true,lowHealthSound=false,
 lowHealthPct=30,targetHealthMode=1,playerHealthMode=1,bossHealthMode=1,chatCopy=false,chatStyle=false,chatFading=false,chatWidth=440,chatHeight=180,chatFontSize=12,chatHistoryLines=200,chatBackgroundOpacity=0,chatShowCopyButton=true,chatFontFace=1,chatBackgroundColor=1,chatTextColor=1,chatOverrideText=false,chatMove=false}

-- Single audited source of defaults for profile-scoped preferences.
-- State such as run counters, cached monster classifications, UI navigation
-- and chat contents is intentionally not part of this configuration contract.
FieldKit.ProfilePreferenceDefaults=defaults

-- Normalize persisted shapes before any frame can consume them. Only the new
-- addon's in-memory DB is repaired; serialization is the client's responsibility.
function FieldKit.InitializeSettings(defaultStats)
 if type(FieldKitDB)~="table" then FieldKitDB={} end
 local d=FieldKitDB
 for key,value in pairs(defaults) do
  if type(d[key])~=type(value) then d[key]=value end
 end
 d.spellsFrame=nil -- retired separate spell window; the existing card now has tabs
 d.loadoutTab=d.loadoutTab==2 and 2 or 1
 d.schema=1;d.language=d.language=="fr" and "fr" or "en"
 d.cardStyle=math.floor(FieldKit.Number(d.cardStyle,1,1,2))
 d.cardOpacity=math.floor(FieldKit.Number(d.cardOpacity,100,0,100))
 d.meterView=math.floor(FieldKit.Number(d.meterView,1,1,3))
 d.bossWarningLead=math.floor(FieldKit.Number(d.bossWarningLead,10,3,30))
 d.bossTimeline=d.bossTimeline==true
 d.bossTimelineWidth=math.floor(FieldKit.Number(d.bossTimelineWidth,560,360,780))
 if type(d.onTopWindows)~="table" then d.onTopWindows={} end
 for name,value in pairs(d.onTopWindows) do
  if (not FieldKitCardLayout.ValidName(name) and name~="FieldKitPartyDetailsFrame") or value~=true then d.onTopWindows[name]=nil end
 end
 d.meterValues=math.floor(FieldKit.Number(d.meterValues,3,1,3))
 for _,key in ipairs({"known","pos","collapsedWindows","frameAnchors","meterHiddenRows"}) do
  if type(d[key])~="table" then d[key]={} end
 end
 if type(d.meterSortKey)~="string" then d.meterSortKey="dmg" end
 if d.meterSortAsc~=true then d.meterSortAsc=false end
 if d.meterHealDone~=true then d.meterHealDone=false end
 if type(d.meterPartyOwner)~="string" then d.meterPartyOwner=nil end
 if type(d.cardSizes)~="table" then d.cardSizes={} end
 for name,size in pairs(d.cardSizes) do
  if not FieldKitCardLayout.ValidName(name) or type(size)~="table" then d.cardSizes[name]=nil
  else
   local width=FieldKit.Number(size.width,nil,220,800)
   local height=FieldKit.Number(size.height,nil,22,800)
   d.cardSizes[name]=(width or height) and {width=width,height=height} or nil
  end
 end
 local anchors=0
 for name,a in pairs(d.frameAnchors) do
  anchors=anchors+1
  if type(name)~="string" or string.len(name)>128 or anchors>256 or not FieldKitPositions.Valid(a) then
   d.frameAnchors[name]=nil
  end
 end
 local count=0
 for name,class in pairs(d.known) do
  count=count+1
  if type(name)~="string" or string.len(name)>160 or type(class)~="string" or count>2048 then d.known[name]=nil end
 end
 for name,p in pairs(d.pos) do
  if type(name)~="string" or type(p)~="table" or not FieldKit.Number(p[1]) or not FieldKit.Number(p[2]) then d.pos[name]=nil end
 end
 d.minimapAngle=FieldKit.Number(d.minimapAngle,150,-360,360)
 d.lowHealthPct=FieldKit.Number(d.lowHealthPct,30,10,70)
 d.chatWidth=math.floor(FieldKit.Number(d.chatWidth,440,280,800))
 d.chatHeight=math.floor(FieldKit.Number(d.chatHeight,180,100,450))
 d.chatFontSize=math.floor(FieldKit.Number(d.chatFontSize,12,10,20))
 d.chatHistoryLines=math.floor(FieldKit.Number(d.chatHistoryLines,200,100,500))
 d.chatBackgroundOpacity=math.floor(FieldKit.Number(d.chatBackgroundOpacity,0,0,85))
 d.chatFontFace=math.floor(FieldKit.Number(d.chatFontFace,1,1,5))
 d.chatBackgroundColor=math.floor(FieldKit.Number(d.chatBackgroundColor,1,1,6))
 d.chatTextColor=math.floor(FieldKit.Number(d.chatTextColor,1,1,6))
 if type(d.chatAnchor)~="table" then d.chatAnchor=nil
 else
  local x=FieldKit.Number(d.chatAnchor.x,nil,0,10000)
  local y=FieldKit.Number(d.chatAnchor.y,nil,0,10000)
  d.chatAnchor=(x and y) and {x=x,y=y} or nil
 end
 -- Stable journey ids survive page reordering without resetting user choices.
 if d.uiSchema~=2 then
  local keep=d.uiPage
  local previous={"nameplates","health","bosses","health","alerts","windows","map","interface","interface","combat","bosses"}
  local titles={Nameplates="nameplates",Target="health",Combat="bosses",Player="health",Warnings="alerts",Windows="windows",Map="map",Interface="interface",Camera="interface",["Combat text"]="combat",["Boss health"]="bosses"}
  d.uiPage=titles[d.panelSection] or previous[tonumber(d.panelTab)] or keep or "home";d.uiSchema=2
 end
 -- Promote legacy mega-Windows page (+ its subtabs) to thin HUD sections.
 if d.uiPage=="windows" then
  local map={display="cards",layout="layout",appearance="look",coop="coop",meter="meter",cards="cards"}
  d.uiPage=map[d.windowPage] or "cards"
 elseif d.uiPage=="appearance" then d.uiPage="look"
 elseif d.uiPage=="display" then d.uiPage="cards" end
 local valid={home=true,combat=true,health=true,bosses=true,alerts=true,cards=true,meter=true,layout=true,look=true,profiles=true,coop=true,map=true,nameplates=true,interface=true}
 if not valid[d.uiPage] then d.uiPage="home" end
 d.panelTab=math.floor(FieldKit.Number(d.panelTab,1,1,16))
 d.playerBarX=FieldKit.Number(d.playerBarX,0,-10000,10000)
 d.playerBarY=FieldKit.Number(d.playerBarY,-70,-10000,10000)
 if type(d.lastStats)=="table" then
  for key,value in pairs(d.lastStats) do d.lastStats[key]=FieldKit.Number(value) end
 else d.lastStats=nil end
 if d.cameraMax~=nil then d.cameraMax=FieldKit.Number(d.cameraMax,nil,15,50) end
 for _,key in ipairs({"playerHealthMode","targetHealthMode","bossHealthMode","partyHealthMode"}) do
  d[key]=math.floor(FieldKit.Number(d[key],1,1,3))
 end
 for _,key in ipairs({"hideDamage","showCrits","groupCrits","hideGryphons","moneyDetached","hudBossesHidden","hudTallyHidden","hudMeterHidden","statsCollapsed","gearCollapsed"}) do
  if d[key]~=nil and type(d[key])~="boolean" then d[key]=nil end
 end
 d.chestsOpened=FieldKit.Number(d.chestsOpened,0,0,1e9)
 if type(d.shownStats)~="table" then
  d.shownStats={};for i=1,table.getn(defaultStats) do d.shownStats[defaultStats[i]]=true end
 end
 -- Obsolete experiments and gameplay-state persistence are not supported.
 for _,key in ipairs({"talentToggles","talentStamp","chestSeq","goldSpent","runePins","runeRecord","runePickupSetup","runeObservations","runeProbe","worldProbe","runeTrace","runeOverlay"}) do d[key]=nil end
 if FieldKitCombat then FieldKitCombat.Ensure() end
 return d
end
