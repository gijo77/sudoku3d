#!/usr/bin/env bash
# Exports a debug-signed APK to build/sudoku3d-debug.apk (for emulators / USB devices).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts_tools/_env.sh
[ -f android/build/build.gradle ] || { echo "Android build template missing. Run scripts_tools/setup_android.sh first."; exit 1; }
case "$(uname -s)" in
  Darwin) KS_DIR="$HOME/Library/Application Support/Godot/keystores";;
  *) KS_DIR="$HOME/.config/godot/keystores";;
esac
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$KS_DIR/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"
mkdir -p build
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-debug "Android Debug APK" build/sudoku3d-debug.apk
ls -la build/sudoku3d-debug.apk
echo "Install with: scripts_tools/run_adb.sh install"
