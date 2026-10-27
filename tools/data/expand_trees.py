"""Grows each affinity tree to 21+ distinct active skills, every active with its own upgrade, and
writes the requirements of every node (docs/arbol_habilidades.md).

    python3 tools/data/expand_trees.py

Idempotent: nodes already in a tree are kept as they are (ids decide), the new ones are added, the
requirements are rewritten. Requirements:
- an active of tier II or more needs any active of its branch from a lower tier ("requires_any");
- an upgrade needs its skill ("requires");
- a passive needs any active of its branch up to its tier;
- the ultimate keeps its own rule (tier V and three nodes of tier IV or V, in progress.gd).
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TREES = ROOT / "data" / "trees"
CELL = 4  # nodes that fit in one branch x tier cell of the tree screen


def A(branch, tier, id_, name, desc, skill, cost=2):
    return dict(type="activa", branch=branch, tier=tier, id=id_, name=name, desc=desc, skill=skill, cost=cost)


# --- new active skills ----------------------------------------------------------------------------

NEW = {
    "fuego": [
        A(0, 2, "abanico_de_brasas", "Abanico de brasas", "14 / 3 s / 9 × 5. Cinco brasas en abanico: de cerca aciertan todas",
          {"kind": "PROJECTILE", "mana_cost": 14, "cooldown": 3, "damage": 9, "count": 5, "spread_deg": 14.0, "speed": 13.0, "scale": 0.8}),
        A(0, 3, "bola_saltarina", "Bola saltarina", "18 / 5 s / 20. Rebota entre tres enemigos cercanos",
          {"kind": "PROJECTILE", "mana_cost": 18, "cooldown": 5, "damage": 20, "bounce": 3, "scale": 1.1, "speed": 12.0}),
        A(0, 3, "rafaga_ignea", "Ráfaga ígnea", "20 / 6 s / 14 × 4. Cuatro disparos seguidos hacia donde apuntas",
          {"kind": "PROJECTILE", "mana_cost": 20, "cooldown": 6, "damage": 14, "count": 4, "interval": 0.12, "speed": 16.0}),
        A(0, 4, "cadena_de_fuego", "Cadena de fuego", "26 / 8 s / 22. Salta a cuatro enemigos y los quema",
          {"kind": "CHAIN", "mana_cost": 26, "cooldown": 8, "damage": 22, "count": 4, "radius": 4.0, "offset": 6.0, "status": "quemadura"}),
        A(1, 1, "latigo_igneo", "Látigo ígneo", "12 / 3 s / 16. Latigazo de fuego en línea corta",
          {"kind": "LINE", "mana_cost": 12, "cooldown": 3, "damage": 16, "length": 4.0, "count": 4, "step_delay": 0.03, "once": True}),
        A(1, 2, "brasero", "Brasero", "22 / 12 s / 5 cada 0,5 s. Un círculo de brasas te sigue 4 s y quema",
          {"kind": "ZONE", "mana_cost": 22, "cooldown": 12, "damage": 5, "duration": 4.0, "tick": 0.5, "radius": 1.6, "offset": 0.0,
           "follow": True, "status": "quemadura"}),
        A(1, 3, "erupcion", "Erupción", "30 / 11 s / 40. Tras 0,5 s, el suelo estalla a tu alrededor",
          {"kind": "STRIKE", "mana_cost": 30, "cooldown": 11, "damage": 40, "offset": 0.0, "delay": 0.5, "radius": 2.6, "push": 9.0}),
        A(1, 5, "lluvia_de_meteoros", "Lluvia de meteoros", "42 / 18 s / 30 × 6. Seis meteoros caen sobre un área grande",
          {"kind": "RAIN", "mana_cost": 42, "cooldown": 18, "damage": 30, "count": 6, "duration": 2.4, "radius": 3.2, "offset": 4.0,
           "status": "quemadura"}, cost=3),
        A(2, 1, "carga_ignea", "Carga ígnea", "16 / 6 s / 18. Embestida de 5 unidades que deja un rastro ardiente",
          {"kind": "DASH", "mana_cost": 16, "cooldown": 6, "damage": 18, "length": 5.0, "trail_status": "quemadura"}),
        A(2, 2, "escudo_de_brasas", "Escudo de brasas", "18 / 14 s. Absorbe 25 de daño; quien lo rompe se quema",
          {"kind": "SHIELD", "mana_cost": 18, "cooldown": 14, "damage": 0, "duration": 6.0, "shield": 25, "thorns": 10,
           "break_status": "quemadura"}),
        A(2, 4, "ritmo_de_la_forja", "Ritmo de la forja", "24 / 16 s. +15 % de daño y de velocidad durante 6 s",
          {"kind": "BUFF", "mana_cost": 24, "cooldown": 16, "damage": 0, "duration": 6.0, "mods": {"damage_pct": 0.15, "move_pct": 0.15}}),
        A(2, 4, "pira_purificadora", "Pira purificadora", "30 / 25 s. Te envuelves en llamas 0,8 s y recuperas el 20 % de vida",
          {"kind": "HEAL", "mana_cost": 30, "cooldown": 25, "damage": 0, "heal_pct": 0.2, "cast_seconds": 0.8, "release_at": 0.75,
           "interruptible": True}),
    ],
    "hielo": [
        A(0, 1, "copo_errante", "Copo errante", "12 / 2,5 s / 16. Copo lento que estalla en área y enfría",
          {"kind": "PROJECTILE", "mana_cost": 12, "cooldown": 2.5, "damage": 16, "speed": 7.0, "explode_radius": 1.6, "status": "frio",
           "scale": 1.2}),
        A(0, 2, "abanico_de_escarcha", "Abanico de escarcha", "14 / 3 s / 12 × 3. Tres agujas abiertas que enfrían",
          {"kind": "PROJECTILE", "mana_cost": 14, "cooldown": 3, "damage": 12, "count": 3, "spread_deg": 20.0, "status": "frio",
           "speed": 16.0}),
        A(0, 3, "cadena_de_escarcha", "Cadena de escarcha", "20 / 6 s / 18. Salta a tres enemigos y los enfría",
          {"kind": "CHAIN", "mana_cost": 20, "cooldown": 6, "damage": 18, "count": 3, "radius": 4.0, "offset": 6.0, "status": "frio"}),
        A(1, 2, "pilar_de_hielo", "Pilar de hielo", "18 / 7 s / 34. Un pilar brota delante tras 0,4 s y enfría dos veces",
          {"kind": "STRIKE", "mana_cost": 18, "cooldown": 7, "damage": 34, "offset": 3.5, "delay": 0.4, "radius": 1.4, "status": "frio",
           "stacks": 2}),
        A(1, 3, "espejo_helado", "Espejo helado", "22 / 12 s. Dos cristales que bloquean el paso y estallan (25) al romperse",
          {"kind": "WALL", "mana_cost": 22, "cooldown": 12, "damage": 0, "length": 2.0, "duration": 6.0, "hits": 2, "prop": "crystal",
           "offset": 2.0, "shatter_damage": 25}),
        A(1, 5, "ventisca", "Ventisca", "40 / 18 s / 12 × 10. Una ventisca de 4 s golpea y enfría el área",
          {"kind": "RAIN", "mana_cost": 40, "cooldown": 18, "damage": 12, "count": 10, "duration": 4.0, "radius": 3.5, "offset": 3.5,
           "status": "frio"}, cost=3),
        A(2, 1, "patinar", "Patinar", "10 / 4 s / 8. Te deslizas 5 unidades y dejas hielo que enfría",
          {"kind": "DASH", "mana_cost": 10, "cooldown": 4, "damage": 8, "length": 5.0, "trail_status": "frio"}),
        A(2, 1, "aliento_glacial", "Aliento glacial", "16 / 6 s / 6 cada 0,25 s. Aliento helado continuo de 1,5 s",
          {"kind": "BEAM", "mana_cost": 16, "cooldown": 6, "damage": 6, "duration": 1.5, "tick": 0.25, "length": 4.0, "status": "frio"}),
        A(2, 2, "coraza_de_escarcha", "Coraza de escarcha", "20 / 14 s. Absorbe 35 de daño; quien la rompe queda helado",
          {"kind": "SHIELD", "mana_cost": 20, "cooldown": 14, "damage": 0, "duration": 6.0, "shield": 35, "thorns": 8,
           "break_status": "frio"}),
        A(2, 5, "corazon_helado", "Corazón helado", "30 / 20 s. +30 % de daño de hielo y −15 % de daño recibido durante 8 s",
          {"kind": "BUFF", "mana_cost": 30, "cooldown": 20, "damage": 0, "duration": 8.0,
           "mods": {"aff_pct.hielo": 0.3, "received_pct": -0.15}}, cost=3),
    ],
    "rayo": [
        A(0, 1, "tridente", "Tridente", "10 / 1,5 s / 8 × 3. Tres descargas rápidas en abanico cerrado",
          {"kind": "PROJECTILE", "mana_cost": 10, "cooldown": 1.5, "damage": 8, "count": 3, "spread_deg": 10.0, "speed": 24.0,
           "status": "marca_electrica", "scale": 0.8}),
        A(0, 2, "bola_de_plasma", "Bola de plasma", "16 / 5 s / 14. Esfera lenta que atraviesa y marca todo lo que toca",
          {"kind": "PROJECTILE", "mana_cost": 16, "cooldown": 5, "damage": 14, "speed": 6.0, "pierce": True, "scale": 1.5,
           "status": "marca_electrica"}),
        A(0, 3, "lanza_de_trueno", "Lanza de trueno", "24 / 7 s / 30. Rayo en línea de 7 unidades tras 0,2 s",
          {"kind": "LINE", "mana_cost": 24, "cooldown": 7, "damage": 30, "length": 7.0, "count": 7, "step_delay": 0.0, "once": True,
           "delay": 0.2, "status": "marca_electrica"}),
        A(0, 4, "iman_voltaico", "Imán voltaico", "16 / 8 s. Atrae al enemigo más cercano y lo deja aturdido 0,4 s",
          {"kind": "PULL", "mana_cost": 16, "cooldown": 8, "damage": 0, "offset": 6.0}),
        A(1, 1, "impulso", "Impulso", "8 / 8 s. +40 % de velocidad durante 2,5 s",
          {"kind": "BUFF", "mana_cost": 8, "cooldown": 8, "damage": 0, "duration": 2.5, "mods": {"move_pct": 0.4}}),
        A(1, 2, "destello_galvanico", "Destello galvánico", "16 / 6 s. Apareces detrás del enemigo marcado más cercano",
          {"kind": "BLINK", "mana_cost": 16, "cooldown": 6, "damage": 0, "offset": 8.0, "on_marked": "marca_electrica"}),
        A(1, 3, "relevo", "Relevo", "12 / 6 s / 10. Tres pasos cortos que se encadenan",
          {"kind": "DASH", "mana_cost": 12, "cooldown": 6, "damage": 10, "length": 3.0, "charges": 3}),
        A(2, 1, "chispazo", "Chispazo", "12 / 3 s / 14. Descarga a tu alrededor que marca",
          {"kind": "AREA", "mana_cost": 12, "cooldown": 3, "damage": 14, "scale": 1.0, "status": "marca_electrica", "fx": "spark"}),
        A(2, 2, "escudo_estatico", "Escudo estático", "18 / 12 s. Bloquea dos golpes y descarga 15 en quien golpea",
          {"kind": "SHIELD", "mana_cost": 18, "cooldown": 12, "damage": 0, "duration": 6.0, "hits": 2, "thorns": 15,
           "break_status": "marca_electrica"}),
        A(2, 3, "jaula_electrica", "Jaula eléctrica", "22 / 10 s / 6 cada 0,5 s. Jaula de 3 s que frena y marca",
          {"kind": "ZONE", "mana_cost": 22, "cooldown": 10, "damage": 6, "duration": 3.0, "tick": 0.5, "radius": 2.2, "offset": 3.0,
           "slow": 0.5, "status": "marca_electrica"}),
        A(2, 5, "cielo_cargado", "Cielo cargado", "36 / 14 s / 50. Un rayo cae sobre el enemigo más cercano y salta a los marcados",
          {"kind": "STRIKE", "mana_cost": 36, "cooldown": 14, "damage": 50, "target": "nearest", "offset": 8.0, "delay": 0.3,
           "radius": 1.6, "aoe_marked": 4.0}, cost=3),
    ],
    "sombra": [
        A(0, 2, "guadana", "Guadaña", "14 / 4 s / 20. Tajo de sombra en línea corta que marca",
          {"kind": "LINE", "mana_cost": 14, "cooldown": 4, "damage": 20, "length": 3.5, "count": 4, "step_delay": 0.02, "once": True,
           "status": "marca_sombra"}),
        A(0, 3, "enjambre_umbrio", "Enjambre umbrío", "18 / 6 s / 8 × 5. Cinco dardos seguidos que marcan",
          {"kind": "PROJECTILE", "mana_cost": 18, "cooldown": 6, "damage": 8, "count": 5, "interval": 0.08, "speed": 18.0,
           "status": "marca_sombra", "scale": 0.8}),
        A(0, 5, "lluvia_de_cuervos", "Lluvia de cuervos", "38 / 16 s / 18 × 8. Cuervos de sombra caen sobre un área",
          {"kind": "RAIN", "mana_cost": 38, "cooldown": 16, "damage": 18, "count": 9, "duration": 3.0, "radius": 2.6, "offset": 3.5,
           "status": "marca_sombra"}, cost=3),
        A(1, 1, "paso_fantasma", "Paso fantasma", "14 / 6 s / 10. Atraviesas 4,5 unidades sin recibir daño",
          {"kind": "DASH", "mana_cost": 14, "cooldown": 6, "damage": 10, "length": 4.5, "invulnerable": 1.0}),
        A(1, 2, "espejismo", "Espejismo", "18 / 12 s. Invisible y +30 % de velocidad durante 2 s",
          {"kind": "BUFF", "mana_cost": 18, "cooldown": 12, "damage": 0, "duration": 2.0, "mods": {"invisible": 1, "move_pct": 0.3}}),
        A(1, 3, "manto_de_niebla", "Manto de niebla", "24 / 16 s. Niebla de 4 s a tu alrededor: −25 % de daño recibido y deslumbra",
          {"kind": "ZONE", "mana_cost": 24, "cooldown": 16, "damage": 0, "duration": 4.0, "tick": 1.0, "radius": 2.5, "offset": 0.0,
           "follow": True, "status": "deslumbrado", "self_mods": {"received_pct": -0.25}}),
        A(2, 1, "maldicion", "Maldición", "10 / 6 s / 6. Ralentiza 3 s al enemigo más cercano",
          {"kind": "STRIKE", "mana_cost": 10, "cooldown": 6, "damage": 6, "target": "nearest", "offset": 7.0, "radius": 1.0,
           "status": "lento", "status_seconds": 3.0}),
        A(2, 2, "marchitar", "Marchitar", "18 / 9 s / 5 cada 0,5 s. Zona de 4 s que vuelve frágiles a los enemigos",
          {"kind": "ZONE", "mana_cost": 18, "cooldown": 9, "damage": 5, "duration": 4.0, "tick": 0.5, "radius": 2.0, "offset": 3.0,
           "status": "fragil"}),
        A(2, 3, "sifon", "Sifón", "16 / 8 s / 14. Golpe a tu alrededor; si alcanza a alguien recuperas el 6 % de vida",
          {"kind": "AREA", "mana_cost": 16, "cooldown": 8, "damage": 14, "scale": 1.5, "heal_pct": 0.06, "heal_if_hits": 1,
           "status": "marca_sombra"}),
        A(2, 4, "pozo_del_vacio", "Pozo del vacío", "28 / 12 s / 8 cada 0,5 s. Pozo de 3 s que retiene y marca",
          {"kind": "ZONE", "mana_cost": 28, "cooldown": 12, "damage": 8, "duration": 3.0, "tick": 0.5, "radius": 2.8, "offset": 4.0,
           "slow": 0.3, "status": "marca_sombra"}),
    ],
    "tierra": [
        A(0, 1, "honda", "Honda", "10 / 2 s / 10 × 3. Tres piedras seguidas",
          {"kind": "PROJECTILE", "mana_cost": 10, "cooldown": 2, "damage": 10, "count": 3, "interval": 0.15, "speed": 12.0}),
        A(0, 2, "estalagmitas", "Estalagmitas", "20 / 7 s / 22 × 4. Cuatro estalagmitas brotan delante",
          {"kind": "RAIN", "mana_cost": 20, "cooldown": 7, "damage": 22, "count": 4, "duration": 0.8, "radius": 2.2, "offset": 3.0,
           "status": "fisura"}),
        A(0, 3, "pedrada_explosiva", "Pedrada explosiva", "22 / 7 s / 28. Roca que revienta en área y agrieta",
          {"kind": "PROJECTILE", "mana_cost": 22, "cooldown": 7, "damage": 28, "speed": 10.0, "explode_radius": 2.0, "scale": 1.4,
           "status": "fisura"}),
        A(1, 2, "embestida_rocosa", "Embestida rocosa", "16 / 6 s / 24. Embestida de 3,5 unidades que empuja muy fuerte",
          {"kind": "DASH", "mana_cost": 16, "cooldown": 6, "damage": 24, "length": 3.5, "push": 14.0}),
        A(1, 3, "coraza_de_cuarzo", "Coraza de cuarzo", "26 / 16 s. Absorbe 50 de daño durante 6 s",
          {"kind": "SHIELD", "mana_cost": 26, "cooldown": 16, "damage": 0, "duration": 6.0, "shield": 50}),
        A(1, 5, "menhir", "Menhir", "30 / 14 s. Un menhir aguanta 6 golpes y estalla (40) al romperse",
          {"kind": "WALL", "mana_cost": 30, "cooldown": 14, "damage": 0, "length": 1.0, "duration": 8.0, "hits": 6, "prop": "boulder",
           "offset": 2.0, "shatter_damage": 40}, cost=3),
        A(2, 1, "sacudida", "Sacudida", "12 / 5 s / 18. Golpe al suelo delante que aturde 0,6 s",
          {"kind": "STRIKE", "mana_cost": 12, "cooldown": 5, "damage": 18, "offset": 2.5, "radius": 2.0, "status": "aturdido",
           "status_seconds": 0.6}),
        A(2, 3, "fauces_de_tierra", "Fauces de tierra", "26 / 10 s / 45. El suelo muerde al enemigo más cercano tras 0,5 s",
          {"kind": "STRIKE", "mana_cost": 26, "cooldown": 10, "damage": 45, "target": "nearest", "offset": 6.0, "delay": 0.5,
           "radius": 1.4, "status": "fisura", "stacks": 2}),
        A(2, 5, "corrimiento", "Corrimiento de tierra", "36 / 15 s / 26. Avalancha en línea de 8 unidades que empuja",
          {"kind": "LINE", "mana_cost": 36, "cooldown": 15, "damage": 26, "length": 8.0, "count": 8, "step_delay": 0.07, "once": True,
           "push": 12.0, "status": "lento"}, cost=3),
    ],
    "luz": [
        A(0, 1, "rayos_gemelos", "Rayos gemelos", "12 / 1,5 s / 10 × 2. Dos destellos paralelos",
          {"kind": "PROJECTILE", "mana_cost": 12, "cooldown": 1.5, "damage": 10, "count": 2, "spread_deg": 8.0, "speed": 24.0}),
        A(0, 3, "juicio", "Juicio", "26 / 9 s / 45. Columna de luz sobre el enemigo más cercano que deslumbra",
          {"kind": "STRIKE", "mana_cost": 26, "cooldown": 9, "damage": 45, "target": "nearest", "offset": 8.0, "delay": 0.5,
           "radius": 1.3, "status": "deslumbrado"}),
        A(0, 5, "lluvia_de_estrellas", "Lluvia de estrellas", "40 / 18 s / 20 × 9. Estrellas caen 3 s sobre un área",
          {"kind": "RAIN", "mana_cost": 40, "cooldown": 18, "damage": 20, "count": 9, "duration": 3.0, "radius": 3.5, "offset": 3.5,
           "status": "deslumbrado"}, cost=3),
        A(1, 1, "destello_cegador", "Destello cegador", "10 / 6 s / 6. Ciega un momento a quien te rodea",
          {"kind": "AREA", "mana_cost": 10, "cooldown": 6, "damage": 6, "scale": 1.4, "status": "deslumbrado", "fx": "spark"}),
        A(1, 2, "paso_de_luz", "Paso de luz", "14 / 7 s. Apareces junto al enemigo deslumbrado más cercano",
          {"kind": "BLINK", "mana_cost": 14, "cooldown": 7, "damage": 0, "offset": 8.0, "on_marked": "deslumbrado"}),
        A(1, 3, "muro_de_luz", "Muro de luz", "24 / 12 s. Muro de 3,5 unidades durante 6 s que detiene a los enemigos",
          {"kind": "WALL", "mana_cost": 24, "cooldown": 12, "damage": 0, "length": 3.5, "duration": 6.0, "hits": 3, "prop": "crystal",
           "offset": 2.0}),
        A(2, 2, "luz_curativa", "Luz curativa", "22 / 18 s. Círculo de 4 s que te cura un 4 % por segundo",
          {"kind": "ZONE", "mana_cost": 22, "cooldown": 18, "damage": 0, "duration": 4.0, "tick": 0.5, "radius": 2.5, "offset": 0.0,
           "self_mods": {"regen_pct": 0.04}}),
        A(2, 3, "aura_radiante", "Aura radiante", "24 / 14 s / 5 cada 0,5 s. Aura de 5 s que te sigue y deslumbra",
          {"kind": "ZONE", "mana_cost": 24, "cooldown": 14, "damage": 5, "duration": 5.0, "tick": 0.5, "radius": 2.0, "offset": 0.0,
           "follow": True, "status": "deslumbrado"}),
        A(2, 4, "himno", "Himno", "30 / 22 s. −30 % de recargas y +4 de maná por segundo durante 8 s",
          {"kind": "BUFF", "mana_cost": 30, "cooldown": 22, "damage": 0, "duration": 8.0, "mods": {"cooldown_pct": -0.3, "mp_regen": 4}}),
        A(0, 4, "haz_purificador", "Haz purificador", "28 / 10 s / 14 cada 0,25 s. Haz continuo de 2 s que deslumbra",
          {"kind": "BEAM", "mana_cost": 28, "cooldown": 10, "damage": 14, "duration": 2.0, "tick": 0.25, "length": 7.0,
           "status": "deslumbrado"}),
    ],
}

# skills of the design that had no mechanics yet: now built from the existing kinds
IMPLEMENT = {
    "sombra.doble_sombra": {"kind": "BUFF", "mana_cost": 25, "cooldown": 14, "damage": 0, "duration": 5.0,
                            "mods": {"extra_projectiles.sombra": 1, "aff_pct.sombra": 0.4}},
    "sombra.eco_oscuro": {"kind": "BUFF", "mana_cost": 20, "cooldown": 6, "damage": 0, "duration": 4.0, "mods": {"next_sword_pct": 0.5}},
    "luz.sello_protector": {"kind": "ZONE", "mana_cost": 22, "cooldown": 14, "damage": 0, "duration": 5.0, "tick": 0.5, "radius": 3.0,
                            "offset": 0.0, "slow": 0.5, "self_mods": {"received_pct": -0.5}},
    "luz.guardian_de_luz": {"kind": "SHIELD", "mana_cost": 30, "cooldown": 20, "damage": 0, "duration": 8.0, "hits": 2,
                            "break_status": "deslumbrado"},
    "luz.purgar": {"kind": "HEAL", "mana_cost": 15, "cooldown": 10, "damage": 0, "heal_pct": 0.1, "invulnerable": 1.0},
    "tierra.despertar_de_la_montana": {"kind": "RAIN", "mana_cost": 60, "cooldown": 45, "damage": 30, "count": 14, "duration": 7.0,
                                       "radius": 4.0, "offset": 0.0, "status": "fisura", "scale": 1.3},
}
FIX_UPGRADES = {  # upgrades of the design that had no numbers yet
    "hielo.reflejo_de_cristal": [{"skill": "hielo.barrera_cristalina", "set": {"thorns": 20}}],
    "tierra.avalancha": [{"skill": "tierra.meteoro_de_piedra", "mul": {"scale": 1.35}, "add": {"damage": 20}}],
}

# --- one upgrade per active -----------------------------------------------------------------------

# kind -> (name suffix, description, mods without the skill id)
UPGRADE_BY_KIND = {
    "PROJECTILE": ("certero", "+30 % de daño", {"mul": {"damage": 1.3}}),
    "AREA": ("amplio", "+35 % de radio", {"mul": {"scale": 1.35}}),
    "STRIKE": ("devastador", "+30 % de daño y de radio", {"mul": {"damage": 1.3, "radius": 1.3}}),
    "ZONE": ("duradero", "+50 % de duración", {"mul": {"duration": 1.5}}),
    "LINE": ("largo", "+2 unidades de alcance", {"add": {"length": 2.0, "count": 2}}),
    "CHAIN": ("encadenado", "+2 saltos", {"add": {"count": 2}}),
    "BEAM": ("sostenido", "+1 s de duración", {"add": {"duration": 1.0}}),
    "DASH": ("doble", "Una carga más", {"add": {"charges": 1}}),
    "BLINK": ("ágil", "−35 % de recarga", {"mul": {"cooldown": 0.65}}),
    "PULL": ("firme", "−35 % de recarga", {"mul": {"cooldown": 0.65}}),
    "RAIN": ("torrencial", "+4 impactos", {"add": {"count": 4}}),
    "BUFF": ("prolongado", "+50 % de duración", {"mul": {"duration": 1.5}}),
    "SHIELD": ("reforzado", "+50 % de absorción y un bloqueo más", {"mul": {"shield": 1.5}, "add": {"hits": 1}}),
    "HEAL": ("sereno", "−30 % de recarga", {"mul": {"cooldown": 0.7}}),
    "WALL": ("macizo", "+2 unidades y +2 golpes", {"add": {"length": 2.0, "hits": 2}}),
}
FEMININE_END = ("a", "ión", "ad", "ez")


def upgrade_for(tree, node):
    kind = node["skill"]["kind"]
    suffix, effect, mods = UPGRADE_BY_KIND[kind]
    name = node["name"]
    first = name.split()[0].lower()
    if first.endswith(FEMININE_END) or first in ("ventisca", "lluvia", "cadena", "bola", "lanza", "jaula", "coraza", "pira",
                                                 "guadaña", "maldición", "aura", "luz", "columna", "erupción", "tormenta",
                                                 "fortaleza", "grieta", "piel", "barrera", "prisión", "fractura", "nova",
                                                 "chispa", "descarga", "pedrada", "honda", "sacudida", "estela", "convergencia",
                                                 "sobrecarga", "embestida", "carga", "ráfaga"):
        suffix = {"certero": "certera", "amplio": "amplia", "duradero": "duradera", "largo": "larga", "encadenado": "encadenada",
                  "sostenido": "sostenida", "prolongado": "prolongada", "reforzado": "reforzada", "macizo": "maciza",
                  "sereno": "serena", "firme": "firme", "doble": "doble", "ágil": "ágil", "torrencial": "torrencial",
                  "devastador": "devastadora"}[suffix]
    entry = {"skill": node["id"]}
    entry.update(json.loads(json.dumps(mods)))
    return dict(type="mejora", branch=node["branch"], tier=node["tier"], id=node["id"] + "_mejora", name=f"{name} {suffix}",
                desc=f"{name}: {effect}", cost=1, mods=[entry])


def place(nodes, node, min_tier=1):
    """Puts the node in its tier or the nearest one with room in its branch's column (never below
    `min_tier`: an upgrade sits with its skill or after it)."""
    used = {}
    for n in nodes:
        if n["branch"] >= 0:
            used[(n["branch"], n["tier"])] = used.get((n["branch"], n["tier"]), 0) + 1
    want = node["tier"]
    for t in [want, want + 1, want - 1, want + 2, want - 2, want + 3, want - 3]:
        if min_tier <= t <= 5 and used.get((node["branch"], t), 0) < CELL:
            node["tier"] = t
            return node
    raise SystemExit(f"no room for {node['id']} in branch {node['branch']}")


def expand(tree):
    path = TREES / f"{tree}.json"
    data = json.loads(path.read_text())
    nodes = data["nodes"]
    order = {n["id"]: i for i, n in enumerate(nodes)}  # the design's own nodes keep their order (starters first)
    names = {n["branch"]: n["branch_name"] for n in nodes}
    ids = {n["id"] for n in nodes}
    for nid, skill in IMPLEMENT.items():
        for n in nodes:
            if n["id"] == nid:
                n["skill"] = skill
                n.pop("implemented", None)
    for nid, mods in FIX_UPGRADES.items():
        for n in nodes:
            if n["id"] == nid:
                n["mods"] = mods
                n.pop("implemented", None)
    for new in NEW.get(tree, []):
        node = dict(new, id=f"{tree}.{new['id']}", branch_name=names[new["branch"]])
        if node["id"] not in ids:
            nodes.append(place(nodes, node))
            ids.add(node["id"])
    upgraded = {m["skill"] for n in nodes if n["type"] == "mejora" for m in (n.get("mods") or []) if "skill" in m}
    for n in list(nodes):
        if n["type"] == "activa" and n.get("skill") and n.get("implemented", True) and n["id"] not in upgraded:
            up = upgrade_for(tree, n)
            if up["id"] not in ids:
                up["branch_name"] = n["branch_name"]
                nodes.append(place(nodes, up, min_tier=n["tier"]))
                ids.add(up["id"])
    # order: by branch, then tier, actives before their upgrades (the screen fills cells in this order)
    rank = {"activa": 0, "mejora": 1, "pasiva": 2, "definitiva": 3}
    base_of = {n["id"]: (n["mods"][0]["skill"] if n["type"] == "mejora" and n.get("mods") else n["id"]) for n in nodes}
    tier_of = {n["id"]: n["tier"] for n in nodes}
    nodes.sort(key=lambda n: (n["branch"] if n["branch"] >= 0 else 9, n["tier"],
                              0 if n["type"] in ("activa", "mejora") else 1, order.get(base_of[n["id"]], 1000),
                              base_of[n["id"]], rank[n["type"]]))
    # requirements
    for n in nodes:
        n.pop("requires", None)
        n.pop("requires_any", None)
        if n["branch"] < 0:
            continue
        if n["type"] == "mejora" and n.get("mods") and "skill" in n["mods"][0]:
            n["requires"] = [n["mods"][0]["skill"]]
        elif n["type"] == "activa" and n["tier"] > 1:
            lower = [o["id"] for o in nodes if o["branch"] == n["branch"] and o["type"] == "activa" and o["tier"] < n["tier"]
                     and o.get("implemented", True)]
            if lower:
                n["requires_any"] = lower
        elif n["type"] == "pasiva":
            lower = [o["id"] for o in nodes if o["branch"] == n["branch"] and o["type"] == "activa" and o["tier"] <= n["tier"]
                     and o.get("implemented", True) and o["id"] != n["id"]]
            if lower and n["tier"] > 1:
                n["requires_any"] = lower
        if "requires" not in n and "requires_any" not in n:
            n["requires"] = []  # free once its tier is open
    path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
    actives = [n for n in nodes if n["type"] == "activa" and n.get("implemented", True)]
    cells = {}
    for n in nodes:
        if n["branch"] >= 0:
            cells[(n["branch"], n["tier"])] = cells.get((n["branch"], n["tier"]), 0) + 1
    return len(nodes), len(actives), max(cells.values())


if __name__ == "__main__":
    for tree in ["fuego", "hielo", "rayo", "sombra", "tierra", "luz"]:
        total, actives, fullest = expand(tree)
        print(f"{tree}: {total} nodes, {actives} actives, fullest cell {fullest}")
