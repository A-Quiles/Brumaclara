"""Builds every game-ready sprite and texture from the AI source images in art/ai.

Usage: python3 tools/art_pipeline/build.py [asset ...]     (no argument = everything)

Each recipe says which cells of which source become which frames, the pixel size `f` of the
drawing (source pixels per game pixel) and where the result goes in assets/. The sources and their
prompts are listed in art/FUENTES.md.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

import pixelate as px
import sheets

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art" / "ai"
OUT = ROOT / "assets"


def grid(name, rows=4, cols=4, inset=6):
    return sheets.cut_grid(px.load(SRC / f"{name}.png"), rows, cols, inset)


def raw_height(cell, tol=100.0):
    """Height in source pixels of the drawing in a cell (keyed against the cell's backdrop)."""
    solid = ~px.background_mask(cell, sheets.cell_background(cell), tol)
    rows = np.nonzero(solid.any(1))[0]
    return rows[-1] - rows[0] + 1


# accent colours kept in the palettes, so small flames, sparks and rift crystals keep their hue
FIRE = [(255, 242, 168), (255, 201, 60), (255, 138, 28), (226, 69, 28)]
RIFT = [(84, 48, 150), (124, 78, 210), (166, 122, 246), (214, 184, 255), (246, 232, 255)]


def palette_for(images, n, extra=()):
    pal = px.kmeans_palette(sheets.interior_pixels(images), n)
    return np.vstack([pal, np.asarray(extra, np.float64)]) if len(extra) else pal


def save(image, *parts):
    path = OUT.joinpath(*parts)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return path


def baseline_rows(rows, frame, anchor):
    """Places every row's frames in fixed-size frames; each row keeps its own feet line."""
    out = []
    for row in rows:
        bottoms = [sheets.solid_box(im)[3] for im in row if sheets.solid_box(im)]
        base = int(np.median(bottoms))
        out.append([sheets.place(im, *frame, anchor[0], anchor[1], bottom=base) for im in row])
    return out


def cropped(image):
    return image.crop(sheets.solid_box(image))


# --- hero ------------------------------------------------------------------------------

HERO_F = 5            # source pixels per game pixel
HERO_HEIGHT = 46      # game pixels from hair tip to soles, standing
HERO_FRAME = (56, 56)
HERO_ANCHOR = (28, 53)  # feet centre inside a frame


def traveller(name, prefix, flips=None):
    """A player model of the character creator (art/ai/heroes/<prefix>_walk|actions|extra): a traveller
    looking for work, no cape. Side views face right; `flips` maps an animation row to the columns drawn
    facing left, which are mirrored."""
    walk, act, extra = (grid(f"heroes/{prefix}_{n}") for n in ("walk", "actions", "extra"))
    flips = flips or {}
    layout = {
        "walk_down": (walk, 0, range(4)),
        "walk_side": (walk, 1, range(4)),
        "walk_up": (walk, 2, range(4)),
        "attack_down": (act, 0, range(4)),
        "attack_side": (act, 1, range(4)),
        "attack_up": (act, 2, range(4)),
        "dodge_down": (extra, 0, range(4)),
        "dodge_side": (extra, 1, range(4)),
        "dodge_up": (extra, 2, range(3)),
        "misc": (act, 3, range(4)),  # hurt front, hurt side, knocked out, casting
    }
    layout = {k: v + (flips[k],) if k in flips else v for k, v in layout.items()}
    # the actions sheet has no plain standing pose: it is drawn at the size of the dodge sheet's
    return hero_set(name, (walk, act, extra), ((walk, 3, 0), (act, 3, 0, extra), (extra, 3, 0)), layout, clean=True)


def hero():
    return traveller("hero", "hombre", {"attack_side": {2, 3}})


def heroine():
    return traveller("heroine", "mujer", {"walk_side": {0}})


# Colour groups of the character creator (scripts/systems/hero_look.gd): each set says which
# palette colours are hair, skin, clothes (tunic) and vest, by hue (degrees), saturation and value ranges.
# "top" groups only count in the upper part of an upright figure (the hero's hair and tunic share a blue).
LOOK_GROUPS = {
    "hero": [
        ("hair", (220, 242), (0.45, 1), (0.25, 1), None),
        ("clothes", (95, 130), (0.25, 1), (0.18, 1), None),
        ("vest", (345, 360), (0.55, 1), (0.25, 1), None),
        ("skin", (15, 26), (0.2, 0.45), (0.6, 1), None),
        ("leather", (10, 26), (0.45, 1), (0.18, 0.56), None),
        ("trousers", (200, 260), (0, 0.25), (0.12, 0.42), None),
    ],
    "heroine": [
        ("hair", (30, 46), (0.6, 1), (0.58, 1), None),
        ("clothes", (95, 130), (0.25, 1), (0.18, 1), None),
        ("vest", (345, 360), (0.55, 1), (0.25, 1), None),
        ("skin", (15, 26), (0.2, 0.45), (0.6, 1), None),
        ("leather", (10, 26), (0.45, 1), (0.18, 0.56), None),
        ("trousers", (200, 260), (0, 0.25), (0.12, 0.42), None),
    ],
}
LOOK_IDS = {"hair": 1, "skin": 2, "clothes": 3, "vest": 4, "leather": 5, "trousers": 6}
LOOK_STEP = 30  # the mask stores id * LOOK_STEP (scripts/systems/hero_look.gd divides by the same number)


def look_mask(sheet, rules, frame):
    """L image: the colour group of every pixel of a hero sheet, as id * LOOK_STEP (0 = keep the colour)."""
    import colorsys
    a = np.asarray(sheet.convert("RGBA"))
    out = np.zeros(a.shape[:2], np.uint8)
    hsv = np.zeros(a.shape[:2] + (3,))
    solid = a[..., 3] > 0
    for y, x in zip(*np.nonzero(solid)):
        h, s_, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
        hsv[y, x] = (h * 360, s_, v)
    fire = np.zeros(a.shape[:2], bool)
    for c in FIRE:
        fire |= (a[..., :3] == c).all(2)
    fw, fh = frame
    for fy in range(0, a.shape[0], fh):
        for fx in range(0, a.shape[1], fw):
            cell = solid[fy:fy + fh, fx:fx + fw]
            ys, xs = np.nonzero(cell)
            if len(ys) == 0:
                continue
            top, height, upright = ys.min(), ys.max() - ys.min() + 1, (ys.max() - ys.min()) >= (xs.max() - xs.min()) * 0.9
            sub = hsv[fy:fy + fh, fx:fx + fw]
            done = out[fy:fy + fh, fx:fx + fw] > 0
            rows = np.arange(fh)[:, None].repeat(fw, 1)
            for group, hue, sat, val, upper in rules:
                hit = cell & ~done & ~fire[fy:fy + fh, fx:fx + fw]
                hit &= (sub[..., 0] >= hue[0]) & (sub[..., 0] <= hue[1])
                hit &= (sub[..., 1] >= sat[0]) & (sub[..., 1] <= sat[1])
                hit &= (sub[..., 2] >= val[0]) & (sub[..., 2] <= val[1])
                if upper is not None:  # ponytail: lying frames (knocked out) keep this group's colour
                    hit &= upright & (rows < top + height * upper)
                out[fy:fy + fh, fx:fx + fw][hit] = LOOK_IDS[group] * LOOK_STEP
                done |= hit
    return Image.fromarray(out, "L")


def hero_set(name, sources, standing, layout, clean=False):
    """One hero sprite set: `layout` maps each animation row to (sheet, row, columns[, mirror]).
    `standing` gives, per sheet, a cell where the hero stands upright (optionally on another sheet
    drawn at the same size)."""
    # each source sheet draws the hero at a slightly different size: normalise on a standing pose
    scale = {id(sheet): HERO_HEIGHT * HERO_F / raw_height((ref + [sheet])[0][r][c])
             for sheet, r, c, *ref in standing}

    def frames(sheet, r, cols, flip=False):
        out = []
        for c in cols:
            im = sheets.pixelate_cell(sheet[r][c], HERO_F, scale[id(sheet)])
            if clean:  # magenta backdrop left on the outline (JPEG sources) becomes outline
                a = np.asarray(im).copy()
                rgb = a[..., :3].astype(int)
                spill = (rgb[..., 0] > rgb[..., 1] * 1.6) & (rgb[..., 2] > rgb[..., 1] * 1.6) & (rgb[..., 2] > rgb[..., 0] * 0.75)
                # pinkish blends of backdrop and drawing on the silhouette edge become outline too
                solid = a[..., 3] > 0
                edge = solid & ~(np.roll(solid, 1, 0) & np.roll(solid, -1, 0) & np.roll(solid, 1, 1) & np.roll(solid, -1, 1))
                spill |= edge & (rgb[..., 2] > rgb[..., 1] * 1.1) & (rgb[..., 0] > rgb[..., 1] * 1.3)
                a[spill & solid, :3] = (38, 26, 24)
                im = Image.fromarray(a, "RGBA")
            out.append(sheets.mirror(im) if flip is True or (flip and c in flip) else im)
        return out

    rows = {key: frames(*spec) for key, spec in layout.items()}
    every = [im for row in rows.values() for im in row]
    palette = palette_for(every, 40, FIRE)
    sheet_rows = baseline_rows([sheets.snap_all(row, palette) for row in rows.values()], HERO_FRAME, HERO_ANCHOR)
    out_dir = OUT / "characters" / "hero"
    sheet = sheets.assemble(sheet_rows, *HERO_FRAME)
    save(sheet, "characters", "hero", f"{name}.png")
    save(look_mask(sheet, LOOK_GROUPS[name], HERO_FRAME), "characters", "hero", f"{name}_mask.png")
    r = {key: i for i, key in enumerate(rows)}
    cells = lambda key, n: [(c, r[key]) for c in range(n)]
    animations = [
        ("idle_down", [(0, r["walk_down"])], 1, True),
        ("idle_side", [(0, r["walk_side"])], 1, True),
        ("idle_up", [(0, r["walk_up"])], 1, True),
        ("walk_down", cells("walk_down", 4), 8, True),
        ("walk_side", cells("walk_side", 4), 8, True),
        ("walk_up", cells("walk_up", 4), 8, True),
        ("attack_down", cells("attack_down", 4), 14, False),
        ("attack_side", cells("attack_side", 4), 14, False),
        ("attack_up", cells("attack_up", 4), 14, False),
        ("dodge_down", cells("dodge_down", 4), 14, False),
        ("dodge_side", cells("dodge_side", 4), 14, False),
        ("dodge_up", cells("dodge_up", 3), 12, False),
        ("hurt_down", [(0, r["misc"])], 1, False),
        ("hurt_side", [(1, r["misc"])], 1, False),
        ("hurt_up", [(1, r["misc"])], 1, False),
        ("cast_down", [(3, r["misc"])], 1, False),
        ("cast_side", [(1, r["attack_side"])], 1, False),
        ("cast_up", [(1, r["attack_up"])], 1, False),
        ("dead", [(0, r["misc"]), (2, r["misc"])], 4, False),
    ]
    sheets.write_sprite_frames(out_dir / f"{name}_frames.tres", f"res://assets/characters/hero/{name}.png",
                               *HERO_FRAME, animations)
    return out_dir / f"{name}.png"


# --- enemy: Fractura wolf ------------------------------------------------------------------

WOLF_F = 5
WOLF_FRAME = (60, 52)
WOLF_ANCHOR = (30, 49)


def wolf():
    g = grid("wolf")
    frames = lambda r, cols, flip: [sheets.mirror(im) if flip else im
                                    for im in (sheets.pixelate_cell(g[r][c], WOLF_F) for c in cols)]
    rows = {  # all facing right
        "idle": frames(0, range(4), True),
        "run": frames(1, range(4), True),
        "attack": frames(2, range(4), False),  # wind-up, leap, leap with open jaws, bite
        "fall": frames(3, range(4), False),    # recoil, stagger, collapsed, dissolving
    }
    palette = palette_for([im for row in rows.values() for im in row], 32)
    sheet_rows = baseline_rows([sheets.snap_all(row, palette) for row in rows.values()], WOLF_FRAME, WOLF_ANCHOR)
    path = save(sheets.assemble(sheet_rows, *WOLF_FRAME), "characters", "enemies", "wolf.png")
    r = {name: i for i, name in enumerate(rows)}
    cells = lambda name, cols: [(c, r[name]) for c in cols]
    sheets.write_sprite_frames(path.with_name("wolf_frames.tres"), "res://assets/characters/enemies/wolf.png",
                               *WOLF_FRAME, [
                                   ("idle", cells("idle", range(4)), 6, True),
                                   ("run", cells("run", range(4)), 12, True),
                                   ("windup", cells("attack", [0]), 1, False),
                                   ("pounce", cells("attack", [1, 2, 3]), 10, False),
                                   ("hurt", cells("fall", [0]), 1, False),
                                   ("dead", cells("fall", [1, 2, 3]), 5, False),
                               ])
    return path


# --- nature and props ----------------------------------------------------------------------

TREES = {(0, 0): "tree_oak", (0, 1): "tree_fir", (1, 0): "tree_young", (1, 1): "tree_dead"}
# cell -> (name, source pixels per game pixel): f sets each object's size next to the hero
PROPS = {
    (0, 0): ("bush", 6), (0, 1): ("bush_berries", 6), (0, 2): ("flowers", 6), (0, 3): ("tall_grass", 6),
    (1, 0): ("boulder", 5), (1, 1): ("rocks", 6), (1, 2): ("stump", 6), (1, 3): ("mushrooms", 7),
    (2, 0): ("fence", 5), (2, 1): ("signpost", 5), (2, 2): ("notice_board", 5), (2, 3): ("lantern", 4, 135),
    (3, 0): ("barrel", 8), (3, 1): ("crate", 8), (3, 2): ("crystal", 6),  # (3, 3): chest, replaced by props_b
}


def nature():
    trees, props = grid("trees", 2, 2, 10), grid("props")
    images = {name: cropped(sheets.pixelate_cell(trees[r][c], 5)) for (r, c), name in TREES.items()}
    for (r, c), (name, f, *tol) in PROPS.items():  # the lantern's pink glow needs a wider key
        images[name] = cropped(sheets.pixelate_cell(props[r][c], f, tol=tol[0] if tol else 100.0))
    palette = palette_for(list(images.values()), 48, FIRE + RIFT)
    own = {"crystal": palette_for([images["crystal"]], 14)}  # its violets would be lost in the shared palette
    for (name, im) in images.items():
        folder = "nature" if name.startswith("tree") or name in ("bush", "bush_berries", "flowers", "tall_grass",
                                                                   "boulder", "rocks", "stump", "mushrooms") else "props"
        save(sheets.snap_all([im], own.get(name, palette))[0], "environment", folder, name + ".png")
    return OUT / "environment"


# second sheet: village life, the Fractura site and the chest in its four states
PROPS_B = {  # cell -> (name, source pixels per game pixel)
    (0, 0): ("well", 4), (0, 1): ("hay_cart", 6), (0, 2): ("firewood", 7), (0, 3): ("bench", 6),
    (1, 0): ("planter", 7), (1, 1): ("hay_bale", 6), (1, 2): ("sacks", 8), (1, 3): ("bucket", 10),
    (2, 0): ("rift_crystals", 5), (2, 1): ("rift_crack", 5), (2, 2): ("rift_bramble", 6), (2, 3): ("rune_stone", 4),
}
CHEST_F = 6


def props_b():
    g = grid("props_b")
    images = {name: cropped(sheets.pixelate_cell(g[r][c], f)) for (r, c), (name, f) in PROPS_B.items()}
    chest = [sheets.pixelate_cell(g[3][c], CHEST_F) for c in range(4)]  # closed, opening, open, emptied
    palette = palette_for(list(images.values()) + chest, 40, FIRE + RIFT)
    for name, im in images.items():
        save(sheets.snap_all([im], palette)[0], "environment", "nature" if name == "rift_bramble" else "props",
             name + ".png")
    # the lid swings up and back, so the frames are aligned on the front edge of the chest's base
    chest = sheets.snap_all(chest, palette)
    bases = []
    for im in chest:
        a = np.asarray(im.getchannel("A")) > 0
        bottom = np.nonzero(a.any(1))[0][-1]
        bases.append((np.nonzero(a[bottom - 2:bottom + 1].any(0))[0].mean(), bottom + 1))
    boxes = [sheets.solid_box(im) for im in chest]
    w = max(b[2] - b[0] for b in boxes) + 4
    h = max(b[3] - b[1] for b in boxes) + 2
    frames = [sheets.place(im, w, h, w // 2, h - 1, x_centre=x, bottom=y) for im, (x, y) in zip(chest, bases)]
    path = save(sheets.assemble([frames], w, h), "environment", "props", "chest.png")
    sheets.write_sprite_frames(path.with_name("chest_frames.tres"), "res://assets/environment/props/chest.png", w, h, [
        ("closed", [(0, 0)], 1, False), ("open", [(1, 0), (2, 0)], 6, False), ("empty", [(3, 0)], 1, False)])
    return OUT / "environment"


# town square: the fountain in three frames, market stalls, lamps, banners and street furniture
PLAZA = {  # cell -> (name, source pixels per game pixel); the fountain row (0, 0..2) is animated
    (0, 3): ("flower_bed", 5), (1, 0): ("stall_red", 4), (1, 1): ("stall_green", 4), (1, 2): ("stall_blue", 4),
    (2, 0): ("street_lamp", 4), (2, 1): ("banner", 4), (2, 2): ("flower_cart", 5), (2, 3): ("barrel_stack", 6),
    (3, 0): ("low_wall", 5), (3, 1): ("pillar", 5), (3, 2): ("tree_planter", 4), (3, 3): ("chalkboard", 6),
}


def plaza():
    g = grid("plaza_props")
    images = {name: cropped(sheets.pixelate_cell(g[r][c], f)) for (r, c), (name, f) in PLAZA.items()}
    water = [sheets.pixelate_cell(g[0][c], 4) for c in range(3)]
    palette = palette_for(list(images.values()) + water, 40, FIRE)
    for name, im in images.items():
        save(sheets.snap_all([im], palette)[0], "environment", "props", name + ".png")
    water = sheets.snap_all(water, palette)  # frames share the basin's base line and centre
    boxes = [sheets.solid_box(im) for im in water]
    w = max(b[2] - b[0] for b in boxes) + 2
    h = max(b[3] - b[1] for b in boxes) + 2
    frames = [sheets.place(im, w, h, w // 2, h - 1, x_centre=(b[0] + b[2]) / 2) for im, b in zip(water, boxes)]
    path = save(sheets.assemble([frames], w, h), "environment", "props", "fountain.png")
    sheets.write_sprite_frames(path.with_name("fountain_frames.tres"), "res://assets/environment/props/fountain.png",
                               w, h, [("flow", [(0, 0), (1, 0), (2, 0)], 6, True)])
    return OUT / "environment" / "props"


# --- ground and building textures ------------------------------------------------------------

def texture(cell, f, colours, band=None, flatten=0.0, vertical=True):
    """Opaque tileable texture. `flatten` (blur radius in game pixels) removes large light/dark
    blotches that would show as a repeating pattern, keeping the small details. vertical=False
    only wraps it sideways."""
    small, _ = px.downscale(cell, np.ones(cell.shape[:2]), f)
    if flatten:
        from scipy import ndimage
        low = np.stack([ndimage.gaussian_filter(small[..., i], flatten, mode="wrap") for i in range(3)], -1)
        small = small - low + small.reshape(-1, 3).mean(0)
    if band:
        small = px.make_tileable(small, band, vertical)
    solid = np.ones(small.shape[:2])
    palette = px.kmeans_palette(small.reshape(-1, 3), colours)
    return px.to_image(px.snap(small, solid, palette), solid)


def terrain():
    g = grid("terrain_a", 2, 2, 8)
    for (r, c), name in {(0, 0): "grass", (0, 1): "dirt", (1, 0): "cobble", (1, 1): "cliff"}.items():
        save(texture(g[r][c], 4, 20, band=14, flatten=8.0 if name == "grass" else 0.0),
             "environment", "textures", name + ".png")
    return OUT / "environment" / "textures"


def terrain_b():
    # the sheet's flower meadow (0, 0) is not used: at game size its flowers shrink to specks
    g = grid("terrain_b", 2, 2, 8)
    save(texture(g[0][1], 4, 20, band=14, flatten=8.0), "environment", "textures", "forest_floor.png")
    save(texture(g[1][1], 4, 20, band=14), "environment", "textures", "garden_soil.png")
    # the rift scar's dull ground is lifted toward ash so the dark wolves stand out on it; its
    # glowing cracks and crystals keep their colour
    scar = g[1][0].copy()
    lab = px.oklab(scar)
    dull = (lab[..., 0] < 0.62) & (np.hypot(lab[..., 1], lab[..., 2]) < 0.08)
    scar[dull] = scar[dull] * 0.6 + np.array([196.0, 188.0, 208.0]) * 0.4
    save(texture(scar, 4, 20, band=14), "environment", "textures", "rift_ground.png")
    return OUT / "environment" / "textures"


def house():
    g = grid("house", 2, 2, 6)
    front = g[0][0]
    gable_rows = 196  # source rows above the eave beam: the triangular gable
    bg = sheets.cell_background(front[:40, :40])
    wall = px.pixelate(front[gable_rows:], bg, 4)
    gable = px.pixelate(front[:gable_rows], bg, 4)
    side = px.pixelate(g[0][1][186:], bg, 4)
    parts = {"front": wall, "gable": gable, "side": side}
    palette = palette_for(list(parts.values()), 24)
    for name, im in parts.items():
        save(sheets.snap_all([im], palette)[0], "environment", "buildings", "house_" + name + ".png")
    save(texture(g[1][0], 4, 12, band=12), "environment", "buildings", "roof_orange.png")
    save(texture(g[1][1], 4, 12, band=12), "environment", "buildings", "roof_slate.png")
    return OUT / "environment" / "buildings"


FACADES = {  # sheet -> cell -> building; each sheet keeps its own palette
    "facades": {(0, 0): "inn", (0, 1): "shop", (1, 0): "smithy", (1, 1): "guild"},
    "guild_facades": {(0, 0): "brasa", (0, 1): "archive", (1, 0): "league", (1, 1): "stable"},
    "home_facades": {(0, 0): "home_green", (0, 1): "home_blue", (1, 0): "home_red", (1, 1): "home_yellow"},
}


def add_storey(wall):
    """The same wall one floor taller: its timber upper floor is repeated above itself. The floor
    line is where the grey stone of the ground floor starts."""
    a = np.asarray(wall.convert("RGBA"))
    rgb = a[..., :3].astype(np.float64)
    grey = (rgb.max(-1) - rgb.min(-1) < 28) & (rgb.mean(-1) > 60) & (rgb.mean(-1) < 200)
    rows = grey.mean(1)
    start = int(len(rows) * 0.3)
    floor = start + int(np.argmax(rows[start:] > 0.45))
    return Image.fromarray(np.concatenate([a[:floor], a[:floor], a[floor:]]), "RGBA")


def facades():
    """Front walls and gables of the town's buildings. Each drawing is split at its eave (its
    widest row in the upper part) and both halves are cropped to the wall's width."""
    magenta = np.array([255.0, 0.0, 255.0])  # the bottom corners are wall, so the cell corners can't key it
    for sheet, cells in FACADES.items():
        g = grid(sheet, 2, 2, 8)
        parts = {}
        for (r, c), name in cells.items():
            cell = g[r][c]
            solid = ~px.background_mask(cell, magenta, 110)
            eave = int(np.argmax(solid.sum(1)[: int(len(cell) * 0.6)]))
            xs = np.nonzero(solid[int(len(cell) * 0.9)])[0]
            cell = cell[:, xs[0]:xs[-1] + 1]
            parts[name + "_gable"] = px.pixelate(cell[:eave], magenta, 4)
            parts[name + "_wall"] = px.pixelate(cell[eave:], magenta, 4, tol=1.0)  # the wall is opaque throughout
        palette = palette_for(list(parts.values()), 40, FIRE)
        for name, im in parts.items():
            im = sheets.snap_all([im], palette)[0]
            save(im, "environment", "buildings", "facade_" + name + ".png")
            if name.endswith("_wall"):
                save(add_storey(im), "environment", "buildings", "facade_" + name + "_tall.png")
    return OUT / "environment" / "buildings"


def walls_roofs():
    """Side wall of the town houses, the stone of the retaining walls and two more roofs."""
    g = grid("walls_roofs", 2, 2, 8)
    # not wrapped: the wall is symmetric (windows centred between posts) and covers a wall once
    side = texture(g[0][0], 4, 24)
    save(side, "environment", "buildings", "side_timber.png")
    save(add_storey(side), "environment", "buildings", "side_timber_tall.png")
    save(texture(g[0][1], 4, 16, band=12), "environment", "textures", "stone_wall.png")
    save(texture(g[1][0], 4, 12, band=12), "environment", "buildings", "roof_red.png")
    save(texture(g[1][1], 4, 12, band=12), "environment", "buildings", "roof_shingle.png")
    return OUT / "environment"


TOWN_PROPS = {  # cell -> (name, source pixels per game pixel)
    (0, 0): ("town_gate", 3), (0, 1): ("chimney", 5), (0, 2): ("dormer", 5), (0, 3): ("wall_lantern", 6),
    (1, 0): ("training_dummy", 5), (1, 1): ("weapon_rack", 5), (1, 2): ("archery_target", 6), (1, 3): ("wagon", 4),
    (2, 0): ("horse", 4), (2, 1): ("trough", 5), (2, 2): ("hay_pile", 5), (2, 3): ("fence_gate", 5),
    (3, 1): ("rose_bush", 6), (3, 2): ("cypress_pot", 5), (3, 3): ("bread_stool", 7),
}


def town_props():
    g = grid("town_props")
    images = {name: cropped(sheets.pixelate_cell(g[r][c], f)) for (r, c), (name, f) in TOWN_PROPS.items()}
    palette = palette_for(list(images.values()), 40, FIRE)
    for name, im in images.items():
        save(sheets.snap_all([im], palette)[0], "environment", "props", name + ".png")
    return OUT / "environment" / "props"


# townsfolk: (sheet, row) of each walk; side walks face right, the game mirrors them for left
TOWNSFOLK = {
    "mara": {"down": ("townsfolk", 0), "side": ("townsfolk_b", 0), "up": ("townsfolk_b", 1)},
    "elia": {"down": ("townsfolk", 1), "side": ("townsfolk_b", 2), "up": ("townsfolk_b", 3)},
    "carter": {"down": ("townsfolk", 2)},
    "guard": {"down": ("townsfolk", 3)},
}
FOLK_HEIGHT = {"mara": 44, "elia": 43, "carter": 45, "guard": 52}  # the guard's spear stands above him


def townsfolk():
    sheets_ = {name: grid(name) for name in ("townsfolk", "townsfolk_b")}
    for who, walks in TOWNSFOLK.items():
        rows = {}
        for facing, (sheet, r) in walks.items():
            row = sheets_[sheet][r]
            scale = FOLK_HEIGHT[who] * HERO_F / raw_height(row[0])
            rows[facing] = [sheets.pixelate_cell(cell, HERO_F, scale) for cell in row]
        palette = palette_for([im for row in rows.values() for im in row], 32)
        placed = baseline_rows([sheets.snap_all(row, palette) for row in rows.values()], HERO_FRAME, HERO_ANCHOR)
        path = save(sheets.assemble(placed, *HERO_FRAME), "characters", "townsfolk", who + ".png")
        animations = []
        for i, facing in enumerate(rows):
            animations += [("idle_" + facing, [(0, i)], 1, True), ("walk_" + facing, [(c, i) for c in range(4)], 7, True)]
        sheets.write_sprite_frames(path.with_name(who + "_frames.tres"),
                                   f"res://assets/characters/townsfolk/{who}.png", *HERO_FRAME, animations)
    return OUT / "characters" / "townsfolk"


# People of the story drawn as 4 x 3 sheets (art/ai/<who>.png, 200 x 150 px, one game pixel per
# source pixel): rows walking toward the camera, to the side and away. who -> (the side row was drawn
# facing left: the game expects right and mirrors it, keying tolerance: lower when the clothes are close
# to the backdrop's colour).
CHARACTERS = {"iven": (True, 80.0, True), "neris": (False, 50.0, False), "tovan": (False, 80.0, "all"), "rhea": (False, 80.0, "all"), "caldus": (False, 80.0, "all"), "lio": (False, 80.0, "all"), "sella": (False, 80.0, "all")}  # + clear magenta spill


def segment_sheet(rgb, rows, cols, tol, spill=False):
    """The figures of a sheet whose grid is not exact: the backdrop is keyed on the whole image, the
    figures found as blobs (parts a pixel or two apart join), the rows*cols largest kept and sorted
    row by row. Returns rows of RGBA images, each cut to its figure."""
    from scipy import ndimage
    whole = flood_key(rgb, tol, bg=px.dominant_border_colour(rgb), spill=spill)
    alpha = np.asarray(whole)[..., 3] > 0
    labels, n = ndimage.label(ndimage.binary_dilation(alpha, structure=np.ones((1, 5))))  # sideways only: rows stay apart
    boxes = ndimage.find_objects(labels)
    sizes = ndimage.sum(alpha, labels, range(1, n + 1))
    keep = sorted(range(n), key=lambda i: -sizes[i])[:rows * cols]
    figures = [(boxes[i], i + 1) for i in keep]
    figures.sort(key=lambda f: (f[0][0].start + f[0][0].stop) / 2)
    out = []
    for r in range(rows):
        row = sorted(figures[r * cols:(r + 1) * cols], key=lambda f: f[0][1].start)
        images = []
        for (sy, sx), label in row:
            cut = np.asarray(whole)[sy, sx].copy()
            cut[..., 3] = np.where(labels[sy, sx] == label, cut[..., 3], 0)
            images.append(Image.fromarray(cut, "RGBA"))
        out.append(images)
    return out


def characters(only=None):
    out = OUT / "characters" / "townsfolk"
    for who, (faces_left, tol, spill) in CHARACTERS.items():
        if (only and who not in only) or not (SRC / f"{who}.png").exists():
            continue
        rgb = px.load(SRC / f"{who}.png")
        g = segment_sheet(rgb, 3, 4, tol, spill)
        rows = {facing: g[r] for r, facing in enumerate(["down", "side", "up"])}
        if faces_left:
            rows["side"] = [sheets.mirror(im) for im in rows["side"]]
        palette = palette_for([im for row in rows.values() for im in row], 32)
        placed = baseline_rows([[cropped(im) for im in row] for row in (sheets.snap_all(r, palette) for r in rows.values())],
                               HERO_FRAME, HERO_ANCHOR)
        path = save(sheets.assemble(placed, *HERO_FRAME), "characters", "townsfolk", who + ".png")
        animations = []
        for i, facing in enumerate(rows):
            animations += [("idle_" + facing, [(0, i)], 1, True), ("walk_" + facing, [(c, i) for c in range(4)], 7, True)]
        sheets.write_sprite_frames(path.with_name(who + "_frames.tres"),
                                   f"res://assets/characters/townsfolk/{who}.png", *HERO_FRAME, animations)
    return out


# --- interface -------------------------------------------------------------------------------

ICON = 22  # px, the HUD's slots and the tree's nodes
ICON_GRID = {"tronco": 6}  # icons per row and column of each sheet (5 by default)


def skill_icons():
    """art/ai/icons_<tree>.png (5 x 5 framed icons on black; the adventurer's trunk 6 x 6) ->
    assets/ui/skills/<tree>.png, a sheet of 22 px icons (data/ui/skill_icons.json says which skill uses
    which one)."""
    out = None
    for src in sorted(SRC.glob("icons_*.png")):
        rgb = px.load(src)
        n = ICON_GRID.get(src.stem.replace("icons_", ""), 5)
        cells = sheets.cut_grid(rgb, n, n, inset=1)
        icons = []
        for row in cells:
            for cell in row:
                solid = cell.max(-1) > 40  # the tile, without the black around it
                ys, xs = np.nonzero(solid)
                tile = cell[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
                small = Image.fromarray(tile.astype(np.uint8)).resize((ICON, ICON), Image.LANCZOS)
                icons.append(np.asarray(small).astype(np.float64))
        solid = np.ones((ICON, ICON))
        palette = px.kmeans_palette(np.concatenate([i.reshape(-1, 3) for i in icons]), 40)
        sheet = Image.new("RGBA", (ICON * n, ICON * n))
        for k, icon in enumerate(icons):
            sheet.paste(px.to_image(px.snap(icon, solid, palette), solid), (k % n * ICON, k // n * ICON))
        out = save(sheet, "ui", "skills", src.stem.replace("icons_", "") + ".png")
    return out

UI_PARTS = ["panel", "trough", "bar_hp", "trough_2", "bar_mp", "trough_3", "bar_xp",
            "icon_sword", "icon_bolt", "icon_burst", "icon_dash", "potion", "coin"]


def ui():
    from scipy import ndimage
    rgb = px.load(SRC / "ui.png")
    bg = sheets.cell_background(rgb)
    solid = ~px.background_mask(rgb, bg, 100)
    labels, count = ndimage.label(ndimage.binary_closing(solid, iterations=3))
    boxes = [s for s in ndimage.find_objects(labels) if (s[0].stop - s[0].start) * (s[1].stop - s[1].start) > 900]
    boxes.sort(key=lambda s: (round(s[0].start / 60), s[1].start))  # reading order
    assert len(boxes) == len(UI_PARTS), len(boxes)
    images = {}
    for name, (sy, sx) in zip(UI_PARTS, boxes):
        cut = rgb[max(0, sy.start - 8):sy.stop + 8, max(0, sx.start - 8):sx.stop + 8]
        images[name] = cropped(px.pixelate(cut, bg, 8))
    # the panel's top row is its outline blended with the magenta backdrop: drop it and repeat the bottom outline
    # and its washed-out top border takes the gold of the side border
    panel = np.asarray(images["panel"].convert("RGBA"))[1:].copy()
    panel[0] = panel[-1]
    panel[1, 4:-4] = panel[len(panel) // 2, 1]
    images["panel"] = Image.fromarray(panel, "RGBA")
    for bar in ("bar_hp", "bar_mp", "bar_xp"):  # fills match the trough; the gold one is drawn part-empty
        fill = images[bar].crop((0, 0, round(images[bar].width * (0.78 if bar == "bar_xp" else 1.0)), images[bar].height))
        images[bar] = fill.resize(images["trough"].size, Image.NEAREST)
    palette = palette_for(list(images.values()), 40, FIRE)
    for name, im in images.items():
        if not name.startswith("trough_"):
            save(sheets.snap_all([im], palette)[0], "ui", name + ".png")
    return OUT / "ui"


# --- effects -----------------------------------------------------------------------------------

VFX = {  # name: (row, columns, source pixels per game pixel)
    "bolt": (0, range(4), 10), "explosion": (1, range(4), 6), "spark": (2, range(3), 8),
    "dust": (3, range(2), 8), "orb": (3, range(2, 4), 8),
}


def vfx():
    g = grid("vfx", 4, 4, 10)
    strips = {}
    for name, (r, cols, f) in VFX.items():
        strips[name] = [sheets.pixelate_cell(g[r][c], f) for c in cols]
    palette = palette_for([im for strip in strips.values() for im in strip], 32, FIRE)
    for name, strip in strips.items():
        strip = sheets.snap_all(strip, palette)
        boxes = [sheets.solid_box(im) for im in strip]
        w = max(b[2] - b[0] for b in boxes) + 2
        h = max(b[3] - b[1] for b in boxes) + 2
        frames = []
        for im, b in zip(strip, boxes):  # every frame centred on its drawing
            frames.append(sheets.place(im, w, h, w / 2, h - 1, x_centre=(b[0] + b[2]) / 2,
                                       bottom=(b[1] + b[3]) / 2 + h / 2 - 1))
        save(sheets.assemble([frames], w, h), "effects", name + ".png")
    return OUT / "effects"


# --- far scenery ---------------------------------------------------------------------------------

def backdrop():
    """Sky, mountains and hills seen over the forest (scripts/environment/backdrop.gd): wraps
    sideways, one game pixel per screen pixel."""
    image = texture(px.load(SRC / "backdrop.png"), 2, 32, band=24, vertical=False)
    return save(image, "environment", "backdrop", "far_scenery.png")


def shadow():
    """Contact shadow under characters and objects: a flat translucent ellipse, the only image the
    pipeline draws instead of taking it from a source."""
    y, x = np.mgrid[0:8, 0:16] + 0.5
    rgba = np.zeros((8, 16, 4), np.uint8)
    rgba[((x - 8) / 7.5) ** 2 + ((y - 4) / 3.6) ** 2 <= 1] = (16, 28, 30, 140)
    return save(Image.fromarray(rgba, "RGBA"), "environment", "textures", "blob_shadow.png")


# --- extra angles of existing props (art/ai/variants, drawn by the author with Gemini) -------------
# sheet: (piece that matches the existing sprite, that sprite, {piece: view}). A view named after a
# direction (s, sw, w, nw, n, ne, e, se: where the object faces on screen, s towards the camera) is
# the same object turned that way; any other name is another model of it. Missing directions are the
# mirror of their opposite (scripts/systems/sprite_catalog.gd). Every piece is scaled like the
# reference one, so sizes match the existing sprite.
VARIANTS = {
    "bench": (0, "bench", {0: "s", 1: "n", 5: "w", 7: "e", 8: "se", 10: "nw"}),
    "hay_cart": (22, "hay_cart", {25: "s", 33: "n", 13: "w", 24: "nw", 26: "ne"}),
    "banner": (0, "banner", {1: "n", 5: "sw", 4: "se", 6: "nw", 7: "ne", 2: "e"}),
    "notice_board": (6, "notice_board", {10: "n", 18: "sw", 25: "se", 20: "nw", 8: "e"}),
    "chalkboard": (0, "chalkboard", {1: "n", 8: "sw", 4: "se", 5: "ne", 2: "e"}),
    "horse": (3, "horse", {0: "s", 2: "n", 20: "se", 14: "ne", 19: "grazing", 21: "lying"}),
    "fence": (3, "fence", {3: "sw", 1: "post"}),
    "hay_bale": (4, "hay_bale", {1: "e", 7: "rolled", 8: "upright"}),
    "target": (0, "archery_target", {1: "e", 3: "sw", 8: "se", 2: "n"}),
    "crate": (0, "crate", {12: "se", 17: "tall"}),
    "barrel_crates": (0, "barrel_stack", {1: "b", 2: "c"}),
    "barrel": (12, "barrel", {16: "lying", 0: "tipped"}),
    "rock": (1, "boulder", {2: "b", 3: "c", 8: "d"}),
    "lamp": (2, "lantern", {1: "e", 8: "sw"}),
}
# where the sprites without a direction in their name face, when it is not the camera (s)
FACING = {"props/bench": "sw", "props/hay_cart": "sw", "props/horse": "w", "props/horse__grazing": "e",
          "props/horse__lying": "e"}

# Colour variants painted over finished sprites (recipe `recolors`): object -> how to find each
# colour group, and the variants with a colour per group. A variant of a model is "<colour>_<model>".
HORSE_COATS = {"negro": ("3a3640", "1e1a22"), "tordo": ("b4b2b0", "5e5a62"), "blanco": ("e6e2da", "c4bcb4"),
               "palomino": ("d6a650", "f0e2b8"), "alazan": ("a84e2a", "7e3418")}
WAGON_CANVAS = {"azul": "5a7ab0", "verde": "6a9a5a", "rojo": "b0483a"}
for coat in HORSE_COATS:
    FACING[f"props/horse__{coat}"] = "w"
    FACING[f"props/horse__{coat}_grazing"] = "e"
    FACING[f"props/horse__{coat}_lying"] = "e"


def _paint(rgba, groups, targets):
    """Moves every colour group of an RGBA sprite to its target colour, keeping its shading."""
    import colorsys
    out = rgba.copy()
    for g, hexc in targets.items():
        sel = groups == g
        if not sel.any():
            continue
        t = colorsys.rgb_to_hsv(*(int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4)))
        v = rgba[..., :3].max(2) / 255.0
        rel = v / v[sel].mean()
        for y, x in zip(*np.nonzero(sel)):
            r = rel[y, x]
            sat = min(1.0, t[1] * (1.15 - 0.25 * r))
            out[y, x, :3] = [round(c * 255) for c in colorsys.hsv_to_rgb(t[0], sat, min(1.0, t[2] * r))]
    return out


def _hsv(rgba):
    import colorsys
    flat = rgba[..., :3].reshape(-1, 3) / 255.0
    return np.array([colorsys.rgb_to_hsv(*c) for c in flat]).reshape(rgba.shape[:2] + (3,)) * [360, 1, 1]


def recolors():
    folder = OUT / "environment" / "props"
    for old in list(folder.glob("horse__*_*.png*")) + [f for c in HORSE_COATS for f in folder.glob(f"horse__{c}*")] + \
            [f for c in WAGON_CANVAS for f in folder.glob(f"wagon__{c}*")]:
        old.unlink(missing_ok=True)
    for src in sorted(folder.glob("horse*.png")):
        rgba = np.asarray(Image.open(src).convert("RGBA"))
        h = _hsv(rgba)
        solid = (rgba[..., 3] > 0) & (h[..., 2] >= 0.17) & (h[..., 1] >= 0.3)  # outline and white markings stay
        red = (h[..., 0] < 35) | (h[..., 0] > 340)
        groups = np.where(solid & red & ((h[..., 0] < 17) | (h[..., 0] > 340)), 2, np.where(solid & red, 1, 0))
        rest = src.stem.split("__")[1:]  # [] / ["s"] / ["grazing"]
        for coat, (body, mane) in HORSE_COATS.items():
            if rest and rest[0] in ("grazing", "lying"):
                name = f"horse__{coat}_{rest[0]}"
            else:
                name = "__".join(["horse", coat] + rest)
            save(Image.fromarray(_paint(rgba, groups, {1: body, 2: mane}), "RGBA"), "environment", "props", name + ".png")
    rgba = np.asarray(Image.open(folder / "wagon.png").convert("RGBA"))
    h = _hsv(rgba)
    canvas = (rgba[..., 3] > 0) & (h[..., 1] < 0.35) & (h[..., 2] > 0.55)
    for colour, hexc in WAGON_CANVAS.items():
        save(Image.fromarray(_paint(rgba, canvas.astype(int), {1: hexc}), "RGBA"), "environment", "props", f"wagon__{colour}.png")
    (OUT / "environment" / "vistas.json").write_text(json.dumps(FACING, indent="\t", sort_keys=True) + "\n")
    return folder


# --- affinity effects: the fire effects and skill icons repainted for each affinity ----------------

# dark -> light colour ramp of each affinity; fire keeps the drawn colours
AFFINITY_RAMPS = {
    "hielo": ["1d3f8a", "3f8fd8", "8fd8ff", "eefcff"],
    "rayo": ["2e2a8a", "6a6cff", "b4d8ff", "ffffff"],
    "sombra": ["1a0f2a", "4a2a7a", "8f5ad0", "e2c8ff"],
    "tierra": ["3a2414", "7a5030", "b88a50", "eedab0"],
    "luz": ["8a6a10", "e0b030", "ffe880", "fffdf0"],
}
AFFINITY_SOURCES = [("effects", "bolt.png"), ("effects", "explosion.png"), ("effects", "spark.png"),
                    ("ui", "icon_bolt.png"), ("ui", "icon_burst.png")]


def _ramp_paint(rgba, ramp):
    """Each opaque pixel takes the ramp colour at its brightness (relative to the image's own range)."""
    out = rgba.copy()
    solid = rgba[..., 3] > 0
    lum = rgba[..., :3].astype(np.float64) @ np.array([0.299, 0.587, 0.114])
    lo, hi = np.percentile(lum[solid], 2), np.percentile(lum[solid], 98)
    t = np.clip((lum - lo) / max(hi - lo, 1.0), 0.0, 1.0) * (len(ramp) - 1)
    stops = np.array([[int(c[i:i + 2], 16) for i in (0, 2, 4)] for c in ramp], np.float64)
    i0 = np.floor(t).astype(int).clip(0, len(ramp) - 2)
    f = (t - i0)[..., None]
    rgb = stops[i0] * (1 - f) + stops[i0 + 1] * f
    out[..., :3] = np.where(solid[..., None], rgb.round(), rgba[..., :3]).astype(np.uint8)
    return out


def affinity_fx():
    """assets/<folder>/affinity/<affinity>_<file>: same frames as the fire version, repainted."""
    for affinity, ramp in AFFINITY_RAMPS.items():
        for folder, name in AFFINITY_SOURCES:
            rgba = np.asarray(Image.open(OUT / folder / name).convert("RGBA"))
            save(Image.fromarray(_ramp_paint(rgba, ramp), "RGBA"), folder, "affinity", f"{affinity}_{name}")
    return OUT / "effects" / "affinity"


# --- wolf variants (bestiary zone 1 and 5): the Fractura wolf repainted, same frames --------------

# name: (fur colour, glow colour); fur is the slate-blue body, glow the violet cracks and eyes
WOLF_VARIANTS = {
    "alfa": ("5a4a44", "d0303c"),       # Lobo alfa: charcoal-brown, red cracks
    "tormenta": ("5c7088", "40d8ff"),   # Lobo de tormenta: steel blue, electric cracks
    "gris": ("a8a8ac", "ffb040"),       # Colmillo Gris (élite): pale grey, amber cracks
    "madre": ("3a2a4c", "e050ff"),      # Madre de la manada (jefe): near-black, bright violet
    "brasa": ("7a3a2a", "ff8a1c"),      # Lobo de brasa: ember-brown, orange cracks (fire)
    "escarcha": ("a8d8e8", "8fd8ff"),   # Lobo de escarcha: pale ice (ice)
    "umbral": ("2a2236", "a87ae0"),     # Lobo umbral: shadow violet (shadow)
    "pedrero": ("8a7458", "c09060"),    # Lobo pedrero: dusty stone (earth)
    "sacro": ("e8e0c0", "ffe880"),      # Lobo sacro: bone white, gold (light)
}


def wolf_variants():
    src = OUT / "characters" / "enemies" / "wolf.png"
    rgba = np.asarray(Image.open(src).convert("RGBA"))
    h = _hsv(rgba)
    solid = (rgba[..., 3] > 0) & (h[..., 2] >= 0.2)  # the darkest outline stays
    groups = np.where(solid & (h[..., 0] < 250), 1, np.where(solid & (h[..., 0] >= 250), 2, 0))
    frames = (src.parent / "wolf_frames.tres").read_text()
    for name, (fur, glow) in WOLF_VARIANTS.items():
        save(Image.fromarray(_paint(rgba, groups, {1: fur, 2: glow}), "RGBA"), "characters", "enemies", f"wolf__{name}.png")
        (src.parent / f"wolf__{name}_frames.tres").write_text(frames.replace("enemies/wolf.png", f"enemies/wolf__{name}.png"))
    return src.parent


# Monsters drawn as 4x4 sheets (art/ai/<src>.png, 200 px, one game pixel per source pixel):
# rows idle, move, attack, fall. name -> (palette colours, lift): `lift` raises flying creatures above
# their shadow. Frames are as big as the largest drawing; the feet sit 3 px above the bottom (+ lift),
# centred, and data/enemies/<name>.tres gets the matching sprite_offset.
MONSTERS = {
    "hongo": (24, 0), "murcielago": (24, 10), "esqueleto": (24, 0), "golem": (24, 0), "espectro": (24, 6),
    # touched by the Fractura
    "hongo_f": (28, 0), "murcielago_f": (28, 10), "esqueleto_f": (28, 0), "golem_f": (28, 0), "espectro_f": (28, 6),
    "sporineo": (28, 0), "guardian_raices": (28, 0), "polilla_luminica": (24, 12),
    # zone 1
    "roedor_bruma": (28, 0), "jabali_espinoso": (28, 0), "cuervo_bruma": (28, 12),
}
KEY_TOL = {"murcielago_f": 45.0, "esqueleto_f": 45.0, "sporineo": 55.0}  # violet art close to the magenta backdrop
PURPLE_CLEAN = {"hongo", "murcielago", "esqueleto", "golem"}  # no violet in the art: purple is backdrop spill
GREEN_CLEAN = {"roedor_bruma", "jabali_espinoso", "cuervo_bruma"}  # drawn on green with no green in the art: green fringes are backdrop spill


def _unbackdrop(im):
    """Drops the magenta backdrop's purple spill (shadows, fringes) from art that has no violet."""
    a = np.asarray(im).copy()
    r, g, b = (a[..., i].astype(int) for i in range(3))
    bad = (b > g * 1.25) & (r > g * 1.25) & (a[..., 3] > 0)
    a[bad, 3] = 0
    return Image.fromarray(a, "RGBA")


def flood_key(cell, tol, tight=38.0, bg=None, main_only=False, spill=False):
    """See _flood_key; spill="all" also clears backdrop-tinted pixels enclosed by the outline (gaps
    between an arm and the body), for art that has none of the backdrop's hue."""
    image = _flood_key(cell, tol, tight, bg, main_only, bool(spill))
    if spill == "all":
        a = np.asarray(image).copy()
        r, g, b = (a[..., i].astype(int) for i in range(3))
        bgc = sheets.cell_background(cell) if bg is None else bg
        if bgc[1] > bgc[0] + 60 and bgc[1] > bgc[2] + 60:
            a[(g - r > 35) & (g - b > 25), 3] = 0
        else:
            a[(r - g > 40) & (b - g > 25), 3] = 0
        image = Image.fromarray(a, "RGBA")
    return image


def _flood_key(cell, tol, tight=38.0, bg=None, main_only=False, spill=False):
    """Alpha of a cell: the backdrop is what has the corners' colour AND touches the border, so
    colours like it inside the outline (violet cracks on a magenta sheet) stay; only holes of the
    backdrop's exact colour (between legs, under arms) go too. `bg` overrides the corners' colour;
    `main_only` drops specks (bits of the neighbouring cells); `spill` also clears the backdrop-tinted
    shadows drawn under the objects (purple pixels reached from outside the outline)."""
    bg = sheets.cell_background(cell) if bg is None else bg
    like = px.background_mask(cell, bg, tol)
    if spill:
        r, g, b = cell[..., 0], cell[..., 1], cell[..., 2]
        if bg[1] > bg[0] + 60 and bg[1] > bg[2] + 60:  # a green backdrop
            like |= (g - r > 35) & (g - b > 25)
        else:  # magenta: strongly magenta pixels; dark outlines are grey, never spill
            like |= (r - g > 40) & (b - g > 25)
    hole = px.background_mask(cell, bg, min(tight, tol))
    reach = np.zeros_like(like)
    reach[0, :], reach[-1, :], reach[:, 0], reach[:, -1] = like[0, :], like[-1, :], like[:, 0], like[:, -1]
    while True:
        grown = reach.copy()
        grown[1:, :] |= reach[:-1, :]
        grown[:-1, :] |= reach[1:, :]
        grown[:, 1:] |= reach[:, :-1]
        grown[:, :-1] |= reach[:, 1:]
        grown &= like
        if (grown == reach).all():
            break
        reach = grown
    alpha = px.despeckle((~(reach | hole)).astype(np.float64))
    if main_only:
        from scipy import ndimage
        labels, n = ndimage.label(alpha > 0)
        if n > 1:
            sizes = ndimage.sum(alpha > 0, labels, range(1, n + 1))
            keep = [i + 1 for i, size in enumerate(sizes) if size >= 0.04 * sizes.max()]
            alpha = np.isin(labels, keep).astype(np.float64)
    return px.to_image(cell, alpha)


def monsters(only=None):
    out = None
    for name, (ncol, lift) in MONSTERS.items():
        if (only and name not in only) or not (SRC / f"{name}.png").exists():
            continue
        g = sheets.cut_grid(px.load(SRC / f"{name}.png"), 4, 4, inset=2)
        clean = _unbackdrop if name in PURPLE_CLEAN else (lambda im: im)
        spill = "all" if name in GREEN_CLEAN else False
        rows = {key: [clean(flood_key(g[r][c], KEY_TOL.get(name, 100.0), spill=spill)) for c in range(4)]
                for r, key in enumerate(["idle", "run", "attack", "fall"])}
        palette = palette_for([im for row in rows.values() for im in row], ncol)
        snapped = [sheets.snap_all(row, palette) for row in rows.values()]
        cx = snapped[0][0].width / 2  # the drawings keep their place in their cells (no jitter)
        bases, half, above, below = [], 0, 0, 0
        for row in snapped:
            boxes = [sheets.solid_box(im) for im in row if sheets.solid_box(im)]
            base = int(np.median([b[3] for b in boxes]))
            bases.append(base)
            for b in boxes:
                half = max(half, cx - b[0], b[2] - cx)
                above = max(above, base - b[1])
                below = max(below, b[3] - base)
        w = 2 * int(np.ceil(half)) + 4
        bottom = 3 + lift + below
        h = above + bottom + 2
        anchor = (w // 2, h - bottom)
        sheet_rows = [[sheets.place(im, w, h, anchor[0], anchor[1], x_centre=cx, bottom=base) for im in row]
                      for row, base in zip(snapped, bases)]
        path = save(sheets.assemble(sheet_rows, w, h), "characters", "enemies", f"{name}.png")
        cells = lambda key, cols: [(c, list(rows).index(key)) for c in cols]  # noqa: E731
        sheets.write_sprite_frames(path.with_name(f"{name}_frames.tres"), f"res://assets/characters/enemies/{name}.png",
                                   w, h, [("idle", cells("idle", range(4)), 5, True),
                                          ("run", cells("run", range(4)), 10, True),
                                          ("windup", cells("attack", [0]), 1, False),
                                          ("pounce", cells("attack", [1, 2, 3]), 10, False),
                                          ("hurt", cells("fall", [0]), 1, False),
                                          ("dead", cells("fall", [1, 2, 3]), 5, False)])
        _set_offset(name, (-(w // 2), -bottom))
        out = path
    return out


def _set_offset(name, offset):
    """Writes where the feet are (Sprite3D offset) into the enemy's data; a new enemy gets a bare data
    file that tools/data/enemies.py fills in later (keeping this offset)."""
    data = ROOT / "data" / "enemies" / f"{name}.tres"
    text = data.read_text() if data.exists() else (
        '[gd_resource type="Resource" script_class="EnemyData" format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/data/enemy_data.gd" id="1_data"]\n'
        f'[ext_resource type="SpriteFrames" path="res://assets/characters/enemies/{name}_frames.tres" id="2_frames"]\n\n'
        '[resource]\nscript = ExtResource("1_data")\nframes = ExtResource("2_frames")\n')
    line = f"sprite_offset = Vector2({offset[0]}, {offset[1]})"
    if "sprite_offset" in text:
        text = re.sub(r"sprite_offset = Vector2\([^)]*\)", line, text)
    else:
        text = text.replace('frames = ExtResource("2_frames")', 'frames = ExtResource("2_frames")\n' + line)
    data.write_text(text)


FURNITURE = {  # sheet -> the props in its 4 x 4 cells, row by row
    "furniture_a": ["mesa_redonda", "silla", "mesa_larga", "barra", "estante_botellas", "chimenea", "cama", "armario",
                    "barril_grifo", "fogon", "estanteria", "escritorio", "alfombrilla", "planta", "farol_poste", "arcon"],
    "furniture_b": ["mostrador_registro", "tablon_contratos", "vitrina_pociones", "armero", "maniqui_cota", "yunque",
                    "banco_trabajo", "mesa_mapas", "estante_pergaminos", "lampara_cristal", "cajas_mercancia",
                    "sacos_harina", "estante_pociones", "estandarte_gremio", "cofre_tesoro", "candelabro"],
}


def interiors():
    """Floors, walls and rug of the interiors, and their furniture (assets/environment/props/interior)."""
    g = grid("interior_textures", 2, 2, 4)
    for (r, c), name in {(0, 0): "floor_planks", (0, 1): "wall_plaster", (1, 0): "floor_flagstone"}.items():
        save(texture(g[r][c], 1, 20, band=8), "environment", "textures", name + ".png")
    rug = g[1][1]
    save(texture(rug, 1, 18), "environment", "textures", "rug_red.png")
    for sheet, names in FURNITURE.items():
        rgb = px.load(SRC / f"{sheet}.png")
        bg = px.dominant_border_colour(rgb)
        cells = sheets.cut_grid(rgb, 4, 4, inset=2)
        images = [flood_key(cells[i // 4][i % 4], 70.0, bg=bg, main_only=True, spill=True) for i in range(16)]
        palette = palette_for(images, 40, FIRE)
        for name, im in zip(names, sheets.snap_all(images, palette)):
            save(cropped(im), "environment", "props", "interior", name + ".png")
    return OUT / "environment" / "props" / "interior"


HAIRSTYLES = ["alto", "cresta", "mono", "largo", "volumen"]


def hair_styles():
    """The extra hairstyles of the creator: assets/characters/hero/<set>__<style>.png (+ mask + frames)."""
    import hairstyles
    folder = OUT / "characters" / "hero"
    for base in ("hero", "heroine"):
        sheet = Image.open(folder / f"{base}.png")
        mask = Image.open(folder / f"{base}_mask.png")
        frames = (folder / f"{base}_frames.tres").read_text()
        for style in HAIRSTYLES:
            img, new_mask = hairstyles.make(sheet, mask, style)
            img.save(folder / f"{base}__{style}.png")
            new_mask.save(folder / f"{base}__{style}_mask.png")
            (folder / f"{base}__{style}_frames.tres").write_text(frames.replace(f"hero/{base}.png", f"hero/{base}__{style}.png"))
    return folder


def _main_parts(mask):
    """Drops the specks a cut-out drags along (bits of labels or of the next drawing)."""
    from scipy import ndimage
    labels, n = ndimage.label(mask, structure=np.ones((3, 3)))
    if n <= 1:
        return mask
    sizes = ndimage.sum(mask, labels, range(1, n + 1))
    keep = [i + 1 for i, size in enumerate(sizes) if size >= sizes.max() * 0.03]
    return np.isin(labels, keep)


def variants():
    import json
    import variants as vr
    images = {}
    for sheet, (ref, base, views) in VARIANTS.items():
        rgb = np.asarray(Image.open(SRC / "variants" / f"{sheet}.jpg").convert("RGB")).astype(np.int32)
        boxes = vr.pieces(rgb)
        folder = "nature" if base == "boulder" else "props"
        for old in (OUT / "environment" / folder).glob(f"{base}__*.png*"):  # views renamed or dropped
            old.unlink()
        target_h = Image.open(OUT / "environment" / folder / f"{base}.png").height
        scale = target_h / (boxes[ref][3] - boxes[ref][1])
        for idx, view in views.items():
            cut = vr.cut(rgb, boxes[idx]).astype(np.float64)
            a = cut[..., 3:] / 255.0
            w = max(1, round(cut.shape[1] * scale))
            h = max(1, round(cut.shape[0] * scale))
            pre = Image.fromarray(np.dstack([cut[..., :3] * a, a * 255]).astype(np.uint8), "RGBA")
            small = np.asarray(pre.resize((w, h), Image.BOX)).astype(np.float64)
            alpha = small[..., 3] / 255.0
            colour = small[..., :3] / np.maximum(alpha, 1e-3)[..., None]
            solid = _main_parts(alpha > 0.5).astype(np.float64)
            fringe = (colour[..., 0] > colour[..., 1] * 1.25) & (colour[..., 2] > colour[..., 1] * 1.25)
            colour[fringe] = (38, 26, 24)  # magenta backdrop spill on the outline becomes outline
            images[(folder, f"{base}__{view}")] = px.to_image(np.clip(colour, 0, 255), solid)
    palette = palette_for(list(images.values()), 48, FIRE)
    for (folder, name), im in images.items():
        save(cropped(sheets.snap_all([im], palette)[0]), "environment", folder, name + ".png")
    (OUT / "environment" / "vistas.json").write_text(json.dumps(FACING, indent="\t", sort_keys=True) + "\n")
    return OUT / "environment"


RECIPES = {"hero": hero, "heroine": heroine, "wolf": wolf, "nature": nature, "props_b": props_b, "terrain": terrain,
           "terrain_b": terrain_b, "house": house, "facades": facades, "plaza": plaza, "walls_roofs": walls_roofs,
           "town_props": town_props, "townsfolk": townsfolk, "variants": variants, "recolors": recolors, "affinity_fx": affinity_fx, "wolf_variants": wolf_variants, "monsters": monsters, "interiors": interiors, "characters": characters, "skill_icons": skill_icons, "hair_styles": hair_styles, "ui": ui, "vfx": vfx, "backdrop": backdrop, "shadow": shadow}

if __name__ == "__main__":
    for key in sys.argv[1:] or RECIPES:
        print(key, "->", RECIPES[key]())
