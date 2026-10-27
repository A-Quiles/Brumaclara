# Bestiario de Edria

Enemigos y jefes del juego final, ordenados por las zonas de la campaña (`GUILD_ZERO_Historia_Completa`).
Completa `docs/diseno_combate.md`: roles, estados, fórmula de daño y debilidades. Los valores son la
propuesta de partida y vivirán en las fichas `EnemyData` (`data/enemies`).

**Reglas que cumple cada enemigo**

1. Tiene un **rol** (acechador, bruto, hostigador, protector o anómalo) y un comportamiento propio. Una
   variante solo existe si añade una regla nueva, nunca por tener más vida o cambiar de color.
2. Todo ataque peligroso tiene **aviso** visible de al menos 0,4 s (y sonido cuando lo haya).
3. Las criaturas alteradas no son malvadas: la Fractura las desorienta. Algunas se pueden ahuyentar o
   rodear, y varios contratos lo premian.
4. Los humanos pueden **rendirse** al 20 % de vida (salvo en combates de historia). Rendirlos cuenta
   para la crónica y la reputación.

**Familias:** Bestias alteradas · Flora fracturada · Criaturas del agua · Autómatas de la Trama ·
Ecos (anomalías puras) · Humanos.

**Columnas:** vida y daño a nivel de zona; «Débil / Resiste» usa las seis afinidades y la espada.

## Resumen

| Zona | Capítulo | Nivel | Enemigos | Jefe |
|---|---|---|---|---|
| 1. Afueras de Brumaclara y Puente Oriental | 1 | 1–4 | 6 | Madre de la manada |
| 2. Bosque de los Susurros | 2 | 4–8 | 6 | El Árbol que susurra |
| 3. Humedal de la Barrera | 2 y 5 | 6–10 | 6 | Caparazón de Vigilia |
| 4. Cantera Vieja y galerías mineras | 2 y 5 | 8–13 | 6 | Taladro de la Trama |
| 5. Puentegris y el Paso de la Tormenta | 3 y 4 | 12–17 | 6 | Heraldo de la grieta |
| 6. Santuario Hundido | 3 | 14–18 | 6 | Sierpe del caudal |
| 7. Ruinas del Umbral y estación abandonada | 2 y 4 | 16–22 | 6 | Archivista hueco |
| 8. Veyra y sus cámaras | 4 y 5 | 22–28 | 6 | Ejecutor de la prefectura |
| 9. Corredor de mantenimiento y Nudo Cero | 6 | 26–32 | 5 | Custodio de Enlace y Odrana |
| Contratos de caza (todas las zonas) | 2–6 | — | 8 élites | — |

En total: **53 enemigos, 8 élites de contrato y 10 jefes.** El nivel máximo es 40: los contratos de
caza y el contenido posterior a la historia cubren del 32 al 40.

## Zona 1 — Afueras de Brumaclara y Puente Oriental (cap. 1, nivel 1–4)

El camino de llegada, la carreta volcada, la alcantarilla y el puente oriental. Enseña a leer avisos.

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Roedor de bruma | Bestia / acechador | 12 | 5 | Sale de la alcantarilla en grupos de 3–5; corre en zigzag y muerde | Chillido y se encoge 0,4 s | Fuego / — |
| Lobo de la Fractura **(en juego)** | Bestia / acechador | 40 | 14 | Vigila su guarida, persigue y salta en línea recta; queda abierto 0,8 s al aterrizar | Brillo violeta 0,6 s | — / — |
| Jabalí espinoso | Bestia / bruto | 70 | 20 | Carga en línea recta; si choca contra un muro queda aturdido 1,5 s | Escarba el suelo 0,8 s | Fuego / Tierra |
| Cuervo de bruma | Bestia / hostigador | 20 | 8 | Vuela en círculos y se lanza en picado; huye si pierde la mitad de la vida | Grito y se queda quieto en el aire 0,5 s | Rayo / Sombra |
| Saqueador de caminos | Humano / acechador | 45 | 12 | Ataca con espada y se aleja para lanzar cuchillos; se rinde al 20 % | Echa el brazo atrás 0,5 s | Sombra / — |
| Lobo alfa | Bestia / acechador (variante) | 90 | 18 | Su aullido acelera a los lobos cercanos; salta dos veces seguidas | Aúlla 1 s (se puede interrumpir) | Hielo / — |

**Jefe — Madre de la manada** (Puente Oriental, 400 de vida). Loba enorme con cristales violeta que
absorbe energía de la grieta del puente.
1. *Doble salto:* dos saltos encadenados; el segundo corrige la dirección.
2. *Llamada:* aúlla y aparecen dos lobos; si se la interrumpe, solo llega uno.
3. *Absorber la grieta:* se queda junto a la grieta 3 s y se cura un 15 %; golpearla con fuerza la
   interrumpe y la deja aturdida.
4. *Bajo el 50 %:* abre grietas en el suelo que hay que rodear durante el resto del combate.

## Zona 2 — Bosque de los Susurros (cap. 2, nivel 4–8)

Senderos estrechos, setas luminosas, árboles marcados con geometrías de la Trama y la baliza rota.

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Sporíneo | Flora / hostigador | 30 | 10 | Seta que dispara esporas en abanico y se entierra si te acercas | Se hincha 0,6 s | Fuego / Hielo |
| Guardián de raíces | Flora / protector | 90 | 12 | Levanta un muro de raíces que protege a los enemigos de detrás | Las raíces asoman 0,7 s antes | Fuego / Rayo |
| Polilla lumínica | Eco / anómalo | 25 | 6 | Aplica Eco; si recibe magia se divide en dos | Suelta polvo brillante | Espada, Luz / Magia |
| Araña de musgo | Bestia / acechador | 30 | 10 | Cuelga de los árboles y cae sobre el héroe; su red ralentiza | Su sombra crece en el suelo 0,6 s | Fuego / Sombra |
| Ciervo de cuerno cristal | Bestia / bruto | 80 | 18 | Embiste y, al frenar, deja cristales en el suelo que estallan a los 2 s | Baja la cabeza 0,7 s | Tierra / Luz |
| Enredadera susurrante | Flora / protector (trampa) | 50 | 8 | Inmóvil; atrapa 1,5 s a quien pasa cerca y llama a los demás | Hojas que tiemblan | Fuego / Tierra |

**Jefe — El Árbol que susurra** (800). Árbol antiguo fijo en el centro de un claro.
1. *Barrido de raíces:* raíces que barren zonas marcadas en el suelo.
2. *Siembra:* lanza esporas que crean Sporíneos; quemarlos antes de que salgan los evita.
3. *Susurro:* durante 3 s invierte los controles del héroe salvo que se tape (Velo, Escudo de luz o
   Barrera cristalina lo bloquean); el aviso es un murmullo y una niebla verde.
4. *Corazón expuesto:* tras cada siembra, el tronco se abre 4 s y recibe el doble de daño.

## Zona 3 — Humedal de la Barrera (cap. 2 con el Faro, cap. 5, nivel 6–10)

El humedal del que bebe la barrera del Faro: animales alterados por la extracción (historia, misión 2.2).

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Rana cornuda | Agua / hostigador | 35 | 11 | Salta entre charcas y te alcanza con la lengua desde 4 unidades | Infla la garganta 0,5 s | Hielo / Fuego |
| Garza alterada | Bestia / acechador | 40 | 16 | Se queda inmóvil entre los juncos y pica muy lejos y muy rápido | Estira el cuello 0,4 s | Rayo / — |
| Sanguijuela de cristal | Agua / anómalo | 20 | 4 | Se pega al héroe y le roba 3 de maná por segundo hasta que esquiva | Brillo bajo el agua | Fuego, Luz / Hielo |
| Tortuga de lodo | Agua / protector | 110 | 14 | Inmune por delante; protege a los enemigos de detrás con su caparazón | Mete la cabeza 0,6 s antes de embestir | Tierra (Fisura le rompe el caparazón) / Fuego |
| Fuego fatuo | Eco / anómalo | 15 | 25 | Atrae al héroe con su luz y estalla si llega a tocarlo | Parpadeo cada vez más rápido 1 s | Luz, Hielo / Fuego |
| Caimán de la barrera | Agua / bruto | 130 | 26 | Se hunde y emerge bajo el héroe con un mordisco | Burbujas en el agua 0,8 s | Rayo / Tierra |

**Jefe — Caparazón de Vigilia** (1.100). Tortuga colosal con los cristales de la barrera crecidos en el
caparazón. Se puede calmar en lugar de matarla si el jugador desconectó la extracción (decisión de la
misión 2.2).
1. *Ola de lodo:* oleada que hay que saltar con la esquiva.
2. *Cristales de la barrera:* dispara cristales que se clavan en el suelo y forman un laberinto.
3. *Encierro:* se mete en el caparazón; los cristales de la espalda quedan expuestos y son el punto débil.
4. *Bajo el 30 %:* los cristales se sobrecargan y descargan rayos en línea.

## Zona 4 — Cantera Vieja y galerías mineras (cap. 2 con la Brasa, cap. 5, nivel 8–13)

El puesto minero abandonado de la prueba de la Brasa y la cantera donde las herramientas se han
contaminado de energía (misión 5.2).

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Jabalí de cantera | Bestia / bruto | 140 | 28 | Golpe de área en círculo al detenerse | Círculo de polvo 0,9 s | Hielo / Fuego |
| Gólem de escombro | Autómata / protector | 200 | 22 | Lento; recoge rocas y se blinda (defensa 0,6) hasta que se le rompe la coraza | Se agacha 1 s | Rayo, Tierra / Espada |
| Minero perdido | Humano alterado / acechador | 60 | 18 | Hace un amago antes del golpe real; se le puede despertar con Luz (Purgar) | Levanta el pico dos veces | Luz / — |
| Murciélago de hollín | Bestia / hostigador | 15 | 6 | En enjambre; apaga las lámparas y deja la galería a oscuras | Batir de alas que se acerca | Fuego, Luz / — |
| Escarabajo perforador | Bestia / acechador | 55 | 20 | Excava y sale bajo los pies del héroe | La tierra se levanta 0,7 s antes | Tierra / Rayo |
| Pico errante | Eco / anómalo | 35 | 15 | Herramienta poseída que gira y persigue; si se destruye, suelta mineral útil | Zumbido y vibración 0,5 s | Hielo / Fuego |

**Jefe — Taladro de la Trama** (1.500). Antiguo autómata minero de la red, aún obedeciendo la orden de
excavar.
1. *Perforación:* avanza en línea recta por la galería; las columnas lo frenan y lo dejan expuesto.
2. *Lluvia de piedras:* el techo cae en zonas marcadas.
3. *Sobrecalentamiento:* tras tres perforaciones abre las rejillas 4 s (punto débil; el Hielo lo alarga).
4. *Bajo el 50 %:* llama a Picos errantes desde las paredes.

## Zona 5 — Puentegris y el Paso de la Tormenta (cap. 3 y 4, nivel 12–17)

La comunidad que no aparece en los mapas, su puente de la Trama y el paso de montaña con viento.

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Halcón de tormenta | Bestia / hostigador | 50 | 20 | Picado que deja una descarga en el suelo | Chillido y destello 0,5 s | Tierra / Rayo |
| Cabra de risco | Bestia / bruto | 120 | 24 | Embiste para tirar al héroe por el borde (cae a una zona inferior, no muere) | Rasca el suelo 0,8 s | Hielo / Tierra |
| Remolino | Eco / anómalo | 60 | 10 | Desvía los proyectiles y empuja al héroe | Hojas y polvo que giran 1 s | Tierra / Rayo, Fuego |
| Contrabandista | Humano / hostigador | 70 | 18 | Ballesta y bombas de humo; se rinde al 20 % | Carga la ballesta 0,7 s | Sombra / — |
| Matón contrabandista | Humano / protector | 150 | 22 | Escudo grande; protege al ballestero y empuja | Levanta el escudo 0,6 s | Tierra, Sombra / Espada |
| Lobo de tormenta | Bestia / acechador (variante) | 90 | 22 | Como el lobo, pero su salto deja un rayo que encadena entre lobos | Brillo azul 0,6 s | Tierra / Rayo |

**Jefe — Heraldo de la grieta** (2.000; misión 4.1, «La noche de Puentegris»). Una forma inestable que
sale de la Fractura junto al puente. El combate ocurre mientras la evacuación avanza: defender puntos del
puente cambia el resultado narrativo.
1. *Oleadas:* abre portales de los que salen enemigos de las zonas 1 a 4.
2. *Rayo del puente:* barre el puente de lado a lado con una línea marcada.
3. *Absorber:* se alimenta de los portales abiertos; cerrar un portal (golpeándolo) lo debilita un 10 %.
4. *Fase final:* se fragmenta en tres partes; solo la que brilla recibe daño.

## Zona 6 — Santuario Hundido (cap. 3, nivel 14–18)

Ruinas inundadas donde Neris encuentra los registros de los nodos aislables (misión 3.5).

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Anguila de eco | Agua / acechador | 60 | 22 | Nada bajo el agua y salta desde los canales | Ondas en el agua 0,6 s | Rayo / Fuego |
| Cangrejo de piedra | Agua / protector | 160 | 18 | Pinza que bloquea golpes frontales y contraataca | Abre la pinza 0,5 s | Rayo, Tierra / Espada |
| Medusa de luz | Agua / hostigador | 40 | 14 | Flota y lanza descargas; al morir deja un charco electrificado | Se ilumina entera 0,6 s | Tierra, Sombra / Luz |
| Centinela anegado | Autómata / bruto | 220 | 30 | Guardia oxidado y lento; golpe de martillo en área | Levanta el martillo 1 s | Rayo / Hielo |
| Eco de peregrino | Eco / anómalo | 50 | 16 | Repite los movimientos del héroe con 2 s de retraso, ataques incluidos | Silueta translúcida | Luz / Sombra |
| Nenúfar devorador | Flora / protector (trampa) | 40 | 20 | Flota inmóvil; muerde a quien pisa su hoja | La hoja se cierra 0,5 s | Fuego / Hielo |

**Jefe — Sierpe del caudal** (2.300). Serpiente de agua que protege la cámara de los registros.
1. *Corriente:* inunda la sala y empuja hacia un lado; las columnas sirven de refugio.
2. *Mordisco desde el agua:* emerge de un canal marcado.
3. *Espiral:* se enrosca alrededor del héroe; hay que salir antes de que se cierre (2 s).
4. *Bajo el 40 %:* vacía los canales y combate en tierra, más lenta pero más fuerte.

## Zona 7 — Ruinas del Umbral y estación abandonada (cap. 2 con el Archivo, cap. 4, nivel 16–22)

Cámaras de piedra con barreras de seguridad, la estación donde aparece el mapa de la Trama y la cámara
de las tres versiones.

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Autómata vigía | Autómata / hostigador | 80 | 22 | Dispara rayos desde lejos y cambia de posición | Ojo que se carga 0,7 s | Tierra / Rayo |
| Autómata de mantenimiento | Autómata / protector | 120 | 10 | Repara a los demás autómatas; hay que derribarlo primero | Brazo de reparación brillante | Rayo / Fuego |
| Guardia de sellos | Autómata / bruto | 260 | 32 | Escudo de runas que solo se rompe con la afinidad que muestra encima | Runas que giran 1 s | Cambia en cada encuentro / — |
| Eco errante | Eco / anómalo | 70 | 20 | Se teletransporta y aplica Eco; desaparece si se le ilumina | Destello violeta donde va a aparecer | Luz / Sombra |
| Glifo vivo | Eco / protector (trampa) | 60 | 25 | Runa en el suelo que estalla al pisarla y se recarga | Brilla al acercarse | Espada, Tierra / Magia |
| Saqueador de ruinas | Humano / acechador | 90 | 24 | Busca artefactos; usa bombas y huye con el botín si no se le detiene | Prende la mecha 0,8 s | Sombra, Hielo / — |

**Jefe — Archivista hueco** (2.800). Autómata archivero que protege la cámara de las tres versiones.
1. *Tres versiones:* crea dos copias de sí mismo; la real es la que coincide con el registro que el
   jugador ha leído en la sala (pista ambiental, no azar).
2. *Lectura:* dispara líneas de texto luminoso que hay que esquivar.
3. *Sello:* bloquea una afinidad del héroe durante 10 s (se ve en la interfaz).
4. *Bajo el 30 %:* las copias atacan a la vez y la real se mueve detrás de ellas.

## Zona 8 — Veyra y sus cámaras (cap. 4 y 5, nivel 22–28)

La ciudad de Odrana: calles vigiladas, conductos de la Trama y cámaras bajo la ciudad. Muchos combates
contra humanos se pueden evitar con la afiliación, el disfraz o la técnica Mediación de la Liga.

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Guardia de Veyra | Humano / protector | 180 | 26 | Escudo y lanza; si te ve, toca un silbato y llegan refuerzos en 10 s | Se cuadra 0,6 s | Sombra / — |
| Ballestero de la prefectura | Humano / hostigador | 110 | 30 | Dispara desde balcones; cambia de balcón tras dos disparos | Línea de puntería visible 0,8 s | Rayo, Tierra / — |
| Autómata de contención | Autómata / bruto | 320 | 38 | Lanza una red de energía que inmoviliza 1,5 s | Proyector que se ilumina 1 s | Tierra, Rayo / Fuego |
| Rata de conducto | Bestia / acechador | 20 | 9 | Enjambre que sale de las tuberías y se dispersa | Ruido en las tuberías | Fuego / — |
| Sobrecarga viva | Eco / anómalo | 90 | 28 | Chispa que salta por las tuberías y explota cerca del héroe | Las tuberías se iluminan en su camino | Hielo / Rayo |
| Torreta de la Trama | Autómata / hostigador (fija) | 150 | 20 | Dispara en abanico; se desactiva cortando su conducto | Gira y se carga 0,7 s | Tierra / Rayo |

**Jefe — Ejecutor de la prefectura** (3.400; misión 5.4). El oficial que dirige el traslado del control.
Se puede negociar si el jugador tiene pruebas suficientes (no se combate).
1. *Formación:* dos guardias le cubren; si caen, cambia a combate cuerpo a cuerpo.
2. *Red de contención:* inmoviliza una zona amplia.
3. *Orden de fuego:* los ballesteros disparan a la vez sobre un círculo marcado.
4. *Bajo el 25 %:* se rinde y entrega información (es un humano, no un monstruo).

## Zona 9 — Corredor de mantenimiento y Nudo Cero (cap. 6, nivel 26–32)

La ruta final: enemigos conocidos alterados por el entorno y las defensas del Nudo.

| Enemigo | Familia / rol | Vida | Daño | Comportamiento | Aviso | Débil / Resiste |
|---|---|---|---|---|---|---|
| Custodio menor | Autómata / protector | 300 | 30 | Crea un campo que refleja los proyectiles | Campo azul que se forma 0,8 s | Espada, Tierra / Magia a distancia |
| Eco del Nudo | Eco / anómalo | 120 | 34 | Copia la última habilidad que lanzó el héroe | Toma su color 0,6 s antes | Luz / La afinidad copiada |
| Enjambre de chispas | Eco / hostigador | 60 | 12 × 5 | Cinco chispas que rodean al héroe y se lanzan una a una | Cada chispa parpadea antes de lanzarse | Hielo / Rayo |
| Fractura errante | Eco / anómalo | 200 | — | Portal que se desplaza y saca enemigos alterados de zonas anteriores | Se ensancha 1,5 s antes de abrir | Luz (la cierra antes) / — |
| Guardián de válvula | Autómata / bruto | 450 | 44 | Gira su martillo y cierra compuertas que dividen la sala | Vapor por las juntas 1 s | Hielo, Tierra / Fuego |

**Jefe — Custodio de Enlace** (4.500; misión 6.2). Autómata antiguo que sigue órdenes de mantenimiento
que ya no tienen sentido.
1. *Mantenimiento:* canaliza 4 s para repararse; hay que interrumpirlo (lo enseña el combate).
2. *Barrido de conexiones:* líneas de energía que recorren el suelo siguiendo el trazado de la Trama.
3. *Aislar nodo:* encierra al héroe en un círculo que se estrecha; se sale rompiendo un pilar.
4. *Usar el entorno:* las válvulas de la sala, al abrirlas, lo dejan aturdido 3 s.

**Jefe — Prefecta Odrana Vey** (3.800; misión 6.3, opcional). Solo se combate si el jugador la trata como
enemiga sin opción de diálogo. Lucha con protocolos de contención, no con magia oscura.
1. *Protocolo de cierre:* sella zonas de la cámara y obliga a moverse.
2. *Guardia personal:* llama a dos guardias de Veyra.
3. *Sobrecarga del Nudo:* usa el Nudo contra el héroe con rayos marcados; se debilita ella también.
4. *Final:* no muere: al 10 % de vida se rinde y el combate termina en escena.

La secuencia final (misión 6.5) no es un jefe: son oleadas cortas de enemigos de la zona 9 mientras se
activan mecanismos y se protege a los aliados, distintas según el final elegido.

## Contratos de caza (élites)

Enemigos únicos con nombre del tablón de contratos. Cada uno vive en una zona ya visitada, tiene una
regla extra y da una recompensa propia (equipo único o PA).

| Élite | Zona | Nivel | Base | Regla extra | Recompensa |
|---|---|---|---|---|---|
| Colmillo Gris | 1 | 6 | Lobo alfa | Solo ataca de noche; su manada se esconde en la niebla | Amuleto de manada |
| La Reina de las esporas | 2 | 10 | Sporíneo gigante | Sus esporas crean zonas que ralentizan | Catalizador verde |
| Viejo Barro | 3 | 12 | Caimán de la barrera | Arrastra al héroe bajo el agua 2 s si le muerde | Botas de pantano |
| Capataz Hollín | 4 | 15 | Minero perdido | Lleva una lámpara: si se la rompes, los murciélagos lo atacan a él | Pico ligero (arma) |
| El Barquero sin río | 6 | 20 | Eco de peregrino | Repite tus habilidades, no solo tus movimientos | 2 PA |
| Rey del Paso | 5 | 22 | Matón contrabandista | Ordena a los contrabandistas cambiar de formación | Insignia de contrabando |
| Biblioteca andante | 7 | 28 | Autómata de mantenimiento | Repara también las ruinas: reconstruye columnas que bloquean | Tomo de afinidad (+1 PA) |
| Eco de Arel | 9 | 36 | Eco del Nudo | Copia dos habilidades a la vez; combate posterior a la historia | Título «Rango Cero» y 3 PA |

## Arte y producción

Cada enemigo necesita hojas de reposo, moverse, aviso, ataque, daño y derrota (GDD 4.3). Para no
multiplicar el coste:

- Las **variantes** (lobo alfa, lobo de tormenta, élites) reutilizan la hoja de su base con repintado y
  un efecto añadido, como los caballos de colores (`build.py recolors`).
- Los **ecos** son en gran parte efectos visuales, no animaciones completas.
- Orden de producción recomendado: la zona 1 completa (cinco enemigos nuevos y su jefe), luego zona a
  zona según avance la campaña.


## En el juego

Cada enemigo es una ficha `data/enemies/<nombre>.tres` (vida, daño, avisos, debilidades, ataque) con su
hoja de 4×4 fotogramas (`assets/characters/enemies/<nombre>.png`: reposo, moverse, aviso + ataque,
daño + caída). El ataque es de uno de tres tipos, siempre tras su aviso:

- **Salto** (`pounce`): se lanza en línea recta y muerde; queda abierto al aterrizar.
- **Golpe en área** (`burst`): golpea a su alrededor (el radio va en la ficha).
- **Disparos** (`volley`): uno o varios proyectiles en abanico hacia el héroe.

| Enemigo | Zona | Vida | Ataque | Débil a | Resiste | Nota |
|---|---|---|---|---|---|---|
| Lobo de la Fractura, alfa, de tormenta, Colmillo Gris, Madre de la manada y lobos elementales | 1 | 40–400 | Salto | según variante | según variante | 11 fichas; la Madre invoca crías |
| Hongo errante | 1 | 45 | Disparo de esporas | fuego | tierra | |
| Murciélago de cueva | 1 | 28 | Salto | rayo | — | vuela |
| Esqueleto guerrero | 1 | 70 | Salto | luz, tierra | sombra, hielo | defensa 10 % |
| Gólem de musgo | 1 | 160 | Golpe en área | rayo, hielo | tierra, fuego | lento, defensa 20 % |
| Espectro errante | 1 | 50 | Disparo | luz, fuego | sombra, espada | flota |
| Hongo, murciélago, esqueleto y gólem fracturados | 1 (claro) | 38–210 | como su base | luz | sombra | anómalos |
| Espectro de la Fractura | 1 (claro) | 60 | Disparo | luz | sombra, espada | anómalo |
| Sporíneo | 2 | 30 | Abanico de 3 esporas | fuego | hielo | |
| Guardián de raíces | 2 | 90 | Golpe en área (raíces) | fuego | rayo | defensa 20 % |
| Polilla lumínica | 2 | 25 | Estallido de polvo | espada, luz | la magia | anómala, vuela |

Las criaturas alteradas llevan la marca de la Fractura en el dibujo: ojos y grietas violeta y cristales
que les crecen en el cuerpo. Los números de los enemigos del bestiario que ya tienen dibujo están en
`tools/data/enemies.py`, que escribe sus fichas y los coloca en las afueras.
