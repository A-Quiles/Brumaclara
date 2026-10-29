#!/bin/sh
# Records the gameplay tour (gameplay_video.gd) and writes docs/video/jugabilidad.mp4 (1280x720) and
# docs/video/combate.gif (a slice of the fight for the README). Needs xvfb-run and ffmpeg.
#   sh tools/capture/make_video.sh [start second of the GIF] [GIF seconds]
set -e
cd "$(dirname "$0")/../.."
GODOT=${GODOT:-$HOME/bin/godot}
AVI=${TMPDIR:-/tmp}/guild_zero_tour.avi
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . --write-movie "$AVI" --fixed-fps 30 \
	--script res://tools/capture/gameplay_video.gd
mkdir -p docs/video
# nearest-neighbour upscale keeps the pixel art crisp
ffmpeg -y -loglevel error -i "$AVI" -vf scale=1280:720:flags=neighbor -c:v libx264 -preset veryfast -crf 20 \
	-pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart docs/video/jugabilidad.mp4
ffmpeg -y -loglevel error -ss "${1:-30}" -t "${2:-8}" -i "$AVI" \
	-vf "fps=15,split[a][b];[a]palettegen=max_colors=255[p];[b][p]paletteuse=dither=none" docs/video/combate.gif
ls -l docs/video
