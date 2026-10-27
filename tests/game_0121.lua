-- Contract tests based on the installed 0.121.0 client's exposed native strings.
-- Synthetic inputs exercise actual UI and filter callbacks, not a live game run.
FieldKitDB={}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
AZS_RUN.ph="playing";AZS_ZONE.heroic=5
assert(FieldKit.GetHeroicLabel()=="Heroic V")
update(FieldKitPanel,.3);assert(string.find(FieldKitUI.subtitle:GetText(),"Heroic V",1,true))
FieldKit_SetLanguage("fr");assert(FieldKit.GetHeroicLabel()=="Héroïque V")
FieldKit_SetLanguage("en")
AZS_ZONE.heroic=0;assert(FieldKit.GetHeroicLabel()=="Normal difficulty")
AZS_ZONE.heroic=nil;AZS_ZONE.diff=5
assert(FieldKit.GetHeroicLevel()==nil,"Zone multiplier must never imply Heroic V")
AZS_ZONE.heroic=6;assert(FieldKit.GetHeroicLevel()==nil)
AZS_ZONE.heroic=2.5;assert(FieldKit.GetHeroicLevel()==nil)
AZS_ZONE.heroic=5;AZS_RUN.ph=nil
assert(FieldKit.GetHeroicLabel()==nil,"Do not display retained run difficulty")
AZS_RUN.ph="playing"

assert(FieldKit.FormatPercent(.003,true)=="+0.3%")
assert(FieldKit.FormatBonus(.3)=="0.3" and FieldKit.FormatBonus(1)=="1")
assert(FieldKit.FormatPercent(.003,false)=="0.3%")
assert(FieldKit.FormatPercent(.10,true)=="+10%")
assert(FieldKit.FormatPercent(-.00001,true)=="+0%")
AZS_STATS={dmg=1.003,cd=.997,crit=.003,cm=2.35,luck=.003,xp=1.003,gold=1.003,lch=.003,heal=1}
AZS_STATS_UPDATED=NOW+1;update(FieldKitFrame,.3)
local damage=false
for i=1,table.getn(FieldKitStatsFrame.rows) do
 local row=FieldKitStatsFrame.rows[i]
 if row.label:GetText()=="Damage" then assert(row.value:GetText()=="+0.3%");damage=true end
end
assert(damage)

-- Council: a final and a returning earlier boss coexist, independently of target.
FieldKitDB.bossFrame=true;TARGET="Unrelated enemy"
AZS_UNITS={{kind="final",id=101,name="Zevrim Sabot-de-ronce",hp=100,hpm=100,state=0},
 {kind="boss",id=102,name="Brute gordunni",hp=80,hpm=100,state=0}}
AZS_UNITS_UPDATED=NOW+2;update(FieldKitFrame,.3)
assert(FieldKitBossFrame1:IsShown() and FieldKitBossFrame2:IsShown())
assert(FieldKitBossFrame1.name:GetText()=="Zevrim Sabot-de-ronce")
assert(FieldKitBossFrame2.name:GetText()=="Brute gordunni")

-- Actual ordinary-enemy filtering must preserve critical objective nameplates.
local function plate(name)
 local p=CreateFrame("Button",nil,WorldFrame)
 local border=p:CreateTexture(nil,"BORDER");border:SetTexture("Interface\\Tooltips\\Nameplate-Border")
 local text=p:CreateFontString(nil,"OVERLAY");text:SetText(name)
 local level=p:CreateFontString(nil,"OVERLAY");level:SetText("1")
 function p:GetRegions() return border,text,level end
 return p,text
end
local orb,en=plate("Explosive Orb");local orbfr,fr=plate("Orbe explosif");local mob,normal=plate("Ordinary mob")
function WorldFrame:GetChildren() return orb,orbfr,mob end
function WorldFrame:GetNumChildren() return 3 end
FieldKitDB.hidePlates=true;FieldKitDB.hideUnknown=true;NAMEPLATES_ON=true
FieldKitDB.known["Explosive Orb"]="normal";FieldKitDB.known["Orbe explosif"]="normal";FieldKitDB.known["Ordinary mob"]="normal"
for i=1,5 do NOW=NOW+.3;update(FieldKitFrame,.3) end
assert(en:GetAlpha()==1 and fr:GetAlpha()==1 and normal:GetAlpha()==0)
assert(orb:GetParent()==UIParent and orbfr:GetParent()==UIParent)
NAMEPLATES_ON=false;update(FieldKitFrame,.3)
assert(en:GetAlpha()==0 and fr:GetAlpha()==0,"Respect the player's V-key state")
FieldKitDB.hidePlates=false;update(FieldKitFrame,.3)
assert(orb:GetParent()==WorldFrame and orbfr:GetParent()==WorldFrame)
