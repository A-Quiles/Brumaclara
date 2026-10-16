"""Trees, bushes and rocks. Every sprite's origin is the bottom-centre of its base."""
from palette import (LEAF, LEAF_OUTLINE, PINE, PINE_OUTLINE, WOOD,
                     STONE, STONE_OUTLINE, MOSS, FLOWER_PINK, FLOWER_WHITE)
from pixel import Canvas, sphere_shade, rng


def _clumps(cv, circles, ramp, rim, bias_top=0.0, bias_bottom=-0.4):
    """Leaf clumps: each circle shaded on its own, with a dark rim where it overlaps another."""
    top = min(cy - r for cx, cy, r in circles)
    bottom = max(cy + r for cx, cy, r in circles)
    for cx, cy, r in sorted(circles, key=lambda c: c[1]):
        t = (cy - top) / max(1, bottom - top)
        bias = bias_top + (bias_bottom - bias_top) * t
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                nx, ny = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
                d = nx * nx + ny * ny
                if d > 1.0:
                    continue
                on_rim = d > (1 - 1.6 / r) ** 2 and ny > 0.1
                if on_rim and cv.opaque(x, y):
                    cv.set(x, y, rim)
                else:
                    cv.set(x, y, sphere_shade(nx, ny, ramp, bias))


def _leaf_texture(cv, ramp, seed, amount):
    r = rng(seed)
    for _ in range(amount):
        x, y = r.randrange(cv.w), r.randrange(cv.h)
        here = cv.get(x, y)
        if here[3] != 255 or here not in ramp:
            continue
        i = ramp.index(here)
        # small "leaf" marks: a lighter pixel with a darker one under it
        if 0 < i < len(ramp) - 1:
            cv.set(x, y, ramp[i + 1])
            if cv.get(x, y + 1) in ramp:
                cv.set(x, y + 1, ramp[i - 1])


def _trunk(cv, cx, base, top, width):
    for y in range(top, base + 1):
        flare = 2 if y >= base - 1 else (1 if y >= base - 3 else 0)
        x0, x1 = cx - width // 2 - flare, cx + width // 2 + flare - 1
        for x in range(x0, x1 + 1):
            t = (x - x0) / max(1, x1 - x0)
            color = WOOD[3] if t < 0.25 else WOOD[2] if t < 0.6 else WOOD[1]
            cv.set(x, y, color)
    for i, y in enumerate(range(top + 2, base - 3, 4)):  # bark strokes
        x = cx - 1 + (i % 2) * 2
        cv.set(x, y, WOOD[0])
        cv.set(x, y + 1, WOOD[0])
        cv.set(x - 1 + (i % 2) * 2, y + 2, WOOD[1])


def tree_oak():
    cv = Canvas(52, 60)
    cx, base = 26, 55
    cv.shadow(cx + 3, base + 0.5, 15, 3.5)
    _trunk(cv, cx, base, 36, 8)
    circles = [
        (26, 13, 10), (16, 17, 9), (36, 17, 9),
        (10, 26, 8), (42, 26, 8), (20, 24, 10), (32, 24, 10),
        (14, 34, 7), (38, 34, 7), (26, 34, 9),
    ]
    _clumps(cv, circles, LEAF, LEAF[0])
    _leaf_texture(cv, LEAF, 3, 220)
    cv.outline(LEAF_OUTLINE)
    return cv, (cx, base)


def tree_pine():
    cv = Canvas(38, 66)
    cx, base = 19, 62
    cv.shadow(cx + 3, base + 0.5, 11, 3)
    _trunk(cv, cx, base, 52, 6)
    # tiers from the bottom (widest, drawn first) to the top
    tiers = [(30, 56, 17), (20, 45, 14), (11, 34, 11), (3, 22, 7)]
    for apex, bottom, half in tiers:
        for y in range(apex, bottom + 1):
            span = half * (y - apex) / max(1, bottom - apex) + 1
            for x in range(int(cx - span), int(cx + span) + 1):
                tooth = abs(((x - cx) % 6) - 3)  # zig-zag lower edge
                if y > bottom - tooth:
                    continue
                t = (x - cx) / max(1.0, span)
                v = (y - apex) / max(1, bottom - apex)
                if t < -0.55:
                    color = PINE[4] if v < 0.7 else PINE[3]
                elif t < -0.1:
                    color = PINE[3]
                elif t < 0.45:
                    color = PINE[2]
                else:
                    color = PINE[1]
                if y >= bottom - tooth - 1:
                    color = PINE[1] if t < 0.45 else PINE[0]
                cv.set(x, y, color)
        # shadow cast by this tier on the one below
        for x in range(int(cx - half), int(cx + half) + 1):
            tooth = abs(((x - cx) % 6) - 3)
            y = bottom - tooth + 1
            if cv.opaque(x, y):
                cv.set(x, y, PINE[0])
    _leaf_texture(cv, PINE, 9, 90)
    cv.outline(PINE_OUTLINE)
    return cv, (cx, base)


def bush(flowers=False, seed=4):
    cv = Canvas(30, 24)
    cx, base = 15, 20
    cv.shadow(cx + 2, base, 12, 3)
    circles = [(9, 12, 7), (21, 12, 7), (15, 9, 7), (7, 16, 5), (23, 16, 5), (15, 15, 7)]
    _clumps(cv, circles, LEAF, LEAF[0], bias_top=0.12, bias_bottom=-0.25)
    _leaf_texture(cv, LEAF, seed, 70)
    if flowers:
        r = rng(seed + 100)
        placed = 0
        while placed < 9:
            x, y = r.randrange(5, 25), r.randrange(4, 17)
            if not (cv.opaque(x, y) and cv.opaque(x + 1, y + 1)):
                continue
            ramp = FLOWER_PINK if placed % 3 else FLOWER_WHITE
            cv.set(x, y, ramp[2])
            cv.set(x + 1, y, ramp[1])
            cv.set(x, y + 1, ramp[1])
            cv.set(x + 1, y + 1, ramp[0])
            placed += 1
    cv.outline(LEAF_OUTLINE)
    return cv, (cx, base)


def _rock(size, silhouette, top_face, crack, moss=False, seed=1):
    w, h, base = size
    cv = Canvas(w, h)
    cx = w // 2
    cv.shadow(cx + 2, base + 0.5, w * 0.42, 2.5)
    shape = Canvas(w, h)
    shape.polygon(silhouette, STONE[2])
    top = Canvas(w, h)
    top.polygon(top_face, STONE[3])
    for y in range(h):
        for x in range(w):
            if not shape.opaque(x, y):
                continue
            if top.opaque(x, y):
                lit = not top.opaque(x - 1, y - 1) or not top.opaque(x, y - 1)
                color = STONE[4] if lit else STONE[3]
            else:
                right = x > cx + (w * 0.18) - (y - base) * 0.3
                color = STONE[1] if right else STONE[2]
                if not top.opaque(x, y - 1) and top.opaque(x, y - 2):
                    color = STONE[1]  # edge under the top face
            cv.set(x, y, color)
    for x, y in crack:
        cv.set(x, y, STONE[0])
    if moss:
        r = rng(seed)
        for _ in range(26):
            x, y = r.randrange(w), r.randrange(h // 2)
            if top.opaque(x, y) and cv.opaque(x, y):
                cv.set(x, y, MOSS[r.randrange(2)])
                cv.set(x + 1, y, MOSS[1])
                if cv.get(x, y - 1)[3] == 255:
                    cv.set(x, y - 1, MOSS[2])
    cv.outline(STONE_OUTLINE)
    return cv, (cx, base)


def rock_small():
    return _rock((14, 12, 9),
                 [(1, 9), (1, 5), (4, 2), (9, 2), (12, 5), (12, 9)],
                 [(2, 5), (4, 2), (9, 2), (11, 5), (8, 6), (4, 6)],
                 [(7, 7), (7, 8)])


def rock_medium():
    return _rock((22, 17, 14),
                 [(1, 14), (1, 8), (5, 3), (12, 2), (18, 4), (20, 9), (20, 14)],
                 [(2, 8), (5, 3), (12, 2), (18, 4), (19, 8), (13, 10), (6, 10)],
                 [(11, 11), (12, 12), (12, 13), (5, 4), (6, 5)])


def rock_large():
    return _rock((36, 28, 24),
                 [(2, 24), (1, 16), (5, 9), (12, 4), (22, 3), (30, 7), (34, 14), (33, 24)],
                 [(3, 14), (6, 9), (12, 5), (22, 4), (29, 8), (31, 13), (22, 16), (11, 16)],
                 [(20, 18), (21, 19), (21, 20), (22, 21), (9, 7), (10, 8), (26, 9), (27, 10)],
                 moss=True, seed=5)
