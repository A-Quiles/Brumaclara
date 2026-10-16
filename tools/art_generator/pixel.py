"""Small pixel-art canvas on top of Pillow: exact pixels, no antialiasing."""
import math
import random

from PIL import Image, ImageDraw

LIGHT = (-0.55, -0.7, 0.45)  # light comes from the upper left, slightly in front


def hex_rgba(value, alpha=255):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


class Canvas:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        self.px = self.img.load()

    # --- basic pixels -------------------------------------------------------
    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, color):
        x, y = int(x), int(y)
        if self.inside(x, y):
            self.px[x, y] = color

    def get(self, x, y):
        return self.px[int(x), int(y)] if self.inside(x, y) else (0, 0, 0, 0)

    def opaque(self, x, y):
        return self.get(x, y)[3] == 255

    def rect(self, x, y, w, h, color):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, color)

    def hline(self, x0, x1, y, color):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            self.set(x, y, color)

    def vline(self, x, y0, y1, color):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            self.set(x, y, color)

    def line(self, x0, y0, x1, y1, color):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.set(x0, y0, color)
            if x0 == x1 and y0 == y1:
                return
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, color):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, color)

    def polygon(self, points, color):
        ImageDraw.Draw(self.img).polygon(points, fill=color)

    def paste(self, other, x, y):
        self.img.alpha_composite(other.img, (int(x), int(y)))

    def save(self, path):
        self.img.save(path)

    # --- pixel-art helpers --------------------------------------------------
    def outline(self, color, only_below=None):
        """Adds a 1px outline around opaque pixels (shadows are ignored)."""
        targets = []
        for y in range(self.h):
            for x in range(self.w):
                if self.opaque(x, y):
                    continue
                if only_below is not None and y < only_below:
                    continue
                if any(self.opaque(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    targets.append((x, y))
        for x, y in targets:
            self.px[x, y] = color

    def shadow(self, cx, cy, rx, ry, alpha=90):
        """Soft drop shadow drawn only on empty pixels."""
        color = (16, 28, 30, alpha)
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0 and self.get(x, y)[3] == 0:
                    self.set(x, y, color)


def sphere_shade(nx, ny, ramp, bias=0.0):
    """Picks a ramp color for a point on a sphere (nx, ny in -1..1)."""
    nz = math.sqrt(max(0.0, 1.0 - nx * nx - ny * ny))
    lx, ly, lz = LIGHT
    norm = math.sqrt(lx * lx + ly * ly + lz * lz)
    light = (nx * lx + ny * ly + nz * lz) / norm + bias
    t = max(0.0, min(0.999, (light + 0.55) / 1.45))
    return ramp[int(t * len(ramp))]


def rng(seed):
    return random.Random(seed)
