"""Shared palette. Every ramp goes from darkest (outline) to brightest."""
from pixel import hex_rgba as c

# Ground
GRASS = [c("#2f7a3a"), c("#3c8a3d"), c("#4f9f45"), c("#62b44c"), c("#86cc5e"), c("#b0e27a")]
GRASS_BASE = GRASS[3]

PATH_JOINT = c("#8d7a5e")
PATH = [c("#a8946f"), c("#c4b08a"), c("#d6c59f"), c("#e8dbbb")]

# Foliage
LEAF_OUTLINE = c("#173226")
LEAF = [c("#1b4630"), c("#235e39"), c("#2e7840"), c("#3e9346"), c("#58ad4f"), c("#8acb66")]
PINE_OUTLINE = c("#12302a")
PINE = [c("#184736"), c("#215f42"), c("#2d7a4d"), c("#43965a"), c("#6db574")]

# Wood
WOOD_OUTLINE = c("#2a1a14")
WOOD = [c("#4a2c1e"), c("#6b4128"), c("#8f5a34"), c("#b57d48"), c("#d9a66a")]
TIMBER = [c("#3a2418"), c("#553422"), c("#6e4630")]

# Roof tiles and brick
ROOF_OUTLINE = c("#3a1712")
ROOF = [c("#6e2a1c"), c("#9a3b24"), c("#c2552e"), c("#e07a42"), c("#f2a35e")]

# Stone
STONE_OUTLINE = c("#2e2b33")
STONE = [c("#4f4b55"), c("#6f6a72"), c("#908a8a"), c("#b2aa9f"), c("#d4cbbb")]
MOSS = [c("#3d7a3a"), c("#5d9c45"), c("#86c05e")]

# Plaster, glass, water
PLASTER = [c("#c9b48a"), c("#e3d2aa"), c("#f4e8c8")]
GLASS = [c("#1d2b4a"), c("#2f5590"), c("#5f8fd4"), c("#a9d0f5")]
WATER = [c("#1e3d6e"), c("#2a5a98"), c("#3a7cc4"), c("#62a6e6"), c("#b8e2ff")]
SOIL = [c("#3b2418"), c("#563624"), c("#704a30"), c("#8a6040")]
METAL = [c("#2a2a33"), c("#4a4b57"), c("#7a7c88")]

# Flowers
FLOWER_PINK = [c("#c2456e"), c("#f07aa0"), c("#ffc2d6")]
FLOWER_YELLOW = [c("#c9902a"), c("#f6c84a"), c("#fff2a0")]
FLOWER_WHITE = [c("#9aa4b8"), c("#e8eef6"), c("#ffffff")]
FLOWER_BLUE = [c("#3b4aa8"), c("#6a86e0"), c("#b9cbff")]
FLOWER_RED = [c("#8e2430"), c("#dd4a48"), c("#ff9a86")]
