"""Extra hairstyles for the character creator, made from the drawn models (hero, heroine) by adding
hair pixels to every frame of the sheet: taller spikes, a crest, a top bun, long loose hair and a
fuller head of hair. Only pixels are added (never removed), so the drawing's own outline and face
stay intact; the colour mask grows with them, so the creator's hair colours still apply."""
import numpy as np
from PIL import Image

FW = FH = 56  # frame size of the hero sheets
UP_ROWS = {2, 5, 8}  # rows seen from behind (walk, attack, dodge)
STEP = 30  # the colour mask stores group id * STEP (see build.py: LOOK_STEP)
HAIR, SKIN, LEATHER, TROUSERS = STEP, 2 * STEP, 5 * STEP, 6 * STEP


def cells(arr):
    for r in range(arr.shape[0] // FH):
        for c in range(arr.shape[1] // FW):
            yield r, c, (slice(r * FH, (r + 1) * FH), slice(c * FW, (c + 1) * FW))


def _n4(a):
    p = np.pad(a, 1)
    return [p[:-2, 1:-1], p[2:, 1:-1], p[1:-1, :-2], p[1:-1, 2:]]


def _n8(a):
    p = np.pad(a, 1)
    return [p[dy:dy + a.shape[0], dx:dx + a.shape[1]] for dy in (0, 1, 2) for dx in (0, 1, 2) if (dy, dx) != (1, 1)]


def finish(rgba, mk, ink, rows_lo, rows_hi):
    """Seams between old outline and new hair become hair; the new silhouette gets an outline."""
    alpha = rgba[..., 3] > 0
    v = rgba[..., :3].max(2)
    zone = np.zeros_like(alpha)
    zone[rows_lo:rows_hi] = True
    outline = alpha & (mk == 0) & (v < 90)
    hair = mk == HAIR
    four = np.ones_like(alpha)
    for n in _n4(alpha):
        four &= n
    near_hair = np.zeros_like(alpha)
    for n in _n4(hair):
        near_hair |= n
    skin = mk == SKIN
    near_skin = np.zeros_like(alpha)
    for n in _n8(skin):
        near_skin |= n
    seam = outline & four & near_hair & ~near_skin & zone
    if seam.any():
        # colour of the hair pixel above, else any neighbour
        ys, xs = np.nonzero(seam)
        for y, x in zip(ys, xs):
            for dy, dx in ((-1, 0), (0, -1), (0, 1), (1, 0)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < FH and 0 <= xx < FW and mk[yy, xx] == HAIR:
                    rgba[y, x, :3] = (rgba[yy, xx, :3] * 0.85).astype(np.uint8)
                    mk[y, x] = HAIR
                    break
    alpha = rgba[..., 3] > 0
    outline = alpha & (mk == 0) & (rgba[..., :3].max(2) < 90)
    body = alpha & ~outline
    touch = np.zeros_like(alpha)
    for n in _n4(body):
        touch |= n
    new = ~alpha & touch & zone
    rgba[new, :3] = ink
    rgba[new, 3] = 255
    mk[new] = 0


def paint(rgba, mk, y, x, colour):
    if 0 <= y < FH and 0 <= x < FW and rgba[y, x, 3] == 0:
        rgba[y, x, :3] = np.clip(colour, 0, 255).astype(np.uint8)
        rgba[y, x, 3] = 255
        mk[y, x] = HAIR


def make(sheet, mask, style):
    img = np.array(sheet.convert("RGBA"))
    m = np.array(mask)
    out, om = img.copy(), m.copy()
    for r, c, (sy, sx) in cells(img):
        rgba = out[sy, sx]
        mk = om[sy, sx]
        hair = mk == HAIR
        if hair.sum() < 6:
            continue
        up = r in UP_ROWS
        rows = np.nonzero(hair.any(1))[0]
        top, bottom = rows.min(), rows.max()
        xs_top = np.nonzero(hair[top: top + 4].any(0))[0]
        cx = int(round(xs_top.mean()))
        v = rgba[..., :3].max(2)
        alpha = rgba[..., 3] > 0
        outline_px = alpha & (mk == 0) & (v < 90)
        ink = rgba[..., :3][outline_px][v[outline_px].argmin()] if outline_px.any() else np.array([38, 26, 24])
        lo = max(top - 8, 0)
        hi = bottom + 1
        if style in ("alto", "cresta"):
            pat = [4, 2, 3, 1, 4, 2] if style == "alto" else None
            for x in range(FW):
                ys = np.nonzero(hair[:, x])[0]
                if len(ys) == 0:
                    continue
                y0 = ys.min()
                h = pat[x % 6] if pat else (7 if abs(x - cx) <= 1 else (4 if abs(x - cx) == 2 else 0))
                col = rgba[y0, x, :3].astype(float)
                for step in range(1, h + 1):
                    paint(rgba, mk, y0 - step, x, col * (1.0 + 0.05 * step))
        elif style == "mono":  # a top bun
            col = rgba[top + 2, cx, :3].astype(float) if hair[top + 2, cx] else rgba[top, xs_top[0], :3].astype(float)
            cy = top - 2
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    d = dx * dx + dy * dy
                    if d <= 9:
                        shade = 1.12 if (dx + dy) < -1 else (0.88 if (dx + dy) > 2 else 1.0)
                        paint(rgba, mk, cy + dy, cx + dx, col * shade)
        elif style == "largo":
            k = 10 if up else 9
            for x in range(FW):
                ys = np.nonzero(hair[:, x])[0]
                if len(ys) == 0:
                    continue
                y0 = ys.max()
                col = rgba[y0, x, :3].astype(float)
                for step in range(1, k + 1):
                    y = y0 + step
                    if y >= FH:
                        break
                    if rgba[y, x, 3] > 0 and not (up and mk[y, x] in (0, SKIN, 3 * STEP, 4 * STEP, HAIR)):
                        break
                    if rgba[y, x, 3] > 0 and up and v[y, x] < 90 and mk[y, x] == 0:
                        pass
                    rgba[y, x, :3] = (col * (0.94 ** step)).astype(np.uint8)
                    rgba[y, x, 3] = 255
                    mk[y, x] = HAIR
        elif style == "volumen":
            grow = np.zeros_like(alpha)
            for n in _n8(hair):
                grow |= n
            grow &= ~alpha
            ys, xs = np.nonzero(grow)
            for y, x in zip(ys, xs):
                best = None
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < FH and 0 <= xx < FW and mk[yy, xx] == HAIR:
                        best = rgba[yy, xx, :3].astype(float) * 0.92
                if best is not None:
                    paint(rgba, mk, y, x, best)
        finish(rgba, mk, ink, lo, hi + (6 if style == "largo" else 0))
        out[sy, sx] = rgba
        om[sy, sx] = mk
    return Image.fromarray(out, "RGBA"), Image.fromarray(om, "L")
