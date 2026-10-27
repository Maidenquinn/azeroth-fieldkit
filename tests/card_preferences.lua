-- Verify the user-facing controls, native observed totals and retained preferences.
local U,T=FieldKitUI,FieldKitTheme
local function control(label)
 for i=1,table.getn(U.controls) do local c=U.controls[i];if c.label==label then return c end end
 error(label)
end
local style,opacity,mode=FieldKitDB.cardStyle,FieldKitDB.cardOpacity,FieldKitDB.meterValues
local original=AZS_GetMeter
local lines={{name="Observed spell",dmg=1234567,dps=8656,share=.39}}
AZS_GetMeter=function() return lines,1234567,8656 end
local display=control("Damage meter values")
local function choose(c,index) click(c);click(c.choiceButtons[index]) end
choose(display,3)
assert(FieldKitMeterFrame.rows[1].value:GetText()=="1234567 | 8656 dps | 39%")
assert(FieldKitMeterFrame:GetWidth()==360)
choose(display,2)
assert(FieldKitMeterFrame.rows[1].value:GetText()=="1234567 | 8656 dps")
assert(FieldKitMeterFrame:GetWidth()==320)
choose(display,1)
assert(FieldKitMeterFrame.rows[1].value:GetText()=="8656 dps | 39%")
assert(FieldKitMeterFrame:GetWidth()==220)
assert(FieldKit_FormatMeterValues({dps=10},3)=="? | 10 dps | ?","Never infer damage from DPS")
assert(FieldKit_FormatMeterValues({dmg=0,dps=0,share=0},3)=="0 | 0 dps | 0%")
assert(lines[1].dmg==1234567 and lines[1].dps==8656)

local appearance=control("Card style");local skin=FieldKitMeterFrame.fieldkitSkin
local count=table.getn(objects)
choose(appearance,2)
for i=1,9 do assert(skin.parts[i].texture:IsShown()==(i<=4)) end
assert(skin.parts[1].texture:GetHeight()==1)
assert(skin.parts[3].texture:GetWidth()==1)
FieldKitDB.cardOpacity=0;T.Refresh()
assert(skin.base:GetAlpha()==0 and skin.grain:GetAlpha()==0)
assert(skin.parts[1].texture:GetAlpha()==1 and FieldKitMeterFrame:GetAlpha()==1)
choose(appearance,1)
assert(skin.parts[5].texture:IsShown() and skin.parts[5].texture:GetAlpha()==0)
assert(skin.parts[1].texture:GetAlpha()==1)
FieldKitDB.cardOpacity=40;T.Refresh()
assert(skin.base:GetAlpha()==.4 and skin.parts[5].texture:GetAlpha()==.4)
for i=1,4 do choose(appearance,2);choose(appearance,1) end
assert(table.getn(objects)==count,"Changing appearance must reuse the skin")
FieldKitDB.cardStyle=style;FieldKitDB.cardOpacity=opacity;FieldKitDB.meterValues=mode
AZS_GetMeter=original;T.Refresh();U.Refresh()
-- The outer reload fixture snapshots these non-default choices.
FieldKitDB.cardStyle=2;FieldKitDB.cardOpacity=37;FieldKitDB.meterValues=2
T.Refresh();U.Refresh()
