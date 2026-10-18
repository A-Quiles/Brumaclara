# Guía de arte de Brumaclara

El modelo visual que deben seguir todos los recursos del juego. La escena de referencia es
`scenes/levels/demo_zone.tscn` (las afueras de Brumaclara); si un recurso nuevo no encaja al lado del
héroe y del lobo de esa escena, no está terminado.

## 1. Objetivo

Fantasía anime en píxel art: mundo 3D en perspectiva elevada de tres cuartos con personajes 2D, en la
línea de lectura visual de los RPG de Nintendo DS como Pokémon Blanco 2 / Negro 2, con diseños propios.
Debe leerse en una captura pequeña: héroe reconocible, profundidad, enemigos distinguibles y magia clara.

## 2. Resolución y cámara

| Elemento | Valor |
|---|---|
| Resolución interna | 640 × 360, escalado entero ×3 a 1920 × 1080, filtrado *nearest* |
| Cámara | lente desplazada: plano de imagen vertical (las verticales se dibujan verticales, como en un píxel art pintado) y ventana desplazada hacia abajo; equivale a mirar unos 27–30° hacia abajo |
| Encuadre | el héroe a ~78 % de la altura de la pantalla, mirando hacia el fondo del escenario |
| Escala | 1 unidad del mundo = 22,3 px a la distancia del héroe; 1 píxel de sprite = 0,0449 unidades |

Todos los sprites están orientados hacia la cámara sin rotar, así sus píxeles salen 1:1 en pantalla.

## 3. Tamaños

| Recurso | Tamaño en pantalla |
|---|---|
| Héroe | 46 px de alto (≈ 2,1 unidades), 2,5 cabezas |
| Lobo de la Fractura | 34 × 48 px |
| Árboles | 60–93 px (1,3–2 veces el héroe) |
| Objetos | barril 25 px, caja 26 px, cofre 30 px, poste 42 px, menhir 53 px, farol 58 px, pozo 59 px |
| Texturas del suelo y muros | 20 texels por unidad (bloque repetible de 109 px = 5,45 unidades) |
| Fachadas | ≈ 15 texels por unidad; la puerta mide lo que el héroe |
| Fondo lejano | 767 × 335 px, a 1 texel por píxel de pantalla |

## 4. Estilo de dibujo

- Contorno oscuro de 1 px en siluetas (casi negro, teñido del color del objeto).
- Luz desde arriba a la izquierda; sombreado *cel* suave de 2–3 tonos por material.
- Sin antialias, sin degradados largos, sin píxeles de tamaños mezclados: un efecto que necesite ser más
  grande se compone de varias piezas a escala 1:1 (el Estallido es un anillo de explosiones), nunca se
  agranda un sprite.
- Fondos y suelos algo apagados; personajes, enemigos y efectos más saturados para que destaquen.
- Un enemigo tiene que destacar sobre el suelo donde vive: si un suelo especial tiene su mismo valor
  (el lobo oscuro sobre la cicatriz de la Fractura), se aclara el suelo, nunca el enemigo.
- La Fractura se reconoce siempre por el violeta (`RIFT` en el pipeline) y las grietas luminosas.
- Cada lugar tiene un elemento propio: la aldea, su pozo, huerto y faroles; el claro de la Fractura, su
  suelo agrietado, la grieta luminosa, el menhir con runas y los cristales.

## 5. Color

Cada familia de recursos tiene su paleta, calculada por el pipeline a partir de sus propias imágenes, y
comparte dos rampas de acento definidas en `tools/art_pipeline/build.py`:

- **FIRE** (fuego): `#fff2a8 #ffc93c #ff8a1c #e2451c`
- **RIFT** (Fractura): `#54309a #7c4ed2 #a67af6 #d6b8ff #f6e8ff`

| Familia | Colores |
|---|---|
| Héroe | 40 + FIRE |
| Lobo | 32 |
| Naturaleza y objetos | 48 + FIRE + RIFT (los cristales usan una paleta propia de 14) |
| Objetos de la aldea y de la Fractura, cofre | 40 + FIRE + RIFT |
| Cada textura de suelo | 20 |
| Fondo lejano | 32 |
| Fachadas y tejados | 24 / 12 |
| Interfaz | 40 + FIRE |
| Efectos | 32 + FIRE |

## 6. Animación

| Animación | Fotogramas | Velocidad |
|---|---|---|
| Héroe: reposo | 1 por dirección | — |
| Héroe: caminar | 4 por dirección | 8 fps |
| Héroe: espada | 4 (preparación, carga, tajo, remate) | 14 fps; golpea en el tercer fotograma |
| Héroe: esquiva | 4 (3 de espaldas) | 14 fps, 0,3 s, invulnerable 0,28 s |
| Héroe: daño / hechizo / derrota | 1 / 1 / 2 | — |
| Lobo: reposo / carrera | 4 / 4 | 6 / 12 fps |
| Lobo: aviso / salto | 1 (0,6 s, ojos y cuerpo brillando) / 3 | — / 10 fps |
| Lobo: caída y disolución | 3 | 5 fps |
| Cofre: cerrado / abriéndose / vacío | 1 / 2 / 1 | — / 6 fps / — |

- Cuatro direcciones; la izquierda es el espejo de la derecha.
- Cada hoja tiene fotogramas del mismo tamaño con los pies en el mismo punto (héroe: 56 × 56 px, pies en
  (28, 53); lobo: 60 × 52 px, pies en (30, 49)), así no hay saltos entre fotogramas.
- El código anima recursos (parpadeo de invulnerabilidad, destello al recibir daño, estelas de la
  esquiva, temblor de cámara, congelación breve en los impactos); no dibuja su aspecto.

## 7. Escenario

- Suelo: bloques 3D con textura arriba y roca en los lados, con contorno oscuro en las aristas; los
  caminos y las manchas (suelo de bosque bajo los árboles, huerto, cicatriz de la Fractura) son franjas
  u óvalos de textura con el borde irregular a píxeles enteros, nunca una línea recta.
- Los objetos que están sobre el suelo, como la grieta de la Fractura, se dibujan antes que los
  personajes para que nadie quede tapado por ellos.
- Fondo lejano: una imagen pintada detrás del mundo (fondo *canvas* del entorno), siempre a 1 texel
  por píxel. Se mueve mucho menos que el mundo, 4 px por unidad que avanza la cámara: de lado, y hacia
  abajo al ir al norte, de modo que las montañas asoman por encima del bosque. La cámara nunca ve el
  horizonte real, así que el fondo solo se ve por encima de los árboles.

## 8. Interfaz

Kit generado con el mismo estilo: panel azul noche con borde dorado (se estira por su centro liso,
nunca por el borde) con las barras de vida, maná y experiencia, iconos de habilidades con su tecla y una
sombra que baja mientras se recargan. Texto con Pixelify Sans a 11 px sin antialias: a ese tamaño cada
píxel de la fuente es un píxel de pantalla (a 12 o 13 px las letras se deforman). La pantalla no se
llena de números: solo daño recibido y causado.

## 9. Cómo se produce un recurso nuevo

1. **Generar** con IA usando la plantilla de prompts de `art/FUENTES.md`: misma frase de estilo, la
   descripción fija del personaje u objeto, rejilla exacta sobre magenta puro y el cierre técnico.
2. **Revisar** la hoja: coherencia entre fotogramas, dirección de cada fila, que nada toque los bordes.
   Lo que no sirva se anota en `art/FUENTES.md` y no se usa.
3. **Procesar** con `python3 tools/art_pipeline/build.py <receta>`: recorta el fondo, reduce cada bloque
   de píxeles de la imagen a un píxel del juego alineándose con su rejilla, ajusta a la paleta, coloca los
   fotogramas sobre su ancla y escribe el `SpriteFrames` de Godot.
4. **Comprobar** en la escena de referencia junto al héroe (`tools/capture/screenshot_tour.gd`): tamaño,
   contraste, paleta y que no haya píxeles de otro tamaño.

## 10. Lista de control

- [ ] ¿Se distingue del fondo y del resto de personajes en una captura pequeña?
- [ ] ¿Su píxel mide lo mismo que el del héroe?
- [ ] ¿Usa la paleta de su familia y los acentos comunes?
- [ ] ¿La luz viene de arriba a la izquierda?
- [ ] ¿Tiene contorno oscuro de 1 px?
- [ ] ¿Sus fotogramas están alineados por los pies y a la velocidad de la tabla?
- [ ] ¿Está registrado en `art/FUENTES.md`?
