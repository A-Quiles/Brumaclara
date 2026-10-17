"""House catalogue for the village and the facade/gable/roof textures of each house.

Sizes are world units (w, wall height, d). `ridge_along_x` False means the gable faces the
front (+z); True means the long eave wall faces the front and the gables face left/right.
Facade layouts are fractions of the wall so each house keeps its look at any size.
"""
import math

from pixel import Canvas
from village_textures import (T, INFILL, OUTLINE, beam_h, beam_v, brace, bricks, border, door,
                              flat_roof, roof_slope, stones, window)

# Wall layouts. posts: x fractions; bands: y fractions of first-floor beams; win_up / win_low: window
# centres on the upper / ground floor; door: x centre; stone_ground: stone below the last band.
STYLES = {
    "b1": {"front": {"posts": [0, 0.5, 1], "bands": [0.43, 0.54], "win_up": [0.27, 0.73], "win_low": [0.2], "door": 0.64},
           "side": {"posts": [0, 1], "bands": [0.43, 0.54], "win_up": [0.5], "win_low": [0.5]},
           "gable": "v"},
    "b2": {"front": {"posts": [0, 0.5, 1], "bands": [0.44, 0.54], "win_up": [0.27, 0.73], "win_low": [0.76], "door": 0.3},
           "side": {"posts": [0, 1], "bands": [0.44, 0.54], "win_up": [0.5], "win_low": []},
           "gable": "x"},
    "b9": {"front": {"posts": [0, 0.5, 1], "bands": [], "win_up": [0.27, 0.73], "plinth": 6},
           "side": {"posts": [0, 1], "bands": [], "win_up": [0.5], "plinth": 6},
           "gable": "post"},
    "b4": {"front": {"posts": [0, 0.25, 0.5, 0.75, 1], "bands": [], "win_up": [0.125, 0.375, 0.625, 0.875]},
           "side": {"posts": [0, 1], "bands": [], "door": 0.55},
           "gable": "v"},
    "b5": {"front": {"posts": [0, 0.33, 0.66, 1], "bands": [0.5], "win_up": [0.16, 0.5, 0.84], "win_low": [0.16, 0.84]},
           "side": {"posts": [0, 1], "bands": [0.5], "win_up": [0.5], "win_low": [0.5]},
           "gable": "x"},
    "b6": {"front": {"posts": [0, 0.5, 1], "bands": [0.45], "win_up": [0.27, 0.73], "door": 0.5},
           "side": {"posts": [0, 1], "bands": [0.45], "win_up": [0.5]},
           "gable": "v"},
    "b7": {"front": {"posts": [0, 1], "bands": [0.45], "win_up": [0.3, 0.72], "door": 0.55},
           "side": {"posts": [0, 1], "bands": [0.45], "win_up": [0.5]},
           "gable": "post"},
    "b3": {"front": {"posts": [0, 0.5, 1], "bands": [0.5], "win_up": [0.25, 0.75], "win_low": [0.25], "door": 0.7},
           "side": {"posts": [0, 1], "bands": [0.5], "win_up": [0.3, 0.7]},
           "gable": "x"},
    "b10": {"front": {"posts": [0, 1], "bands": [0.36, 0.66], "win_up": [0.3, 0.72], "win_mid": [0.3, 0.72], "door": 0.5},
            "side": {"posts": [0, 1], "bands": [0.36, 0.66], "win_up": [0.5], "win_mid": [0.5]},
            "gable": "x"},
    "b11": {"front": {"posts": [0, 0.33, 0.66, 1], "bands": [0.42], "win_up": [0.17, 0.5, 0.83], "door": 0.24,
                      "stone_ground": True, "win_low": [0.6]},
            "side": {"posts": [0, 1], "bands": [0.42], "win_up": [0.5], "stone_ground": True},
            "gable": "x"},
    "b12": {"front": {"posts": [0, 0.33, 0.66, 1], "bands": [], "win_up": [0.17, 0.83]},
            "side": {"posts": [0, 0.5, 1], "bands": [], "win_up": [0.25, 0.75]},
            "gable": "x_windows"},
    "tower": {"front": {"posts": [0, 1], "bands": [0.52, 0.6], "post_w": 5, "beam_w": 4},
              "side": {"posts": [0, 1], "bands": [0.52, 0.6], "win_up": [0.3, 0.7], "win_low": [0.3],
                       "door": 0.78, "post_w": 5, "beam_w": 4},
              "gable": None},
    "plain": {"front": {"posts": [0, 1], "bands": [0.5], "win_up": [0.3, 0.7]},
              "side": {"posts": [0, 1], "bands": [0.5], "win_up": [0.5]},
              "gable": "post"},
    "dormer": {"front": {"posts": [0, 1], "bands": [], "win_up": [0.5], "plinth": 0, "win_size": 6},
               "side": {"posts": [], "bands": [], "plinth": 0},
               "gable": None},
}

HOUSES = {
    "HouseBlueRoof": {"style": "b1", "infill": "brick", "size": (3.55, 3.99, 2.8), "roof": "blue", "roof_h": 1.35},
    "HouseOrangeRoof": {"style": "b2", "infill": "cream", "size": (3.9, 3.42, 2.6), "roof": "orange", "roof_h": 1.64},
    "HouseRedRoof": {"style": "b9", "infill": "brick", "size": (4.2, 2.0, 3.0), "roof": "red", "roof_h": 1.75,
                     "ridge_along_x": True, "dormers": [-1.0, 1.0]},
    "HouseLongLeft": {"style": "b4", "infill": "brick", "size": (8.6, 2.0, 3.6), "roof": "orange", "roof_h": 1.27,
                      "ridge_along_x": True, "dormers": [-2.2, 0.4]},
    "HouseTealLeft": {"style": "b5", "infill": "cream", "size": (7.0, 2.6, 3.5), "roof": "teal", "roof_h": 1.7,
                      "ridge_along_x": True},
    "HouseCreamBack": {"style": "b6", "infill": "cream", "size": (3.3, 2.5, 3.0), "roof": "orange", "roof_h": 1.6},
    "HouseBrickBack": {"style": "b7", "infill": "brick", "size": (2.7, 2.3, 2.8), "roof": "blue", "roof_h": 1.3},
    "HouseFarLeft": {"style": "b3", "infill": "cream", "size": (5.0, 3.0, 4.0), "roof": "red", "roof_h": 1.6},
    "HouseTealRight": {"style": "b10", "infill": "brick", "size": (2.6, 4.79, 2.6), "roof": "teal", "roof_h": 1.8},
    "HouseStoneRight": {"style": "b11", "infill": "cream", "size": (7.0, 4.09, 5.0), "roof": "orange", "roof_h": 2.4},
    "HouseBottomRight": {"style": "b12", "infill": "cream", "size": (6.2, 2.5, 7.2), "roof": "orange", "roof_h": 4.0,
                         "ridge_along_x": True, "overhang": 0.4, "dormers": [1.6], "big_dormer": True},
    "TowerLeft": {"style": "tower", "infill": "brick_big", "size": (6.0, 7.5, 4.7), "roof": "flat", "roof_h": 0.0,
                  "overhang": 0.0},
    "HouseCornerBlue": {"style": "plain", "infill": "brick", "size": (6.0, 3.0, 6.0), "roof": "blue", "roof_h": 2.4},
}

DORMER = {"size": (1.3, 0.9, 1.6), "roof_h": 0.7, "overhang": 0.12}
BIG_DORMER = {"size": (2.0, 1.3, 2.2), "roof_h": 1.0, "overhang": 0.15}


def wall(w_units, h_units, infill, layout, seed=0):
    """A timber-framed wall texture."""
    w, h = max(6, round(w_units * T)), max(6, round(h_units * T))
    cv = Canvas(w, h)
    ramp = INFILL[infill]
    if infill == "brick_big":
        bricks(cv, 0, 0, w - 1, h - 1, ramp, 6, 2, seed=seed)
    elif infill == "cream":
        bricks(cv, 0, 0, w - 1, h - 1, ramp, 4, 2, seed=seed)
    else:
        bricks(cv, 0, 0, w - 1, h - 1, ramp, 3, 1, seed=seed)
    post_w = layout.get("post_w", 2)
    plinth = layout.get("plinth", 3 if h > 14 else 0)
    bands = [round(f * h) for f in layout.get("bands", [])]
    ground_top = bands[-1] + 2 if bands else 3
    if layout.get("stone_ground") and bands:
        stones(cv, 0, ground_top, w - 1, h - 1, seed=seed + 1)
    elif plinth:
        stones(cv, 0, h - plinth, w - 1, h - 1, seed=seed + 1, row_h=3)
    beam_w = layout.get("beam_w", 2)
    beam_h(cv, 0, w - 1, 0, beam_w + 1 if h > 12 else 2)
    for y in bands:
        beam_h(cv, 0, w - 1, y, beam_w)
    upper_bottom = bands[0] if bands else h - plinth
    for f in layout.get("posts", []):
        x = min(w - post_w - 1, max(0, round(f * w - post_w / 2)))
        beam_v(cv, x, 0, upper_bottom - 1 if layout.get("stone_ground") else h - plinth - 1, post_w)
    win = layout.get("win_size", 8)
    zones = [("win_up", 3, upper_bottom)]
    if len(bands) >= 2:
        zones.append(("win_mid", bands[0] + 2, bands[1]))
    zones.append(("win_low", ground_top, h - plinth))
    for key, top, bottom in zones:
        span = bottom - top
        if span < 6:
            continue
        size = min(win, span - 4)
        for f in layout.get(key, []):
            x = round(f * w - size / 2)
            y = top + max(1, (span - size) // 2 - (1 if key == "win_low" else 0))
            window(cv, x, y, size, size, sill=span - size > 3)
    if "door" in layout:
        dw = 9 if w > 30 else 7
        dh = min(17, h - ground_top - 2)
        if dh >= 6:
            door(cv, round(layout["door"] * w - dw / 2), h - dh, dw, dh)
    border(cv, "lrbt")
    return cv


def gable(w_units, h_units, infill, kind, seed=0):
    """The triangle above a gable wall; the mesh maps it with the apex at the top centre."""
    w, h = max(6, round(w_units * T)), max(4, round(h_units * T))
    cv = Canvas(w, h)
    if infill == "brick_big":
        infill = "brick"
    bricks(cv, 0, 0, w - 1, h - 1, INFILL[infill], 3 if infill == "brick" else 4, 1 if infill == "brick" else 2, seed=seed)
    beam_h(cv, 0, w - 1, h - 3, 2)
    mid = w // 2 - 1
    if kind:
        beam_v(cv, mid, 0, h - 3)
    if kind in ("v", "x", "x_windows"):
        # braces from the eave beam up to the king post, following the roof pitch
        for side in (-1, 1):
            x_eave = mid + side * (w // 4 + 2) + (2 if side > 0 else 0)
            y_top = max(1, h - 3 - (abs(x_eave - mid) * h) // max(1, w // 2) + 2)
            brace(cv, x_eave, h - 4, mid + (2 if side > 0 else 0), y_top + 2)
    if kind in ("x", "x_windows"):
        for side in (-1, 1):
            x0 = mid + side * (w // 2 - 3)
            x1 = mid + side * (w // 6)
            brace(cv, x0, h - 5, x1, max(2, h - 5 - abs(x1 - x0) // 2))
    if kind == "x_windows":
        for f in (0.32, 0.68):
            size = min(9, h // 3)
            window(cv, round(f * w - size / 2), h - size - 6, size, size)
    elif h > 14:
        size = 6
        window(cv, mid - size // 2 + 1, h - size - 7, size, size, sill=False)
    for x in range(w):  # dark verge under the roof edge
        y = int(abs(x + 0.5 - w / 2) / (w / 2) * h)
        cv.set(x, y, OUTLINE)
        cv.set(x, y + 1, OUTLINE)
    return cv


def roof_dims(size, roof_h, overhang, ridge_along_x):
    """(length along the ridge, slope length) of one roof slope, matching house_mesh.gd."""
    w, _, d = size
    half = d / 2 if ridge_along_x else w / 2
    length = (w if ridge_along_x else d) + 2 * overhang
    drop = overhang * roof_h / half if half else 0
    return length, math.hypot(half + overhang, roof_h + drop)


def house_textures(name, spec):
    """All textures of one house as {suffix: Canvas}."""
    style = STYLES[spec["style"]]
    w, h, d = spec["size"]
    along_x = spec.get("ridge_along_x", False)
    overhang = spec.get("overhang", 0.3)
    infill = spec["infill"]
    seed = sum(map(ord, name))
    out = {"front": wall(w, h, infill, style["front"], seed),
           "side": wall(d, h, infill, style["side"], seed + 7)}
    if spec["roof"] == "flat":
        out["roof"] = flat_roof(round(w * T), round(d * T / 2))
    else:
        length, slope = roof_dims(spec["size"], spec["roof_h"], overhang, along_x)
        out["roof"] = roof_slope(length, slope, spec["roof"], seed=seed)
        out["gable"] = gable(d if along_x else w, spec["roof_h"], infill, style["gable"], seed + 3)
    if spec.get("dormers"):
        dm = BIG_DORMER if spec.get("big_dormer") else DORMER
        dw, dh, dd = dm["size"]
        out["dormer_front"] = wall(dw, dh, "cream", STYLES["dormer"]["front"], seed + 11)
        out["dormer_side"] = wall(dd, dh, "cream", STYLES["dormer"]["side"], seed + 12)
        out["dormer_gable"] = gable(dw, dm["roof_h"], "cream", None, seed + 13)
        length, slope = roof_dims(dm["size"], dm["roof_h"], dm["overhang"], False)
        out["dormer_roof"] = roof_slope(length, slope, spec["roof"], tile=(4, 2), seed=seed + 14)
    return out
