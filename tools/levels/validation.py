"""Art validation scene (docs/plan_unificacion_artistica.md, section 5): scenes/dev/validacion_arte.tscn.

The light, the sky, the ground, the camera (the Player's), the HUD and one house are copied from
Brumaclara as they are, so the composition renders exactly like the game; around them stand a
neighbour, a tree and low plants, the barrel, crate, chest and lantern, a market stall, the
interior floor and wall, a stone wall and a magic effect that repeats (scripts/dev/art_validation.gd).
Every new or redone asset is tried here first (tools/capture/validacion_arte.sh).

    python3 tools/levels/validation.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOWN = ROOT / "scenes" / "levels" / "brumaclara.tscn"
OUT = ROOT / "scenes" / "dev" / "validacion_arte.tscn"
HOUSE = "CasaRoja"
KEEP = ["WorldEnvironment", "Sun", "Ground", "Buildings", f"Buildings/{HOUSE}", "Backdrop", "Player", "HUD"]
HOUSE_AT = (29.0, 0.0, -14.0)  # where the house stands in the town: the composition is built round it
# (scene, x, z) relative to the house's front door; the camera looks north (-z), the hero stands at (0, 5)
PROPS = [
    ("res://scenes/characters/townsfolk/mara.tscn", 2.2, 4.4),
    ("res://scenes/environment/nature/tree_oak.tscn", -6.8, 1.0),
    ("res://scenes/environment/nature/bush.tscn", -4.6, 2.2),
    ("res://scenes/environment/props/flower_bed.tscn", -3.2, 3.4),
    ("res://scenes/environment/props/barrel.tscn", -1.9, 6.6),
    ("res://scenes/environment/props/crate.tscn", -1.0, 6.9),
    ("res://scenes/environment/props/interior/cofre_tesoro.tscn", 1.3, 6.8),
    ("res://scenes/environment/props/street_lamp.tscn", 3.4, 6.2),
    ("res://scenes/environment/props/stall_red.tscn", 5.6, 3.4),
    ("res://scenes/environment/props/potion_stall.tscn", 8.2, 1.6),
    ("res://scenes/environment/props/interior/silla.tscn", -5.0, 7.4),
    ("res://scenes/environment/props/interior/barril_grifo.tscn", -6.4, 7.0),
]
# an interior sample (floor + plaster wall) and a stone wall, with the same materials as the game
BLOCKS = [  # (material, x, y, z, size)
    ("res://materials/interior/floor_planks.tres", -6.0, -0.44, 7.6, (3.6, 1.0, 2.2)),
    ("res://materials/interior/wall_plaster.tres", -6.0, 1.2, 6.3, (3.6, 2.4, 0.4)),
]


def blocks(text):
    """Header-delimited sections of a .tscn: (header line, full text)."""
    parts = re.split(r"(?m)^(?=\[)", text)
    return [(p.split("\n", 1)[0], p) for p in parts if p.startswith("[")]


def node_path(header):
    name = re.search(r'name="([^"]+)"', header).group(1)
    parent = re.search(r'parent="([^"]*)"', header)
    if parent is None:
        return ""
    return name if parent.group(1) == "." else f"{parent.group(1)}/{name}"


def main():
    sections = blocks(TOWN.read_text())
    ext = {re.search(r'id="([^"]+)"', h).group(1): s for h, s in sections if h.startswith("[ext_resource")}
    sub = {re.search(r'id="([^"]+)"', h).group(1): s for h, s in sections if h.startswith("[sub_resource")}
    nodes = []
    for h, s in sections:
        if not h.startswith("[node"):
            continue
        path = node_path(h)
        if path == "" or path in KEEP or path.startswith(f"Buildings/{HOUSE}/"):
            nodes.append(s)
    used_ext, used_sub, todo = set(), set(), "".join(nodes)
    while todo:
        found = ""
        for kind, rid in re.findall(r'(ExtResource|SubResource)\("([^"]+)"\)', todo):
            if kind == "ExtResource" and rid not in used_ext:
                used_ext.add(rid)
            elif kind == "SubResource" and rid not in used_sub and rid in sub:
                used_sub.add(rid)
                found += sub[rid]
        todo = found
    root = nodes[0]
    root = re.sub(r'name="Brumaclara"', 'name="ValidacionArte"', root)
    root = re.sub(r"\nscript = [^\n]*", "", root)
    hx, _, hz = HOUSE_AT
    out = ["[gd_scene format=3]\n\n"]
    out += [ext[r] for r in ext if r in used_ext]
    out.append('[ext_resource type="Script" path="res://scripts/dev/art_validation.gd" id="900_val"]\n')
    for i, (scene, *_rest) in enumerate(PROPS):
        out.append(f'[ext_resource type="PackedScene" path="{scene}" id="91{i:02d}_p"]\n')
    for i, (mat, *_rest) in enumerate(BLOCKS):
        out.append(f'[ext_resource type="Material" path="{mat}" id="95{i}_m"]\n')
    out.append("\n")
    out += [sub[r] for r in sub if r in used_sub]
    for i, (_m, _x, _y, _z, size) in enumerate(BLOCKS):
        out.append(f'[sub_resource type="BoxMesh" id="BoxMesh_val{i}"]\nsize = Vector3({size[0]}, {size[1]}, {size[2]})\n\n')
    out.append(root.rstrip("\n") + '\nscript = ExtResource("900_val")\n\n')
    for s in nodes[1:]:
        if re.search(r'^\[node name="Player"', s):
            s = re.sub(r"transform = Transform3D\([^)]*\)", f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hx}, 0, {hz + 5.0})", s)
        out.append(s if s.endswith("\n\n") else s.rstrip("\n") + "\n\n")
    out.append('[node name="Muestras" type="Node3D" parent="."]\n\n')
    for i, (scene, x, z) in enumerate(PROPS):
        name = Path(scene).stem.capitalize()
        out.append(f'[node name="{name}" parent="Muestras" instance=ExtResource("91{i:02d}_p")]\n'
                   f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hx + x}, 0, {hz + z})\n\n")
    for i, (_m, x, y, z, _s) in enumerate(BLOCKS):
        out.append(f'[node name="Bloque{i}" type="MeshInstance3D" parent="Muestras"]\n'
                   f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hx + x}, {y}, {hz + z})\n"
                   f'mesh = SubResource("BoxMesh_val{i}")\nmaterial_override = ExtResource("95{i}_m")\n\n')
    out.append(f'[node name="Efecto" type="Marker3D" parent="Muestras"]\n'
               f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hx - 1.6}, 0, {hz + 2.6})\n")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("".join(out))
    print(OUT, len(used_ext), "resources,", len(nodes), "nodes from the town")


if __name__ == "__main__":
    main()
