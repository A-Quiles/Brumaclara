"""Protagonist walk sheet: 24x32 frames, 3 columns (idle, step A, step B) x 3 rows (down, left, up).

The right-facing animation is the left one mirrored in the engine.
Upper bodies are hand-placed pixels (row -> (first column, colours)); legs are drawn per frame.
"""
from pixel import Canvas, hex_rgba as c

FRAME_W, FRAME_H = 24, 32
OUTLINE = c("#251a2b")
COLORS = {
    "H": c("#2f5ad6"), "h": c("#1f3990"), "L": c("#5f8ff2"), "l": c("#a9c9ff"),
    "S": c("#f8d6b6"), "s": c("#dea27f"), "E": c("#1b2140"), "e": c("#3f6fd0"), "W": c("#ffffff"),
    "R": c("#c8432f"), "r": c("#862b22"), "P": c("#ec6c4c"),
    "B": c("#3c6bb4"), "b": c("#294b88"), "C": c("#6b9be0"),
    "T": c("#7a4a2a"), "t": c("#4e2e1c"), "Y": c("#e8c050"),
    "D": c("#3c3651"), "d": c("#28232f"), "K": c("#6b4028"), "k": c("#43271a"),
}

FRONT = {
    2: (9, "L....L"),
    3: (8, "LH...LH...L"),
    4: (6, "LLHHH.LHHH.LH"),
    5: (5, "LHHHHHHLHHHHHHH"),
    6: (4, "LHHHLLHHHHHLLHHH"),
    7: (4, "HHHHHHHHHHHHHHHhh"),
    8: (3, "hHHHHHHHHHHHHHHHhh"),
    9: (3, "hHHHhHHHHHhHHHHHhh"),
    10: (3, "hhHHhHHHhHHHhHHhhh"),
    11: (3, "hhHhSSHhSSHhSShHhh"),
    12: (3, "hhhSSShSSSShSSShHh"),
    13: (4, "hhSWESSSSWESShh"),
    14: (4, "hhSeESSSSeESShh"),
    15: (5, "hsSSSSSSSSSSsh"),
    16: (7, "sSSSsSSSs"),
    17: (6, "rRPPRRRRRRRr"),
    18: (4, "rRCBrRRrrRRrBbRr"),
    19: (4, "rRCBBrRBBBTBBbRr"),
    20: (4, "rRCBCRrBBTBbBbRr"),
    21: (4, "rRCBBBBBTBBbBbRr"),
    22: (4, "rRSSBBBTBBBbSsRr"),
    23: (3, "rRRssBBTBBBBbssRRr"),
    24: (3, "rRRRrtTTYYTTtrRRRr"),
    25: (3, "rRRr..........rRRr"),
    26: (3, "rrr............rrr"),
}

BACK = {
    2: (9, "L....L"),
    3: (8, "LH...LH...L"),
    4: (6, "LLHHH.LHHH.LH"),
    5: (5, "LHHHHHHLHHHHHHH"),
    6: (4, "LHHHLLHHHHHLLHHH"),
    7: (4, "HHHHHHHHHHHHHHHhh"),
    8: (3, "hHHHHHHHHHHHHHHHhh"),
    9: (3, "hHHHhHHHHHhHHHHHhh"),
    10: (3, "hHHHHhHHHHHhHHHHhh"),
    11: (3, "hhHHHHHhHHHHHHhHhh"),
    12: (3, "hhhHHhHHHHhHHHHhhh"),
    13: (4, "hhHHHHhHHhHHHhh"),
    14: (4, "hhhHhHHhHHHhHhh"),
    15: (5, "hhhhHhhHhhhhhh"),
    16: (7, "shhhhhhhs"),
    17: (6, "rRRRRRRRRRRr"),
    18: (4, "rRRRRRRrrRRRRRRr"),
    19: (4, "bRRPRRRRRRRRRRRb"),
    20: (4, "bRRPRRRrRRRRrRRb"),
    21: (4, "bRPRRRRrRRRRrRRb"),
    22: (4, "SRPRRRRrRRRRrRRS"),
    23: (3, "rsRPRRRRrRRRRrRsr"),
    24: (3, "rRRRRRRRrRRRRrRRRr"),
    25: (3, "rRRRRRRRrRRRRrRRRr"),
    26: (4, "rrrrrrrrrrrrrrrr"),
}

LEFT = {
    2: (10, "L....L"),
    3: (8, "LHH..LHH..L"),
    4: (6, "LLHHHHLHHHHLHH"),
    5: (5, "LHHHHHHHHHHHHHHHh"),
    6: (4, "LHHHHHHHHLHHHHHHHhh"),
    7: (4, "HHHHHHHHHHHHHHHHhh"),
    8: (3, "hHHHHHHHHHHHHHHHhhh"),
    9: (3, "hHHHHHHHhHHHHHHhhh"),
    10: (3, "hhHhHHHHHHHHHHhhh"),
    11: (4, "hSShSSHHHHHHHhh"),
    12: (4, "SSSSSShHHHHHHhh"),
    13: (4, "SWESSSSshHHHHhh"),
    14: (3, "SSeESSSsshHHHhh"),
    15: (4, "SSSSSsshhHhh"),
    16: (5, "sSSsss"),
    17: (6, "RPPRRRRrRr"),
    18: (7, "BBCCBbrRRRr"),
    19: (7, "BBCBbbrRRRRr"),
    20: (7, "TBCBTbrRRPRr"),
    21: (7, "BTCBbbrRRRRRr"),
    22: (7, "BBSSbbrRRRRRr"),
    23: (7, "BBssBbrrRRRRRr"),
    24: (7, "tTYTTtrRRRRRRr"),
    25: (13, "rRRRRRRr"),
    26: (14, "rrrrrr"),
}


def _paint(cv, ox, grid, dy=0):
    for y, (x0, chars) in grid.items():
        for i, ch in enumerate(chars):
            if ch != ".":
                cv.set(ox + x0 + i, y + dy, COLORS[ch])


def _leg(cv, ox, x, top, bottom, far=False, toe=0):
    """Trouser leg from `top` to the ankle, then a boot of three rows ending on `bottom`."""
    pants, dark = (COLORS["d"], COLORS["d"]) if far else (COLORS["D"], COLORS["d"])
    boot, boot_dark = (COLORS["k"], COLORS["k"]) if far else (COLORS["K"], COLORS["k"])
    for y in range(top, bottom - 2):
        cv.set(ox + x, y, pants)
        cv.set(ox + x + 1, y, pants)
        cv.set(ox + x + 2, y, dark)
    for y in range(bottom - 2, bottom + 1):
        for i in range(-1 if toe < 0 else 0, 3 + (1 if toe > 0 else 0)):
            cv.set(ox + x + i, y, boot_dark if y == bottom else boot)


def _legs(cv, ox, view, step):
    base = 30
    if view in ("down", "up"):
        lift_l = 2 if step == 1 else 0
        lift_r = 2 if step == 2 else 0
        cv.set(ox + 11, 25, COLORS["D"])
        cv.set(ox + 12, 25, COLORS["d"])
        _leg(cv, ox, 8, 25, base - lift_l, toe=-1)
        _leg(cv, ox, 13, 25, base - lift_r, toe=1)
    else:  # side view, facing left
        if step == 0:
            _leg(cv, ox, 10, 25, base, far=True, toe=-1)
            _leg(cv, ox, 8, 25, base, toe=-1)
        else:
            near_front = step == 1
            _leg(cv, ox, 12, 25, base - (0 if near_front else 1), far=True, toe=-1)
            _leg(cv, ox, 6, 25, base - (1 if near_front else 0), far=not near_front, toe=-1)
            for y in (25, 26):
                for x in range(8, 13):
                    cv.set(ox + x, y, COLORS["D"])


def hero_sheet():
    sheet = Canvas(FRAME_W * 3, FRAME_H * 3)
    for row, (view, grid) in enumerate((("down", FRONT), ("left", LEFT), ("up", BACK))):
        for step in range(3):
            frame = Canvas(FRAME_W, FRAME_H)
            bob = 1 if step else 0  # the body dips slightly on each step
            _legs(frame, 0, view, step)
            _paint(frame, 0, grid, dy=bob)
            frame.outline(OUTLINE)
            frame.shadow(12.5, 30.5, 7, 2)
            sheet.paste(frame, step * FRAME_W, row * FRAME_H)
    return sheet
