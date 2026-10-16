"""The cottage and the small garden props. Origins are the bottom-centre of each base."""
import math

from palette import (c, WOOD, WOOD_OUTLINE, TIMBER, PLASTER, GLASS,
                     STONE, STONE_OUTLINE, LEAF, SOIL, METAL, WATER, MOSS,
                     FLOWER_PINK, FLOWER_RED, FLOWER_YELLOW, GRASS)
from pixel import Canvas, rng

SHUTTER = [c("#24464c"), c("#33656c"), c("#4a8a8e")]


# --- cottage ---------------------------------------------------------------

def _stone_band(cv, x0, x1, y0, y1, seed):
    r = rng(seed)
    y = y0
    offset = 0
    while y <= y1:
        h = min(4, y1 - y + 1)
        x = x0 - offset
        while x <= x1:
            w = r.choice((6, 7, 8))
            tone = r.choice((STONE[2], STONE[3], STONE[2], STONE[1]))
            for bx in range(w - 1):
                for by in range(h - 1):
                    if x0 <= x + bx <= x1:
                        color = STONE[4] if by == 0 and tone != STONE[1] else tone
                        if by == h - 2 and h > 2:
                            color = STONE[1]
                        cv.set(x + bx, y + by, color)
            if x0 <= x + w - 1 <= x1:
                cv.vline(x + w - 1, y, y + h - 2, STONE_OUTLINE)
            x += w
        cv.hline(x0, x1, y + h - 1, STONE_OUTLINE)
        y += h
        offset = 3 if offset == 0 else 0


def _plaster(cv, x0, y0, x1, y1, seed):
    r = rng(seed)
    cv.rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, PLASTER[1])
    for _ in range((x1 - x0) * (y1 - y0) // 14):
        cv.set(r.randint(x0, x1), r.randint(y0, y1), r.choice((PLASTER[0], PLASTER[2], PLASTER[2])))


def _beam_h(cv, x0, x1, y, thick=2):
    cv.rect(x0, y, x1 - x0 + 1, thick, TIMBER[1])
    cv.hline(x0, x1, y, TIMBER[2])
    cv.hline(x0, x1, y + thick - 1, TIMBER[0])


def _beam_v(cv, x, y0, y1, thick=3):
    cv.rect(x, y0, thick, y1 - y0 + 1, TIMBER[1])
    cv.vline(x, y0, y1, TIMBER[2])
    cv.vline(x + thick - 1, y0, y1, TIMBER[0])


def _window(cv, x, y, w=16, h=14):
    # shutters
    for sx in (x - 5, x + w + 1):
        cv.rect(sx, y, 4, h, SHUTTER[1])
        cv.vline(sx, y, y + h - 1, SHUTTER[2])
        cv.vline(sx + 3, y, y + h - 1, SHUTTER[0])
        for yy in range(y + 2, y + h - 1, 3):
            cv.hline(sx + 1, sx + 2, yy, SHUTTER[0])
    # frame and glass
    cv.rect(x - 1, y - 1, w + 2, h + 2, TIMBER[0])
    cv.rect(x, y, w, h, GLASS[1])
    cv.rect(x, y, w, 3, GLASS[0])  # the eave darkens the top of the glass
    for i in range(5):  # diagonal reflections
        cv.set(x + 3 + i, y + h - 3 - i, GLASS[3])
        cv.set(x + 4 + i, y + h - 3 - i, GLASS[2])
        cv.set(x + 9 + i, y + h - 2 - i, GLASS[2])
    cv.vline(x + w // 2, y, y + h - 1, TIMBER[1])
    cv.hline(x, x + w - 1, y + h // 2, TIMBER[1])
    # sill and flower box
    cv.rect(x - 2, y + h + 1, w + 4, 1, WOOD[3])
    cv.rect(x - 1, y + h + 2, w + 2, 3, WOOD[1])
    cv.hline(x - 1, x + w, y + h + 2, WOOD[2])
    for i, fx in enumerate(range(x, x + w, 3)):
        ramp = (FLOWER_RED, FLOWER_PINK, FLOWER_YELLOW)[i % 3]
        cv.set(fx, y + h, LEAF[3])
        cv.set(fx + 1, y + h, LEAF[2])
        cv.set(fx, y + h - 1, ramp[1])
        cv.set(fx + 1, y + h - 1, ramp[2])
        cv.set(fx + 1, y + h + 1, LEAF[2])


def _door(cv, x, y, w, h):
    cv.rect(x - 2, y - 2, w + 4, h + 2, TIMBER[0])
    cv.rect(x - 1, y - 1, w + 2, h + 1, TIMBER[1])
    cv.rect(x, y, w, h, WOOD[2])
    for px in range(x, x + w, 4):
        cv.vline(px, y, y + h - 1, WOOD[1])
        cv.vline(px + 1, y, y + h - 1, WOOD[3])
    cv.rect(x, y, w, 2, WOOD[0])  # shadow under the lintel
    for by in (y + 6, y + h - 7):
        cv.hline(x, x + w - 1, by, WOOD[1])
        cv.hline(x, x + w - 1, by + 1, METAL[1])
    cv.set(x + w - 4, y + h // 2, FLOWER_YELLOW[1])
    cv.set(x + w - 4, y + h // 2 + 1, FLOWER_YELLOW[0])


def _wood_shade(x, x0, x1):
    t = (x - x0) / max(1, x1 - x0)
    return WOOD[4] if t < 0.2 else WOOD[3] if t < 0.65 else WOOD[2]


def fence_h():
    """16px wide picket fence segment; tiles horizontally (rails show between pickets)."""
    cv = Canvas(16, 22)
    for ry in (8, 14):  # rails behind the pickets
        cv.rect(0, ry, 16, 2, WOOD[2])
        cv.hline(0, 15, ry, WOOD[3])
    for px in (2, 10):
        for y in range(3, 20):
            for x in range(px, px + 4):
                if y == 3 and x in (px, px + 3):
                    continue
                cv.set(x, y, _wood_shade(x, px, px + 3))
        cv.hline(px + 1, px + 2, 3, WOOD[4])
        cv.hline(px, px + 3, 19, WOOD[1])
    cv.outline(WOOD_OUTLINE)
    cv.hline(0, 15, 21, (16, 28, 30, 80))
    return cv, (8, 20)


def barrel():
    cv = Canvas(18, 22)
    cv.shadow(11, 19.5, 8, 2.5)
    for y in range(4, 19):
        bulge = 1 if 7 <= y <= 15 else 0
        x0, x1 = 3 - bulge, 14 + bulge
        for x in range(x0, x1 + 1):
            cv.set(x, y, _wood_shade(x, x0, x1))
        for sx in range(x0 + 3, x1, 3):
            cv.set(sx, y, WOOD[1])
    for hy in (6, 15):
        for x in range(2, 16):
            cv.set(x, hy, METAL[1] if x < 12 else METAL[0])
        cv.set(4, hy, METAL[2])
    cv.ellipse(8.5, 4, 6, 2.5, WOOD[3])
    cv.ellipse(8.5, 4, 4.5, 1.6, WOOD[2])
    cv.hline(5, 12, 3, WOOD[4])
    cv.outline(WOOD_OUTLINE)
    return cv, (9, 19)


def crate():
    cv = Canvas(20, 22)
    cv.shadow(12, 18.5, 9, 2.5)
    cv.rect(2, 3, 16, 5, WOOD[4])               # top face
    cv.hline(2, 17, 5, WOOD[3])
    cv.rect(2, 8, 16, 10, WOOD[3])              # front face
    for y in (11, 14):
        cv.hline(3, 16, y, WOOD[2])
    cv.rect(2, 8, 2, 10, WOOD[2])
    cv.rect(16, 8, 2, 10, WOOD[1])
    cv.hline(2, 17, 8, WOOD[1])
    cv.hline(2, 17, 17, WOOD[1])
    cv.line(4, 16, 15, 9, WOOD[2])
    cv.outline(WOOD_OUTLINE)
    return cv, (10, 18)


def signpost():
    cv = Canvas(20, 28)
    cv.shadow(11, 25.5, 6, 2)
    cv.rect(9, 10, 3, 15, WOOD[2])
    cv.vline(9, 10, 24, WOOD[3])
    cv.rect(1, 3, 18, 10, WOOD[3])
    cv.hline(1, 18, 3, WOOD[4])
    cv.hline(1, 18, 12, WOOD[1])
    cv.vline(18, 3, 12, WOOD[2])
    for y, (a, b) in ((6, (4, 14)), (9, (4, 11))):  # carved lettering
        for x in range(a, b + 1):
            if x % 4 != 3:
                cv.set(x, y, WOOD[0])
    cv.outline(WOOD_OUTLINE)
    return cv, (10, 25)


def garden_bed(seed=1):
    cv = Canvas(52, 32)
    cv.shadow(28, 27.5, 25, 3)
    x0, x1, top, front, bottom = 2, 49, 6, 21, 26
    cv.rect(x0, top, x1 - x0 + 1, front - top, SOIL[2])     # soil
    for y in range(top + 3, front, 4):                       # furrows
        cv.hline(x0 + 2, x1 - 2, y, SOIL[1])
        cv.hline(x0 + 2, x1 - 2, y - 1, SOIL[3])
    for x in range(x0, x1 + 1):                              # frame planks
        cv.set(x, top, WOOD[3])
        cv.set(x, top + 1, WOOD[2])
    for y in range(top, front):
        for x in (x0, x0 + 1, x1 - 1, x1):
            cv.set(x, y, WOOD[3] if x in (x0, x1 - 1) else WOOD[2])
    cv.rect(x0, front, x1 - x0 + 1, bottom - front + 1, WOOD[2])  # front plank
    cv.hline(x0, x1, front, WOOD[4])
    cv.hline(x0, x1, bottom, WOOD[1])
    for x in range(x0 + 11, x1, 12):
        cv.vline(x, front + 1, bottom - 1, WOOD[1])
    r = rng(seed)
    for row, y in enumerate((top + 4, top + 11)):            # cabbages and sprouts
        for x in range(x0 + 6, x1 - 3, 8):
            x += r.randint(-1, 1)
            if row == 0:
                cv.ellipse(x, y, 3.5, 3, LEAF[3])
                cv.ellipse(x - 0.5, y - 0.5, 2, 1.5, LEAF[5])
                cv.set(x + 1, y + 1, LEAF[1])
                cv.hline(x - 3, x + 3, y + 3, SOIL[0])
            else:
                for dx, dy in ((0, 0), (-1, -1), (1, -1), (-2, -2), (2, -2), (0, -2)):
                    cv.set(x + dx, y + dy, LEAF[4] if dy < -1 else LEAF[2])
                cv.set(x, y + 1, FLOWER_RED[1] if r.random() < 0.4 else SOIL[0])
    cv.outline(WOOD_OUTLINE)
    return cv, (26, 27)


def pond():
    """Flat decoration: drawn under everything else."""
    cv = Canvas(72, 44)
    cx, cy, rx, ry = 36, 21, 31, 16
    cv.ellipse(cx, cy, rx + 1, ry + 1, GRASS[1])
    cv.ellipse(cx, cy, rx, ry, SOIL[1])
    cv.ellipse(cx, cy + 2, rx - 1, ry - 2, WATER[1])
    cv.ellipse(cx, cy + 3, rx - 4, ry - 5, WATER[2])
    cv.ellipse(cx + 2, cy + 6, rx - 10, ry - 9, WATER[3])
    for x0, y, length in ((14, 26, 6), (40, 30, 8), (26, 14, 5), (50, 20, 4)):
        cv.hline(x0, x0 + length, y, WATER[4])
        cv.hline(x0 + 2, x0 + length - 2, y + 1, WATER[3])
    for lx, ly in ((20, 20), (47, 27), (54, 16)):          # lily pads
        cv.ellipse(lx, ly, 3.5, 2.2, LEAF[3])
        cv.ellipse(lx - 0.5, ly - 0.5, 2, 1.2, LEAF[4])
        cv.set(lx + 2, ly, WATER[2])
        cv.set(lx + 3, ly, WATER[2])
    cv.set(20, 18, FLOWER_PINK[2])
    cv.set(21, 18, FLOWER_PINK[1])
    cv.set(20, 19, FLOWER_PINK[1])
    r = rng(17)  # stones along the rim
    for i in range(22):

        a = i / 22 * math.tau + r.uniform(-0.08, 0.08)
        sx, sy = cx + math.cos(a) * (rx + 0.5), cy + math.sin(a) * (ry + 0.5)
        size = r.choice((2.2, 2.6, 3.0))
        cv.ellipse(sx, sy, size, size * 0.75, STONE[2])
        cv.set(int(sx) - 1, int(sy) - 1, STONE[4])
        cv.set(int(sx), int(sy) - 1, STONE[3])
        if r.random() < 0.3:
            cv.set(int(sx) + 1, int(sy) - 1, MOSS[1])
    cv.outline(STONE_OUTLINE)
    return cv, (cx, 0)
