"""Contact sheet: assets side by side at the game's 3x zoom (nearest), labelled, on a mid-grey
ground, to compare pixel density by eye (docs/plan_unificacion_artistica.md, 3.1).

    python3 tools/art_audit/sheet.py out.png path[:x,y,w,h] ...
Textures are shown as a 64 x 64 crop.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ZOOM = 3


def piece(spec):
    path, _, box = spec.partition(":")
    im = Image.open(ROOT / path).convert("RGBA")
    if box:
        x, y, w, h = map(int, box.split(","))
        im = im.crop((x, y, x + w, y + h))
    elif "/textures/" in path:
        im = im.crop((0, 0, min(64, im.width), min(64, im.height)))
    return Path(path).stem, im.resize((im.width * ZOOM, im.height * ZOOM), Image.NEAREST)


def sheet(out, specs, width=1280):
    pieces = [piece(s) for s in specs]
    rows, row, x = [], [], 0
    for name, im in pieces:
        if row and x + im.width + 8 > width:
            rows.append(row)
            row, x = [], 0
        row.append((name, im))
        x += im.width + 8
    rows.append(row)
    height = sum(max(im.height for _, im in r) + 22 for r in rows) + 8
    canvas = Image.new("RGBA", (width, height), (96, 100, 96, 255))
    draw = ImageDraw.Draw(canvas)
    y = 8
    for r in rows:
        x = 8
        for name, im in r:
            canvas.alpha_composite(im, (x, y))
            draw.text((x, y + im.height + 2), name[:22], fill=(255, 255, 255, 255))
            x += im.width + 8
        y += max(im.height for _, im in r) + 22
    canvas.save(out)


if __name__ == "__main__":
    sheet(sys.argv[1], sys.argv[2:])
