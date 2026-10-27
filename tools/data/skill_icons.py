"""Which icon each skill of the trees uses: data/ui/skill_icons.json.

The icon sheets (assets/ui/skills/<affinity>.png, 5 x 5 icons) come from art/ai/icons_<affinity>.png,
drawn in the order of ORDER below (the image prompt lists them in that order). Upgrades show their
skill's icon with a mark; passives the affinity's emblem.

    python3 tools/data/skill_icons.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

ORDER = {
    "fuego": ["chispa", "lanza_de_fuego", "cometa", "estallido", "rastro_ardiente", "muro_de_llamas", "columna_ignea",
              "ascua_viva", "sobrecalentamiento", "abanico_de_brasas", "bola_saltarina", "rafaga_ignea", "cadena_de_fuego",
              "latigo_igneo", "brasero", "erupcion", "lluvia_de_meteoros", "carga_ignea", "escudo_de_brasas",
              "ritmo_de_la_forja", "pira_purificadora", "ruptura_ignea", "@mejora", "@pasiva2", "@pasiva"],
    "hielo": ["aguja_de_escarcha", "lanza_glacial", "rafaga_helada", "tormenta_de_agujas", "suelo_helado",
              "barrera_cristalina", "muro_de_hielo", "glaciar", "prision_breve", "hibernacion", "fractura_glacial",
              "copo_errante", "abanico_de_escarcha", "cadena_de_escarcha", "pilar_de_hielo", "espejo_helado", "ventisca",
              "patinar", "aliento_glacial", "coraza_de_escarcha", "corazon_helado", "@mejora", "@pasiva2", "@pasiva",
              "era_glacial"],
    "rayo": ["descarga", "salto_voltaico", "arco_persistente", "convergencia", "paso_relampago", "sobrecarga",
             "rayo_en_botella", "campo_estatico", "pararrayos", "trueno", "tormenta", "tridente", "bola_de_plasma",
             "lanza_de_trueno", "impulso", "destello_galvanico", "relevo", "chispazo", "escudo_estatico", "jaula_electrica",
             "cielo_cargado", "iman_voltaico", "juicio_del_cielo", "@mejora", "@pasiva"],
    "sombra": ["dardo_umbrio", "desgarro", "lazo_umbrio", "eclipse", "velo", "doble_sombra", "paso_del_vacio", "drenaje",
               "eco_oscuro", "fragilidad", "pacto_de_sombra", "guadana", "enjambre_umbrio", "lluvia_de_cuervos",
               "paso_fantasma", "espejismo", "manto_de_niebla", "maldicion", "marchitar", "sifon", "pozo_del_vacio",
               "noche_cerrada", "@mejora", "@pasiva2", "@pasiva"],
    "tierra": ["canto_rodado", "puas_de_piedra", "lluvia_de_grava", "meteoro_de_piedra", "piel_de_piedra", "muro_de_tierra",
               "escudo_de_rocas", "fortaleza", "pisoton", "grieta", "arenas_movedizas", "terremoto", "honda", "estalagmitas",
               "pedrada_explosiva", "embestida_rocosa", "coraza_de_cuarzo", "menhir", "sacudida", "fauces_de_tierra",
               "corrimiento", "despertar_de_la_montana", "@mejora", "@pasiva2", "@pasiva"],
    "luz": ["destello", "lanza_solar", "prisma", "nova", "escudo_de_luz", "sello_protector", "guardian_de_luz", "santuario",
            "respiro", "purgar", "bendicion", "rayos_gemelos", "juicio", "lluvia_de_estrellas", "destello_cegador",
            "paso_de_luz", "muro_de_luz", "luz_curativa", "aura_radiante", "himno", "haz_purificador", "sol_de_mediodia",
            "@mejora", "@pasiva2", "@pasiva"],
    # the adventurer's trunk: one icon per node, 6 x 6
    "tronco": ["filo_templado", "estocada", "castigo", "combo_largo", "golpe_pesado", "torbellino", "remate",
               "maestro_de_armas", "impulso", "paso_ligero", "esquiva_limpia", "doble_esquiva", "lectura",
               "rodar_y_golpear", "tiempo_justo", "fantasma", "piel_curtida", "pociones_dobles", "segundo_aliento",
               "recuperacion", "ultimo_recurso", "antidotos", "corazon_firme", "inquebrantable", "ojo_de_rastreador",
               "bolsillos", "botin_atento", "regateo", "cartografo", "alquimia_de_campo", "recarga_rapida",
               "leyenda_en_ciernes", "@insignia", "@mochila", "@hoguera", "@pasiva"],
}
COLS = {"tronco": 6}


def main():
    out = {}
    for aff, order in ORDER.items():
        tree = json.loads((ROOT / "data" / "trees" / f"{aff}.json").read_text())
        ids = {n["id"] for n in tree["nodes"]}
        entry = {"sheet": f"res://assets/ui/skills/{aff}.png", "cols": COLS.get(aff, 5), "icons": {}}
        for i, name in enumerate(order):
            if name.startswith("@"):
                entry[name[1:]] = i
                continue
            nid = f"{aff}.{name}"
            assert nid in ids, nid
            entry["icons"][nid] = i
        missing = [n["id"] for n in tree["nodes"] if n["type"] in ("activa", "definitiva") and n["id"] not in entry["icons"]]
        if aff == "tronco":
            missing = [n["id"] for n in tree["nodes"] if n["id"] not in entry["icons"]]
        assert not missing, missing
        out[aff] = entry
    path = ROOT / "data" / "ui" / "skill_icons.json"
    path.write_text(json.dumps(out, ensure_ascii=False, indent="\t") + "\n")
    print("icons for", sum(len(e["icons"]) for e in out.values()), "skills")


if __name__ == "__main__":
    main()
