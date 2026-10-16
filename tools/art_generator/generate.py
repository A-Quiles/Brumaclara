"""Regenerates every procedural sprite into res://assets.

Usage: python3 tools/art_generator/generate.py
Prints each sprite's origin (bottom-centre of its base) so scenes can align them.
"""
import json
from pathlib import Path

import ground
import hero
import nature
import structures
import textures3d

ASSETS = Path(__file__).resolve().parents[2] / "assets"

SPRITES = {
    "characters/hero/hero_walk.png": hero.hero_sheet,
    "environment/stone_wall.png": ground.stone_wall,
    "environment/textures/house_front.png": textures3d.house_front,
    "environment/textures/house_side.png": textures3d.house_side,
    "environment/textures/house_gable.png": textures3d.house_gable,
    "environment/textures/roof_tiles.png": textures3d.roof_tiles,
    "environment/textures/grass.png": textures3d.grass,
    "environment/textures/paving.png": textures3d.paving,
    "environment/textures/stone_blocks.png": textures3d.stone_blocks,
    "environment/textures/blob_shadow.png": textures3d.blob_shadow,
    "environment/textures/sky_backdrop.png": textures3d.sky_backdrop,
    "environment/nature/tree_oak.png": nature.tree_oak,
    "environment/nature/tree_pine.png": nature.tree_pine,
    "environment/nature/bush.png": nature.bush,
    "environment/nature/bush_flowers.png": lambda: nature.bush(flowers=True, seed=6),
    "environment/nature/rock_small.png": nature.rock_small,
    "environment/nature/rock_medium.png": nature.rock_medium,
    "environment/nature/rock_large.png": nature.rock_large,
    "environment/props/fence_h.png": structures.fence_h,
    "environment/props/barrel.png": structures.barrel,
    "environment/props/crate.png": structures.crate,
    "environment/props/signpost.png": structures.signpost,
    "environment/props/garden_bed.png": structures.garden_bed,
    "environment/props/pond.png": structures.pond,
}


def main():
    origins = {}
    for rel_path, build in SPRITES.items():
        result = build()
        canvas, origin = result if isinstance(result, tuple) else (result, None)
        if rel_path.split("/")[1] in ("hero", "nature", "props"):
            # standing sprites get a real blob shadow in 3D, so drop the painted one
            canvas.img.putalpha(canvas.img.getchannel("A").point(lambda a: 255 if a == 255 else 0))
        out = ASSETS / rel_path
        out.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(out)
        if origin:
            origins[rel_path] = {"origin": origin, "size": [canvas.w, canvas.h]}
    print(json.dumps(origins, indent=1))


if __name__ == "__main__":
    main()
