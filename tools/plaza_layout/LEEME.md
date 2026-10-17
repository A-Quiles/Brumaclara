# Plaza del pueblo: ajuste a la imagen de referencia

Herramientas con las que se colocó la plaza de `scenes/levels/village.tscn` sobre
`docs/reference/concepto.jpg`.

- `cam.py`: la cámara de 30° del prototipo, ajustada a la imagen (pies del héroe en (705, 600)).
- `layout.py`: todos los bloques, casas, escaleras, objetos y personajes de la plaza; `python3 layout.py layout.json`.
- `overlay.py`: dibuja el layout sobre la referencia para comprobar el ajuste.
- `cam2.py` y `convert.py`: la cámara de lente desplazada (verticales verticales) y la conversión del
  layout a ella, para rehacer la plaza con el arte nuevo.

El escenario se genera con `tools/plaza_builder/build_plaza.gd` (`-- prefabs level`).
