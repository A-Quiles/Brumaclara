"""Prop scenes for the sprites of the second art pass (tools/art_pipeline/v2.py):
scenes/environment/props/<name>.tscn with the sprite standing on its feet, a soft shadow and a
collision cylinder as wide as the drawing.

    python3 tools/levels/props_v2.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PX = 0.0449  # world units per sprite pixel
PROPS = ["merchant_wagon", "cloth_cart", "potion_stall", "smith_stall", "food_stall", "fortune_tent", "town_arch"]
CLASS = {"town_arch": None}  # no collision cylinder: the arch is walked through (piers below)

TEMPLATE = """[gd_scene format=3]

[ext_resource type="Texture2D" path="res://assets/environment/props/{name}.png" id="1_tex"]
[ext_resource type="Texture2D" path="res://assets/environment/textures/blob_shadow.png" id="2_shadow"]

{shapes}
[node name="{node}" type="StaticBody3D"]

[node name="Sprite" type="Sprite3D" parent="."]
centered = false
offset = Vector2({ox}, 0)
pixel_size = {px}
alpha_cut = 1
texture_filter = 0
texture = ExtResource("1_tex")

[node name="Shadow" type="Sprite3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.05, 0.02, {sz})
cast_shadow = 0
pixel_size = {sp}
axis = 1
texture_filter = 0
texture = ExtResource("2_shadow")
{collision}"""


def write(name):
    w, h = Image.open(ROOT / "assets" / "environment" / "props" / f"{name}.png").size
    node = "".join(p.capitalize() for p in name.split("_"))
    if name == "town_arch":  # two piers, open in the middle
        shapes = '[sub_resource type="BoxShape3D" id="Pier"]\nsize = Vector3(0.7, 3, 0.9)\n'
        collision = "".join(f'\n[node name="Pier{i}" type="CollisionShape3D" parent="."]\n'
                            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 1.5, -0.4)\n"
                            'shape = SubResource("Pier")\n' for i, x in enumerate((-1.25, 1.25)))
    else:
        r = round(w * PX * 0.36, 2)
        shapes = f'[sub_resource type="CylinderShape3D" id="Body"]\nheight = 1.6\nradius = {r}\n'
        collision = ('\n[node name="Collision" type="CollisionShape3D" parent="."]\n'
                     "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)\n"
                     'shape = SubResource("Body")\n')
    text = TEMPLATE.format(name=name, node=node, shapes=shapes, ox=-w / 2, px=PX, sz=round(-w * 0.008, 3),
                           sp=round(w * 0.00283, 3), collision=collision)
    (ROOT / "scenes" / "environment" / "props" / f"{name}.tscn").write_text(text)


if __name__ == "__main__":
    for p in PROPS:
        write(p)
    print("props:", ", ".join(PROPS))
