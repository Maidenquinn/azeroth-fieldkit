"""Derive the "frame matte" and, for the cards that draw their own clean body, the "body tile" of each approved card art tile (Damage, Lairs, Accessories, Stats, Effects; Elwynn and Naxx).

The card tiles bake the dark body AND the gold border / ornaments / rules in one texture, so the "panel opacity" setting could only fade
the whole tile (border included). The matte keeps what is NOT the dark body: every pixel is split into body colour and a foreground by a
difference matte against the tile's own body colour (median of its opaque centre), alpha = clamp((distance - LO) / (HI - LO)), colour
recovered as body + (pixel - body) / alpha. The card then draws the original tile at the panel opacity and the matte on top at full
opacity: at 100 % the card is the approved art; at 0 % only the gold frame, ornaments and rules remain; text and icons are separate objects.
Nothing is invented: every matte pixel colour is derived from the approved tile.

Cards other than Equipment (Damage, Lairs, Stats, Effects) additionally paint a clean dark body (`<zone>_card_body_v9.tga`, a separate
texture) over the interior of the tile (x 17..w-17, y 44..h-16) to hide the decorations baked there (sockets, row outlines). That body
used to stay opaque whatever the setting. For those cards the interior rectangle is therefore REMOVED from both derived textures, so
the panel opacity fades every dark region (the tile's margins and title bar = `<tile>_body.tga`, the clean body, the tab band) and the
frame matte keeps only the gold frame, never a baked row outline.
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
# tile sizes (art px) of the cards that draw the clean body, see R.Update in ReferenceHUD.lua (cleanBody: x 17, y 44, w - 34, h - 60)
CLEAN = {'elwynn_complete_Damage_1': (400, 259), 'elwynn_complete_Lairs_1': (367, 140), 'elwynn_complete_Stats_1': (361, 220), 'elwynn_complete_Effects_1': (361, 116),
         'naxx_complete_Damage_1': (326, 335), 'naxx_complete_Lairs_1': (326, 206), 'naxx_complete_Stats_1': (320, 198), 'naxx_complete_Effects_1': (320, 125)}
manifest = base / 'data/theme-assets.json'
m = json.loads(manifest.read_text(encoding='utf-8'))
for name in NAMES:
    im = np.array(Image.open(out / (name + '.tga')).convert('RGBA')).astype(np.float64)
    a0 = im[..., 3] / 255.0
    h, w = a0.shape
    cy0, cy1, cx0, cx1 = int(h * .3), int(h * .7), int(w * .3), int(w * .7)
    centre = im[cy0:cy1, cx0:cx1]
    opaque = centre[..., 3] > 250
    bodyc = np.median(centre[opaque][:, :3], axis=0)
    dist = np.abs(im[..., :3] - bodyc).max(axis=2)
    alpha = np.clip((dist - LO) / (HI - LO), 0, 1) * a0
    safe = np.maximum(alpha, 1e-3)[..., None]
    fg = np.clip(bodyc + (im[..., :3] - bodyc) / safe, 0, 255)
    rgb = np.where(alpha[..., None] > 0, fg, 0)
    tile = np.dstack([rgb, alpha * 255]).round().astype('uint8')
    outputs = {}
    if name in CLEAN:
        w_, h_ = CLEAN[name]
        tile[44:h_ - 16, 17:w_ - 17, 3] = 0                      # the clean body covers this rectangle
        body = np.array(Image.open(out / (name + '.tga')).convert('RGBA'))
        body[44:h_ - 16, 17:w_ - 17, 3] = 0
        outputs[name + '_body.tga'] = (body, 'Body tile of ' + name + '.tga: the approved tile with the interior rectangle removed (the card draws its own clean body there); derived by tools/build_card_frame_matte.py.')
    outputs[name + '_frame.tga'] = (tile, 'Frame matte of ' + name + '.tga derived by tools/build_card_frame_matte.py (difference matte against the tile body colour' + ('; the clean-body interior removed' if name in CLEAN else '') + '); every colour comes from the approved tile.')
    for fname, (arr, src) in outputs.items():
        target = out / fname
        Image.fromarray(arr, 'RGBA').save(target)
        raw = target.read_bytes()
        m['files']['media/ReferenceHUD/' + fname] = {'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw), 'source': src}
    print(name, 'fg share', round(float((alpha > .5).mean()), 3), 'clean' if name in CLEAN else '')
manifest.write_bytes((json.dumps(m, indent=2) + '\n').encode('utf-8'))
