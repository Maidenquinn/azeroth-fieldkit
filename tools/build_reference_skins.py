"""Encode approved, information-free HUD artwork into native texture tiles.

Image editing is performed with the image tool. This exporter only packs
unchanged RGBA regions into power-of-two TGA containers for the native client.
The JSON regions are the independently movable UI components, in reference pixels.
"""
from pathlib import Path
import json, hashlib
from PIL import Image

base=Path(__file__).resolve().parent.parent
source=base/'design/reference-skins'
out=base/'AzerothFieldKit/media/ReferenceHUD'
out.mkdir(parents=True,exist_ok=True)
layouts=json.loads((source/'layouts.json').read_text(encoding='utf-8'))
media_path=base/'data/theme-assets.json'
media=json.loads(media_path.read_text(encoding='utf-8'))
art={}
generated_paths=set()
def pot(n):
    p=1
    while p<n:p*=2
    return p
def lua(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    return str(v).lower()
for key,layout in layouts.items():
    path=source/(key+'_v3.png' if key in ('naxx_minimal','naxx_alternative','elwynn_alternative') else key+'.png')
    if not path.exists():continue
    im=Image.open(path).convert('RGBA')
    assert im.height==layout['size'][1] and abs(im.width-layout['size'][0])<=1,(key,im.size,layout['size'])
    # A one-pixel output-width drift is transparent-padded by crop/packing, never resampled.
    record=dict(layout);record['tiles']={}
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    for component,rect in layout['rects'].items():
        x,y,w,h=rect;parts=[]
        region=im.crop((x,y,x+w,y+h))
        # Dock rectangles include the characters' outstretched silhouettes.
        # They also intersect a few pixels of neighbouring independent panels.
        # Remove those foreign rectangles from this component so resizing it
        # cannot carry an orphan strip of the equipment/effects/chat panel.
        if component=='dock':
            for other,foreign in layout['rects'].items():
                if other not in ('Damage','Lairs','Accessories','Stats','Effects','chat','nav'):continue
                fx,fy,fw,fh=foreign
                left,top,right,bottom=max(x,fx),max(y,fy),min(x+w,fx+fw),min(y+h,fy+fh)
                if right>left and bottom>top:region.paste((0,0,0,0),(left-x,top-y,right-x,bottom-y))
        for dy in range(0,h,512):
            for dx in range(0,w,512):
                iw,ih=min(512,w-dx),min(512,h-dy)
                tile=Image.new('RGBA',(pot(iw),pot(ih)),(0,0,0,0))
                tile.paste(region.crop((dx,dy,dx+iw,dy+ih)),(0,0))
                name=f'{key}_{component}_{len(parts)+1}'+('_v3.tga' if key in ('naxx_minimal','naxx_alternative','elwynn_alternative') else '.tga')
                target=out/name;tile.save(target);generated_paths.add(target.name)
                media['files']['media/ReferenceHUD/'+name]={'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'source':'Information-free artwork extracted with image tool from approved concept; mechanically cropped and packed without resampling. Dock excludes intersecting independent panel rectangles for separate scaling. All text, live bars, map and action icons are native components.','sourcePngSha256':digest}
                parts.append([name,dx,dy,iw,ih,tile.width,tile.height])
        record['tiles'][component]=parts
    art[key]=record
# Mechanical nine-slice packing from the approved settings perimeter.
for zone in ('elwynn','naxx'):
    layout=layouts[zone+'_complete'];x,y,w,h=layout['rects']['Accessories']
    im=Image.open(source/(zone+'_complete.png')).convert('RGBA').crop((x,y,x+w,y+h))
    im=im.crop(im.getchannel('A').point(lambda n:255 if n>220 else 0).getbbox());w,h=im.size
    tile=Image.new('RGBA',(512,512));cuts=[0,12,500,512];sx=[0,12,w-12,w];sy=[0,12,h-12,h]
    for iy in range(3):
        for ix in range(3):
            region=im.crop((sx[ix],sy[iy],sx[ix+1],sy[iy+1])).resize((cuts[ix+1]-cuts[ix],cuts[iy+1]-cuts[iy]))
            tile.paste(region,(cuts[ix],cuts[iy]))
    target=out/(zone+'_material_v3.tga');tile.save(target);generated_paths.add(target.name)
    media['files']['media/ReferenceHUD/'+target.name]={'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'source':'Mechanical nine-slice packing of the approved equipment-panel perimeter; live widgets supply all labels and values.'}
# Small illustrative previews are encoded separately and never used as live HUD.
concepts=source/'approved'
for zone,folder,prefix in [('elwynn','01_Foret_Elwynn','Foret_Elwynn'),('naxx','13_Naxxramas','Naxxramas')]:
    for variant,label in [('minimal','Minimaliste'),('complete','Complete'),('alternative','Alternative')]:
        im=Image.open(concepts/(zone+'_'+variant+'.png')).convert('RGBA')
        d=layouts[zone+'_'+variant];x,y,w,h=d['rects']['dock']
        # Include the adjacent world solely as an explicitly named concept preview.
        box=(max(0,x),max(0,y-90),min(im.width,x+w),min(im.height,y+h))
        thumb=im.crop(box).resize((256,128));target=out/(zone+'_'+variant+'_preview.tga');thumb.save(target);generated_paths.add(target.name)
        media['files']['media/ReferenceHUD/'+target.name]={'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'source':'Illustrative thumbnail of the user-approved concept; contains example values and is labelled as a concept preview in settings, never used for live information.'}
widgets=Image.open(source/'settings_widgets.png').convert('RGBA')
for i,name in enumerate(('elwynn_seal_v3','naxx_seal_v3','elwynn_thumb_v3','naxx_thumb_v3')):
    cell=widgets.crop((i*widgets.width//4,0,(i+1)*widgets.width//4,widgets.height))
    cell=cell.crop(cell.getchannel('A').point(lambda n:255 if n>120 else 0).getbbox())
    cell.thumbnail((112,112));tile=Image.new('RGBA',(128,128));tile.paste(cell,((128-cell.width)//2,(128-cell.height)//2))
    target=out/(name+'.tga');tile.save(target);generated_paths.add(target.name)
    media['files']['media/ReferenceHUD/'+target.name]={'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'source':'Image-tool extraction from approved settings references, mechanically packed into a native texture.'}
# Retire only obsolete generated files already recorded in this manifest.
retired_path=base/'build/reference-retired.json'
retired=json.loads(retired_path.read_text(encoding='utf-8')) if retired_path.exists() else []
for relative in list(media['files']):
    if relative.startswith('media/ReferenceHUD/') and Path(relative).name not in generated_paths:
        target=(base/'AzerothFieldKit'/relative).resolve()
        assert target.parent==out.resolve() and target.suffix=='.tga'
        if target.exists():target.unlink()
        if relative not in retired:retired.append(relative)
        del media['files'][relative]
(base/'build').mkdir(exist_ok=True)
(base/'build/reference-retired.json').write_bytes((json.dumps(retired,indent=2)+'\n').encode('utf-8'))
media_path.write_bytes((json.dumps(media,indent=2)+'\n').encode('utf-8'))
(base/'AzerothFieldKit/ReferenceArt.lua').write_bytes(('-- Generated texture geometry; no executable dynamic loading.\nFieldKitReferenceArt='+lua(art)+'\n').encode('utf-8'))
print('Encoded reference skins:',', '.join(art))
