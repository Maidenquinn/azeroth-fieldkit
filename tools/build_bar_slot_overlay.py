"""Derive the life-bar slot ring overlay from the approved Elwynn vitality art.

The ring (gold border, its anti-aliasing and the rounded corners) is copied unchanged from
elwynn_complete_vitality_1.tga; only the INTERIOR of the slot (the opening the green fill must show through) is made
transparent. Drawn above the StatusBar at 1:1, the real corner radius of the art clips the fill exactly.
Nothing is invented: every opaque pixel is a pixel of the approved art.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image

base=Path(__file__).resolve().parent.parent
out=base/'AzerothFieldKit/media/ReferenceHUD'
src=Image.open(out/'elwynn_complete_vitality_1.tga').convert('RGBA')
# crop box in art pixels (texture is the 360 x 135 art at 1:1): the slot with its ring and a margin
X0,Y0,W,H=130,53,200,30
crop=np.array(src.crop((X0,Y0,X0+W,Y0+H))).astype(int)
lum=crop[:,:,:3].mean(axis=2)
dark=lum<=32
# flood fill the interior from the slot centre over dark pixels (the gold ring, lum > 32, closes the region)
seed=(230-X0,70-Y0)
mask=np.zeros(dark.shape,bool);stack=[(seed[1],seed[0])]
while stack:
    y,x=stack.pop()
    if y<0 or x<0 or y>=H or x>=W or mask[y,x] or not dark[y,x]:continue
    mask[y,x]=True;stack+= [(y+1,x),(y-1,x),(y,x+1),(y,x-1)]
# Rows that only touch the interior through a few anti-aliased pixels of the ring (the ring row at the bottom has two dark pixels at
# the right end) are not interior: keep them opaque, otherwise the fill shows as a speck on the gold.
widest=int(mask.sum(axis=1).max())
for row in range(H):
    if 0<mask[row].sum()<0.5*widest:mask[row,:]=False
ys,xs=np.where(mask)
bbox=(int(xs.min())+X0,int(ys.min())+Y0,int(xs.max())+X0+1,int(ys.max())+Y0+1)
area=int(mask.sum())
rect_area=(bbox[2]-bbox[0])*(bbox[3]-bbox[1])
# the interior must be the slot (a rounded rectangle), not the whole body: it must be bounded and nearly rectangular
assert 150<=bbox[2]-bbox[0]<=200 and 14<=bbox[3]-bbox[1]<=30 and area>=rect_area*0.90,(bbox,area,rect_area)
# overlay: the art pixels, interior transparent; texture 256 x 32 (power of two), art placed at its top-left
over=crop.copy().astype('uint8')
over[mask,3]=0
tile=Image.new('RGBA',(256,32),(0,0,0,0));tile.paste(Image.fromarray(over,'RGBA'),(0,0))
target=out/'elwynn_complete_vitality_slot_overlay.tga';tile.save(target)
manifest=base/'data/theme-assets.json';m=json.loads(manifest.read_text(encoding='utf-8'))
raw=target.read_bytes()
m['files']['media/ReferenceHUD/'+target.name]={'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'source':'Pixels of the approved elwynn_complete_vitality_1 art (slot ring, unchanged); the slot interior is made transparent by tools/build_bar_slot_overlay.py.'}
manifest.write_bytes((json.dumps(m,indent=2)+'\n').encode('utf-8'))
print('interior bbox (art px) x',bbox[0],bbox[2],'y',bbox[1],bbox[3],'size',bbox[2]-bbox[0],'x',bbox[3]-bbox[1],'interior pixels',area,'of',rect_area)
print('overlay origin in art px',X0,Y0,'size',W,H,'texture 256x32 ->',target.name)
