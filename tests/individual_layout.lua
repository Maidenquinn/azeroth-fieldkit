-- Exercise actual UI callbacks, group routing and content refreshes. Native
-- StartMoving/clamping is mocked, so edge visibility still needs a client test.
FieldKitDB={linkLeftCards=true,linkRightCards=true,runModeCard=true,meterValues=3,
 cardSizes={Unknown={width=500},FieldKitModeFrame="bad",FieldKitStatsFrame={width=99999,height=-2}}}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
assert(FieldKitDB.cardSizes.Unknown==nil and FieldKitDB.cardSizes.FieldKitModeFrame==nil)
assert(FieldKitDB.cardSizes.FieldKitStatsFrame.width==800 and FieldKitDB.cardSizes.FieldKitStatsFrame.height==22)
FieldKitDB.cardSizes={}
AZS_ZONE.heroic=2;AZS_RUN.ph="playing"
local lines={{name="Observed",dmg=420,dps=42,share=.8},{name="Other",dmg=105,dps=10.5,share=.2}}
AZS_GetMeter=function() return lines,525,52.5 end
AZS_TAKEN={{source="mob melee",dmg=12}};AZS_TAKEN_UPDATED=NOW
AZS_GetLairs=function() return {{name="Guardian",state="asleep",x=20,y=20,left=0}} end
update(FieldKitFrame,.3)
local C,U=FieldKitCardLayout,FieldKitUI
local function control(label)
 for i=1,table.getn(U.controls) do
  local c=U.controls[i];if c.label==label or (c.item and c.item.label==label) then return c end
 end
 error(label)
end
local function choose(c,n) click(c);click(c.choiceButtons[n]) end
local function slide(c,n) this=c;c:SetValue(n);c:GetScript("OnValueChanged")() end
local function relative(frame) local p,r=frame:GetPoint();return r end
local function offset(frame) local p,r,rp,x=frame:GetPoint();return x end
local function drag(frame,point,x,y)
 this=frame;frame:GetScript("OnDragStart")()
 frame:ClearAllPoints();frame:SetPoint(point,UIParent,point,x,y)
 frame:GetScript("OnDragStop")()
end

-- Both sides can be unlinked directly from the arrangement dock.
U.SetLayoutEditing(true,false)
click(U.groupLeft);click(U.groupRight)
assert(not FieldKitDB.linkLeftCards and not FieldKitDB.linkRightCards)
local meterAnchor=FieldKitDB.frameAnchors.FieldKitMeterFrame
drag(FieldKitTakenFrame,"TOPLEFT",77,-130)
assert(FieldKitDB.frameAnchors.FieldKitTakenFrame[3]==77)
assert(FieldKitDB.frameAnchors.FieldKitMeterFrame==meterAnchor)
drag(FieldKitGearFrame,"TOPRIGHT",-25,-60)
drag(FieldKitStatsFrame,"BOTTOMRIGHT",-30,45)
update(FieldKitFrame,.3)
assert(relative(FieldKitTakenFrame)==UIParent,"Taken reattached to damage")
assert(offset(FieldKitTakenFrame)==77)
assert(offset(FieldKitGearFrame)==-25)
assert(offset(FieldKitStatsFrame)==-30)
click(U.sizes);assert(not FieldKit.layoutEditing and FieldKitDB.uiPage=="windows")

-- Each card keeps its own width and height through unchanged native stamps.
local selector,width,height=control("Window to resize"),control("Window width"),control("Window height")
local expected={}
for i=1,7 do
 choose(selector,i);slide(width,480+i*10);slide(height,280+i*10)
 local f=C.Frame();expected[i]={f:GetWidth(),f:GetHeight()}
 assert(f:GetWidth()==480+i*10 and f:GetHeight()==280+i*10,C.names[i])
end
for i=1,7 do
 choose(selector,i);assert(C.Frame():GetWidth()==expected[i][1] and C.Frame():GetHeight()==expected[i][2])
end
update(FieldKitFrame,.3)
for i=1,7 do local f=getglobal(C.names[i]);assert(f:GetWidth()==expected[i][1] and f:GetHeight()==expected[i][2]) end
assert(FieldKitMeterFrame.rows[1].meterColumns[1]:GetText()=="420")
assert(FieldKitMeterFrame.rows[1].meterColumns[2]:GetText()=="42 dps")
assert(FieldKitMeterFrame.rows[1].label:GetWidth()>200)
-- Smaller height cannot crop the observed rows; font size is not stretched.
choose(selector,2);slide(height,22)
assert(FieldKitMeterFrame:GetHeight()>=28+14*2)
assert(FieldKitMeterFrame.rows[1]:GetHeight()>=12 and FieldKitMeterFrame.rows[2]:IsShown())
slide(height,360);click(FieldKitMeterFrame.mashCollapseButton)
assert(FieldKitMeterFrame:GetHeight()==24)
click(FieldKitMeterFrame.mashCollapseButton);assert(FieldKitMeterFrame:GetHeight()==360)
choose(selector,6);slide(height,22)
assert(FieldKitStatsFrame:GetHeight()>=FieldKitStatsFrame.fieldkitMinimumHeight)

-- Group dragging must save only the proxy anchor; unlink restores own anchors.
U.SetLayoutEditing(true,false);click(U.groupRight);click(U.groupLeft)
local oldGear=FieldKitDB.frameAnchors.FieldKitGearFrame
this=FieldKitGearFrame;FieldKitGearFrame:GetScript("OnDragStart")()
assert(C.root.azsMoving and not FieldKitGearFrame.azsMoving)
C.root:ClearAllPoints();C.root:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",0,-10)
FieldKitGearFrame:GetScript("OnDragStop")()
assert(FieldKitDB.frameAnchors.FieldKitRightStack[3]==0)
assert(FieldKitDB.frameAnchors.FieldKitGearFrame==oldGear)
assert(not C.root.mouseEnabled and C.root.clamped)
assert(C.root:GetWidth()==math.max(FieldKitGearFrame:GetWidth(),FieldKitStatsFrame:GetWidth()))
assert(FieldKitModeFrame:GetWidth()==490 and FieldKitMeterFrame:GetWidth()==500)
local h=C.root:GetHeight()
click(FieldKitGearFrame.mashCollapseButton);update(FieldKitFrame,.3)
assert(C.root:GetHeight()<h and FieldKitDB.cardSizes.FieldKitGearFrame.height==330)
click(FieldKitGearFrame.mashCollapseButton);update(FieldKitFrame,.3)
click(U.groupRight);click(U.groupLeft)
assert(offset(FieldKitGearFrame)==-25)
assert(offset(FieldKitTakenFrame)==77)
U.SetLayoutEditing(false,true)

-- Reset size belongs to the selected card; reset positions leaves sizes intact.
choose(selector,5);local automatic=control("Automatic size for this window")
automatic:SetChecked(true);click(automatic)
assert(FieldKitDB.cardSizes.FieldKitGearFrame==nil and FieldKitGearFrame:GetWidth()==220)
assert(FieldKitDB.cardSizes.FieldKitMeterFrame.width==500)
choose(selector,7);automatic:SetChecked(true);click(automatic)
assert(FieldKitMoneyFrame:GetHeight()==22,"Automatic money height was not restored")
U.ResetPositions();assert(FieldKitDB.cardSizes.FieldKitMeterFrame.height==360);U.UndoPositions()
FieldKit_SetLanguage("fr");assert(FieldKit_L("Window width")=="Largeur de la fenêtre")
FieldKit_SetLanguage("en")
print("Independent cards, group proxies, per-card dimensions and collapse fixtures passed")
