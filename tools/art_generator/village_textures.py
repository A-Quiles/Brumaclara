"""Tileable village textures and wall-drawing helpers (12 texels = 1 world unit).

Colours are sampled from the project's reference image: warm brick, cream stone,
dark timber, four roof colours, beige paving, bright grass and blue water.
"""
from pixel import Canvas, hex_rgba as c, rng

T = 12  # texels per world unit

OUTLINE = c("#21150d")
TIMBER = [c("#26150b"), c("#3b2416"), c("#4f321f"), c("#664530"), c("#7f5a3e")]
BRICK = [c("#572d1b"), c("#7b4129"), c("#935034"), c("#a76340"), c("#ba744d"), c("#cd8a5c"), c("#e1a070")]
BRICK_BIG = [c("#6f3923"), c("#894c33"), c("#9c5637"), c("#af6b48"), c("#bc7b53"), c("#cc8b5e"), c("#e3a36f")]
CREAM = [c("#6b5844"), c("#9c8668"), c("#b39b78"), c("#c4ad88"), c("#d3be98"), c("#e2cfab")]
STONE = [c("#3a362d"), c("#555046"), c("#6c675a"), c("#807a6a"), c("#918a78"), c("#a39b88")]
FOUNTAIN = [c("#4a4539"), c("#6d6658"), c("#8b8473"), c("#a39b87"), c("#b8b09b"), c("#cbc3ad")]
GLASS = [c("#141b2b"), c("#222e45"), c("#33435d"), c("#56698a")]
WOOD = [c("#3a2414"), c("#52341f"), c("#6a4529"), c("#82583a"), c("#9c6e48")]
PAVING = [c("#8f836d"), c("#a49880"), c("#afa38a"), c("#b8ad95"), c("#c1b7a1"), c("#cac2ad")]
JOINT = c("#6f6350")
GRASS = [c("#33582c"), c("#456f36"), c("#58883f"), c("#6a9c48"), c("#82b258"), c("#a2c874")]
DIRT = [c("#8a5a2c"), c("#a8723c"), c("#c38a4c"), c("#d6a462")]
WATER = [c("#1d4c94"), c("#2c69bb"), c("#3b86da"), c("#62aeee"), c("#b5e2ff"), c("#ffffff")]
GOLD = c("#e2b54a")

ROOFS = {
    "orange": [c("#4a2416"), c("#6e3a26"), c("#86482f"), c("#9c5a3b"), c("#ae6b47"), c("#c2835a")],
    "blue": [c("#22303a"), c("#334656"), c("#43596a"), c("#55707f"), c("#6c8b96"), c("#90b0b4")],
    "teal": [c("#1b2e2d"), c("#28423f"), c("#355652"), c("#446b65"), c("#58827a"), c("#77a197")],
    "red": [c("#4a2218"), c("#6c3324"), c("#83432f"), c("#97553e"), c("#a9674e"), c("#be8068")],
}
INFILL = {"brick": BRICK, "cream": CREAM, "brick_big": BRICK_BIG, "stone": STONE}


# --- wall materials ---------------------------------------------------------

def bricks(cv, x0, y0, x1, y1, ramp, bw=3, bh=1, seed=0, mortar=0):
    """Running-bond bricks; mortar uses ramp[mortar]. Brick tones vary like hand-placed pixels."""
    r = rng(seed)
    cv.rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, ramp[mortar])
    for row, y in enumerate(range(y0, y1 + 1, bh + 1)):
        x = x0 - ((bw + 1) // 2 if row % 2 else 0)
        while x <= x1:
            tone = r.choice((2, 3, 3, 4, 4, 5, 3))
            for bx in range(bw):
                for by in range(bh):
                    px, py = x + bx, y + by
                    if x0 <= px <= x1 and py <= y1:
                        k = tone
                        if bh > 1 and by == 0 and bx < bw - 1:
                            k = min(len(ramp) - 1, tone + 1)
                        elif bh > 1 and by == bh - 1:
                            k = tone - 1
                        cv.set(px, py, ramp[k])
            x += bw + 1


def stones(cv, x0, y0, x1, y1, seed=0, row_h=4, ramp=STONE):
    """Dressed stone blocks with dark joints (foundations, ground floors)."""
    r = rng(seed)
    cv.rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, ramp[0])
    y = y0
    while y <= y1:
        x = x0 - r.randrange(4)
        while x <= x1:
            w = r.choice((5, 6, 7, 8))
            tone = r.choice((2, 3, 3, 4))
            for bx in range(w - 1):
                for by in range(row_h - 1):
                    px, py = x + bx, y + by
                    if x0 <= px <= x1 and py <= y1:
                        k = tone + 1 if by == 0 else (tone - 1 if by == row_h - 2 and row_h > 3 else tone)
                        cv.set(px, py, ramp[min(5, k)])
            x += w
        y += row_h


def beam_h(cv, x0, x1, y, thick=2):
    cv.rect(x0, y, x1 - x0 + 1, thick, TIMBER[2])
    cv.hline(x0, x1, y, TIMBER[3])
    if thick > 2:
        cv.hline(x0, x1, y + thick - 1, TIMBER[1])
    cv.hline(x0, x1, y + thick, OUTLINE)


def beam_v(cv, x, y0, y1, thick=2):
    cv.rect(x, y0, thick, y1 - y0 + 1, TIMBER[2])
    cv.vline(x, y0, y1, TIMBER[3])
    cv.vline(x + thick, y0, y1, OUTLINE)


def brace(cv, x0, y0, x1, y1):
    """Diagonal timber, 2 texels thick with a dark lower edge."""
    cv.line(x0, y0, x1, y1, TIMBER[3])
    cv.line(x0, y0 + 1, x1, y1 + 1, TIMBER[2])
    cv.line(x0, y0 + 2, x1, y1 + 2, OUTLINE)


def window(cv, x, y, w=8, h=8, sill=True, shutters=False):
    """Four-pane window: dark frame, navy glass with a reflection, wooden sill. (x, y) = top-left."""
    if shutters:
        for sx in (x - 3, x + w + 1):
            cv.rect(sx, y, 2, h, WOOD[2])
            cv.vline(sx, y, y + h - 1, WOOD[3])
    cv.rect(x - 1, y - 1, w + 2, h + 2, OUTLINE)
    cv.rect(x, y, w, h, TIMBER[3])
    cv.rect(x + 1, y + 1, w - 2, h - 2, GLASS[1])
    cv.hline(x + 1, x + w - 2, y + 1, GLASS[0])
    mx, my = x + w // 2, y + h // 2
    cv.vline(mx, y + 1, y + h - 2, TIMBER[3])
    cv.hline(x + 1, x + w - 2, my, TIMBER[3])
    cv.set(x + 2, my - 1, GLASS[3])
    cv.set(mx + 1, my + 1, GLASS[2])
    cv.set(x + 2, my + 2, GLASS[2])
    if sill:
        cv.hline(x - 1, x + w, y + h + 1, TIMBER[4])
        cv.hline(x - 1, x + w, y + h + 2, OUTLINE)


def door(cv, x, y, w, h, color=WOOD, arch=False):
    """Plank door with frame and a brass knob; (x, y) is the top-left of the door leaf."""
    cv.rect(x - 2, y - 2, w + 4, h + 2, OUTLINE)
    cv.rect(x - 1, y - 1, w + 2, h + 1, TIMBER[3])
    cv.rect(x, y, w, h, color[2])
    for px in range(x + 2, x + w - 1, 3):
        cv.vline(px, y, y + h - 1, color[1])
    cv.vline(x, y, y + h - 1, color[3])
    cv.hline(x, x + w - 1, y, color[0])
    cv.set(x + w - 3, y + h // 2, GOLD)
    if arch:
        cv.hline(x - 1, x + w, y - 3, TIMBER[3])


def border(cv, sides="lrb"):
    """Dark outline on the given texture edges (l, r, t, b)."""
    if "l" in sides:
        cv.vline(0, 0, cv.h - 1, OUTLINE)
    if "r" in sides:
        cv.vline(cv.w - 1, 0, cv.h - 1, OUTLINE)
    if "t" in sides:
        cv.hline(0, cv.w - 1, 0, OUTLINE)
    if "b" in sides:
        cv.hline(0, cv.w - 1, cv.h - 1, OUTLINE)


# --- roofs ------------------------------------------------------------------

def roof_slope(w_units, slope_units, color, tile=(6, 3), seed=3):
    """One roof slope: shingle rows parallel to the eave, dark verges, ridge cap at the top (v = 0)."""
    ramp = ROOFS[color]
    w, h = max(8, round(w_units * T)), max(6, round(slope_units * T))
    tw, th = tile
    cv = Canvas(w, h)
    r = rng(seed)
    cv.rect(0, 0, w, h, ramp[0])
    for row, y0 in enumerate(range(2, h, th + 1)):
        x0 = -(tw // 2 if row % 2 else 0) - r.randrange(2)
        while x0 < w:
            tone = r.choice((3, 3, 3, 2, 4, 3, 2))
            for bx in range(tw):
                for by in range(th):
                    px, py = x0 + bx, y0 + by
                    if 0 <= px < w and py < h:
                        k = tone
                        if by == 0 and bx < tw - 2:
                            k = min(5, tone + 1)
                        elif bx == tw - 1:
                            k = 1
                        cv.set(px, py, ramp[k])
            x0 += tw
    cv.rect(0, 0, w, 2, ramp[4])          # ridge cap
    cv.hline(0, w - 1, 2, ramp[1])
    for x in range(0, w, 4):
        cv.set(x, 0, ramp[5])
        cv.set(x + 3, 1, ramp[2])
    for x in (0, 1):                      # verges: dark line + lit barge edge
        cv.vline(x if x == 0 else 1, 0, h - 1, OUTLINE if x == 0 else ramp[4])
        cv.vline(w - 1 - x, 0, h - 1, OUTLINE if x == 0 else ramp[2])
    cv.hline(0, w - 1, h - 2, ramp[1])    # eave
    cv.hline(0, w - 1, h - 1, OUTLINE)
    return cv


def flat_roof(w, h, seed=5):
    """Tower top: wooden rim around a plank deck (w, h in texels)."""
    cv = Canvas(w, h)
    r = rng(seed)
    for y in range(h):
        tone = 2 + (y // 3) % 2
        cv.hline(0, w - 1, y, WOOD[tone])
        if y % 3 == 2:
            cv.hline(0, w - 1, y, WOOD[1])
    for _ in range(w * h // 30):
        cv.set(r.randrange(w), r.randrange(h), WOOD[1])
    cv.rect(0, 0, w, 3, TIMBER[3])
    cv.rect(0, h - 3, w, 3, TIMBER[2])
    cv.rect(0, 0, 3, h, TIMBER[3])
    cv.rect(w - 3, 0, 3, h, TIMBER[2])
    border(cv, "lrtb")
    return cv


# --- ground -----------------------------------------------------------------

def _stone(cv, x, y, w, h, r, ramp=PAVING, wrap=None):
    """One flat stone with a slightly lit top edge (low contrast, like worn flagstones)."""
    tone = r.choice((2, 3, 3, 4, 4, 1, 3))
    for bx in range(w):
        for by in range(h):
            px, py = x + bx, y + by
            if wrap:
                px, py = px % wrap[0], py % wrap[1]
            elif not (0 <= px < cv.w and 0 <= py < cv.h):
                continue
            k = min(5, tone + 1) if by == 0 and 0 < bx < w - 1 else tone
            cv.set(px, py, ramp[k])
    if r.random() < 0.3:  # a worn speck
        px, py = x + r.randrange(w), y + r.randrange(h)
        cv.set(px % cv.w, py % cv.h, ramp[max(1, tone - 1)])


def paving(seed=5):
    """48x48 tileable plaza flagstones in running bond (4 x 4 units)."""
    size = 48
    cv = Canvas(size, size)
    cv.rect(0, 0, size, size, PAVING[0])
    r = rng(seed)
    for row, y in enumerate(range(0, size, 4)):
        x = r.randrange(0, 6)
        start = x
        while x < start + size:
            ln = r.choice((6, 7, 8, 9, 10))
            if x + ln > start + size:
                ln = start + size - x
            if ln > 1:
                _stone(cv, x, y, ln - 1, 3, r, wrap=(size, size))
            x += ln
    return cv


def path(seed=8):
    """48x48 path tile: irregular cobbles between two curbs of long stones (u = 0 and u = 1 edges)."""
    size, cb = 48, 4
    cv = Canvas(size, size)
    cv.rect(0, 0, size, size, PAVING[0])
    r = rng(seed)
    y = 0
    while y < size:
        rh = r.choice((4, 5, 5, 6))
        if y + rh > size:
            rh = size - y
        x = cb + 1 - r.randrange(3)
        while x < size - cb - 1:
            sw = r.choice((5, 6, 6, 7, 8))
            tone = r.choice((2, 3, 3, 4, 1, 4))
            for bx in range(sw - 1):
                for by in range(rh - 1):
                    px, py = x + bx, y + by
                    if not (cb + 1 <= px < size - cb - 1):
                        continue
                    k = min(5, tone + 1) if by == 0 and 0 < bx < sw - 2 else tone
                    cv.set(px, py % size, PAVING[k])
            x += sw
        y += rh
    for x0 in (0, size - cb):  # curbs: long light stones with dark joints
        for y0 in range(0, size, 8):
            for bx in range(cb):
                for by in range(7):
                    k = 5 if by == 0 else (4 if bx in (1, 2) else 3)
                    cv.set(x0 + bx, y0 + by, PAVING[k])
            cv.hline(x0, x0 + cb - 1, y0 + 7, PAVING[0])
        cv.vline(x0 if x0 == 0 else x0 - 1, 0, size - 1, PAVING[0])
    return cv


def grass(seed=2, dark=False):
    """48x48 tileable grass with small tufts."""
    size = 48
    ramp = GRASS[:-1] if dark else GRASS[1:]
    cv = Canvas(size, size)
    cv.rect(0, 0, size, size, ramp[2])
    r = rng(seed)
    for _ in range(size * size // 9):
        x, y = r.randrange(size), r.randrange(size)
        cv.set(x, y, ramp[1])
    for _ in range(size * size // 18):
        x, y = r.randrange(size), r.randrange(size)
        cv.set(x, y, ramp[3])
    for _ in range(size // 2):  # tufts: dark base, light tips
        x, y = r.randrange(size), r.randrange(size)
        for dx, dy, k in ((0, 0, 1), (2, 0, 1), (1, 0, 1), (0, -1, 3), (2, -1, 3), (1, -2, 4)):
            cv.set((x + dx) % size, (y + dy) % size, ramp[k])
    return cv


def wall_blocks(seed=4):
    """48x24 tileable big stone blocks (4 x 2 units) for retaining walls, parapets and steps."""
    cv = Canvas(48, 24)
    r = rng(seed)
    cv.rect(0, 0, 48, 24, STONE[1])
    for row in range(4):
        y0 = row * 6
        x = -(row % 2) * 6
        while x < 48:
            w = r.choice((10, 12, 12, 14)) if x + 14 < 48 else 48 - x
            tone = r.choice((3, 4, 4, 3, 2))
            for bx in range(w - 1):
                for by in range(5):
                    k = tone
                    if by == 0:
                        k = min(5, tone + 1)
                    elif by == 4:
                        k = tone - 1
                    if bx == 0:
                        k = min(5, k + 1)
                    cv.set((x + bx) % 48, y0 + by, STONE[k])
            x += w
    return cv


def wall_top(seed=6):
    """24x24 coping stones for the top of walls."""
    cv = Canvas(24, 24)
    cv.rect(0, 0, 24, 24, STONE[2])
    for y0 in (0, 12):
        for x0 in ((0, 12) if y0 == 0 else (6, -6, 18)):
            for bx in range(11):
                for by in range(11):
                    k = 5 if (by == 0 or bx == 0) else (3 if by == 10 or bx == 10 else 4)
                    cv.set((x0 + bx) % 24, y0 + by, STONE[k])
    return cv


def wood_planks(seed=1):
    cv = Canvas(24, 24)
    r = rng(seed)
    for y0 in range(0, 24, 4):
        tone = r.choice((2, 3, 3, 4))
        cv.rect(0, y0, 24, 3, WOOD[tone])
        cv.hline(0, 23, y0, WOOD[min(4, tone + 1)])
        cv.hline(0, 23, y0 + 3, WOOD[0])
        cv.set(r.randrange(24), y0 + 1, WOOD[tone - 1])
    return cv


def awning(kind):
    """24x24 striped canvas (2 x 2 units); stripes run down the slope, dark scalloped hem at the bottom."""
    stripes = {
        "rainbow": ["#d9413a", "#ef8a33", "#f5cf3d", "#3f8ee0", "#4b63cf", "#8a50c2"],
        "green": ["#2a9a6a", "#8fe0aa", "#2a9a6a", "#8fe0aa", "#2a9a6a", "#8fe0aa"],
        "purple": ["#7d5a92", "#8f6aa4", "#7d5a92", "#8f6aa4", "#7d5a92", "#8f6aa4"],
    }[kind]
    cv = Canvas(24, 24)
    for i, hexcol in enumerate(stripes):
        col = c(hexcol)
        dark = tuple(int(v * 0.78) for v in col[:3]) + (255,)
        light = tuple(min(255, int(v * 1.12)) for v in col[:3]) + (255,)
        cv.rect(i * 4, 0, 4, 24, col)
        cv.vline(i * 4, 0, 23, light)
        cv.vline(i * 4 + 3, 0, 23, dark)
    cv.hline(0, 23, 0, OUTLINE)
    cv.hline(0, 23, 23, OUTLINE)
    return cv


def water(frame=0):
    """24x24 tileable water with sparkles; frames shift the highlights."""
    cv = Canvas(24, 24)
    cv.rect(0, 0, 24, 24, WATER[2])
    r = rng(11)
    for _ in range(16):
        x, y = r.randrange(24), r.randrange(24)
        cv.hline(x, x + r.randrange(2, 5), (y + frame * 3) % 24, WATER[3])
    for _ in range(7):
        x, y = r.randrange(24), r.randrange(24)
        yy = (y + frame * 5) % 24
        cv.set(x, yy, WATER[5])
        cv.set((x + 1) % 24, yy, WATER[4])
    return cv


def fountain_stone(seed=9):
    """24x6 outer face of the fountain basin (2 x 0.5 units): two courses of grey blocks."""
    side = [c("#4d4943"), c("#635e57"), c("#79736b"), c("#89837a"), c("#9a948a")]
    cv = Canvas(24, 6)
    cv.rect(0, 0, 24, 6, side[1])
    r = rng(seed)
    for row, y0 in enumerate((0, 3)):
        for x0 in range(-4 * row, 24, 8):
            tone = r.choice((3, 3, 4)) - row
            for bx in range(7):
                cv.set((x0 + bx) % 24, y0, side[min(4, tone + 1)])
                cv.set((x0 + bx) % 24, y0 + 1, side[tone])
    return cv


def fountain_top(seed=10):
    """24x24 rim of the fountain basin seen from above: light slabs with soft joints."""
    cv = Canvas(24, 24)
    cv.rect(0, 0, 24, 24, FOUNTAIN[4])
    r = rng(seed)
    for y in range(0, 24, 6):
        cv.hline(0, 23, y, FOUNTAIN[3])
        for x in range(r.randrange(6), 24, 6):
            cv.vline(x, y, y + 5, FOUNTAIN[3])
    for _ in range(30):
        cv.set(r.randrange(24), r.randrange(24), FOUNTAIN[5])
    return cv


def plaza_border(w_units, h_units, band_units=0.45, seed=21):
    """Inset band of the plaza: light slabs laid along a rectangle, framed by dark joints; the rest is clear."""
    w, h, b = round(w_units * T), round(h_units * T), max(3, round(band_units * T))
    cv = Canvas(w, h)
    r = rng(seed)
    for y in range(h):
        for x in range(w):
            if b <= x < w - b and b <= y < h - b:
                continue
            cv.set(x, y, PAVING[r.choice((3, 4, 4, 5))])
    for x in range(0, w, 6):  # joints across the band
        cv.vline(x, 0, b - 1, PAVING[1])
        cv.vline(x, h - b, h - 1, PAVING[1])
    for y in range(0, h, 6):
        cv.hline(0, b - 1, y, PAVING[1])
        cv.hline(w - b, w - 1, y, PAVING[1])
    for x0, y0, x1, y1 in ((0, 0, w - 1, h - 1), (b, b, w - 1 - b, h - 1 - b)):
        cv.hline(x0, x1, y0, JOINT)
        cv.hline(x0, x1, y1, JOINT)
        cv.vline(x0, y0, y1, JOINT)
        cv.vline(x1, y0, y1, JOINT)
    return cv


def dirt_patch(seed=1):
    cv = Canvas(28, 18)
    r = rng(seed)
    for _ in range(5):
        cx, cy = r.uniform(7, 21), r.uniform(5, 13)
        cv.ellipse(cx, cy, r.uniform(4, 8), r.uniform(3, 5), DIRT[2])
    for y in range(cv.h):
        for x in range(cv.w):
            if cv.opaque(x, y) and not cv.opaque(x, y - 1):
                cv.set(x, y, DIRT[3])
            elif cv.opaque(x, y) and r.random() < 0.12:
                cv.set(x, y, DIRT[1])
    return cv


def blob_shadow():
    cv = Canvas(16, 8)
    cv.ellipse(8, 4, 7.5, 3.6, (16, 28, 30, 105))
    return cv
