# GUILD ZERO / Brumaclara — contexto para trabajar en el repo

- Motor: Godot 4.7 (GL Compatibility). Pruebas: `~/bin/godot --headless --fixed-fps 60 --path . --script tools/tests/<test>.gd`.
- Cada cambio se sube: commit + push a `main` y `tools/web/publish.sh` (versión web en gh-pages).
- **Arte: `docs/plan_unificacion_artistica.md` es de obligado cumplimiento.** Ningún recurso entra en el
  juego sin pasar por la escena de validación (`scenes/dev/validacion_arte.tscn`, captura con
  `tools/capture/validacion_arte.sh`) y la lista de comprobación de su sección 5. Trabajar por lotes
  pequeños y reversibles, comparando capturas antes/después.
- Auditoría medible del arte: `python3 tools/art_audit/audit.py` (densidad de píxel, ruido, suavidad,
  bordes, saturación) e informe en `docs/auditoria_arte.md`. Los recursos que no encajan se apartan en
  `art/revision/no_encajan/` con su motivo; el registro de aprobaciones está en `art/revision/registro.md`.
- Paleta maestra con rampas por material: `art/paleta/`. Trucos para necesitar menos sprites:
  `docs/guia_arte_sin_tantos_sprites.md`.
- Píxel de referencia: `pixel_size 0.0449` (22,3 píxeles por unidad); el suelo, 20 por unidad.
