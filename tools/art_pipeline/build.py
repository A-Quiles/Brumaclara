"""Builds every game-ready sprite and texture from the AI source images in art/ai.

Usage: python3 tools/art_pipeline/build.py [asset ...]     (no argument = everything)

Each recipe says which cells of which source become which frames, the pixel size `f` of the
drawing (source pixels per game pixel) and where the result goes in assets/. The sources and their
prompts are listed in art/FUENTES.md.
"""
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


def hero():
    walk, act, extra = grid("hero_walk"), grid("hero_actions"), grid("hero_extra")
    # each source sheet draws the hero at a slightly different size: normalise on a standing pose
    scale = {id(walk): None, id(act): None, id(extra): None}
    for sheet, (r, c) in ((walk, (0, 0)), (act, (1, 0)), (extra, (3, 0))):
        scale[id(sheet)] = HERO_HEIGHT * HERO_F / raw_height(sheet[r][c])

    def frames(sheet, r, cols, flip=False):
        out = []
        for c in cols:
            im = sheets.pixelate_cell(sheet[r][c], HERO_F, scale[id(sheet)])
            out.append(sheets.mirror(im) if flip else im)
        return out

    rows = {  # animation rows of the sheet; side views face right (the game mirrors them for left)
        "walk_down": frames(walk, 0, range(4)),
        "walk_side": frames(walk, 1, range(4), flip=True),
        "walk_up": frames(act, 0, range(4)),
        "attack_down": frames(act, 1, range(4)),
        "attack_side": frames(act, 2, range(4)),
        "attack_up": frames(act, 3, range(4)),
        "dodge_down": frames(extra, 0, range(4)),
        "dodge_side": frames(extra, 1, range(4)),
        "dodge_up": frames(extra, 2, range(3)),
        "misc": frames(extra, 3, range(4)),  # hurt front, hurt front (alt), knocked out, casting
    }
    every = [im for row in rows.values() for im in row]
    palette = palette_for(every, 40, FIRE)
    sheet_rows = baseline_rows([sheets.snap_all(row, palette) for row in rows.values()], HERO_FRAME, HERO_ANCHOR)
    out_dir = OUT / "characters" / "hero"
    save(sheets.assemble(sheet_rows, *HERO_FRAME), "characters", "hero", "hero.png")
    r = {name: i for i, name in enumerate(rows)}
    cells = lambda name, n: [(c, r[name]) for c in range(n)]
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
    sheets.write_sprite_frames(out_dir / "hero_frames.tres", "res://assets/characters/hero/hero.png",
                               *HERO_FRAME, animations)
    return out_dir / "hero.png"


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


FACADES = {(0, 0): "inn", (0, 1): "shop", (1, 0): "smithy", (1, 1): "guild"}


def facades():
    """Front walls and gables of the town's named buildings. Each drawing is split at its eave
    (its widest row in the upper part) and both halves are cropped to the wall's width."""
    g = grid("facades", 2, 2, 8)
    magenta = np.array([255.0, 0.0, 255.0])  # the bottom corners are wall, so the cell corners can't key it
    parts = {}
    for (r, c), name in FACADES.items():
        cell = g[r][c]
        solid = ~px.background_mask(cell, magenta, 110)
        eave = int(np.argmax(solid.sum(1)[: int(len(cell) * 0.6)]))
        xs = np.nonzero(solid[int(len(cell) * 0.9)])[0]
        cell = cell[:, xs[0]:xs[-1] + 1]
        parts[name + "_gable"] = px.pixelate(cell[:eave], magenta, 4)
        parts[name + "_wall"] = px.pixelate(cell[eave:], magenta, 4, tol=1.0)  # the wall is opaque throughout
    palette = palette_for(list(parts.values()), 40, FIRE)
    for name, im in parts.items():
        save(sheets.snap_all([im], palette)[0], "environment", "buildings", "facade_" + name + ".png")
    return OUT / "environment" / "buildings"


# --- interface -------------------------------------------------------------------------------

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


RECIPES = {"hero": hero, "wolf": wolf, "nature": nature, "props_b": props_b, "terrain": terrain,
           "terrain_b": terrain_b, "house": house, "facades": facades, "plaza": plaza, "ui": ui, "vfx": vfx, "backdrop": backdrop, "shadow": shadow}

if __name__ == "__main__":
    for key in sys.argv[1:] or RECIPES:
        print(key, "->", RECIPES[key]())
