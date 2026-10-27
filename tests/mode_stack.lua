-- Whole-card geometry and native-rank/reference separation, using real handlers.
FieldKitDB={bossFrame=false,linkLeftCards=true,runModeCard=true,meterValues=3}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
AZS_RUN.ph="playing";AZS_ZONE={zone="elwynn",zname="Elwynn Forest",heroic=2}
AZS_GetMeter=function() return {{name="Observed spell",dmg=100,dps=10,share=1}},100,10 end
AZS_TAKEN={{source="mob melee",dmg=20}};AZS_TAKEN_UPDATED=NOW
AZS_GetLairs=function() return {{name="Guardian",state="asleep",x=20,y=20,left=0}} end
update(FieldKitFrame,.3)
local S,R=FieldKitHudStack,FieldKitRunMode
local frames={FieldKitModeFrame,FieldKitMeterFrame,FieldKitTakenFrame,FieldKitLairFrame}
local function checkStack()
 local y=0
 for i=1,4 do
  local f=frames[i]
  if f:IsShown() then
   local point,relative,rp,x,offset=f:GetPoint()
   assert(point=="TOPLEFT" and relative==S.root and rp=="CENTER" and x==0)
   assert(offset==-y and f:GetWidth()==FieldKit.MeterWidth(FieldKitDB.meterValues))
   y=y+f:GetHeight()+6
  end
 end
 assert(S.height==math.max(0,y-6))
end
checkStack()
assert(R.frame.total:GetText()=="Heroic II")
assert(R.frame.rows[2].label:GetText()=="Modifier reference · 0.121")
assert(R.frame.rows[3].label:GetText()=="Shorter warnings")
assert(R.frame.rows[6].label:GetText()=="Sentinels")
local legacyX,legacyY=FieldKitDB.pos.FieldKitMeterFrame[1],FieldKitDB.pos.FieldKitMeterFrame[2]
local oldHeight=FieldKitMeterFrame:GetHeight()
local _,_,_,_,takenY=FieldKitTakenFrame:GetPoint()
click(FieldKitMeterFrame.mashCollapseButton);update(FieldKitFrame,.06)
checkStack()
local _,_,_,_,collapsedY=FieldKitTakenFrame:GetPoint()
assert(collapsedY-takenY==oldHeight-24,"Collapsed card left a hole in the stack")
click(FieldKitMeterFrame.mashCollapseButton);update(FieldKitFrame,.06)
assert(FieldKitMeterFrame.rows[1]:IsShown(),"Unchanged meter data did not reappear on expansion")
checkStack()
local function control(label)
 for i=1,table.getn(FieldKitUI.controls) do
  local c=FieldKitUI.controls[i];if c.label==label or (c.item and c.item.label==label) then return c end
 end
 error(label)
end
local mode=control("Run mode card");mode:SetChecked(false);click(mode)
assert(not R.frame:IsShown());checkStack()
local point,relative,rp,x,y=FieldKitMeterFrame:GetPoint();assert(y==0)
mode:SetChecked(true);click(mode);checkStack()
local values=control("Damage meter values");click(values);click(values.choiceButtons[1]);checkStack()
assert(FieldKitDB.pos.FieldKitMeterFrame[1]==legacyX and FieldKitDB.pos.FieldKitMeterFrame[2]==legacyY)

-- Dragging any member in layout mode moves the same anchor, not one card.
FieldKit.layoutEditing=true;this=FieldKitLairFrame;FieldKitLairFrame:GetScript("OnDragStart")()
assert(S.root.azsMoving and not FieldKitLairFrame.azsMoving)
FieldKitLairFrame:GetScript("OnDragStop")();FieldKit.layoutEditing=false
assert(not S.root.azsMoving)
assert(FieldKitDB.pos.FieldKitMeterFrame[1]==legacyX)

local align=control("Align left HUD cards");align:SetChecked(false);click(align)
assert(not S.linked and FieldKitMeterFrame:GetPoint()=="CENTER")
assert(FieldKitDB.pos.FieldKitMeterFrame[1]==legacyX and FieldKitDB.pos.FieldKitMeterFrame[2]==legacyY)
align:SetChecked(true);click(align);checkStack()

AZS_ZONE.heroic=5;update(FieldKitFrame,.3)
assert(R.frame.total:GetText()=="Heroic V")
assert(R.frame.rows[8].label:GetText()=="Active affixes: not provided")
local originalWidth,originalHeight=UIParent.width,UIParent.height
UIParent.width=800;UIParent.height=600;S.Apply()
local _,_,_,sx,sy=S.root:GetPoint()
assert(sx>=-400+12 and sx+S.width<=400-12)
assert(sy<=300-12 and sy-S.height>=-300+12)
UIParent.width=originalWidth;UIParent.height=originalHeight;S.Apply()
AZS_ZONE.heroic=nil;update(FieldKitFrame,.3)
assert(R.frame.total:GetText()=="Mode not provided" and R.frame.mashVisibleRows==2)
AZS_ZONE.heroic=0;update(FieldKitFrame,.3)
assert(R.frame.total:GetText()=="Normal difficulty" and R.frame.rows[2].label:GetText()=="Normal zone rules.")
AZS_RUN.ph=nil;update(FieldKitFrame,.3)
assert(not R.frame:IsShown() and S.height==0)
