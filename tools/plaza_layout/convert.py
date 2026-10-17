"""Converts the layout fitted for the old 30-degree pitched camera (cam.py) to the shifted-lens
camera (cam2.py). Footprints on the ground are unchanged (both cameras see y = 0 identically);
raised levels, positions on them and every height are re-solved so that bases and tops land on the
same image rows as before, but now with truly vertical walls. Writes layout2.json."""
import copy
import json
import math
import sys

import cam
import cam2
import layout as old

H_OLD, H_NEW = cam.CAM[1], cam2.CAM[1]
COS30 = math.cos(math.radians(30))


def ray_hit(u, v, y):
    """Point at height y seen at image (u, v) by the new camera."""
    d = cam2.F * (cam2.CAM[1] - y) / (v - cam2.V_H)
    return (cam2.CAM[0] + (u - cam2.CX) * d / cam2.F, y, cam2.CAM[2] - d)


def move(p, y_new):
    """Old point -> new point at height y_new with the same image position."""
    u, v = cam.project(p)
    return ray_hit(u, v, y_new)


def height(base_new, top_old):
    """Height above base_new whose top lands on the image row of the old point top_old."""
    return (cam2.project(base_new)[1] - cam.project(top_old)[1]) / cam2.scale_at(base_new[2])


def rot(px, pz, yaw):
    a = math.radians(yaw)
    return px * math.cos(a) + pz * math.sin(a), -px * math.sin(a) + pz * math.cos(a)


# --- levels -------------------------------------------------------------------------
L1 = height((-12.0, 0, -8.6), (-12.0, old.L1, -8.6))       # left walkway wall
L2 = height((-4.3, 0, -16.8), (-4.3, old.L2, -16.8))       # back-left terrace wall
_v_top = cam.project((2.95, 0, 2.0))[1]
_v_bot = cam.project((2.95, old.SUNK, 2.0))[1]
SUNK = -(_v_bot - _v_top) / cam2.scale_at(2.0)               # path's right wall into the sunken garden
LEVEL = {0.0: 0.0, old.L1: L1, old.L2: L2, old.SUNK: SUNK}


def level_of(y):
    for k, v in LEVEL.items():
        if abs(y - k) < 1e-6:
            return v
    raise ValueError(y)


def k_scale(y_old):
    """Uniform scale of the plane map at an old level (1 on the ground)."""
    return (H_NEW - level_of(y_old)) * COS30 / (H_OLD - y_old)


def convert():
    out = []
    for o in old.objects:
        o = copy.deepcopy(o)
        t = o["type"]
        if t == "block":
            cx, bottom, cz = o["pos"]
            w, h, d = o["size"]
            top = bottom + h
            if any(abs(top - k) < 1e-6 for k in LEVEL):
                new_top = level_of(top)
            else:  # parapets: keep the front face's top row
                front = (cx, 0.0, cz + d / 2)
                new_top = height(front, (cx, top, cz + d / 2))
            o["size"][1] = round(new_top - bottom, 3)
        elif t == "house":
            x, y0, z = o["pos"]
            w, hh, d = o["size"]
            base = level_of(y0)
            k = k_scale(y0)
            c_new = move((x, y0, z), base) if y0 else (x, 0.0, z)
            fx, fz = rot(0, d / 2, o["yaw"])
            front_old = (x + fx, y0, z + fz)
            front_new = move(front_old, base) if y0 else front_old
            new_h = height(front_new, (front_old[0], y0 + hh, front_old[2]))
            ridge = height(c_new, (x, y0 + hh + o["roof_h"], z)) if o["roof_h"] else new_h
            o["pos"] = [round(c_new[0], 3), round(base, 3), round(c_new[2], 3)]
            o["size"] = [round(w * k, 3), round(new_h, 3), round(d * k, 3)]
            o["roof_h"] = round(max(0.0, ridge - new_h), 3)
            o["overhang"] = round(o["overhang"] * k, 3)
            if o["chimney"]:
                o["chimney"]["size"][1] = round(o["chimney"]["size"][1] * new_h / hh, 3)
            o["dormers"] = [dict(dm, x=round(dm["x"] * k, 3)) for dm in o["dormers"]]
        elif t == "stairs":
            x, y0, z = o["pos"]
            y1 = y0 + o["rise"]
            dx, dz = rot(0, -o["run"], o["yaw"])
            b_new = move((x, y0, z), level_of(y0)) if y0 else (x, 0.0, z)
            t_new = move((x + dx, y1, z + dz), level_of(y1))
            ux, uz = rot(0, -1, o["yaw"])
            run = (t_new[0] - b_new[0]) * ux + (t_new[2] - b_new[2]) * uz
            o["pos"] = [round(b_new[0], 3), round(b_new[1], 3), round(b_new[2], 3)]
            o["rise"] = round(level_of(y1) - level_of(y0), 3)
            o["run"] = round(run, 3)
            o["width"] = round(o["width"] * k_scale(y0), 3)
        else:
            x, y0, z = o["pos"]
            if y0:
                p = move((x, y0, z), level_of(y0))
                o["pos"] = [round(p[0], 3), round(p[1], 3), round(p[2], 3)]
        out.append(o)

    # raised blocks whose front wall stands on the walkway: that wall follows the walkway's surface
    for o in out:
        if o["name"] in ("TerraceLeft", "TerraceRight"):
            cx, bottom, cz = o["pos"]
            w, h, d = o["size"]
            z_front = move((cx, old.L1, cz + d / 2), L1)[2]
            z_back = cz - d / 2
            o["pos"][2] = round((z_front + z_back) / 2, 3)
            o["size"][2] = round(z_front - z_back, 3)
    return out


if __name__ == "__main__":
    objects = convert()
    print("levels: L1 %.3f  L2 %.3f  SUNK %.3f" % (L1, L2, SUNK))
    json.dump(objects, open(sys.argv[1], "w"), indent=1)
    for o in objects:
        if o["type"] in ("house", "stairs"):
            print(o["name"], o["pos"], o.get("size"), o.get("roof_h"), o.get("rise"), o.get("run"))
