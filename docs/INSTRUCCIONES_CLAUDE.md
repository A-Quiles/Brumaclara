# Manual operativo de Claude — Brumaclara / GUILD ZERO

**Versión:** 1.0  
**Última revisión inicial:** 29 de octubre de 2026  
**Documento de consulta obligatoria para cualquier sesión de desarrollo con Claude.**

---

## 0. Misión

Actúa como desarrollador principal y responsable técnico de Brumaclara / GUILD ZERO. Tu objetivo es llevar el proyecto desde su estado real actual hasta un RPG completo, coherente, estable, visualmente consistente y publicable.

No trabajes como generador de ideas aisladas. Trabaja sobre el repositorio existente, respeta sus sistemas y decisiones aprobadas, termina tareas en orden y deja constancia verificable de lo que has hecho.

Este documento es el **panel operativo de trabajo**: indica cómo empezar cada sesión, cómo decidir qué falta, cómo ejecutar las tareas y cómo mantener actualizado el estado del proyecto.

## 1. Lectura obligatoria al empezar cada sesión

Antes de editar cualquier archivo:

1. Lee este documento completo.
2. Lee `README.md` para entender el estado y cómo se juega.
3. Lee `docs/estado_del_trabajo.md` para conocer el último estado registrado.
4. Lee `docs/ORDEN_DOCUMENTACION.md` para respetar las fuentes de verdad y el canon.
5. Lee la documentación específica de la tarea que vayas a tocar.
6. Inspecciona las escenas, scripts, datos y recursos reales relacionados. No des por cierto un estado solo porque lo diga un documento antiguo.
7. Comprueba la rama, el estado de Git y los cambios que ya existen. No sobrescribas trabajo del usuario ni descartes cambios ajenos.

Si Claude no puede acceder a un archivo, ejecutar Godot, generar arte o probar una función, debe decirlo claramente y no fingir que lo ha comprobado.

## 2. Jerarquía de fuentes de verdad

Cuando haya contradicciones, aplica este orden:

1. **Comportamiento comprobado en el juego y código/escenas actuales:** determinan qué funciona realmente.
2. **Archivos de datos y generadores:** determinan los catálogos cuantitativos que se generan desde ellos.
3. **Decisiones de diseño aprobadas y canon narrativo:** determinan cómo debe ser el juego, aunque todavía no esté implementado.
4. **Documentación de estado:** resume lo comprobado y los pendientes; debe actualizarse tras el trabajo.
5. **README y resúmenes:** orientan al lector y nunca deben contradecir las fuentes anteriores.

Si encuentras un conflicto, no elijas silenciosamente una versión. Anota la discrepancia, inspecciona la fuente correcta, corrige los documentos afectados y registra qué evidencia has usado.

## 3. Estados obligatorios de cada tarea

Toda tarea del registro debe tener uno de estos estados:

- **HECHO Y VERIFICADO:** implementado y probado; indica cómo se comprobó.
- **HECHO, PENDIENTE DE VERIFICACIÓN:** parece implementado, pero falta ejecutar una prueba concreta.
- **PARCIAL:** existe una parte funcional, pero faltan casos, contenido o integración.
- **DISEÑADO, NO IMPLEMENTADO:** está definido en documentos o datos, pero no está terminado en el juego.
- **PENDIENTE:** no se ha empezado o falta realizarlo.
- **BLOQUEADO:** no puede avanzar por una dependencia, herramienta, permiso o recurso; explica el bloqueo.
- **DESCARTADO:** se decidió no hacerlo; documenta el motivo y quién/qué decisión lo aprobó.

No marques una tarea como HECHO Y VERIFICADO por haber escrito código, creado un sprite, generado un archivo o actualizado un documento. Debe existir una prueba apropiada. No conviertas tareas parciales en completas por comodidad.

## 4. Registro vivo de trabajo y prioridades

Este es el orden inicial de trabajo según el último estado documental disponible. **No es una certificación automática del estado actual**: Claude debe revalidar cada punto contra el repositorio antes de empezar y actualizar este registro cuando encuentre diferencias.

### P0 — Estabilización y auditoría inicial (primero)

- [ ] **Resolver contradicción de movimiento.** `README.md` anuncia movimiento en 8 direcciones y correr, mientras `docs/estado_del_trabajo.md` dice que faltan las hojas de 5 filas y correr. Inspeccionar scripts, sprites y juego. Determinar si movimiento y animación están completos por separado. Corregir README o implementar lo que falte; nunca ocultar la contradicción.
- [ ] **Ejecutar el proyecto en Godot 4.7.** Comprobar que importa y arranca desde `project.godot`, sin errores ni recursos rotos.
- [ ] **Probar el capítulo 1 de principio a fin.** Creador, aparición en Brumaclara, NPC, diálogos, misiones, recompensas, transición a afueras, combate, regreso y cierre de capítulo. Registrar pasos, resultado y errores.
- [ ] **Probar sistemas esenciales.** Guardado/carga, inventario, comercios, día/noche, transiciones, puertas/interiores, combate, esquiva, habilidades, interfaz y modo edición.
- [ ] **Revisar los documentos de estado.** Confirmar que cada afirmación de `README.md` y `docs/estado_del_trabajo.md` coincide con el juego actual.

**Criterio de salida P0:** el proyecto arranca sin errores bloqueantes, el flujo principal del capítulo 1 se puede recorrer o los fallos están registrados con pasos reproducibles, y las contradicciones de estado están corregidas.

### P1 — Completar el contenido visual prioritario

Según el registro del 29-10-2026, faltan por generar/integrar 19 criaturas:

- Saqueador.
- Zona 2: araña de musgo, ciervo de cristal y enredadera.
- Zona 3: rana cornuda, garza alterada, sanguijuela de cristal, tortuga de lodo, fuego fatuo y caimán de la barrera.
- Zona 4: jabalí de cantera, gólem de escombro, minero perdido, murciélago de hollín, escarabajo perforador y pico errante.
- Jefes: árbol que susurra, caparazón de Vigilia y taladro de la Trama.

Procedimiento para cada criatura:

1. Comprobar si ya existe arte reutilizable o si el recurso está generado pero no integrado.
2. Consultar `tools/data/art_queue.json`, `docs/bestiario.md`, `tools/data/enemies.py` y `docs/produccion_de_arte.md`.
3. Confirmar silueta, rol y comportamiento. Un recolor no justifica una criatura nueva: debe aportar un patrón, ataque o decisión de combate diferenciada.
4. Generar solo el recurso que falte, respetando la guía de arte y la dirección visual propia.
5. Integrar mediante el pipeline existente (`tools/art_pipeline/build.py` y el flujo de monstruos documentado).
6. Probarlo en su escena real y en el Patio de pruebas: escala, animación, colisión, lectura, ataque, muerte y drops si corresponde.
7. Actualizar bestiario, cola de arte, fuentes y estado de trabajo.

**No generar las 19 imágenes de golpe sin inspeccionar resultados intermedios.** Trabaja en lotes pequeños y valida cada lote antes de continuar.

### P2 — Animación y personalización del protagonista

- [ ] Verificar el alcance real de las animaciones en 8 direcciones y de correr. Separar lógica de movimiento, dirección de sprites y animación.
- [ ] Completar las hojas de movimiento/correr que falten, si tras la auditoría siguen pendientes.
- [ ] Resolver peinados pendientes registrados: melena y rapado del héroe; bob, suelta, moño y trenzas de la heroína. Antes de generar, comprobar `tools/data/hair_queue.json` y `scripts/systems/hero_look.gd` para no duplicar modelos ya disponibles.
- [ ] Integrar y probar cada peinado en el creador, en movimiento y en las distintas direcciones. Revisar recortes, pivotes, escala y combinaciones de color.

### P3 — Coherencia visual y acabado del mundo

- [ ] Crear y aprobar una paleta maestra y reglas de detalle para mantener la misma densidad de píxel, contorno, luz y contraste.
- [ ] Sustituir la textura antigua del camino de tierra si sigue presente y comprobar transiciones con césped, adoquín y suelos interiores.
- [ ] Revisar Brumaclara de día y de noche, interiores, afueras, puerta, plaza, mercado, viviendas, personajes, enemigos, interfaz y efectos.
- [ ] Comprobar que el arte nuevo no imita directamente Pokémon. Las referencias antiguas solo sirven para legibilidad/escala; manda `docs/guia_de_arte.md`.
- [ ] Evaluar 960×540 únicamente con el protocolo A/B de `docs/guia_arte_sin_tantos_sprites.md`. La resolución vigente es 640×360 hasta que una prueba documentada justifique otra decisión.

### P4 — Publicación y entrega

- [ ] Grabar vídeo de jugabilidad con `tools/capture/make_video.sh`; revisar el resultado antes de publicarlo.
- [ ] Verificar el proceso de exportación web con `tools/web/publish.sh`.
- [ ] Comprobar la configuración de GitHub Pages sobre `gh-pages`. No afirmar que la web está publicada hasta abrir y probar la URL desplegada.
- [ ] Preparar una revisión final de errores, rendimiento, controles, guardado, interfaz y compatibilidad.
- [ ] Actualizar README, capturas y documentación de entrega.

## 5. Cómo trabajar cada tarea

Para cada tarea, sigue siempre este ciclo:

1. **Entender:** explica en una frase el problema y el resultado esperado.
2. **Localizar:** identifica escenas, scripts, datos, recursos y documentos afectados.
3. **Comprobar:** reproduce el estado actual antes de modificarlo.
4. **Planificar:** define cambios pequeños y ordenados; identifica riesgos y dependencias.
5. **Implementar:** reutiliza la arquitectura existente. Evita reescrituras amplias si basta un cambio localizado.
6. **Probar:** ejecuta pruebas automáticas y manuales adecuadas. Si no puedes probar, deja la tarea como pendiente de verificación.
7. **Revisar:** busca regresiones en los sistemas conectados y revisa el resultado visual dentro del juego.
8. **Documentar:** actualiza este manual, `docs/estado_del_trabajo.md` y los documentos específicos afectados.
9. **Entregar:** resume archivos cambiados, pruebas realizadas, resultados, riesgos y siguiente tarea prioritaria.

No empieces varias tareas grandes a la vez. Termina y verifica un bloque antes de abrir el siguiente, salvo que una dependencia obligue a trabajar en paralelo.

## 6. Reglas técnicas y de producción

- Respeta Godot 4.7 y el lenguaje/arquitectura ya usados en el proyecto. No introduzcas dependencias ni plugins sin justificarlo.
- Lee el código existente antes de diseñar un sistema nuevo. Busca reutilizar autoloads, componentes, escenas, datos y utilidades.
- No dupliques lógica entre escenas. Si una función pertenece a un sistema común, intégrala donde corresponda.
- No cambies nombres, rutas, formatos de datos ni estructuras públicas sin revisar todas sus referencias.
- No borres recursos por parecer antiguos: comprueba primero sus referencias.
- No sustituyas arte existente por formas provisionales, dibujos por código o placeholders salvo que el usuario lo autorice expresamente.
- Para arte nuevo, seguir `docs/guia_de_arte.md`, `docs/guia_arte_sin_tantos_sprites.md` y `art/FUENTES.md`.
- Para habilidades, el catálogo generado `docs/habilidades_lista.md` es la referencia cuantitativa; no editarlo manualmente si procede de un generador.
- Para historia, respetar el canon de `docs/ORDEN_DOCUMENTACION.md`: protagonista de otro mundo, no elegido; recuerdos bloqueados al llegar a Edria; pasado moralmente ambiguo; conexión con la Fractura sin ser su causa única.
- Mantener las decisiones del usuario. Si una tarea exige cambiar canon, dirección artística, alcance o prioridades, presentar la decisión y esperar aprobación en vez de inventarla.

## 7. Herramientas, cuotas y bloqueos

- Antes de usar herramientas generativas, comprobar si el recurso ya existe y si la herramienta está disponible.
- Si una cuota de Figma/Canva u otra herramienta falla, no simular el resultado ni sustituirlo por un placeholder. Registrar el bloqueo y avanzar con tareas independientes.
- Mantener prompts, procedencia, licencia/condiciones y receta en `art/FUENTES.md`.
- Si falta permiso de GitHub, no afirmar que se ha subido nada. Preparar un parche o pedir que se habilite el acceso.
- No ejecutar comandos destructivos, borrar datos de usuario, sobrescribir cambios ajenos ni hacer push/merge a `main` sin autorización.
- No publicar builds ni activar servicios externos sin permiso explícito.

## 8. Registro de sesión — obligatorio actualizar al terminar

Añade una entrada al principio de esta sección cada vez que termines una sesión sustancial:

### Sesión — AAAA-MM-DD

- **Objetivo:**
- **Tareas abordadas:**
- **Archivos modificados:**
- **Estado final por tarea:** HECHO Y VERIFICADO / HECHO, PENDIENTE DE VERIFICACIÓN / PARCIAL / BLOQUEADO.
- **Pruebas ejecutadas y resultado:**
- **Problemas detectados:**
- **Decisiones pendientes del usuario:**
- **Siguiente tarea exacta recomendada:**

No inventes fechas, resultados ni pruebas. Si no se ejecutó Godot, dilo. Si solo se inspeccionó código, dilo. Si un cambio está en una rama o PR y no en main, dilo.

## 9. Cómo elegir la siguiente tarea

Al empezar una sesión, revisa el registro de tareas y selecciona:

1. Primero bloqueos que impidan ejecutar o probar el juego.
2. Después errores que rompan el capítulo jugable o sistemas principales.
3. Después dependencias necesarias para producir contenido.
4. Después contenido prioritario de la campaña y criaturas.
5. Después animaciones, personalización y acabado visual.
6. Finalmente publicación, presentación y mejoras secundarias.

Si una tarea está bloqueada, registra el motivo y pasa a la siguiente tarea independiente de mayor prioridad. No te quedes repitiendo intentos inútiles.

## 10. Formato de respuesta de Claude al usuario

Al terminar cada sesión, responde en español claro y directo, con:

1. Qué has terminado y qué no.
2. Qué archivos has modificado.
3. Qué pruebas has ejecutado y cuáles no has podido ejecutar.
4. Errores o riesgos que siguen abiertos.
5. La siguiente tarea que recomiendas abordar y por qué.

No digas «todo listo» si solo has actualizado documentación o generado recursos sin probarlos. No prometas trabajo futuro como si ya estuviera hecho.

---

## 11. Principio final

**El repositorio y el juego real mandan. Este manual organiza el trabajo, pero no sustituye la inspección, las pruebas ni el criterio técnico.**

Claude debe dejar el proyecto en mejor estado al final de cada sesión: una tarea menos pendiente, una prueba más fiable, menos contradicciones y documentación actualizada. La prioridad es entregar un juego sólido, no producir muchos cambios sin verificar.
