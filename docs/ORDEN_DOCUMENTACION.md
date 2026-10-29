# Índice maestro y reglas de coherencia documental

**Fecha de revisión:** 29 de octubre de 2026  
**Ámbito:** documentación del videojuego Brumaclara / GUILD ZERO.  
**Objetivo:** que una persona nueva pueda saber qué documento manda, qué está decidido, qué está implementado y qué sigue siendo una propuesta.

## 1. Regla principal: diseño no significa implementación

En toda la documentación se deben distinguir estos estados:

- **Implementado:** existe en el código/escenas actuales y se puede comprobar ejecutando el proyecto.
- **Documentado/datos:** existe en un documento o archivo de datos, pero eso por sí solo no prueba que el comportamiento esté terminado.
- **Planificado:** decisión de diseño aprobada, aún no necesariamente construida.
- **Propuesto/por validar:** idea pendiente de prueba o decisión.
- **Pendiente:** falta arte, código, revisión o contenido.

No usar una casilla [x], una tabla de diseño o el número de entradas de un catálogo como prueba automática de que todo está jugable. Si un documento antiguo contradice al código o a los datos actuales, registrar la discrepancia y corregir el documento; no inventar una cifra para que encaje.

## 2. Qué documento manda en cada tema

| Tema | Fuente principal | Documentos de apoyo |
|---|---|---|
| Estado actual del juego, cómo ejecutarlo y controles | README.md y project.godot | escenas y scripts reales |
| Dirección visual, cámara, escala, paleta y calidad mínima | docs/guia_de_arte.md | art/FUENTES.md, capturas de docs/screenshots/ |
| Reutilización de sprites y optimización del trabajo artístico | docs/guia_arte_sin_tantos_sprites.md | tools/art_pipeline/, art/FUENTES.md |
| Historia, personajes, canon y estructura de capítulos | documento narrativo maestro de GUILD ZERO y documentos de historia existentes | diálogos/misiones implementados; indicar por separado qué está jugable |
| Pueblo de Brumaclara, barrios y edificios | docs/diseno_pueblo.md | referencias visuales y escenas del pueblo |
| Reglas y fórmulas de combate | docs/diseno_combate.md | scripts y fichas de datos |
| Diseño explicativo de las habilidades | docs/arbol_habilidades.md | docs/habilidades_lista.md |
| Recuento exacto de nodos de habilidades | docs/habilidades_lista.md, generado desde data/trees/*.json | tools/data/tree_doc.py |
| Enemigos, zonas, debilidades y jefes diseñados | docs/bestiario.md | datos de enemigos y arte en tools/data/enemies.py |
| Origen de imágenes, prompts, limitaciones y recetas | art/FUENTES.md | archivos originales de art/ai/ y pipeline |

Si existe un documento narrativo maestro con otro nombre, conservar su nombre real y enlazarlo desde el índice; no crear una segunda versión de la historia que pueda divergir.

## 3. Dirección artística vigente

Brumaclara es un RPG de fantasía y aventura con identidad propia: escenarios 3D estilizados, cámara elevada de tres cuartos y personajes/objetos 2D en píxel art integrado. Las referencias a RPG de Nintendo DS solo explican la legibilidad, escala y lectura espacial; no son una plantilla para copiar su estética.

Evitar que el resultado parezca una imitación directa de Pokémon: no replicar sus siluetas, edificios, composición, paleta, interfaz ni lenguaje visual. Buscar arquitectura vivida e irregular, materiales legibles, atmósfera, iluminación con intención y detalles propios del mundo.

### Resolución de referencia

La configuración real comprobada en project.godot es:

- Resolución interna: **640 × 360**.
- Ventana objetivo: **1920 × 1080**.
- Escalado: modo viewport con scale_mode="integer".

Esta es la configuración vigente, no una recomendación permanente. La alternativa **960 × 540** solo se puede aceptar después del protocolo A/B de docs/guia_arte_sin_tantos_sprites.md: mismas escenas, mismas condiciones y comparación de legibilidad, pixelado, HUD, oclusión, exportación web y rendimiento. No cambiar la resolución como sustituto de corregir arte inconsistente.

## 4. Recuento de habilidades: cifra y alcance

El resumen generado actualmente en docs/habilidades_lista.md enumera:

| Árbol | Nodos |
|---|---:|
| Fuego | 55 |
| Hielo | 53 |
| Rayo | 53 |
| Sombra | 54 |
| Tierra | 51 |
| Luz | 54 |
| **Seis afinidades** | **320** |
| Aventurero | 32 |
| **Afinidades + aventurero** | **352** |

Los árboles de gremio se contabilizan aparte y no se incluyen en el total de 352. Esta cifra describe el catálogo generado de datos; no certifica que cada habilidad, mejora o efecto esté plenamente implementado, equilibrado o probado. Para cambios de datos, ejecutar el generador y actualizar docs/habilidades_lista.md; no corregir esa lista manualmente.

## 5. Canon narrativo aprobado

Las decisiones siguientes son canon de diseño y deben mantenerse al actualizar la historia:

1. El protagonista llega desde otro mundo a Edria; **no es el elegido**.
2. Sus recuerdos están bloqueados al llegar. La causa es un misterio que se descubre progresivamente.
3. Su pasado es moralmente ambiguo: hizo cosas buenas y malas.
4. Su pasado está relacionado con la Fractura, pero no es la única causa de ella.
5. Las decisiones pequeñas pueden producir consecuencias personales y narrativas posteriores.
6. El tono combina misterio y aventura; los personajes importantes deben tener arcos propios y consecuencias creíbles.
7. La campaña apunta a 7–9 regiones compactas, unas 20 horas de historia principal y 25–30 horas con contenido opcional. Son objetivos de diseño, no una afirmación de que toda esa campaña esté ya construida.

El protagonista debe sentirse como una persona que busca trabajo y construye su propia leyenda, no como un héroe predestinado. Mantener la coherencia entre este canon, el creador de personaje y las descripciones del arte.

## 6. Reglas de producción para ahorrar sprites

1. Antes de pedir arte nuevo, comprobar si sirve un recurso existente, una vista reflejada, una variante de paleta, una máscara/capa o un efecto procedural.
2. Un recolor no basta para justificar un enemigo nuevo: la variante debe aportar una mecánica, ataque, patrón o respuesta reconocible.
3. Preferir hojas consistentes a imágenes sueltas. Definir cuadrícula, orientación, número de fotogramas, fondo y punto de apoyo antes de generar.
4. No duplicar hojas completas para combinaciones de color o vestuario si las capas o máscaras existentes pueden hacerlo.
5. Los efectos sencillos (partículas, destellos, anillos, estelas y auras) deben resolverse con el motor cuando sea visualmente suficiente.
6. Integrar arte por el pipeline existente; los recursos generados deben poder reconstruirse desde sus fuentes y recetas.
7. Revisar todo en la escena real y en movimiento. Rechazar los recursos con contorno, escala, densidad de píxel, iluminación o silueta incompatibles.
8. Registrar las fuentes, limitaciones y decisiones de descarte en art/FUENTES.md.

Los detalles técnicos y el protocolo de revisión están en docs/guia_arte_sin_tantos_sprites.md.

## 7. Cómo actualizar documentación sin reintroducir contradicciones

Al realizar un cambio:

1. Identificar la fuente de verdad de ese tema según la tabla de la sección 2.
2. Leer el documento, los datos y el código relacionados antes de editar.
3. Actualizar primero la fuente principal y después las referencias/resúmenes (README, índice y documentos de apoyo).
4. No mantener números copiados a mano cuando pueden generarse desde datos.
5. Marcar expresamente lo planificado, lo probado y lo implementado.
6. Buscar en todo docs/ y README.md las cifras y frases antiguas que puedan quedar obsoletas.
7. Verificar enlaces relativos, rutas de archivos, nombres de scripts y los generadores de documentación.
8. Ejecutar las pruebas pertinentes si hay cambios de código; una edición de documentación no debe declarar pruebas que no se han ejecutado.

## 8. Limitación de esta revisión

Esta pasada armoniza las referencias principales de arte, resolución, habilidades y estado del proyecto. No certifica que todos los capítulos, regiones, enemigos, efectos o árboles descritos estén implementados. Las cifras y estados deben seguir contrastándose con el repositorio y con el juego ejecutado.
