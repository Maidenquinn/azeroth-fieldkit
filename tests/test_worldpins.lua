-- World pins: actual world axes, edge direction, state, independent options.
AZS_RUN={ph="playing",t=100,px=100,py=200};AZS_LAIRS_UPDATED=NOW
AZS_CHESTS={{x=110,y=180},{x=100,y=1200},{x="bad",y=3}}
AZS_LAIRS={{name="Same",index=1,state="asleep",x=120,y=180,left=-1},
 {name="Same",index=2,state="awake",x=90,y=210,left=-1},
 {name="Return",state="empty",x=100,y=200,left=180}}
FieldKitDB.chestPins=true;FieldKitDB.guardianPins=true
FieldKit_UpdateWorldPins()
assert(FieldKitChestPin1:IsShown() and FieldKitChestPin1.icon.texture=="Interface\\Icons\\INV_Box_02")
assert(math.abs(FieldKitChestPin1.point[4]-8.4)<.01 and math.abs(FieldKitChestPin1.point[5]-4.2)<.01)
assert(FieldKitChestPin2.edge and FieldKitChestPin2.point[4]==-61)
assert(not FieldKitChestPin3:IsShown())
assert(FieldKitGuardianPin1:IsShown() and FieldKitGuardianPin2:IsShown())
assert(FieldKitGuardianPin1.detail~=FieldKitGuardianPin2.detail)
assert(FieldKitGuardianPin3.timer.text=="3:00" and not FieldKitGuardianPin3.icon:IsShown())
NOW=NOW+1;AZS_LAIRS[3].left=179;AZS_LAIRS_UPDATED=NOW
FieldKit_UpdateWorldPins();assert(FieldKitGuardianPin3.timer.text=="2:59")
FieldKitDB.guardianPins=false;FieldKit_UpdateWorldPins()
assert(not FieldKitGuardianPin1:IsShown() and FieldKitChestPin1:IsShown())
FieldKitDB.guardianPins=true;FieldKitDB.chestPins=false;FieldKit_UpdateWorldPins()
assert(FieldKitGuardianPin1:IsShown() and not FieldKitChestPin1:IsShown())
AZS_LAIRS={};FieldKit_UpdateWorldPins();assert(not FieldKitGuardianPin1:IsShown())
AZS_CHESTS={{x=1000,y=-700}};FieldKitDB.chestPins=true
GetMinimapShape=function() return "SQUARE" end;FieldKit_UpdateWorldPins()
assert(math.abs(FieldKitChestPin1.point[4]-61)<.001 and math.abs(FieldKitChestPin1.point[5]-61)<.001)
GetMinimapShape=nil
Minimap:Hide();FieldKit_UpdateWorldPins();assert(not FieldKitChestPin1:IsShown());Minimap:Show()
AZS_RUN.ph=nil;FieldKit_UpdateWorldPins();assert(not FieldKitChestPin1:IsShown())
AZS_RUN.ph="playing"
-- Persist disabled preference.
FieldKitDB.guardianPins=false
