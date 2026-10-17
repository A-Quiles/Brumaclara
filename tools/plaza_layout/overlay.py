"""Draws the layout's wireframe over the reference image to check placement."""
import math
import sys

from PIL import Image, ImageDraw

import layout
from cam import project

COL = {"block": (255, 255, 0), "house": (255, 0, 255), "stairs": (0, 255, 255), "npc": (255, 80, 80),
       "tree": (80, 255, 80), "prop": (255, 160, 0), "fountain": (0, 160, 255), "stall": (255, 255, 255),
       "kiosk": (255, 255, 255), "player": (255, 0, 0), "plaza_border": (200, 200, 255)}


def rot(px, pz, yaw):
    a = math.radians(yaw)
    # Godot: rotation.y = a maps local x -> (cos a, -sin a), local z -> (sin a, cos a)
    return px * math.cos(a) + pz * math.sin(a), -px * math.sin(a) + pz * math.cos(a)


def box_corners(pos, size, yaw):
    cx, by, cz = pos
    w, h, d = size
    out = []
    for lx in (-w / 2, w / 2):
        for ly in (0, h):
            for lz in (-d / 2, d / 2):
                rx, rz = rot(lx, lz, yaw)
                out.append((cx + rx, by + ly, cz + rz))
    return out


def draw_box(dr, pos, size, yaw, col):
    c = box_corners(pos, size, yaw)
    p = [project(q) for q in c]
    edges = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7), (0, 4), (1, 5), (2, 6), (3, 7)]
    for a, b in edges:
        dr.line([p[a], p[b]], fill=col, width=2)


def draw_house(dr, o, col):
    draw_box(dr, o["pos"], o["size"], o["yaw"], col)
    if o["roof"] == "flat":
        return
    cx, by, cz = o["pos"]
    w, h, d = o["size"]
    top = by + h + o["roof_h"]
    if o["ridge_along_x"]:
        ridge = [(-w / 2, 0), (w / 2, 0)]
        gables = [((-w / 2, -d / 2), (-w / 2, d / 2)), ((w / 2, -d / 2), (w / 2, d / 2))]
    else:
        ridge = [(0, -d / 2), (0, d / 2)]
        gables = [((-w / 2, -d / 2), (w / 2, -d / 2)), ((-w / 2, d / 2), (w / 2, d / 2))]
    rp = []
    for lx, lz in ridge:
        rx, rz = rot(lx, lz, o["yaw"])
        rp.append(project((cx + rx, top, cz + rz)))
    dr.line(rp, fill=col, width=2)
    for (a, b), r in zip(gables, rp):
        for lx, lz in (a, b):
            rx, rz = rot(lx, lz, o["yaw"])
            dr.line([project((cx + rx, by + h, cz + rz)), r], fill=col, width=2)


def draw_sprite(dr, o, w, h, col):
    x, y, z = o["pos"]
    a = project((x - w / 2, y, z))
    b = project((x + w / 2, y + h, z))
    dr.rectangle([a[0], b[1], b[0], a[1]], outline=col, width=2)


def main(ref, out, only=None):
    im = Image.open(ref).convert("RGB")
    im = Image.blend(im, Image.new("RGB", im.size, (0, 0, 0)), 0.35)
    dr = ImageDraw.Draw(im)
    for o in layout.objects:
        t = o["type"]
        if only and t not in only:
            continue
        col = COL.get(t, (255, 255, 255))
        if t == "block":
            c = box_corners(o["pos"], o["size"], o["yaw"])
            top = [project(c[i]) for i in (1, 3, 7, 5)]
            dr.polygon(top, outline=col, width=2)
        elif t == "house":
            draw_house(dr, o, col)
        elif t == "stairs":
            yaw = o["yaw"]
            # local -z is the climbing direction
            dx, dz = rot(0, -o["run"] / 2, yaw)
            draw_box(dr, [o["pos"][0] + dx, o["pos"][1], o["pos"][2] + dz], [o["width"], o["rise"], o["run"]], yaw, col)
        elif t == "tree":
            w, h = {"pine": (2.6, 4.2), "pine_small": (1.8, 3.0), "bush": (1.3, 0.9)}[o["kind"]]
            draw_sprite(dr, o, w, h, col)
        elif t == "npc" or t == "player":
            draw_sprite(dr, o, 1.2, 2.0, col)
        elif t == "prop":
            draw_sprite(dr, o, 0.9, 0.9, col)
        elif t == "fountain":
            draw_box(dr, [o["pos"][0], 0, o["pos"][2]], [3.5, 0.45, 3.5], 0, col)
            draw_box(dr, [o["pos"][0], 0, o["pos"][2]], [0.9, 1.9, 0.9], 0, col)
        elif t in ("stall", "kiosk"):
            draw_box(dr, o["pos"], [o["width"], 2.0, o["depth"]], 0, col)
        elif t == "plaza_border":
            w, d = o["size"]
            draw_box(dr, o["pos"], [w, 0.01, d], 0, col)
    im.save(out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3].split(",") if len(sys.argv) > 3 else None)
