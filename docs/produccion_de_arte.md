# Producción de arte (cola de Canva)

El arte nuevo se genera con Canva (`generate-image`) y se integra con el pipeline de
`tools/art_pipeline/`. Canva da pocas imágenes seguidas: cuando responde `quota_exceeded` hay que
esperar unos minutos (recupera aproximadamente una imagen cada 4–8 minutos). Por eso el trabajo va
en tandas, siguiendo una cola.

## La cola

`tools/data/art_queue.json` (se rehace con `python3 tools/data/art_queue.py`, que marca como hecho
todo lo que ya tiene su imagen en `art/ai/`). Cada entrada tiene el nombre del archivo, el tipo
(`monster`, `character`, `icons`), la proporción para Canva y el prompt completo. Las criaturas
alteradas llevan siempre la marca de la Fractura (ojos y grietas violeta, cristales), y el fondo
plano va en verde cuando el dibujo tiene mucho violeta o magenta.

## Integrar cada tipo

Guardar la imagen de Canva (la que devuelve el trabajo terminado) como `art/ai/<nombre>.png`, y:

**Monstruo**
1. Añadir `"<nombre>": (28, lift)` a `MONSTERS` en `tools/art_pipeline/build.py` (lift: píxeles que
   flota si vuela; 0 si no).
2. `python3 tools/art_pipeline/build.py monsters` y mirar la hoja (`assets/characters/enemies/<nombre>.png`):
   si el recorte se come parte del dibujo, bajar su tolerancia en `KEY_TOL`.
3. `python3 tools/data/enemies.py`: escribe su ficha (números del bestiario) y coloca en las afueras
   los de las zonas 1 y 2. Los de otras zonas se ven en la galería `scenes/dev/bestiario.tscn`.

**Personaje**
1. Añadir `"<nombre>": (mira_a_la_izquierda, 80.0, "all")` a `CHARACTERS` en `build.py` (el primer
   valor, si la fila lateral está dibujada mirando a la izquierda; `"all"` limpia el color del fondo
   que queda pegado, salvo que la ropa tenga ese mismo color).
2. `python3 tools/art_pipeline/build.py characters` y revisar la hoja.
3. Colocarlo: en el pueblo con `tools/levels/people.py`, o en un interior con `tools/levels/interiors.py`
   (lista `people` de cada sala), con sus frases.

**Iconos**
1. `python3 tools/art_pipeline/build.py skill_icons` (5×5; el tronco, 6×6).
2. `python3 tools/data/skill_icons.py` (qué icono usa cada habilidad, en el orden del prompt).

Después: `~/bin/godot --headless --path . --import`, las pruebas de `tools/tests/` y commit.
