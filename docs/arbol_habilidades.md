# Árbol de aprendizaje y habilidades

Sistema de progresión de habilidades del juego final. Completa `docs/diseno_combate.md` (recursos,
fórmulas y estados) y el GDD (secciones 11 y 12). Los números son la propuesta de partida; se ajustan
jugando y viven en las fichas de datos (`data/skills`), no en el código.

El juego tiene **seis afinidades**: fuego, hielo, rayo, sombra, tierra y luz. Cada una tiene su propio
árbol de **51–55 nodos con 21 habilidades activas distintas, cada una con su mejora**, sus pasivas y una
definitiva. Además hay un **tronco común del aventurero** (32 nodos, sin afinidad) y un árbol pequeño
por **gremio** (9 nodos). En total, unos 390 nodos; ninguna partida puede comprarlos todos.

La lista completa de nodos, con sus números, está en `docs/habilidades_lista.md` (generada desde los
datos). Las secciones 3.x de este documento cuentan la idea de cada rama y sus nodos originales; las
activas añadidas siguen las mismas reglas y aparecen en la lista. Cada habilidad tiene su icono
(`assets/ui/skills/<afinidad>.png`; las mejoras muestran el de su habilidad con una marca dorada).

## 1. Sistema de puntos

### Monedas de progreso

| Moneda | Cómo se gana | Para qué sirve |
|---|---|---|
| **Puntos de aprendizaje (PA)** | 2 por nivel (del 2 al 40: 78 PA); 1 por cada hito de maestría (6 por afinidad despertada); 1 por cada santuario o registro antiguo opcional (unos 12) | Nodos de los árboles de afinidad y del tronco común |
| **Puntos de atributo** | 1 por nivel | Vitalidad, Poder, Control y Agilidad (`docs/diseno_combate.md`) |
| **Méritos de gremio (MG)** | Misiones de la línea del gremio (unos 9 en la campaña) | Nodos del árbol del gremio |

Una partida completa reúne unos **110 PA**. Completar un árbol de afinidad cuesta unos 41 PA y el tronco común entero unos 42, así que alcanza para completar una afinidad, desarrollar bien una
segunda, tocar una tercera y elegir una parte del tronco común. La identidad del personaje sale de qué
se deja sin comprar.

### Coste de los nodos

| Tipo | Coste | Qué es |
|---|---|---|
| **Activa** | 2 PA | Una habilidad que se equipa en una ranura y se lanza |
| **Mejora** | 1 PA | Cambia cómo funciona una activa concreta (requiere esa activa) |
| **Pasiva** | 1 PA (niveles I–III) o 2 PA (IV–V) | Efecto permanente; no ocupa ranura |
| **Definitiva** | 5 PA | La técnica cumbre de una afinidad; una ranura propia (tecla X) |

### Niveles del árbol

Cada árbol tiene cinco niveles. Para abrir un nivel hay que haber gastado PA **en ese mismo árbol**:

| Nivel | PA gastados en el árbol | Notas |
|---|---|---|
| I | 0 | |
| II | 4 | |
| III | 10 | Tope de las afinidades secundarias (salvo la técnica Resonancia del Archivo, que lo sube al IV) |
| IV | 18 | |
| V | 28 | La definitiva pide además 3 nodos de nivel IV o V |

Requisitos dentro de un árbol de afinidad: una activa de nivel II o más pide **cualquier** activa de su
rama de un nivel inferior; una pasiva, una activa de su rama hasta su nivel; una mejora, su activa. Así
cada rama se recorre por caminos distintos. En el tronco común, un nodo pide el anterior de su rama.

### Afinidad principal y secundarias

- **Principal:** se elige en el santuario de Brumaclara durante el capítulo 1, después del primer
  combate, cuando el jugador ya sabe qué significa (GDD 7.2). Árbol completo hasta el nivel V y la
  definitiva.
- **Secundarias:** se despiertan en santuarios de la campaña (uno accesible en el capítulo 3 y otro en
  el 5; hay más ocultos). Llegan hasta el nivel III. Se pueden despertar varias, pero cada PA cuenta.
- **Maestría:** cada afinidad despertada tiene 6 hitos que dan 1 PA cada uno. Son retos, no repeticiones;
  por ejemplo: «derrota a un enemigo grande solo con habilidades de esta afinidad», «interrumpe tres
  avisos de enemigo con ella», «supera el santuario sin recibir daño».

### Ranuras

- **4 ranuras de habilidad** (Q, E, R y C por defecto; todo es reasignable) más la **definitiva** (X). La F sigue siendo interactuar.
  La espada y la esquiva van siempre equipadas.
- Las habilidades equipadas se cambian fuera de combate o en los puntos de descanso.
- El gremio del Archivo da una 5.ª ranura en su rango 3.

### Reasignar puntos

- En la sede de Brumaclara, con Mara: cuesta 50 monedas por nivel del personaje.
- Gratis una vez al jurar un gremio y otra al terminar el capítulo 4, para que nadie se quede atrapado
  con una elección temprana.

## 2. Tronco común del aventurero

Sin afinidad: lo que aprende cualquier aventurero que vive de los contratos. Usa PA.

### Acero — la espada

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Filo templado | Pasiva | 1 | El 3.er golpe del combo hace +50 % |
| I | Estocada | Activa | 2 | Avanza 2 unidades con la espada por delante y hace 20; sin maná, recarga 5 s |
| II | Castigo | Pasiva | 1 | +30 % de daño a enemigos que acaban de fallar un ataque |
| II | Combo largo | Pasiva | 1 | El combo pasa de 3 a 4 golpes |
| III | Golpe pesado | Pasiva | 1 | El último golpe del combo empuja el doble e interrumpe a enemigos pequeños |
| III | Torbellino | Activa | 2 | Giro de 360°, 25 de daño; sin maná, recarga 8 s |
| IV | Remate | Pasiva | 2 | +50 % de daño a enemigos con menos del 25 % de vida |
| V | Maestro de armas | Pasiva | 2 | Cada golpe de espada reduce 0,3 s la recarga de todas las habilidades |

### Instinto — esquiva y movimiento

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Impulso | Pasiva | 1 | Tras esquivar, el siguiente golpe en 1 s hace +40 % |
| I | Paso ligero | Pasiva | 1 | +10 % de velocidad fuera de combate |
| II | Esquiva limpia | Pasiva | 1 | Esquivar en los últimos 0,15 s antes de un golpe devuelve 10 de maná |
| II | Doble esquiva | Pasiva | 1 | Dos cargas de esquiva |
| III | Lectura | Pasiva | 1 | Los avisos enemigos se ven 0,15 s antes |
| III | Rodar y golpear | Pasiva | 1 | Atacar justo al acabar la esquiva hace un tajo giratorio de 15 |
| IV | Tiempo justo | Pasiva | 2 | La esquiva perfecta ralentiza a los enemigos 0,5 s (el efecto de pantalla se puede desactivar) |
| V | Fantasma | Pasiva | 2 | +0,1 s de invulnerabilidad en la esquiva |

### Resistencia — supervivencia

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Piel curtida | Pasiva | 1 | +15 % de vida máxima |
| I | Pociones dobles | Pasiva | 1 | 4 pociones por expedición en lugar de 3 |
| II | Segundo aliento | Pasiva | 1 | En lugar de caer te quedas a 1 de vida e invulnerable 1 s; se recarga en 60 s |
| II | Recuperación | Pasiva | 1 | Fuera de combate recuperas un 2 % de vida por segundo |
| III | Último recurso | Pasiva | 1 | Con menos del 30 % de vida recibes −20 % de daño |
| III | Antídotos | Pasiva | 1 | Los estados alterados duran −40 % sobre ti |
| IV | Corazón firme | Pasiva | 2 | +25 de vida; inmune al primer aturdimiento de cada combate |
| V | Inquebrantable | Pasiva | 2 | Segundo aliento tiene dos cargas |

### Oficio — exploración y utilidad

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Ojo de rastreador | Pasiva | 1 | Ves la vida de los enemigos sin golpearlos |
| I | Bolsillos | Pasiva | 1 | +1 hueco de consumible |
| II | Botín atento | Pasiva | 1 | Los cofres dan un objeto más |
| II | Regateo | Pasiva | 1 | −10 % en las tiendas |
| III | Cartógrafo | Pasiva | 1 | El mapa marca los secretos a menos de 20 unidades |
| III | Alquimia de campo | Pasiva | 1 | Las pociones preparadas en un punto de descanso curan +20 % |
| IV | Recarga rápida | Pasiva | 2 | −15 % a todas las recargas |
| V | Leyenda en ciernes | Pasiva | 2 | +10 % de experiencia y de reputación por contrato |

## 3. Árboles de afinidad

Cada afinidad tiene tres ramas y una definitiva. Abajo, los nodos originales de cada rama; las activas
nuevas (abanicos, cadenas, lluvias, escudos, embestidas, auras...) y todas las mejoras están en
`docs/habilidades_lista.md`. Formato de las activas: **maná / recarga / daño**. Todas están implementadas.

### 3.1 Fuego — presión y daño

Estado propio: **Quemadura**. Fuerte contra flora y bestias; débil contra criaturas de agua y autómatas
con coraza.

**Rama Llama (proyectiles)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Chispa *(en juego)* | Activa | 2 | 8 / 0,45 s / 18. Proyectil rápido que estalla al primer impacto |
| I | Chispa doble | Mejora | 1 | Chispa lanza dos proyectiles en abanico; coste 12 |
| II | Lanza de fuego | Activa | 2 | 14 / 3 s / 26. Atraviesa a todos los enemigos en línea |
| II | Combustión | Pasiva | 1 | Los proyectiles de fuego aplican Quemadura |
| III | Chispa rebotante | Mejora | 1 | Chispa salta a un segundo enemigo a menos de 4 unidades |
| III | Puntería ardiente | Pasiva | 1 | +20 % de daño de fuego a más de 5 unidades |
| IV | Cometa | Activa | 2 | 30 / 9 s / 45. Proyectil grande y lento que explota en área |
| V | Lluvia de brasas | Mejora | 1 | El Cometa deja caer 5 brasas alrededor (10 cada una) |

**Rama Hoguera (áreas)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Estallido *(en juego)* | Activa | 2 | 25 / 4 s / 30. Anillo alrededor del héroe que empuja fuerte |
| I | Anillo amplio | Mejora | 1 | +40 % de radio del Estallido |
| II | Rastro ardiente | Activa | 2 | 20 / 6 s / 6 cada 0,5 s. Zona de 3 s en el suelo que quema |
| II | Suelo encendido | Pasiva | 1 | Al esquivar dejas una llama de 1,5 s (8 de daño) |
| III | Muro de llamas | Activa | 2 | 28 / 10 s / 8 cada 0,5 s. Línea de fuego de 5 unidades durante 4 s; detiene proyectiles enemigos |
| III | Hoguera persistente | Pasiva | 1 | Las zonas de fuego duran +50 % |
| IV | Columna ígnea | Activa | 2 | 35 / 12 s / 60. Columna en el punto apuntado tras 0,6 s de aviso |
| V | Infierno contenido | Pasiva | 2 | Los enemigos que mueren con Quemadura explotan (15 en área) |

**Rama Brasa interior (potenciación)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Ascua viva | Activa | 2 | 15 / 8 s. El siguiente golpe de espada hace +100 % y quema |
| I | Calor corporal | Pasiva | 1 | +10 de maná máximo |
| II | Filo encendido | Pasiva | 1 | El último golpe del combo aplica Quemadura |
| II | Avivar | Pasiva | 1 | Golpear con la espada a un enemigo quemado devuelve 3 de maná |
| III | Sobrecalentamiento | Activa | 2 | 20 / 18 s. Durante 6 s, +30 % de daño de fuego y +15 % de daño recibido |
| III | Piel de brasas | Pasiva | 1 | Quien te golpea cuerpo a cuerpo se quema |
| IV | Fénix menor | Pasiva | 2 | Una vez por zona, al caer, vuelves con el 30 % de vida y un Estallido gratis |
| V | Corazón de horno | Pasiva | 2 | +50 % de regeneración de maná mientras haya un enemigo quemado a menos de 6 unidades |

**Definitiva — Ruptura ígnea** (5 PA): 50 / 30 s / 120 en total. Se canaliza 0,5 s (interrumpible) y
abre una línea de explosiones de 10 unidades.

### 3.2 Hielo — control y supervivencia

Estado propio: **Frío** (−40 % de velocidad; tres cargas congelan 1 s). Fuerte contra bestias rápidas y
criaturas de agua; débil contra autómatas y criaturas de fuego.

**Rama Escarcha (proyectiles)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Aguja de escarcha | Activa | 2 | 8 / 0,5 s / 14. Aplica Frío |
| I | Esquirlas | Mejora | 1 | La aguja se rompe en 3 esquirlas al impactar (5 cada una) |
| II | Lanza glacial | Activa | 2 | 16 / 4 s / 30. Atraviesa y aplica 2 cargas de Frío |
| II | Frío penetrante | Pasiva | 1 | El Frío dura 2 s más |
| III | Ráfaga helada | Activa | 2 | 22 / 7 s / 18. Cono de 4 unidades que empuja y aplica 2 cargas de Frío |
| III | Escarcha certera | Pasiva | 1 | +25 % de daño a enemigos con Frío |
| IV | Tormenta de agujas | Activa | 2 | 32 / 12 s / 8 × 8. Ocho agujas en 1 s hacia donde apuntas |
| V | Corazón de invierno | Pasiva | 2 | Congelar a un enemigo reduce 2 s las recargas de hielo |

**Rama Glaciar (terreno)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Suelo helado | Activa | 2 | 20 / 6 s. Zona de 3 s que ralentiza un 40 % |
| I | Hielo resbaladizo | Mejora | 1 | Quien corre sobre el suelo helado resbala y pierde el control 0,5 s |
| II | Barrera cristalina | Activa | 2 | 20 / 10 s. Bloquea el siguiente golpe en 2 s |
| II | Reflejo de cristal | Mejora | 1 | La barrera devuelve el proyectil que bloquea |
| III | Muro de hielo | Activa | 2 | 25 / 12 s. Muro de 4 unidades durante 5 s; se rompe con 3 golpes |
| III | Témpano | Pasiva | 1 | Cuando se rompe tu muro de hielo, estalla (20 y Frío) |
| IV | Glaciar | Activa | 2 | 35 / 16 s / 40. Avalancha en línea de 6 unidades que congela a los enemigos pequeños |
| V | Invierno eterno | Pasiva | 2 | Las zonas de hielo son +50 % más grandes y duraderas |

**Rama Sangre fría (supervivencia)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Calma | Pasiva | 1 | +15 de maná máximo |
| I | Paso escarchado | Pasiva | 1 | Al esquivar dejas suelo helado durante 1,5 s |
| II | Prisión breve | Activa | 2 | 30 / 12 s / 10. Inmoviliza 1,5 s a un enemigo pequeño; interrumpe cargas |
| II | Armadura de escarcha | Pasiva | 1 | −10 % de daño recibido; quien te golpea cuerpo a cuerpo recibe Frío |
| III | Mente fría | Pasiva | 1 | Congelar a un enemigo devuelve 5 de maná |
| III | Hibernación | Activa | 2 | 25 / 30 s. Te encierras en hielo 2 s: inmune y recuperas el 20 % de vida |
| IV | Fractura glacial | Activa | 2 | 40 / 10 s / 55. Doble daño contra objetivos con Frío; consume el Frío |
| V | Cero absoluto | Pasiva | 2 | La Fractura glacial hace triple daño a enemigos congelados |

**Definitiva — Era glacial** (5 PA): 60 / 40 s. Congela 2 s a los enemigos normales a menos de 8
unidades; ralentiza a los jefes 4 s.

### 3.3 Rayo — velocidad y encadenamiento

Estado propio: **Marca eléctrica** (tres marcas provocan una descarga). Fuerte contra autómatas y
criaturas de agua; débil contra criaturas de tierra.

**Rama Descarga (ataque)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Descarga | Activa | 2 | 6 / 0,35 s / 10. Marca eléctrica |
| I | Doble descarga | Mejora | 1 | Cada tercera Descarga lanza dos |
| II | Salto voltaico | Activa | 2 | 18 / 4 s / 16. Salta a 3 enemigos a menos de 4 unidades |
| II | Conductor | Mejora | 1 | El Salto voltaico alcanza 2 enemigos más |
| III | Arco persistente | Activa | 2 | 24 / 8 s / 12 cada 0,25 s. Haz continuo de 2 s; te mueves despacio mientras dura |
| III | Sobrecarga de marca | Pasiva | 1 | La descarga de tres marcas hace 20 en lugar de 10 |
| IV | Convergencia | Activa | 2 | 40 / 12 s / 20 + 15 por marca. Consume las marcas |
| V | Tormenta cautiva | Pasiva | 2 | La Convergencia pasa las marcas sobrantes al enemigo más cercano |

**Rama Relámpago (movilidad)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Paso relámpago | Activa | 2 | 15 / 3 s / 12. Desplazamiento de 4 unidades que daña al pasar |
| I | Estela estática | Mejora | 1 | El paso deja una línea eléctrica de 1 s que marca |
| II | Reflejos | Pasiva | 1 | −15 % de recarga de esquiva |
| II | Doble paso | Mejora | 1 | El Paso relámpago tiene dos cargas |
| III | Sobrecarga | Activa | 2 | 25 / 15 s. +25 % de velocidad y −25 % de recargas durante 5 s |
| III | Contraataque eléctrico | Pasiva | 1 | La esquiva perfecta marca al atacante |
| IV | Rayo en botella | Activa | 2 | 30 / 14 s / 30. Te conviertes en rayo 1 s y atraviesas hasta 8 unidades |
| V | Velocidad del trueno | Pasiva | 2 | Cada enemigo derrotado durante la Sobrecarga la alarga 1 s |

**Rama Tormenta (área)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Chispazo | Pasiva | 1 | El último golpe del combo marca |
| I | Campo estático | Activa | 2 | 20 / 7 s. Área de 3 s a tu alrededor que marca a quien entra |
| II | Pararrayos | Activa | 2 | 22 / 9 s / 10 por segundo. Poste de 6 s que lanza rayos a los enemigos cercanos |
| II | Toma de tierra | Pasiva | 1 | Pararrayos y campos duran +50 % |
| III | Trueno | Activa | 2 | 28 / 10 s / 15. Onda de 5 unidades que aturde 0,8 s a los enemigos marcados |
| III | Carga acumulada | Pasiva | 1 | +2 % de daño de rayo por enemigo marcado a menos de 6 unidades (hasta +10 %) |
| IV | Tormenta | Activa | 2 | 45 / 20 s / 25 × 8. Ocho rayos caen en 6 s sobre un área grande |
| V | Ojo de la tormenta | Pasiva | 2 | Durante la Tormenta no recibes daño a distancia |

**Definitiva — Juicio del cielo** (5 PA): 60 / 35 s. Durante 3 s cae un rayo de 40 cada 0,5 s sobre cada
enemigo marcado.

### 3.4 Sombra — engaño y debilitación

Estado propio: **Marca de sombra** (hasta 3 por enemigo). Fuerte contra humanos y enemigos con escudo;
débil contra criaturas de luz y anómalos.

**Rama Umbra (marcas)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Dardo umbrío | Activa | 2 | 8 / 0,5 s / 12. Aplica una marca de sombra |
| I | Dardo triple | Mejora | 1 | Tres dardos en abanico; coste 14 |
| II | Desgarro | Activa | 2 | 35 / 10 s / 15 por marca. Consume las marcas |
| II | Herida abierta | Pasiva | 1 | Cada marca de sombra hace 2 de daño por segundo |
| III | Lazo umbrío | Activa | 2 | 20 / 8 s. Atrae a un enemigo pequeño hacia ti, o a ti hacia uno grande |
| III | Profundidad | Pasiva | 1 | Hasta 5 marcas por enemigo |
| IV | Eclipse | Activa | 2 | 40 / 15 s / 30. Esfera lenta que marca todo lo que toca y explota al final |
| V | Cosecha | Pasiva | 2 | Si el Desgarro mata, las marcas que sobran pasan a los enemigos cercanos |

**Rama Velo (sigilo y evasión)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Velo | Activa | 2 | 15 / 8 s. Invisible 1,5 s: los enemigos pierden tu rastro |
| I | Paso en las sombras | Mejora | 1 | El primer golpe desde el Velo hace +100 % |
| II | Silueta | Pasiva | 1 | La esquiva deja un señuelo de 1 s que atrae los ataques |
| II | Fundirse | Pasiva | 1 | +20 % de velocidad durante el Velo |
| III | Doble sombra | Activa | 2 | 25 / 14 s. Un doble repite tus ataques al 40 % durante 5 s |
| III | Ojos de la noche | Pasiva | 1 | Ves a los enemigos ocultos y la vida de los marcados |
| IV | Paso del vacío | Activa | 2 | 20 / 6 s. Apareces detrás de un enemigo marcado |
| V | Sin rastro | Pasiva | 2 | El Velo se activa solo al bajar del 20 % de vida (una vez por combate) |

**Rama Ruina (debilitación y drenaje)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Drenaje | Activa | 2 | 0 / 5 s / 8. Recupera 6 de maná por marca del objetivo |
| I | Debilitar | Pasiva | 1 | Los enemigos marcados hacen −10 % de daño |
| II | Eco oscuro | Activa | 2 | 20 / 6 s. Tu siguiente ataque se repite al 50 % sobre los marcados |
| II | Sed | Pasiva | 1 | El Drenaje también cura 3 de vida por marca |
| III | Fragilidad | Activa | 2 | 25 / 12 s. El objetivo recibe +25 % de daño durante 6 s |
| III | Contagio | Pasiva | 1 | Cuando muere un enemigo marcado, sus marcas pasan al más cercano |
| IV | Pacto de sombra | Activa | 2 | 15 % de tu vida / 20 s. Recuperas todo el maná |
| V | Ruina total | Pasiva | 2 | La Fragilidad afecta a todos los enemigos marcados a menos de 6 unidades |

**Definitiva — Noche cerrada** (5 PA): 50 / 40 s. Oscuridad de 6 s en un área grande: los enemigos de
dentro solo pueden atacarte si están pegados a ti y reciben 3 marcas.

### 3.5 Tierra — peso, defensa y terreno

Estado propio: **Fisura** (−20 % de defensa y no puede bloquear durante 5 s; tres fisuras derriban 1 s).
Fuerte contra autómatas y enemigos con coraza; débil contra voladores y criaturas de agua.

**Rama Roca (ataque)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Canto rodado | Activa | 2 | 10 / 0,8 s / 20. Proyectil lento que empuja mucho y aplica Fisura |
| I | Rodar | Mejora | 1 | El canto sigue rodando 4 unidades y golpea a todo lo que encuentra |
| II | Púas de piedra | Activa | 2 | 18 / 5 s / 22. Línea de púas de 5 unidades que sale del suelo |
| II | Peso de la montaña | Pasiva | 1 | Las habilidades de tierra empujan +50 % |
| III | Lluvia de grava | Activa | 2 | 24 / 8 s / 5 × 8. Área de 3 unidades; aplica Fisura |
| III | Corazón de granito | Pasiva | 1 | +20 % de daño contra enemigos con Fisura |
| IV | Meteoro de piedra | Activa | 2 | 38 / 14 s / 70. Cae al cabo de 1 s (con aviso en el suelo) y derriba |
| V | Avalancha | Mejora | 1 | El meteoro deja 3 rocas que bloquean el paso y estallan a los 3 s (20) |

**Rama Bastión (defensa)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Piel de piedra | Activa | 2 | 15 / 12 s. −40 % de daño recibido y −20 % de velocidad durante 4 s |
| I | Raíces de roca | Mejora | 1 | Con Piel de piedra no te pueden empujar |
| II | Muro de tierra | Activa | 2 | 20 / 10 s. Muro de 3 unidades durante 6 s que detiene proyectiles |
| II | Fortificar | Pasiva | 1 | +0,08 de defensa permanente |
| III | Escudo de rocas | Activa | 2 | 25 / 15 s. Tres rocas orbitan a tu alrededor; cada una bloquea un golpe |
| III | Contraataque pétreo | Pasiva | 1 | Cada roca que bloquea golpea al atacante (15) |
| IV | Fortaleza | Activa | 2 | 35 / 25 s. Círculo de 4 unidades durante 6 s: tú y tus aliados recibís −30 % de daño y los enemigos van más lentos |
| V | Inamovible | Pasiva | 2 | Con Piel de piedra eres inmune a aturdimientos y derribos |

**Rama Temblor (control)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Pisotón | Activa | 2 | 12 / 4 s / 10. Anillo de 2,5 unidades que aturde 0,5 s a los enemigos pequeños |
| I | Réplica | Mejora | 1 | El Pisotón se repite 0,5 s después |
| II | Grieta | Activa | 2 | 20 / 8 s / 12. Grieta en línea que derriba 1 s |
| II | Terreno firme | Pasiva | 1 | Inmune a las ralentizaciones del terreno (barro, hielo, telarañas) |
| III | Arenas movedizas | Activa | 2 | 25 / 10 s. Zona de 4 s: −60 % de velocidad y los enemigos no pueden esquivar ni saltar |
| III | Ondas | Pasiva | 1 | +50 % de radio del Pisotón |
| IV | Terremoto | Activa | 2 | 45 / 20 s / 10 cada 0,5 s. Temblor de 3 s en 7 unidades; derriba a los pequeños cada segundo |
| V | Falla | Pasiva | 2 | El Terremoto abre grietas que siguen activas 4 s más |

**Definitiva — Despertar de la montaña** (5 PA): 60 / 45 s. Un gólem de roca lucha a tu lado 15 s; sus
golpes aplican Fisura.

### 3.6 Luz — protección, curación y revelación

Estado propio: **Deslumbrado** (pierde el objetivo 1 s y su siguiente aviso dura el doble). Fuerte contra
anómalos y criaturas de sombra; débil contra autómatas.

**Rama Resplandor (ataque)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Destello | Activa | 2 | 8 / 0,5 s / 12. Rayo corto y rápido |
| I | Haz doble | Mejora | 1 | El Destello atraviesa al primer enemigo |
| II | Lanza solar | Activa | 2 | 20 / 6 s / 35. Tras 0,4 s de carga, haz de 8 unidades |
| II | Purificar | Pasiva | 1 | +40 % de daño de luz contra enemigos anómalos |
| III | Prisma | Activa | 2 | 24 / 9 s. Cristal que divide tus Destellos en tres durante 6 s |
| III | Ceguera | Pasiva | 1 | La Lanza solar deslumbra 1,5 s |
| IV | Nova | Activa | 2 | 40 / 15 s / 45. Explosión de luz de 5 unidades que deslumbra |
| V | Amanecer | Pasiva | 2 | Si la Nova alcanza a 3 enemigos o más, recuperas el 20 % de vida |

**Rama Égida (protección)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Escudo de luz | Activa | 2 | 18 / 12 s. Absorbe 30 de daño durante 5 s |
| I | Escudo reflejante | Mejora | 1 | Al romperse, deslumbra a los enemigos cercanos |
| II | Halo | Pasiva | 1 | Tras 4 s sin recibir daño, el siguiente golpe que recibes se reduce a la mitad |
| II | Sello protector | Activa | 2 | 22 / 14 s. Círculo de 3 unidades durante 5 s que destruye los proyectiles enemigos |
| III | Guardián de luz | Activa | 2 | 30 / 20 s. Un espíritu protege a un aliado o escoltado y bloquea 3 golpes |
| III | Égida firme | Pasiva | 1 | El Escudo de luz absorbe +50 % |
| IV | Santuario | Activa | 2 | 40 / 30 s. Zona de 4 unidades durante 6 s: recuperas un 3 % de vida por segundo y no puedes bajar de 1 |
| V | Juramento | Pasiva | 2 | El Escudo de luz se lanza solo al bajar del 30 % de vida (una vez cada 60 s) |

**Rama Alba (curación y apoyo)**

| Nv | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Respiro | Activa | 2 | 20 / 15 s. Recuperas el 25 % de vida en 1 s (un golpe lo interrumpe) |
| I | Luz serena | Pasiva | 1 | +1 de regeneración de maná por segundo |
| II | Purgar | Activa | 2 | 15 / 10 s. Quita todos los estados negativos |
| II | Revelar | Pasiva | 1 | Ves trampas, enemigos ocultos y puntos débiles de los jefes (+15 % de daño en ellos) |
| III | Bendición | Activa | 2 | 25 / 20 s. Durante 8 s, +20 % de daño y −20 % de recargas |
| III | Fe | Pasiva | 1 | El Respiro no se interrumpe y cura un 10 % más |
| IV | Faro interior | Pasiva | 2 | Cada 30 s, el siguiente hechizo de luz no cuesta maná |
| V | Segunda alba | Pasiva | 2 | Una vez por zona, al caer, vuelves con el 50 % de vida y una Nova gratis |

**Definitiva — Sol de mediodía** (5 PA): 60 / 45 s. Durante 6 s, un sol sobre el héroe hace 10 cada 0,5 s
y deslumbra a los enemigos a menos de 6 unidades, y te cura un 2 % de vida por segundo.

## 4. Técnicas de gremio

Árbol de 9 nodos por gremio, en tres rangos. Cada nodo cuesta 1 mérito de gremio. El rango se alcanza
con la línea de misiones del gremio (rango 1 al jurar, rango 2 en el capítulo 4, rango 3 en el 5).

| Gremio | Rango 1 | Rango 2 | Rango 3 |
|---|---|---|---|
| **Faro** | **Escudo de vigía:** bloqueo de 0,5 s, recarga 6 s · **Farol de guardia:** el héroe lleva luz que revela emboscadas · **Disciplina:** +10 % de defensa durante escoltas | **Botiquín del Faro:** las pociones quitan estados · **Vendaje rápido:** las pociones se beben en 0,5 s · **Protocolo:** los escoltados tienen +50 % de vida | **Señal de rescate:** una vez por zona, vuelves al último punto seguro con la vida llena · **Bastión:** el bloqueo perfecto devuelve el golpe · **Vigilia:** los ataques de los jefes tienen un aviso sonoro extra |
| **Brasa** | **Embestida:** la esquiva hace 8 al atravesar enemigos · **Equipo ligero:** +10 % de velocidad · **Apuesta:** contratos de alto riesgo con +50 % de recompensa | **Sin red:** +20 % de daño con menos del 50 % de vida · **Gancho:** cuerda para atajos en rutas peligrosas · **Adrenalina:** cada enemigo derrotado cura el 5 % de vida | **Carga de caldera:** mantener ataque 0,8 s hace un tajo que avanza 3 unidades (45) · **Temeridad:** esquivar a través de un ataque da +30 % de daño 2 s · **Ruta prohibida:** acceso a pasos peligrosos con cofres propios |
| **Archivo** | **Lectura de la Fractura:** los avisos de los enemigos anómalos se ven 0,2 s antes · **Catálogo:** el bestiario muestra debilidades desde el primer encuentro · **Sellos:** abre cerraduras arcanas | **Catalizador:** +20 de maná y +1 de regeneración · **Resonancia:** las afinidades secundarias llegan al nivel IV · **Muestras:** los anómalos sueltan materiales de investigación | **Contención:** +40 % de daño a enemigos anómalos · **Doble foco:** 5.ª ranura de habilidad · **Registro de Arel:** +3 PA y una escena de historia |
| **Liga** | **Contactos:** −15 % en las tiendas · **Mapas de la Liga:** viaje rápido entre estaciones · **Trueque:** +25 % al vender materiales | **Trampa de caravanero:** cepo que inmoviliza 2 s (2 cargas) · **Caravana:** cofre de suministros en cada estación · **Mediación:** opciones de diálogo para evitar combates contra humanos | **Ruta segura:** viajar entre sedes no tiene encuentros y recuperas las pociones · **Red de favores:** una vez por zona, llamas a un aliado que lucha contigo 20 s · **Fondos comunes:** +1 poción y reparación gratis |

## 5. Construcciones de ejemplo (para probar el equilibrio)

Con unos 110 PA al final de la campaña:

| Estilo | Principal | Secundaria | Tronco común | Idea |
|---|---|---|---|---|
| Artillero | Fuego completo (≈ 41 PA) | Rayo hasta III (≈ 20) | Instinto y Oficio | Presión a distancia, encadenar marcas y quemaduras |
| Guardián | Tierra completa | Luz hasta III | Resistencia y Acero | Aguantar en primera línea y proteger escoltas |
| Duelista | Sombra completa | Hielo hasta III | Acero e Instinto | Marcar, congelar y rematar con la espada |
| Sanador de campo | Luz completa | Tierra hasta III | Resistencia | Sobrevivir a todo y castigar a los anómalos |

## 6. Implementación

- Cada nodo será una ficha: las activas, `SkillData` (`data/skills`); las pasivas y mejoras, una ficha
  de modificador por nodo, cuando se programe el árbol (Fase 5 de la hoja de ruta).
- Hoy existen en el juego Chispa y Estallido. Las activas de cada afinidad se pueden reutilizar entre
  ellas por **tipo**: proyectil, área a tu alrededor, zona en el suelo, línea, desplazamiento, mejora
  personal, escudo e invocación. Cada tipo se programa una vez; el resto son fichas y efectos visuales.
- Arte necesario por afinidad: un proyectil, un impacto, una zona, una explosión grande y la definitiva.
