"""Ground atlas (grass + paved path with grass edges) and the stone retaining wall."""
from palette import (GRASS, GRASS_BASE, LEAF, PATH, PATH_JOINT, STONE, STONE_OUTLINE,
                     FLOWER_PINK, FLOWER_WHITE, FLOWER_YELLOW, FLOWER_BLUE)
from pixel import Canvas, rng

T = 16  # tile size

# Path edges are encoded as a bitmask of the neighbours that are grass.
N, E, S, W = 1, 2, 4, 8


def _tuft(cv, x, y, dark=GRASS[2], light=GRASS[4]):
    """Three blades: dark roots, bright tips leaning outwards."""
    for bx, tip in ((0, -1), (1, 0), (2, 1)):
        cv.set(x + bx, y, dark)
        cv.set(x + bx, y - 1, dark if bx != 1 else light)
        cv.set(x + bx + tip, y - 2, light)
    cv.set(x + 1, y - 3, light)


def _flower(cv, x, y, ramp):
    cv.set(x, y - 1, ramp[1])
    cv.set(x - 1, y, ramp[1])
    cv.set(x + 1, y, ramp[1])
    cv.set(x, y + 1, ramp[0])
    cv.set(x, y, FLOWER_YELLOW[2] if ramp is not FLOWER_YELLOW else FLOWER_WHITE[2])
    cv.set(x - 1, y - 1, ramp[2])


def grass_tile(seed, tufts=2, specks=3, flowers=None, dense=False):
    cv = Canvas(T, T)
    cv.rect(0, 0, T, T, GRASS_BASE)
    if dense:  # tall-grass patch: darker blades everywhere, used in clusters
        r = rng(seed * 7)
        for _ in range(16):
            x, y = r.randrange(T), r.randrange(1, T)
            cv.set(x, y, GRASS[1])
            cv.set(x, y - 1, GRASS[2])
    r = rng(seed)
    for _ in range(specks):
        cv.set(r.randrange(T), r.randrange(T), GRASS[4] if r.random() < 0.6 else GRASS[2])
    for _ in range(tufts):
        _tuft(cv, r.randrange(1, T - 4), r.randrange(4, T - 1))
    for ramp in flowers or []:
        x, y = r.randrange(2, T - 2), r.randrange(2, T - 2)
        cv.set(x + 1, y + 2, GRASS[1])  # tiny stem shadow
        _flower(cv, x, y, ramp)
    return cv


def _paving(cv, seed):
    """Light flagstones in staggered rows, like a village street."""
    r = rng(seed)
    for row in range(4):
        y0 = row * 4
        x = r.randrange(0, 6)
        start = x
        while x < start + T:
            width = r.choice((5, 6, 7))
            tone = r.choice((PATH[2], PATH[2], PATH[2], PATH[1], PATH[3]))
            for bx in range(width - 1):
                for by in range(3):
                    color = tone
                    if by == 0 and tone != PATH[3]:
                        color = PATH[3]
                    elif by == 2 or bx == width - 2:
                        color = PATH[1] if tone != PATH[1] else PATH[0]
                    cv.set((x + bx) % T, y0 + by, color)
            cv.vline((x + width - 1) % T, y0, y0 + 2, PATH_JOINT)
            x += width
        cv.hline(0, T - 1, y0 + 3, PATH_JOINT)
    for _ in range(2):  # small chips
        cv.set(r.randrange(T), r.randrange(T), PATH_JOINT)


def _grass_fringe(cv, side, seed):
    """Grass spilling over the paving on one side, with a thin shadow line."""
    r = rng(seed)
    for i in range(T):
        depth = 1 + (r.random() < 0.55) + (r.random() < 0.2)
        for d in range(depth):
            if side == N:
                x, y = i, d
            elif side == S:
                x, y = i, T - 1 - d
            elif side == W:
                x, y = d, i
            else:
                x, y = T - 1 - d, i
            cv.set(x, y, GRASS_BASE if d < depth - 1 else GRASS[2])
        if side == N:
            cv.set(i, depth, PATH_JOINT)
        elif side == W:
            cv.set(depth, i, PATH_JOINT)
        elif side == S:
            cv.set(i, T - depth, GRASS[4])
        else:
            cv.set(T - depth, i, GRASS[3])


def path_tile(mask, seed=7):
    cv = Canvas(T, T)
    _paving(cv, seed)
    for side in (N, E, S, W):
        if mask & side:
            _grass_fringe(cv, side, seed * 31 + side)
    return cv


def ground_atlas():
    """Row 0: grass variants. Rows 1-2: path by grass-neighbour mask (0-15).
    Row 3: plain path variants (0-2) and tall-grass patches (3-4)."""
    grass = [
        grass_tile(1, tufts=1, specks=3),
        grass_tile(2, tufts=2, specks=2),
        grass_tile(3, tufts=0, specks=4),
        grass_tile(4, tufts=4, specks=2),
        grass_tile(5, tufts=1, specks=1, flowers=[FLOWER_WHITE, FLOWER_YELLOW]),
        grass_tile(6, tufts=1, specks=2, flowers=[FLOWER_PINK, FLOWER_PINK, FLOWER_WHITE]),
        grass_tile(7, tufts=2, specks=1, flowers=[FLOWER_BLUE, FLOWER_WHITE]),
        grass_tile(8, tufts=3, specks=3),
    ]
    atlas = Canvas(T * 8, T * 4)
    for i, tile in enumerate(grass):
        atlas.paste(tile, i * T, 0)
    for mask in range(16):
        atlas.paste(path_tile(mask), (mask % 8) * T, (1 + mask // 8) * T)
    for i, seed in enumerate((11, 12, 13)):
        atlas.paste(path_tile(0, seed), i * T, 3 * T)
    atlas.paste(grass_tile(21, tufts=4, specks=2, dense=True), 3 * T, 3 * T)
    atlas.paste(grass_tile(22, tufts=5, specks=3, dense=True), 4 * T, 3 * T)
    return atlas


def stone_wall():
    """Horizontally tileable retaining wall: grass lip, dressed stone, ivy and a plinth.

    Ground contact (sprite origin) is at y = 36.
    """
    width, height, top, foot = 64, 39, 6, 34
    cv = Canvas(width, height)
    r = rng(42)
    for i, y0 in enumerate(range(top, foot, 7)):
        x = -r.randrange(8)
        while x < width - 1:
            w = min(r.choice((10, 11, 12, 13, 14)), width - x) if x + 14 >= width else r.choice((10, 11, 12, 13, 14))
            tone = r.choice((STONE[2], STONE[3], STONE[3], STONE[2], STONE[1]))
            for bx in range(w - 1):
                for by in range(6):
                    color = tone
                    if by == 0:
                        color = STONE[4] if tone != STONE[1] else STONE[2]
                    elif by == 5 or bx == w - 2:
                        color = STONE[1] if tone != STONE[1] else STONE[0]
                    elif bx == 0:
                        color = STONE[3] if tone == STONE[2] else tone
                    cv.set((x + bx) % width, y0 + by, color)
            cv.vline((x + w - 1) % width, y0, y0 + 5, STONE_OUTLINE)
            x += w
        cv.hline(0, width - 1, y0 + 6, STONE_OUTLINE)
    cv.rect(0, foot, width, 2, STONE[1])  # plinth
    cv.hline(0, width - 1, foot, STONE[2])
    cv.hline(0, width - 1, foot + 2, STONE_OUTLINE)
    # grass lip with a ragged edge hanging over the first row of stones
    for x in range(width):
        hang = top + (r.random() < 0.5) + (r.random() < 0.25)
        for y in range(0, hang):
            cv.set(x, y, GRASS_BASE)
        cv.set(x, hang, GRASS[1])
        if r.random() < 0.3:
            cv.set(x, hang + 1, GRASS[1])
    for x in range(1, width - 4, 7):
        _tuft(cv, x + r.randrange(3), 4)
    # ivy hanging from the lip
    for vx, length in ((9, 18), (13, 11), (40, 24), (45, 9), (57, 14)):
        x = vx
        for y in range(top + 1, top + length):
            x += r.choice((0, 0, 0, -1, 1))
            cv.set(x, y, LEAF[1])
            if y % 3 == 0:
                lx = x + (1 if (y // 3) % 2 else -2)
                cv.rect(lx, y - 1, 2, 2, LEAF[3])
                cv.set(lx, y - 1, LEAF[4])
    cv.hline(0, width - 1, foot + 3, (16, 28, 30, 90))  # contact shadow on the ground
    cv.hline(0, width - 1, foot + 4, (16, 28, 30, 45))
    return cv
