-- Chroniques d'Azeroth visual family, adapted from the maintainer's Azeroth Stats.
-- Fixed bundled assets only; no dependency on another installed addon.
FieldKitTheme={media="Interface\\AddOns\\AzerothFieldKit\\media\\",
 background={.063,.09,.106},panel={.094,.129,.149},gold={.85,.71,.42},
 bronze={.54,.44,.27},text={.94,.91,.83},muted={.65,.70,.70},
 green={.61,.77,.57},red={.91,.40,.37}}
local T=FieldKitTheme
T.surfaces={}

-- Display preferences affect only our material layers, never frame/text alpha.
function T.Style() return FieldKitDB and FieldKitDB.cardStyle==2 and 2 or 1 end
function T.Opacity()
 return FieldKit.Number(FieldKitDB and FieldKitDB.cardOpacity,100,0,100)/100
end
function T.Refresh()
 for i=1,table.getn(T.surfaces) do
  local frame=T.surfaces[i];T.State(frame,frame.fieldkitActive);T.Update(frame)
 end
end

-- Keep headings and body type consistent; the native face is a safe fallback.
function T.Font(label,size,color,heading)
 local path=T.media..(heading and "AzerothSerif.ttf" or "AzerothSans.ttf")
 local ok,result=pcall(label.SetFont,label,path,size or 14,"")
 if not ok or result==false then label:SetFont(heading and "Fonts\\FRIZQT__.TTF" or "Fonts\\ARIALN.TTF",size or 14,"") end
 color=color or T.text;label:SetTextColor(color[1],color[2],color[3])
end

-- Explicit dimensions avoid this client's custom-backdrop tiling/stretch quirks.
function T.Update(frame)
 if not frame.fieldkitSkin then return end
 local w,h=frame:GetWidth(),frame:GetHeight()
 local skin=frame.fieldkitSkin
 local style=T.Style()
 if skin.width==w and skin.height==h and skin.style==style then return end
 skin.width=w;skin.height=h;skin.style=style
 skin.base:SetWidth(w);skin.base:SetHeight(h);skin.grain:SetWidth(w);skin.grain:SetHeight(h)
 local c=math.min(skin.kind=="window" and 18 or (skin.kind=="card" and 10 or 6),w/3,h/3)
 local xs,ys={0,c,w-c},{0,c,h-c}
 if style==2 then
  -- Four one-pixel solid edges; remaining ornate slices stay hidden.
  local edges={{0,0,w,1},{0,h-1,w,1},{0,0,1,h},{w-1,0,1,h}}
  for i=1,4 do
   local t=skin.parts[i].texture;local e=edges[i]
   t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",e[1],-e[2]);t:SetWidth(e[3]);t:SetHeight(e[4])
  end
  return
 end
 for i=1,table.getn(skin.parts) do
  local p=skin.parts[i];local x,y=p.x,p.y
  p.texture:ClearAllPoints();p.texture:SetPoint("TOPLEFT",frame,"TOPLEFT",xs[x],-ys[y])
  p.texture:SetWidth(x==2 and math.max(1,w-2*c) or c)
  p.texture:SetHeight(y==2 and math.max(1,h-2*c) or c)
 end
end

-- Build nine owned material slices once; do not skin native/game-owned frames.
function T.Surface(frame,kind)
 if frame.fieldkitSkin then T.Update(frame);return end
 kind=kind or "card";frame:SetBackdrop({})
 local skin={kind=kind,parts={}};frame.fieldkitSkin=skin
 table.insert(T.surfaces,frame)
 local color=kind=="card" and T.panel or T.background
 skin.base=frame:CreateTexture(nil,"BACKGROUND");skin.base:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
 skin.base:SetTexture(color[1],color[2],color[3]);skin.base:SetAlpha(1)
 skin.grain=frame:CreateTexture(nil,"BACKGROUND");skin.grain:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
 skin.grain:SetTexture(T.media.."ChronicleGrain.tga");skin.grain:SetAlpha(.16)
 local cuts={0,.07,.93,1}
 for y=1,3 do for x=1,3 do
  local texture=frame:CreateTexture(nil,"BORDER")
  texture:SetTexCoord(cuts[x],cuts[x+1],cuts[y],cuts[y+1])
  if kind=="window" and x==2 and y==2 then texture:Hide() end
  table.insert(skin.parts,{texture=texture,x=x,y=y})
 end end
 T.State(frame,false);T.Update(frame)
end

-- Selection/hover only changes the fixed material, never allocates another layer.
function T.State(frame,active)
 local skin=frame.fieldkitSkin;if not skin then return end
 local alpha=(frame.fieldkitNavigation and not active) and 0 or 1
 local opacity=skin.kind=="button" and 1 or T.Opacity()
 skin.base:SetAlpha(alpha*opacity);skin.grain:SetAlpha(T.Style()==2 and 0 or .16*alpha*opacity)
 local plate=skin.kind=="window" and 4 or (skin.kind=="card" and 3 or (active and 2 or 1))
 for i=1,table.getn(skin.parts) do
  local t=skin.parts[i].texture
  if T.Style()==2 then
   if i<=4 then
    t:Show();t:SetTexture(T.bronze[1],T.bronze[2],T.bronze[3]);t:SetAlpha(alpha)
   else t:Hide() end
   t.fieldkitPlate=nil
  else
   if skin.kind=="window" and i==5 then t:Hide() else t:Show() end
   if t.fieldkitPlate~=plate then t:SetTexture(T.media.."ChroniclePlate"..plate..".tga");t.fieldkitPlate=plate end
   t:SetAlpha(alpha*(i==5 and opacity or 1))
  end
 end
 frame.fieldkitActive=active and true or false
end

-- Native legacy Button with its own visible label; no red template underneath.
function T.Button(parent,name,label,x,y,w,h,callback)
 local b=CreateFrame("Button",name,parent);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
 b:SetWidth(w);b:SetHeight(h or 28);T.Surface(b,"button")
 b.fieldkitLabel=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
 local padding=w<50 and 2 or 10
 b.fieldkitLabel:SetPoint("LEFT",b,"LEFT",padding,0);b.fieldkitLabel:SetWidth(w-2*padding);b.fieldkitLabel:SetHeight(h or 28)
 b.fieldkitLabel:SetJustifyH(w<50 and "CENTER" or "LEFT");b.fieldkitLabel:SetJustifyV("MIDDLE");T.Font(b.fieldkitLabel,w<50 and 11 or 13,T.gold)
 if b.SetFontString then b:SetFontString(b.fieldkitLabel) end
 b.callback=callback
 b:SetScript("OnClick",function() if this.callback then this.callback() end end)
 b:SetScript("OnEnter",function() T.State(this,true) end)
 b:SetScript("OnLeave",function() T.State(this,this.fieldkitSelected) end)
 FieldKit_Text(b,label or "");return b
end

-- Static painted glyph identifiers are shared across the addon family.
function T.Glyph(parent,index,x,y,size)
 local t=parent:CreateTexture(nil,"ARTWORK");t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
 t:SetWidth(size);t:SetHeight(size);t:SetTexture(T.media..string.format("ChronicleGlyph%02d.tga",index))
 return t
end

-- Bound only addon chrome. Game-provided names keep their existing native fonts.
function T.Label(parent,key,x,y,w,h,size,color,heading)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);t:SetWidth(w);t:SetHeight(h or 22)
 t:SetJustifyH("LEFT");t:SetJustifyV("MIDDLE");T.Font(t,size,color,heading)
 if key then FieldKit_Text(t,key) end
 return t
end
