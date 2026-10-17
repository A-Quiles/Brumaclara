"""HUD pieces drawn at the game's native 480x270 resolution (HP/MP panel, bars, minimap frame, prompts)."""
from pixel import Canvas, hex_rgba as c

INK = c("#0b0f1a")
PANEL = [c("#101b2e"), c("#172741"), c("#22385a")]
RIM = [c("#3c5a80"), c("#6a8cb4"), c("#9cbcdc")]
SLOT = c("#0a1220")
HP = [c("#1e7a2a"), c("#36b240"), c("#6ee070"), c("#b8f8a8")]
MP = [c("#1a5aa8"), c("#2e86dc"), c("#5ab4f4"), c("#b0e4ff")]
LABEL_HP = [c("#a8904a"), c("#e8d27e")]
LABEL_MP = [c("#4a7ab0"), c("#9cccf2")]

GLYPHS = {
    "H": ["XX..XX", "XX..XX", "XX..XX", "XXXXXX", "XX..XX", "XX..XX", "XX..XX"],
    "P": ["XXXXX.", "XX..XX", "XX..XX", "XXXXX.", "XX....", "XX....", "XX...."],
    "M": ["XX...XX", "XXX.XXX", "XXXXXXX", "XX.X.XX", "XX...XX", "XX...XX", "XX...XX"],
    "Y": ["X...X", ".X.X.", "..X..", "..X..", "..X.."],
    "X": ["X...X", ".X.X.", "..X..", ".X.X.", "X...X"],
}


def _rounded_rect(cv, x, y, w, h, fill, rim=None, ink=INK):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            corner = (xx in (x, x + w - 1)) and (yy in (y, y + h - 1))
            if not corner:
                cv.set(xx, yy, fill)
    if rim:
        cv.hline(x + 1, x + w - 2, y + 1, rim[2])
        cv.vline(x + 1, y + 1, y + h - 2, rim[1])
        cv.hline(x + 1, x + w - 2, y + h - 2, rim[0])
        cv.vline(x + w - 2, y + 1, y + h - 2, rim[0])
    cv.hline(x + 1, x + w - 2, y, ink)
    cv.hline(x + 1, x + w - 2, y + h - 1, ink)
    cv.vline(x, y + 1, y + h - 2, ink)
    cv.vline(x + w - 1, y + 1, y + h - 2, ink)


def _text(cv, x, y, text, ramp, outline=INK):
    """Bold pixel letters with a dark outline; ramp = (shade, light)."""
    layer = Canvas(cv.w, cv.h)
    for ch in text:
        g = GLYPHS[ch]
        for gy, row in enumerate(g):
            for gx, px in enumerate(row):
                if px == "X":
                    layer.set(x + gx, y + gy, ramp[1] if gy < len(g) // 2 + 1 else ramp[0])
        x += len(g[0]) + 1
    layer.outline(outline)
    cv.img.alpha_composite(layer.img)


def hp_panel():
    """96x24 panel with HP/MP labels and empty bar slots (the fills are separate textures)."""
    cv = Canvas(96, 24)
    _rounded_rect(cv, 0, 0, 96, 24, PANEL[1], RIM)
    for x in range(3, 93):
        cv.set(x, 3, PANEL[2])
    _text(cv, 4, 3, "HP", LABEL_HP)
    _text(cv, 4, 13, "MP", LABEL_MP)
    for y in (4, 14):
        _rounded_rect(cv, 22, y, 70, 7, SLOT, None)
    return cv


def bar_fill(ramp):
    """68x5 bar fill with a bright top row and a dark bottom row."""
    cv = Canvas(68, 5)
    cv.rect(0, 0, 68, 5, ramp[1])
    cv.hline(0, 67, 0, ramp[3])
    cv.hline(0, 67, 1, ramp[2])
    cv.hline(0, 67, 4, ramp[0])
    return cv


def minimap_frame(w=68, h=58):
    """Light grey bevelled frame; the map itself is a viewport drawn inside (3 px border)."""
    cv = Canvas(w, h)
    rim = [c("#6a7682"), c("#aab6c2"), c("#e2e8ee")]
    _rounded_rect(cv, 0, 0, w, h, (0, 0, 0, 0), rim)
    for y in range(3, h - 3):
        for x in range(3, w - 3):
            cv.set(x, y, (0, 0, 0, 0))
    cv.hline(2, w - 3, 2, rim[0])
    cv.vline(2, 2, h - 3, rim[0])
    return cv


def key_cap(letter):
    cv = Canvas(11, 11)
    _rounded_rect(cv, 0, 0, 11, 11, c("#3a3e48"), [c("#22252c"), c("#5a606c"), c("#7a808c")])
    layer = Canvas(11, 11)
    for gy, row in enumerate(GLYPHS[letter]):
        for gx, px in enumerate(row):
            if px == "X":
                layer.set(3 + gx, 3 + gy, c("#e8ecf2"))
    cv.img.alpha_composite(layer.img)
    return cv


def prompt_arrow():
    cv = Canvas(5, 7)
    for i in range(4):
        cv.vline(i, i, 6 - i, c("#f4f4f4"))
    return cv


def player_marker():
    cv = Canvas(5, 5)
    cv.rect(1, 1, 3, 3, c("#f04030"))
    cv.set(2, 1, c("#ffb0a0"))
    cv.hline(1, 3, 0, INK)
    cv.hline(1, 3, 4, INK)
    cv.vline(0, 1, 3, INK)
    cv.vline(4, 1, 3, INK)
    return cv
