"""Village layout fitted to the reference image. Units: 1 = 16 character pixels; plaza level y = 0.

Every entry is plain data; the Godot builder turns it into scenes. `pos` is the centre of the
object's base, `yaw` is rotation.y in degrees (Godot convention), sizes are (x, y, z).
"""
import json
import math

L1 = 2.2    # left walkway / right walkway level
L2 = 3.8    # back terraces
SUNK = -2.5  # sunken garden right of the path
BASE = -3.0  # bottom of every ground block

objects = []


def block(name, x0, x1, z0, z1, top_y, top="paving", side="stone", bottom=BASE, yaw=0.0, cx=None, cz=None, edges=True):
    """Axis-aligned ground/wall block from extents; or rotated when cx/cz (centre) and yaw are given."""
    if cx is None:
        cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    objects.append({"type": "block", "name": name, "pos": [cx, bottom, cz],
                    "size": [abs(x1 - x0), top_y - bottom, abs(z1 - z0)], "yaw": yaw,
                    "top": top, "side": side, "edges": edges})


def house(name, pos, size, roof, roof_h, facade, yaw=0.0, ridge_along_x=False, overhang=0.3, chimney=None, dormers=()):
    objects.append({"type": "house", "name": name, "pos": list(pos), "size": list(size), "yaw": yaw,
                    "roof": roof, "roof_h": roof_h, "ridge_along_x": ridge_along_x, "overhang": overhang,
                    "facade": facade, "chimney": chimney, "dormers": list(dormers)})


def thing(otype, name, x, y, z, **extra):
    objects.append({"type": otype, "name": name, "pos": [x, y, z], **extra})


def stairs(name, bottom, direction_deg, width, rise, run, steps, side="stone"):
    """bottom = centre of the lowest step's front edge; direction = compass yaw the stairs climb toward."""
    objects.append({"type": "stairs", "name": name, "pos": list(bottom), "yaw": direction_deg,
                    "width": width, "rise": rise, "run": run, "steps": steps, "side": side})


# --- ground -------------------------------------------------------------------
BACK = -21.0   # the painted backdrop stands here; nothing may poke through it
block("Plaza", -8.0, 8.6, -12.6, -4.3, 0.0, top="paving")
block("PlazaBackLeft", -8.0, -3.0, -16.8, -12.6, 0.0, top="paving")
block("PlazaBackRight", 3.0, 6.95, BACK, -12.6, 0.0, top="paving")
block("BackPath", -1.9, 1.9, -15.5, -12.6, 0.0, top="paving")
block("BackGrassLeft", -3.0, -1.9, -15.5, -12.6, 0.0, top="grass")
block("BackGrassRight", 1.9, 3.0, -15.5, -12.6, 0.0, top="grass")
block("Path", -2.05, 1.95, -4.3, 14.0, 0.0, top="path")
block("PathGrassLeft", -3.0, -2.05, -4.3, 14.0, 0.0, top="grass")
block("PathGrassRight", 1.95, 2.95, -4.3, 14.0, 0.0, top="grass")
block("GardenLeft", -30.0, -3.0, -4.3, 14.0, 0.0, top="grass_dark")
block("GardenLeftBack", -30.0, -8.0, -8.6, -4.3, 0.0, top="grass_dark")
block("PlazaLeftStrip", -8.0, -3.0, -8.6, -4.3, 0.0, top="paving")
block("GardenSunken", 2.95, 9.0, -4.3, 14.0, SUNK, top="grass")
block("RightBase", 9.0, 30.0, -4.3, 14.0, SUNK, top="grass")

# left walkway (L1) and the terrace behind it (L2)
block("WalkwayLeft", -30.0, -7.8, BACK, -8.6, L1, top="paving")
block("TerraceLeft", -12.5, -5.6, BACK, -14.6, L2, top="paving")
block("TerraceLeftBack", -5.6, -3.0, BACK, -16.8, L2, top="grass")

# right walkway (R1) runs diagonally, the B9 terrace (R2) sits behind it
EDGE_A, EDGE_B = (6.79, -11.75), (15.6, -3.89)
ex, ez = (EDGE_B[0] - EDGE_A[0]) / math.dist(EDGE_A, EDGE_B), (EDGE_B[1] - EDGE_A[1]) / math.dist(EDGE_A, EDGE_B)
edge_len = math.dist(EDGE_A, EDGE_B) + 8.0           # runs on past the right edge of the screen
edge_yaw = -math.degrees(math.atan2(ez, ex))        # -41.7
nx, nz = -ez, ex                                    # into the walkway (away from the camera)
nx, nz = (nx, nz) if nz < 0 else (-nx, -nz)
mid = (EDGE_A[0] + ex * edge_len / 2, EDGE_A[1] + ez * edge_len / 2)
depth_r1 = 14.0
block("WalkwayRight", 0, edge_len, 0, depth_r1, L1, top="paving", yaw=edge_yaw,
      cx=mid[0] + nx * depth_r1 / 2, cz=mid[1] + nz * depth_r1 / 2)
block("TerraceRight", 6.95, 20.0, BACK, -13.0, L2, top="paving")

# --- houses ----------------------------------------------------------------------
# facade specs are read by the art generator (keys documented in village_houses.py)
house("HouseBlueRoof", (-4.8, 0.0, -13.7), (3.55, 3.99, 2.4), "blue", 1.35,
      {"style": "b1", "infill": "brick"}, chimney={"pos": [-1.1, 0.0, 0.6], "size": [0.6, 1.6, 0.6]})
house("HouseOrangeRoof", (5.0, 0.0, -15.0), (3.9, 3.42, 2.6), "orange", 1.64,
      {"style": "b2", "infill": "cream"}, chimney={"pos": [1.25, 0.0, 0.0], "size": [0.55, 1.4, 0.55]})
house("HouseRedRoof", (9.1, L2, -14.7), (4.2, 2.0, 3.0), "red", 1.75,
      {"style": "b9", "infill": "brick"}, ridge_along_x=True,
      dormers=[{"x": -1.0}, {"x": 1.0}])
house("HouseLongLeft", (-15.5, L1, -11.4), (8.6, 2.0, 3.6), "orange", 1.27,
      {"style": "b4", "infill": "brick"}, ridge_along_x=True, dormers=[{"x": -2.2}, {"x": 0.4}])
house("HouseTealLeft", (-14.5, L1, -17.5), (7.0, 2.6, 3.5), "teal", 1.7,
      {"style": "b5", "infill": "cream"}, ridge_along_x=True)
house("HouseCreamBack", (-11.1, L2, -16.2), (3.3, 2.5, 3.0), "orange", 1.6,
      {"style": "b6", "infill": "cream"})
house("HouseBrickBack", (-7.75, L2, -16.1), (2.3, 2.3, 2.8), "blue", 1.3,
      {"style": "b7", "infill": "brick"})
house("HouseFarLeft", (-22.0, L1, -14.5), (5.0, 3.0, 4.0), "red", 1.6,
      {"style": "b3", "infill": "cream"})
house("HouseTealRight", (11.6, L1, -10.3), (2.6, 4.79, 2.6), "teal", 1.8,
      {"style": "b10", "infill": "brick"}, yaw=-10.0)
house("HouseStoneRight", (16.56, L1, -7.47), (7.0, 4.09, 5.0), "orange", 2.4,
      {"style": "b11", "infill": "cream"}, yaw=edge_yaw)
house("HouseBottomRight", (10.9, SUNK, -1.0), (6.2, 2.5, 7.2), "orange", 4.0,
      {"style": "b12", "infill": "cream"}, ridge_along_x=True, overhang=0.4, dormers=[{"x": 1.6, "big": True}])
house("TowerLeft", (-9.31, 0.0, 1.90), (6.0, 7.5, 4.7), "flat", 0.0,
      {"style": "tower", "infill": "brick_big"}, yaw=-10.0)
house("HouseCornerBlue", (-13.0, 0.0, 9.0), (6.0, 3.0, 6.0), "blue", 2.4,
      {"style": "plain", "infill": "brick"}, ridge_along_x=False, yaw=-30.0)

# --- plaza furniture ---------------------------------------------------------------
thing("fountain", "Fountain", 0.03, 0.0, -8.69)
thing("plaza_border", "PlazaBorder", -0.2, 0.0, -8.3, size=[7.2, 6.4])
thing("stall", "StallRainbow", 4.4, 0.0, -11.0, awning="rainbow", width=2.2, depth=1.4)
thing("stall", "StallGreen", 6.3, 0.0, -9.2, awning="green", width=2.0, depth=1.4)
thing("kiosk", "Kiosk", -6.55, 0.0, -12.3, width=1.7, depth=1.3)
stairs("StairsRight", (7.75, 0.0, -7.75), edge_yaw, 2.2, L1, 3.0, 8)
stairs("StairsRightUpper", (8.6, L1, -11.0), 0.0, 1.4, L2 - L1, 2.0, 6)
stairs("StairsLeftUpper", (-8.95, L1, -12.6), 0.0, 2.0, L2 - L1, 2.0, 6)

# low walls
block("ParapetPathLeft", -3.45, -3.0, -4.3, 2.0, 0.75, top="stone_top", side="stone")
block("ParapetPathRight", 2.95, 3.4, -4.3, 14.0, 0.3, top="stone_top", side="stone")
block("ParapetPlazaRight", 3.4, 8.6, -4.75, -4.3, 0.3, top="stone_top", side="stone")

# --- vegetation, props and people ----------------------------------------------------
for x, y, z, kind in [(-2.2, 0, -14.7, "pine_small"), (2.5, 0, -14.5, "pine_small"), (-4.35, 0, -0.5, "pine"),
                      (4.9, SUNK, -1.9, "pine"), (-15.9, L1, -7.2, "pine_mid")]:
    thing("tree", "Pine", x, y, z, kind=kind)
for x, y, z, kind in [(-4.0, 0, 4.4, "bush")]:
    thing("tree", "Bush", x, y, z, kind=kind)
for kind, x, y, z in [("barrel", 5.1, 0, -9.3), ("barrel", 6.35, 0, -8.6), ("crate", 8.6, 0, -7.3),
                      ("barrel_blue", 9.05, 0, -6.6), ("basket", 8.7, 0, -6.4), ("crate", 5.7, SUNK, -0.1),
                      ("crate_stack", 15.2, L1, -5.3), ("signpost", -1.8, 0, -12.6), ("bollard", 8.3, 0, -10.6),
                      ("dirt", 4.4, SUNK, 0.4), ("dirt", 5.4, SUNK, 2.0)]:
    thing("prop", kind.title().replace("_", ""), x, y, z, kind=kind)
for kind, x, y, z in [("boy", -2.8, 0, -10.5), ("oldman", -4.25, 0, -8.0), ("woman_purple", -5.75, 0, -5.8),
                      ("woman_lilac", 2.85, 0, -10.8), ("merchant", 4.25, 0, -10.1), ("girl_orange", 3.55, 0, -4.8),
                      ("knight", 6.6, 0, -4.8), ("girl_brown", -10.25, L1, -11.15), ("guard", -9.2, L1, -11.6),
                      ("girl_red", 8.8, L1, -10.1), ("boy_blue", 10.2, L1, -9.4), ("kid_a", -5.45, 0, 3.75),
                      ("kid_b", -4.2, 0, 3.65), ("vendor", 6.4, 0, -9.8)]:
    thing("npc", kind.title().replace("_", ""), x, y, z, kind=kind)
thing("player", "Player", 0.0, 0.0, 0.0)

if __name__ == "__main__":
    import sys
    json.dump(objects, open(sys.argv[1], "w"), indent=1)
    print(len(objects), "objects")
