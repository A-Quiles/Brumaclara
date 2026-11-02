"""After a sprite is redrawn at another width, puts its feet back under the node: every Sprite3D
drawn uncentred (`centered = false`) with that texture gets `offset.x = -width / 2`, in every scene
(prop scenes and the levels' own overrides). The vertical offset is kept.

    python3 tools/levels/fit_offsets.py assets/environment/props/bench.png ...
    python3 tools/levels/fit_offsets.py --changed      # every PNG git sees as modified
"""
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def fit(pngs):
    widths = {f"res://{p}": Image.open(ROOT / p).width for p in pngs}
    changed = 0
    for scene in ROOT.glob("scenes/**/*.tscn"):
        text = scene.read_text()
        ids = {m.group(2): widths[m.group(1)] for m in re.finditer(r'\[ext_resource type="Texture2D" path="([^"]+)" id="([^"]+)"\]', text)
               if m.group(1) in widths}
        if not ids:
            continue
        parts = re.split(r"(?m)^(?=\[)", text)
        for i, part in enumerate(parts):
            m = re.search(r'^texture = ExtResource\("([^"]+)"\)', part, re.M)
            if not (part.startswith("[node") and m and m.group(1) in ids and "centered = false" in part):
                continue
            half = ids[m.group(1)] / 2
            parts[i] = re.sub(r"offset = Vector2\([^,]+, ([^)]+)\)", lambda o: f"offset = Vector2({half:g}, {o.group(1)})".replace(f"({half:g}", f"({-half:g}"), part)
        new = "".join(parts)
        if new != text:
            scene.write_text(new)
            changed += 1
    return changed


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["--changed"]:
        out = subprocess.run(["git", "status", "--porcelain", "assets"], cwd=ROOT, capture_output=True, text=True).stdout
        args = [line[3:] for line in out.splitlines() if line.endswith(".png")]
    print(fit(args), "scenes updated")
