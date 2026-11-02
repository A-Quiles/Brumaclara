"""Master palette of GUILD ZERO (docs/plan_unificacion_artistica.md, 3.3 and 4 «Paleta»).

Built once from the approved reference art (the Figma facades and outdoor props, the trees, the hero
and the classic ground), grouped in ramps by material, plus a few colours reserved for magic and
focal points. Assets that are redone are snapped to it, so their greens, woods and shadows are the
same ones the rest of the game uses.

    python3 tools/art_pipeline/palette.py        # rebuilds art/paleta/ from the references
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art" / "paleta"
A = ROOT / "assets"
REFERENCES = (
    [p for p in (A / "environment" / "buildings").glob("facade_*.png")]
    + [A / "environment" / "buildings" / n for n in ("house_front.png", "house_side.png", "side_timber.png", "roof_slate.png", "roof_shingle.png")]
    + [A / "environment" / "props" / f"{n}.png" for n in (
        "barrel", "crate", "lantern", "street_lamp", "bench", "stall_red", "stall_blue", "stall_green", "well", "wagon",
        "signpost", "notice_board", "firewood", "sacks", "planter", "trough", "hay_bale", "fence", "weapon_rack",
        "training_dummy", "flower_cart", "bucket")]
    + [A / "environment" / "nature" / f"{n}.png" for n in ("tree_oak", "tree_fir", "tree_young", "bush", "boulder", "stump", "rocks")]
    + [A / "characters" / "hero" / "hero.png", A / "characters" / "hero" / "heroine.png"]
    + [A / "environment" / "textures" / f"{n}.png" for n in ("grass", "dirt", "forest_floor", "garden_soil", "cliff", "stone_wall")]
)
# reserved accents: magic of the six affinities and the Fractura, fire and lamp light (plan, 4 «Paleta»)
RESERVED = {
    "magia": ["ff8a1c", "8fd8ff", "b4b8ff", "a87ae0", "ffe880", "7c4ed2", "d6b8ff"],
    "fuego y luz": ["fff2a8", "ffc93c", "e2451c"],
}
QUOTA = {  # colours per material ramp (60 from the references; with the reserved accents, 70)
    "contorno y sombra": 4, "madera y tierra": 12, "yeso y tierra clara": 6, "piedra y metal": 10,
    "vegetación": 12, "tejidos cálidos y tejas": 8, "tejidos fríos y pizarra": 8,
}


def _lab(rgb):
    """sRGB (0-255) -> CIE Lab, for perceptual nearest-colour matching."""
    c = np.asarray(rgb, np.float64) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    xyz = c @ np.array([[0.4124, 0.2126, 0.0193], [0.3576, 0.7152, 0.1192], [0.1805, 0.0722, 0.9505]])
    xyz /= np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def _material(rgb):
    r, g, b = [x / 255.0 for x in rgb]
    mx, mn = max(r, g, b), min(r, g, b)
    sat = (mx - mn) / mx if mx else 0.0
    if mx < 0.16:
        return "contorno y sombra"
    if sat < 0.16:
        return "piedra y metal"
    h = 0.0
    if mx == r:
        h = ((g - b) / (mx - mn)) % 6
    elif mx == g:
        h = (b - r) / (mx - mn) + 2
    else:
        h = (r - g) / (mx - mn) + 4
    h *= 60
    if 60 <= h < 170:
        return "vegetación"
    if 170 <= h < 290:
        return "tejidos fríos y pizarra"
    if (h >= 290 or h < 18) and sat > 0.45:
        return "tejidos cálidos y tejas"
    if mx > 0.68 and sat < 0.42:
        return "yeso y tierra clara"
    return "madera y tierra"


def build():
    pixels = []
    rng = np.random.default_rng(1)
    for path in REFERENCES:
        im = np.asarray(Image.open(path).convert("RGBA"))
        px = im[im[..., 3] > 127][:, :3]
        pixels.append(px[rng.choice(len(px), min(len(px), 1500), replace=False)])  # every reference weighs the same
    sample = np.concatenate(pixels).astype(np.float64)
    groups = {}
    for c in sample:
        groups.setdefault(_material(c), []).append(c)
    ramps = {}
    for name, size in QUOTA.items():  # one k-means per material: every material gets its own ramp
        px = np.asarray(groups.get(name, []))
        if len(px) == 0:
            continue
        lab = _lab(px)
        k = min(size, len(px))
        centres = lab[rng.choice(len(lab), k, replace=False)]
        for _ in range(30):
            near = np.argmin(((lab[:, None] - centres[None]) ** 2).sum(-1), 1)
            for j in range(k):
                if (near == j).any():
                    centres[j] = lab[near == j].mean(0)
        rgb = [px[near == j].mean(0) for j in range(k) if (near == j).any()]
        ramps[name] = sorted({"%02x%02x%02x" % tuple(np.round(c).astype(int)) for c in rgb})
    for name in ramps:  # dark to light
        ramps[name].sort(key=lambda h: _lab(np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)]))[0])
    ramps.update(RESERVED)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "maestra.json").write_text(json.dumps(ramps, indent=1, ensure_ascii=False))
    _draw(ramps)
    with open(OUT / "maestra.gpl", "w") as f:  # for Aseprite / GIMP / Krita
        f.write("GIMP Palette\nName: GUILD ZERO maestra\nColumns: 12\n#\n")
        for name, ramp in ramps.items():
            for h in ramp:
                f.write("%3d %3d %3d %s\n" % (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), name))
    return ramps


def _draw(ramps):
    cell, label = 22, 190
    width = label + cell * max(len(r) for r in ramps.values()) + 8
    im = Image.new("RGB", (width, cell * len(ramps) + 8), (40, 40, 44))
    d = ImageDraw.Draw(im)
    from PIL import ImageFont
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 12)
    except OSError:
        font = None
    for row, (name, ramp) in enumerate(ramps.items()):
        y = 4 + row * cell
        d.text((6, y + 4), name, fill=(235, 235, 235), font=font)
        for i, h in enumerate(ramp):
            d.rectangle([label + i * cell, y, label + (i + 1) * cell - 2, y + cell - 2], fill="#" + h)
    im.save(OUT / "maestra.png")


def colours():
    """All the master palette's colours, (n, 3) float."""
    ramps = json.loads((OUT / "maestra.json").read_text())
    return np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for ramp in ramps.values() for h in ramp], np.float64)


def snap(rgb, alpha=None, keep=()):
    """Every pixel to its perceptually nearest master colour (`keep`: extra colours allowed)."""
    pal = colours()
    if len(keep):
        pal = np.vstack([pal, np.asarray(keep, np.float64)])
    lab_pal = _lab(pal)
    flat = np.asarray(rgb, np.float64).reshape(-1, 3)
    out = np.empty_like(flat)
    for i in range(0, len(flat), 65536):
        part = _lab(flat[i:i + 65536])
        out[i:i + 65536] = pal[np.argmin(((part[:, None] - lab_pal[None]) ** 2).sum(-1), 1)]
    return out.reshape(np.shape(rgb))


if __name__ == "__main__":
    for name, ramp in build().items():
        print(f"{name:26} {len(ramp)}")
