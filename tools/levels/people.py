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

PEOPLE = {  # who -> (position, wander, lines)
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
    for who, (pos, wander, lines) in PEOPLE.items():
        if not ensure_scene(who):
            continue
        name = who.capitalize()
        # drop an earlier copy of this person (node + its ext_resource) before writing it again
        text = re.sub(rf'\n\[node name="{name}" type="CharacterBody3D" parent="People"[^\n]*\n(?:[^\[\n][^\n]*\n)*', "\n", text)
        text = re.sub(rf'\[ext_resource type="PackedScene" path="res://scenes/characters/townsfolk/{who}.tscn" id="[^"]+"\]\n', "", text)
        rid = f"901_{who}"
        text = text.replace("\n[sub_resource", f'\n[ext_resource type="PackedScene" path="res://scenes/characters/townsfolk/{who}.tscn" id="{rid}"]\n[sub_resource', 1)
        said = ", ".join('"' + line.replace('"', '\\"') + '"' for line in lines)
        node = (f'\n[node name="{name}" type="CharacterBody3D" parent="People" instance=ExtResource("{rid}")]\n'
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})\n"
                f'script = ExtResource("{script}")\nlines = PackedStringArray({said})\n'
                + (f"wander = {wander}\n" if wander else ""))
        text = text.replace('\n[node name="Edge" type="StaticBody3D" parent="."', node + '\n[node name="Edge" type="StaticBody3D" parent="."', 1)
        placed.append(who)
    text = re.sub(r"\n\n\n+", "\n\n", text)
    TOWN.write_text(text)
    print("people in town:", ", ".join(placed))


if __name__ == "__main__":
    main()
