"""Cutting AI sprite grids into game frames, assembling sheets and writing Godot SpriteFrames."""
import numpy as np
from PIL import Image, ImageOps

import pixelate as px


def cell_background(cell):
    """Median colour of the four corner patches of a cell: the flat backdrop it was drawn on."""
    patches = [cell[2:12, 2:12], cell[2:12, -12:-2], cell[-12:-2, 2:12], cell[-12:-2, -12:-2]]
    return np.median(np.concatenate([p.reshape(-1, 3) for p in patches]), axis=0)


def cut_grid(rgb, rows, cols, inset=6):
    """Cells of an exact rows x cols grid, minus `inset` pixels on every side (grid lines)."""
    ch, cw = rgb.shape[0] / rows, rgb.shape[1] / cols
    return [[rgb[round(r * ch) + inset:round((r + 1) * ch) - inset, round(c * cw) + inset:round((c + 1) * cw) - inset]
             for c in range(cols)] for r in range(rows)]


def solid_box(image):
    """(left, top, right, bottom) of the opaque pixels, or None."""
    return image.getchannel("A").getbbox()


def pixelate_cell(cell, f, scale=1.0, tol=100.0):
    """One cell -> RGBA game pixels. `scale` resizes the drawing first so f stays an integer."""
    bg = cell_background(cell)
    if scale != 1.0:
        size = (round(cell.shape[1] * scale), round(cell.shape[0] * scale))
        cell = np.asarray(Image.fromarray(cell.astype(np.uint8)).resize(size, Image.LANCZOS)).astype(np.float64)
    return px.pixelate(cell, bg, f, tol=tol)


def interior_pixels(images):
    """RGB of the solid pixels that are not on a silhouette edge (keying fringe stays out)."""
    out = []
    for im in images:
        a = np.asarray(im.getchannel("A")) > 0
        inner = a.copy()
        inner[1:] &= a[:-1]
        inner[:-1] &= a[1:]
        inner[:, 1:] &= a[:, :-1]
        inner[:, :-1] &= a[:, 1:]
        out.append(np.asarray(im.convert("RGB")).astype(np.float64)[inner])
    return np.concatenate(out)


def snap_all(images, palette):
    out = []
    for im in images:
        rgb = np.asarray(im.convert("RGB")).astype(np.float64)
        a = (np.asarray(im.getchannel("A")) > 0).astype(np.float64)
        out.append(px.to_image(px.snap(rgb, a, palette), a))
    return out


def place(image, frame_w, frame_h, anchor_x, baseline, x_centre=None, bottom=None):
    """Pastes `image` into a transparent frame so that its point (x_centre, bottom) lands on
    (anchor_x, baseline). By default the drawing's own horizontal centre and lowest pixel are used."""
    box = solid_box(image)
    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    if box is None:
        return frame
    if x_centre is None:
        x_centre = image.width / 2
    if bottom is None:
        bottom = box[3]
    frame.alpha_composite(image, (round(anchor_x - x_centre), round(baseline - bottom)))
    return frame


def mirror(image):
    return ImageOps.mirror(image)


def assemble(rows, frame_w, frame_h):
    """rows: list of lists of frames -> sheet image (one animation per row)."""
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cols * frame_w, len(rows) * frame_h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, frame in enumerate(row):
            sheet.alpha_composite(frame, (x * frame_w, y * frame_h))
    return sheet


def write_sprite_frames(path, texture_path, frame_w, frame_h, animations):
    """Godot 4 SpriteFrames resource. animations: [(name, [(col, row), ...], fps, loop)]."""
    regions, subs = {}, []
    for _, frames, _, _ in animations:
        for cell in frames:
            if cell not in regions:
                regions[cell] = "AtlasTexture_%d_%d" % cell
                subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("1_sheet")\n'
                            "region = Rect2(%d, %d, %d, %d)\n" % (regions[cell], cell[0] * frame_w, cell[1] * frame_h,
                                                                  frame_w, frame_h))
    anims = []
    for name, frames, fps, loop in animations:
        entries = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % regions[c] for c in frames)
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                     % (entries, "true" if loop else "false", name, fps))
    text = ('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n'
            '[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n\n' % (len(subs) + 2, texture_path)
            + "\n".join(subs) + "\n[resource]\nanimations = [" + ", ".join(anims) + "]\n")
    with open(path, "w") as out:
        out.write(text)
