#!/usr/bin/env bash
# One-time Android toolchain setup for exporting Sudoku 3D. Safe to re-run: every step is skipped
# if already done. Each LARGE download asks for confirmation first (pass --yes to accept all).
#
#   1. Godot export templates for your exact Godot version   (~1 GB download)
#   2. JDK 17 (Temurin) into ~/Library/Java/jdk-17 (macOS) or ~/.jdks/jdk-17   (~190 MB)
#   3. Android SDK packages via sdkmanager                  (NDK alone is ~1.5 GB)
#   4. Godot editor settings: Java SDK path + Android SDK path
#   5. Godot Android build template -> android/build (needed for Gradle / AAB export)
#   6. A debug keystore for debug APKs
#
# Usage: scripts_tools/setup_android.sh [--yes] [--skip-ndk]
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts_tools/_env.sh

YES=0; SKIP_NDK=0
for a in "$@"; do case "$a" in --yes) YES=1;; --skip-ndk) SKIP_NDK=1;; esac; done

# Versions required by the Godot 4.7 docs (https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
BUILD_TOOLS="35.0.1"; PLATFORM="android-35"; TARGET_PLATFORM="android-36"
CMAKE="3.10.2.4988404"; NDK="28.1.13356709"

confirm() {  # confirm "what" "size"
  [ "$YES" = 1 ] && return 0
  read -r -p "Download/install $1 ($2)? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

OS="$(uname -s)"; ARCH="$(uname -m)"
GVER="$("$GODOT" --version | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?)\.([a-z0-9]+)\..*/\1-\3/')"      # e.g. 4.7.2-stable
GDIR="$("$GODOT" --version | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?)\.([a-z0-9]+)\..*/\1.\3/')"      # e.g. 4.7.2.stable
if [ "$OS" = Darwin ]; then
  TEMPLATES="$HOME/Library/Application Support/Godot/export_templates/$GDIR"
  EDITOR_CFG="$HOME/Library/Application Support/Godot/editor_settings-4.7.tres"
  JDK_DEST="$HOME/Library/Java/jdk-17"
else
  TEMPLATES="$HOME/.local/share/godot/export_templates/$GDIR"
  EDITOR_CFG="$HOME/.config/godot/editor_settings-4.7.tres"
  JDK_DEST="$HOME/.jdks/jdk-17"
fi
echo "Godot $GDIR | templates: $TEMPLATES"

# --- 1. export templates -------------------------------------------------------
if [ -f "$TEMPLATES/android_source.zip" ]; then
  echo "[ok] export templates already installed"
else
  if confirm "Godot $GDIR export templates" "~1 GB"; then
    TMP="$(mktemp -d)"; trap 'rm -rf "${TMP:?}"' EXIT
    URL="https://github.com/godotengine/godot/releases/download/$GVER/Godot_v$GVER""_export_templates.tpz"
    echo "Downloading $URL"
    curl -L --fail --progress-bar -o "$TMP/templates.tpz" "$URL"
    mkdir -p "$TMP/x" "$TEMPLATES"
    unzip -q "$TMP/templates.tpz" -d "$TMP/x"
    cp -R "$TMP/x/templates/." "$TEMPLATES/"
    echo "[done] templates installed"
  else echo "[skip] templates (required for export)"; fi
fi

# --- 2. JDK 17 -------------------------------------------------------------------
if [ -x "$JDK_DEST/Contents/Home/bin/java" ] || [ -x "$JDK_DEST/bin/java" ] || { [ -n "${JAVA_HOME:-}" ] && "$JAVA_HOME/bin/java" -version 2>&1 | grep -q '"17\.'; }; then
  echo "[ok] JDK 17 present"
else
  if confirm "Temurin JDK 17" "~190 MB"; then
    case "$OS-$ARCH" in
      Darwin-arm64) P="mac/aarch64";; Darwin-x86_64) P="mac/x64";; Linux-x86_64) P="linux/x64";; Linux-aarch64) P="linux/aarch64";;
      *) echo "Unsupported platform $OS-$ARCH"; exit 1;;
    esac
    TMP2="$(mktemp -d)"
    curl -L --fail --progress-bar -o "$TMP2/jdk.tgz" "https://api.adoptium.net/v3/binary/latest/17/ga/$P/jdk/hotspot/normal/eclipse"
    tar -xzf "$TMP2/jdk.tgz" -C "$TMP2"
    mkdir -p "$(dirname "$JDK_DEST")"
    rm -rf "${JDK_DEST:?}"; mv "$TMP2"/jdk-17* "$JDK_DEST"
    rm -rf "${TMP2:?}"
    echo "[done] JDK 17 at $JDK_DEST"
  else echo "[skip] JDK 17 (required for Gradle builds)"; fi
fi
source scripts_tools/_env.sh   # re-detect JAVA_HOME

# --- 3. Android SDK packages -------------------------------------------------------
if command -v sdkmanager >/dev/null 2>&1; then
  PKGS=("platform-tools" "build-tools;$BUILD_TOOLS" "platforms;$PLATFORM" "platforms;$TARGET_PLATFORM" "cmake;$CMAKE")
  [ "$SKIP_NDK" = 0 ] && PKGS+=("ndk;$NDK")
  MISSING=()
  for p in "${PKGS[@]}"; do [ -d "$ANDROID_SDK_ROOT/${p//;//}" ] || MISSING+=("$p"); done
  if [ ${#MISSING[@]} -eq 0 ]; then echo "[ok] Android SDK packages present"
  elif confirm "Android SDK packages: ${MISSING[*]}" "NDK ~1.5 GB, others <150 MB"; then
    yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null || true
    sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "${MISSING[@]}"
    echo "[done] SDK packages installed"
  else echo "[skip] SDK packages"; fi
else
  echo "[!] sdkmanager not found. Install Android command-line tools (https://developer.android.com/studio#command-tools)"
  echo "    into $ANDROID_SDK_ROOT/cmdline-tools/latest and re-run."
fi

# --- 4. Godot editor settings -------------------------------------------------------
if [ ! -f "$EDITOR_CFG" ]; then "$GODOT" --headless --editor --quit >/dev/null 2>&1 || true; fi
if [ -f "$EDITOR_CFG" ] && [ -n "${JAVA_HOME:-}" ]; then
  python3 - "$EDITOR_CFG" "$JAVA_HOME" "$ANDROID_SDK_ROOT" <<'PY'
import re, sys
path, java, sdk = sys.argv[1:4]
s = open(path).read()
def setkey(s, key, val):
    line = f'{key} = "{val}"'
    if re.search(rf'^{re.escape(key)} = .*$', s, re.M):
        return re.sub(rf'^{re.escape(key)} = .*$', line, s, flags=re.M)
    return s.rstrip("\n") + "\n" + line + "\n"
s = setkey(s, "export/android/java_sdk_path", java)
s = setkey(s, "export/android/android_sdk_path", sdk)
open(path, "w").write(s)
print("[done] editor settings: java_sdk_path and android_sdk_path set")
PY
else echo "[skip] editor settings (JDK 17 not found yet)"; fi

# --- 5. Android build template (Gradle) -----------------------------------------------
if [ -f "$TEMPLATES/android_source.zip" ]; then
  if [ -f android/build/build.gradle ]; then echo "[ok] android/build template present"
  else
    mkdir -p android/build
    unzip -q -o "$TEMPLATES/android_source.zip" -d android/build
    echo "$GDIR" > android/.build_version
    touch android/build/.gdignore
    echo "[done] build template installed to android/build"
  fi
fi

# --- 6. debug keystore ------------------------------------------------------------------
DK="$(dirname "$EDITOR_CFG")/keystores/debug.keystore"
if [ -f "$DK" ]; then echo "[ok] debug keystore present"
elif command -v keytool >/dev/null 2>&1 && keytool -help >/dev/null 2>&1; then
  mkdir -p "$(dirname "$DK")"
  keytool -genkeypair -v -keystore "$DK" -storepass android -keypass android -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
  echo "[done] debug keystore created"
else echo "[skip] debug keystore (needs a JDK with keytool)"; fi
echo "Setup finished. Next: scripts_tools/export_debug.sh"
