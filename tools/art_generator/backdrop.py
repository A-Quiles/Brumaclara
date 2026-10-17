"""Distant scenery behind the village, painted for the default camera.

The backdrop is a vertical quad at z = BACKDROP_Z. Each texel is projected with the game camera
(the player's shifted-lens Camera3D) and painted from a description in screen space, so from the
default view the valley, road and clouds sit exactly where the reference image has them.
Coordinates (u, v) below are reference-image pixels (1408 x 768).
"""
import math

from pixel import Canvas, hex_rgba as c, rng

# camera of scenes/characters/player.tscn, looking at the hero standing at the plaza origin:
# a vertical image plane whose window is shifted down (frustum offset), so verticals stay vertical
CAM = (0.0, 24.764, 40.434)
FOCAL = 1920.62     # reference-image pixels
HORIZON = -576.31   # image row of the horizon, above the picture
IMG_W, IMG_H = 1408, 768

BACKDROP_Z = -21.0
X0, X1 = -42.0, 42.0      # quad extent in world units
Y0, Y1 = -6.0, 10.0
TEXELS_PER_UNIT = 10

SKY_TOP, SKY_BOTTOM = c("#86d4f0"), c("#cdeff8")
CLOUD = [c("#9ab8d8"), c("#cfe2f2"), c("#ffffff")]
FAR_HILL = [c("#6f9ab0"), c("#86afc0")]
HILL = [c("#3e7a3e"), c("#4f8f45"), c("#62a24e"), c("#7cb85e")]
ROAD = [c("#a8865a"), c("#c8a676"), c("#dcc092")]
PINE = [c("#1c4433"), c("#2a5e3e"), c("#3f7f45")]


def _project(x, y, z):
    d = CAM[2] - z
    return IMG_W / 2 + FOCAL * (x - CAM[0]) / d, HORIZON + FOCAL * (CAM[1] - y) / d


def _unproject(u, v):
    """Point on the backdrop plane seen at image (u, v)."""
    d = CAM[2] - BACKDROP_Z
    return CAM[0] + (u - IMG_W / 2) * d / FOCAL, CAM[1] - (v - HORIZON) * d / FOCAL


def _hill_line(u):
    """Image row of the green hills' crest; highest behind the road."""
    return 150 - 38 * math.exp(-((u - 720) / 150) ** 2) + 6 * math.sin(u / 47)


def _road_centre(v):
    t = (285 - v) / 165  # 0 at the plaza end, 1 at the crest
    return 708 + 46 * math.sin(t * 5.2) * (0.35 + 0.65 * t), 50 * max(0.0, 1 - t) ** 1.4 + 9


def _paint(u, v, r):
    crest = _hill_line(u)
    if v < crest:
        far = 135 - 22 * math.exp(-((u - 420) / 170) ** 2) - 30 * math.exp(-((u - 1010) / 200) ** 2)
        if v > far:
            return FAR_HILL[0] if (u + v) % 7 < 2 else FAR_HILL[1]
        t = max(0.0, min(1.0, v / 150))
        return tuple(round(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOTTOM))
    depth = (v - crest) / max(1.0, 290 - crest)          # 0 at the crest, 1 near the village
    centre, half = _road_centre(v)
    if abs(u - centre) < half * (0.6 + 0.4 * depth):
        edge = abs(u - centre) > half * (0.6 + 0.4 * depth) - 3
        return ROAD[0] if edge else (ROAD[2] if (int(u) + int(v)) % 9 == 0 else ROAD[1])
    k = 2 if depth < 0.25 else 1
    if (int(u * 3) ^ int(v * 5)) % 11 == 0:
        k = 3
    if (int(u) + 2 * int(v)) % 13 == 0:
        k = 0
    return HILL[k]


def _pines(cv, to_tex):
    """Little pines dotted over the hills, sized by their distance."""
    r = rng(12)
    spots = [(605, 215), (628, 238), (590, 262), (660, 200), (790, 210), (812, 240), (770, 262), (845, 228),
             (540, 230), (870, 260), (750, 190), (680, 172), (505, 205), (905, 215)]
    for u, v in spots:
        size = 6 + (v - 160) / 14
        tx, ty = to_tex(u, v)
        if tx is None:
            continue
        hgt = max(4, int(size * 0.9))
        for i in range(hgt):
            half = int((i + 1) * size / 2.4 / hgt * 2.4 / 2)
            for x in range(tx - half, tx + half + 1):
                col = PINE[2] if x < tx else PINE[1]
                cv.set(x, ty - hgt + i, PINE[0] if i == hgt - 1 else col)
        cv.set(tx, ty, c("#5a3620"))
        r.random()


def _clouds(u, v):
    for cu, cv0, scale in ((600, 92, 1.0), (840, 98, 1.1), (90, 150, 0.7), (1150, 40, 0.6), (300, 20, 0.6)):
        for i, (du, dv, rad) in enumerate(((-55, 6, 26), (-22, -6, 30), (14, -10, 32), (50, 0, 28), (78, 8, 20),
                                           (-80, 12, 16))):
            dx = (u - (cu + du * scale)) / (rad * scale)
            dy = (v - (cv0 + dv * scale)) / (rad * scale * 0.62)
            d = dx * dx + dy * dy
            if d < 1:
                if dy > 0.45:
                    return CLOUD[0]
                return CLOUD[2] if dy < -0.1 or dx < -0.3 else CLOUD[1]
    return None


def backdrop():
    w = round((X1 - X0) * TEXELS_PER_UNIT)
    h = round((Y1 - Y0) * TEXELS_PER_UNIT)
    cv = Canvas(w, h)
    r = rng(3)
    for j in range(h):
        y = Y1 - (j + 0.5) / TEXELS_PER_UNIT
        for i in range(w):
            x = X0 + (i + 0.5) / TEXELS_PER_UNIT
            u, v = _project(x, y, BACKDROP_Z)
            col = _paint(u, v, r)
            if v < _hill_line(u):
                cloud = _clouds(u, v)
                if cloud:
                    col = cloud
            cv.set(i, j, col)

    def to_tex(u, v):
        x, y = _unproject(u, v)
        i, j = round((x - X0) * TEXELS_PER_UNIT), round((Y1 - y) * TEXELS_PER_UNIT)
        return (i, j) if 0 <= i < w and 0 <= j < h else (None, None)
    _pines(cv, to_tex)
    return cv
