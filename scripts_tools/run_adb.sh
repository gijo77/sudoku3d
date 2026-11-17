#!/usr/bin/env bash
# adb helper for the emulator or a USB device.
#   run_adb.sh devices            list connected devices
#   run_adb.sh install [apk]      install (replace) the debug APK, default build/sudoku3d-debug.apk
#   run_adb.sh launch             start the game
#   run_adb.sh logs               follow the game's log (Godot prints + errors)
#   run_adb.sh gfx                frame-time stats: janky frames % and percentiles (play for a while first)
#   run_adb.sh shot [file]        save a screenshot (default store/screenshots/device.png)
#   run_adb.sh uninstall          remove the app
# Use ANDROID_SERIAL=<serial> to pick a device when several are connected.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts_tools/_env.sh
command -v adb >/dev/null || { echo "adb not found (install Android platform-tools)"; exit 1; }
cmd="${1:-devices}"; shift || true
case "$cmd" in
  devices)   adb devices -l ;;
  install)   adb install -r "${1:-build/sudoku3d-debug.apk}" ;;
  launch)    adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 ;;
  logs)      adb logcat -c; adb logcat godot:V GodotLib:V AndroidRuntime:E DEBUG:E "*:S" ;;
  gfx)       adb shell dumpsys gfxinfo "$APP_ID" | sed -n '/Total frames rendered/,/Number Frame deadline missed/p' ;;
  shot)      adb exec-out screencap -p > "${1:-store/screenshots/device.png}"; echo "saved" ;;
  uninstall) adb uninstall "$APP_ID" ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
