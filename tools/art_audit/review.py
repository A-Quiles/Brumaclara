"""Second step of the art audit: compares every asset with the approved references of its family
(docs/plan_unificacion_artistica.md, 3.1 and 3.3) and lists the ones that stray.

For each metric of audit.csv (smooth, edges, noise, sat, value) the family's references give a
median and a spread; an asset strays on a metric when it is more than LIMIT spreads away. The
verdicts are a starting point for the visual review, not the decision (plan, 3.6): the final list,
with the reasons seen in the game, is kept by hand in art/revision/no_encajan/LEEME.md.

    python3 tools/art_audit/audit.py && python3 tools/art_audit/review.py
Writes tools/art_audit/out/review.csv and one contact sheet per family (references first).
"""
import csv
import statistics
from pathlib import Path

import sheet

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "out"
LIMIT = 2.5
METRICS = {  # metric: (reason when too high, reason when too low)
    "smooth": ("sombreado degradado, se lee como pintura y no como píxel", "sombreado plano"),
    "edges": ("demasiadas líneas duras", "detalle sobredimensionado: pocos bordes, parece ampliado"),
    "noise": ("ruido de píxeles sueltos", None),
    "sat": ("más saturado que su familia", "más apagado que su familia"),
    "value": ("más claro que su familia", "más oscuro que su familia"),
}
PROPS_REF = ["barrel", "crate", "lantern", "street_lamp", "bench", "stall_red", "stall_blue", "stall_green",
             "well", "wagon", "signpost", "notice_board", "firewood", "sacks", "planter", "trough",
             "hay_bale", "fence", "weapon_rack", "training_dummy", "flower_cart", "bucket"]
NATURE_REF = ["tree_oak", "tree_fir", "tree_young", "bush", "boulder", "stump", "rocks"]
FAMILIES = {  # family: (asset prefix filter, reference stems)
    "personajes": (("characters/",), ["hero", "hero__corto", "hero__coleta", "hero__largo", "heroine", "heroine__largo"]),
    "edificios": (("environment/buildings/",), None),  # references: the facades and house pieces
    "objetos": (("environment/props/", "environment/nature/"), PROPS_REF + NATURE_REF),
    "suelos": (("environment/textures/",), ["grass", "dirt", "forest_floor", "garden_soil", "cliff", "rift_ground", "stone_wall"]),
    "efectos": (("effects/",), ["explosion", "spark", "bolt"]),
}
SKIP = ("_mask", "blob_shadow", "/ui/")


def family_of(asset):
    for fam, (prefixes, _) in FAMILIES.items():
        if any(asset.startswith("assets/" + p) for p in prefixes):
            return fam
    return None


def main():
    rows = [r for r in csv.DictReader(open(OUT / "audit.csv")) if not any(s in r["asset"] for s in SKIP)]
    out = []
    for fam, (_, refs) in FAMILIES.items():
        members = [r for r in rows if family_of(r["asset"]) == fam]
        if refs is None:
            ref = [r for r in members if "/facade_" in r["asset"] or "/house_" in r["asset"] or "/side_" in r["asset"]]
        else:
            ref = [r for r in members if Path(r["asset"]).stem in refs]
        stats = {}
        for m in METRICS:
            vals = [float(r[m]) for r in ref]
            med = statistics.median(vals)
            spread = max(statistics.median([abs(v - med) for v in vals]) * 1.4826, 0.06)  # floor: near-identical references (recoloured sheets) would flag everything
            stats[m] = (med, spread)
        for r in members:
            reasons, worst = [], 0.0
            for m, (high, low) in METRICS.items():
                z = (float(r[m]) - stats[m][0]) / stats[m][1]
                worst = max(worst, abs(z))
                if z > LIMIT and high:
                    reasons.append(high)
                elif z < -LIMIT and low:
                    reasons.append(low)
            out.append({"family": fam, "asset": r["asset"], "reference": Path(r["asset"]).stem in (refs or []) or r in ref,
                        "score": round(worst, 1), "reasons": "; ".join(reasons)})
        flagged = sorted((o for o in out if o["family"] == fam and o["reasons"] and not o["reference"]),
                         key=lambda o: -o["score"])
        specs = [r["asset"] + _crop(r) for r in ref[:10]] + [o["asset"] + _crop(next(r for r in rows if r["asset"] == o["asset"])) for o in flagged[:40]]
        if specs:
            sheet.sheet(OUT / f"sheet_{fam}.png", specs)
    with open(OUT / "review.csv", "w", newline="") as f:
        w = csv.DictWriter(f, ["family", "asset", "reference", "score", "reasons"])
        w.writeheader()
        w.writerows(sorted(out, key=lambda o: (o["family"], -o["score"])))
    for o in sorted(out, key=lambda o: (o["family"], -o["score"])):
        if o["reasons"] and not o["reference"]:
            print(f'{o["family"]:10} {o["score"]:5} {o["asset"][7:]:55} {o["reasons"]}')


def _crop(row):
    """Sheets of animation frames: show the first cell only (frames are 56 px, monsters up to 64)."""
    w, h = map(int, row["size"].split("x"))
    if row["asset"].startswith("assets/characters/"):
        cell = 56 if w % 56 == 0 else (50 if w % 50 == 0 else (60 if w % 60 == 0 else 64))
        return f":0,0,{min(cell, w)},{min(cell, h)}"
    if "/textures/" in row["asset"]:
        return f":0,0,{min(64, w)},{min(64, h)}"
    return ""


if __name__ == "__main__":
    main()
