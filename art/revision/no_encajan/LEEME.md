# Sprites que no encajan

Recursos que no cumplen `docs/plan_unificacion_artistica.md`, encontrados con la auditoría
(`tools/art_audit/`) y revisados en la escena de validación. Aquí se guardan las versiones que no
encajaban: `rehechos/` son los que ya se rehicieron desde sus fuentes sin generar nada nuevo (para
comparar o deshacer); `pendientes/` siguen en el juego hasta que se puedan redibujar.

## Paredes y suelos de interior (rehechos)

**Problema:** Detalle sobredimensionado: las vigas miden 10 px frente a 4-5 px en las fachadas, y el sombreado es degradado (suavidad 0,77 frente a 0,26-0,39 de las fachadas). Se leen menos pixeladas que el exterior. Fuente Canva v2 de 1264 px reducida 7,5 veces a baldosas de 168 px.

**Acción:** Rehechas desde la misma fuente a baldosas de 84 px (el detalle a la mitad), tono ajustado y paleta maestra.

Archivos: `wall_plaster.png`, `floor_planks.png`, `floor_flagstone.png`

## Muebles de interior (rehechos)

**Problema:** Escala de 1,4 a 1,9 veces la de su tamaño real junto al héroe (una silla de 41 px frente a un héroe de 44 px; un barril de 40 px frente a los 25 px del barril de la calle). Madera naranja muy saturada (0,6-0,7) y ruido de la miniatura de 200 px de la que salen.

**Acción:** Reducidos a su tamaño real (25 px por metro) promediando la fuente, lo que además limpia el ruido, y pasados por la paleta maestra con la saturación de la madera del exterior.

Archivos: `mesa_redonda.png`, `silla.png`, `mesa_larga.png`, `barra.png`, `estante_botellas.png`, `chimenea.png`, `cama.png`, `armario.png`, `barril_grifo.png`, `fogon.png`, `estanteria.png`, `escritorio.png`, `alfombrilla.png`, `planta.png`, `farol_poste.png`, `arcon.png`, `mostrador_registro.png`, `tablon_contratos.png`, `vitrina_pociones.png`, `armero.png`, `maniqui_cota.png`, `yunque.png`, `banco_trabajo.png`, `mesa_mapas.png`, `estante_pergaminos.png`, `lampara_cristal.png`, `cajas_mercancia.png`, `sacos_harina.png`, `estante_pociones.png`, `estandarte_gremio.png`, `cofre_tesoro.png`, `candelabro.png`

## Comercios ambulantes (rehechos)

**Problema:** Más oscuros (valor medio 0,18-0,33 frente a 0,31-0,45 de los puestos y objetos de la plaza) y más saturados; cada uno con 40 colores propios.

**Acción:** Tono ajustado (más luz, algo menos de saturación) y paleta maestra, desde la misma fuente.

Archivos: `merchant_wagon.png`, `cloth_cart.png`, `potion_stall.png`, `smith_stall.png`, `food_stall.png`, `fortune_tent.png`

## Tejados rojo y naranja (rehechos)

**Problema:** Rojo y naranja planos y muy saturados frente a la pizarra y la teja de madera, con textura y luz.

**Acción:** Saturación y luz contenidas conservando sus propios colores (pasadas por la paleta maestra, el rojo perdía los brillos y quedaba plano).

Archivos: `roof_red.png`, `roof_orange.png`

## Adoquín de la segunda pasada (rehechos)

**Problema:** Piedras borrosas sin contorno (bordes 0,025) y más oscuras que las fachadas; tamaño de piedra irregular. Con el césped clásico de vuelta, desentona más que el adoquín anterior.

**Acción:** Vuelve el adoquín anterior (contornos limpios, como las fachadas). El nuevo queda aquí.

Archivos: `cobble.png`

## Vecinos dibujados a 200 px (pendientes)

**Problema:** Salen de miniaturas de Canva de 200 px usadas píxel a píxel: ruido de píxeles sueltos (0,45-0,58 frente a 0,39 del héroe) y algo más saturados que Mara, Elia o el guardia.

**Acción:** Redibujar a tamaño completo (1024 px o más) con el prompt de art/FUENTES.md y reducir como los demás. Necesita cupo de generación.

Archivos: `caldus.png`, `iven.png`, `lio.png`, `neris.png`, `rhea.png`, `sella.png`, `tovan.png`

## Monstruos dibujados a 200 px (pendientes)

**Problema:** Misma causa: miniaturas de 200 px. Ruido y bordes de distinto grosor que el lobo (fuente Figma de 1024 px).

**Acción:** Redibujar a tamaño completo cuando haya cupo; hasta entonces se mantienen.

Archivos: `cuervo_bruma.png`, `espectro.png`, `espectro_f.png`, `esqueleto.png`, `esqueleto_f.png`, `golem.png`, `golem_f.png`, `guardian_raices.png`, `hongo.png`, `hongo_f.png`, `jabali_espinoso.png`, `murcielago.png`, `murcielago_f.png`, `polilla_luminica.png`, `roedor_bruma.png`, `sporineo.png`

## Puerta de la ciudad (pendientes)

**Problema:** Dibujada en tres cuartos: la torre izquierda más cercana y los tejados en diagonal; se ve torcida frente a la cámara. Además, más ruido que su familia.

**Acción:** Generar una vista de frente (prompt preparado) cuando haya cupo.

Archivos: `town_gate.png`
