# Fuentes del arte

Registro de cada imagen de origen del juego: con qué se hizo, cuándo y con qué indicación (prompt).
Las imágenes en bruto están en `art/ai/` (Godot no las importa: la carpeta `art/` tiene `.gdignore`).
`tools/art_pipeline/build.py` las convierte en los recursos del juego en `assets/`.

- **Herramienta:** generación de imágenes de Figma AI (archivos «Brumaclara — Arte del juego» y
  «Brumaclara — Arte del juego (escenario)» del autor).
- **Modelo:** `gemini-3.1-flash-image`, 1024 × 1024 px (el fondo lejano, 1584 × 672 px).
- **Fecha:** 18 de octubre de 2026.
- **Autoría y licencia:** generadas a petición del autor del proyecto para uso propio, comercial incluido;
  no reproducen personajes, mapas ni recursos de otros juegos (la referencia a Pokémon Blanco 2 / Negro 2
  es solo de estilo de lectura visual, como indica el GDD).

## Plantilla de los prompts

Todas las hojas repiten las mismas piezas para que el estilo no cambie entre imágenes:

1. *«Pixel art … for an original top-down action RPG, in the overworld sprite style of Nintendo DS RPGs
   like Pokemon Black 2 and White 2 (original …)»*.
2. La descripción fija del personaje u objeto (la del héroe se copia literalmente en cada hoja).
3. La rejilla exacta (*«an exact grid of 4 rows and 4 columns of equal square cells on a flat solid pure
   magenta (#FF00FF) background»*) y qué va en cada fila.
4. El cierre técnico: *«Crisp hard-edged pixels, clean dark outline, limited palette, soft cel shading lit
   from the top left, no anti-aliasing, no ground shadow, no text, no grid lines.»*

## Imágenes

| Archivo | Contenido | Notas de revisión |
|---|---|---|
| `hero_walk.png` | Héroe: caminar de frente y de lado (4 fotogramas). | Las filas 3 y 4 salieron incoherentes: no se usan (la derecha es el espejo de la izquierda; la espalda viene de `hero_actions`). |
| `hero_actions.png` | Caminar de espaldas; ataque con espada de frente, de lado (mira a la derecha) y de espaldas. | Todo aprovechable. |
| `hero_extra.png` | Esquiva de frente, de lado y de espaldas; daño, derrota y lanzar hechizo. | El 4.º fotograma de la esquiva de espaldas mira de lado: se descarta. |
| `wolf.png` | Lobo de bruma: reposo, carrera, ataque (aviso, salto, mordisco) y caída/disolución. | Las filas 3 y 4 miran a la derecha y las 1 y 2 a la izquierda: el pipeline las iguala. |
| `vfx.png` | Proyectil de fuego, explosión, chispa de impacto, polvo y orbe de experiencia. | El último fotograma de la chispa es casi invisible: se descarta. |
| `terrain_a.png` | Hierba, camino de tierra, adoquines y muro de roca. | El pipeline las hace repetibles sin costuras y quita la mancha clara grande de la hierba. |
| `trees.png` | Roble, abeto, árbol joven y árbol muerto con cristales de la Fractura. | — |
| `props.png` | 16 objetos: arbustos, flores, hierba alta, rocas, tocón, setas, valla, poste indicador, tablón de anuncios, farol, barril, caja, cristal de la Fractura y cofre. | El halo rosa del farol se recorta con una tolerancia mayor. |
| `house.png` | Fachada con hastial, pared lateral, tejas naranjas y tejas de pizarra. | El lateral se recorta a sus dos plantas inferiores. |
| `ui.png` | Panel, barras (vacía, vida, maná, experiencia), iconos de habilidades, poción y moneda. | La fila superior del panel es su contorno mezclado con el magenta: se sustituye por el contorno inferior y su borde dorado desvaído toma el dorado del lateral. El relleno dorado se recorta a su parte llena. |
| `backdrop.png` | Fondo lejano: cielo con nubes, montañas nevadas, colinas y bosque lejano. | Se reduce con píxeles de 2 y se hace repetible solo en horizontal. |
| `terrain_b.png` | Pradera con flores, suelo de bosque, suelo de la Fractura y huerto. | La pradera no se usa (las flores quedan en motas de un píxel). Al suelo de bosque se le quitan las manchas grandes; el suelo apagado de la Fractura se aclara hacia gris ceniza para que los lobos destaquen encima, sin tocar grietas ni cristales. |
| `props_b.png` | Pozo, carro de heno, leña, banco, jardinera, paca, sacos, cubo, cristales grandes de la Fractura, grieta de la Fractura, zarza corrupta, menhir con runas y el cofre en cuatro estados. | Todo aprovechable. El cofre sustituye al de `props.png` para que sus fotogramas (cerrado, abriéndose, abierto, vacío) sean el mismo dibujo. |

### Prompt del héroe (descripción fija)

> The same hero in every cell: young anime adventurer, spiky swept royal-blue hair with a long fringe, dark
> crimson scarf wrapped around the neck, crimson cape reaching the knees, blue short-sleeved tunic, brown
> leather bracers, brown leather strap diagonally across the chest, brown belt with a small silver buckle,
> dark grey trousers, brown leather boots, a steel short sword with a brown grip. About 2.5 heads tall.

### Prompt del lobo (descripción fija)

> A feral wolf corrupted by a magical rift, dark slate-blue and charcoal fur, glowing violet crack lines
> across its body, a few jagged violet crystal shards growing from its shoulders and spine, glowing violet
> eyes, sharp white fangs.

### Prompts completos del escenario

`backdrop.png` (pedido a 2048 × 878):

> Wide panoramic pixel art background for an original fantasy action RPG, in the bright colourful
> overworld style of Nintendo DS RPGs like Pokemon Black 2 and White 2 (original scenery, not copied from
> any game). A distant landscape layer that will be seen far behind a forest: the upper half is a clear
> light cyan-blue sky with a few soft white cumulus clouds drawn with simple flat cel shading; the lower
> half is a long range of distant blue-violet mountains with small snowy peaks, pale and hazy with
> distance, then gentle blue-green rolling hills with tiny far-away trees, and along the bottom edge a
> continuous band of distant forest canopy in muted green. Flat front view, no foreground ground, no
> buildings, no characters, no sun. The scene continues seamlessly off the left and right edges. Small
> crisp square pixels of one consistent size, limited palette, no anti-aliasing, no smooth gradients, no
> text, no frame or border.

`terrain_b.png`:

> Pixel art ground textures for an original top-down action RPG, in the overworld tile style of Nintendo
> DS RPGs like Pokemon Black 2 and White 2 (original, not copied from any game). An exact grid of 2 rows
> and 2 columns of equal square cells; each cell is completely filled edge to edge with one seamless
> tileable texture seen from directly above, with no border, no frame and no gaps: top left, a bright
> green meadow of short grass with many tiny white, yellow and pink wildflowers spread evenly; top right,
> a shady forest floor of dark green grass and moss with fallen brown and orange leaves, small twigs and a
> few pebbles; bottom left, ground corrupted by a magical rift: dark grey-violet cracked earth with thin
> glowing violet cracks, small violet crystal shards and a few withered grass tufts; bottom right, a
> vegetable garden bed of dark brown tilled soil in straight horizontal furrows with neat rows of small
> green lettuce and cabbage sprouts. Even lighting from the top left, no large light or dark blotches.
> Crisp hard-edged pixels, limited palette, soft cel shading, no anti-aliasing, no text, no grid lines.

`props_b.png`:

> Pixel art props for an original top-down action RPG, in the overworld sprite style of Nintendo DS RPGs
> like Pokemon Black 2 and White 2 (original, not copied from any game), each object seen from a high
> three-quarter view from the front. An exact grid of 4 rows and 4 columns of equal square cells on a flat
> solid pure magenta (#FF00FF) background, one object centred in each cell, nothing touching the cell
> edges. Row 1: a round stone village well with a small wooden shingle roof and a wooden bucket; a wooden
> hand cart loaded with hay; a neat stack of chopped firewood logs; a simple wooden bench. Row 2: a long
> wooden flower planter box with red and yellow flowers; a round hay bale; a pile of three tied cloth grain
> sacks; a wooden water bucket. Row 3: a large cluster of glowing violet rift crystals; a glowing violet
> magical crack torn open in the ground with tiny floating shards; a thorny bramble bush corrupted by the
> rift with violet glowing thorns; an old cracked standing stone with faint glowing violet runes. Row 4:
> the same small wooden treasure chest with iron bands and a gold lock in four states: closed; lid half
> open with a golden glow; lid fully open showing gold coins inside; lid fully open and empty. Crisp
> hard-edged pixels, clean dark outline, limited palette, soft cel shading lit from the top left, no
> anti-aliasing, no ground shadow, no text, no grid lines.
