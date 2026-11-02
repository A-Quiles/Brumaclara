"""Assets that do not fit the game's art (docs/plan_unificacion_artistica.md), found by the audit
(tools/art_audit/audit.py, review.py) and checked by eye in the validation scene. Copies of the
versions that did not fit go to art/revision/no_encajan/<estado>/, with the reason, in LEEME.md.

    python3 tools/art_audit/no_encajan.py      # copies the current files (only the first time: run it
                                               # BEFORE redoing them) and rewrites LEEME.md
"""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "art" / "revision" / "no_encajan"
FURNITURE = ["mesa_redonda", "silla", "mesa_larga", "barra", "estante_botellas", "chimenea", "cama", "armario",
             "barril_grifo", "fogon", "estanteria", "escritorio", "alfombrilla", "planta", "farol_poste", "arcon",
             "mostrador_registro", "tablon_contratos", "vitrina_pociones", "armero", "maniqui_cota", "yunque",
             "banco_trabajo", "mesa_mapas", "estante_pergaminos", "lampara_cristal", "cajas_mercancia",
             "sacos_harina", "estante_pociones", "estandarte_gremio", "cofre_tesoro", "candelabro"]
MONSTERS = ["cuervo_bruma", "espectro", "espectro_f", "esqueleto", "esqueleto_f", "golem", "golem_f",
            "guardian_raices", "hongo", "hongo_f", "jabali_espinoso", "murcielago", "murcielago_f",
            "polilla_luminica", "roedor_bruma", "sporineo"]
TOWNSFOLK_200 = ["caldus", "iven", "lio", "neris", "rhea", "sella", "tovan"]

# (estado, group, files, problem seen, what was done or is needed)
ENTRIES = [
    ("rehechos", "Paredes y suelos de interior",
     [f"environment/textures/{n}.png" for n in ("wall_plaster", "floor_planks", "floor_flagstone")],
     "Detalle sobredimensionado: las vigas miden 10 px frente a 4-5 px en las fachadas, y el sombreado es "
     "degradado (suavidad 0,77 frente a 0,26-0,39 de las fachadas). Se leen menos pixeladas que el exterior. "
     "Fuente Canva v2 de 1264 px reducida 7,5 veces a baldosas de 168 px.",
     "Rehechas desde la misma fuente a baldosas de 84 px (el detalle a la mitad), tono ajustado y paleta maestra."),
    ("rehechos", "Muebles de interior",
     [f"environment/props/interior/{n}.png" for n in FURNITURE],
     "Escala de 1,4 a 1,9 veces la de su tamaño real junto al héroe (una silla de 41 px frente a un héroe de 44 px; "
     "un barril de 40 px frente a los 25 px del barril de la calle). Madera naranja muy saturada (0,6-0,7) y ruido "
     "de la miniatura de 200 px de la que salen.",
     "Reducidos a su tamaño real (25 px por metro) promediando la fuente, lo que además limpia el ruido, y pasados "
     "por la paleta maestra con la saturación de la madera del exterior."),
    ("rehechos", "Comercios ambulantes",
     [f"environment/props/{n}.png" for n in ("merchant_wagon", "cloth_cart", "potion_stall", "smith_stall", "food_stall", "fortune_tent")],
     "Más oscuros (valor medio 0,18-0,33 frente a 0,31-0,45 de los puestos y objetos de la plaza) y más saturados; "
     "cada uno con 40 colores propios.",
     "Tono ajustado (más luz, algo menos de saturación) y paleta maestra, desde la misma fuente."),
    ("rehechos", "Tejados rojo y naranja",
     [f"environment/buildings/{n}.png" for n in ("roof_red", "roof_orange")],
     "Rojo y naranja planos y muy saturados frente a la pizarra y la teja de madera, con textura y luz.",
     "Saturación y luz contenidas conservando sus propios colores (pasadas por la paleta maestra, el rojo perdía "
     "los brillos y quedaba plano)."),
    ("rehechos", "Adoquín de la segunda pasada",
     ["environment/textures/cobble.png"],
     "Piedras borrosas sin contorno (bordes 0,025) y más oscuras que las fachadas; tamaño de piedra irregular. "
     "Con el césped clásico de vuelta, desentona más que el adoquín anterior.",
     "Vuelve el adoquín anterior (contornos limpios, como las fachadas). El nuevo queda aquí."),
    ("pendientes", "Vecinos dibujados a 200 px",
     [f"characters/townsfolk/{n}.png" for n in TOWNSFOLK_200],
     "Salen de miniaturas de Canva de 200 px usadas píxel a píxel: ruido de píxeles sueltos (0,45-0,58 frente a "
     "0,39 del héroe) y algo más saturados que Mara, Elia o el guardia.",
     "Redibujar a tamaño completo (1024 px o más) con el prompt de art/FUENTES.md y reducir como los demás. "
     "Necesita cupo de generación."),
    ("pendientes", "Monstruos dibujados a 200 px",
     [f"characters/enemies/{n}.png" for n in MONSTERS],
     "Misma causa: miniaturas de 200 px. Ruido y bordes de distinto grosor que el lobo (fuente Figma de 1024 px).",
     "Redibujar a tamaño completo cuando haya cupo; hasta entonces se mantienen."),
    ("rehechos", "Objetos dibujados en diagonal (se veían torcidos)",
     ["environment/props/town_gate.png"] + [f"environment/props/{n}.png" for n in (
         "bench", "crate", "notice_board", "planter", "trough", "low_wall", "flower_cart", "hay_cart", "well",
         "firewood", "fence", "fence_gate", "chalkboard", "barrel_stack", "weapon_rack", "town_arch", "dormer",
         "chimney", "wall_lantern", "hay_bale", "sacks", "chest")],
     "Dibujados en vista isométrica o en tres cuartos girados (la puerta, con la torre izquierda más cercana). La "
     "cámara mira al norte con las verticales rectas, así que junto a las casas, de frente, se veían torcidos.",
     "Redibujados de frente con Figma (art/ai/frente), a su tamaño real y en la paleta maestra; los muebles y los "
     "comercios ambulantes, también. Sprites recentrados con tools/levels/fit_offsets.py."),
]


def main():
    for state, group, files, *_ in ENTRIES:
        for rel in files:
            src = ROOT / "assets" / rel
            if src.exists() and not (DEST / state / rel.split("/", 1)[1]).exists():  # never overwrite the kept original
                dst = DEST / state / rel.split("/", 1)[1]
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
    lines = ["# Sprites que no encajan", "",
             "Recursos que no cumplen `docs/plan_unificacion_artistica.md`, encontrados con la auditoría",
             "(`tools/art_audit/`) y revisados en la escena de validación. Aquí se guardan las versiones que no",
             "encajaban: `rehechos/` son los que ya se rehicieron desde sus fuentes sin generar nada nuevo (para",
             "comparar o deshacer); `pendientes/` siguen en el juego hasta que se puedan redibujar.", ""]
    for state, group, files, problem, action in ENTRIES:
        lines += [f"## {group} ({state})", "", f"**Problema:** {problem}", "", f"**Acción:** {action}", "",
                  "Archivos: " + ", ".join(f"`{Path(f).name}`" for f in files), ""]
    (DEST / "LEEME.md").write_text("\n".join(lines))
    print("set aside ->", DEST)


if __name__ == "__main__":
    main()
