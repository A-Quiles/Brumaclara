# Cómo seguir sin generar sprites para todo, y cómo mantener el pixelado coherente

Notas de producción (29 de octubre de 2026). Resumen de lo que hacen los equipos pequeños de pixel art y
de lo que ya aplica GUILD ZERO o puede aplicar a partir de ahora.

## 1. Necesitar menos dibujos

**Variantes por código, no por dibujo.** Un dibujo base y muchas versiones: recolorear por grupos de color
(*palette swap*), escalar o añadir un brillo. GUILD ZERO ya lo hace:
- los 9 lobos de colores salen de un único lobo (`wolf_variants`);
- caballos, carretas y toldos cambian de pelaje o tela (`recolors`);
- el creador de personaje pinta pelo, piel, ropa y cuero con una máscara (`hero_look.gd`);
- los efectos de las seis afinidades salen del de fuego (`affinity_fx`).

Siguiente paso posible: monstruos «élite» y de zonas posteriores como recoloreados con una regla nueva de
comportamiento (el bestiario ya exige que una variante cambie la regla, no solo el color).

**Personajes por capas (*paper doll*).** En vez de una hoja por peinado y ropa, se dibuja el cuerpo una vez
y encima van capas que siguen sus fotogramas: pelo, ropa, arma. Es lo que hace el generador
[Universal LPC](https://github.com/makrohn/Universal-LPC-spritesheet), con miles de combinaciones a partir de
pocas piezas. Para GUILD ZERO bastaría con dibujar el pelo como capa aparte (3 vistas × fotogramas) en lugar
de redibujar el personaje entero. Es la mejora que más sprites ahorraría en el creador.

**Efectos sin sprites.** Partículas, anillos, destellos de luz y sombras los dibuja el motor. Las habilidades
nuevas ya funcionan así (`scripts/effects/vfx.gd`): no hizo falta generar ni una imagen para que los 268 poderes
tengan efecto propio por afinidad.

**Animación por código.** Respiración, balanceo al andar, aplastar y estirar, temblores, desvanecidos y el
agua de la fuente se hacen con *tweens*, shaders o partículas sobre un dibujo quieto. Se dibujan solo los
fotogramas que cambian la silueta (andar, atacar).

**Reutilizar con intención.** Tiles y texturas que se repiten sin que se note (texturas grandes, bordes
irregulares, objetos que tapan juntas), decorados compuestos de piezas (las casas ya se componen de
fachadas, tejados, buhardillas y chimeneas) y el modo edición para colocar en el juego lo que ya existe.

**Packs con licencia libre o de pago.** Muchos equipos compran o usan packs (itch.io, OpenGameArt) y dedican el
arte propio a lo que da identidad: protagonistas, jefes y edificios principales. Hay que elegir packs con el
mismo tamaño de píxel y pasarlos por la paleta del juego (ver abajo).

**Pedir hojas, no sueltos, y editar en vez de generar.** Con IA rinde más pedir una hoja de 4×4 que 16
imágenes, y editar una hoja aprobada (como los peinados de esta tanda) que generar de cero: mantiene ropa,
poses y estilo.

## 2. ¿Se integra bien todo visualmente?

Revisión con las capturas actuales. El juego se dibuja a **640 × 360** y se amplía por múltiplos enteros, así
que un píxel del juego siempre ocupa el mismo cuadrado de pantalla. Lo que cambia entre piezas es cuánto
detalle cabe en cada píxel:

| Pieza | Píxeles por unidad del mundo | Cómo se ve |
|---|---|---|
| Personajes, objetos, edificios, interiores | 22,3 (`pixel_size 0.0449`) | Referencia. |
| Suelo exterior (césped, adoquín, tierra) | 20 | Casi igual: bien. |
| Fondo lejano (cielo, montañas) | dibujado en pantalla con píxeles dobles | Más grueso a propósito: se lee como lejano. |
| Explosiones escaladas, partículas | variable | Una explosión «grande» tiene píxeles más gordos. |
| Textos 3D (nombres, carteles) | suaves | No son pixel art. |

**Lo que sí desentona y por qué:**
1. **Densidad de detalle distinta según la fuente.** El arte de Figma se redujo mucho (5 píxeles de origen por
   píxel del juego) y queda «gordo» y limpio; parte del de Canva trae detalle muy fino y, al reducirlo,
   deja ruido de píxeles sueltos que parece menos pixel art. Es lo que notas como «unas más pixeladas que
   otras».
2. **Las texturas nuevas de suelo se vieron un rato a la mitad de tamaño** (40 píxeles por unidad) hasta que
   se ajustó su escala: ya están a 20.
3. **El suelo está tumbado y la cámara lo ve en diagonal**, así que sus píxeles se ven aplastados en vertical
   frente a los sprites, que están de pie. Es normal en 2.5D y apenas se nota con texturas de detalle medio.
4. **Paletas distintas por hoja.** Cada hoja tiene su propia paleta reducida; dos hojas de días distintos
   pueden tener verdes o sombras que no casan.

**Qué haría para que quede «algo pixelado, pero no descarado»** (orden de impacto):
1. **Una paleta maestra del juego** (unos 64 colores) y pasar todo el arte por ella en el pipeline. Es lo que
   más unifica y no requiere dibujar nada.
2. **Una regla de densidad de detalle:** reducir cada fuente hasta que sus detalles más pequeños midan 2
   píxeles del juego (quitar el píxel suelto) y añadir el contorno oscuro de 1 píxel en todo lo que esté de pie.
3. **Explosiones y partículas a tamaño de píxel fijo** (crecer añadiendo píxeles, no agrandándolos).
4. **Textos 3D con la fuente pixel del HUD**.

Los puntos 1 y 2 se pueden hacer en `tools/art_pipeline` cuando quieras: rehacen todos los assets desde las
fuentes en `art/ai/` sin generar nada nuevo.

## Fuentes

- [Universal LPC Spritesheet (capas de personaje)](https://github.com/makrohn/Universal-LPC-spritesheet)
- [Universal Sprite Sheet Character Creator — GameFromScratch](https://gamefromscratch.com/universal-sprite-sheet-character-creator/)
- [Customizable palettes add simple variety to your game's characters — Envato Tuts+](https://code.tutsplus.com/customizable-palettes-add-simple-variety-to-your-games-characters--gamedev-1846t)
- [Mini rant: stop using mixels — Flowlab community](https://community.flowlab.io/t/mini-rant-stop-using-mixels/38287)
- [Canvas size, pixel size, resolution and PPU — Aseprite community](https://community.aseprite.org/t/canvas-size-pixel-size-resolution-and-ppu/8668)
- [Pixel Art Resolution Guide — Pixnote](https://pixnote.net/en/learn/resolution)
- [Texel Density Basics — RebusFarm](https://rebusfarm.net/blog/texel-density-basics-every-artist-should-know)
- [How does one create flexible pixel art? — GameDev.net](https://gamedev.net/forums/topic/660334-how-does-one-create-flexible-pixel-art/5176499/)
