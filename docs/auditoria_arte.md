# Auditoría artística de Brumaclara — 2 de noviembre de 2026

Primera aplicación de `docs/plan_unificacion_artistica.md` (fase P0). Este documento separa lo
**implementado y probado**, lo **diseñado** y lo **pendiente**, como pide el plan (sección 9).

## Cómo se ha medido

`python3 tools/art_audit/audit.py` mide los 347 PNG de `assets/` tal como se dibujan en el juego:

| Métrica | Qué mide | Por qué importa |
|---|---|---|
| píxel aparente | unidades del mundo por píxel donde se dibuja, frente al del héroe (`pixel_size 0,0449`) | 1,0 = mismo píxel que el héroe; 2 = píxeles el doble de gordos (*mixels*) |
| suavidad | parte de los píxeles vecinos que cambian solo un poco (degradados) | alta = se lee como pintura, «menos pixelado» |
| bordes | parte de los vecinos con un salto fuerte de luz (contornos, vigas, juntas) | baja = detalle sobredimensionado, parece ampliado |
| ruido | píxeles distintos de sus cuatro vecinos | alto = «demasiado pixelado», píxeles sueltos |
| saturación y valor | color y luz medios | paletas que no casan |

`tools/art_audit/review.py` compara cada recurso con las **referencias aprobadas de su familia**
(fachadas Figma para edificios; barril, caja, farol, bancos y puestos de la plaza para objetos; el
héroe para personajes; el suelo clásico para suelos) y lista los que se apartan. Las listas son un
punto de partida: todo se revisó a ojo en hojas de contacto a ×3 y en la escena de validación.

## Lo que se encontró

1. **La escala del píxel ya era coherente** en sprites (todos a 1,0) y casi en suelos (1,11). El
   problema no es el tamaño del píxel, sino **cuánto detalle cabe en cada píxel** y de dónde sale el
   dibujo. Había tres orígenes que no casan entre sí:
   - **Figma, hojas de 1024 px reducidas ~5×** (fachadas, objetos de la plaza, árboles, Mara, Elia,
     lobo): contornos limpios, grupos de píxeles claros. Es la referencia.
   - **Miniaturas de Canva de 200 px usadas píxel a píxel** (vecinos nuevos, 16 monstruos, muebles,
     iconos): ruido de píxeles sueltos (0,45-0,58 frente a 0,39 del héroe). Además, los muebles se
     dibujaron todos del mismo tamaño de celda: una silla medía casi lo que el héroe.
   - **Canva a tamaño completo reducido 7,5×** (paredes y suelos de interior, puestos ambulantes,
     adoquín nuevo, puerta): detalle sobredimensionado (vigas de 10 px frente a 4-5 px de las
     fachadas) y sombreado degradado. Por eso **las paredes de los interiores se veían menos
     pixeladas que las exteriores**.
2. **Paletas independientes**: cada hoja tenía la suya; puestos y muebles más oscuros y saturados.
3. **Efectos a otra escala de píxel**: el anillo de choque, el destello y las marcas de aviso se
   ampliaban desde texturas de 16-32 px (píxeles hasta 4,5 veces más gordos), y las explosiones
   grandes se dibujaban ampliando el sprite.
4. **Fallo propio corregido**: al devolver el césped clásico, las afueras y el patio de pruebas lo
   dibujaban a doble tamaño de píxel (tamaño de baldosa de la segunda pasada). Arreglado: el patio
   calcula ahora la baldosa a partir del ancho de la textura.

## Implementado y probado (lote 1, sin generar ninguna imagen nueva)

| Recurso | Antes | Después |
|---|---|---|
| Pared de yeso, tarima y losas de interior | baldosa 168 px, vigas de 10 px, degradados | baldosa 84 px desde la misma fuente, tono ajustado, paleta maestra |
| 32 muebles de interior | todos ~40 px de alto, madera naranja saturada | tamaño real (25 px por metro), madera en la rampa del exterior |
| Salas interiores | pensadas para muebles enormes | más pequeñas y amuebladas con más intención (sillas alrededor de las mesas, barra con barriles…) |
| 6 comercios ambulantes | oscuros y saturados, 40 colores propios | más luz, menos saturación, paleta maestra |
| Tejados rojo y naranja | rojo y naranja planos y chillones | saturación y luz contenidas, con sus propios matices |
| Adoquín | el de la segunda pasada (borroso, oscuro) | vuelve el clásico, de contornos limpios |
| Anillos, destellos, marcas de aviso y zonas | texturas pequeñas ampliadas | dibujados al píxel del juego; crecen añadiendo píxeles |
| Explosiones grandes | un sprite ampliado | varias explosiones a tamaño normal alrededor del centro |
| Partículas | tamaño y escala aleatorios | cuadrados de píxeles enteros |

Comparación en `docs/screenshots/validacion/comparacion.png` (escena de validación y posada,
antes/después) y todas las capturas en `docs/screenshots/validacion/`.

Las 13 pruebas automáticas pasan. Las versiones que no encajaban están en
`art/revision/no_encajan/` con su motivo; el registro de aprobación, en `art/revision/registro.md`.

## Lote 2: objetos de frente (implementado y probado)

Muchos objetos estaban dibujados en **diagonal** (isométricos o en tres cuartos girados): la puerta de la
ciudad con una torre más cerca que la otra, el arco del patio, los seis comercios ambulantes, bancos,
cajas, el tablón, la jardinera, el abrevadero, el muro bajo, las carretillas, el pozo, las vallas y casi
todos los muebles de interior. Con la cámara mirando al norte y las verticales rectas, junto a las
casas de frente se veían torcidos. Se redibujaron **de frente** con Figma (la misma herramienta y modelo
de las fuentes aprobadas, plantilla de `art/FUENTES.md` con una frase de cámara obligatoria): 21
objetos de calle, el cofre animado, los 6 comercios, la puerta y los 32 muebles, a su tamaño real y en
la paleta maestra. `tools/levels/fit_offsets.py` recentró los sprites en todas las escenas; la puerta
tiene ahora las torres y los faroles donde están en el dibujo.

Capturas en `docs/screenshots/frente/`. Las vistas giradas de `art/ai/variants` (`__sw`, `__se`…) se
mantienen: existen precisamente para orientar un objeto según una calle en diagonal.

## Diseñado (herramientas listas)

- **Paleta maestra** (`art/paleta/maestra.png`, `.gpl` para Aseprite/GIMP/Krita, `.json`): 69
  colores en rampas por material (contorno y sombra, madera y tierra, yeso y tierra clara, piedra y
  metal, vegetación, tejidos cálidos y tejas, tejidos fríos y pizarra) más colores reservados para
  la magia y el fuego. Se construye desde las referencias aprobadas (`tools/art_pipeline/palette.py`).
- **Paso de unificación** (`tools/art_pipeline/unify.py`): reducir al tamaño real, ajustar tono y
  pasar por la paleta maestra. Para rampas finas (el rojo de un tejado) solo se ajusta el tono: la
  paleta aplanaba sus brillos.
- **Escena de validación** (`scenes/dev/validacion_arte.tscn`, generada por
  `tools/levels/validation.py`): la luz, el cielo, el suelo, la cámara, el HUD y una casa copiados de
  Brumaclara, con héroe, vecina, árbol, plantas, barril, caja, cofre, farol, puesto, suelo y pared de
  interior, y un efecto mágico que se repite. `tools/capture/validacion_arte.sh <prefijo>` saca día,
  efectos de las seis afinidades, diálogo y noche.

## Pendiente

- **Redibujar a tamaño completo**: 7 vecinos y 16 monstruos que salen de miniaturas de 200 px. Siguen en
  el juego hasta entonces.
- **Lote 2 sin generar**: revisar con la escena de validación los iconos de habilidad (también de
  200 px), las vistas extra de objetos hechas con Gemini y los textos 3D (no usan la fuente pixel).
- **Interfaz**: revisión de legibilidad (plan, P1).
- **Tamaños de referencia por categoría**: la tabla de alturas de los muebles es el primer paso
  (`FURNITURE_HEIGHT` en `tools/art_pipeline/build.py`); falta hacer lo mismo con objetos de exterior.
