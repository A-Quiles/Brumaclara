# Registro de aprobación de recursos

Metadatos y decisión por recurso, como pide `docs/plan_unificacion_artistica.md` (sección 6). Estado:
**aprobado** (probado en la escena de validación y en el juego), **pendiente** (sigue en el juego,
hay que rehacerlo) o **rechazado** (fuera del juego, guardado en `no_encajan/`).

| Recurso | Categoría | Origen → destino | Herramienta | Fuente | Licencia / procedencia | Fecha | Estado | Observaciones |
|---|---|---|---|---|---|---|---|---|
| `textures/wall_plaster.png` | Pared interior | 1264 px → baldosa 84 px | `v2.interior` + `unify.master` | `art/ai/v2/wall_plaster.png` | Canva (cuenta del autor) | 2026-11-02 | aprobado | Vigas a 4-5 px como las fachadas |
| `textures/floor_planks.png` | Suelo interior | 1264 px → 84 px | ídem | `art/ai/v2/floor_planks.png` | Canva | 2026-11-02 | aprobado | Saturación 0,62 |
| `textures/floor_flagstone.png` | Suelo interior | 1264 px → 84 px | ídem | `art/ai/v2/flagstone.png` | Canva | 2026-11-02 | aprobado | |
| `props/interior/*.png` (32) | Muebles | celda de 50 px → 20-46 px de alto | `build.interiors` + `unify.shrink/master` | `art/ai/furniture_a.png`, `furniture_b.png` | Canva | 2026-11-02 | aprobado | Tamaño real (25 px/m); siguen saliendo de miniaturas de 200 px: redibujar cuando haya cupo |
| `props/merchant_wagon.png` y 5 comercios más | Puestos | 1536 px → 56-84 px | `v2.stalls` + `unify.master` | `art/ai/v2/stalls.png` | Canva | 2026-11-02 | aprobado | Luz ×1,3, saturación ×0,8 |
| `buildings/roof_red.png`, `roof_orange.png` | Tejados | 1024 px → baldosa | `build.walls_roofs/house` + `unify.toned` | `art/ai/walls_roofs.png`, `house.png` | Figma | 2026-11-02 | aprobado | Solo tono: la paleta maestra aplanaba el rojo |
| `textures/cobble.png` | Suelo | 1024 px → 109 px | `build.terrain` | `art/ai/terrain_a.png` | Figma | 2026-11-02 | aprobado | Vuelve el clásico; el de la segunda pasada, rechazado |
| `textures/cobble.png` (segunda pasada) | Suelo | 1264 px → 218 px | `v2.ground` | `art/ai/v2/cobble.png` | Canva | 2026-11-02 | rechazado | Borroso y oscuro junto a las fachadas |
| `textures/grass_nuevo.png` | Suelo | 1264 px → 218 px | `v2.ground` | `art/ai/v2/grass.png` | Canva | 2026-10-29 | guardado | Para otros lugares, a petición del autor; no se usa en Brumaclara |
| `characters/townsfolk/{caldus,iven,lio,neris,rhea,sella,tovan}.png` | Vecinos | 200 px → 1:1 | `build.characters` | `art/ai/<nombre>.png` | Canva | 2026-10-27 | pendiente | Ruido de miniatura |
| `characters/enemies/*` (16 hojas de 200 px) | Monstruos | 200 px → 1:1 | `build.monsters` | `art/ai/<nombre>.png` | Canva | 2026-10-27 | pendiente | Ruido de miniatura |
| `props/town_gate.png` | Puerta | 1264 px → 190 px | `v2.gate` | `art/ai/v2/gate.png` | Canva | 2026-10-29 | pendiente | En tres cuartos: se ve torcida |
