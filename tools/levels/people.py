"""Places the people of the story in the town (scenes/levels/brumaclara.tscn, under People).

    python3 tools/levels/people.py

Each person needs its sheet (tools/art_pipeline/build.py characters) and its scene
(scenes/characters/townsfolk/<who>.tscn, written here from the sheet if missing). Re-running replaces
the people listed below and leaves everyone else as it is. The interiors' people are in
tools/levels/interiors.py.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOWN = ROOT / "scenes" / "levels" / "brumaclara.tscn"
FOLK = ROOT / "scenes" / "characters" / "townsfolk"
SHEETS = ROOT / "assets" / "characters" / "townsfolk"

PEOPLE = {  # who -> (position, wander, lines[, extra]); extra: route, pause, shop, name (shown), node (node name)
    "neris": ((21.6, 3.6, -45.2), 0.0, [
        "Neris Vale, del Archivo. Estudio lo que dejan atrás las Fracturas.",
        "No podemos protegernos de algo que nos negamos a estudiar.",
        "Si ves cristales violeta en las afueras, no los toques con las manos desnudas. Tráeme lo que puedas contarme de ellos."]),
    "tovan": ((32.4, 2.4, -31.4), 1.5, [
        "Tovan Sere, de la Liga. Si una caravana no llega, alguien pasa hambre: de eso me ocupo.",
        "Un mapa no muestra quién merece ayuda. Solo muestra cuánto tardas en llegar.",
        "El camino del oeste está cerrado desde lo de la grieta. Si lo despejas, la Liga sabrá agradecerlo."]),
    "rhea": ((-12.6, 2.4, -32.0), 0.0, [
        "Rhea Kest. Sí, la de la Brasa. No, no voy a firmarte nada.",
        "El Faro llama imprudente a cualquiera que no espere permiso.",
        "¿Quieres aprender a pelear de verdad? Sal ahí fuera y vuelve con todos los dedos."]),
    "iven": ((-3.0, 2.4, -31.5), 1.2, [
        "Iven Rusk. Si vas a quedarte en Brumaclara, no me estorbes en el tablón.",
        "Un contrato bueno te da dinero. Uno difícil te da un nombre."], {"name": "Iven Rusk"}),
    "caldus": ((5.0, 2.4, -31.0), 0.0, [
        "El Faro protege los caminos. Alguien tiene que hacerlo con orden.",
        "La verdad debe revelarse cuando existan medios para gestionar sus consecuencias."], {"name": "Caldus Renn"}),
    "lio": ((26.6, 0.0, -5.6), 0.0, [
        "¡Lio, guía y comerciante de la ruta oriental! Pociones frescas de Puentegris.",
        "Mi hermana Sella lleva las cuentas en el carromato. Yo llevo la sonrisa."],
        {"name": "Lio", "shop": {"pocion": 15, "tonico": 20}}),
    "sella": ((16.2, 0.0, 6.6), 0.0, [
        "Sella. Si compras, paga lo justo; si regateas, que sea con argumentos.",
        "Puentegris no sale en los mapas nuevos. Aun así, seguimos aquí."],
        {"name": "Sella", "shop": {"pocion": 14, "tonico": 18, "cristal": 30}}),
    "guard": ((1.5, 0.0, 28.0), 0.0, [
        "Patrulla de la tarde. Todo en calma... de momento.",
        "Por la noche encendemos los faroles. Las criaturas evitan la luz, dicen."],
        {"name": "Guardia", "node": "GuardPatrol", "pause": 3.0,
         "route": [(1.5, 0, 28), (1.5, 0, 14), (2, 0, 6), (14.5, 0, 0), (30, 0, -1), (14.5, 0, 0), (2, 0, 6), (1.5, 0, 14)]}),
    "guard#2": ((-3.0, 0.0, 4.0), 0.0, [
        "El barrio del Camino es tranquilo. Lo raro viene de fuera.",
        "Si ves al carretero, dile que ya le hemos levantado la carreta."],
        {"name": "Guardia", "node": "GuardWest", "pause": 4.0,
         "route": [(-3, 0, 4), (-14.5, 0, 3.5), (-30, 0, 3.5), (-14.5, 0, 3.5)]}),
    "elia": ((-7.0, 0.0, 0.0), 0.0, [
        "Me llamo Elia. Reparo herramientas y catalizadores... y curo lo que puedo con hierbas.",
        "Desde que apareció esa grieta violeta, los animales del bosque ya no se comportan igual."],
        {"name": "Elia", "node": "Elia", "pause": 5.0,
         "route": [(-6, 0, 0), (-4, 0, 6), (6, 0, 6), (8.3, 0, -0.5)]}),
}


def ensure_scene(who):
    scene = FOLK / f"{who}.tscn"
    if scene.exists() or not (SHEETS / f"{who}_frames.tres").exists():
        return scene.exists()
    text = (FOLK / "mara.tscn").read_text()
    text = text.replace("mara_frames.tres", f"{who}_frames.tres").replace('node name="Mara"', f'node name="{who.capitalize()}"')
    scene.write_text(text)
    return True


def main():
    text = TOWN.read_text()
    script = re.search(r'node name="Mara"[^\n]*\n[^\n]*\nscript = ExtResource\("([^"]+)"\)', text).group(1)
    placed = []
    for key, (pos, wander, lines, *more) in PEOPLE.items():
        extra = more[0] if more else {}
        who = key.split("#")[0]
        if not ensure_scene(who):
            continue
        name = extra.get("node", who.capitalize())
        # drop an earlier copy of this person (node + its ext_resource) before writing it again
        text = re.sub(rf'\n\[node name="{name}" type="CharacterBody3D" parent="People"[^\n]*\n(?:[^\[\n][^\n]*\n)*', "\n", text)
        known = re.search(rf'\[ext_resource type="PackedScene" path="res://scenes/characters/townsfolk/{who}.tscn" id="([^"]+)"\]', text)
        rid = known.group(1) if known else f"901_{who}"
        if not known:
            text = text.replace("\n[sub_resource", f'\n[ext_resource type="PackedScene" path="res://scenes/characters/townsfolk/{who}.tscn" id="{rid}"]\n[sub_resource', 1)
        said = ", ".join('"' + line.replace('"', '\\"') + '"' for line in lines)
        node = (f'\n[node name="{name}" type="CharacterBody3D" parent="People" instance=ExtResource("{rid}")]\n'
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})\n"
                f'script = ExtResource("{script}")\nlines = PackedStringArray({said})\n'
                + (f"wander = {wander}\n" if wander else "")
                + ("route = PackedVector3Array(" + ", ".join(f"{x}, {y}, {z}" for x, y, z in extra["route"]) + ")\n" if "route" in extra else "")
                + (f"pause = {extra['pause']}\n" if "pause" in extra else "")
                + ("shop = {" + ", ".join(f'"{k}": {v}' for k, v in extra["shop"].items()) + "}\n" if "shop" in extra else "")
                + (f'metadata/display_name = "{extra["name"]}"\n' if "name" in extra else ""))
        text = text.replace('\n[node name="Edge" type="StaticBody3D" parent="."', node + '\n[node name="Edge" type="StaticBody3D" parent="."', 1)
        placed.append(who)
    text = re.sub(r"\n\n\n+", "\n\n", text)
    TOWN.write_text(text)
    print("people in town:", ", ".join(placed))


if __name__ == "__main__":
    main()
