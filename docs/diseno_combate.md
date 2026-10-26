# Diseño de combate, habilidades y monstruos (Fase 3)

Concreta en reglas y números lo que el GDD deja abierto (secciones 10, 11 y 12). Los valores marcados
**(en juego)** ya están implementados; el resto es una propuesta para probar y ajustar jugando. Las
habilidades y los enemigos se guardan como fichas de datos (ver el apartado 9), así que cambiar un número
no requiere tocar código.

Regla de alcance del GDD: el prototipo solo implementa **fuego**. Hielo, rayo y sombra quedan diseñados
en papel hasta validar que el combate base es divertido.

## 1. Principios

- **Leer y responder.** Todo ataque enemigo peligroso tiene un aviso visible (y, cuando haya sonido,
  audible) de al menos 0,4 s. Si el jugador recibe un golpe, debe saber por qué.
- **Ninguna herramienta sirve para todo.** La espada no gasta nada pero obliga a acercarse; la magia
  alcanza lejos pero cuesta maná; la esquiva salva pero tiene recarga.
- **Números pequeños y legibles.** Sin golpes críticos aleatorios ni variaciones de daño: el mismo golpe
  hace siempre el mismo daño, así el jugador aprende cuánto aguanta cada enemigo.
- **Las variantes de color no son enemigos nuevos.** Cada enemigo nuevo aporta un comportamiento.

## 2. Recursos

| Recurso | Valor | Notas |
|---|---|---|
| Vida | 100 al nivel 1 **(en juego)** | +10 por nivel (en juego) y +12 por punto de Vitalidad (propuesta) |
| Maná | 50 al nivel 1 **(en juego)** | +5 por nivel (en juego). Se regenera 5/s **(en juego)**, sin pausa tras gastar |
| Recargas | Por habilidad **(en juego)** | Evitan repetir la misma habilidad; el maná limita el total |
| Esquiva | Recarga 0,55 s, invulnerable 0,28 s **(en juego)** | Sin coste de maná: es la herramienta básica |
| Pociones | 3 por expedición (propuesta) | Curan 40 % de la vida en 1 s; se rellenan en la sede y en puntos de descanso |

Decisión (GDD 21.6): las habilidades consumen **maná y recarga a la vez**. El maná decide cuántas
habilidades caben en un combate; la recarga, el ritmo.

## 3. Atributos, nivel y fórmulas

- **Nivel máximo:** 30. Experiencia para subir: `60 + 40 × (nivel − 1)` **(en juego)**.
- **Cada nivel:** +10 vida y +5 maná automáticos **(en juego)**, 1 punto de atributo y, en los niveles
  pares, 1 punto de talento (15 en total para 20 talentos: hay que elegir).

| Atributo | Efecto por punto | Tope útil |
|---|---|---|
| Vitalidad | +12 vida | — |
| Poder | +4 % daño de la espada y de los ataques físicos | 20 puntos (+80 %) |
| Control | +4 % daño mágico y −1 % coste de maná | 20 puntos |
| Agilidad | −2 % recarga de esquiva y +1 % velocidad | 15 puntos |

**Daño de un golpe:**

```
daño = redondear(base × (1 + bonificación del atributo) × afinidad del objetivo × (1 − defensa del objetivo))
```

- `base`: el daño de la ficha de la habilidad o del arma. Espada 12 **(en juego)**.
- `afinidad del objetivo`: ×1,5 si es débil a ese elemento, ×0,5 si lo resiste, ×1 si no.
- `defensa del objetivo`: entre 0 y 0,6. Viene del equipo (jugador) o de la ficha (enemigo).
- Mínimo 1 de daño. Sin críticos.

## 4. Afinidades

El jugador elige una al empezar (GDD 7.2). Las dos primeras habilidades vienen con la afinidad; las
otras tres se desbloquean con **maestría**: hitos concretos, no repeticiones (por ejemplo, «derrota a
tres enemigos con quemadura activa»).

### Fuego — presión y daño (en juego)

| Habilidad | Tipo | Coste | Recarga | Daño | Efecto | Estado |
|---|---|---|---|---|---|---|
| Chispa | Proyectil rápido | 8 | 0,45 s | 18 | Estalla al primer impacto | **En juego** |
| Estallido | Anillo alrededor del héroe | 25 | 4 s | 30 | Empuja fuerte; congela el juego un instante al acertar | **En juego** |
| Rastro ardiente | Zona en el suelo, 3 s | 20 | 6 s | 6/0,5 s | Quemadura a quien la pise | Maestría 1 |
| Ascua viva | Mejora | 15 | 8 s | — | El siguiente golpe de espada hace +100 % y quema | Maestría 2 |
| Ruptura ígnea | Línea de explosiones | 45 | 14 s | 60 | Se canaliza 0,5 s (interrumpible) | Maestría 3 |

### Hielo — control y supervivencia (en papel)

| Habilidad | Coste | Recarga | Daño | Efecto |
|---|---|---|---|---|
| Aguja de escarcha | 8 | 0,5 s | 14 | Aplica frío |
| Suelo helado | 20 | 6 s | — | Zona de 3 s que ralentiza un 40 % |
| Barrera cristalina | 20 | 10 s | — | Bloquea el siguiente golpe en 2 s |
| Prisión breve | 30 | 12 s | 10 | Inmoviliza 1,5 s a enemigos pequeños; interrumpe cargas |
| Fractura glacial | 40 | 10 s | 55 | ×2 contra objetivos con frío; quita el frío |

### Rayo — velocidad y encadenamiento (en papel)

| Habilidad | Coste | Recarga | Daño | Efecto |
|---|---|---|---|---|
| Descarga | 6 | 0,35 s | 10 | Marca eléctrica |
| Salto voltaico | 18 | 4 s | 16 | Salta a 3 enemigos a menos de 4 unidades |
| Paso relámpago | 15 | 3 s | 12 | Desplazamiento de 4 unidades que daña al pasar |
| Sobrecarga | 25 | 15 s | — | +25 % velocidad y −25 % recargas durante 5 s |
| Convergencia | 40 | 12 s | 20 + 15 por marca | Consume las marcas eléctricas |

### Sombra — engaño y debilitación (en papel)

| Habilidad | Coste | Recarga | Daño | Efecto |
|---|---|---|---|---|
| Dardo umbrío | 8 | 0,5 s | 12 | Marca de sombra (hasta 3 por enemigo) |
| Velo | 15 | 8 s | — | 1,5 s invisible: los enemigos pierden el rastro |
| Eco oscuro | 20 | 6 s | — | El siguiente ataque se repite al 50 % sobre objetivos marcados |
| Drenaje | 0 | 5 s | 8 | Recupera 6 de maná por marca del objetivo |
| Desgarro | 35 | 10 s | 15 por marca | Consume las marcas |

## 5. Árbol de talentos

Cuatro ramas de cinco talentos (GDD 12.3). Cada talento pide el anterior de su rama, salvo el primero.
Todos cambian algo visible.

| Rama | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| **Ofensiva** | Filo templado: el 3.er golpe del combo hace +50 % | Castigo: +30 % de daño a enemigos que acaban de fallar un ataque | Impulso: tras esquivar, el siguiente golpe en 1 s hace +40 % | Presión: cada golpe de espada reduce 0,3 s las recargas de magia | Remate: +50 % de daño a enemigos con menos del 25 % de vida |
| **Control** | Golpe pesado: el 3.er golpe del combo empuja el doble | Estados largos: estados alterados +40 % de duración | Interrupción: la espada interrumpe avisos de enemigos pequeños | Zona propia: las zonas de habilidad duran +50 % | Afinidad profunda: las habilidades de la afinidad aplican su estado siempre |
| **Supervivencia** | Piel curtida: +15 % de vida | Segundo aliento: una vez por combate, a 1 de vida durante 1 s en lugar de caer | Esquiva limpia: esquivar justo antes de un golpe devuelve 10 de maná | Pociones dobles: 4 pociones y curan más rápido | Último recurso: bajo el 30 % de vida, −20 % de daño recibido |
| **Utilidad** | Ojo de rastreador: ves la vida de los enemigos sin golpearlos | Bolsillos: +1 hueco de consumible | Paso ligero: +10 % de velocidad fuera de combate | Botín atento: +1 objeto en los cofres | Recarga rápida: −15 % a todas las recargas |

## 6. Técnicas de gremio

Al afiliarse (GDD 8.7) se abre un árbol pequeño de tres técnicas, una por rango de gremio. Refuerzan la
filosofía de cada uno, no la afinidad.

| Gremio | Rango 1 | Rango 2 | Rango 3 |
|---|---|---|---|
| **Faro** (protección) | Escudo de vigía: bloqueo de 0,5 s con recarga de 6 s | Botiquín del Faro: las pociones también quitan estados | Señal de rescate: una vez por zona, vuelve al último punto seguro con la vida llena |
| **Brasa** (riesgo y movilidad) | Embestida: la esquiva daña 8 al atravesar enemigos | Sin red: +20 % de daño con menos del 50 % de vida | Carga de caldera: mantener ataque 0,8 s hace un tajo que avanza 3 unidades |
| **Archivo** (conocimiento) | Lectura de la Fractura: ves el aviso de los enemigos 0,2 s antes | Catalizador: +20 maná máximo y +1/s de regeneración | Contención: los enemigos anómalos reciben +40 % de daño |
| **Liga** (rutas y comercio) | Contactos: −15 % de precios | Trampa de caravanero: coloca un cepo (inmoviliza 2 s, 2 cargas) | Ruta segura: los viajes entre sedes no tienen encuentros y recuperas las pociones |

## 7. Estados alterados

| Estado | Efecto | Duración | Jefes |
|---|---|---|---|
| Quemadura | 3 de daño cada 0,5 s | 3 s | Normal |
| Frío | −40 % de velocidad; con 3 aplicaciones, congela 1 s | 4 s | Solo ralentiza, nunca congela |
| Aturdimiento | No actúa | 0,8 s | Inmunes 6 s después de cada aturdimiento |
| Marca eléctrica | La consume Convergencia; 3 marcas = descarga de 10 | 5 s | Normal |
| Eco (Fractura) | Repite el último golpe recibido al 30 % a los 1,5 s | Un golpe | Lo aplican los enemigos anómalos al jugador |

Cada estado lleva un icono sobre la barra de vida y un tinte en el sprite (nunca solo color: también
partículas o parpadeo).

## 8. Enemigos

### Roles (GDD 10.9)

| Rol | Qué enseña | Ejemplo |
|---|---|---|
| Acechador | Leer el aviso y esquivar a tiempo | Lobo de la Fractura **(en juego)** |
| Bruto | Salir de las áreas marcadas y castigar la recuperación larga | Jabalí de cantera |
| Hostigador | Moverse y cerrar distancias | Sporíneo |
| Protector | Elegir el orden de los objetivos | Guardián de raíces |
| Anómalo | Reglas propias de la Fractura | Eco errante |

### Bestiario por zona

Vida y daño a nivel de la zona; los números se ajustan jugando. «Aviso» es la señal que permite
reaccionar.

**Afueras de Brumaclara (nivel 1–3)**

| Enemigo | Rol | Vida | Daño | Comportamiento | Aviso | Débil / resiste |
|---|---|---|---|---|---|---|
| Lobo de la Fractura **(en juego)** | Acechador | 40 | 14 | Vigila su guarida, persigue, salta en línea recta y queda abierto 0,8 s | Brillo violeta 0,6 s | — / — |
| Jabalí espinoso | Bruto | 70 | 20 | Carga en línea recta y se estrella contra muros (aturdido 1,5 s) | Escarba el suelo 0,8 s | Fuego / — |
| Cuervo de bruma | Hostigador | 20 | 8 | Vuela en círculos y se lanza en picado | Grito y pausa en el aire 0,5 s | Rayo / Sombra |

*Jefe:* **Madre de la manada.** Loba grande que llama a dos lobos, salta dos veces seguidas y, bajo el
50 % de vida, abre grietas que hay que rodear. Tres patrones, como pide el MVP.

**Bosque de los Susurros (nivel 4–7)**

| Enemigo | Rol | Vida | Daño | Comportamiento | Aviso | Débil / resiste |
|---|---|---|---|---|---|---|
| Sporíneo | Hostigador | 30 | 10 | Seta que dispara esporas en abanico y se entierra si te acercas | Se hincha 0,6 s | Fuego / Hielo |
| Guardián de raíces | Protector | 90 | 12 | Levanta un muro de raíces que protege a los enemigos de detrás | Las raíces brotan 0,7 s antes | Fuego / Rayo |
| Polilla lumínica | Anómalo | 25 | 6 | Aplica eco; se divide en dos si recibe magia | Polvo brillante | Espada / Magia |

*Jefe:* **El Árbol que susurra.** Fijo en el centro; sus raíces barren zonas marcadas y sus esporas
crean Sporíneos.

**Cantera Vieja (nivel 8–12)**

| Enemigo | Rol | Vida | Daño | Comportamiento | Aviso | Débil / resiste |
|---|---|---|---|---|---|---|
| Jabalí de cantera | Bruto | 140 | 28 | Golpe de área en círculo | Círculo de polvo 0,9 s | Hielo / Fuego |
| Gólem de escombro | Protector | 200 | 22 | Lento; recoge rocas y se blinda (defensa 0,6 hasta que se le rompe la coraza) | Se agacha 1 s | Rayo / Espada |
| Minero perdido | Acechador | 60 | 18 | Humano alterado; finta antes del golpe real | Levanta el pico dos veces | — / — |

**Ruinas del Umbral, Paso de la Tormenta y Santuario Hundido (nivel 13–30).** Se diseñan al llegar a
la Fase 6. Cada zona añade un comportamiento nuevo y una variante de uno conocido; la idea guía de cada
una es: ruinas = enemigos anómalos y trampas mágicas; paso = viento que empuja proyectiles y enemigos
voladores; santuario = enemigos que se esconden bajo el agua.

## 9. Fichas de datos (en juego)

- **Habilidades:** `data/skills/<id>.tres`, recurso `SkillData` (`scripts/data/skill_data.gd`): coste,
  recarga, duración del lanzamiento, momento en que sale, daño, empuje, tipo (proyectil o área) y la
  escena del efecto. El héroe lleva una lista de habilidades (`skills` en `player.tscn`); la primera va
  en Q y la segunda en E.
- **Enemigos:** `data/enemies/<id>.tres`, recurso `EnemyData` (`scripts/data/enemy_data.gd`): vida,
  daño y empuje del ataque, velocidades, radios de detección y ataque, duración del aviso, experiencia y
  reaparición. El lobo lee la suya (`data/enemies/wolf.tres`).
- **Cómo añadir una habilidad del mismo tipo:** duplicar una ficha, cambiar sus números y añadirla a la
  lista del héroe. Un tipo nuevo (zona, mejora, canalización) sí necesita código una vez.
- `tools/tests/test_data.gd` comprueba que el héroe y el lobo usan los valores de sus fichas.

## 10. Pendiente de validar jugando

1. ¿Es la esquiva demasiado buena sin coste? Si se abusa, subir la recarga a 0,8 s antes de añadirle
   coste de maná.
2. ¿Bastan 5 de maná por segundo? Con la regeneración actual, Chispa se puede lanzar casi sin parar
   (8 de coste cada 0,45 s gasta 17,8/s, así que vacía el maná en unos 4 s).
3. ¿Se elige la afinidad en el creador de personaje o en la primera hora de juego (por ejemplo, en un
   santuario de Brumaclara)? Recomendación: en el juego, para que sea una decisión con contexto.
4. Talentos frente a atributos: si los atributos no se notan, dejar solo talentos y subir la vida y el
   maná automáticamente.
