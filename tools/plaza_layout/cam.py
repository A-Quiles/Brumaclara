"""Camera fitted to the reference image (1408x768): pitch 30 deg, vertical FOV 26 deg.
Hero feet at image (705, 600) are the world origin; the hero (2 units tall) is ~95 px there."""
import math
W, H = 1408, 768
CX, CY = W / 2, H / 2
VFOV = 26.0
PITCH = 30.0
F = CY / math.tan(math.radians(VFOV / 2))
th = math.radians(PITCH)
S_HERO = 47.5
CAM_H = (F * math.sin(th) + math.cos(th) * (600 - CY)) / S_HERO
alpha = math.atan((600 - CY) / F)
CAM_D = CAM_H / math.tan(th + alpha)
CAM = (0.0, CAM_H, CAM_D)
R = (1.0, 0.0, 0.0)
U = (0.0, math.cos(th), -math.sin(th))
Fw = (0.0, -math.sin(th), -math.cos(th))


def ray(u, v):
    x, y = (u - CX) / F, -(v - CY) / F
    return tuple(R[i] * x + U[i] * y + Fw[i] for i in range(3))


def P(u, v, y0=0.0):
    """World point at height y0 seen at image (u, v)."""
    d = ray(u, v)
    t = (y0 - CAM[1]) / d[1]
    return (CAM[0] + t * d[0], y0, CAM[2] + t * d[2])


def scale_at(u, v, y0=0.0):
    d = ray(u, v)
    t = (y0 - CAM[1]) / d[1]
    return F / t


def project(p):
    v = tuple(p[i] - CAM[i] for i in range(3))
    xc = sum(v[i] * R[i] for i in range(3))
    yc = sum(v[i] * U[i] for i in range(3))
    zc = sum(v[i] * Fw[i] for i in range(3))
    return CX + F * xc / zc, CY - F * yc / zc


def height_to(x, z, y0, v_top):
    """Height above y0 at (x, z) whose top projects to image row v_top."""
    lo, hi = 0.0, 60.0
    for _ in range(80):
        mid = (lo + hi) / 2
        if project((x, y0 + mid, z))[1] > v_top:
            lo = mid
        else:
            hi = mid
    return lo


if __name__ == "__main__":
    print("camera", [round(c, 3) for c in CAM], "F", round(F, 1))


def at_depth(u, v, z):
    """World point (x, y, z) on the plane z = const that projects to image (u, v)."""
    d = ray(u, v)
    t = (z - CAM[2]) / d[2]
    return (CAM[0] + t * d[0], CAM[1] + t * d[1], z)
