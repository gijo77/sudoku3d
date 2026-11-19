#!/usr/bin/env bash
# Makes the portrait orientation requirement optional so Play does not hide the app from devices
# (tablets, desktops, XR) that report no portrait screen. Safe to run repeatedly.
set -euo pipefail
cd "$(dirname "$0")/.."
M=android/build/src/main/AndroidManifest.xml
[ -f "$M" ] || { echo "Android build template missing. Run scripts_tools/setup_android.sh first."; exit 1; }
if grep -q "android.hardware.screen.portrait" "$M"; then
  echo "Manifest already patched."
  exit 0
fi
python3 - "$M" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
anchor = '    <application'
add = ('    <uses-feature\n        android:name="android.hardware.screen.portrait"\n        android:required="false" />\n\n')
assert anchor in s
s = s.replace(anchor, add + anchor, 1)
open(p, "w").write(s)
PY
echo "Manifest patched: portrait screen is no longer a required feature."
