"""Derive the "frame matte" of each approved card art tile (Damage, Lairs, Accessories, Stats, Effects; Elwynn and Naxx).

The card tiles bake the dark body AND the gold border / ornaments / rules in one texture, so the "panel opacity" setting could only fade
the whole tile (border included). The matte keeps what is NOT the dark body: every pixel is split into body colour and a foreground by a
difference matte against the tile's own body colour (median of its opaque centre), alpha = clamp((distance - LO) / (HI - LO)), colour
recovered as body + (pixel - body) / alpha. The card then draws the original tile at the panel opacity and the matte on top at full
opacity: at 100 % the card is the approved art; at 0 % only the gold frame, ornaments and rules remain; text and icons are separate objects.
Nothing is invented: every matte pixel colour is derived from the approved tile.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image

base = Path(__file__).resolve().parent.parent
out = base / 'AzerothFieldKit/media/ReferenceHUD'
NAMES = ['elwynn_complete_Accessories_1', 'elwynn_complete_Damage_1', 'elwynn_complete_Effects_1', 'elwynn_complete_Lairs_1', 'elwynn_complete_Stats_1',
         'naxx_complete_Accessories_1', 'naxx_complete_Damage_1', 'naxx_complete_Effects_1', 'naxx_complete_Lairs_1', 'naxx_complete_Stats_1']
LO, HI = 16.0, 52.0
manifest = base / 'data/theme-assets.json'
m = json.loads(manifest.read_text(encoding='utf-8'))
for name in NAMES:
    im = np.array(Image.open(out / (name + '.tga')).convert('RGBA')).astype(np.float64)
    a0 = im[..., 3] / 255.0
    h, w = a0.shape
    cy0, cy1, cx0, cx1 = int(h * .3), int(h * .7), int(w * .3), int(w * .7)
    centre = im[cy0:cy1, cx0:cx1]
    opaque = centre[..., 3] > 250
    body = np.median(centre[opaque][:, :3], axis=0)
    dist = np.abs(im[..., :3] - body).max(axis=2)
    alpha = np.clip((dist - LO) / (HI - LO), 0, 1) * a0
    safe = np.maximum(alpha, 1e-3)[..., None]
    fg = np.clip(body + (im[..., :3] - body) / safe, 0, 255)
    rgb = np.where(alpha[..., None] > 0, fg, 0)
    tile = np.dstack([rgb, alpha * 255]).round().astype('uint8')
    target = out / (name + '_frame.tga')
    Image.fromarray(tile, 'RGBA').save(target)
    raw = target.read_bytes()
    m['files']['media/ReferenceHUD/' + target.name] = {
        'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw),
        'source': 'Frame matte of ' + name + '.tga derived by tools/build_card_frame_matte.py (difference matte against the tile body colour); every colour comes from the approved tile.'}
    print(name, 'body', body.round().tolist(), 'opaque fg share', round(float((alpha > .5).mean()), 3))
manifest.write_bytes((json.dumps(m, indent=2) + '\n').encode('utf-8'))
