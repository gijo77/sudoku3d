#!/usr/bin/env bash
# Regenerates icons, the feature graphic and phone screenshots into store/ and assets/icons/.
# Needs Godot (auto-detected) and python3. Screenshots are rendered by Godot (no device needed).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts_tools/_env.sh
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT

python3 scripts_tools/make_icons.py
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

grab() {  # grab <out.png> <project dir> <resolution> <frame> <godot args...>
  local out="$1" proj="$2" res="$3" frame="$4"; shift 4
  "$GODOT" --path "$proj" --resolution "$res" --write-movie "$TMP/f.png" --fixed-fps 30 --quit-after $((frame + 2)) "$@" >/dev/null 2>&1
  cp "$TMP/f$(printf '%08d' "$frame").png" "$out"
  rm -f "$TMP"/f*.png "$TMP"/f.wav
}

grab store/feature_graphic_1024x500.png scripts_tools/feature_project 1024x500 6
mkdir -p store/screenshots
grab store/screenshots/01_menu.png . 540x960 8 scenes/main_menu.tscn
grab store/screenshots/02_classic.png . 540x960 30 scenes/game_3d.tscn -- --demo
grab store/screenshots/03_dark.png . 540x960 30 scenes/game_3d.tscn -- --demo --dark
grab store/screenshots/04_cube.png . 540x960 30 scenes/game_3d.tscn -- --demo --cube
grab store/screenshots/05_win.png . 540x960 26 scenes/game_3d.tscn -- --demo --win
echo "Store assets written to store/"
