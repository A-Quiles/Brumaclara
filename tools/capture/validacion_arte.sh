#!/bin/sh
# Captures of the art validation scene: <prefix>_dia.png, _dialogo.png, _noche.png
#   tools/capture/validacion_arte.sh docs/screenshots/validacion/antes
set -e
cd "$(dirname "$0")/../.."
mkdir -p "$(dirname "$1")"
xvfb-run -a "${GODOT:-$HOME/bin/godot}" --path . --script res://tools/capture/validacion_arte.gd -- "$(realpath -m "$1")"
