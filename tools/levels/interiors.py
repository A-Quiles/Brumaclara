"""Writes the interiors of Brumaclara's buildings and the doors that lead into them.

    python3 tools/levels/interiors.py

- scenes/environment/props/interior/<name>.tscn: one prop per furniture image (assets/environment/props/interior),
  a standing sprite with its shadow and collision, or a rug lying on the floor;
- materials/interior/*.tres: floors and walls with the blocks' shader (tiling texture, dark edges);
- scenes/levels/interiors/<room>.tscn: the rooms, furnished, lit and with a way out to the town;
- scenes/levels/brumaclara.tscn: a door (Exit) on each building that has an interior.

The layouts below are the source of truth; the scenes are rewritten from them every run.
"""
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PX = 0.0449  # world units per sprite pixel
PROPS = ROOT / "assets" / "environment" / "props" / "interior"
PROP_SCENES = ROOT / "scenes" / "environment" / "props" / "interior"
MATERIALS = ROOT / "materials" / "interior"
ROOMS = ROOT / "scenes" / "levels" / "interiors"
TOWN = ROOT / "scenes" / "levels" / "brumaclara.tscn"
TILE = 84 * PX  # one texture tile (84 px) in world units

FLAT = {"alfombrilla"}  # lie on the floor
LIGHT = {"chimenea": ("ff9a3c", 2.2, 6.0), "fogon": ("ff9a3c", 1.4, 4.0), "candelabro": ("ffd27a", 1.0, 4.0),
         "farol_poste": ("ffd27a", 1.2, 4.5), "lampara_cristal": ("8fd8ff", 1.0, 4.0), "escritorio": ("ffd27a", 0.6, 3.0)}
DEPTH = {"cama": 1.6, "mesa_larga": 1.4, "mesa_redonda": 1.2, "barra": 1.0, "mesa_mapas": 1.2, "vitrina_pociones": 0.9,
         "mostrador_registro": 0.9, "banco_trabajo": 0.9}  # collision depth (default 0.7)


class Scene:
    """A tiny .tscn writer: resources first, then nodes in order."""

    def __init__(self):
        self.ext, self.sub, self.nodes = [], [], []

    def res(self, kind, path):
        for rid, k, p in self.ext:
            if p == path:
                return rid
        rid = f"{len(self.ext) + 1}_r"
        self.ext.append((rid, kind, path))
        return rid

    def subres(self, kind, **props):
        sid = f"{kind}_{len(self.sub) + 1}"
        self.sub.append((sid, kind, props))
        return sid

    def node(self, name, kind=None, parent=None, instance=None, groups=None, **props):
        self.nodes.append((name, kind, parent, instance, groups, props))

    def text(self):
        out = ["[gd_scene format=3]", ""]
        for rid, kind, path in self.ext:
            out.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
        out.append("")
        for sid, kind, props in self.sub:
            out.append(f'[sub_resource type="{kind}" id="{sid}"]')
            out += [f"{k} = {v}" for k, v in props.items()]
            out.append("")
        for name, kind, parent, instance, groups, props in self.nodes:
            head = f'[node name="{name}"'
            if kind:
                head += f' type="{kind}"'
            if parent is not None:
                head += f' parent="{parent}"'
            if groups:
                head += " groups=[" + ", ".join(f'"{g}"' for g in groups) + "]"
            if instance:
                head += f' instance=ExtResource("{instance}")'
            out.append(head + "]")
            out += [f"{k} = {v}" for k, v in props.items()]
            out.append("")
        return "\n".join(out)


def xform(x=0.0, y=0.0, z=0.0, sx=1.0, sy=1.0, sz=1.0):
    return f"Transform3D({sx}, 0, 0, 0, {sy}, 0, 0, 0, {sz}, {x}, {y}, {z})"


def colour(hexcol, a=1.0):
    r, g, b = (int(hexcol[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, {a})"


# --- props -------------------------------------------------------------------------------------------

def write_props():
    PROP_SCENES.mkdir(parents=True, exist_ok=True)
    for png in sorted(PROPS.glob("*.png")):
        name = png.stem
        w, h = Image.open(png).size
        sc = Scene()
        tex = sc.res("Texture2D", f"res://assets/environment/props/interior/{name}.png")
        if name in FLAT:
            sc.node(name.capitalize(), "Node3D")
            sc.node("Sprite", "Sprite3D", ".", transform=xform(y=0.02), pixel_size=PX, axis=1, alpha_cut=1,
                    texture_filter=0, texture=f'ExtResource("{tex}")')
        else:
            shadow = sc.res("Texture2D", "res://assets/environment/textures/blob_shadow.png")
            depth = DEPTH.get(name, 0.7)
            shape = sc.subres("BoxShape3D", size=f"Vector3({w * PX * 0.85:.3f}, 1.4, {depth})")
            sc.node(name.capitalize(), "StaticBody3D")
            sc.node("Sprite", "Sprite3D", ".", centered="false", offset=f"Vector2({-(w // 2)}, 0)", pixel_size=PX,
                    alpha_cut=1, texture_filter=0, texture=f'ExtResource("{tex}")')
            sc.node("Shadow", "Sprite3D", ".", transform=xform(y=0.02, z=-0.05), cast_shadow=0,
                    pixel_size=round(w * PX / 32 * 1.1, 4), axis=1, texture_filter=0, modulate=colour("ffffff", 0.8),
                    texture=f'ExtResource("{shadow}")')
            sc.node("Collision", "CollisionShape3D", ".", transform=xform(y=0.7, z=-depth / 2 + 0.25),
                    shape=f'SubResource("{shape}")')
            if name in LIGHT:
                col, energy, rng = LIGHT[name]
                sc.node("Light", "OmniLight3D", ".", transform=xform(y=h * PX * 0.6, z=0.6),
                        light_color=colour(col), light_energy=energy, omni_range=rng, shadow_enabled="false")
        (PROP_SCENES / f"{name}.tscn").write_text(sc.text())


# --- materials ---------------------------------------------------------------------------------------

def write_materials():
    MATERIALS.mkdir(parents=True, exist_ok=True)
    for name, top, side, side_size in (
            ("floor_planks", "floor_planks", "floor_planks", (TILE, TILE)),
            ("floor_flagstone", "floor_flagstone", "floor_flagstone", (TILE, TILE)),
            ("wall_plaster", "floor_planks", "wall_plaster", (TILE, TILE)),
    ):
        text = f'''[gd_resource type="ShaderMaterial" load_steps=4 format=3]

[ext_resource type="Shader" path="res://shaders/terrain_block.gdshader" id="1_s"]
[ext_resource type="Texture2D" path="res://assets/environment/textures/{top}.png" id="2_t"]
[ext_resource type="Texture2D" path="res://assets/environment/textures/{side}.png" id="3_s"]

[resource]
render_priority = 0
shader = ExtResource("1_s")
shader_parameter/top_texture = ExtResource("2_t")
shader_parameter/side_texture = ExtResource("3_s")
shader_parameter/top_size = Vector2({TILE:.4f}, {TILE:.4f})
shader_parameter/side_size = Vector2({side_size[0]:.4f}, {side_size[1]:.4f})
shader_parameter/top_local = true
shader_parameter/tint = Color(1, 1, 1, 1)
shader_parameter/edge_color = Color(0.13, 0.08, 0.05, 1)
shader_parameter/edge_width = 0.07
'''
        (MATERIALS / f"{name}.tres").write_text(text)


# --- rooms -------------------------------------------------------------------------------------------

# door: the building in the town and its doorstep (local); size: inside width x depth; props:
# (prop, x, z) with z = 0 the back wall's foot and growing toward the door; people: (scene, x, z, lines)
INTERIORS = {
    "posada": dict(
        title="Posada del Cruce", building="Posada", floor="floor_planks", size=(16.0, 11.0), ambient=0.85,
        props=[("chimenea", -4.0, 0.45), ("alfombrilla", -4.0, 2.6), ("barra", 4.6, 1.6), ("estante_botellas", 3.4, 0.4),
               ("estante_botellas", 5.6, 0.4), ("barril_grifo", 7.0, 1.2), ("barril_grifo", 7.0, 2.7),
               ("mesa_redonda", -4.5, 5.6), ("silla", -6.2, 5.4), ("silla", -2.9, 5.4), ("mesa_redonda", 1.0, 5.0),
               ("silla", -0.6, 4.8), ("silla", 2.6, 4.8), ("mesa_larga", 4.5, 7.6), ("candelabro", 1.0, 4.5),
               ("planta", -7.2, 0.6), ("planta", 7.3, 9.6), ("farol_poste", -6.8, 9.3), ("armario", -1.0, 0.45),
               ("fogon", 0.9, 0.45)],
        people=[("lio", -2.6, 6.8, ["¡Eh, tú! Lio, guía de la ruta oriental. Si vas hacia Puentegris, conozco atajos que no salen en ningún mapa.",
                                   "Mi hermana Sella dice que soy un imprudente. Yo digo que llegar tarde también es un riesgo.",
                                   "Desde que se abrió la grieta, el puente oriental cruje de una forma que no me gusta nada."]),
                ("sella", -0.8, 7.2, ["Sella. Llevo las cuentas de Puentegris. Alguien tiene que hacerlo mientras mi hermano busca atajos.",
                                      "Cada caravana que no llega es un mes más difícil para nosotros.",
                                      "Si de verdad vas a ayudar, apúntalo. Las promesas sin apuntar se las lleva el viento."])],
    ),
    "sede_faro": dict(
        title="Sede del Faro", building="SedeDelFaro", floor="floor_flagstone", size=(14.0, 10.0), ambient=0.8,
        props=[("mostrador_registro", 0.0, 2.0), ("tablon_contratos", -3.6, 0.4), ("estante_pergaminos", 3.4, 0.4),
               ("estandarte_gremio", -1.8, 0.6), ("estandarte_gremio", 1.8, 0.6), ("mesa_mapas", 4.6, 5.2),
               ("candelabro", 3.0, 4.6), ("lampara_cristal", -5.8, 0.6), ("lampara_cristal", 5.8, 0.6),
               ("armero", -5.4, 4.0), ("cofre_tesoro", -5.6, 6.8), ("alfombrilla", 0.0, 5.6), ("estanteria", -0.0, 0.4)],
        people=[("iven", -3.4, 2.6, ["¿Tú también vienes por contratos? Llegas tarde: los buenos ya los he cogido yo.",
                                     "Un contrato bueno te da dinero. Uno difícil te da un nombre.",
                                     "No te confundas: no soy tu enemigo. Solo no pienso volver a ser el prescindible de nadie."]),
                ("caldus", 2.6, 3.0, ["Ser Caldus Renn, del Faro. Mientras yo dirija esta sede, nadie sale sin saber a qué se enfrenta.",
                                      "La verdad hay que contarla cuando existan medios para gestionar lo que provoque.",
                                      "Las afueras no son lugar para valientes sin preparación. Habla con Mara antes de salir."])],
    ),
    "tienda_nara": dict(
        title="Tienda de Nara", building="TiendaDeNara", floor="floor_planks", size=(12.0, 9.0), ambient=0.9,
        props=[("vitrina_pociones", 0.0, 2.2), ("estante_pociones", -2.0, 0.4), ("estante_botellas", 2.0, 0.4),
               ("estanteria", 4.4, 0.4), ("cajas_mercancia", -4.6, 1.2), ("sacos_harina", -4.4, 3.4),
               ("barril_grifo", 4.8, 3.2), ("planta", -5.0, 7.2), ("alfombrilla", 0.0, 6.0), ("candelabro", 2.2, 2.0),
               ("armario", -4.4, 0.45)],
    ),
    "taller_elia": dict(
        title="Taller de Elia", building="CasaDeElia", floor="floor_planks", size=(12.0, 9.0), ambient=0.85,
        props=[("banco_trabajo", -2.4, 0.9), ("yunque", 0.4, 2.6), ("armero", -4.6, 0.6), ("maniqui_cota", 1.6, 0.8),
               ("fogon", 3.6, 0.45), ("cama", 4.4, 4.6), ("arcon", 4.4, 6.9), ("estanteria", 0.0, 0.4),
               ("escritorio", -4.2, 4.4), ("planta", -5.0, 7.3), ("alfombrilla", 1.0, 5.6), ("lampara_cristal", -1.2, 4.2)],
    ),
}

WALL_H = 4.2
WALL_T = 0.6
FRONT_H = 0.7
DOOR_W = 2.4


def building_door(name):
    """(origin, doorstep) of a building in the town scene."""
    text = TOWN.read_text()
    m = re.search(rf'\[node name="{name}" type="StaticBody3D" parent="Buildings"[^\]]*\]\ntransform = Transform3D\(([^)]*)\)', text)
    origin = [float(v) for v in m.group(1).split(",")][9:12]
    m = re.search(rf'\[node name="Doorstep" type="StaticBody3D" parent="Buildings/{name}"[^\]]*\]\ntransform = Transform3D\(([^)]*)\)', text)
    step = [float(v) for v in m.group(1).split(",")][9:12]
    return origin, step


def write_room(key, spec):
    w, d = spec["size"]
    sc = Scene()
    shader_floor = sc.res("Material", f"res://materials/interior/{spec['floor']}.tres")
    shader_wall = sc.res("Material", "res://materials/interior/wall_plaster.tres")
    box = sc.res("BoxMesh", "res://materials/blocks/unit_box.tres")
    env = sc.subres("Environment", background_mode=1, background_color="Color(0.02, 0.015, 0.02, 1)",
                    ambient_light_source=2, ambient_light_color=colour("ffe6c8"),
                    ambient_light_energy=spec.get("ambient", 0.85))
    sc.node(spec["title"].replace(" ", ""), "Node3D")
    sc.node("WorldEnvironment", "WorldEnvironment", ".", environment=f'SubResource("{env}")')
    sc.node("Sun", "DirectionalLight3D", ".", transform="Transform3D(0.8433914, 0.40550515, -0.35250026, 0, 0.656059, "
            "0.75470954, 0.53729963, -0.63651556, 0.55331457, 0, 0, 0)", light_energy=0.05, shadow_enabled="true")
    # the room: a floor and walls built from blocks, open toward the camera but for a low front wall
    sc.node("Buildings", "Node3D", ".")
    blocks = [("Floor", shader_floor, (0, -1.0, (d + WALL_T) / 2), (w + 2 * WALL_T, 1.0, d + WALL_T)),
              ("Threshold", shader_floor, (0, -1.0, d + WALL_T + 1.0), (DOOR_W, 1.0, 2.0))]
    blocks.append(("BackWall", shader_wall, (0, 0, -WALL_T / 2), (w + 2 * WALL_T, WALL_H, WALL_T)))
    for side, sx in (("WestWall", -1), ("EastWall", 1)):
        blocks.append((side, shader_wall, (sx * (w / 2 + WALL_T / 2), 0, d / 2), (WALL_T, WALL_H, d + WALL_T)))
    seg = (w - DOOR_W) / 2 + WALL_T
    for side, sx in (("FrontWest", -1), ("FrontEast", 1)):
        blocks.append((side, shader_wall, (sx * (DOOR_W / 2 + seg / 2), 0, d + WALL_T / 2), (seg, FRONT_H, WALL_T)))
    for name, mat, (x, y, z), (bw, bh, bd) in blocks:
        shape = sc.subres("BoxShape3D", size=f"Vector3({bw}, {bh}, {bd})")
        sc.node(name, "StaticBody3D", "Buildings", transform=xform(x, y, z))
        sc.node("Mesh", "MeshInstance3D", f"Buildings/{name}", transform=xform(0, bh / 2, 0, bw, bh, bd),
                material_override=f'ExtResource("{mat}")', mesh=f'ExtResource("{box}")')
        sc.node("Collision", "CollisionShape3D", f"Buildings/{name}", transform=xform(0, bh / 2, 0),
                shape=f'SubResource("{shape}")')
    # furniture
    sc.node("Props", "Node3D", ".")
    counts = {}
    for prop, x, z in spec["props"]:
        rid = sc.res("PackedScene", f"res://scenes/environment/props/interior/{prop}.tscn")
        counts[prop] = counts.get(prop, 0) + 1
        sc.node(f"{prop}{counts[prop]}", None, "Props", instance=rid, transform=xform(x, 0, z))
    sc.node("People", "Node3D", ".")
    for who, x, z, lines in spec.get("people", []):
        rid = sc.res("PackedScene", f"res://scenes/characters/townsfolk/{who}.tscn")
        folk = sc.res("Script", "res://scripts/characters/townsfolk.gd")
        said = ", ".join('"' + line.replace('"', '\\"') + '"' for line in lines)
        sc.node(who.capitalize(), "CharacterBody3D", "People", instance=rid, transform=xform(x, 0.1, z),
                script=f'ExtResource("{folk}")', lines=f"PackedStringArray({said})")
    # the way out: back to the town, in front of the building's door
    origin, step = building_door(spec["building"])
    out = (origin[0] + step[0], origin[1] + 0.6, origin[2] + step[2] + 1.8)
    exit_script = sc.res("Script", "res://scripts/systems/exit.gd")
    exit_shape = sc.subres("BoxShape3D", size=f"Vector3({DOOR_W}, 3, 1.2)")
    sc.node("Exit", "Area3D", ".", transform=xform(0, 0, d + WALL_T + 1.2), collision_layer=0, collision_mask=2,
            script=f'ExtResource("{exit_script}")', target_scene='"res://scenes/levels/brumaclara.tscn"',
            arrival=f"Vector3({out[0]:.2f}, {out[1]:.2f}, {out[2]:.2f})")
    sc.node("Collision", "CollisionShape3D", "Exit", transform=xform(y=1.5), shape=f'SubResource("{exit_shape}")')
    rug = sc.res("PackedScene", "res://scenes/environment/props/interior/alfombrilla.tscn")
    sc.node("Doormat", None, "Props", instance=rug, transform=xform(0, 0, d - 0.7))
    # the hero and the screen
    player = sc.res("PackedScene", "res://scenes/characters/player.tscn")
    player_script = sc.res("Script", "res://scripts/characters/player.gd")
    dust = sc.res("PackedScene", "res://scenes/effects/dust.tscn")
    text = sc.res("PackedScene", "res://scenes/effects/floating_text.tscn")
    sc.node("Player", "CharacterBody3D", ".", instance=player, transform=xform(0, 0.1, d - 1.6), collision_layer=2,
            collision_mask=5, floor_max_angle=0.87266463, floor_snap_length=0.4,
            script=f'ExtResource("{player_script}")', dust_scene=f'ExtResource("{dust}")',
            text_scene=f'ExtResource("{text}")')
    # the room fits on the screen: the camera stays put, framing all of it (the hero's camera offset,
    # from a point near the door)
    sc.node("Camera", None, "Player", top_level="true", transform=xform(0, 24.764, d - 1.4 + 40.434))
    hud = sc.res("PackedScene", "res://scenes/ui/hud.tscn")
    hud_script = sc.res("Script", "res://scripts/ui/hud.gd")
    sc.node("HUD", "CanvasLayer", ".", instance=hud, groups=["hud"], script=f'ExtResource("{hud_script}")',
            player_path='NodePath("../Player")')
    edits = sc.res("Script", "res://scripts/systems/level_edits.gd")
    sc.node("LevelEdits", "Node", ".", script=f'ExtResource("{edits}")')
    ROOMS.mkdir(parents=True, exist_ok=True)
    (ROOMS / f"{key}.tscn").write_text(sc.text())
    return origin, step, d


def write_doors(rooms):
    """A door on each building with an interior; rewritten in place on every run."""
    text = TOWN.read_text()
    text = re.sub(r'\n\[node name="Puerta" type="Area3D" parent="Buildings/[^"]*"[^\n]*\n(?:[^\[][^\n]*\n|\n)*?'
                  r'\[node name="Collision" type="CollisionShape3D" parent="Buildings/[^"]*/Puerta"[^\n]*\n(?:[^\[\n][^\n]*\n)*',
                  "\n", text)
    text = re.sub(r'\[sub_resource type="BoxShape3D" id="BoxShape3D_puerta"\]\nsize = [^\n]*\n\n', "", text)
    text = re.sub(r'\[ext_resource type="Script" path="res://scripts/systems/exit.gd" id="900_exit"\]\n', "", text)
    exit_id = re.search(r'\[ext_resource type="Script" path="res://scripts/systems/exit.gd" id="([^"]*)"\]', text)
    exit_id = exit_id.group(1) if exit_id else None
    if exit_id is None:
        exit_id = "900_exit"
        text = text.replace("\n[sub_resource", f'\n[ext_resource type="Script" path="res://scripts/systems/exit.gd" id="{exit_id}"]\n\n[sub_resource', 1)
    text = text.replace("\n[sub_resource", '\n[sub_resource type="BoxShape3D" id="BoxShape3D_puerta"]\nsize = Vector3(1.4, 2.2, 1.4)\n\n[sub_resource', 1)
    doors = ""
    for key, (origin, step, d) in rooms.items():
        building = INTERIORS[key]["building"]
        doors += (f'\n[node name="Puerta" type="Area3D" parent="Buildings/{building}"]\n'
                  f"transform = {xform(step[0], 0.0, step[2] + 0.3)}\ncollision_layer = 0\ncollision_mask = 2\n"
                  f'script = ExtResource("{exit_id}")\ntarget_scene = "res://scenes/levels/interiors/{key}.tscn"\n'
                  f"arrival = Vector3(0, 0.1, {d - 1.6})\n"
                  f'\n[node name="Collision" type="CollisionShape3D" parent="Buildings/{building}/Puerta"]\n'
                  f"transform = {xform(y=1.1)}\n" + 'shape = SubResource("BoxShape3D_puerta")\n')
    anchor = '\n[node name="Exit" type="Area3D" parent="."'
    text = text.replace(anchor, doors + anchor, 1)
    TOWN.write_text(text)


if __name__ == "__main__":
    write_props()
    write_materials()
    rooms = {key: write_room(key, spec) for key, spec in INTERIORS.items()}
    write_doors(rooms)
    print("interiors:", ", ".join(rooms))
