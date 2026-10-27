"""The numbers of the bestiary's enemies drawn so far (docs/bestiario.md) -> data/enemies/<name>.tres,
and where they live in the outskirts (scenes/levels/afueras.tscn, under Enemies).

    python3 tools/data/enemies.py

Only enemies whose sheet exists (tools/art_pipeline/build.py monsters) are written or placed; the
sheet's recipe adds the sprite_offset. Re-running rewrites these files and these nodes only.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "enemies"
SHEETS = ROOT / "assets" / "characters" / "enemies"
LEVEL = ROOT / "scenes" / "levels" / "afueras.tscn"

# name -> display name, numbers (EnemyData fields), places in the outskirts
ENEMIES = {
    # zone 1 — outskirts of Brumaclara
    "roedor_bruma": ("Roedor de bruma", dict(max_hp=12, damage=5, push=4.0, speed=5.4, attack_speed=14.0, attack_range=2.6,
                     windup_seconds=0.4, xp_reward=8, respawn_seconds=14, weak=["fuego"], resist=[]),
                     [(-17, 4), (-16, 6), (-18.5, 5.5)]),
    "jabali_espinoso": ("Jabalí espinoso", dict(max_hp=70, damage=20, push=12.0, speed=3.4, attack_speed=16.0, attack_range=5.0,
                        windup_seconds=0.8, xp_reward=55, respawn_seconds=25, weak=["fuego"], resist=["tierra"]),
                        [(15, 8), (-8, 10)]),
    "cuervo_bruma": ("Cuervo de bruma", dict(max_hp=20, damage=8, push=5.0, speed=4.8, attack_speed=14.0, attack_range=3.6,
                     windup_seconds=0.5, xp_reward=18, respawn_seconds=18, weak=["rayo"], resist=["sombra"]),
                     [(4, 9), (8, 12)]),
    "saqueador": ("Saqueador de caminos", dict(max_hp=45, damage=12, push=6.0, speed=3.8, attack_range=6.0, windup_seconds=0.5,
                  xp_reward=40, respawn_seconds=30, weak=["sombra"], resist=[], attack_kind="volley", volley=1,
                  shot_speed=12.0, shot_affinity="luz"),
                  [(-20, -2), (-21, 1)]),
    # zone 2 — Bosque de los Susurros (for now at the edge of the outskirts' wood)
    "arana_musgo": ("Araña de musgo", dict(max_hp=30, damage=10, push=5.0, speed=4.4, attack_speed=14.0, attack_range=3.4,
                    windup_seconds=0.6, xp_reward=26, respawn_seconds=20, weak=["fuego"], resist=["sombra"]),
                    [(-15, -14), (-19, -12)]),
    "ciervo_cristal": ("Ciervo de cuerno cristal", dict(max_hp=80, damage=18, push=11.0, speed=4.2, attack_speed=17.0,
                       attack_range=5.0, windup_seconds=0.7, xp_reward=60, respawn_seconds=30, weak=["tierra"], resist=["luz"]),
                       [(-4, -18)]),
    "enredadera": ("Enredadera susurrante", dict(max_hp=50, damage=8, push=3.0, speed=0.0, attack_range=2.2, windup_seconds=0.5,
                   detect_radius=3.0, xp_reward=30, respawn_seconds=25, weak=["fuego"], resist=["tierra"], attack_kind="burst",
                   burst_radius=2.0, shot_affinity="tierra"),
                   [(-10, -17), (0, -19)]),
    # zone 3 — Humedal de la Barrera (no level yet: the bestiary gallery shows them)
    "rana_cornuda": ("Rana cornuda", dict(max_hp=35, damage=11, push=6.0, speed=3.6, attack_speed=18.0, attack_range=4.5,
                     windup_seconds=0.5, xp_reward=34, respawn_seconds=20, weak=["hielo"], resist=["fuego"]), []),
    "garza_alterada": ("Garza alterada", dict(max_hp=40, damage=16, push=7.0, speed=3.0, attack_speed=20.0, attack_range=5.0,
                       windup_seconds=0.4, xp_reward=40, respawn_seconds=22, weak=["rayo"], resist=[]), []),
    "sanguijuela_cristal": ("Sanguijuela de cristal", dict(max_hp=20, damage=4, push=2.0, speed=3.2, attack_range=2.4,
                            windup_seconds=0.5, xp_reward=18, respawn_seconds=18, weak=["fuego", "luz"], resist=["hielo"],
                            anomalous=True), []),
    "tortuga_lodo": ("Tortuga de lodo", dict(max_hp=110, damage=14, push=10.0, speed=1.8, attack_speed=12.0, attack_range=3.6,
                     windup_seconds=0.6, defense=0.4, xp_reward=70, respawn_seconds=30, weak=["tierra"], resist=["fuego"]), []),
    "fuego_fatuo": ("Fuego fatuo", dict(max_hp=15, damage=25, push=8.0, speed=3.0, attack_range=1.8, windup_seconds=1.0,
                    xp_reward=30, respawn_seconds=20, weak=["luz", "hielo"], resist=["fuego"], anomalous=True,
                    attack_kind="burst", burst_radius=1.8, shot_affinity="sombra"), []),
    "caiman_barrera": ("Caimán de la barrera", dict(max_hp=130, damage=26, push=12.0, speed=2.6, attack_speed=16.0,
                       attack_range=3.8, windup_seconds=0.8, xp_reward=90, respawn_seconds=35, weak=["rayo"], resist=["tierra"]), []),
    # zone 4 — Cantera Vieja
    "jabali_cantera": ("Jabalí de cantera", dict(max_hp=140, damage=28, push=12.0, speed=3.2, attack_range=2.6, windup_seconds=0.9,
                       xp_reward=95, respawn_seconds=35, weak=["hielo"], resist=["fuego"], attack_kind="burst", burst_radius=2.5,
                       shot_affinity="tierra"), []),
    "golem_escombro": ("Gólem de escombro", dict(max_hp=200, damage=22, push=12.0, speed=1.6, attack_range=2.6, windup_seconds=1.0,
                       defense=0.6, xp_reward=120, respawn_seconds=40, weak=["rayo", "tierra"], resist=["espada"],
                       attack_kind="burst", burst_radius=2.4, shot_affinity="tierra"), []),
    "minero_perdido": ("Minero perdido", dict(max_hp=60, damage=18, push=7.0, speed=3.4, attack_speed=12.0, attack_range=3.0,
                       windup_seconds=0.7, xp_reward=50, respawn_seconds=25, weak=["luz"], resist=[]), []),
    "murcielago_hollin": ("Murciélago de hollín", dict(max_hp=15, damage=6, push=4.0, speed=5.6, attack_speed=15.0,
                          attack_range=3.0, windup_seconds=0.4, xp_reward=14, respawn_seconds=15, weak=["fuego", "luz"], resist=[]), []),
    "escarabajo_perforador": ("Escarabajo perforador", dict(max_hp=55, damage=20, push=9.0, speed=3.2, attack_speed=16.0,
                              attack_range=3.6, windup_seconds=0.7, xp_reward=48, respawn_seconds=25, weak=["tierra"],
                              resist=["rayo"]), []),
    "pico_errante": ("Pico errante", dict(max_hp=35, damage=15, push=7.0, speed=4.4, attack_speed=16.0, attack_range=3.4,
                     windup_seconds=0.5, xp_reward=36, respawn_seconds=22, weak=["hielo"], resist=["fuego"], anomalous=True), []),
    # bosses of zones 2–4
    "arbol_susurra": ("El Árbol que susurra", dict(max_hp=800, damage=24, push=12.0, speed=0.0, attack_range=4.5,
                      detect_radius=9.0, windup_seconds=0.9, xp_reward=600, respawn_seconds=600, weak=["fuego"], resist=["tierra"],
                      boss=True, attack_kind="burst", burst_radius=4.0, shot_affinity="tierra", sprite_scale=1.6), []),
    "caparazon_vigilia": ("Caparazón de Vigilia", dict(max_hp=1100, damage=30, push=14.0, speed=1.4, attack_range=4.0,
                          windup_seconds=1.0, defense=0.3, xp_reward=800, respawn_seconds=600, weak=["tierra"], resist=["fuego"],
                          boss=True, attack_kind="burst", burst_radius=3.6, shot_affinity="hielo", sprite_scale=1.7), []),
    "taladro_trama": ("Taladro de la Trama", dict(max_hp=1500, damage=34, push=14.0, speed=2.0, attack_speed=14.0,
                      attack_range=6.0, windup_seconds=1.0, defense=0.3, xp_reward=1000, respawn_seconds=600, weak=["hielo"],
                      resist=["rayo"], boss=True, sprite_scale=1.7), []),
}


def _value(key, v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, list):
        return "Array[StringName]([" + ", ".join(f'&"{x}"' for x in v) + "])"
    if key == "attack_kind":
        return f'"{v}"'
    if isinstance(v, str):
        return f'&"{v}"'
    return repr(v)


def write_data(name, display, stats):
    path = DATA / f"{name}.tres"
    offset = None
    if path.exists():  # keep the sheet's sprite_offset
        m = re.search(r"sprite_offset = (Vector2\([^)]*\))", path.read_text())
        offset = m.group(1) if m else None
    lines = ['[gd_resource type="Resource" script_class="EnemyData" format=3]', "",
             '[ext_resource type="Script" path="res://scripts/data/enemy_data.gd" id="1_data"]',
             f'[ext_resource type="SpriteFrames" path="res://assets/characters/enemies/{name}_frames.tres" id="2_frames"]',
             "", "[resource]", 'script = ExtResource("1_data")', f'display_name = "{display}"', 'frames = ExtResource("2_frames")']
    if offset:
        lines.append(f"sprite_offset = {offset}")
    lines += [f"{k} = {_value(k, v)}" for k, v in stats.items()]
    path.write_text("\n".join(lines) + "\n")


def place(names):
    text = LEVEL.read_text()
    for name in names:
        text = re.sub(rf'\n\[node name="Bestia_{name}\d+" type="CharacterBody3D" parent="Enemies"[^\n]*\n(?:[^\[\n][^\n]*\n)*', "\n", text)
        text = re.sub(rf'\[ext_resource type="Resource" path="res://data/enemies/{name}.tres" id="904_{name}"\]\n', "", text)
    add = ""
    for name in names:
        text = text.replace('[ext_resource type="Script" path="res://scripts/systems/level_edits.gd"',
                            f'[ext_resource type="Resource" path="res://data/enemies/{name}.tres" id="904_{name}"]\n'
                            '[ext_resource type="Script" path="res://scripts/systems/level_edits.gd"', 1)
        for i, (x, z) in enumerate(ENEMIES[name][2]):
            add += (f'\n[node name="Bestia_{name}{i}" type="CharacterBody3D" parent="Enemies" instance=ExtResource("61_uikkc")]\n'
                    f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 0, {z})\ncollision_layer = 4\ncollision_mask = 7\n"
                    'script = ExtResource("62_gkhel")\n'
                    f'data = ExtResource("904_{name}")\norb_scene = ExtResource("56_vadvj")\n'
                    'death_effect = ExtResource("63_7y0p2")\ntext_scene = ExtResource("64_efuy5")\n')
    text = text.replace('\n[node name="Exit" type="Area3D"', add + '\n[node name="Exit" type="Area3D"', 1)
    text = re.sub(r"\n\n\n+", "\n\n", text)
    LEVEL.write_text(text)


def main():
    ready = [n for n in ENEMIES if (SHEETS / f"{n}_frames.tres").exists()]
    for name in ready:
        display, stats, _places = ENEMIES[name]
        write_data(name, display, stats)
    place(ready)
    print("enemies written and placed:", ", ".join(ready) or "none yet")


if __name__ == "__main__":
    main()
