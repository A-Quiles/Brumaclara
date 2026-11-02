"""Art audit (docs/plan_unificacion_artistica.md, sections 3 and 5).

Measures every PNG under assets/ the way it ends up on screen:
  * apparent pixel: world units per texel where the game draws it, divided by the reference
    (sprites: pixel_size 0.0449, the hero's). 1.0 = same pixel as the hero; 1.5 = fatter pixels.
  * smooth: share of neighbouring pixel pairs that differ only slightly (gradients, anti-aliasing,
    painted shading). High = reads as "painting", not pixel art.
  * noise: share of pixels unlike all four neighbours (lone pixels).
  * cluster: mean run of identical colour along rows (how chunky the pixel clusters are).
  * colours: distinct colours.
Writes tools/art_audit/out/audit.csv and prints the table sorted by how far each asset is from
the reference band (taken from the hero sheets).

    python3 tools/art_audit/audit.py
"""
import csv
import math
import re
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "out"
REF_PX = 0.0449  # world units per sprite pixel (docs/guia_de_arte.md)
SMALL = 24  # max channel difference that counts as a "soft" step between two pixels

EXT = re.compile(r'\[ext_resource type="(\w+)"[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"')
SECTION = re.compile(r'^\[(\w+)([^\]]*)\]\s*$')
ATTR = re.compile(r'(\w+)=("[^"]*"|\w+\("[^"]*"\))')


def parse(path):
    """(ext {id: (type, path)}, sections [(kind, attrs, props)]) of a .tscn/.tres file."""
    ext, sections = {}, []
    for line in path.read_text(errors="ignore").splitlines():
        m = EXT.search(line)
        if m:
            ext[m.group(3)] = (m.group(1), m.group(2))
            continue
        m = SECTION.match(line)
        if m:
            sections.append((m.group(1), dict(ATTR.findall(m.group(2))), {}))
        elif sections and " = " in line:
            k, v = line.split(" = ", 1)
            sections[-1][2][k.strip()] = v.strip()
    return ext, sections


def ref_id(value):
    m = re.search(r'Resource\("([^"]+)"\)', value or "")
    return m.group(1) if m else None


def scale_of(props):
    t = props.get("transform")
    if not t:
        return 1.0
    n = [float(x) for x in re.findall(r"-?[\d.]+(?:e-?\d+)?", t.split("(", 1)[1])]
    sx = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
    sy = math.sqrt(n[3] ** 2 + n[4] ** 2 + n[5] ** 2)
    return (sx + sy) / 2


USES = defaultdict(list)  # asset path -> [(apparent pixel ratio, where)]


def textures_of(ext, sections, value):
    """Texture paths a property points at (a texture, or sprite frames full of atlas textures)."""
    rid = ref_id(value)
    if rid is None:
        return []
    if rid in ext:
        kind, p = ext[rid]
        if kind == "Texture2D":
            return [p]
        if p.endswith(".tres") and (ROOT / p).exists():
            e2, s2 = parse(ROOT / p)
            return [q for k, q in e2.values() if k == "Texture2D"]
        return []
    sub = [s for s in sections if s[0] == "sub_resource" and s[1].get("id", "").strip('"') == rid]
    if not sub:
        return []
    if sub[0][1].get("type", "").strip('"') == "SpriteFrames":
        return sorted({p for k, p in ext.values() if k == "Texture2D"})
    return textures_of(ext, sections, sub[0][2].get("atlas", ""))


def walk(scene, factor=1.0, where=None, seen=()):
    if scene in seen or not (ROOT / scene).exists():
        return
    ext, sections = parse(ROOT / scene)
    where = where or scene
    scales = {}
    for kind, attrs, props in sections:
        if kind == "sub_resource" and attrs.get("type", "").strip('"') == "ShaderMaterial":
            material(ext, sections, props, where)
        if kind != "node":
            continue
        name = attrs.get("name", "").strip('"')
        parent = attrs.get("parent", "").strip('"')
        path = name if not parent else (name if parent == "." else f"{parent}/{name}")
        base = factor if not parent else scales.get(parent if parent != "." else "", factor)
        if not parent:
            path = ""
        s = base * scale_of(props)
        scales[path] = s
        inst = ref_id(attrs.get("instance", ""))
        if inst and inst in ext:
            walk(ext[inst][1], s, where, seen + (scene,))
        if "texture" in props or "sprite_frames" in props:
            px = float(props.get("pixel_size", "0.01"))
            for tex in textures_of(ext, sections, props.get("texture") or props.get("sprite_frames")):
                if "shadow" not in tex and "glow" not in tex:
                    USES[tex].append((round(px * s / REF_PX, 2), where))
        mo = ref_id(props.get("material_override", "")) or ref_id(props.get("surface_material_override/0", ""))
        if mo and mo in ext and ext[mo][1].endswith(".tres"):
            e2, s2 = parse(ROOT / ext[mo][1])
            res = [x for x in s2 if x[0] == "resource"]
            if res:
                material(e2, s2, res[0][2], where)


SIZE_OF = {"top_texture": "top_size", "side_texture": "side_size", "surface": "tile"}


def material(ext, sections, props, where):
    """Textures on meshes: world size of one texture repeat / texture width."""
    for key, value in props.items():
        if not key.startswith("shader_parameter/"):
            continue
        param = key.split("/", 1)[1]
        rid = ref_id(value)
        if rid not in ext or ext[rid][0] != "Texture2D":
            continue
        tex = ext[rid][1]
        if param == "paths" or not (ROOT / tex).exists():
            continue
        width = Image.open(ROOT / tex).width
        size_key = SIZE_OF.get(param)
        if size_key and f"shader_parameter/{size_key}" in props:
            nums = re.findall(r"-?[\d.]+", props[f"shader_parameter/{size_key}"].split("(")[-1])
            world = float(nums[0])
        elif param == "cobble":
            world = float(props.get("shader_parameter/big_tile", 10.9))
        else:
            world = float(props.get("shader_parameter/tile", 5.45))
        USES[tex].append((round(world / width / REF_PX, 2), where))


def metrics(path):
    im = np.asarray(Image.open(path).convert("RGBA")).astype(int)
    rgb, alpha = im[..., :3], im[..., 3] > 127
    if alpha.sum() < 16:
        return None
    out = {}
    pairs = soft = 0
    for a, b, m in ((rgb[:, 1:], rgb[:, :-1], alpha[:, 1:] & alpha[:, :-1]),
                    (rgb[1:], rgb[:-1], alpha[1:] & alpha[:-1])):
        d = np.abs(a - b).max(-1)[m]
        differ = d > 0
        pairs += differ.sum()
        soft += (differ & (d <= SMALL)).sum()
    out["smooth"] = round(soft / max(pairs, 1), 3)
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    strong = total = 0
    for a, b, m in ((lum[:, 1:], lum[:, :-1], alpha[:, 1:] & alpha[:, :-1]), (lum[1:], lum[:-1], alpha[1:] & alpha[:-1])):
        strong += (np.abs(a - b)[m] >= 48).sum()
        total += m.sum()
    out["edges"] = round(strong / max(total, 1), 3)  # outlines, beams, joints: low = oversized, blurry-looking detail
    mx, mn = rgb.max(-1)[alpha], rgb.min(-1)[alpha]
    out["sat"] = round(float(np.mean((mx - mn) / np.maximum(mx, 1))), 2)
    out["value"] = round(float(np.mean(lum[alpha])) / 255, 2)
    key = (rgb[..., 0] << 16) | (rgb[..., 1] << 8) | rgb[..., 2]
    out["colours"] = int(len(np.unique(key[alpha])))
    lone = np.ones_like(alpha)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        lone &= np.roll(key, (dy, dx), (0, 1)) != key
    inner = alpha & np.roll(alpha, 1, 0) & np.roll(alpha, -1, 0) & np.roll(alpha, 1, 1) & np.roll(alpha, -1, 1)
    out["noise"] = round((lone & inner).sum() / max(inner.sum(), 1), 3)
    runs = []
    for row, mrow in zip(key, alpha):
        change = np.flatnonzero(np.diff(row) != 0)
        cuts = np.concatenate(([0], change + 1, [len(row)]))
        lens = np.diff(cuts)
        runs.extend(l for l, start in zip(lens, cuts[:-1]) if mrow[start])
    out["cluster"] = round(float(np.mean(runs)), 2) if runs else 0
    out["size"] = f"{im.shape[1]}x{im.shape[0]}"
    return out


def main():
    for scene in sorted(ROOT.glob("scenes/**/*.tscn")):
        walk(str(scene.relative_to(ROOT)))
    for tres in sorted(ROOT.glob("materials/**/*.tres")):
        e2, s2 = parse(tres)
        res = [x for x in s2 if x[0] == "resource"]
        if res:
            material(e2, s2, res[0][2], str(tres.relative_to(ROOT)))
    rows = []
    for png in sorted(ROOT.glob("assets/**/*.png")):
        rel = str(png.relative_to(ROOT))
        m = metrics(png)
        if m is None:
            continue
        uses = USES.get(rel, [])
        ratios = sorted({r for r, _ in uses})
        m.update(asset=rel, pixel=",".join(str(r) for r in ratios) or "-",
                 used_in=len({w for _, w in uses}))
        rows.append(m)
    OUT.mkdir(exist_ok=True)
    with open(OUT / "audit.csv", "w", newline="") as f:
        w = csv.DictWriter(f, ["asset", "size", "pixel", "smooth", "edges", "noise", "cluster", "colours", "sat", "value", "used_in"])
        w.writeheader()
        w.writerows(rows)
    print(f"{len(rows)} assets -> {OUT / 'audit.csv'}")


if __name__ == "__main__":
    main()
