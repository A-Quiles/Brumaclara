"""Unification steps for redone art (docs/plan_unificacion_artistica.md): resize to the size an
object really has next to the hero, bring tone in line with its family, and snap to the master
palette (palette.py). Used by the recipes that redo assets from their existing sources, so no new
image has to be generated.
"""
import numpy as np
from PIL import Image

import palette
import pixelate as px

HERO_PX = 44  # the hero is 44 game px tall (1,75 m): 25 px per metre


def shrink(image, height):
    """An RGBA sprite area-averaged down to `height` px (never enlarged: that would fatten pixels)."""
    if image.height <= height:
        return image
    width = max(1, round(image.width * height / image.height))
    a = np.asarray(image).astype(np.float64)
    alpha = a[..., 3:] / 255.0
    pre = Image.fromarray(np.dstack([a[..., :3] * alpha, a[..., 3:]]).astype(np.uint8), "RGBA")
    small = np.asarray(pre.resize((width, height), Image.BOX)).astype(np.float64)
    sa = small[..., 3] / 255.0
    rgb = small[..., :3] / np.maximum(sa, 1e-3)[..., None]
    return px.to_image(np.clip(rgb, 0, 255), (sa > 0.5).astype(np.float64))


def tone(rgb, saturation=1.0, value=1.0):
    grey = rgb.mean(-1, keepdims=True)
    return np.clip((grey + (rgb - grey) * saturation) * value, 0, 255)


def master(image, saturation=1.0, value=1.0, keep=()):
    """An RGBA sprite toned and snapped to the master palette (`keep`: extra accents allowed)."""
    a = np.asarray(image.convert("RGBA")).astype(np.float64)
    solid = (a[..., 3] > 127).astype(np.float64)
    rgb = tone(a[..., :3], saturation, value)
    return px.to_image(palette.snap(rgb, keep=keep), solid)


def toned(image, saturation=1.0, value=1.0):
    """Tone only, keeping the image's own colours (for ramps the master palette is too coarse for,
    such as the red of a roof: snapped, its highlights collapsed into one flat red)."""
    a = np.asarray(image.convert("RGBA")).astype(np.float64)
    return px.to_image(tone(a[..., :3], saturation, value), (a[..., 3] > 127).astype(np.float64))
