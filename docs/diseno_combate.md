# Diseño de combate

Reglas y números del combate del juego final: recursos, atributos, fórmula de daño, estados y roles de
enemigo. Concreta las secciones 10 a 12 del GDD. Los valores marcados **(en juego)** ya están
implementados; el resto es la propuesta de partida, para ajustar jugando. Viven en fichas de datos
(apartado 7), así que cambiar un número no requiere tocar código.

Documentos que lo completan:

- `docs/arbol_habilidades.md`: las **seis afinidades** (fuego, hielo, rayo, sombra, tierra y luz), sus
  árboles de 25 nodos, el tronco común del aventurero, las técnicas de gremio y el sistema de puntos.
- `docs/bestiario.md`: los 53 enemigos, las 8 élites de contrato y los 10 jefes, zona a zona.

## 1. Principios

- **Leer y responder.** Todo ataque enemigo peligroso tiene un aviso visible (y audible cuando haya
  sonido) de al menos 0,4 s. Si el jugador recibe un golpe, debe saber por qué.
- **Ninguna herramienta sirve para todo.** La espada no gasta nada pero obliga a acercarse; la magia
  alcanza lejos pero cuesta maná; la esquiva salva pero tiene recarga.
- **Números pequeños y legibles.** Sin golpes críticos ni variaciones aleatorias de daño: el mismo golpe
  hace siempre el mismo daño, así el jugador aprende cuánto aguanta cada enemigo.
- **Las variantes de color no son enemigos nuevos.** Cada enemigo nuevo aporta un comportamiento.
- **Elegir es renunciar.** Los árboles tienen muchos más nodos de los que se pueden comprar en una
  partida.

## 2. Recursos

| Recurso | Valor | Notas |
|---|---|---|
| Vida | 100 al nivel 1 **(en juego)** | +10 por nivel **(en juego)** y +12 por punto de Vitalidad |
| Maná | 50 al nivel 1 **(en juego)** | +5 por nivel **(en juego)**. Se regenera 5/s **(en juego)** |
| Recargas | Por habilidad **(en juego)** | Evitan repetir la misma habilidad; el maná limita el total |
| Esquiva | Recarga 0,55 s, invulnerable 0,28 s **(en juego)** | Sin coste de maná: es la herramienta básica |
| Pociones | 3 por expedición | Curan el 40 % de la vida en 1 s; se rellenan en la sede y en los puntos de descanso |
| Ranuras | 4 habilidades + la definitiva | Q, E, R y C, y X para la definitiva (F es interactuar); todo reasignable |

Las habilidades consumen **maná y recarga a la vez** (decisión pendiente 6 del GDD, cerrada): el maná
decide cuántas habilidades caben en un combate y la recarga, el ritmo.

## 3. Nivel, atributos y fórmulas

- **Nivel máximo: 40.** La historia principal termina hacia el nivel 32; los contratos de caza y el
  contenido posterior llegan al 40. Experiencia para subir: `60 + 40 × (nivel − 1)` **(en juego)**.
- **Cada nivel:** +10 de vida y +5 de maná automáticos **(en juego)**, 1 punto de atributo y 2 puntos de
  aprendizaje (PA) para los árboles (`docs/arbol_habilidades.md`).

| Atributo | Efecto por punto | Tope útil |
|---|---|---|
| Vitalidad | +12 de vida | — |
| Poder | +4 % de daño de la espada y de los ataques físicos | 25 puntos (+100 %) |
| Control | +4 % de daño mágico y −1 % de coste de maná | 25 puntos |
| Agilidad | −2 % de recarga de esquiva y +1 % de velocidad | 15 puntos |

**Daño de un golpe:**

```
daño = redondear(base × (1 + bonificación del atributo) × afinidad del objetivo × (1 − defensa del objetivo))
```

- `base`: el daño de la ficha de la habilidad o del arma. Espada: 12 **(en juego)**.
- `afinidad del objetivo`: ×1,5 si es débil a ese elemento, ×0,5 si lo resiste, ×1 si no.
- `defensa del objetivo`: entre 0 y 0,6. La del jugador viene del equipo; la del enemigo, de su ficha.
- Mínimo 1 de daño. Sin críticos.

## 4. Estados alterados

Cada afinidad tiene su estado propio; la Fractura añade el Eco.

| Estado | Afinidad | Efecto | Duración | Jefes |
|---|---|---|---|---|
| Quemadura | Fuego | 3 de daño cada 0,5 s | 3 s | Normal |
| Frío | Hielo | −40 % de velocidad; con 3 cargas, congela 1 s | 4 s | Solo ralentiza, nunca congela |
| Marca eléctrica | Rayo | La consumen otras habilidades; 3 marcas provocan una descarga de 10 | 5 s | Normal |
| Marca de sombra | Sombra | Hasta 3 por enemigo; la consumen Desgarro y Drenaje | 8 s | Normal |
| Fisura | Tierra | −20 % de defensa y no puede bloquear; 3 fisuras derriban 1 s | 5 s | No se les derriba |
| Deslumbrado | Luz | Pierde el objetivo 1 s y su siguiente aviso dura el doble | 1 s | Solo alarga el aviso |
| Aturdimiento | Varias | No actúa | 0,8 s | Inmunes 6 s después de cada aturdimiento |
| Eco | Fractura | Repite el último golpe recibido al 30 % a los 1,5 s | Un golpe | Lo aplican los anómalos al jugador |

Cada estado lleva un icono sobre la barra de vida y una señal en el sprite que no depende solo del color
(partículas o parpadeo), como pide el GDD.

## 5. Afinidades

| Afinidad | Papel | Fuerte contra | Débil contra |
|---|---|---|---|
| Fuego | Presión y daño | Flora y bestias | Agua y autómatas con coraza |
| Hielo | Control y supervivencia | Bestias rápidas y agua | Autómatas y criaturas de fuego |
| Rayo | Velocidad y cadenas | Autómatas y agua | Criaturas de tierra |
| Sombra | Engaño y debilitación | Humanos y enemigos con escudo | Luz y anómalos |
| Tierra | Peso, defensa y terreno | Autómatas y corazas | Voladores y agua |
| Luz | Protección, curación y revelación | Anómalos y sombra | Autómatas |

La afinidad principal se elige en el santuario de Brumaclara durante el capítulo 1; las secundarias se
despiertan en santuarios de la campaña. Árboles completos en `docs/arbol_habilidades.md`.

## 6. Enemigos

| Rol | Qué enseña | Ejemplo |
|---|---|---|
| Acechador | Leer el aviso y esquivar a tiempo | Lobo de la Fractura **(en juego)** |
| Bruto | Salir de las áreas marcadas y castigar la recuperación larga | Jabalí espinoso |
| Hostigador | Moverse y cerrar distancias | Cuervo de bruma |
| Protector | Elegir el orden de los objetivos | Guardián de raíces |
| Anómalo | Reglas propias de la Fractura | Polilla lumínica |

Los jefes tienen entre 3 y 5 patrones reconocibles, una ventana de castigo clara y, cuando procede, una
salida narrativa sin combate (calmar al Caparazón de Vigilia, negociar con el Ejecutor, no combatir a
Odrana). Lista completa en `docs/bestiario.md`.

## 7. Fichas de datos (en juego)

- **Habilidades:** `data/skills/<id>.tres`, recurso `SkillData` (`scripts/data/skill_data.gd`): coste,
  recarga, duración del lanzamiento, momento en que sale, daño, empuje, tipo (proyectil o área) y la
  escena del efecto. El héroe lleva una lista de habilidades (`skills` en `player.tscn`); la primera va
  en Q y la segunda en E.
- **Enemigos:** `data/enemies/<id>.tres`, recurso `EnemyData` (`scripts/data/enemy_data.gd`): vida,
  daño y empuje del ataque, velocidades, radios de detección y ataque, duración del aviso, experiencia y
  reaparición. El lobo lee la suya (`data/enemies/wolf.tres`).
- **Cómo añadir una habilidad del mismo tipo:** duplicar una ficha, cambiar sus números y añadirla a la
  lista del héroe. Un tipo nuevo (zona, línea, desplazamiento, mejora, escudo, invocación) necesita
  código una vez.
- `tools/tests/test_data.gd` comprueba que el héroe y el lobo usan los valores de sus fichas.

## 8. Pendiente de validar jugando

1. ¿Es la esquiva demasiado buena sin coste? Si se abusa, subir la recarga a 0,8 s antes de añadirle
   coste de maná.
2. ¿Bastan 5 de maná por segundo? Chispa gasta 8 cada 0,45 s (17,8/s), así que con la regeneración
   actual vacía el maná en unos 4 s de uso continuo.
3. ¿Los 110 PA de una partida bastan para que se note cada nivel? Si no, subir a 3 PA por nivel en
   lugar de abaratar los nodos.
4. ¿Los atributos se notan? Si no, dejar solo los árboles y subir vida y maná automáticamente.
