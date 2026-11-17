#!/usr/bin/env bash
# Runs the unit tests headless. Set GODOT=/path/to/godot to override auto-detection.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$(command -v godot || true)}"
[ -z "$GODOT" ] && [ -x "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ] && GODOT="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
[ -z "$GODOT" ] && { echo "Godot not found. Set GODOT=/path/to/godot"; exit 1; }
exec "$GODOT" --headless --path . -s tests/run_tests.gd
