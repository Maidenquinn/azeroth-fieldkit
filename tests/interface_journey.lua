-- End-to-end UI intent tests. These run against the actual addon constructors.
local U=FieldKitUI
assert(U and table.getn(U.sections)==9)
local function page(id)
 for i=1,table.getn(U.pages) do if U.pages[i].section.id==id then return U.pages[i] end end
 error(id)
end
local function check(label)
 for i=1,table.getn(U.controls) do local c=U.controls[i];if c.item and c.item.label==label then return c end end
 error(label)
end
local function choose(c,value) click(c);click(c.choiceButtons[value]) end
local savedMode=FieldKitDB.playerHealthMode
U.Select("home");click(U.homeCards[2].open);assert(FieldKitDB.uiPage=="health")
local health=page("health")
choose(health.flow[2].frame.children[2],3)
assert(FieldKitDB.playerHealthMode==3)
choose(health.flow[2].frame.children[2],2)
assert(FieldKitDB.playerHealthMode==2)
FieldKitDB.playerHealthMode=savedMode

-- Reading, translating and resizing must not write native settings or reload.
local oldReload,oldCVar,oldHud=ReloadUI,SetCVar,AZS_SetHudShown
local reloads,writes=0,0
ReloadUI=function() reloads=reloads+1 end
SetCVar=function() writes=writes+1 end
AZS_SetHudShown=function() writes=writes+1 end
local compact=FieldKitDB.compactBar
U.Select("interface");local control=check("Compact action bar")
control:SetChecked(not compact);click(control)
assert(reloads==0 and U.reloadNeeded)
click(U.reload);assert(reloads==1)
control:SetChecked(compact);click(control);assert(not U.reloadNeeded)
local language=FieldKitDB.language
FieldKit_SetLanguage("en");FieldKit_SetLanguage("fr");FieldKit_SetLanguage(language)
local total=table.getn(objects);local sw,sh=UIParent.width,UIParent.height
UIParent.width=800;UIParent.height=600
for i=1,12 do U.Reflow() end
assert(U.frame:GetWidth()==776 and U.frame:GetHeight()==576)
assert(page("windows").contentHeight>page("windows").scroll:GetHeight())
local viewport=page("windows").scroll
this=viewport;arg1=-100;viewport.scripts.OnMouseWheel()
assert(viewport:GetVerticalScroll()==page("windows"):GetHeight()-viewport:GetHeight())
arg1=100;viewport.scripts.OnMouseWheel();assert(viewport:GetVerticalScroll()==0)
assert(table.getn(objects)==total,"Resize must reuse all widgets")
assert(writes==0,"Read-only UI paths wrote native state")
UIParent.width=sw;UIParent.height=sh;U.Reflow()
ReloadUI=oldReload;SetCVar=oldCVar;AZS_SetHudShown=oldHud

-- Settings do not unlock the HUD. Layout mode does and hides the settings panel.
U.frame:Show();assert(not FieldKit.layoutEditing)
click(U.move);assert(FieldKit.layoutEditing and not U.frame:IsShown() and U.dock:IsShown())
click(U.done);assert(not FieldKit.layoutEditing and U.frame:IsShown() and not U.dock:IsShown())

-- Reset/Undo restores the exact coordinates and detached-money preference.
local previous=FieldKitDB.pos.FieldKitStatsFrame;local detached=FieldKitDB.moneyDetached
FieldKitDB.pos.FieldKitStatsFrame={123,77};FieldKitDB.moneyDetached=true
click(U.reset);assert(U.undoPositions and FieldKitDB.pos.FieldKitStatsFrame[1]~=123)
click(U.undo);assert(FieldKitDB.pos.FieldKitStatsFrame[1]==123 and FieldKitDB.pos.FieldKitStatsFrame[2]==77)
assert(FieldKitDB.moneyDetached==true and not U.undoPositions)
FieldKitDB.pos.FieldKitStatsFrame=previous;FieldKitDB.moneyDetached=detached;U.context.positions()

-- Gold strip can be disabled independently of statistics and remain hidden on ticks.
local money=FieldKitDB.moneyFrame
local moneyControl=check("Gold and chest price");moneyControl:SetChecked(false);click(moneyControl)
update(FieldKitFrame,.4);assert(not FieldKitMoneyFrame:IsShown())
moneyControl:SetChecked(money);click(moneyControl)
U.Select("home")
