"""Regenerates every procedural texture and sprite into res://assets.

Usage: python3 tools/art_generator/generate.py
"""
from pathlib import Path

import backdrop
import hero
import hud
import village_houses
import village_sprites as vs
import village_textures as vt

ASSETS = Path(__file__).resolve().parents[2] / "assets"

ART = {
    "characters/hero/hero_walk.png": hero.hero_sheet,
    "environment/textures/paving.png": vt.paving,
    "environment/textures/path.png": vt.path,
    "environment/textures/grass.png": vt.grass,
    "environment/textures/grass_dark.png": lambda: vt.grass(seed=7, dark=True),
    "environment/textures/stone_wall.png": vt.wall_blocks,
    "environment/textures/stone_top.png": vt.wall_top,
    "environment/textures/wood_planks.png": vt.wood_planks,
    "environment/textures/water.png": vt.water,
    "environment/textures/fountain_stone.png": vt.fountain_stone,
    "environment/textures/fountain_top.png": vt.fountain_top,
    "environment/textures/awning_rainbow.png": lambda: vt.awning("rainbow"),
    "environment/textures/awning_green.png": lambda: vt.awning("green"),
    "environment/textures/awning_purple.png": lambda: vt.awning("purple"),
    "environment/textures/dirt.png": vt.dirt_patch,
    "environment/textures/plaza_border.png": lambda: vt.plaza_border(7.2, 6.4),
    "environment/textures/blob_shadow.png": vt.blob_shadow,
    "environment/textures/backdrop.png": backdrop.backdrop,
    "environment/vegetation/pine_large.png": lambda: vs.pine(38, 64, 5, 1),
    "environment/vegetation/pine_medium.png": lambda: vs.pine(32, 48, 4, 2),
    "environment/vegetation/pine_small.png": lambda: vs.pine(16, 26, 3, 3),
    "environment/vegetation/bush.png": vs.bush,
    "environment/props/barrel.png": vs.barrel,
    "environment/props/crate.png": vs.crate,
    "environment/props/crate_stack.png": lambda: vs.crate(24, 22, stacked=True),
    "environment/props/barrel_blue.png": vs.barrel_blue,
    "environment/props/basket.png": vs.basket,
    "environment/props/signpost.png": vs.signpost,
    "environment/props/bollard.png": vs.bollard,
    "environment/props/produce.png": vs.produce,
    "environment/props/fountain_spray.png": vs.fountain_spray_sheet,
    "ui/hp_panel.png": hud.hp_panel,
    "ui/hp_fill.png": lambda: hud.bar_fill(hud.HP),
    "ui/mp_fill.png": lambda: hud.bar_fill(hud.MP),
    "ui/minimap_frame.png": hud.minimap_frame,
    "ui/key_y.png": lambda: hud.key_cap("Y"),
    "ui/key_x.png": lambda: hud.key_cap("X"),
    "ui/prompt_arrow.png": hud.prompt_arrow,
    "ui/player_marker.png": hud.player_marker,
}
for _kind in vs.VILLAGERS:
    ART[f"characters/villagers/{_kind}.png"] = lambda kind=_kind: vs.villager_sheet(kind)


def save(rel_path, canvas):
    out = ASSETS / rel_path
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)


def main():
    for rel_path, build in ART.items():
        canvas = build()
        if rel_path.startswith("characters/hero"):
            # the hero gets a real blob shadow in 3D, so drop the painted one
            canvas.img.putalpha(canvas.img.getchannel("A").point(lambda a: 255 if a == 255 else 0))
        save(rel_path, canvas)
    for name, spec in village_houses.HOUSES.items():
        for part, canvas in village_houses.house_textures(name, spec).items():
            save(f"environment/houses/{name}/{part}.png", canvas)
    print("ok")


if __name__ == "__main__":
    main()
