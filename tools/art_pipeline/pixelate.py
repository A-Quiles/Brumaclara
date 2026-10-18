"""Turns AI-generated "pixel art" images into clean game pixels.

AI images draw pixel art with soft, slightly irregular blocks of several screen pixels. Here each
block becomes one game pixel: the background colour is keyed out, the image is averaged over f x f
blocks aligned with the drawing's own grid (the phase with the least variance inside the blocks),
and the colours are snapped to a palette so every asset shares the same flat tones.
"""
import numpy as np
from PIL import Image


def load(path):
    """RGB float array (0-255) of an image file."""
    return np.asarray(Image.open(path).convert("RGB")).astype(np.float64)


def background_mask(rgb, bg, tol=60.0):
    """True where the pixel is the flat background colour `bg` (RGB 0-255)."""
    return np.sqrt(((rgb - np.asarray(bg, np.float64)) ** 2).sum(-1)) < tol


def dominant_border_colour(rgb):
    """Most common colour on the image border: the backdrop the sprites were drawn on."""
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]]).round(-1)
    colours, counts = np.unique(border, axis=0, return_counts=True)
    return colours[counts.argmax()]


def downscale(rgb, alpha, f, coverage=0.5):
    """Average f x f blocks (alpha-weighted) at the grid phase that keeps blocks most uniform.

    Returns (rgb, alpha) at 1/f size; alpha is 0 or 1 (a block is solid if `coverage` of it is).
    """
    best = None
    for oy in range(f):
        for ox in range(f):
            h, w = (rgb.shape[0] - oy) // f, (rgb.shape[1] - ox) // f
            c = rgb[oy:oy + h * f, ox:ox + w * f].reshape(h, f, w, f, 3)
            a = alpha[oy:oy + h * f, ox:ox + w * f].reshape(h, f, w, f)
            weight = a.sum((1, 3))
            mean = (c * a[..., None]).sum((1, 3)) / np.maximum(weight, 1e-9)[..., None]
            spread = (((c - mean[:, None, :, None, :]) ** 2).sum(-1) * a).sum()
            if best is None or spread < best[0]:
                best = (spread, mean, (weight / (f * f) >= coverage).astype(np.float64))
    return best[1], best[2]


def oklab(rgb):
    """sRGB (0-255) -> OKLab, for perceptual colour distances."""
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    lms = c @ np.array([[0.4122214708, 0.2119034982, 0.0883024619],
                        [0.5363325363, 0.6806995451, 0.2817188376],
                        [0.0514459929, 0.1073969566, 0.6299787005]])
    lms = np.cbrt(lms)
    return lms @ np.array([[0.2104542553, 1.9779984951, 0.0259040371],
                           [0.7936177850, -2.4285922050, 0.7827717662],
                           [-0.0040720468, 0.4505937099, -0.8086757660]])


def kmeans_palette(pixels, n, iterations=25, seed=1):
    """n representative colours (RGB 0-255) of the pixels, clustered in OKLab."""
    rng = np.random.default_rng(seed)
    lab = oklab(pixels)
    centres = lab[rng.choice(len(lab), size=min(n, len(lab)), replace=False)]
    for _ in range(iterations):
        nearest = ((lab[:, None, :] - centres[None]) ** 2).sum(-1).argmin(1)
        for k in range(len(centres)):
            members = nearest == k
            if members.any():
                centres[k] = lab[members].mean(0)
    nearest = ((lab[:, None, :] - centres[None]) ** 2).sum(-1).argmin(1)
    return np.array([pixels[nearest == k].mean(0) for k in range(len(centres)) if (nearest == k).any()]).round()


def snap(rgb, alpha, palette):
    """Every solid pixel takes the perceptually closest palette colour."""
    lab, pal = oklab(rgb.reshape(-1, 3)), oklab(np.asarray(palette, np.float64))
    nearest = np.empty(len(lab), np.int64)
    for i in range(0, len(lab), 65536):  # chunks keep the distance table small
        nearest[i:i + 65536] = ((lab[i:i + 65536, None, :] - pal[None]) ** 2).sum(-1).argmin(1)
    out = np.asarray(palette, np.float64)[nearest].reshape(rgb.shape)
    return np.where(alpha[..., None] > 0, out, 0)


def seam_cut(a, b):
    """Column index per row of the cheapest top-to-bottom path through |a - b| (a, b: h x w x 3)."""
    cost = np.sqrt(((a - b) ** 2).sum(-1))
    cost[:, 0] = cost[:, -1] = 1e9  # the switch must happen inside the band, never on its edge
    acc = cost.copy()
    for y in range(1, len(acc)):
        prev = np.pad(acc[y - 1], 1, constant_values=np.inf)
        acc[y] += np.minimum(np.minimum(prev[:-2], prev[1:-1]), prev[2:])
    path = [int(acc[-1].argmin())]
    for y in range(len(acc) - 2, -1, -1):
        x = path[-1]
        lo = max(0, x - 1)
        path.append(lo + int(acc[y, lo:x + 2].argmin()))
    return path[::-1]


def make_tileable(rgb, band, vertical=True):
    """Wraps a texture seamlessly by overlapping a `band` of each edge with the opposite edge and
    switching between them along the least visible seam (no blending, so pixels stay crisp).
    With vertical=False it only wraps sideways (a panorama)."""
    for _ in range(2 if vertical else 1):  # horizontal wrap, then the same on the transposed image
        h, w, _ = rgb.shape
        left, right = rgb[:, :band], rgb[:, w - band:]
        seam = seam_cut(left, right)
        out = rgb[:, :w - band].copy()
        for y, x in enumerate(seam):
            out[y, :x] = right[y, :x]
        rgb = out.transpose(1, 0, 2)
    return rgb if vertical else rgb.transpose(1, 0, 2)


def despeckle(alpha):
    """Drops lone solid pixels and fills lone holes left by the keying."""
    p = np.pad(alpha, 1)
    neighbours = p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:]
    alpha = np.where((alpha > 0) & (neighbours == 0), 0, alpha)
    return np.where((alpha == 0) & (neighbours == 4), 1, alpha)


def to_image(rgb, alpha):
    return Image.fromarray(np.dstack([rgb, alpha * 255]).round().astype(np.uint8), "RGBA")


def pixelate(rgb, bg, f, palette=None, tol=60.0):
    """Full treatment of one cut-out: key, downscale, despeckle, snap. Returns an RGBA image."""
    alpha = (~background_mask(rgb, bg, tol)).astype(np.float64)
    small, a = downscale(rgb, alpha, f)
    a = despeckle(a)
    if palette is not None:
        small = snap(small, a, palette)
    return to_image(small, a)


if __name__ == "__main__":
    # self-check: a 3x upscaled 4x4 checker with a known phase comes back exactly
    base = np.zeros((4, 4, 3))
    base[::2, ::2] = base[1::2, 1::2] = 200
    big = np.pad(np.kron(base, np.ones((3, 3, 1))), ((1, 2), (2, 1), (0, 0)), constant_values=255)
    small, a = downscale(big, np.ones(big.shape[:2]), 3)
    assert np.allclose(small[:4, :4], base), small[:4, :4, 0]
    pal = kmeans_palette(np.array([[0, 0, 0], [1, 1, 1], [250, 250, 250], [255, 255, 255]], float), 2)
    assert len(pal) == 2
    # tileable: a horizontal ramp wrapped with a band keeps its width minus the band, and every
    # output row continues from its last pixel into its first one as in the source
    ramp = np.dstack([np.tile(np.arange(40.0), (30, 1))] * 3)
    tiled = make_tileable(ramp, 8)
    assert tiled.shape == (22, 32, 3)
    assert make_tileable(ramp, 8, vertical=False).shape == (30, 32, 3)
    print("pixelate ok")
