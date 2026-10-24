# Creador de personaje

Es la primera pantalla del juego (`scenes/ui/character_creator.tscn`). El protagonista es un viajero
que llega a Brumaclara buscando trabajo, no un héroe elegido (GDD 7.1), así que viste ropa de viaje:
túnica, chaleco de tela, cinturón con bolsa, brazales y botas. Sin capa ni bufanda. Se elige:

| Opción | Qué cambia |
|---|---|
| Género | El modelo dibujado: hombre o mujer |
| Peinado | Los peinados dibujados para ese género (de momento uno por género: puntas y coleta) |
| Pelo | 10 colores (el original, negro, castaño, rubio, pelirrojo, blanco, azul, rosa, verde y morado) |
| Piel | 5 tonos (el original, clara, media, morena y oscura) |
| Atuendo | 9 combinaciones de colores para la túnica y el chaleco (Viajero, Campesino, Leñador, Marinero, Herrero, Mercader, Brasa, Bruma y Noche) |

Flechas o WASD para elegir, Intro para confirmar. También se puede usar el ratón. «Aleatorio» sortea
un aspecto. Al empezar se guarda en `user://personaje.json` y el juego lo usa en todos los niveles.

![Combinaciones](screenshots/17_aspectos.png)

## Cómo funciona

- **Modelos.** Cada modelo es un juego completo de sprites del héroe: `assets/characters/hero/<set>.png`
  con `<set>_frames.tres`, con las mismas animaciones. Están en la lista `MODELS` de
  `scripts/systems/hero_look.gd`.
- **Colores.** `tools/art_pipeline/build.py` guarda junto a cada juego una máscara (`<set>_mask.png`)
  que dice qué píxeles son pelo, piel, túnica o chaleco (tabla `LOOK_GROUPS`). Al cargar, `HeroLook` pinta
  cada grupo con el color elegido y conserva el sombreado del dibujo.

## Añadir un peinado o un atuendo dibujado

1. Generar las tres hojas (caminar, ataques, esquivas) con la misma rejilla que las de la heroína
   (`art/FUENTES.md`) y dejarlas en `art/ai/heroes/`.
2. Añadir su receta en `build.py` (como `heroine()`) y sus grupos de color en `LOOK_GROUPS`.
3. Añadir una línea a `MODELS` en `hero_look.gd`. El creador lo muestra solo.

## Pendiente

- **Más peinados.** Cada peinado es un juego completo de tres hojas. El siguiente previsto es un hombre
  con pelo corto rubio. Los créditos de IA de Figma del plan Starter se agotaron el 24 de octubre de 2026
  y vuelven el 1 de noviembre. Canva sabe editar una hoja existente cambiando solo el peinado
  (`generate-image` con la hoja como referencia), pero la imagen a tamaño completo solo se puede bajar
  exportando un diseño de Canva.
- **Espadas finas.** En algunos fotogramas de ataque la hoja de la espada queda muy fina al reducirla al
  píxel del juego.
