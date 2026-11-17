#!/usr/bin/env bash
# Exports the signed release Android App Bundle (AAB) for Google Play: build/sudoku3d-release.aab
# Requires the release keystore from scripts_tools/make_keystore.sh. Bump version/code in
# export_presets.cfg (and version/name) before every Play upload - each upload needs a higher code.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts_tools/_env.sh
[ -f android/build/build.gradle ] || { echo "Android build template missing. Run scripts_tools/setup_android.sh first."; exit 1; }
ENVF="${KEYSTORE_ENV:-$HOME/sudoku3d-keystore/keystore.env}"
if [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]; then
  [ -f "$ENVF" ] || { echo "No release keystore. Run scripts_tools/make_keystore.sh first (or set KEYSTORE_ENV=/path/keystore.env)."; exit 1; }
  # shellcheck disable=SC1090
  source "$ENVF"
fi
[ -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ] || { echo "Keystore file not found: $GODOT_ANDROID_KEYSTORE_RELEASE_PATH"; exit 1; }
# Make sure tests pass before shipping.
./scripts_tools/run_tests.sh | tail -3
mkdir -p build
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Android Release AAB" build/sudoku3d-release.aab
ls -la build/sudoku3d-release.aab
echo "Upload build/sudoku3d-release.aab in Play Console (see store/RELEASE_CHECKLIST.md)."
