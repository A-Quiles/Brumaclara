"""Shifted-lens camera fitted to the reference (1408x768): the image plane is vertical, so vertical
edges stay vertical like hand-drawn pixel art. It sees the y = 0 ground exactly like the old 30-degree
pitched camera in cam.py (same horizon and scale), but nothing is foreshortened vertically."""
import math
import cam

W, H = cam.W, cam.H
CX = W / 2
COS, TAN = math.cos(math.radians(cam.PITCH)), math.tan(math.radians(cam.PITCH))
F = cam.F / COS                          # focal length in reference pixels
CAM = (0.0, cam.CAM[1] / COS, cam.CAM[2] + cam.CAM[1] * TAN)
V_H = cam.CY - cam.F * TAN               # horizon row (above the image)
SHIFT = (cam.CY - V_H) / F               # slope of the ray through the image centre


def project(p):
    d = CAM[2] - p[2]
    return CX + F * (p[0] - CAM[0]) / d, V_H + F * (CAM[1] - p[1]) / d


def scale_at(z):
    """Reference pixels per world unit, horizontally and vertically, at depth z."""
    return F / (CAM[2] - z)


def ground_z(v, y0=0.0):
    """World z of the point at height y0 that projects to image row v."""
    return CAM[2] - F * (CAM[1] - y0) / (v - V_H)


if __name__ == "__main__":
    print("camera", [round(c, 3) for c in CAM], "F", round(F, 1), "horizon", round(V_H, 1), "shift", round(SHIFT, 4))
    for p in [(0, 0, 0), (3, 0, -8), (-5, 0, 6), (0, 0, -21)]:
        a, b = cam.project(p), project(p)
        print(p, [round(x, 2) for x in a], [round(x, 2) for x in b])
