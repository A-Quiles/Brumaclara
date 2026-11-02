# Registro de aprobación de recursos

Metadatos y decisión por recurso, como pide `docs/plan_unificacion_artistica.md` (sección 6). Estado:
**aprobado** (probado en la escena de validación y en el juego), **pendiente** (sigue en el juego,
hay que rehacerlo) o **rechazado** (fuera del juego, guardado en `no_encajan/`).

| Recurso | Categoría | Origen → destino | Herramienta | Fuente | Licencia / procedencia | Fecha | Estado | Observaciones |
|---|---|---|---|---|---|---|---|---|
| `textures/wall_plaster.png` | Pared interior | 1264 px → baldosa 84 px | `v2.interior` + `unify.master` | `art/ai/v2/wall_plaster.png` | Canva (cuenta del autor) | 2026-11-02 | aprobado | Vigas a 4-5 px como las fachadas |
| `textures/floor_planks.png` | Suelo interior | 1264 px → 84 px | ídem | `art/ai/v2/floor_planks.png` | Canva | 2026-11-02 | aprobado | Saturación 0,62 |
| `textures/floor_flagstone.png` | Suelo interior | 1264 px → 84 px | ídem | `art/ai/v2/flagstone.png` | Canva | 2026-11-02 | aprobado | |
| `props/interior/*.png` (32) | Muebles | 1024 px → 20-46 px de alto | `build.interiors` + `unify.shrink/master` | `art/ai/frente/muebles_a.png`, `muebles_b.png` | Figma | 2026-11-02 | aprobado | De frente, tamaño real (25 px/m) |
| `props/merchant_wagon.png` y 5 comercios más | Puestos | 1024 px → 46-80 px | `build.frente` | `art/ai/frente/puestos.png` | Figma | 2026-11-02 | aprobado | De frente; sustituyen a los diagonales de Canva |
| 21 objetos de calle (banco, caja, tablón, jardinera, abrevadero, muro bajo, carretillas, pozo, leña, vallas, pizarra, barriles, armero, arco, buhardilla, chimenea, farol de pared, paca, sacos) y el cofre animado | Objetos | 1024 px → 18-77 px | `build.frente` | `art/ai/frente/objetos_calle.png`, `puestos.png` | Figma | 2026-11-02 | aprobado | De frente; antes en diagonal |
| `buildings/roof_red.png`, `roof_orange.png` | Tejados | 1024 px → baldosa | `build.walls_roofs/house` + `unify.toned` | `art/ai/walls_roofs.png`, `house.png` | Figma | 2026-11-02 | aprobado | Solo tono: la paleta maestra aplanaba el rojo |
| `textures/cobble.png` | Suelo | 1024 px → 109 px | `build.terrain` | `art/ai/terrain_a.png` | Figma | 2026-11-02 | aprobado | Vuelve el clásico; el de la segunda pasada, rechazado |
| `textures/cobble.png` (segunda pasada) | Suelo | 1264 px → 218 px | `v2.ground` | `art/ai/v2/cobble.png` | Canva | 2026-11-02 | rechazado | Borroso y oscuro junto a las fachadas |
| `textures/grass_nuevo.png` | Suelo | 1264 px → 218 px | `v2.ground` | `art/ai/v2/grass.png` | Canva | 2026-10-29 | guardado | Para otros lugares, a petición del autor; no se usa en Brumaclara |
| `characters/townsfolk/{caldus,iven,lio,neris,rhea,sella,tovan}.png` | Vecinos | 200 px → 1:1 | `build.characters` | `art/ai/<nombre>.png` | Canva | 2026-10-27 | pendiente | Ruido de miniatura |
| `characters/enemies/*` (16 hojas de 200 px) | Monstruos | 200 px → 1:1 | `build.monsters` | `art/ai/<nombre>.png` | Canva | 2026-10-27 | pendiente | Ruido de miniatura |
| `props/town_gate.png` | Puerta | 1024 px → 190 px | `build.frente` | `art/ai/frente/puerta.png` | Figma | 2026-11-02 | aprobado | De frente y simétrica; torres y faroles recolocados en la escena |
