"""Writes docs/habilidades_lista.md: every node of every tree, from data/trees (the source of truth).

    python3 tools/data/tree_doc.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROMAN = ["", "I", "II", "III", "IV", "V"]
TYPES = {"activa": "Activa", "mejora": "Mejora", "pasiva": "Pasiva", "definitiva": "Definitiva"}


def main():
    out = ["# Lista de habilidades", "",
           "Generada desde `data/trees/*.json` con `python3 tools/data/tree_doc.py`: no se edita a mano.",
           "El diseño (reglas, PA, niveles, estados) está en `docs/arbol_habilidades.md`.", "",
           "Columnas de las activas: maná / recarga / daño, y lo que hacen. Cada activa tiene al menos una",
           "mejora; las mejoras piden su habilidad y las activas de nivel II o más piden otra activa de su rama",
           "de un nivel inferior.", ""]
    summary = []
    for tree in ["fuego", "hielo", "rayo", "sombra", "tierra", "luz", "tronco"]:
        data = json.loads((ROOT / "data" / "trees" / f"{tree}.json").read_text())
        nodes = data["nodes"]
        count = {t: sum(1 for n in nodes if n["type"] == t) for t in TYPES}
        summary.append(f"| {data['name']} | {count['activa']} | {count['mejora']} | {count['pasiva']} | {count['definitiva']} | {len(nodes)} |")
        out += [f"## {data['name']}", ""]
        branches = {}
        for n in nodes:
            branches.setdefault(n["branch"], n["branch_name"])
        for b in sorted(branches, key=lambda x: (x < 0, x)):
            out += [f"### {branches[b]}", "", "| Nivel | Nodo | Tipo | PA | Efecto |", "|---|---|---|---|---|"]
            for n in nodes:
                if n["branch"] == b:
                    tipo = TYPES[n["type"]] + (" (próximamente)" if n.get("implemented", True) is False else "")
                    out.append(f"| {ROMAN[n['tier']]} | {n['name']} | {tipo} | {n['cost']} | {n['desc']} |")
            out.append("")
    head = ["## Resumen", "", "| Árbol | Activas | Mejoras | Pasivas | Definitiva | Nodos |", "|---|---|---|---|---|---|"]
    text = out[:9] + head + summary + [""] + out[9:]
    (ROOT / "docs" / "habilidades_lista.md").write_text("\n".join(text) + "\n")


if __name__ == "__main__":
    main()
