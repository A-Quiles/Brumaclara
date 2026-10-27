# Lista de habilidades

Generada desde `data/trees/*.json` con `python3 tools/data/tree_doc.py`: no se edita a mano.
El diseño (reglas, PA, niveles, estados) está en `docs/arbol_habilidades.md`.

Columnas de las activas: maná / recarga / daño, y lo que hacen. Cada activa tiene al menos una
mejora; las mejoras piden su habilidad y las activas de nivel II o más piden otra activa de su rama
de un nivel inferior.

## Resumen

| Árbol | Activas | Mejoras | Pasivas | Definitiva | Nodos |
|---|---|---|---|---|---|
| Fuego | 21 | 22 | 11 | 1 | 55 |
| Hielo | 21 | 21 | 10 | 1 | 53 |
| Rayo | 21 | 22 | 9 | 1 | 53 |
| Sombra | 21 | 21 | 11 | 1 | 54 |
| Tierra | 21 | 21 | 8 | 1 | 51 |
| Luz | 21 | 21 | 11 | 1 | 54 |
| Aventurero | 2 | 0 | 30 | 0 | 32 |

## Fuego

### Llama (proyectiles)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Chispa | Activa | 2 | 8 / 0,45 s / 18. Proyectil rápido que estalla al primer impacto |
| I | Chispa doble | Mejora | 1 | Chispa lanza dos proyectiles en abanico; coste 12 |
| II | Lanza de fuego | Activa | 2 | 14 / 3 s / 26. Atraviesa a todos los enemigos en línea |
| II | Lanza de fuego certera | Mejora | 1 | Lanza de fuego: +30 % de daño |
| II | Abanico de brasas | Activa | 2 | 14 / 3 s / 9 × 5. Cinco brasas en abanico: de cerca aciertan todas |
| II | Combustión | Pasiva | 1 | Los proyectiles de fuego aplican Quemadura |
| III | Chispa rebotante | Mejora | 1 | Chispa salta a un segundo enemigo a menos de 4 unidades |
| III | Bola saltarina | Activa | 2 | 18 / 5 s / 20. Rebota entre tres enemigos cercanos |
| III | Ráfaga ígnea | Activa | 2 | 20 / 6 s / 14 × 4. Cuatro disparos seguidos hacia donde apuntas |
| III | Puntería ardiente | Pasiva | 1 | +20 % de daño de fuego a más de 5 unidades |
| IV | Cometa | Activa | 2 | 30 / 9 s / 45. Proyectil grande y lento que explota en área |
| IV | Abanico de brasas certero | Mejora | 1 | Abanico de brasas: +30 % de daño |
| IV | Bola saltarina certera | Mejora | 1 | Bola saltarina: +30 % de daño |
| IV | Cadena de fuego | Activa | 2 | 26 / 8 s / 22. Salta a cuatro enemigos y los quema |
| V | Lluvia de brasas | Mejora | 1 | El Cometa deja caer 5 brasas alrededor (10 cada una) |
| V | Cadena de fuego encadenada | Mejora | 1 | Cadena de fuego: +2 saltos |
| V | Ráfaga ígnea certera | Mejora | 1 | Ráfaga ígnea: +30 % de daño |

### Hoguera (áreas)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Estallido | Activa | 2 | 25 / 4 s / 30. Anillo alrededor del héroe que empuja fuerte |
| I | Anillo amplio | Mejora | 1 | +40 % de radio del Estallido |
| I | Látigo ígneo | Activa | 2 | 12 / 3 s / 16. Latigazo de fuego en línea corta |
| I | Látigo ígneo largo | Mejora | 1 | Látigo ígneo: +2 unidades de alcance |
| II | Rastro ardiente | Activa | 2 | 20 / 6 s / 6 cada 0,5 s. Zona de 3 s en el suelo que quema |
| II | Rastro ardiente duradero | Mejora | 1 | Rastro ardiente: +50 % de duración |
| II | Brasero | Activa | 2 | 22 / 12 s / 5 cada 0,5 s. Un círculo de brasas te sigue 4 s y quema |
| II | Suelo encendido | Pasiva | 1 | Al esquivar dejas una llama de 1,5 s (8 de daño) |
| III | Muro de llamas | Activa | 2 | 28 / 10 s / 8 cada 0,5 s. Línea de fuego de 5 unidades durante 4 s; detiene proyectiles enemigos |
| III | Muro de llamas duradero | Mejora | 1 | Muro de llamas: +50 % de duración |
| III | Erupción | Activa | 2 | 30 / 11 s / 40. Tras 0,5 s, el suelo estalla a tu alrededor |
| III | Hoguera persistente | Pasiva | 1 | Las zonas de fuego duran +50 % |
| IV | Columna ígnea | Activa | 2 | 35 / 12 s / 60. Columna en el punto apuntado tras 0,6 s de aviso |
| IV | Columna ígnea devastadora | Mejora | 1 | Columna ígnea: +30 % de daño y de radio |
| IV | Brasero duradero | Mejora | 1 | Brasero: +50 % de duración |
| IV | Erupción devastadora | Mejora | 1 | Erupción: +30 % de daño y de radio |
| V | Lluvia de meteoros | Activa | 3 | 42 / 18 s / 30 × 6. Seis meteoros caen sobre un área grande |
| V | Lluvia de meteoros torrencial | Mejora | 1 | Lluvia de meteoros: +4 impactos |
| V | Infierno contenido | Pasiva | 2 | Los enemigos que mueren con Quemadura explotan (15 en área) |

### Brasa interior (potenciación)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Ascua viva | Activa | 2 | 15 / 8 s. El siguiente golpe de espada hace +100 % y quema |
| I | Ascua viva prolongada | Mejora | 1 | Ascua viva: +50 % de duración |
| I | Carga ígnea | Activa | 2 | 16 / 6 s / 18. Embestida de 5 unidades que deja un rastro ardiente |
| I | Calor corporal | Pasiva | 1 | +10 de maná máximo |
| II | Carga ígnea doble | Mejora | 1 | Carga ígnea: Una carga más |
| II | Escudo de brasas | Activa | 2 | 18 / 14 s. Absorbe 25 de daño; quien lo rompe se quema |
| II | Filo encendido | Pasiva | 1 | El último golpe del combo aplica Quemadura |
| II | Avivar | Pasiva | 1 | Golpear con la espada a un enemigo quemado devuelve 3 de maná |
| III | Sobrecalentamiento | Activa | 2 | 20 / 18 s. Durante 6 s, +30 % de daño de fuego y +15 % de daño recibido |
| III | Sobrecalentamiento prolongado | Mejora | 1 | Sobrecalentamiento: +50 % de duración |
| III | Escudo de brasas reforzado | Mejora | 1 | Escudo de brasas: +50 % de absorción y un bloqueo más |
| III | Piel de brasas | Pasiva | 1 | Quien te golpea cuerpo a cuerpo se quema |
| IV | Pira purificadora | Activa | 2 | 30 / 25 s. Te envuelves en llamas 0,8 s y recuperas el 20 % de vida |
| IV | Ritmo de la forja | Activa | 2 | 24 / 16 s. +15 % de daño y de velocidad durante 6 s |
| IV | Ritmo de la forja prolongado | Mejora | 1 | Ritmo de la forja: +50 % de duración |
| IV | Fénix menor | Pasiva | 2 | Una vez por zona, al caer, vuelves con el 30 % de vida y un Estallido gratis |
| V | Pira purificadora serena | Mejora | 1 | Pira purificadora: −30 % de recarga |
| V | Corazón de horno | Pasiva | 2 | +50 % de regeneración de maná mientras haya un enemigo quemado a menos de 6 unidades |

### Definitiva

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| V | Ruptura ígnea | Definitiva | 5 | 50 / 30 s / 120 en total. Se canaliza 0,5 s (interrumpible) y abre una línea de explosiones de 10 unidades. |

## Hielo

### Escarcha (proyectiles)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Aguja de escarcha | Activa | 2 | 8 / 0,5 s / 14. Aplica Frío |
| I | Esquirlas | Mejora | 1 | La aguja se rompe en 3 esquirlas al impactar (5 cada una) |
| I | Copo errante | Activa | 2 | 12 / 2,5 s / 16. Copo lento que estalla en área y enfría |
| I | Copo errante certero | Mejora | 1 | Copo errante: +30 % de daño |
| II | Lanza glacial | Activa | 2 | 16 / 4 s / 30. Atraviesa y aplica 2 cargas de Frío |
| II | Lanza glacial certera | Mejora | 1 | Lanza glacial: +30 % de daño |
| II | Abanico de escarcha | Activa | 2 | 14 / 3 s / 12 × 3. Tres agujas abiertas que enfrían |
| II | Frío penetrante | Pasiva | 1 | El Frío dura 2 s más |
| III | Ráfaga helada | Activa | 2 | 22 / 7 s / 18. Cono de 4 unidades que empuja y aplica 2 cargas de Frío |
| III | Ráfaga helada devastadora | Mejora | 1 | Ráfaga helada: +30 % de daño y de radio |
| III | Cadena de escarcha | Activa | 2 | 20 / 6 s / 18. Salta a tres enemigos y los enfría |
| III | Escarcha certera | Pasiva | 1 | +25 % de daño a enemigos con Frío |
| IV | Tormenta de agujas | Activa | 2 | 32 / 12 s / 8 × 8. Ocho agujas en 1 s hacia donde apuntas |
| IV | Tormenta de agujas certera | Mejora | 1 | Tormenta de agujas: +30 % de daño |
| IV | Abanico de escarcha certero | Mejora | 1 | Abanico de escarcha: +30 % de daño |
| IV | Cadena de escarcha encadenada | Mejora | 1 | Cadena de escarcha: +2 saltos |
| V | Corazón de invierno | Pasiva | 2 | Congelar a un enemigo reduce 2 s las recargas de hielo |

### Glaciar (terreno)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Suelo helado | Activa | 2 | 20 / 6 s. Zona de 3 s que ralentiza un 40 % |
| I | Hielo resbaladizo | Mejora | 1 | Quien corre sobre el suelo helado resbala y pierde el control 0,5 s |
| II | Barrera cristalina | Activa | 2 | 20 / 10 s. Bloquea el siguiente golpe en 2 s |
| II | Reflejo de cristal | Mejora | 1 | La barrera devuelve el proyectil que bloquea |
| II | Pilar de hielo | Activa | 2 | 18 / 7 s / 34. Un pilar brota delante tras 0,4 s y enfría dos veces |
| II | Pilar de hielo devastador | Mejora | 1 | Pilar de hielo: +30 % de daño y de radio |
| III | Muro de hielo | Activa | 2 | 25 / 12 s. Muro de 4 unidades durante 5 s; se rompe con 3 golpes |
| III | Muro de hielo macizo | Mejora | 1 | Muro de hielo: +2 unidades y +2 golpes |
| III | Espejo helado | Activa | 2 | 22 / 12 s. Dos cristales que bloquean el paso y estallan (25) al romperse |
| III | Témpano | Pasiva | 1 | Cuando se rompe tu muro de hielo, estalla (20 y Frío) |
| IV | Glaciar | Activa | 2 | 35 / 16 s / 40. Avalancha en línea de 6 unidades que congela a los enemigos pequeños |
| IV | Glaciar largo | Mejora | 1 | Glaciar: +2 unidades de alcance |
| IV | Espejo helado macizo | Mejora | 1 | Espejo helado: +2 unidades y +2 golpes |
| V | Ventisca | Activa | 3 | 40 / 18 s / 12 × 10. Una ventisca de 4 s golpea y enfría el área |
| V | Ventisca torrencial | Mejora | 1 | Ventisca: +4 impactos |
| V | Invierno eterno | Pasiva | 2 | Las zonas de hielo son +50 % más grandes y duraderas |

### Sangre fría (supervivencia)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Aliento glacial | Activa | 2 | 16 / 6 s / 6 cada 0,25 s. Aliento helado continuo de 1,5 s |
| I | Patinar | Activa | 2 | 10 / 4 s / 8. Te deslizas 5 unidades y dejas hielo que enfría |
| I | Calma | Pasiva | 1 | +15 de maná máximo |
| I | Paso escarchado | Pasiva | 1 | Al esquivar dejas suelo helado durante 1,5 s |
| II | Prisión breve | Activa | 2 | 30 / 12 s / 10. Inmoviliza 1,5 s a un enemigo pequeño; interrumpe cargas |
| II | Prisión breve certera | Mejora | 1 | Prisión breve: +30 % de daño |
| II | Coraza de escarcha | Activa | 2 | 20 / 14 s. Absorbe 35 de daño; quien la rompe queda helado |
| II | Armadura de escarcha | Pasiva | 1 | −10 % de daño recibido; quien te golpea cuerpo a cuerpo recibe Frío |
| III | Hibernación | Activa | 2 | 25 / 30 s. Te encierras en hielo 2 s: inmune y recuperas el 20 % de vida |
| III | Hibernación serena | Mejora | 1 | Hibernación: −30 % de recarga |
| III | Patinar doble | Mejora | 1 | Patinar: Una carga más |
| III | Mente fría | Pasiva | 1 | Congelar a un enemigo devuelve 5 de maná |
| IV | Fractura glacial | Activa | 2 | 40 / 10 s / 55. Doble daño contra objetivos con Frío; consume el Frío |
| IV | Fractura glacial devastadora | Mejora | 1 | Fractura glacial: +30 % de daño y de radio |
| IV | Aliento glacial sostenido | Mejora | 1 | Aliento glacial: +1 s de duración |
| IV | Coraza de escarcha reforzada | Mejora | 1 | Coraza de escarcha: +50 % de absorción y un bloqueo más |
| V | Corazón helado | Activa | 3 | 30 / 20 s. +30 % de daño de hielo y −15 % de daño recibido durante 8 s |
| V | Corazón helado prolongado | Mejora | 1 | Corazón helado: +50 % de duración |
| V | Cero absoluto | Pasiva | 2 | La Fractura glacial hace triple daño a enemigos congelados |

### Definitiva

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| V | Era glacial | Definitiva | 5 | 60 / 40 s. Congela 2 s a los enemigos normales a menos de 8 unidades; ralentiza a los jefes 4 s. |

## Rayo

### Descarga (ataque)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Descarga | Activa | 2 | 6 / 0,35 s / 10. Marca eléctrica |
| I | Doble descarga | Mejora | 1 | Cada tercera Descarga lanza dos |
| I | Tridente | Activa | 2 | 10 / 1,5 s / 8 × 3. Tres descargas rápidas en abanico cerrado |
| I | Tridente certero | Mejora | 1 | Tridente: +30 % de daño |
| II | Salto voltaico | Activa | 2 | 18 / 4 s / 16. Salta a 3 enemigos a menos de 4 unidades |
| II | Conductor | Mejora | 1 | El Salto voltaico alcanza 2 enemigos más |
| II | Bola de plasma | Activa | 2 | 16 / 5 s / 14. Esfera lenta que atraviesa y marca todo lo que toca |
| II | Bola de plasma certera | Mejora | 1 | Bola de plasma: +30 % de daño |
| III | Arco persistente | Activa | 2 | 24 / 8 s / 12 cada 0,25 s. Haz continuo de 2 s; te mueves despacio mientras dura |
| III | Arco persistente sostenido | Mejora | 1 | Arco persistente: +1 s de duración |
| III | Lanza de trueno | Activa | 2 | 24 / 7 s / 30. Rayo en línea de 7 unidades tras 0,2 s |
| III | Sobrecarga de marca | Pasiva | 1 | La descarga de tres marcas hace 20 en lugar de 10 |
| IV | Convergencia | Activa | 2 | 40 / 12 s / 20 + 15 por marca. Consume las marcas |
| IV | Convergencia devastadora | Mejora | 1 | Convergencia: +30 % de daño y de radio |
| IV | Imán voltaico | Activa | 2 | 16 / 8 s. Atrae al enemigo más cercano y lo deja aturdido 0,4 s |
| IV | Lanza de trueno larga | Mejora | 1 | Lanza de trueno: +2 unidades de alcance |
| V | Imán voltaico firme | Mejora | 1 | Imán voltaico: −35 % de recarga |
| V | Tormenta cautiva | Pasiva (próximamente) | 2 | La Convergencia pasa las marcas sobrantes al enemigo más cercano |

### Relámpago (movilidad)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Paso relámpago | Activa | 2 | 15 / 3 s / 12. Desplazamiento de 4 unidades que daña al pasar |
| I | Estela estática | Mejora | 1 | El paso deja una línea eléctrica de 1 s que marca |
| I | Impulso | Activa | 2 | 8 / 8 s. +40 % de velocidad durante 2,5 s |
| I | Impulso prolongado | Mejora | 1 | Impulso: +50 % de duración |
| II | Doble paso | Mejora | 1 | El Paso relámpago tiene dos cargas |
| II | Destello galvánico | Activa | 2 | 16 / 6 s. Apareces detrás del enemigo marcado más cercano |
| II | Destello galvánico ágil | Mejora | 1 | Destello galvánico: −35 % de recarga |
| II | Reflejos | Pasiva | 1 | −15 % de recarga de esquiva |
| III | Sobrecarga | Activa | 2 | 25 / 15 s. +25 % de velocidad y −25 % de recargas durante 5 s |
| III | Sobrecarga prolongada | Mejora | 1 | Sobrecarga: +50 % de duración |
| III | Relevo | Activa | 2 | 12 / 6 s / 10. Tres pasos cortos que se encadenan |
| III | Contraataque eléctrico | Pasiva | 1 | La esquiva perfecta marca al atacante |
| IV | Rayo en botella | Activa | 2 | 30 / 14 s / 30. Te conviertes en rayo 1 s y atraviesas hasta 8 unidades |
| IV | Rayo en botella doble | Mejora | 1 | Rayo en botella: Una carga más |
| IV | Relevo doble | Mejora | 1 | Relevo: Una carga más |
| V | Velocidad del trueno | Pasiva (próximamente) | 2 | Cada enemigo derrotado durante la Sobrecarga la alarga 1 s |

### Tormenta (área)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Campo estático | Activa | 2 | 20 / 7 s. Área de 3 s a tu alrededor que marca a quien entra |
| I | Campo estático duradero | Mejora | 1 | Campo estático: +50 % de duración |
| I | Chispazo | Pasiva | 1 | El último golpe del combo marca |
| II | Pararrayos | Activa | 2 | 22 / 9 s / 10 por segundo. Poste de 6 s que lanza rayos a los enemigos cercanos |
| II | Pararrayos duradero | Mejora | 1 | Pararrayos: +50 % de duración |
| II | Escudo estático | Activa | 2 | 18 / 12 s. Bloquea dos golpes y descarga 15 en quien golpea |
| II | Toma de tierra | Pasiva | 1 | Pararrayos y campos duran +50 % |
| III | Trueno | Activa | 2 | 28 / 10 s / 15. Onda de 5 unidades que aturde 0,8 s a los enemigos marcados |
| III | Trueno amplio | Mejora | 1 | Trueno: +35 % de radio |
| III | Jaula eléctrica | Activa | 2 | 22 / 10 s / 6 cada 0,5 s. Jaula de 3 s que frena y marca |
| III | Carga acumulada | Pasiva | 1 | +2 % de daño de rayo por enemigo marcado a menos de 6 unidades (hasta +10 %) |
| IV | Tormenta | Activa | 2 | 45 / 20 s / 25 × 8. Ocho rayos caen en 6 s sobre un área grande |
| IV | Tormenta torrencial | Mejora | 1 | Tormenta: +4 impactos |
| IV | Escudo estático reforzado | Mejora | 1 | Escudo estático: +50 % de absorción y un bloqueo más |
| IV | Jaula eléctrica duradera | Mejora | 1 | Jaula eléctrica: +50 % de duración |
| V | Cielo cargado | Activa | 3 | 36 / 14 s / 50. Un rayo cae sobre el enemigo más cercano y salta a los marcados |
| V | Cielo cargado devastador | Mejora | 1 | Cielo cargado: +30 % de daño y de radio |
| V | Ojo de la tormenta | Pasiva (próximamente) | 2 | Durante la Tormenta no recibes daño a distancia |

### Definitiva

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| V | Juicio del cielo | Definitiva | 5 | 60 / 35 s. Durante 3 s cae un rayo de 40 cada 0,5 s sobre cada enemigo marcado. |

## Sombra

### Umbra (marcas)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Dardo umbrío | Activa | 2 | 8 / 0,5 s / 12. Aplica una marca de sombra |
| I | Dardo triple | Mejora | 1 | Tres dardos en abanico; coste 14 |
| II | Desgarro | Activa | 2 | 35 / 10 s / 15 por marca. Consume las marcas |
| II | Desgarro devastador | Mejora | 1 | Desgarro: +30 % de daño y de radio |
| II | Guadaña | Activa | 2 | 14 / 4 s / 20. Tajo de sombra en línea corta que marca |
| II | Herida abierta | Pasiva | 1 | Cada marca de sombra hace 2 de daño por segundo |
| III | Lazo umbrío | Activa | 2 | 20 / 8 s. Atrae a un enemigo pequeño hacia ti, o a ti hacia uno grande |
| III | Lazo umbrío firme | Mejora | 1 | Lazo umbrío: −35 % de recarga |
| III | Enjambre umbrío | Activa | 2 | 18 / 6 s / 8 × 5. Cinco dardos seguidos que marcan |
| III | Profundidad | Pasiva | 1 | Hasta 5 marcas por enemigo |
| IV | Eclipse | Activa | 2 | 40 / 15 s / 30. Esfera lenta que marca todo lo que toca y explota al final |
| IV | Eclipse certero | Mejora | 1 | Eclipse: +30 % de daño |
| IV | Enjambre umbrío certero | Mejora | 1 | Enjambre umbrío: +30 % de daño |
| IV | Guadaña larga | Mejora | 1 | Guadaña: +2 unidades de alcance |
| V | Lluvia de cuervos | Activa | 3 | 38 / 16 s / 18 × 8. Cuervos de sombra caen sobre un área |
| V | Lluvia de cuervos torrencial | Mejora | 1 | Lluvia de cuervos: +4 impactos |
| V | Cosecha | Pasiva (próximamente) | 2 | Si el Desgarro mata, las marcas que sobran pasan a los enemigos cercanos |

### Velo (sigilo y evasión)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Velo | Activa | 2 | 15 / 8 s. Invisible 1,5 s: los enemigos pierden tu rastro |
| I | Paso en las sombras | Mejora | 1 | El primer golpe desde el Velo hace +100 % |
| I | Paso fantasma | Activa | 2 | 14 / 6 s / 10. Atraviesas 4,5 unidades sin recibir daño |
| I | Paso fantasma doble | Mejora | 1 | Paso fantasma: Una carga más |
| II | Espejismo | Activa | 2 | 18 / 12 s. Invisible y +30 % de velocidad durante 2 s |
| II | Espejismo prolongado | Mejora | 1 | Espejismo: +50 % de duración |
| II | Silueta | Pasiva (próximamente) | 1 | La esquiva deja un señuelo de 1 s que atrae los ataques |
| II | Fundirse | Pasiva | 1 | +20 % de velocidad durante el Velo |
| III | Doble sombra | Activa | 2 | 25 / 14 s. Un doble repite tus ataques al 40 % durante 5 s |
| III | Doble sombra prolongado | Mejora | 1 | Doble sombra: +50 % de duración |
| III | Manto de niebla | Activa | 2 | 24 / 16 s. Niebla de 4 s a tu alrededor: −25 % de daño recibido y deslumbra |
| III | Ojos de la noche | Pasiva | 1 | Ves a los enemigos ocultos y la vida de los marcados |
| IV | Paso del vacío | Activa | 2 | 20 / 6 s. Apareces detrás de un enemigo marcado |
| IV | Paso del vacío ágil | Mejora | 1 | Paso del vacío: −35 % de recarga |
| IV | Manto de niebla duradero | Mejora | 1 | Manto de niebla: +50 % de duración |
| V | Sin rastro | Pasiva | 2 | El Velo se activa solo al bajar del 20 % de vida (una vez por combate) |

### Ruina (debilitación y drenaje)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Drenaje | Activa | 2 | 0 / 5 s / 8. Recupera 6 de maná por marca del objetivo |
| I | Drenaje devastador | Mejora | 1 | Drenaje: +30 % de daño y de radio |
| I | Maldición | Activa | 2 | 10 / 6 s / 6. Ralentiza 3 s al enemigo más cercano |
| I | Debilitar | Pasiva | 1 | Los enemigos marcados hacen −10 % de daño |
| II | Eco oscuro | Activa | 2 | 20 / 6 s. Tu siguiente ataque se repite al 50 % sobre los marcados |
| II | Eco oscuro prolongado | Mejora | 1 | Eco oscuro: +50 % de duración |
| II | Marchitar | Activa | 2 | 18 / 9 s / 5 cada 0,5 s. Zona de 4 s que vuelve frágiles a los enemigos |
| II | Sed | Pasiva | 1 | El Drenaje también cura 3 de vida por marca |
| III | Fragilidad | Activa | 2 | 25 / 12 s. El objetivo recibe +25 % de daño durante 6 s |
| III | Fragilidad devastadora | Mejora | 1 | Fragilidad: +30 % de daño y de radio |
| III | Sifón | Activa | 2 | 16 / 8 s / 14. Golpe a tu alrededor; si alcanza a alguien recuperas el 6 % de vida |
| III | Contagio | Pasiva (próximamente) | 1 | Cuando muere un enemigo marcado, sus marcas pasan al más cercano |
| IV | Pacto de sombra | Activa | 2 | 15 % de tu vida / 20 s. Recuperas todo el maná |
| IV | Pacto de sombra sereno | Mejora | 1 | Pacto de sombra: −30 % de recarga |
| IV | Maldición devastadora | Mejora | 1 | Maldición: +30 % de daño y de radio |
| IV | Pozo del vacío | Activa | 2 | 28 / 12 s / 8 cada 0,5 s. Pozo de 3 s que retiene y marca |
| V | Marchitar duradero | Mejora | 1 | Marchitar: +50 % de duración |
| V | Pozo del vacío duradero | Mejora | 1 | Pozo del vacío: +50 % de duración |
| V | Sifón amplio | Mejora | 1 | Sifón: +35 % de radio |
| V | Ruina total | Pasiva | 2 | La Fragilidad afecta a todos los enemigos marcados a menos de 6 unidades |

### Definitiva

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| V | Noche cerrada | Definitiva | 5 | 50 / 40 s. Oscuridad de 6 s en un área grande: los enemigos de dentro solo pueden atacarte si están pegados a ti y reciben 3 marcas. |

## Tierra

### Roca (ataque)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Canto rodado | Activa | 2 | 10 / 0,8 s / 20. Proyectil lento que empuja mucho y aplica Fisura |
| I | Rodar | Mejora | 1 | El canto sigue rodando 4 unidades y golpea a todo lo que encuentra |
| I | Honda | Activa | 2 | 10 / 2 s / 10 × 3. Tres piedras seguidas |
| I | Honda certera | Mejora | 1 | Honda: +30 % de daño |
| II | Púas de piedra | Activa | 2 | 18 / 5 s / 22. Línea de púas de 5 unidades que sale del suelo |
| II | Púas de piedra largo | Mejora | 1 | Púas de piedra: +2 unidades de alcance |
| II | Estalagmitas | Activa | 2 | 20 / 7 s / 22 × 4. Cuatro estalagmitas brotan delante |
| II | Peso de la montaña | Pasiva | 1 | Las habilidades de tierra empujan +50 % |
| III | Lluvia de grava | Activa | 2 | 24 / 8 s / 5 × 8. Área de 3 unidades; aplica Fisura |
| III | Lluvia de grava torrencial | Mejora | 1 | Lluvia de grava: +4 impactos |
| III | Pedrada explosiva | Activa | 2 | 22 / 7 s / 28. Roca que revienta en área y agrieta |
| III | Corazón de granito | Pasiva | 1 | +20 % de daño contra enemigos con Fisura |
| IV | Meteoro de piedra | Activa | 2 | 38 / 14 s / 70. Cae al cabo de 1 s (con aviso en el suelo) y derriba |
| IV | Estalagmitas torrencial | Mejora | 1 | Estalagmitas: +4 impactos |
| IV | Pedrada explosiva certera | Mejora | 1 | Pedrada explosiva: +30 % de daño |
| V | Avalancha | Mejora | 1 | El meteoro deja 3 rocas que bloquean el paso y estallan a los 3 s (20) |

### Bastión (defensa)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Piel de piedra | Activa | 2 | 15 / 12 s. −40 % de daño recibido y −20 % de velocidad durante 4 s |
| I | Raíces de roca | Mejora | 1 | Con Piel de piedra no te pueden empujar |
| II | Muro de tierra | Activa | 2 | 20 / 10 s. Muro de 3 unidades durante 6 s que detiene proyectiles |
| II | Muro de tierra macizo | Mejora | 1 | Muro de tierra: +2 unidades y +2 golpes |
| II | Embestida rocosa | Activa | 2 | 16 / 6 s / 24. Embestida de 3,5 unidades que empuja muy fuerte |
| II | Fortificar | Pasiva | 1 | +0,08 de defensa permanente |
| III | Escudo de rocas | Activa | 2 | 25 / 15 s. Tres rocas orbitan a tu alrededor; cada una bloquea un golpe |
| III | Escudo de rocas reforzado | Mejora | 1 | Escudo de rocas: +50 % de absorción y un bloqueo más |
| III | Coraza de cuarzo | Activa | 2 | 26 / 16 s. Absorbe 50 de daño durante 6 s |
| III | Contraataque pétreo | Pasiva | 1 | Cada roca que bloquea golpea al atacante (15) |
| IV | Fortaleza | Activa | 2 | 35 / 25 s. Círculo de 4 unidades durante 6 s: tú y tus aliados recibís −30 % de daño y los enemigos van más lentos |
| IV | Fortaleza duradera | Mejora | 1 | Fortaleza: +50 % de duración |
| IV | Coraza de cuarzo reforzada | Mejora | 1 | Coraza de cuarzo: +50 % de absorción y un bloqueo más |
| IV | Embestida rocosa doble | Mejora | 1 | Embestida rocosa: Una carga más |
| V | Menhir | Activa | 3 | 30 / 14 s. Un menhir aguanta 6 golpes y estalla (40) al romperse |
| V | Menhir macizo | Mejora | 1 | Menhir: +2 unidades y +2 golpes |
| V | Inamovible | Pasiva (próximamente) | 2 | Con Piel de piedra eres inmune a aturdimientos y derribos |

### Temblor (control)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Pisotón | Activa | 2 | 12 / 4 s / 10. Anillo de 2,5 unidades que aturde 0,5 s a los enemigos pequeños |
| I | Réplica | Mejora | 1 | El Pisotón se repite 0,5 s después |
| I | Sacudida | Activa | 2 | 12 / 5 s / 18. Golpe al suelo delante que aturde 0,6 s |
| I | Sacudida devastadora | Mejora | 1 | Sacudida: +30 % de daño y de radio |
| II | Grieta | Activa | 2 | 20 / 8 s / 12. Grieta en línea que derriba 1 s |
| II | Grieta larga | Mejora | 1 | Grieta: +2 unidades de alcance |
| II | Terreno firme | Pasiva (próximamente) | 1 | Inmune a las ralentizaciones del terreno (barro, hielo, telarañas) |
| III | Arenas movedizas | Activa | 2 | 25 / 10 s. Zona de 4 s: −60 % de velocidad y los enemigos no pueden esquivar ni saltar |
| III | Arenas movedizas duradero | Mejora | 1 | Arenas movedizas: +50 % de duración |
| III | Fauces de tierra | Activa | 2 | 26 / 10 s / 45. El suelo muerde al enemigo más cercano tras 0,5 s |
| III | Ondas | Pasiva | 1 | +50 % de radio del Pisotón |
| IV | Terremoto | Activa | 2 | 45 / 20 s / 10 cada 0,5 s. Temblor de 3 s en 7 unidades; derriba a los pequeños cada segundo |
| IV | Terremoto duradero | Mejora | 1 | Terremoto: +50 % de duración |
| IV | Fauces de tierra devastador | Mejora | 1 | Fauces de tierra: +30 % de daño y de radio |
| V | Corrimiento de tierra | Activa | 3 | 36 / 15 s / 26. Avalancha en línea de 8 unidades que empuja |
| V | Corrimiento de tierra largo | Mejora | 1 | Corrimiento de tierra: +2 unidades de alcance |
| V | Falla | Pasiva (próximamente) | 2 | El Terremoto abre grietas que siguen activas 4 s más |

### Definitiva

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| V | Despertar de la montaña | Definitiva | 5 | 60 / 45 s. Un gólem de roca lucha a tu lado 15 s; sus golpes aplican Fisura. |

## Luz

### Resplandor (ataque)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Destello | Activa | 2 | 8 / 0,5 s / 12. Rayo corto y rápido |
| I | Haz doble | Mejora | 1 | El Destello atraviesa al primer enemigo |
| I | Rayos gemelos | Activa | 2 | 12 / 1,5 s / 10 × 2. Dos destellos paralelos |
| I | Rayos gemelos certero | Mejora | 1 | Rayos gemelos: +30 % de daño |
| II | Lanza solar | Activa | 2 | 20 / 6 s / 35. Tras 0,4 s de carga, haz de 8 unidades |
| II | Lanza solar larga | Mejora | 1 | Lanza solar: +2 unidades de alcance |
| II | Purificar | Pasiva | 1 | +40 % de daño de luz contra enemigos anómalos |
| III | Prisma | Activa | 2 | 24 / 9 s. Cristal que divide tus Destellos en tres durante 6 s |
| III | Prisma prolongada | Mejora | 1 | Prisma: +50 % de duración |
| III | Juicio | Activa | 2 | 26 / 9 s / 45. Columna de luz sobre el enemigo más cercano que deslumbra |
| III | Ceguera | Pasiva | 1 | La Lanza solar deslumbra 1,5 s |
| IV | Nova | Activa | 2 | 40 / 15 s / 45. Explosión de luz de 5 unidades que deslumbra |
| IV | Nova amplia | Mejora | 1 | Nova: +35 % de radio |
| IV | Haz purificador | Activa | 2 | 28 / 10 s / 14 cada 0,25 s. Haz continuo de 2 s que deslumbra |
| IV | Juicio devastador | Mejora | 1 | Juicio: +30 % de daño y de radio |
| V | Haz purificador sostenido | Mejora | 1 | Haz purificador: +1 s de duración |
| V | Lluvia de estrellas | Activa | 3 | 40 / 18 s / 20 × 9. Estrellas caen 3 s sobre un área |
| V | Lluvia de estrellas torrencial | Mejora | 1 | Lluvia de estrellas: +4 impactos |
| V | Amanecer | Pasiva | 2 | Si la Nova alcanza a 3 enemigos o más, recuperas el 20 % de vida |

### Égida (protección)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Escudo de luz | Activa | 2 | 18 / 12 s. Absorbe 30 de daño durante 5 s |
| I | Escudo reflejante | Mejora | 1 | Al romperse, deslumbra a los enemigos cercanos |
| I | Destello cegador | Activa | 2 | 10 / 6 s / 6. Ciega un momento a quien te rodea |
| I | Destello cegador amplio | Mejora | 1 | Destello cegador: +35 % de radio |
| II | Sello protector | Activa | 2 | 22 / 14 s. Círculo de 3 unidades durante 5 s que destruye los proyectiles enemigos |
| II | Sello protector duradero | Mejora | 1 | Sello protector: +50 % de duración |
| II | Paso de luz | Activa | 2 | 14 / 7 s. Apareces junto al enemigo deslumbrado más cercano |
| II | Halo | Pasiva | 1 | Tras 4 s sin recibir daño, el siguiente golpe que recibes se reduce a la mitad |
| III | Guardián de luz | Activa | 2 | 30 / 20 s. Un espíritu protege a un aliado o escoltado y bloquea 3 golpes |
| III | Guardián de luz reforzado | Mejora | 1 | Guardián de luz: +50 % de absorción y un bloqueo más |
| III | Muro de luz | Activa | 2 | 24 / 12 s. Muro de 3,5 unidades durante 6 s que detiene a los enemigos |
| III | Égida firme | Pasiva | 1 | El Escudo de luz absorbe +50 % |
| IV | Santuario | Activa | 2 | 40 / 30 s. Zona de 4 unidades durante 6 s: recuperas un 3 % de vida por segundo y no puedes bajar de 1 |
| IV | Santuario duradero | Mejora | 1 | Santuario: +50 % de duración |
| IV | Muro de luz macizo | Mejora | 1 | Muro de luz: +2 unidades y +2 golpes |
| IV | Paso de luz ágil | Mejora | 1 | Paso de luz: −35 % de recarga |
| V | Juramento | Pasiva | 2 | El Escudo de luz se lanza solo al bajar del 30 % de vida (una vez cada 60 s) |

### Alba (curación y apoyo)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Respiro | Activa | 2 | 20 / 15 s. Recuperas el 25 % de vida en 1 s (un golpe lo interrumpe) |
| I | Respiro sereno | Mejora | 1 | Respiro: −30 % de recarga |
| I | Luz serena | Pasiva | 1 | +1 de regeneración de maná por segundo |
| II | Purgar | Activa | 2 | 15 / 10 s. Quita todos los estados negativos |
| II | Purgar sereno | Mejora | 1 | Purgar: −30 % de recarga |
| II | Luz curativa | Activa | 2 | 22 / 18 s. Círculo de 4 s que te cura un 4 % por segundo |
| II | Revelar | Pasiva | 1 | Ves trampas, enemigos ocultos y puntos débiles de los jefes (+15 % de daño en ellos) |
| III | Bendición | Activa | 2 | 25 / 20 s. Durante 8 s, +20 % de daño y −20 % de recargas |
| III | Bendición prolongada | Mejora | 1 | Bendición: +50 % de duración |
| III | Aura radiante | Activa | 2 | 24 / 14 s / 5 cada 0,5 s. Aura de 5 s que te sigue y deslumbra |
| III | Fe | Pasiva | 1 | El Respiro no se interrumpe y cura un 10 % más |
| IV | Aura radiante duradera | Mejora | 1 | Aura radiante: +50 % de duración |
| IV | Himno | Activa | 2 | 30 / 22 s. −30 % de recargas y +4 de maná por segundo durante 8 s |
| IV | Luz curativa duradera | Mejora | 1 | Luz curativa: +50 % de duración |
| IV | Faro interior | Pasiva | 2 | Cada 30 s, el siguiente hechizo de luz no cuesta maná |
| V | Himno prolongado | Mejora | 1 | Himno: +50 % de duración |
| V | Segunda alba | Pasiva | 2 | Una vez por zona, al caer, vuelves con el 50 % de vida y una Nova gratis |

### Definitiva

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| V | Sol de mediodía | Definitiva | 5 | 60 / 45 s. Durante 6 s, un sol sobre el héroe hace 10 cada 0,5 s y deslumbra a los enemigos a menos de 6 unidades, y te cura un 2 % de vida por segundo. |

## Aventurero

### Acero (la espada)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Filo templado | Pasiva | 1 | El 3.er golpe del combo hace +50 % |
| I | Estocada | Activa | 2 | Avanza 2 unidades con la espada por delante y hace 20; sin maná, recarga 5 s |
| II | Castigo | Pasiva | 1 | +30 % de daño a enemigos que acaban de fallar un ataque |
| II | Combo largo | Pasiva | 1 | El combo pasa de 3 a 4 golpes |
| III | Golpe pesado | Pasiva | 1 | El último golpe del combo empuja el doble e interrumpe a enemigos pequeños |
| III | Torbellino | Activa | 2 | Giro de 360°, 25 de daño; sin maná, recarga 8 s |
| IV | Remate | Pasiva | 2 | +50 % de daño a enemigos con menos del 25 % de vida |
| V | Maestro de armas | Pasiva | 2 | Cada golpe de espada reduce 0,3 s la recarga de todas las habilidades |

### Instinto (esquiva y movimiento)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Impulso | Pasiva | 1 | Tras esquivar, el siguiente golpe en 1 s hace +40 % |
| I | Paso ligero | Pasiva | 1 | +10 % de velocidad fuera de combate |
| II | Esquiva limpia | Pasiva | 1 | Esquivar en los últimos 0,15 s antes de un golpe devuelve 10 de maná |
| II | Doble esquiva | Pasiva | 1 | Dos cargas de esquiva |
| III | Lectura | Pasiva | 1 | Los avisos enemigos se ven 0,15 s antes |
| III | Rodar y golpear | Pasiva (próximamente) | 1 | Atacar justo al acabar la esquiva hace un tajo giratorio de 15 |
| IV | Tiempo justo | Pasiva | 2 | La esquiva perfecta ralentiza a los enemigos 0,5 s (el efecto de pantalla se puede desactivar) |
| V | Fantasma | Pasiva | 2 | +0,1 s de invulnerabilidad en la esquiva |

### Resistencia (supervivencia)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Piel curtida | Pasiva | 1 | +15 % de vida máxima |
| I | Pociones dobles | Pasiva (próximamente) | 1 | 4 pociones por expedición en lugar de 3 |
| II | Segundo aliento | Pasiva | 1 | En lugar de caer te quedas a 1 de vida e invulnerable 1 s; se recarga en 60 s |
| II | Recuperación | Pasiva | 1 | Fuera de combate recuperas un 2 % de vida por segundo |
| III | Último recurso | Pasiva | 1 | Con menos del 30 % de vida recibes −20 % de daño |
| III | Antídotos | Pasiva (próximamente) | 1 | Los estados alterados duran −40 % sobre ti |
| IV | Corazón firme | Pasiva | 2 | +25 de vida; inmune al primer aturdimiento de cada combate |
| V | Inquebrantable | Pasiva | 2 | Segundo aliento tiene dos cargas |

### Oficio (exploración y utilidad)

| Nivel | Nodo | Tipo | PA | Efecto |
|---|---|---|---|---|
| I | Ojo de rastreador | Pasiva | 1 | Ves la vida de los enemigos sin golpearlos |
| I | Bolsillos | Pasiva (próximamente) | 1 | +1 hueco de consumible |
| II | Botín atento | Pasiva | 1 | Los cofres dan un objeto más |
| II | Regateo | Pasiva (próximamente) | 1 | −10 % en las tiendas |
| III | Cartógrafo | Pasiva (próximamente) | 1 | El mapa marca los secretos a menos de 20 unidades |
| III | Alquimia de campo | Pasiva (próximamente) | 1 | Las pociones preparadas en un punto de descanso curan +20 % |
| IV | Recarga rápida | Pasiva | 2 | −15 % a todas las recargas |
| V | Leyenda en ciernes | Pasiva | 2 | +10 % de experiencia y de reputación por contrato |

