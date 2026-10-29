# Modo edición

Una herramienta de desarrollo dentro del propio juego para decorar los niveles a mano: colocar objetos
de una paleta con todos los sprites del juego, moverlos, girarlos, cambiarles el tamaño o borrarlos y
pintar los caminos del pueblo. Se juega con los cambios en cuanto se sale del modo.

![Colocando un banco](screenshots/12_edicion_colocar.png)

## Uso

1. Ejecuta el juego desde Godot (F5).
2. Pulsa **M** en cualquier nivel: el juego se pausa, la cámara queda libre y aparece el
   panel.
3. Cambia lo que quieras. **Todo se guarda solo** en cuanto lo haces.
4. Pulsa **M** otra vez y sigues jugando con el nivel tal como lo has dejado.

**H** muestra la hoja de ayuda dentro del juego.

| Acción | Teclas |
|---|---|
| Mover la cámara | WASD (y las flechas si no hay nada seleccionado) · arrastrar en un hueco o con el botón central |
| Zoom | Rueda del ratón |
| Colocar | Elige un objeto en el panel y haz clic en el mundo; se pueden colocar varios seguidos · clic derecho o Esc para soltarlo |
| Seleccionar / mover | Clic en un objeto · arrastrar · flechas para ajustar (Mayús: pasos grandes) |
| Girar | **R** / Mayús+R: cambia a la vista dibujada para esa dirección (o al espejo) · edificios: 90° · Alt+R: 15° |
| Otro modelo | **V** (caballo pastando, tumbado…) |
| Espejo | **F** |
| Tamaño | **Q** / **E** (o Ctrl+rueda) · **0** vuelve al tamaño original |
| Subir / bajar | Re Pág / Av Pág |
| Sólido o atravesable | **C** |
| Duplicar | Ctrl+D (aparece bajo el cursor) |
| Usarlo para colocar más | Ctrl+C |
| Borrar | Supr |
| Deshacer / rehacer | Ctrl+Z / Ctrl+Y (también recupera lo borrado) |
| Rejilla de 0,5 | G |
| Ver a través de los edificios | B |
| Pincel de caminos | **P** · 1 adoquín · 2 tierra · 3 huerto · 4 bosque · clic derecho: hierba · Q/E grosor |
| Llevar al héroe al cursor | T |
| Ocultar el panel | Tab |
| Releer las carpetas de sprites | Ctrl+R |

Se pueden editar los objetos y la vegetación, los edificios (moverlos, girarlos, cambiarles el tamaño,
duplicarlos o borrarlos) y los personajes y criaturas (moverlos y duplicarlos). El pincel de caminos
solo funciona en Brumaclara, que es el único nivel con el suelo pintado.

## Dónde se guarda

Cada nivel guarda sus cambios en `data/edits/<nivel>.json`: los objetos movidos, borrados, añadidos y
copiados, y los caminos pintados. Al cargar el nivel, `scripts/systems/level_edits.gd` los aplica, así
que la escena del nivel nunca se reescribe. Si regenero el pueblo con mi script, tus cambios se
siguen aplicando. Cada objeto se reconoce por su lugar en la escena y por dónde estaba. Si algo que
cambiaste ya no existe, su cambio se conserva en el archivo sin aplicarse, para no perder nada.

La primera vez que se guarda en cada sesión se hace una copia del archivo anterior,
`<nivel>.json.bak`, que no se sube al repositorio.

**Para que yo vea tus cambios**, sube `data/edits/` al repositorio (commit y push) o adjúntame el
archivo.

## Sprites nuevos

La paleta lee las carpetas de sprites cada vez que se abre el modo. Si añades imágenes con el juego
abierto, pulsa Ctrl+R para que aparezcan.

| Pestaña | Carpeta | Qué espera |
|---|---|---|
| Objetos | `assets/environment/props` | Sprites ya procesados por el pipeline |
| Naturaleza | `assets/environment/nature` | Ídem |
| Nuevos | `assets/nuevos` | **Cualquier imagen**: directamente de una IA, de cualquier tamaño y con fondo liso |

Las imágenes se adaptan solas:

- **Fondo.** Se quita el color liso del borde (magenta, blanco, verde…). Los bordes se separan del
  fondo para que no quede un halo de color.
- **Tamaño de píxel.** Se mide el tamaño de los bloques de píxeles de la imagen y se reduce para que
  cada bloque sea un píxel del juego. Si no se puede medir, se deja en 48 píxeles de alto. Cualquier
  imagen de más de 256 píxeles de alto se trata igual, esté en la carpeta que esté.
- **Al cambiar el tamaño** (Q/E), la imagen se vuelve a dibujar a la nueva medida en lugar de
  estirarse. Así sus píxeles siguen midiendo lo mismo que los del resto del juego.
- **Sombra, colisión y luz.** Cada objeto recibe una sombra en el suelo y una colisión a su medida. Los
  objetos planos (flores, grietas) no tienen ni sombra ni colisión. Los faroles, lámparas y antorchas
  dan luz.
- **Prefab.** Si ya existe un prefab con ese nombre, se usa su colisión, su sombra y su luz.

### Nombres de los archivos: vistas y modelos

| Nombre | Significado |
|---|---|
| `banco.png` | El objeto tal como está dibujado, mirando a la cámara |
| `banco__e.png` | El mismo objeto mirando hacia otra dirección de la pantalla: `s` (hacia la cámara), `sw`, `w`, `nw`, `n` (de espaldas), `ne`, `e`, `se` |
| `banco__roto.png` | Otro modelo del mismo objeto (se cambia con V) |
| `banco__roto__w.png` | Ese modelo mirando hacia `w` |

Las direcciones que falten se sacan en espejo de la contraria: `w` de `e`, `ne` de `nw`, etc. Si el
dibujo base no mira a la cámara, se indica en `assets/environment/vistas.json` (por ejemplo, el
caballo base mira a `w`).

## Desactivarlo

- Las exportaciones *release* nunca lo incluyen.
- Para quitarlo también al jugar desde Godot, pon `brumaclara/modo_edicion=false` en `project.godot`
  (Proyecto → Configuración del proyecto, con «Avanzado» activado) o borra el autoload `EditMode`.

Lo editado sigue en el juego en ambos casos, porque lo aplica `LevelEdits` y no el editor.

## Qué no hace (todavía)

- No cambia la altura del terreno ni cómo está compuesta una casa (fachada, alas, tejado). Eso se
  sigue pidiendo por escrito.
- No escribe diálogos: un personaje duplicado dice lo mismo que el original.
- Los objetos de `assets/nuevos` se procesan cada vez que se carga el nivel. Cuando uno te guste, lo
  integro en el pipeline con su paleta.
