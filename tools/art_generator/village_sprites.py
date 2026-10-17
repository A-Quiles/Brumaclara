"""Billboard sprites for the village: villagers, pines, bushes and props.

Villagers are 18x22 chibi figures built from a head template, a hair template and an outfit
template. Region letters are shaded automatically (lit top-left, shaded right side) and the
silhouette gets a dark outline, matching the reference image.
"""
from pixel import Canvas, hex_rgba as c, rng

OUTLINE = c("#1c1420")
SKIN = [c("#c98a6c"), c("#efbf9a"), c("#fad8b8")]
EYE, EYE_HI, MOUTH, CHEEK = c("#1d1a2c"), c("#ffffff"), c("#9c4a44"), c("#f0a08c")

FACE = [
    "..................",
    "..................",
    ".....SSSSSSSS.....",
    "...SSSSSSSSSSSS...",
    "..SSSSSSSSSSSSSS..",
    "..SSSEWSSSSEWSSS..",
    "..SSSEESSSSEESSS..",
    "..SCSSSSSSSSSSCS..",
    "...SSSSSMMSSSSS...",
    ".....SSSSSSSS.....",
]

HAIR = {
    "puffy": [
        ".....HHHHHHHH.....",
        "...HHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHH.",
        ".HHH..........HHH.",
        ".HH............HH.",
        "..H............H..",
    ],
    "long": [
        "....HHHHHHHHHH....",
        "..HHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHH.HHHHHHHHH.",
        ".HHH..........HHH.",
        ".HH............HH.",
        ".HH............HH.",
        ".HH............HH.",
        ".HHH..........HHH.",
        ".HHH..........HHH.",
        "..HH..........HH..",
    ],
    "bob": [
        "....HHHHHHHHHH....",
        "..HHHHHHHHHHHHHH..",
        "..AAAAAAAAAAAAAA..",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHH.",
        ".HHH..........HHH.",
        ".HH............HH.",
        ".HH............HH.",
        ".HHH..........HHH.",
    ],
    "curly": [
        "...HH.HHHH.HH.....",
        "..HHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        "HHHH.HH.HH.H.HHHHH",
        "HHH............HHH",
        "HHH............HHH",
        ".HH............HH.",
        ".HHH..........HHH.",
    ],
    "bangs": [
        ".....HHHHHHHH.....",
        "...HHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHH.",
        ".HH.HH.HH.HH.HHHH.",
        ".HH............HH.",
        ".HH............HH.",
        "..H............H..",
    ],
    "cap": [
        "....AAAAAAAAAA....",
        "..AAAAAAAAAAAAAA..",
        ".AAAAAAAAAAAAAAAA.",
        ".AAAAAAAAAAAAAAAA.",
        ".HAAAAAAAAAAAAAAH.",
        ".HH............HH.",
        ".H..............H.",
    ],
    "bald": [
        "..................",
        "..................",
        "..................",
        "..................",
        ".NN............NN.",
        ".NN............NN.",
        ".N..............N.",
        "..................",
        "...NN........NN...",
        "...NNNNNNNNNNNN...",
        "....NNNNNNNNNN....",
        "......NNNNNN......",
    ],
    "back": [
        ".....HHHHHHHH.....",
        "...HHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHH.",
        ".SHHHHHHHHHHHHHHS.",
        ".SHHHHHHHHHHHHHHS.",
        "..HHHHHHHHHHHHHH..",
        "...HHHHHHHHHHHH...",
        ".....HHHHHHHH.....",
    ],
    "helmet": [
        ".....YYYYYYYY.....",
        "...YYYYYYYYYYYY...",
        "..YYYYYYYYYYYYYY..",
        "..YYYYYYYYYYYYYY..",
        "..YYYooooooooYYY..",
        "..YYo........oYY..",
        "..YYo........oYY..",
        "..YYY........YYY..",
        "..YYYY......YYYY..",
        "...YYYYYYYYYYYY...",
    ],
    "plume": [
        "........QQ........",
        ".......QQQQ.......",
        ".....YYYYYYYY.....",
        "...YYYYYYYYYYYY...",
        "..YYYYYYYYYYYYYY..",
        "..YYYooooooooYYY..",
        "..YYo........oYY..",
        "..YYY........YYY..",
        "..YYYY......YYYY..",
        "...YYYYYYYYYYYY...",
    ],
}

BODY = {
    "tunic": [
        "......SSSSSS......",
        "....TTTTTTTTTT....",
        "...KTTTTTTTTTTK...",
        "..KKTTTVVVTTTTKK..",
        "..KKTTTTTTTTTTKK..",
        "..SSTTTTTTTTTTSS..",
        "....AAAAAAAAAA....",
        "....TTTTTTTTTT....",
        "....PPPP..PPPP....",
        "....PPPP..PPPP....",
        "....FFFF..FFFF....",
        "...FFFFF..FFFFF...",
    ],
    "dress": [
        "......SSSSSS......",
        "....TTTTTTTTTT....",
        "...KTTTTTTTTTTK...",
        "..KKTTTTTTTTTTKK..",
        "..KKTTTAAAATTTKK..",
        "..SSGGGGGGGGGGSS..",
        "...GGGGGGGGGGGG...",
        "...GGGGGGGGGGGG...",
        "..GGGGGGGGGGGGGG..",
        ".....PP....PP.....",
        ".....FFF...FFF....",
        ".....FFF...FFF....",
    ],
    "robe": [
        "......SSSSSS......",
        "....TTTTTTTTTT....",
        "...KTTTTTTTTTTK...",
        ".BKKTTTTTTTTTTKK..",
        ".BKKTTTTTTTTTTKK..",
        ".BSSTTTTAAATTTSS..",
        ".B..TTTTTTTTTT....",
        ".B..TTTTTTTTTT....",
        ".B..TTTTTTTTTT....",
        ".B...TTTTTTTT.....",
        ".B..FFFF..FFFF....",
        ".B.FFFFF..FFFFF...",
    ],
    "armor": [
        "......YYYYYY......",
        "..RXXXXXXXXXXXXR..",
        ".RXXXXXXXXXXXXXXR.",
        ".RXKXXXXXXXXXXKXR.",
        ".RKKXXXXXXXXXXKKR.",
        ".RSSXXXXXXXXXXSSR.",
        ".RRRAAAAAAAAAARRR.",
        ".RR.XXXXXXXXXX.RR.",
        "..R.XXXX..XXXX.R..",
        "....XXXX..XXXX....",
        "....FFFF..FFFF....",
        "...FFFFF..FFFFF...",
    ],
    "counter": [  # vendor behind a counter: only the upper body is drawn
        "......SSSSSS......",
        "....TTTTTTTTTT....",
        "...KTTTTTTTTTTK...",
        "..KKTTTVVVTTTTKK..",
        "..KKTTTTTTTTTTKK..",
        "..SSTTTTTTTTTTSS..",
    ],
}

# region -> ramp key in the villager's palette
REGIONS = {"H": "hair", "A": "accent", "T": "top", "V": "patch", "K": "sleeve", "P": "pants", "F": "feet",
           "G": "skirt", "X": "metal", "Y": "helmet", "R": "cape", "Q": "plume", "N": "beard", "B": "item"}


def ramp(*hexes):
    return [c(h) for h in hexes]


VILLAGERS = {
    "boy": dict(hair="puffy", body="tunic", pal={"hair": ramp("#5e2e1a", "#8a4a2a", "#b06a40"),
                "top": ramp("#46523e", "#62705a", "#7e8c74"), "patch": ramp("#5a8a4a", "#8cc070", "#b8e098"),
                "sleeve": ramp("#8a8a90", "#b0b0b8", "#d0d0d8"), "accent": ramp("#3a2a20", "#5a4030", "#7a5840"),
                "pants": ramp("#2a2434", "#3a3448", "#4a445a"), "feet": ramp("#1e1820", "#2e2430", "#3e3440")}),
    "oldman": dict(hair="bald", body="robe", pal={"beard": ramp("#b8b0a4", "#e0d8cc", "#f8f4ec"),
                   "top": ramp("#4a3a34", "#6a5248", "#86685a"), "sleeve": ramp("#5a4a40", "#7a6254", "#967a6a"),
                   "accent": ramp("#7a5a2a", "#a07a3a", "#c09a50"), "feet": ramp("#2a2024", "#3a2e30", "#4a3c3e"),
                   "item": ramp("#4a3020", "#6a4a30", "#8a6a48")}),
    "woman_purple": dict(hair="long", body="dress", pal={"hair": ramp("#3e3e78", "#5a5aa0", "#7e80c4"),
                         "top": ramp("#6888b0", "#90b0d8", "#b8d4f0"), "sleeve": ramp("#6888b0", "#90b0d8", "#b8d4f0"),
                         "accent": ramp("#3a3a5a", "#50506e", "#686886"), "skirt": ramp("#4e4e5c", "#6a6a7a", "#8a8a98"),
                         "pants": ramp("#d8b090", "#efc6a0", "#f8d8b8"), "feet": ramp("#2a2a36", "#3a3a48", "#4a4a5a")}),
    "woman_lilac": dict(hair="bob", body="dress", pal={"hair": ramp("#4a3e88", "#6a5aae", "#8e7ed0"),
                        "accent": ramp("#c0a040", "#e0c060", "#f8e090"), "top": ramp("#7a6aa8", "#a090cc", "#c4b8e8"),
                        "sleeve": ramp("#7a6aa8", "#a090cc", "#c4b8e8"), "skirt": ramp("#6a5a98", "#8a7abc", "#aa9cd8"),
                        "pants": ramp("#5a4a7a", "#6a5a8e", "#7a6aa0"), "feet": ramp("#3a2e4e", "#4a3e62", "#5a4e76")}),
    "merchant": dict(hair="back", body="tunic", pal={"hair": ramp("#5a2e1a", "#7e4528", "#a26238"),
                     "top": ramp("#355a44", "#4a7a5a", "#64987a"), "patch": ramp("#355a44", "#4a7a5a", "#64987a"),
                     "sleeve": ramp("#355a44", "#4a7a5a", "#64987a"), "accent": ramp("#3a2a20", "#5a4030", "#7a5840"),
                     "pants": ramp("#3e2e24", "#564034", "#6e5444"), "feet": ramp("#1e1820", "#2e2430", "#3e3440")}),
    "girl_orange": dict(hair="curly", body="dress", pal={"hair": ramp("#a8561e", "#d8803a", "#f4aa5e"),
                        "top": ramp("#6a2e34", "#8a3e44", "#aa5a5a"), "sleeve": ramp("#6a2e34", "#8a3e44", "#aa5a5a"),
                        "accent": ramp("#2a5aa0", "#4a8ad8", "#7ab4f0"), "skirt": ramp("#7a5050", "#9a6a66", "#b88a82"),
                        "pants": ramp("#d8b090", "#efc6a0", "#f8d8b8"), "feet": ramp("#2a2024", "#3a2e30", "#4a3c3e")}),
    "knight": dict(hair="helmet", body="armor", pal={"helmet": ramp("#6a7080", "#a8aeba", "#dce0e8"),
                   "metal": ramp("#6a7080", "#a8aeba", "#dce0e8"), "sleeve": ramp("#5a606e", "#8a909c", "#b8bcc8"),
                   "cape": ramp("#5a1418", "#8a2228", "#b03a3a"), "accent": ramp("#5a3a24", "#7a5234", "#9a6c48"),
                   "feet": ramp("#3a3e48", "#555a66", "#727884")}),
    "guard": dict(hair="plume", body="armor", pal={"helmet": ramp("#4e5260", "#7a7e8c", "#a6aab6"),
                  "plume": ramp("#8a1a1a", "#c83030", "#f05a4a"), "metal": ramp("#4e5260", "#7a7e8c", "#a6aab6"),
                  "sleeve": ramp("#3e4250", "#5e6270", "#7e8290"), "cape": ramp("#2e3240", "#3e4252", "#4e5264"),
                  "accent": ramp("#5a3a24", "#7a5234", "#9a6c48"), "feet": ramp("#2a2e38", "#3a3e4a", "#4a4e5a")}),
    "girl_brown": dict(hair="bangs", body="dress", pal={"hair": ramp("#8a3e1e", "#b4602e", "#d8844a"),
                       "top": ramp("#b8642a", "#e08a40", "#f4ae66"), "sleeve": ramp("#b8642a", "#e08a40", "#f4ae66"),
                       "accent": ramp("#c8c0b0", "#ece6da", "#ffffff"), "skirt": ramp("#a8542a", "#d07a3c", "#ec9e5a"),
                       "pants": ramp("#d8b090", "#efc6a0", "#f8d8b8"), "feet": ramp("#3a2a20", "#4e3a2c", "#624a3a")}),
    "girl_red": dict(hair="bangs", body="dress", pal={"hair": ramp("#7e2e1a", "#a8462a", "#cc6640"),
                     "top": ramp("#6a4a2e", "#8a643e", "#aa8254"), "sleeve": ramp("#6a4a2e", "#8a643e", "#aa8254"),
                     "accent": ramp("#7a2a20", "#a03a2e", "#c05a48"), "skirt": ramp("#7a5434", "#9a6e46", "#b88c5e"),
                     "pants": ramp("#d8b090", "#efc6a0", "#f8d8b8"), "feet": ramp("#2a2024", "#3a2e30", "#4a3c3e")}),
    "boy_blue": dict(hair="cap", body="tunic", pal={"hair": ramp("#2a2a44", "#3a3a5a", "#4a4a70"),
                     "accent": ramp("#22408a", "#3460b8", "#5a86dc"), "top": ramp("#2c4a9a", "#3e66c4", "#628ae0"),
                     "patch": ramp("#2c4a9a", "#3e66c4", "#628ae0"), "sleeve": ramp("#2c4a9a", "#3e66c4", "#628ae0"),
                     "pants": ramp("#22263a", "#30344c", "#40445e"), "feet": ramp("#1e1820", "#2e2430", "#3e3440")}),
    "kid_a": dict(hair="puffy", body="tunic", pal={"hair": ramp("#4e2a1a", "#704030", "#946048"),
                  "top": ramp("#4a3a5e", "#62507a", "#7c6a96"), "patch": ramp("#8a8090", "#b0a8b8", "#d0c8d8"),
                  "sleeve": ramp("#8a8090", "#b0a8b8", "#d0c8d8"), "accent": ramp("#3a2a20", "#5a4030", "#7a5840"),
                  "pants": ramp("#2a2434", "#3a3448", "#4a445a"), "feet": ramp("#1e1820", "#2e2430", "#3e3440")}),
    "kid_b": dict(hair="puffy", body="tunic", pal={"hair": ramp("#7a4a22", "#a06a34", "#c4904e"),
                  "top": ramp("#8aa8c8", "#b4cce4", "#dcecf8"), "patch": ramp("#6a90c0", "#8ab0dc", "#b0d0f0"),
                  "sleeve": ramp("#8aa8c8", "#b4cce4", "#dcecf8"), "accent": ramp("#3a4a6a", "#4e6084", "#62769e"),
                  "pants": ramp("#3a4458", "#4c5870", "#5e6c88"), "feet": ramp("#1e1820", "#2e2430", "#3e3440")}),
    "vendor": dict(hair="puffy", body="counter", pal={"hair": ramp("#b08a2a", "#d8b448", "#f4d878"),
                   "top": ramp("#3e6a3a", "#548c4e", "#74ac66"), "patch": ramp("#c8c0b0", "#ece6da", "#ffffff"),
                   "sleeve": ramp("#3e6a3a", "#548c4e", "#74ac66")}),
}

# world height (units) of each villager, measured on the reference image
HEIGHTS = {"boy": 1.6, "oldman": 1.45, "woman_purple": 1.6, "woman_lilac": 1.5, "merchant": 1.5,
           "girl_orange": 1.75, "knight": 1.9, "guard": 1.6, "girl_brown": 1.4, "girl_red": 1.6,
           "boy_blue": 1.65, "kid_a": 1.6, "kid_b": 1.6, "vendor": 1.55}


def _shade_regions(cv, grid, palette, letters):
    """Paints region letters with automatic light (top-left) and shade (right side) tones."""
    h, w = len(grid), len(grid[0])
    for y in range(h):
        for x in range(w):
            ch = grid[y][x]
            if ch not in letters:
                continue
            ramp_ = palette.get(REGIONS[ch])
            if ramp_ is None:
                continue
            same = lambda xx, yy: 0 <= yy < h and 0 <= xx < w and grid[yy][xx] == ch
            run_right = 0
            while same(x + run_right + 1, y):
                run_right += 1
            run_left = 0
            while same(x - run_left - 1, y):
                run_left += 1
            run = run_left + run_right + 1
            k = 1
            if not same(x, y - 1) and run >= 3 and run_left < run - 2:
                k = 2
            elif not same(x - 1, y) and run >= 4:
                k = 2
            if run >= 3 and run_right < max(1, run // 4):
                k = 0
            if not same(x, y + 1) and run >= 4 and k == 1:
                k = 0
            cv.set(x, y, ramp_[k])


def villager(kind, frame=0):
    """18x24 front-facing villager (22 rows of art plus outline margins); frame 1 bobs the upper body."""
    spec = VILLAGERS[kind]
    pal = spec["pal"]
    cv = Canvas(18, 22)
    body = BODY[spec["body"]]
    top = 10
    bob = 1 if frame else 0
    # legs first (they don't bob), then the upper body
    legs_from = 8 if spec["body"] != "counter" else 99
    body_grid = ["." * 18] * top + body + ["." * 18] * (22 - top - len(body))
    upper = [row if i < top + legs_from else "." * 18 for i, row in enumerate(body_grid)]
    lower = [row if i >= top + legs_from else "." * 18 for i, row in enumerate(body_grid)]
    _shade_regions(cv, lower, pal, "PFGXBR")
    head = Canvas(18, 22)
    face = FACE + ["." * 18] * 12
    if spec["hair"] in ("back",):
        face = ["." * 18] * 22
    for y, row in enumerate(face):
        for x, ch in enumerate(row):
            if ch == "S":
                head.set(x, y, SKIN[1] if x < 13 else SKIN[0])
            elif ch == "C":
                head.set(x, y, CHEEK)
            elif ch == "E":
                head.set(x, y, EYE)
            elif ch == "W":
                head.set(x, y, EYE_HI)
            elif ch == "M":
                head.set(x, y, MOUTH)
    upper_grid = [list(r) for r in upper]
    hair = HAIR[spec["hair"]]
    for y, row in enumerate(hair):
        for x, ch in enumerate(row):
            if ch != ".":
                upper_grid[y][x] = ch if ch != "o" else "o"
    upper_grid = ["".join(r) for r in upper_grid]
    _shade_regions(head, upper_grid, pal, "HAYQNTVKGXRB")
    for y, row in enumerate(upper_grid):
        for x, ch in enumerate(row):
            if ch == "o":
                head.set(x, y, OUTLINE)
            elif ch == "S" and y >= len(hair):
                head.set(x, y, SKIN[1] if x < 12 else SKIN[0])
            elif ch == "S" and spec["hair"] == "back":
                head.set(x, y, SKIN[0])
    cv.img.alpha_composite(head.img, (0, bob))
    framed = Canvas(18, 24)
    framed.paste(cv, 0, 1)
    framed.outline(OUTLINE)
    return framed


def villager_sheet(kind):
    """Two idle frames side by side (36x24); the feet's outline sits on the bottom row."""
    sheet = Canvas(36, 24)
    sheet.paste(villager(kind, 0), 0, 0)
    sheet.paste(villager(kind, 1), 18, 0)
    return sheet


# --- vegetation ---------------------------------------------------------------

PINE = ramp("#123226", "#1c4433", "#255a3a", "#2f6e3e", "#3f8540", "#579a48", "#77b35c")
TRUNK = ramp("#3a2214", "#5a3620", "#7a4e30", "#965f3a")
PINE_OUTLINE = c("#10241a")


def pine(w=34, h=62, tiers=5, seed=1):
    """Layered pine like the reference: tufted tiers, light tops, dark undersides. Origin = trunk base."""
    cv = Canvas(w, h)
    r = rng(seed)
    cx = w / 2 - 0.5
    trunk_h = max(3, h // 8)
    foliage_bottom = h - trunk_h + 1
    tw = max(2, round(w / 6))
    for y in range(foliage_bottom - 3, h):
        flare = 1 if y >= h - 2 else 0
        x0, x1 = round(cx - tw / 2) - flare, round(cx + tw / 2) + flare
        for x in range(x0, x1 + 1):
            t = (x - x0) / max(1, x1 - x0)
            cv.set(x, y, TRUNK[3] if t < 0.3 else TRUNK[2] if t < 0.7 else TRUNK[1])
    # tier i spans [top_i, bottom_i]; tiers overlap so each tuft row hangs over the next tier
    step = foliage_bottom / (tiers + 0.6)
    for i in reversed(range(tiers)):
        top = round(i * step * 0.92)
        bottom = round(min(foliage_bottom, top + step * 1.75))
        half_bottom = (w / 2 - 1) * (0.42 + 0.58 * (i + 1) / tiers)
        phase = r.randrange(5)
        for y in range(top, bottom + 1):
            t = (y - top) / max(1, bottom - top)
            half = 0.8 + half_bottom * (t ** 0.75)
            jag = 1 if (y + i) % 3 == 0 and t > 0.3 else 0
            for x in range(round(cx - half) - jag, round(cx + half) + jag + 1):
                period_pos = (x + phase) % 5
                tuft_len = (0, 1, 2, 1, 0)[period_pos] + (1 if t > 0.5 and period_pos == 2 else 0)
                if y > bottom - 3 + tuft_len:
                    continue
                rel = (x - cx) / max(1.0, half)
                if t < 0.35:
                    k = 6 if rel < -0.3 else 5 if rel < 0.25 else 4
                elif t < 0.7:
                    k = 5 if rel < -0.5 else 4 if rel < 0.1 else 3
                else:
                    k = 3 if rel < -0.2 else 2
                if y >= bottom - 3 + tuft_len - 1:
                    k = min(k, 2) if rel > -0.4 else min(k, 3)
                if i == tiers - 1 and t > 0.6:
                    k = max(1, k - 1)
                cv.set(x, y, PINE[k])
        for _ in range(int(half_bottom * (bottom - top) / 5)):  # leaf clumps
            y = r.randint(top + 1, max(top + 1, bottom - 2))
            t = (y - top) / max(1, bottom - top)
            half = 0.8 + half_bottom * (t ** 0.75)
            x = r.randint(round(cx - half), round(cx + half))
            if cv.opaque(x, y) and cv.opaque(x + 1, y):
                rel = (x - cx) / max(1.0, half)
                if rel < 0.2:
                    cv.set(x, y, PINE[min(6, 5 if t < 0.5 else 4)])
                    cv.set(x + 1, y, PINE[3 if t < 0.5 else 2])
                else:
                    cv.set(x, y, PINE[1])
    cv.outline(PINE_OUTLINE)
    return cv


LEAF = ramp("#1d4428", "#2a5e30", "#38783a", "#4a9244", "#62ac52", "#86c46a")


def bush(w=24, h=16, seed=3):
    cv = Canvas(w, h)
    r = rng(seed)
    blobs = [(w * 0.3, h * 0.55, h * 0.42), (w * 0.7, h * 0.55, h * 0.42), (w * 0.5, h * 0.42, h * 0.48)]
    for bx, by, rad in sorted(blobs, key=lambda b: b[1]):
        for y in range(int(by - rad) - 1, int(by + rad) + 2):
            for x in range(int(bx - rad) - 1, int(bx + rad) + 2):
                nx, ny = (x + 0.5 - bx) / rad, (y + 0.5 - by) / rad
                d = nx * nx + ny * ny
                if d <= 1.0:
                    light = -nx * 0.6 - ny * 0.8
                    k = 2 + (light > 0.2) + (light > 0.6) - (light < -0.4)
                    cv.set(x, y, LEAF[max(0, min(5, k))])
    for _ in range(w * h // 8):
        x, y = r.randrange(w), r.randrange(h)
        if cv.opaque(x, y):
            col = cv.get(x, y)
            i = LEAF.index(col) if col in LEAF else 2
            cv.set(x, y, LEAF[min(5, i + 1)] if x < w / 2 else LEAF[max(0, i - 1)])
    cv.outline(PINE_OUTLINE)
    return cv


# --- props --------------------------------------------------------------------

WOOD = ramp("#3a2214", "#5a3620", "#7a4e30", "#965f3a", "#b07a4e")
METAL = ramp("#3a3e48", "#6a707c", "#9aa0aa", "#c8ccd4")


def barrel(w=12, h=14):
    cv = Canvas(w, h)
    for y in range(2, h):
        bulge = 1 if 4 <= y <= h - 4 else 0
        x0, x1 = 1 - bulge, w - 2 + bulge
        for x in range(x0, x1 + 1):
            t = (x - x0) / max(1, x1 - x0)
            cv.set(x, y, WOOD[4] if t < 0.2 else WOOD[3] if t < 0.6 else WOOD[2])
        for sx in range(x0 + 3, x1, 3):
            cv.set(sx, y, WOOD[1])
    for hy in (4, h - 4):
        cv.hline(0, w - 1, hy, METAL[1])
    cv.ellipse(w / 2, 2.5, w / 2 - 1, 2, WOOD[3])
    cv.ellipse(w / 2, 2.5, w / 2 - 2.5, 1.2, WOOD[2])
    cv.outline(OUTLINE)
    return cv


def crate(w=20, h=20, stacked=False):
    cv = Canvas(w, h)

    def one(y0, hh):
        top = max(3, hh // 4)
        cv.rect(1, y0, w - 2, top, WOOD[4])
        cv.hline(1, w - 2, y0 + top - 1, WOOD[3])
        cv.rect(1, y0 + top, w - 2, hh - top, WOOD[3])
        for y in range(y0 + top + 2, y0 + hh - 1, 3):
            cv.hline(2, w - 3, y, WOOD[2])
        for x in (1, 2, w - 3, w - 2):  # metal corner bands
            cv.vline(x, y0, y0 + hh - 1, METAL[2] if x in (1, w - 2) else METAL[1])
        cv.hline(1, w - 2, y0 + top, METAL[1])
        cv.hline(1, w - 2, y0 + hh - 1, WOOD[1])
    if stacked:
        one(0, h // 2)
        one(h // 2, h - h // 2)
    else:
        one(1, h - 1)
    cv.outline(OUTLINE)
    return cv


def barrel_blue(w=11, h=16):
    cv = Canvas(w, h)
    blue = ramp("#1f4a8a", "#2e66b8", "#4a88dc", "#7ab0f0")
    for y in range(2, h):
        for x in range(1, w - 1):
            t = x / (w - 1)
            cv.set(x, y, blue[3] if t < 0.25 else blue[2] if t < 0.65 else blue[1])
    cv.ellipse(w / 2, 2.5, w / 2 - 1, 2, blue[2])
    cv.hline(1, w - 2, h - 3, blue[0])
    cv.outline(OUTLINE)
    return cv


def basket(w=13, h=10):
    cv = Canvas(w, h)
    wick = ramp("#c8c0a8", "#e4dcc8", "#f6f0e2")
    for y in range(3, h):
        for x in range(1, w - 1):
            cv.set(x, y, wick[2] if (x + y) % 3 == 0 else wick[1])
    gold = ramp("#b8861e", "#e2b54a", "#f8dc80")
    for x in range(2, w - 2):
        cv.set(x, 2, gold[1])
        cv.set(x, 3, gold[0] if x % 2 else gold[2])
    cv.outline(OUTLINE)
    return cv


def signpost(w=13, h=16):
    cv = Canvas(w, h)
    cv.rect(w // 2 - 1, 6, 2, h - 6, WOOD[2])
    cv.vline(w // 2 - 1, 6, h - 1, WOOD[3])
    cv.rect(1, 1, w - 2, 7, WOOD[3])
    cv.hline(1, w - 2, 1, WOOD[4])
    cv.hline(1, w - 2, 7, WOOD[1])
    purple = ramp("#5a3a7a", "#7a58a0", "#a07ec4")
    cv.rect(w // 2 - 2, 3, 4, 3, purple[1])
    cv.set(w // 2 - 2, 3, purple[2])
    cv.outline(OUTLINE)
    return cv


def bollard(w=7, h=13):
    cv = Canvas(w, h)
    stone = ramp("#5a5448", "#8a8272", "#b0a892", "#cec6ae")
    for y in range(1, h):
        for x in range(1, w - 1):
            cv.set(x, y, stone[3] if x == 1 else stone[2] if x < w - 2 else stone[1])
    cv.hline(1, w - 2, 1, stone[3])
    cv.outline(OUTLINE)
    return cv


# --- fountain -----------------------------------------------------------------

# Two stone tiers inside arches of falling water, as seen by the game camera.
# A = top arch water, P = top stone posts, B = lower water curtain, b = stone seen through the water,
# Q = central stone block, F = foam on the basin.
SPRAY = [
    "..........AAAAAAAA..........",
    "........AAAAAAAAAAAA........",
    ".......AAAPPPPPPPPAAA.......",
    ".......AAPPPPPPPPPPAA.......",
    ".......AAPPPPAAPPPPAA.......",
    ".......AAPPPPAAPPPPAA.......",
    ".......AAPPPPAAPPPPAA.......",
    "......BAAPPPPAAPPPPAAB......",
    "....BBBAAPPPPAAPPPPAABBB....",
    "...BBBBAAAAAAAAAAAAAABBBB...",
    "..BBBBBBBBBBBBBBBBBBBBBBBB..",
    "..BBbbbBBBBBBBBBBBBBBbbbBB..",
    "..BBbbbBBQQQQQQQQQQBBbbbBB..",
    "..BBBbbBBQQQQQQQQQQBBbbBBB..",
    "..BBBBBBBQQQQQQQQQQBBBBBBB..",
    "..BBBBBBBQQQQQQQQQQBBBBBBB..",
    "..BBBBBBBQQQQQQQQQQBBBBBBB..",
    "..BBBBBBBQQQQQQQQQQBBBBBBB..",
    "..BBBBBBBQQQQQQQQQQBBBBBBB..",
    "..BBBBBBBQQQQQQQQQQBBBBBBB..",
    ".FBBBBBBBQQQQQQQQQQBBBBBBBF.",
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ".FFFFFFFFFFFFFFFFFFFFFFFFFF.",
    "............................",
]
SPRAY_WATER = ramp("#3784cf", "#55aceb", "#8ccdf6", "#c8edfc", "#ffffff")
SPRAY_SEEN = c("#5d8db4")  # stone tint under the curtain
SPRAY_STONE = ramp("#2b2926", "#5c5953", "#7f7c75", "#a19e95", "#c4c0b4")
SPRAY_OUTLINE = c("#2a68ad")


def fountain_spray(frame=0):
    """30x24 billboard of the fountain tiers; `frame` (0-2) moves the streaks and flecks down."""
    h, w = len(SPRAY), len(SPRAY[0])
    cv = Canvas(w + 2, h)  # one spare column each side for the outline
    at = lambda x, y: SPRAY[y][x] if 0 <= y < h and 0 <= x < w else "."
    r = rng(17)
    flecks = {(r.randrange(w), r.randrange(h)) for _ in range(22)}
    for y in range(h):
        for x in range(w):
            ch = at(x, y)
            if ch in "PQ":
                if at(x, y - 1) != ch or at(x - 1, y) != ch or at(x + 1, y) != ch:
                    k = 0  # dark joint around every stone face
                elif at(x, y - 2) != ch:
                    k = 4  # lit top face
                elif at(x - 2, y) != ch:
                    k = 3
                elif at(x + 2, y) != ch:
                    k = 1
                else:
                    k = 2
                cv.set(x + 1, y, SPRAY_STONE[k])
            elif ch == "b":
                cv.set(x + 1, y, SPRAY_SEEN)
            elif ch in "AB":
                edge = at(x - 1, y) == "." or at(x + 1, y) == "."
                lip = at(x, y - 1) == "." or (ch == "B" and at(x, y - 1) == "A")
                streak = (x + (y - 2 * frame) // 3) % 4 == 0
                k = 3 if lip else 2 if edge or streak else 1
                if (x, (y - 2 * frame) % h) in flecks:
                    k = 4
                cv.set(x + 1, y, SPRAY_WATER[k])
            elif ch == "F" and (x * 7 + y * 3 + frame * 5) % 11 in (0, 3, 4, 8):
                cv.set(x + 1, y, SPRAY_WATER[4] if (x + y + frame) % 2 else SPRAY_WATER[3])
    cv.outline(SPRAY_OUTLINE, only_below=None)
    return cv


def fountain_spray_sheet():
    """Three animation frames side by side."""
    sheet = Canvas(30 * 3, len(SPRAY))
    for f in range(3):
        sheet.paste(fountain_spray(f), 30 * f, 0)
    return sheet


def produce(w=16, h=8, seed=2):
    """Fruit and vegetables heaped on a stall counter."""
    cv = Canvas(w, h)
    r = rng(seed)
    colours = [ramp("#b8401e", "#e8642e", "#ff9a5a"), ramp("#2e7a2a", "#4aa040", "#7cc860"),
               ramp("#a8241e", "#d83a2e", "#f86a5a"), ramp("#c08a1e", "#eab43a", "#ffd870")]
    for i in range(10):
        col = colours[i % len(colours)]
        x, y = r.uniform(2, w - 3), r.uniform(2, h - 2)
        cv.ellipse(x, y, 2.0, 1.7, col[1])
        cv.set(int(x) - 1, int(y) - 1, col[2])
    cv.outline(OUTLINE)
    return cv
