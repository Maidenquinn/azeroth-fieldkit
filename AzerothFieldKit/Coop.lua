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
 P.CreateMember(0,createWindow,makeMovable) -- the player's own card: same component
 P.TrackRun()
end

function P.CreateMember(index,createWindow,makeMovable)
 local frame=createWindow(index==0 and "FieldKitPlayerCard" or "FieldKitPartyCard"..index,index==0 and "My card" or "Teammate",4)
 frame:SetWidth(280);frame.unit=index==0 and "player" or "party"..index;P.frames[index]=frame
 makeMovable(frame,-UIParent:GetWidth()/2+550,UIParent:GetHeight()/2-220-((index==0 and 4 or index)-1)*112,true)
 frame:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L(index==0 and "My card" or "Teammate"),1,.85,.55)
  GameTooltip:AddLine(FieldKit_L("Native party-unit health and resources. Damage and DPS require a fresh group-meter sample. Drag cards directly. Native teammate frames remain interactive unless explicitly hidden."),.8,.8,.8,true)
  if FieldKitGroupHistory then local who=type(UnitName)=="function" and UnitName(this.unit);if who then FieldKitGroupHistory.DetailTooltip(GameTooltip,this.unit,who) end end
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
-- One card component for the player and for every teammate: same structure, same size, whatever the data. Own widgets only
-- (the generic window rows are not used), every child with an explicit level above the card (a parent's SetFrameLevel does
-- not re-level its children on this client). Detail level (option) picks one of three FIXED sizes.
local CLASS_ICON={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},HUNTER={0,.25,.25,.5},
 SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},PALADIN={0,.25,.5,.75}}
-- Content box = the card minus the art border (12 px, the corner size of the zone material, same on every side).
-- detail: 1 compact (name + life), 2 standard (+ class/level + thin resource), 3 full (+ resource values).
-- Rows are listed top to bottom inside the content box (y from its top, heights in px).
local PAD=12
local DETAIL={
 {content=28,name=0,info=nil,hp=15,hpH=13,res=nil,resH=0},
 {content=44,name=0,info=14,hp=26,hpH=12,res=40,resH=4},
 {content=52,name=0,info=14,hp=28,hpH=13,res=43,resH=9},
}
for _,d in ipairs(DETAIL) do d.h=d.content+2*PAD;d.socket=d.content end
P.detail=DETAIL;P.cardWidth=300;P.pad=PAD
function P.Detail() return math.floor(FieldKit.Number(FieldKitDB and FieldKitDB.partyDetail,2,1,3)) end
local function MakeBar(frame)
 local bar=CreateFrame("StatusBar",nil,frame)
 -- A flat white fill (tinted by SetStatusBarColor): the stock UI-StatusBar texture is a 128x16 gradient strip whose tiling and
 -- soft ends show as small interruptions in a full bar at some scales. Flat = one uniform fill at 100 %, exact at any value.
 bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");bar.fieldkitTexture="Interface\\Buttons\\WHITE8X8";bar:SetMinMaxValues(0,1);bar:SetValue(0)
 bar.back=bar:CreateTexture(nil,"BACKGROUND");bar.back:SetAllPoints(bar);bar.back:SetTexture(.02,.03,.025,.92)
 -- thin gold outline drawn on the bar itself (anchored to its edges, so it can never leave the bar)
 bar.edge={}
 for n,def in ipairs({{"TOPLEFT","TOPRIGHT",true},{"BOTTOMLEFT","BOTTOMRIGHT",true},{"TOPLEFT","BOTTOMLEFT",false},{"TOPRIGHT","BOTTOMRIGHT",false}}) do
  local t=bar:CreateTexture(nil,"OVERLAY");t.fieldkitLayer="OVERLAY";t:SetTexture(FieldKitTheme.gold[1],FieldKitTheme.gold[2],FieldKitTheme.gold[3],.85) -- outline ABOVE the fill: identical at every value
  t:SetPoint(def[1],bar,def[1],0,0);t:SetPoint(def[2],bar,def[2],0,0);if def[3] then t:SetHeight(1) else t:SetWidth(1) end
  bar.edge[n]=t
 end
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
   frame.portraitInner=frame:CreateTexture(nil,"BACKGROUND");frame.portraitInner:SetTexture(0,0,0,1)
   frame.portrait=frame:CreateTexture(nil,"BACKGROUND");frame.portrait:SetTexCoord(.08,.92,.08,.92)
   frame.hpBar=MakeBar(frame);frame.mpBar=MakeBar(frame)
   frame.nameText=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
   frame.infoText=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
   frame.stateText=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
   frame.historyIcons={}
   for n=1,5 do local t=frame:CreateTexture(nil,"OVERLAY");t:SetWidth(12);t:SetHeight(12);t:SetTexCoord(.07,.93,.07,.93);t:Hide();frame.historyIcons[n]=t end
  end
  frame.hpBar:SetFrameLevel(level+2);frame.mpBar:SetFrameLevel(level+2)
  if collapse then collapse:Hide() end
  frame.title:Hide();frame.total:Hide()
  for _,row in ipairs(frame.rows or {}) do row:Hide() end
 else
  frame:SetFrameStrata("LOW");frame:SetFrameLevel(frame.fieldkitOriginalLevel)
  frame.title:Show();frame.total:Show()
  frame.title:ClearAllPoints();frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",9,-7)
  frame.total:ClearAllPoints();frame.total:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-25,-7)
  if frame.portrait then
   frame.portrait:Hide();frame.portraitBack:Hide();frame.portraitInner:Hide();frame.hpBar:Hide();frame.mpBar:Hide()
   frame.nameText:Hide();frame.infoText:Hide();frame.stateText:Hide();for _,t in ipairs(frame.historyIcons) do t:Hide() end
   P.HideArt(frame);frame.fieldkitArtOnly=nil;FieldKitTheme.State(frame,false)
  end
  if collapse then collapse:Show() end
 end
end
-- Real portrait, else the class icon, else nothing (never a made-up face).
function P.Portrait(frame,unit,token)
 local now=GetTime()
 -- a window wider than tall shows the middle of the (square) face instead of stretching it
 local crop=frame.fieldkitPortraitCrop or 1;local margin=(.84*(1-crop))/2
 local function Crop() frame.portrait:SetTexCoord(.08,.92,.08+margin,.92-margin) end
 if frame.portraitKey==token and now<(frame.portraitAt or 0) and frame.portrait:IsShown() then Crop();return end
 frame.portraitKey=token;frame.portraitAt=now+5
 Crop()
 local ok=type(SetPortraitTexture)=="function" and pcall(SetPortraitTexture,frame.portrait,unit)
 if not ok then
  local c=CLASS_ICON[token or ""]
  if c then frame.portrait:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes");frame.portrait:SetTexCoord(c[1],c[2],c[3],c[4]);ok=true end
 end
 if ok then frame.portrait:Show() else frame.portrait:Hide() end
end
-- Every widget is anchored to the card's own edges, and the border is either the Aethus art (Elwynn) or the zone material (Naxx).
-- Elwynn: the card frame IS the approved Aethus vitality art (portrait window, gold border, corner studs, dark green body),
-- cut into a 3x3 grid: corners and the portrait window keep their proportions (scale 0.5), only the plain centre bands stretch.
-- Source art (texture pixels, texture 512x256): occupied area x 5..352, y 7..127; plain columns x 118..130 (checked flat).
local ART={file="elwynn_complete_vitality_1.tga",tw=512,th=256,scale=.5,
 xs={5,116,118,130,336,352},   -- left slice 5..116, plain band 118..130, right slice 336..352 (past the slot ends)
 ys={7,46,95,127},             -- top 7..46, stretched 46..95, bottom 95..127
 hole={11,11,101,109},         -- portrait window inside the art area (x1,y1,x2,y2), art-area pixels
 contentTop=6,contentBottom=7,contentLeft=62,contentRight=12}
P.art=ART
-- Rows of the content box (heights in px), top to bottom; the card height = content + top + bottom insets.
local ART_DETAIL={
 {content=27,name=0,info=nil,hp=15,hpH=12,res=nil,resH=0},
 {content=44,name=0,info=13,hp=26,hpH=12,res=40,resH=4},
 {content=50,name=0,info=13,hp=26,hpH=13,res=41,resH=9},
}
for _,d in ipairs(ART_DETAIL) do d.h=d.content+ART.contentTop+ART.contentBottom end
P.artDetail=ART_DETAIL
function P.UsesArt() local R=FieldKitReferenceHUD;return R and R.key and string.find(R.key,"^elwynn") and true or false end
-- Draws the 9 art tiles for a card of width x height (card pixels). Returns the portrait window in card pixels.
function P.Art(frame,width,height)
 local f=ART.scale
 frame.artTiles=frame.artTiles or {}
 local cols={{ART.xs[1],ART.xs[2]},{ART.xs[3],ART.xs[4]},{ART.xs[5],ART.xs[6]}}
 local rows={{ART.ys[1],ART.ys[2]},{ART.ys[2],ART.ys[3]},{ART.ys[3],ART.ys[4]}}
 local leftW=(cols[1][2]-cols[1][1])*f;local rightW=(cols[3][2]-cols[3][1])*f;local topH=(rows[1][2]-rows[1][1])*f;local bottomH=(rows[3][2]-rows[3][1])*f
 local colW={leftW,width-leftW-rightW,rightW};local rowH={topH,height-topH-bottomH,bottomH}
 local colX={0,leftW,width-rightW};local rowY={0,topH,height-bottomH}
 local n=0
 for r=1,3 do for c=1,3 do
  n=n+1;local t=frame.artTiles[n]
  if not t then t=frame:CreateTexture(nil,"BORDER");frame.artTiles[n]=t end
  t:SetTexture(FieldKitTheme.media.."ReferenceHUD\\"..ART.file)
  t:SetTexCoord(cols[c][1]/ART.tw,cols[c][2]/ART.tw,rows[r][1]/ART.th,rows[r][2]/ART.th)
  t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",colX[c],-rowY[r]);t:SetWidth(colW[c]);t:SetHeight(rowH[r]);t:Show()
  t.fieldkitRect={colX[c],rowY[r],colX[c]+colW[c],rowY[r]+rowH[r]}
 end end
 -- the portrait window: the art-area hole, mapped through the same 3x3 scaling
 local h=ART.hole
 local x1=(h[1]-ART.xs[1])*f;local x2=(h[3]-ART.xs[1])*f
 local y1=(h[2]-ART.ys[1])*f;local y2=height-(ART.ys[4]-h[4])*f
 return {x1,y1,x2,y2}
end
function P.HideArt(frame) for _,t in ipairs(frame.artTiles or {}) do t:Hide() end end
-- A status bar with an explicit whole-pixel size, one anchor, and a fill that is recomputed whenever its geometry changes. The
-- fill of a StatusBar is computed when the value is set; with two anchors the width is only resolved at the next layout pass,
-- so a fill computed at set-value time could be shorter than the bar that finally exists (a transparent strip at 100 %).
-- Toggling the value after a size change forces the fill to be recomputed at the real width.
function P.SizeBar(bar,frame,x,y,w,h)
 w=math.floor(w+.5);h=math.floor(h+.5)
 bar:ClearAllPoints();bar:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-y);bar:SetWidth(w);bar:SetHeight(h)
 local key=w.."x"..h
 if bar.fieldkitSize~=key then
  bar.fieldkitSize=key;bar.fieldkitW,bar.fieldkitH=w,h
  bar:SetStatusBarTexture(bar.fieldkitTexture);bar:SetMinMaxValues(0,1);bar:SetValue(0)
 end
end
function P.FillBar(bar,fraction,r,g,b)
 fraction=math.max(0,math.min(1,fraction or 0))
 bar:SetValue(fraction);bar.fieldkitFraction=fraction
 if r then bar:SetStatusBarColor(r,g,b,1) end -- fully opaque fill: nothing of the card shows through the filled part
end
local function Box(fs,frame,left,right,y,h,size,justify)
 fs:ClearAllPoints();fs:SetPoint("TOPLEFT",frame,"TOPLEFT",left,-y);fs:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-right,-y)
 fs:SetHeight(h);fs:SetJustifyH(justify or "LEFT");FieldKitTheme.Font(fs,size,FieldKitTheme.text)
end
-- Lays the card out and fills it. d holds only values the client reported (nil = unavailable). The geometry depends on the
-- detail level, the card width and the zone style only, never on the data: all cards are identical.
function P.Compact(frame,d)
 local art=P.UsesArt()
 local spec=(art and ART_DETAIL or DETAIL)[P.Detail()]
 local width=FieldKitCardLayout.Width(frame,P.cardWidth);local height=spec.h
 frame:SetWidth(width);frame:SetHeight(height)
 frame.fieldkitArtOnly=art and true or nil
 FieldKitTheme.State(frame,false);FieldKitTheme.Update(frame) -- skin hidden under the art, or resized to the new size
 for _,row in ipairs(frame.rows or {}) do row:Hide() end
 local layout={width=width,height=height,art=art}
 frame.fieldkitLayout=layout
 local hole,box
 if art then
  hole=P.Art(frame,width,height)
  box={ART.contentLeft,width-ART.contentRight,ART.contentTop,height-ART.contentBottom}
  frame.portraitBack:Hide()
 else
  P.HideArt(frame)
  local s=spec.socket
  hole={PAD,PAD,PAD+s,PAD+s}
  box={PAD+s+8,width-PAD,PAD,height-PAD}
  frame.portraitBack:ClearAllPoints();frame.portraitBack:SetPoint("TOPLEFT",frame,"TOPLEFT",PAD,-PAD);frame.portraitBack:SetWidth(s);frame.portraitBack:SetHeight(s);frame.portraitBack:Show()
  hole={PAD+2,PAD+2,PAD+s-2,PAD+s-2}
 end
 layout.box=box;layout.portrait=hole
 -- portrait: fills the window; a square face is cropped (not stretched) when the window is wider than tall
 local pw,ph=hole[3]-hole[1],hole[4]-hole[2]
 frame.portraitInner:ClearAllPoints();frame.portraitInner:SetPoint("TOPLEFT",frame,"TOPLEFT",hole[1],-hole[2]);frame.portraitInner:SetWidth(pw);frame.portraitInner:SetHeight(ph);frame.portraitInner:Show()
 frame.portrait:ClearAllPoints();frame.portrait:SetPoint("TOPLEFT",frame,"TOPLEFT",hole[1],-hole[2]);frame.portrait:SetWidth(pw);frame.portrait:SetHeight(ph)
 frame.fieldkitPortraitCrop=ph<pw and (ph/pw) or 1
 if d.preview then frame.portrait:Hide() else P.Portrait(frame,frame.unit,d.token or d.name) end
 if frame.portrait.SetVertexColor then if d.muted then frame.portrait:SetVertexColor(.5,.5,.5) else frame.portrait:SetVertexColor(1,1,1) end end
 local x,right=box[1],width-box[2];local stateWidth=60
 -- name (left) and state tag (right) share the first line; the name box ends before the tag
 Box(frame.nameText,frame,x,right+stateWidth+4,box[3]+spec.name,13,12)
 frame.nameText:SetText(d.name);if d.muted then frame.nameText:SetTextColor(.7,.7,.7) else frame.nameText:SetTextColor(1,.93,.75) end;frame.nameText:Show()
 frame.stateText:ClearAllPoints();frame.stateText:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-right,-(box[3]+spec.name+1));frame.stateText:SetWidth(stateWidth);frame.stateText:SetHeight(11);frame.stateText:SetJustifyH("RIGHT")
 FieldKitTheme.Font(frame.stateText,10,FieldKitTheme.text)
 frame.stateText:SetText(d.state or "");if d.state then frame.stateText:SetTextColor(.95,.3,.25) end;frame.stateText:Show()
 layout.name={x,width-(right+stateWidth+4),box[3]+spec.name,13};layout.state={width-right-stateWidth,width-right,box[3]+spec.name+1,11}
 -- secondary line (class and level) leaves room for five 12 px icons
 if spec.info then
  Box(frame.infoText,frame,x,right+5*14,box[3]+spec.info,11,10)
  frame.infoText:SetText(d.detail);frame.infoText:SetTextColor(d.color[1],d.color[2],d.color[3]);frame.infoText:Show()
  layout.info={x,width-(right+5*14),box[3]+spec.info,11}
 else frame.infoText:Hide() end
 local shown=0
 if spec.info and d.icons then
  for n=1,table.getn(frame.historyIcons) do
   local t=frame.historyIcons[n];local texture=d.icons[n]
   if texture then t:ClearAllPoints();t:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-right-(n-1)*14,-(box[3]+spec.info-.5));t:SetTexture(texture);t:Show();shown=shown+1 else t:Hide() end
  end
  layout.icons={width-right-5*14,width-right,box[3]+spec.info-.5,12}
 else for _,t in ipairs(frame.historyIcons) do t:Hide() end end
 -- life bar: anchored to both edges, so it ends exactly at the content box
 local bar=frame.hpBar;P.SizeBar(bar,frame,x,box[3]+spec.hp,width-right-x,spec.hpH)
 if d.fraction then P.FillBar(bar,d.fraction,d.barColor[1],d.barColor[2],d.barColor[3]);bar.fieldkitColor=d.barColor else P.FillBar(bar,0) end
 bar:Show();FieldKitTheme.Font(bar.text,10,{1,1,1});bar.text:SetText(d.hpText)
 layout.hp={x,width-right,box[3]+spec.hp,spec.hpH}
 local res=frame.mpBar
 local hasResource=spec.res and d.mana~=nil and d.manaMax~=nil and d.manaMax>0 and not d.muted
 if hasResource then
  P.SizeBar(res,frame,x,box[3]+spec.res,width-right-x,spec.resH)
  P.FillBar(res,d.mana/d.manaMax,d.powerColor[1],d.powerColor[2],d.powerColor[3]);res.fieldkitColor=d.powerColor
  for _,t in ipairs(res.edge) do if spec.resH>=6 then t:Show() else t:Hide() end end
  if spec.resH>=9 then FieldKitTheme.Font(res.text,9,{1,1,1});res.text:SetText(string.format("%.0f / %.0f",d.mana,d.manaMax)) else res.text:SetText("") end
  res:Show();layout.res={x,width-right,box[3]+spec.res,spec.resH}
 else res:Hide() end
 frame.fieldkitIconCount=shown
end

-- With a themed HUD the cards are the group display. Saved preferences are never modified.
function P.Themed() local R=FieldKitReferenceHUD;return R and R.active and true or false end
function P.CardsOn() return FieldKitDB.partyCards or (P.Themed() and FieldKitDB.partyShow~=false) end
function P.ReplaceOn() return FieldKitDB.replacePartyFrames or (P.Themed() and FieldKitDB.partyShow~=false) end
-- Health colour from the real fraction; greyed when the unit is dead, a ghost or offline.
function P.HealthColor(fraction,muted)
 if muted then return {.45,.45,.45} end
 if fraction>.5 then return {.22,.72,.3} elseif fraction>.25 then return {.88,.7,.18} end
 return {.82,.2,.16}
end

-- index 0 is the player's own card (option), 1-4 the teammates: the same code path.
function P.UpdateMember(index,active)
 local frame=P.frames[index];if not frame then return end
 local isPlayer=index==0
 local exists=isPlayer and true or (active and UnitExists(frame.unit))
 local preview=not exists and FieldKit.layoutEditing
 local themed=P.Themed()
 if isPlayer and not (themed and FieldKitDB.partyShow~=false and FieldKitDB.partyPlayerCard) then frame:Hide();return end
 if not P.CardsOn() or (not exists and not preview) then frame:Hide();if not isPlayer then P.Stock(index,false) end;return end
 local hp=type(UnitHealth)=="function" and FieldKit.Number(UnitHealth(frame.unit),nil,0)
 local max=type(UnitHealthMax)=="function" and FieldKit.Number(UnitHealthMax(frame.unit),nil,0)
 local known=not preview and hp~=nil and max and max>0
 if not known and not preview then frame:Hide();if not isPlayer then P.Stock(index,false) end;return end
 P.Style(frame,themed)
 frame:SetScale(math.floor(FieldKit.Number(FieldKitDB.partyCardScale,100,70,130)/5+.5)*5/100)
 local name=preview and FieldKit_L("Teammate").." "..index.." ("..FieldKit_L("Preview")..")" or (UnitName(frame.unit) or "?")
 local class,token
 if not preview and type(UnitClass)=="function" then class,token=UnitClass(frame.unit) end
 local level=not preview and type(UnitLevel)=="function" and FieldKit.Number(UnitLevel(frame.unit),nil,1)
 local color=colors[token] or {.4,.8,.5}
 local connected
 if not preview and type(UnitIsConnected)=="function" then connected=UnitIsConnected(frame.unit) and true or false end
 -- Dead / ghost only when the client reports it (optional API, never inferred from missing data).
 local ghost=not preview and type(UnitIsGhost)=="function" and UnitIsGhost(frame.unit) and true or false
 local dead=not preview and ghost or (not preview and (type(UnitIsDeadOrGhost)=="function" and UnitIsDeadOrGhost(frame.unit) or (type(UnitIsDead)=="function" and UnitIsDead(frame.unit))) and true or false)
 local muted=dead or connected==false
 local fraction=known and math.min(hp/max,1) or 0
 local mana=type(UnitMana)=="function" and FieldKit.Number(UnitMana(frame.unit),nil,0)
 local manaMax=type(UnitManaMax)=="function" and FieldKit.Number(UnitManaMax(frame.unit),nil,0)
 if preview then mana=nil;manaMax=nil end
 local power=not preview and type(UnitPowerType)=="function" and UnitPowerType(frame.unit)
 local powerColor=muted and {.45,.45,.45} or (power==1 and {.9,.2,.15} or (power==3 and {.9,.8,.15} or {.2,.5,.9}))
 if themed then
  local status=connected==false and "Offline" or (ghost and "Ghost" or (dead and "Dead" or (known and hp==0 and "0 HP" or nil)))
  local icons
  if FieldKitDB.partyHistory and FieldKitDB.partyHistoryIcons~=false and FieldKitGroupHistory and not preview then
   icons={};for _,e in ipairs(FieldKitGroupHistory.Recent(name,5)) do local t=FieldKitGroupHistory.Icon(e.spell);if t then table.insert(icons,t) end end
  end
  P.Compact(frame,{name=(FieldKit.layoutEditing and not preview and index>0 and index..". " or "")..name,preview=preview,token=token,color=color,
   detail=preview and FieldKit_L("Preview") or ((level and (FieldKit_L("Lvl").." "..level.." ") or "")..(class or "?")),
   state=status and string.upper(FieldKit_L(status)) or nil,
   fraction=known and (dead and 0 or fraction) or nil,barColor=P.HealthColor(fraction,muted),
   hpText=known and FieldKit_FormatHealth(hp,max,3) or "",muted=muted,mana=mana,manaMax=manaMax,powerColor=powerColor,icons=icons})
  frame:Show();if not isPlayer then P.Stock(index,P.ReplaceOn() and known and true or false) end;return
 end
 -- legacy (non-themed) card: the original generic window rows
 frame:SetWidth(FieldKitCardLayout.Width(frame,280))
 frame.title:SetText((FieldKit.layoutEditing and not preview and index>0 and index..". " or "")..name);frame.title:SetWidth(frame:GetWidth()*.55)
 frame.total:SetText(preview and FieldKit_L("Preview") or ((level and (FieldKit_L("Lvl").." "..level.." ") or "")..(class or "?")));frame.total:SetWidth(frame:GetWidth()*.3);frame.total:SetJustifyH("RIGHT")
 P.Row(frame,1,"Health",known and FieldKit_FormatHealth(hp,max,FieldKitDB.partyHealthMode) or FieldKit_L("Not provided"),dead and 0 or fraction,color)
 local resource=power==0 and "Mana" or (power==1 and "Rage" or (power==3 and "Energy" or "Resource"))
 P.Row(frame,2,resource,mana and manaMax and manaMax>0 and string.format("%.0f / %.0f",mana,manaMax) or FieldKit_L("Not provided"),mana and manaMax and manaMax>0 and not dead and math.min(mana/manaMax,1) or 0,powerColor)
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
 for i=0,4 do P.UpdateMember(i,active) end
 if FieldKitGroupHistory then FieldKitGroupHistory.Sync() end
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

-- /fieldkit barprobe: what each teammate life bar really is (size, value, fill texture width) so a transparent strip at 100 %
-- can be measured in the game instead of guessed.
function P.BarProbe()
 local out={}
 local function N(v) if type(v)~="number" then return tostring(v) end return string.format("%.3f",v) end
 for index=0,4 do
  local f=P.frames[index]
  if f and f:IsShown() and f.hpBar then
   local b=f.hpBar;local L=f.fieldkitLayout or {}
   local tex=b.GetStatusBarTexture and b:GetStatusBarTexture()
   local fillW=tex and type(tex)=="table" and tex.GetWidth and tex:GetWidth() or nil
   local trackW=b.back and b.back.GetWidth and b.back:GetWidth() or nil
   local hp=type(UnitHealth)=="function" and UnitHealth(f.unit) or nil;local max=type(UnitHealthMax)=="function" and UnitHealthMax(f.unit) or nil
   local fe=f.GetEffectiveScale and f:GetEffectiveScale() or 0
   table.insert(out,string.format("card %d %s: unit hp %s / %s = %s | bar value %s fraction %s",index,tostring(f.unit),tostring(hp),tostring(max),(hp and max and max>0) and N(hp/max) or "?",N(b:GetValue()),N(b.fieldkitFraction)))
   table.insert(out,string.format("   container(card) %s x %s | content box %s..%s | bar %s x %s (stored %s x %s) | track %s | fill texture %s",N(f:GetWidth()),N(f:GetHeight()),tostring(L.box and L.box[1]),tostring(L.box and L.box[2]),N(b:GetWidth()),N(b:GetHeight()),tostring(b.fieldkitW),tostring(b.fieldkitH),N(trackW),N(fillW)))
   table.insert(out,string.format("   card scale %s effective %s | bar effective %s | bar pixel width %s | bar left/right %s / %s",N(f:GetScale()),N(fe),N(b.GetEffectiveScale and b:GetEffectiveScale() or 0),N((b:GetWidth() or 0)*fe),N(b.GetLeft and b:GetLeft()),N(b.GetRight and b:GetRight())))
  end
 end
 if table.getn(out)==0 then table.insert(out,"no teammate card shown") end
 return out
end
