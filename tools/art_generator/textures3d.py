"""Textures for the 3D scenery (16 texels = 1 world unit): house faces, roof, ground, stone, sky."""
import math

import ground
from palette import (c, ROOF, ROOF_OUTLINE, TIMBER, PLASTER, STONE_OUTLINE, GRASS, LEAF,
                     PINE, STONE)
from pixel import Canvas, rng
from structures import _beam_h, _beam_v, _door, _plaster, _stone_band, _window

BRICK = [c("#5a2a1e"), c("#8a4430"), c("#a8583a"), c("#c27048")]


def _bricks(cv, x0, y0, x1, y1, seed):
    r = rng(seed)
    cv.rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, BRICK[0])
    for row, y in enumerate(range(y0, y1 + 1, 4)):
        x = x0 - (4 if row % 2 else 0)
        while x <= x1:
            tone = r.choice((BRICK[2], BRICK[2], BRICK[1], BRICK[3]))
            for bx in range(7):
                for by in range(3):
                    if x0 <= x + bx <= x1 and y + by <= y1:
                        cv.set(x + bx, y + by, BRICK[3] if by == 0 and tone != BRICK[3] else tone)
            x += 8


def _frame(cv):
    w, h = cv.w, cv.h
    cv.hline(0, w - 1, 0, ROOF_OUTLINE)
    cv.hline(0, w - 1, h - 1, ROOF_OUTLINE)
    cv.vline(0, 0, h - 1, ROOF_OUTLINE)
    cv.vline(w - 1, 0, h - 1, ROOF_OUTLINE)


def house_front():
    """6 x 3 units: timber frame with brick infill, door and two windows."""
    cv = Canvas(96, 48)
    _bricks(cv, 0, 0, 95, 40, 1)
    _stone_band(cv, 0, 95, 41, 47, 2)
    _beam_h(cv, 0, 95, 0, 3)
    _beam_h(cv, 0, 95, 38, 3)
    _beam_h(cv, 0, 95, 20, 2)
    for x in (0, 37, 56, 93):
        _beam_v(cv, x, 0, 40)
    _window(cv, 12, 6)
    _window(cv, 68, 6)
    _door(cv, 41, 24, 14, 24)
    _frame(cv)
    return cv


def house_side():
    """5 x 3 units: same construction, one window."""
    cv = Canvas(80, 48)
    _bricks(cv, 0, 0, 79, 40, 3)
    _stone_band(cv, 0, 79, 41, 47, 4)
    _beam_h(cv, 0, 79, 0, 3)
    _beam_h(cv, 0, 79, 38, 3)
    _beam_h(cv, 0, 79, 20, 2)
    for x in (0, 38, 77):
        _beam_v(cv, x, 0, 40)
    _window(cv, 50, 6)
    _frame(cv)
    return cv


def house_gable():
    """6 x 2.5 units triangle (apex at the top centre): plaster, king post and a small window."""
    w, h = 96, 40
    cv = Canvas(w, h)
    _plaster(cv, 0, 0, w - 1, h - 1, 5)
    _beam_h(cv, 0, w - 1, h - 3, 3)
    _beam_v(cv, 46, 0, h - 3, 4)
    for side in (-1, 1):  # braces
        for i in range(18):
            cv.set(48 + side * (8 + i), h - 4 - i, TIMBER[1])
            cv.set(48 + side * (8 + i), h - 5 - i, TIMBER[0])
    cv.rect(41, 16, 14, 11, TIMBER[0])
    _window(cv, 43, 18, 10, 7)
    for x in range(w):  # thick dark verge along the roof line
        y = int(abs(x + 0.5 - w / 2) / (w / 2) * h)
        for d in range(3):
            cv.set(x, y + d, ROOF_OUTLINE if d < 2 else TIMBER[0])
    return cv


def roof_tiles():
    """32x32 tileable clay shingles (2 x 2 units)."""
    cv = Canvas(32, 32)
    r = rng(9)
    for row in range(4):
        y0 = row * 8
        for col in range(5):
            x0 = col * 8 - (4 if row % 2 else 0)
            tone = r.choice((ROOF[2], ROOF[2], ROOF[3], ROOF[1]))
            for bx in range(8):
                for by in range(8):
                    color = tone
                    if by == 0:
                        color = ROOF[4] if tone != ROOF[1] else ROOF[2]
                    elif by >= 6:
                        color = ROOF[1] if by == 6 else ROOF_OUTLINE
                    if bx == 7:
                        color = ROOF[0]
                    cv.set((x0 + bx) % 32, y0 + by, color)
    return cv


def grass():
    """64x64 tileable grass made from the 2D grass tiles."""
    atlas = ground.ground_atlas()
    cv = Canvas(64, 64)
    r = rng(4)
    picks = [(i, 0) for i in range(8)] + [(0, 0), (1, 0), (2, 0), (3, 3), (4, 3)]
    for ty in range(4):
        for tx in range(4):
            ax, ay = r.choice(picks)
            cv.img.paste(atlas.img.crop((ax * 16, ay * 16, ax * 16 + 16, ay * 16 + 16)), (tx * 16, ty * 16))
    return cv


def paving():
    """32x32 tileable flagstones."""
    cv = Canvas(32, 32)
    for i, seed in enumerate((7, 11, 12, 13)):
        cv.paste(ground.path_tile(0, seed), (i % 2) * 16, (i // 2) * 16)
    return cv


def stone_blocks():
    """64x28 tileable dressed stone (for terrace walls, steps and the chimney)."""
    wall = ground.stone_wall()
    cv = Canvas(64, 28)
    cv.img.paste(wall.img.crop((0, 6, 64, 34)), (0, 0))
    return cv


def blob_shadow():
    cv = Canvas(16, 8)
    cv.ellipse(8, 4, 7.5, 3.6, (16, 28, 30, 110))
    return cv


def sky_backdrop():
    """Far background: sky, clouds, a castle on distant hills."""
    w, h = 960, 140
    cv = Canvas(w, h)
    top, bottom = (92, 160, 236), (206, 232, 255)
    for y in range(h):
        t = min(1.0, y / 90)
        cv.hline(0, w - 1, y, tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    r = rng(3)
    for cx, cy, s in ((60, 40, 1.0), (250, 28, 0.8), (410, 22, 1.0), (600, 46, 1.2), (720, 30, 0.7), (880, 38, 1.0)):
        for i in range(6):
            ox, oy, rad = r.uniform(-26, 26) * s, r.uniform(-5, 5) * s, r.uniform(8, 15) * s
            cv.ellipse(cx + ox, cy + oy + 2, rad, rad * 0.6, c("#c4d8ee"))
            cv.ellipse(cx + ox, cy + oy, rad, rad * 0.6, c("#ffffff"))
    # castle (blue-grey, atmospheric)
    stone, dark, roof = c("#8f9db8"), c("#6f7d99"), c("#5b6a8c")
    cx, base = w // 2, 98
    cv.rect(cx - 34, base - 26, 68, 26, stone)
    for x in range(cx - 34, cx + 34, 6):
        cv.rect(x, base - 30, 3, 4, stone)
    for tx, th in ((-40, 44), (-14, 58), (14, 58), (40, 44), (0, 70)):
        cv.rect(cx + tx - 6, base - th, 12, th, stone)
        cv.vline(cx + tx + 5, base - th, base, dark)
        for y in range(10):
            cv.hline(cx + tx - 6 + (9 - y) * 6 // 10, cx + tx + 6 - (9 - y) * 6 // 10, base - th - 10 + y, roof)
        cv.rect(cx + tx - 1, base - th + 8, 2, 4, dark)
    cv.rect(cx - 5, base - 14, 10, 14, dark)
    # rolling hills with little trees
    for layer, (amp, y0, col, tree) in enumerate(((8, 96, c("#7fb86a"), PINE[3]), (6, 112, GRASS[3], LEAF[2]))):
        for x in range(w):
            y = int(y0 + amp * math.sin(x / (40 + layer * 15) + layer))
            cv.vline(x, y, h - 1, col)
        for _ in range(110 + layer * 30):
            x = r.randrange(w)
            if abs(x - cx) < 46 and layer == 0:
                continue
            y = int(y0 + amp * math.sin(x / (40 + layer * 15) + layer)) + r.randrange(2, 12)
            for d in range(4):
                cv.hline(x - d // 2, x + d // 2, y - 4 + d, tree)
    # winding road up to the castle
    for y in range(base, h):
        t = (y - base) / (h - base)
        x = int(cx + math.sin(t * 5) * 18 * t)
        cv.hline(x - 1 - int(t * 6), x + 1 + int(t * 6), y, c("#d8c08c"))
    return cv
