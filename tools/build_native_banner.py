"""Derive the Elwynn banner of the NATIVE map presentation from the approved card frame (elwynn_complete_Effects_1.tga).

The banner is built from the real pixels of the approved HUD cards, so it carries the same worked gold frame, the same corner ornaments
(chamfered corner with its triangular plate and stud) and the same dark green body as the other cards: nothing is redrawn.

elwynn_banner.tga  128 x 64, three pieces side by side, each 50 px high:
    x 0..25    left cap   = top-left corner (25 x 25) over bottom-left corner (25 x 25)
    x 32..48   middle     = a 16 px chunk of the top edge over the same chunk of the bottom edge, with the approved clean card body between
                            the two frame lines (stretched horizontally by the game: uniform)
    x 64..89   right cap  = top-right corner over bottom-right corner
The game draws a banner of any width W >= 66 as  left cap | middle stretched to W - 50 | right cap  (no corner is ever scaled).
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image

base = Path(__file__).resolve().parent.parent
out = base / 'AzerothFieldKit/media/ReferenceHUD'
src = Image.open(out / 'elwynn_complete_Effects_1.tga').convert('RGBA')
W0, H0 = 361, 116                      # the card art inside its 512 x 128 texture
C = 25                                 # corner size
tile = src.crop((0, 0, W0, H0))
def piece(box): return tile.crop(box)
tl, tr = piece((0, 0, C, C)), piece((W0 - C, 0, W0, C))
bl, br = piece((0, H0 - C, C, H0)), piece((W0 - C, H0 - C, W0, H0))
MX = 200                                # a plain stretch of the edges (no icon, no rule): x 200..216
mt, mb = piece((MX, 0, MX + 16, C)), piece((MX, H0 - C, MX + 16, H0))
sheet = Image.new('RGBA', (128, 64), (0, 0, 0, 0))
sheet.paste(tl, (0, 0)); sheet.paste(bl, (0, C))
sheet.paste(mt, (32, 0)); sheet.paste(mb, (32, C))
sheet.paste(tr, (64, 0)); sheet.paste(br, (64, C))
# The edges of the card sit next to its header band, whose shadow is darker than the card body: the middle piece takes the approved clean
# body of the cards (elwynn_card_body_v9.tga) between the two gold frame lines (rows 12..37), so the banner reads like the other cards.
body = Image.open(out / 'elwynn_card_body_v9.tga').convert('RGBA').resize((16, 26), Image.BILINEAR)
sheet.paste(body, (32, 12))
target = out / 'elwynn_banner.tga'
sheet.save(target)
manifest = base / 'data/theme-assets.json'
m = json.loads(manifest.read_text(encoding='utf-8'))
raw = target.read_bytes()
m['files']['media/ReferenceHUD/' + target.name] = {
    'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw),
    'source': 'Pixels of the approved elwynn_complete_Effects_1 card frame (four corners and a plain stretch of the top and bottom edges), packed without resampling by tools/build_native_banner.py.'}
# the generated cartouche of alpha.45/46 is replaced
old = out / 'elwynn_cartouche.tga'
if old.exists(): old.unlink()
m['files'].pop('media/ReferenceHUD/elwynn_cartouche.tga', None)
manifest.write_bytes((json.dumps(m, indent=2) + '\n').encode('utf-8'))
print('banner sheet written', len(raw), 'bytes')
