"""Pieces of the extra-angle sheets in art/ai/variants (drawn on magenta, saved as JPEG): finds every
object on a sheet as a connected blob of non-magenta pixels, leaving out labels and frames.

python3 tools/art_pipeline/variants.py <sheet> <out.png>   draws the blobs of a sheet with their indices
"""
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage


def magenta_mask(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return (r > 150) & (b > 150) & (g < 110) & (np.abs(r - b) < 90)


def pieces(rgb, min_size=36):
    """Bounding boxes (x0, y0, x1, y1) of the objects on a sheet, in reading order."""
    solid = ~magenta_mask(rgb)
    solid = ndimage.binary_opening(solid, iterations=2)
    labels, _ = ndimage.label(solid)
    out = []
    for i, sl in enumerate(ndimage.find_objects(labels), 1):
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        if h < min_size or w < 12 or h > rgb.shape[0] * 0.9 or w > rgb.shape[1] * 0.9:
            continue
        blob = rgb[sl][labels[sl] == i]
        light = (blob.min(1) > 170).mean()  # labels, grid lines and the light frames
        dark = (blob.max(1) < 60).mean()    # drawings always have a dark outline
        if light > 0.5 or dark < 0.02:
            continue
        out.append((sl[1].start, sl[0].start, sl[1].stop, sl[0].stop))
    out.sort(key=lambda b: (round(b[1] / 60), b[0]))
    return out


def cut(rgb, box, pad=3):
    """RGBA cut-out of one piece, magenta keyed out."""
    x0, y0, x1, y1 = box
    sub = rgb[max(0, y0 - pad):y1 + pad, max(0, x0 - pad):x1 + pad]
    alpha = ~magenta_mask(sub)
    alpha = ndimage.binary_opening(alpha, iterations=1)
    return np.dstack([sub, alpha * 255]).astype(np.uint8)


if __name__ == "__main__":
    rgb = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(np.int32)
    im = Image.fromarray(rgb.astype(np.uint8))
    d = ImageDraw.Draw(im)
    for i, b in enumerate(pieces(rgb)):
        d.rectangle(b, outline=(0, 255, 255), width=2)
        d.text((b[0] + 3, b[1] + 3), str(i), fill=(255, 255, 0), stroke_width=2, stroke_fill=(0, 0, 0))
    im.save(sys.argv[2])
