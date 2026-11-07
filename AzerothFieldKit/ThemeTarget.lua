-- The compact target reads native units. Hover reveals the complete original
-- target frame (auras, portrait and native interactions); casting stays native.
FieldKitThemeTarget={}
local C=FieldKitThemeTarget
local H=FieldKitThemeHUD
local T=FieldKitTheme
function C.Create()
 if C.frame then return end
 local f=CreateFrame("Button","FieldKitThemeTargetFrame",UIParent);C.frame=f
 f:SetWidth(300);f:SetHeight(75);f:SetFrameStrata("HIGH");T.Surface(f,"card",true)
 C.name=T.Label(f,"",10,4,280,24,14,T.gold,true)
 C.kind=T.Label(f,"",10,50,280,20,11,T.muted)
 C.bar=CreateFrame("StatusBar",nil,f);C.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 C.bar:SetStatusBarColor(.75,.2,.24);C.bar:SetPoint("TOPLEFT",f,"TOPLEFT",10,-31);C.bar:SetWidth(280);C.bar:SetHeight(16)
 local bg=C.bar:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(C.bar);T.Solid(bg,{.12,.04,.06})
 C.hp=T.Label(C.bar,"",0,0,280,16,11,T.text);C.hp:SetJustifyH("CENTER")
 f:RegisterForClicks("LeftButtonUp","RightButtonUp")
 f:SetScript("OnClick",function()
  local source=getglobal("TargetFrame");local callback=source and (source:GetScript("OnClick") or source:GetScript("OnMouseUp"))
  if callback then local previous=this;this=source;pcall(callback);this=previous end
 end)
 f:SetScript("OnEnter",function() C.details=true;C.untilTime=GetTime()+.35 end)
 f:SetScript("OnLeave",function() C.untilTime=GetTime()+.25 end)
 FieldKitZoneThemes.Bind(f)
end
function C.Stop()
 if C.frame then C.frame:Hide() end
 C.details=false
 local native=getglobal("TargetFrame");local saved=native and H.saved[native]
 if saved then
  if native:GetParent()==saved.parent or native:GetParent()==H.storage then H.RestoreOne(native)
  else if native:GetAlpha()==0 then native:SetAlpha(saved.alpha) end;H.saved[native]=nil end
 end
 local cast=getglobal("TargetFrameSpellBar")
 if cast and H.saved[cast] and cast:GetParent()==C.castOwner then H.RestoreOne(cast) end;C.castOwner=nil
end
function C.Update(variant)
 local native=getglobal("TargetFrame")
 if not native or type(UnitExists)~="function" or not UnitExists("target") then C.Stop();return end
 local parent=native:GetParent()
 if parent and parent~=UIParent and parent~=H.storage then C.reason="Another addon owns the target frame";C.Stop();return end
 local hp,max=FieldKit.Number(UnitHealth("target")),FieldKit.Number(UnitHealthMax("target"))
 if not hp or not max or max<=0 then C.reason="Native data unavailable";C.Stop();return end
 C.Create();C.reason=nil
 local matchedBoss
 if FieldKitReferenceHUD and FieldKitReferenceHUD.active then
  for i=1,4 do local boss=getglobal("FieldKitBossFrame"..i.."Compact")
   if boss and boss:IsShown() and boss.name and boss.name:GetText()==UnitName("target") then matchedBoss=boss end
  end
 end
 local f=C.frame;if not f.azsMoving then f:SetScale(math.min(1,UIParent:GetWidth()/1300)*FieldKitZoneThemes.ElementScale("FieldKitThemeTargetFrame")) end
 local mapLeft=(T.zone=="elwynn" and variant=="complete") or (T.zone=="naxx" and variant=="alternative")
 if FieldKitReferenceHUD and FieldKitReferenceHUD.active then
  local boss=getglobal("FieldKitBossFrame1Compact") or getglobal("FieldKitBossFrame1");local y=(boss and boss:IsShown() and boss:GetAlpha()>0) and -195 or -96
  FieldKitZoneThemes.Place(f,"TOP",UIParent,"TOP",0,y/(f:GetScale() or 1),true)
 elseif mapLeft or variant=="alternative" then FieldKitZoneThemes.Place(f,"TOP",UIParent,"TOP",0,-86)
 else FieldKitZoneThemes.Place(f,"TOPLEFT",UIParent,"TOPLEFT",22,-92) end
 C.name:SetText(FieldKitNative.Text(UnitName("target")))
 local level=UnitLevel("target");local classification=type(UnitClassification)=="function" and UnitClassification("target")
 local names={elite="Elite",rareelite="Rare elite",rare="Rare",worldboss="Boss",normal="Target"}
 C.kind:SetText(FieldKit_L(names[classification] or "Target").." · "..tostring(level and level>0 and level or "??").." · "..FieldKit_L("Hover for native details"))
 C.bar:SetMinMaxValues(0,max);C.bar:SetValue(hp);C.hp:SetText(FieldKit_FormatHealth(hp,max,FieldKitDB.targetHealthMode))
 if FieldKitReferenceHUD and FieldKitReferenceHUD.active then FieldKitReferenceHUD.Fit(C.name,14,11);FieldKitReferenceHUD.Fit(C.kind,11,10);FieldKitReferenceHUD.Fit(C.hp,11,10) end
 H.Save(native);H.Anchor(native,"TOPLEFT",f,"BOTTOMLEFT",0,-4)
 native:SetFrameStrata("DIALOG")
 local over=type(MouseIsOver)=="function" and (MouseIsOver(f) or (matchedBoss and MouseIsOver(matchedBoss)) or (C.details and native:GetAlpha()>0 and MouseIsOver(native)))
 if matchedBoss and type(MouseIsOver)=="function" and MouseIsOver(matchedBoss) then C.details=true end
 local show=C.details and (over or GetTime()<(C.untilTime or 0))
 local wasStored=native:GetParent()==H.storage
 native:SetParent(show and H.saved[native].parent or H.Hidden());native:SetAlpha(show and H.saved[native].alpha or 0)
 if show and wasStored and native:IsShown() then native:Hide();native:Show() end
 if not show then C.details=false end
 local cast=getglobal("TargetFrameSpellBar")
 if cast and (cast:GetParent()==UIParent or cast:GetParent()==native or cast:GetParent()==f or cast:GetParent()==C.castOwner) then
  local owner=matchedBoss or f;H.Save(cast);cast:SetParent(owner);C.castOwner=owner;H.Anchor(cast,"TOP",owner,"BOTTOM",0,-6,true);cast:SetWidth(280)
 end
 if matchedBoss then f:Hide() else f:Show() end;T.Update(f)
end
