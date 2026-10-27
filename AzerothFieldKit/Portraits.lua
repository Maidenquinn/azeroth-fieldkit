-- Static portraits rendered from the installed client's M2 + CreatureDisplayInfo skins.
-- Instance ids in AZS_UNITS are NOT creature/display ids. See PORTRAITS.txt.
MASH_Portraits = { last = {}, catalog = MASH_PortraitCatalog or {} }
local P = MASH_Portraits
function P.Apply(frame,name,kind,id)
 local zone=type(AZS_ZONE)=="table" and AZS_ZONE.zone
 local data=P.catalog[zone] and P.catalog[zone][name]
 local path="Interface\\Icons\\INV_Misc_QuestionMark"
 local reason=MASH_L("appearance not identified")
 if data and zone==data.zone then
  local matches=0
  if type(AZS_UNITS)=="table" then
   for i=1,table.getn(AZS_UNITS) do
    local u=AZS_UNITS[i]
    if (u.name or u[3])==name then matches=matches+1 end
   end
  end
  -- The verified native definitions have one display per entry. Several
  -- guardian instances of that entry can coexist; their instance ids remain separate.
  local conflict=false
  if type(AZS_UNITS)=="table" then
   for i=1,table.getn(AZS_UNITS) do
    local u=AZS_UNITS[i]
    if (u.id or u[2])==id then
     local supplied=tonumber(u.displayId or u.display)
     if supplied and supplied~=data.display then conflict=true end
    end
   end
  end
  if conflict then reason=MASH_L("explicit display conflicts with verified catalog")
  elseif matches<=1 or data.sharedAppearance then
   path="Interface\\AddOns\\MASH\\Portraits\\"..data.key;reason=MASH_L("native static render; entry=")..data.entry..MASH_L(" display=")..data.display.." instances="..matches
  else reason=MASH_L("duplicate name: appearance not verified as shared") end
 elseif data then reason=MASH_L("zone unavailable or outside verified portrait catalog") end
 if frame.mashPortraitPath~=path then frame.portrait:SetTexture(path);frame.mashPortraitPath=path end
 frame.mashPortraitReason=reason
 frame.mashPortraitIdentity=tostring(zone)..":"..tostring(kind)..":"..tostring(id)
 P.last={name=name,id=id,zone=zone,path=path,reason=reason,display=data and data.display}
end
SLASH_MASHPORTRAIT1="/mashportrait"
SlashCmdList["MASHPORTRAIT"]=function(msg)
 if msg=="coverage" and DEFAULT_CHAT_FRAME then
  local c=MASH_PortraitCatalogInfo
  DEFAULT_CHAT_FRAME:AddMessage(MASH_L("MASH portraits: ")..c.bosses..MASH_L(" scheduled bosses + ")..c.guardians..MASH_L(" elite/guardian definitions on ")..c.zones..MASH_L(" maps. Static native renders; game validation remains map by map."))
 end
 if not DEFAULT_CHAT_FRAME then return end
 for i=1,4 do
  local f=getglobal("MASHBossFrame"..i)
  if f and f:IsShown() then DEFAULT_CHAT_FRAME:AddMessage(MASH_L("MASH portrait ")..i..": "..tostring(f.mashPortraitIdentity)..MASH_L(" texture=")..tostring(f.mashPortraitPath)..MASH_L(" source=")..tostring(f.mashPortraitReason)) end
 end
 local d=P.last
 DEFAULT_CHAT_FRAME:AddMessage(MASH_L("MASH portrait: ")..tostring(d.name)..MASH_L(" display=")..tostring(d.display)..MASH_L(" source=")..tostring(d.reason)..MASH_L(" zone=")..tostring(d.zone))
end
