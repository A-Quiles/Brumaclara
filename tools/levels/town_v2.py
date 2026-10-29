"""Second pass on Brumaclara (scenes/levels/brumaclara.tscn): the travelling merchants' stalls, the
grand gate as the way in from the outskirts (south exit), the way to the Patio de pruebas (arena) at
the west end of the guilds' terrace, and the names shown for the first townsfolk.

    python3 tools/levels/town_v2.py

Re-running replaces exactly what it wrote (nodes named V2_*, ExitSouth, ExitArena).
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOWN = ROOT / "scenes" / "levels" / "brumaclara.tscn"
OUTSKIRTS = ROOT / "scenes" / "levels" / "afueras.tscn"
ARENA = "res://scenes/levels/arena.tscn"

# prop -> where it stands (free spots found with tools/capture/free_spots.gd)
STALLS = {
    "merchant_wagon": (14.0, 0.0, 6.0),
    "potion_stall": (24.9, 0.0, -6.0),
    "smith_stall": (-19.4, 0.0, -1.6),
    "food_stall": (-14.0, 0.0, 6.0),
    "cloth_cart": (5.0, 0.0, 14.0),
    "fortune_tent": (30.0, 0.0, 8.0),
}
ARENA_ARCH = (-42.0, 2.4, -32.0)  # the arch faces the camera; the way out is just north of it
NAMES = {"Mara": "Mara Venn", "Carter": "Carretero", "Guard": "Guardia"}


def ext(text, kind, path, rid):
    if f'path="{path}"' in text:
        return text, re.search(rf'path="{re.escape(path)}" id="([^"]+)"', text).group(1)
    return text.replace("\n[sub_resource", f'\n[ext_resource type="{kind}" path="{path}" id="{rid}"]\n[sub_resource', 1), rid


def drop(text, name, parent):
    return re.sub(rf'\n\[node name="{name}" type="[^"]+" parent="{parent}"[^\n]*\n(?:[^\[\n][^\n]*\n)*', "\n", text)


def main():
    text = TOWN.read_text()
    nodes = ""
    for prop, (x, y, z) in STALLS.items():
        text, rid = ext(text, "PackedScene", f"res://scenes/environment/props/{prop}.tscn", f"950_{prop}")
        name = "V2_" + "".join(p.capitalize() for p in prop.split("_"))
        text = drop(text, name, "Props")
        nodes += (f'\n[node name="{name}" type="StaticBody3D" parent="Props" instance=ExtResource("{rid}")]\n'
                  f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z})\n")
    # the arch and sign to the arena
    text, arch = ext(text, "PackedScene", "res://scenes/environment/props/town_arch.tscn", "950_town_arch")
    for n in ("V2_ArenaArch", "V2_ArenaSign"):
        text = drop(text, n, "Props")
    x, y, z = ARENA_ARCH
    nodes += (f'\n[node name="V2_ArenaArch" type="StaticBody3D" parent="Props" instance=ExtResource("{arch}")]\n'
              f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z})\n"
              f'\n[node name="V2_ArenaSign" type="Label3D" parent="Props"]\n'
              f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y + 3.9}, {z + 0.3})\n"
              "billboard = 1\npixel_size = 0.012\nfont_size = 56\noutline_size = 14\n"
              'modulate = Color(1, 0.88, 0.55, 1)\ntext = "Patio de pruebas"\n')
    text = text.replace('\n[node name="Nature" type="Node3D" parent="."', nodes + '\n[node name="Nature" type="Node3D" parent="."', 1)

    # exits: through the grand gate to the outskirts, and west to the arena
    exit_script = re.search(r'\[ext_resource type="Script" path="res://scripts/systems/exit.gd" id="([^"]+)"\]', text).group(1)
    for n in ("ExitSouth", "ExitArena"):
        text = re.sub(rf'\n\[node name="{n}" type="Area3D" parent="\."[^\n]*\n(?:[^\[\n][^\n]*\n)*'
                      rf'(?:\n\[node name="Collision" type="CollisionShape3D" parent="{n}"[^\n]*\n(?:[^\[\n][^\n]*\n)*)?', "\n", text)
    text = re.sub(r'\[sub_resource type="BoxShape3D" id="ExitV2_[a-z]+"\]\nsize = [^\n]+\n\n', "", text)
    text = text.replace("\n[node name=", '\n[sub_resource type="BoxShape3D" id="ExitV2_south"]\nsize = Vector3(4, 3, 0.6)\n\n'
                        '[sub_resource type="BoxShape3D" id="ExitV2_arena"]\nsize = Vector3(2.4, 3, 0.6)\n\n[node name=', 1)
    exits = (f'\n[node name="ExitSouth" type="Area3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 36.85)\n'
             f'collision_layer = 0\ncollision_mask = 2\nscript = ExtResource("{exit_script}")\n'
             f'target_scene = "res://scenes/levels/afueras.tscn"\narrival = Vector3(-21, 0, -0.4)\n'
             f'\n[node name="Collision" type="CollisionShape3D" parent="ExitSouth"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)\n'
             f'shape = SubResource("ExitV2_south")\n'
             f'\n[node name="ExitArena" type="Area3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z - 1.6})\n'
             f'collision_layer = 0\ncollision_mask = 2\nscript = ExtResource("{exit_script}")\n'
             f'target_scene = "{ARENA}"\narrival = Vector3(0, 0, 17)\n'
             f'\n[node name="Collision" type="CollisionShape3D" parent="ExitArena"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)\n'
             f'shape = SubResource("ExitV2_arena")\n')
    text = text.replace('\n[node name="Backdrop"', exits + '\n[node name="Backdrop"', 1)

    # the fountain's water moves as particles (scripts/environment/fountain.gd)
    text, fs = ext(text, "Script", "res://scripts/environment/fountain.gd", "960_fountain")
    text = re.sub(r'(\[node name="Fountain" type="StaticBody3D" parent="Props"[^\n]*\ntransform = [^\n]+\n)(script = [^\n]+\n)?',
                  rf'\1script = ExtResource("{fs}")\n', text)

    # names in the dialogue box
    for node, shown in NAMES.items():
        text = re.sub(rf'(\[node name="{node}" type="CharacterBody3D" parent="People"[^\n]*\n(?:[^\[\n][^\n]*\n)*?)metadata/display_name = "[^"]*"\n', r"\1", text)
        text = re.sub(rf'(\[node name="{node}" type="CharacterBody3D" parent="People"[^\n]*\n(?:[^\[\n][^\n]*\n)*)',
                      lambda m: m.group(1) + f'metadata/display_name = "{shown}"\n', text, count=1)
    text = re.sub(r"\n\n\n+", "\n\n", text)
    TOWN.write_text(text)

    # coming back from the outskirts: through the grand gate
    outskirts = OUTSKIRTS.read_text()
    outskirts = re.sub(r'(target_scene = "res://scenes/levels/brumaclara.tscn"\narrival = )Vector3\([^)]*\)',
                       r"\1Vector3(0, 0, 34)", outskirts)
    OUTSKIRTS.write_text(outskirts)
    print("town: stalls, gate exit, arena exit, names")


if __name__ == "__main__":
    main()
