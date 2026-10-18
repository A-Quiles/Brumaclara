"""Assembles the fight recorded by screenshot_tour.gd (combat) into docs/screenshots/04_combate.gif.

Usage: python3 tools/capture/make_gif.py <folder with 000.png, 001.png ...>
Frames are 640x360 at 30 fps; the GIF keeps every other one (15 fps) at that size so the file stays
small enough for the README, with one shared palette and no dithering so the pixel art stays crisp.
"""
import sys
from pathlib import Path

from PIL import Image

frames = [Image.open(p).convert("RGB") for p in sorted(Path(sys.argv[1]).glob("*.png"))[::2]]
assert frames, "no frames"
sample = Image.new("RGB", (frames[0].width, frames[0].height * 8))
for i, im in enumerate(frames[:: max(1, len(frames) // 8)][:8]):
    sample.paste(im, (0, i * im.height))
palette = sample.quantize(255, method=Image.Quantize.MEDIANCUT)
out = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in frames]
target = Path(__file__).resolve().parents[2] / "docs" / "screenshots" / "04_combate.gif"
out[0].save(target, save_all=True, append_images=out[1:], duration=66, loop=0, optimize=True)
print(target, len(out), "frames")
