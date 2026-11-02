# GUILD ZERO — Plan de unificación artística y control de calidad

> Documento de obligado cumplimiento para todo el arte de GUILD ZERO (aportado por Antonio el 29/10/2026). Cualquier recurso nuevo o rehecho pasa por la escena de validación (`scenes/dev/validacion_arte.tscn`) y por la lista de comprobación de la sección 5 antes de entrar en el juego.

Documento de trabajo | 29 de octubre de 2026

## 1. Objetivo

Consolidar una identidad visual reconocible para GUILD ZERO, empezando por Brumaclara. El objetivo no es aumentar el detalle ni generar más recursos, sino conseguir que escenarios, personajes, objetos, vegetación, efectos e interfaz parezcan diseñados para el mismo juego.

Este documento establece reglas de dirección artística, un flujo de aprobación de recursos, prioridades de producción y criterios de validación. Es una propuesta de trabajo: no afirma que los cambios técnicos aquí descritos ya estén implementados.

## 2. Decisiones principales

1. No ampliar el número de ciudades antes de validar la coherencia visual de Brumaclara.

2. Mantener provisionalmente la configuración de renderizado documentada por el proyecto —resolución interna 640 × 360, escalado entero ×3 y filtrado nearest— hasta comprobarla en una escena de prueba.

3. No confundir dimensiones uniformes con estilo uniforme. La escala aparente del píxel, el contraste, la silueta, la paleta y la densidad de detalle también deben coincidir.

4. Evaluar cada recurso dentro de Godot y junto a los recursos existentes, no únicamente en un PNG aislado.

5. No introducir un recurso en la versión principal hasta que supere una revisión visual.

6. Priorizar una sección jugable pequeña y completa antes de expandir la campaña.

## 3. Diagnóstico artístico

### 3.1 Densidad de píxel incoherente

Algunas imágenes pueden contener grandes grupos de píxeles y otras líneas finas, reflejos y detalles diminutos. Aunque terminen con dimensiones similares, se percibirán como recursos de estilos distintos.

Regla: evitar detalles aislados que generen ruido a tamaño de juego. Los detalles pequeños se aceptan cuando son necesarios para reconocer un objeto o enfatizar un elemento importante.

### 3.2 Escala aparente

El suelo, las paredes y otros materiales se proyectan en una superficie 3D, mientras que muchos personajes y objetos se muestran mediante sprites 2D. La perspectiva puede hacer que los bloques del suelo parezcan deformados o de otra escala.

Regla: comprobar el píxel aparente en pantalla y desde la cámara real. No intentar resolver todas las diferencias simplemente cambiando el tamaño de la imagen.

### 3.3 Paletas inconexas

Una paleta limitada por recurso no garantiza armonía global. El contraste y la temperatura de color pueden variar mucho entre imágenes.

Regla: mantener una paleta maestra compartida, con rampas por material y colores reservados para elementos especiales. La paleta debe coordinar el mundo, no forzar a que todos los materiales usen los mismos colores.

### 3.4 Siluetas, contornos y sombreado

Las diferencias en grosor de contorno, cantidad de sombras y dirección de luz pueden hacer que un personaje parezca pegado sobre el escenario.

Regla: definir convenciones comunes para contornos, iluminación, sombras y contraste. Se permiten excepciones intencionadas para magia, objetos raros o elementos narrativos.

### 3.5 Efectos y partículas

Ampliar sprites pequeños puede hacer que los efectos tengan píxeles mucho más gruesos que el resto del juego.

Regla: construir los efectos grandes con grupos de píxeles o piezas diseñadas para esa escala. Evitar escalados que alteren la escala visual del píxel.

### 3.6 Reducción automática de imágenes

El procesamiento puede normalizar dimensiones y paletas, pero no siempre corrige el ruido, las formas confusas, la mala lectura o la iluminación incoherente.

Regla: el pipeline técnico no sustituye la aprobación artística. Una imagen procesada correctamente puede seguir siendo rechazada.

## 4. Biblia visual provisional

### Resolución y píxel

- Mantener la resolución interna y el escalado entero actuales mientras se valida la escena de referencia.

- Evitar escalado fraccionario de sprites pixel art.

- Revisar la nitidez a resolución nativa y en el tamaño final de presentación.

- Si un recurso necesita demasiados píxeles para leerse, simplificar su diseño antes de aumentar el tamaño.

### Paleta

- Crear una paleta maestra compartida.

- Definir rampas específicas para madera, piedra, tierra, vegetación, tejidos, metal y magia.

- Reservar los colores más saturados para focos de interés, objetos interactivos y elementos mágicos.

- Evitar que cada imagen genere una paleta completamente independiente sin revisión.

### Luz y sombra

- Definir una dirección de luz dominante para los recursos estáticos.

- Limitar los niveles de sombra y luz por material, salvo excepciones justificadas.

- Mantener una diferencia de contraste clara entre el personaje y el fondo.

- Revisar por separado día, noche, interiores y efectos de la Fractura.

### Silueta y detalle

- Leer primero la silueta, después el material y finalmente el detalle.

- Evitar texturas pequeñas repetitivas que compitan con los personajes.

- Reservar el detalle más alto para protagonistas, objetos interactivos y puntos focales.

- Reducir el detalle de elementos de fondo para conservar la jerarquía visual.

### Personajes

- Usar el protagonista como referencia de proporciones, contorno, sombreado y densidad de píxel.

- Mantener coherencia entre el tamaño aparente del protagonista, los NPC y los enemigos.

- Revisar las animaciones por estabilidad de volumen, posición de los pies, silueta y consistencia entre fotogramas.

- Evitar mezclar sprites con anatomía, perspectiva o sombreado incompatibles sin una revisión manual.

### Escenarios y materiales

- Mantener familias coherentes de madera, piedra, tejados, suelos y vegetación.

- Diferenciar edificios por forma, volumen y función, no solo por color.

- Evitar que cada edificio parezca proceder de un paquete artístico distinto.

- Revisar texturas en perspectiva y a distancia de juego.

### Objetos

- Crear una familia de referencia para barriles, cajas, sacos, bancos, faroles, puestos, herramientas y plantas.

- Mantener tamaños relativos, contornos y densidad de detalle coherentes.

- Los objetos secundarios deben apoyar la lectura del espacio y no competir con los puntos focales.

### Efectos

- Mantener la escala de píxel del resto del juego.

- Diseñar el volumen de los efectos con agrupaciones claras y animaciones legibles.

- Reservar colores intensos para señales visuales relevantes.

- Comprobar que los efectos no oculten al personaje ni los peligros del combate.

### Interfaz

- Definir un lenguaje común de marcos, paneles, iconos, tipografía, contraste y estados interactivos.

- Priorizar legibilidad y jerarquía sobre ornamentación.

- La interfaz debe sentirse parte del mismo universo sin imitar literalmente la textura del escenario.

## 5. Escena de validación artística

Crear una escena o composición de prueba permanente que contenga, como mínimo:

- Protagonista en posición neutral.

- Un NPC.

- Una casa con tejado visible.

- Un árbol y vegetación baja.

- Suelo, pared y una superficie de piedra.

- Barril, caja, cofre y farol.

- Un puesto de mercado.

- Un efecto mágico.

- Un panel de diálogo o interacción.

La composición debe renderizarse con la cámara, resolución, filtrado, iluminación y escalado reales del juego. Cada recurso nuevo se prueba dentro de esta escena antes de incorporarse a la ciudad.

### Lista de comprobación por recurso

- [ ] La silueta se reconoce a tamaño de juego.

- [ ] La densidad de píxel encaja con los recursos de referencia.

- [ ] La paleta no introduce colores discordantes sin intención.

- [ ] El contorno y el sombreado respetan la guía.

- [ ] La dirección de luz es compatible.

- [ ] Los bordes y la transparencia están limpios.

- [ ] El recurso no presenta ruido de píxeles aislados.

- [ ] La escala relativa respecto al protagonista es correcta.

- [ ] La animación, si existe, mantiene volumen y posición.

- [ ] Se ha probado dentro del escenario, no solo como imagen aislada.

- [ ] Su licencia y procedencia están registradas.

Si un recurso falla, debe corregirse la fuente o rediseñarse. No debe aceptarse únicamente porque el pipeline haya terminado sin errores.

## 6. Flujo de producción de arte

1. Definir: documentar función, tamaño en pantalla, material, silueta y nivel de prioridad.

2. Crear: generar o dibujar el recurso a partir de referencias aprobadas.

3. Revisar la fuente: comprobar formas, perspectiva, iluminación, ruido y detalles antes de procesar.

4. Procesar: aplicar recorte, transparencia, escala y paleta mediante las herramientas del proyecto.

5. Integrar en escena de prueba: comprobarlo junto a los recursos de referencia.

6. Aprobar o rechazar: registrar la decisión y los defectos encontrados.

7. Integrar: incorporarlo al juego solo tras superar la revisión.

8. Regresión visual: comprobar que el recurso no empeora la composición global.

### Metadatos recomendados

Para cada recurso importante, registrar: nombre, categoría, tamaño de origen, tamaño de destino, herramienta de procesado, fuente o prompt, licencia/procedencia, fecha, estado de revisión y observaciones.

## 7. Dirección artística de Brumaclara

### Plaza de la Fuente

Debe ser el principal punto focal. La fuente ha de reconocerse desde una distancia razonable; el espacio transitable debe quedar despejado y los puestos, faroles y NPC deben conducir la mirada sin saturar el centro.

### Barrio del Faro / instituciones

Utilizar formas arquitectónicas más sólidas, señalización reconocible y materiales que comuniquen autoridad o pertenencia a una organización. Los edificios importantes deben distinguirse por silueta y composición, no únicamente por tamaño.

### Calle del Mercado

Concentrar puestos, toldos, mercancías y actividad. Variar las siluetas de los puestos, manteniendo una familia común de madera, telas y objetos. Evitar que cada puesto use una paleta y un nivel de detalle diferentes.

### Barrio residencial

Utilizar casas de menor escala, vegetación doméstica y detalles cotidianos como leña, macetas, ropa o huertos. Estos elementos deben enriquecer la exploración sin llenar cada espacio vacío por obligación.

### Entrada y salida de la ciudad

Usar el camino, la puerta, el relieve y la composición para generar curiosidad por el exterior. La transición debe ser legible y no quedar escondida por elementos decorativos.

### Vida cotidiana

Los NPC deben tener ubicaciones, rutinas o comportamientos que aporten contexto. No añadir habitantes solo para aumentar el número en pantalla. Cada personaje importante debe tener una silueta, vestimenta y función legibles.

## 8. Priorización

### P0 — Antes de producir más contenido

- Aprobar una escena de referencia visual.

- Definir la escala aparente del píxel.

- Unificar las reglas de paleta, contornos, sombreado y densidad de detalle.

- Crear la escena de validación.

- Identificar y corregir los recursos más discordantes.

### P1 — Pulido de Brumaclara

- Revisar fachadas, tejados, suelos, vegetación y objetos.

- Corregir NPC y animaciones que no encajen.

- Revisar efectos mágicos y su relación con los sprites.

- Mejorar jerarquía visual y navegación de la plaza y los barrios.

- Revisar legibilidad de interfaz.

### P2 — Vertical slice jugable

Validar una experiencia pequeña pero completa que incluya exploración, misión principal, misión secundaria con decisión, combate común, jefe, recompensa y cierre narrativo.

### P3 — Expansión

Solo después de validar las fases anteriores, ampliar regiones, ciudades, enemigos y sistemas. Las nuevas zonas pueden tener identidad propia, pero deben respetar las reglas visuales compartidas.

## 9. Criterios para considerar Brumaclara lista para ampliarse

- Una captura general de la ciudad no contiene recursos que parezcan claramente de otra fuente artística.

- El protagonista se distingue del entorno sin parecer pegado sobre él.

- Los objetos pequeños son legibles y no generan ruido excesivo.

- El suelo, las texturas y los sprites tienen una escala aparente compatible.

- Los barrios se reconocen por composición y arquitectura.

- La plaza tiene un punto focal claro.

- Los recursos nuevos pasan la lista de comprobación.

- El juego mantiene legibilidad en movimiento, no solo en capturas estáticas.

- Existe una sección jugable corta con exploración, combate, recompensa y consecuencia narrativa.

- La documentación diferencia lo implementado, probado, diseñado y pendiente.

## 10. Estado y cautelas

Este documento establece objetivos y criterios propuestos. No significa que los recursos existentes ya se hayan corregido ni que los cambios de código estén implementados. Antes de modificar el pipeline, hay que inspeccionar sus scripts, escenas, import settings y recursos actuales para evitar romper el proyecto.

No se debe descartar masivamente arte ni reemplazar recursos de forma automática. Conviene trabajar por lotes pequeños, comparar capturas y mantener cambios fáciles de revertir.

## 11. Registro de decisiones

- Decisión: no ampliar el mundo antes de unificar el estilo.

- Decisión: validar recursos dentro de Godot.

- Decisión: usar una paleta maestra con rampas por material.

- Decisión: no confundir filtrado nearest o dimensiones iguales con coherencia artística.

- Decisión: priorizar silueta, lectura y jerarquía sobre cantidad de detalle.

- Pendiente: fijar tamaños de referencia exactos por categoría tras inspeccionar los recursos actuales.

- Pendiente: revisar el pipeline de procesado y establecer pruebas automáticas donde resulte útil.

- Pendiente: realizar una auditoría recurso por recurso y registrar aprobaciones.
