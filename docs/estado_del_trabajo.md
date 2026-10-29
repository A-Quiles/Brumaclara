# Estado del trabajo (octubre 2026)

> Este documento es la referencia del estado implementado y de los pendientes. Los árboles, enemigos y regiones de otros documentos pueden describir contenido diseñado o previsto; no se considerarán jugables hasta verificarlos en el código y en una ejecución. El índice de fuentes de verdad está en `docs/ORDEN_DOCUMENTACION.md`.

Resumen de lo que hay en el repositorio, lo que falta y cómo probarlo. Para trabajar con Claude, consultar al inicio de cada sesión `docs/INSTRUCCIONES_CLAUDE.md`, que define el orden de prioridades y el registro de tareas. Las directrices generales del proyecto están en `docs/instrucciones_del_proyecto.md`.

## Qué está hecho

- **Juego jugable:** creador de personaje, pueblo de Brumaclara con personajes y diálogos, afueras con combate,
  interiores (posada, sede del Faro, tienda, taller), árbol de habilidades parcialmente implementado (consulta el estado de las afinidades en el código y el catálogo de diseño en `docs/arbol_habilidades.md`),
  progreso guardado y modo edición de niveles.
- **Monstruos:** zona 1 completa en el juego con arte propio: roedor de bruma, jabalí espinoso y cuervo de bruma
  (Canva, marca de la Fractura). El resto de monstruos de la galería del bestiario tienen arte de la tanda anterior.
- **Personajes de la historia:** Iven, Neris, Tovan, Rhea, Caldus, Lio y Sella, con su hoja de movimiento de 4×3.
- **Habilidades:** el catálogo define 21 activas por afinidad, cada una con su mejora e icono propio (165 iconos en total); no se debe interpretar como prueba de que las seis afinidades estén completas en juego. El catálogo exacto está en `docs/habilidades_lista.md`.
- **Exportación web:** `tools/web/publish.sh` exporta el juego y lo sube a la rama `gh-pages`.

## Novedades del 29 de octubre de 2026

- **Brumaclara se juega entera:** capítulo 1 con misiones (`scripts/systems/quests.gd`), caja de diálogo con
  elecciones, objetivo en pantalla, recompensas y final con la insignia de rango cero.
- **Día y noche** (`scripts/systems/day_night.gd`, N salta al atardecer o al amanecer) con charcos de luz en
  farolas, faroles y la puerta.
- **Gran puerta de la ciudad** (Canva) como entrada desde las afueras.
- **Patio de pruebas** (`scenes/levels/arena.tscn`): llama a cualquier enemigo del bestiario.
- **Comerciantes** (Lio y Sella venden) y seis comercios ambulantes nuevos; guardias y Elia pasean por rutas.
- **Texturas nuevas** de césped y adoquín (suelo) y de tarima, yeso con entramado y losas (interiores).
- **Poderes vistosos** con partículas, anillos y luz por afinidad (`scripts/effects/vfx.gd`).
- **Fuente fluida** (agua con partículas sobre el dibujo a pleno caudal).
- **Ataque andando** arreglado: la animación del espadazo ya no se congela al andar.
- **Peinados redibujados** (corto y coleta del héroe); fuera los peinados raros añadidos por código.

## Qué falta

- **Monstruos por generar (19):** saqueador; arana de musgo, ciervo de cristal y enredadera (zona 2); rana cornuda,
  garza alterada, sanguijuela de cristal, tortuga de lodo, fuego fatuo y caimán de la barrera (zona 3); jabalí de
  cantera, gólem de escombro, minero perdido, murciélago de hollín, escarabajo perforador y pico errante (zona 4);
  los tres jefes (árbol que susurra, caparazón de Vigilia y taladro de la Trama). Sus prompts están en
  `tools/data/art_queue.json`. Cada uno se integra con los pasos de `docs/produccion_de_arte.md`.
- **Movimiento en 8 direcciones y correr:** el juego usa solo 3 filas por personaje (abajo, lado, arriba). Hace
  falta una hoja nueva con 5 filas y otra para correr.
- **Vídeo de jugabilidad:** el script `tools/capture/make_video.sh` está listo; falta grabarlo.
- **Peinados pendientes:** melena y rapado del héroe; bob, suelta, moño y trenzas de la heroína
  (`tools/data/hair_queue.json`, prompt en `art/FUENTES.md`).
- **Textura de tierra nueva** (el camino de tierra sigue con la textura antigua).
- **Paleta maestra** y regla de detalle para unificar el pixelado (`docs/guia_arte_sin_tantos_sprites.md`).
- **Activar GitHub Pages** sobre la rama `gh-pages` (Settings → Pages), para jugar en el navegador.

## Probarlo

- **En el navegador:** https://a-quiles.github.io/Brumaclara/ (cuando Pages esté activado).
- **Con Godot 4.7:** descargar el proyecto, abrir `project.godot` y pulsar F5.

## Herramientas de arte

- Canva (`generate-image`) y Figma tienen cuota limitada: si responden `quota_exceeded` o créditos insuficientes,
  hay que esperar. Figma se recarga el 1 de noviembre de 2026.
- El pipeline de sprites está en `tools/art_pipeline/build.py`. Los assets generados se guardan en `art/ai/`.
- Los monstruos se integran con `build.py monsters` y `tools/data/enemies.py`.
