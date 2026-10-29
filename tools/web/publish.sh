#!/bin/sh
# Exports the game for the browser (export_presets.cfg, "Web") and pushes it to the gh-pages branch,
# served at https://a-quiles.github.io/Brumaclara/. Needs Godot's web export templates installed.
set -e
cd "$(dirname "$0")/../.."
GODOT=${GODOT:-$HOME/bin/godot}
rm -rf build/web && mkdir -p build/web
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
touch build/web/.nojekyll
cd build/web
rm -rf .git && git init -q -b gh-pages && git add -A
git commit -q -m "Versión web de GUILD ZERO"
git push -f "$(git -C ../.. remote get-url origin)" gh-pages
rm -rf .git
