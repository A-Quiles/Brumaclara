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

ASSETS = Path(__file__).resolve().parents[2] / "assets"

SPRITES = {
    "characters/hero/hero_walk.png": hero.hero_sheet,
    "environment/ground_tiles.png": ground.ground_atlas,
    "environment/stone_wall.png": ground.stone_wall,
    "environment/buildings/cottage.png": structures.cottage,
    "environment/nature/tree_oak.png": nature.tree_oak,
    "environment/nature/tree_pine.png": nature.tree_pine,
    "environment/nature/bush.png": nature.bush,
    "environment/nature/bush_flowers.png": lambda: nature.bush(flowers=True, seed=6),
    "environment/nature/rock_small.png": nature.rock_small,
    "environment/nature/rock_medium.png": nature.rock_medium,
    "environment/nature/rock_large.png": nature.rock_large,
    "environment/props/fence_h.png": structures.fence_h,
    "environment/props/fence_v.png": structures.fence_v,
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
        out = ASSETS / rel_path
        out.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(out)
        if origin:
            origins[rel_path] = {"origin": origin, "size": [canvas.w, canvas.h]}
    print(json.dumps(origins, indent=1))


if __name__ == "__main__":
    main()
