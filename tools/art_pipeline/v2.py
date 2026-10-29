"""Second art pass (Canva, full-size exports in art/ai/v2): ground and interior textures, the
travelling merchants' stalls and the town gate. Called from build.py (RECIPES)."""
import numpy as np
from PIL import Image

import pixelate as px
import sheets

V2 = None  # set by build.py: art/ai/v2
OUT = None  # set by build.py: assets/
BIG_TILE = 218  # px of the v2 ground textures: two of the old tiles, so the pattern repeats half as often


def _load(name):
    return np.asarray(Image.open(V2 / f"{name}.png").convert("RGB")).astype(np.float64)


def _save(image, *parts):
    path = OUT.joinpath(*parts)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return path


def _texture(rgb, size, colours, band=14, saturation=1.0, value=1.0, flatten=0.0):
    """A tileable texture of `size` px from a full-size source (any size), with `colours` colours."""
    small = np.asarray(Image.fromarray(rgb.astype(np.uint8)).resize((size + band, size + band), Image.LANCZOS)).astype(np.float64)
    if flatten:  # remove big light/dark blotches that would show as a repeating pattern
        from scipy import ndimage
        low = np.stack([ndimage.gaussian_filter(small[..., i], flatten, mode="wrap") for i in range(3)], -1)
        small = small - low + low.reshape(-1, 3).mean(0)
    grey = small.mean(-1, keepdims=True)
    small = np.clip((grey + (small - grey) * saturation) * value, 0, 255)
    small = px.make_tileable(small, band)
    solid = np.ones(small.shape[:2])
    return px.to_image(px.snap(small, solid, px.kmeans_palette(small.reshape(-1, 3), colours)), solid)


GROUND = {  # source -> (texture, colours, saturation, value, flatten)
    "grass": ("grass", 22, 0.78, 0.92, 10.0),
    "cobble": ("cobble", 24, 0.95, 1.0, 0.0),
    "dirt": ("dirt", 20, 0.9, 1.0, 10.0),
}


def replaces():
    out = {name for src, (name, *_) in GROUND.items() if (V2 / f"{src}.png").exists()}
    return out | {name for src, (name, *_) in INTERIOR.items() if (V2 / f"{src}.png").exists()}


def ground():
    for src, (name, colours, sat, val, flatten) in GROUND.items():
        if (V2 / f"{src}.png").exists():
            _save(_texture(_load(src), BIG_TILE, colours, saturation=sat, value=val, flatten=flatten),
                  "environment", "textures", name + ".png")
    return OUT / "environment" / "textures"


INTERIOR_TILE = 168  # px: two of the old 84 px interior tiles (tools/levels/interiors.py doubles their size)
INTERIOR = {"floor_planks": ("floor_planks", 20, 0.85), "wall_plaster": ("wall_plaster", 22, 0.9),
            "flagstone": ("floor_flagstone", 22, 0.9)}


def interior():
    for src, (name, colours, sat) in INTERIOR.items():
        if (V2 / f"{src}.png").exists():
            _save(_texture(_load(src), INTERIOR_TILE, colours, saturation=sat), "environment", "textures", name + ".png")
    return OUT / "environment" / "textures"


def _objects(rgb, min_area=4000):
    """The separate drawings on a magenta sheet: (crop rgb, crop alpha) per object, left to right,
    top to bottom."""
    from scipy import ndimage
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    backdrop = (r > 170) & (b > 170) & (g < 120) & (np.abs(r - b) < 90)
    solid = ndimage.binary_opening(~backdrop, iterations=2)
    solid = ndimage.binary_fill_holes(solid)
    labels, n = ndimage.label(solid)
    parts = []
    for i, box in enumerate(ndimage.find_objects(labels)):
        mask = labels[box] == i + 1
        if mask.sum() < min_area:
            continue
        parts.append((box, mask))
    rows = sorted(parts, key=lambda p: p[0][0].start)
    out = []
    while rows:  # group into rows by vertical overlap, then left to right
        top = rows[0][0][0]
        row = [p for p in rows if p[0][0].start < top.stop - 40]
        rows = [p for p in rows if p not in row]
        out += sorted(row, key=lambda p: p[0][1].start)
    return [(rgb[box], mask) for box, mask in out]


def _sprite(rgb, mask, height, colours):
    """A crisp sprite `height` game px tall: magenta fringe turned to outline, palette `colours`."""
    h, w = mask.shape
    width = max(1, round(w * height / h))
    a = mask.astype(np.float64)
    pre = Image.fromarray(np.dstack([rgb * a[..., None], a * 255]).astype(np.uint8), "RGBA")
    small = np.asarray(pre.resize((width, height), Image.BOX)).astype(np.float64)
    alpha = small[..., 3] / 255.0
    colour = small[..., :3] / np.maximum(alpha, 1e-3)[..., None]
    solid = (alpha > 0.5).astype(np.float64)
    fringe = (colour[..., 0] > colour[..., 1] * 1.3) & (colour[..., 2] > colour[..., 1] * 1.3)
    colour[fringe] = (38, 26, 24)
    colour = np.clip(colour, 0, 255)
    palette = px.kmeans_palette(colour[solid > 0], colours)
    return px.to_image(px.snap(colour, solid, palette), solid)


STALLS = [("merchant_wagon", 78), ("cloth_cart", 56), ("potion_stall", 74), ("smith_stall", 70), ("food_stall", 72),
          ("fortune_tent", 84)]  # left to right, top to bottom; game px tall


def stalls():
    parts = _objects(_load("stalls"))
    for (rgb, mask), (name, height) in zip(parts, STALLS):
        _save(_sprite(rgb, mask, height, 40), "environment", "props", name + ".png")
    return OUT / "environment" / "props"


def gate():
    parts = _objects(_load("gate"), 20000)
    rgb, mask = max(parts, key=lambda p: p[1].sum())
    _save(_sprite(rgb, mask, 190, 56), "environment", "props", "town_gate.png")
    return OUT / "environment" / "props"
