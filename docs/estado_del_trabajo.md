# Estado del trabajo (octubre 2026)

Resumen de lo que hay en el repositorio, lo que falta y cómo probarlo. Las directrices del proyecto están en
`docs/instrucciones_del_proyecto.md`.

## Qué está hecho

- **Juego jugable:** creador de personaje, pueblo de Brumaclara con personajes y diálogos, afueras con combate,
  interiores (posada, sede del Faro, tienda, taller), árbol de habilidades con cuatro afinidades y tronco común,
  progreso guardado y modo edición de niveles.
- **Monstruos:** zona 1 completa en el juego con arte propio: roedor de bruma, jabalí espinoso y cuervo de bruma
  (Canva, marca de la Fractura). El resto de monstruos de la galería del bestiario tienen arte de la tanda anterior.
- **Personajes de la historia:** Iven, Neris, Tovan, Rhea, Caldus, Lio y Sella, con su hoja de movimiento de 4×3.
- **Habilidades:** 21 activas por afinidad, cada una con su mejora e icono propio (165 iconos en total).
- **Exportación web:** `tools/web/publish.sh` exporta el juego y lo sube a la rama `gh-pages`.

## Qué falta

- **Monstruos por generar (19):** saqueador; arana de musgo, ciervo de cristal y enredadera (zona 2); rana cornuda,
  garza alterada, sanguijuela de cristal, tortuga de lodo, fuego fatuo y caimán de la barrera (zona 3); jabalí de
  cantera, gólem de escombro, minero perdido, murciélago de hollín, escarabajo perforador y pico errante (zona 4);
  los tres jefes (árbol que susurra, caparazón de Vigilia y taladro de la Trama). Sus prompts están en
  `tools/data/art_queue.json`. Cada uno se integra con los pasos de `docs/produccion_de_arte.md`.
- **Movimiento en 8 direcciones y correr:** el juego usa solo 3 filas por personaje (abajo, lado, arriba). Hace
  falta una hoja nueva con 5 filas y otra para correr.
- **Vídeo de jugabilidad:** el script `tools/capture/make_video.sh` está listo; falta grabarlo.
- **Activar GitHub Pages** sobre la rama `gh-pages` (Settings → Pages), para jugar en el navegador.

## Probarlo

- **En el navegador:** https://a-quiles.github.io/Brumaclara/ (cuando Pages esté activado).
- **Con Godot 4.7:** descargar el proyecto, abrir `project.godot` y pulsar F5.

## Herramientas de arte

- Canva (`generate-image`) y Figma tienen cuota limitada: si responden `quota_exceeded` o créditos insuficientes,
  hay que esperar. Figma se recarga el 1 de noviembre de 2026.
- El pipeline de sprites está en `tools/art_pipeline/build.py`. Los assets generados se guardan en `art/ai/`.
- Los monstruos se integran con `build.py monsters` y `tools/data/enemies.py`.
