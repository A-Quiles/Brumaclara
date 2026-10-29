"""The art still to generate with Canva, in order: tools/data/art_queue.json.

    python3 tools/data/art_queue.py          # (re)writes the queue, keeping what is already done

Each entry: name (the file art/ai/<name>.png), kind (monster, character, icons), aspect (Canva's ratio),
prompt, and for monsters `lift` (flying creatures float this many pixels above their shadow). An entry
is done when its image is in art/ai. How to integrate each kind is in docs/produccion_de_arte.md.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUEUE = ROOT / "tools" / "data" / "art_queue.json"
RIFT = ("corrupted by a dimensional rift: glowing violet eyes, small violet crystals growing from its body and faint glowing "
        "violet cracks")


def monster(name, desc, bg="magenta", move="walk", attack="wind-up as warning, lunge, lunge with open mouth, recover",
            death="dissolve", lift=0):
    back = "bright green" if bg == "green" else bg
    prompt = (f'Pixel art sprite sheet, 4 columns x 4 rows grid on flat solid {back} background, a single fantasy monster '
              f'"{desc}", all frames facing right, three-quarter top-down view, black outlines, limited palette. Row 1 idle '
              f"(4 frames), row 2 {move} (4 frames), row 3 attack ({attack}), row 4 hurt/collapse/{death}. Same size in every "
              "cell, centered, no text, no ground shadow.")
    return dict(name=name, kind="monster", aspect="SQUARE_1_1", prompt=prompt, lift=lift)


def character(name, desc, bg="magenta"):
    back = "bright green" if bg == "green" else bg
    prompt = (f"Pixel art character sprite sheet, 4 columns x 3 rows grid on flat solid {back} background, one anime-style "
              f"fantasy RPG character {desc}, no cape. Chibi proportions with a big head, full body, black outlines, limited "
              "palette. Row 1 walking toward the viewer (4 frames), row 2 walking to the right in side view (4 frames), row 3 "
              "walking away from the viewer showing the back (4 frames). Same size in every cell, centered, no text, no ground "
              "shadow.")
    return dict(name=name, kind="character", aspect="LANDSCAPE_4_3", prompt=prompt)


QUEUE_ITEMS = [
    character("sella", '"Sella", a prudent young woman who keeps the accounts of a small mountain community, chestnut brown '
              "hair in a neat bun with a pencil in it, calm green eyes, a sage green dress with a cream apron, a small ledger "
              "book in her hands, brown shoes"),
    dict(name="icons_tronco", kind="icons", aspect="SQUARE_1_1", prompt=(
        "Pixel art RPG skill icon sheet, 6 columns x 6 rows grid of 36 separate square icons on a flat solid black background, "
        "every icon is a dark navy square tile with a thin gold border and one bold symbol inside, adventurer techniques "
        "theme, steel silver, leather brown and warm gold, crisp pixels, no text. Icons in order: glowing sharpened sword "
        "blade, sword thrust lunge, sword hitting a stunned foe, three slash marks combo, heavy two-handed sword strike, "
        "spinning sword whirlwind, finishing blow on a skull, crossed swords with laurel, running boots with wind, light "
        "feather, dodging silhouette, two afterimages of a dodge, watchful eye with exclamation, roll arrow with sword, "
        "hourglass, ghostly figure, leather armor, two red potions, deep breath wind, green cross heart, cracked heart with a "
        "flame, antidote vial with a leaf, heart with a shield, unbreakable shield, magnifying glass over footprints, belt "
        "pouches, coins and a gem, handshake with a coin, map with compass, mortar and pestle, circling clock arrows, golden "
        "star badge, guild badge, backpack, campfire, crown")),
    # zone 1
    monster("roedor_bruma", f"mist rat (roedor de bruma), a plump grey-violet rat with misty fur and a long pink tail, {RIFT}",
            bg="green", move="scurry", attack="crouch and squeak as warning, leap, bite, recover"),
    monster("jabali_espinoso", f"spined boar (jabalí espinoso), a dark brown wild boar with bone-white quills along its back and "
            f"big tusks, {RIFT}", bg="green", move="run", attack="paw the ground as warning, charge, charge with tusks forward, skid"),
    monster("cuervo_bruma", f"mist crow (cuervo de bruma), a large black crow with misty trailing feathers, {RIFT}", bg="green",
            move="flying", attack="hover screeching as warning, dive, dive with open beak, rise", lift=12),
    monster("saqueador", "road bandit (saqueador de caminos), a hooded human bandit in patched brown leather with a short sword "
            "and throwing knives, a scarf over the face", move="walk", attack="pull the arm back as warning, throw a knife, "
            "knife flying, recover", death="kneel and surrender"),
    # zone 2
    monster("arana_musgo", f"moss spider (araña de musgo), a big forest spider with a dark green-brown body covered in moss and "
            f"tiny ferns, eight long legs, {RIFT}", attack="rear up showing fangs as warning, leap, bite, recover",
            death="flip on its back and dissolve"),
    monster("ciervo_cristal", "crystal-horned stag (ciervo de cuerno cristal), an elegant tawny forest deer whose antlers are "
            "large glowing violet crystals, white chest, small violet crystal growths on its shoulders", bg="green", move="run",
            attack="lower the head as warning, charge, charge with crystals glowing, skid stop leaving crystal shards"),
    monster("enredadera", f"whispering vine (enredadera susurrante), a stationary carnivorous vine plant with coiling thorny "
            f"tendrils and a pale bulb with a whispering mouth, {RIFT}", move="swaying", attack="leaves tremble as warning, "
            "tendrils lash out, tendrils grab, recover", death="wither and dissolve"),
    # zone 3
    monster("rana_cornuda", f"horned frog (rana cornuda), a big ochre-brown swamp frog with two curved horns and a pale yellow "
            f"throat sac, {RIFT}",
            bg="green", move="hop", attack="inflate the throat as warning, tongue lashes out, long tongue hit, retract"),
    monster("garza_alterada", f"altered heron (garza alterada), a tall grey heron with a long spear beak, {RIFT}", bg="green",
            move="wade walk", attack="stretch the neck as warning, fast peck, long peck, recover"),
    monster("sanguijuela_cristal", "crystal leech (sanguijuela de cristal), a fat dark leech with violet crystal plates along its "
            "back and a round sucker mouth", bg="green", move="crawl", attack="glow under the skin as warning, lunge, latch "
            "on, recover"),
    monster("tortuga_lodo", f"mud turtle (tortuga de lodo), a heavy grey-brown turtle with a brown mud-caked shell and dried "
            f"reeds, {RIFT}", bg="green",
            move="walk", attack="pull the head in as warning, ram, ram with dust, recover"),
    monster("fuego_fatuo", "will-o-wisp (fuego fatuo), a floating ball of pale violet ghost flame with a small sad face and "
            "trailing sparks", bg="green", move="drifting", attack="blink faster and faster as warning, swell, explode, smoke",
            death="fade into sparks", lift=10),
    monster("caiman_barrera", f"barrier caiman (caimán de la barrera), a long dark green caiman with ridged armored back, {RIFT}",
            move="crawl", attack="bubbles and lowered head as warning, lunge, bite, recover"),
    # zone 4
    monster("jabali_cantera", f"quarry boar (jabalí de cantera), a huge boar with stone plates grown on its back, {RIFT}",
            bg="green", move="run", attack="dust circle as warning, rear up, slam the ground, dust shockwave"),
    monster("golem_escombro", "rubble golem (gólem de escombro), a hulking automaton made of quarry rubble and old iron bands "
            "with a dim teal rune in its chest", bg="green", move="heavy walk", attack="crouch as warning, raise both arms, "
            "slam, rocks fly", death="crumble into rubble"),
    monster("minero_perdido", f"lost miner (minero perdido), a hunched human miner with a dented helmet lamp and a pickaxe, "
            f"glowing violet eyes and violet crystals on his shoulders", move="walk", attack="raise the pickaxe twice as "
            "warning, swing, strike, recover", death="collapse"),
    monster("murcielago_hollin", "soot bat (murciélago de hollín), a small sooty black bat with ember-orange eyes and smoky wings",
            bg="green", move="flying", attack="flutter as warning, dive, bite, rise", lift=10),
    monster("escarabajo_perforador", f"drill beetle (escarabajo perforador), a bronze armored beetle with a drill-shaped horn, "
            f"{RIFT}", bg="green", move="walk", attack="dig in as warning, burst out of the ground, drill strike, recover"),
    monster("pico_errante", "wandering pickaxe (pico errante), a possessed floating pickaxe wrapped in violet energy, spinning",
            bg="green", move="spinning flight", attack="hum and vibrate as warning, spin attack, spin hit, recover",
            death="fall and break", lift=8),
    # bosses
    monster("arbol_susurra", f"the Whispering Tree (el Árbol que susurra), an ancient leafless gnarled tree with grey-brown "
            f"bark and a face in its bark, "
            f"glowing violet runes and crystals, roots spread on the ground", bg="green", move="swaying",
            attack="roots rise as warning, roots sweep, spores burst, recover", death="wither and fall apart"),
    monster("caparazon_vigilia", "the Vigil Shell (caparazón de Vigilia), a colossal dark slate grey turtle whose shell is "
            "covered in tall pale "
            "blue barrier crystals", bg="green", move="heavy walk", attack="crystals glow as warning, rear up, slam, crystal "
            "shockwave", death="sink and stop"),
    monster("taladro_trama", "the Weave Drill (taladro de la Trama), a giant ancient mining automaton with a huge drill arm, "
            "teal glowing vents and rusted plates", bg="green", move="heavy walk", attack="vents open as warning, drill "
            "thrust, drill spinning, overheat", death="break down smoking"),
]


def main():
    done = {}
    if QUEUE.exists():
        done = {e["name"]: e.get("done", False) for e in json.loads(QUEUE.read_text())}
    items = []
    for e in QUEUE_ITEMS:
        e = dict(e)
        e["done"] = (ROOT / "art" / "ai" / f"{e['name']}.png").exists() or done.get(e["name"], False)
        items.append(e)
    QUEUE.write_text(json.dumps(items, ensure_ascii=False, indent="\t") + "\n")
    print(f"{sum(not e['done'] for e in items)} of {len(items)} still to generate")


if __name__ == "__main__":
    main()
