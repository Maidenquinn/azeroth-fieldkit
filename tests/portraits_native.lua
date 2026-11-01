-- Explicit addon TGA paths and the two reported arena identities.
fire(FieldKitFrame,"VARIABLES_LOADED")
local P=FieldKit_Portraits
AZS_ZONE={zone=" Arena "};AZS_UNITS_UPDATED=GetTime()
AZS_UNITS={{kind="guardian",id=123,name="Berserker gurubashi"},{kind="boss",id=456,name="Grande prêtresse Jeklik"}}
P.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",123)
P.Apply(FieldKitBossFrame2,AZS_UNITS[2].name,"boss",456)
assert(string.find(FieldKitBossFrame1.mashPortraitPath,"d591.tga",1,true))
assert(string.find(FieldKitBossFrame2.mashPortraitPath,"d15219.tga",1,true))
assert(P.last.zone=="arena")
AZS_UNITS[1].displayId=999;AZS_UNITS_UPDATED=GetTime()+1
P.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",123)
assert(FieldKitBossFrame1.mashPortraitPath=="Interface\\Icons\\INV_Misc_QuestionMark")
AZS_UNITS[1].displayId=nil;AZS_UNITS_UPDATED=GetTime()+2
local set=FieldKitBossFrame1.portrait.SetTexture
FieldKitBossFrame1.portrait.SetTexture=function() return false end
P.Apply(FieldKitBossFrame1,AZS_UNITS[1].name,"guardian",123)
assert(not FieldKitBossFrame1.mashPortraitPath and FieldKitBossFrame1.mashPortraitReason=="Portrait texture rejected by client")
FieldKitBossFrame1.portrait.SetTexture=set
print("Reported arena bosses: canonical native identities, explicit TGA paths, and display conflict guards passed")
