# Shared by the helper scripts: locates Godot, JDK 17 and the Android SDK. Source it, do not run it.
# Override any of these by exporting GODOT, JAVA_HOME, ANDROID_SDK_ROOT before running a script.

if [ -z "${GODOT:-}" ]; then
  GODOT="$(command -v godot || true)"
  [ -z "$GODOT" ] && [ -x "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ] && GODOT="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
  [ -z "$GODOT" ] && [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ] && GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
  [ -z "$GODOT" ] && { echo "Godot not found. Set GODOT=/path/to/godot"; return 1 2>/dev/null || exit 1; }
fi
export GODOT

# Godot 4.x Android builds need JDK 17 (newer JDKs such as 21/25 often break Gradle).
if [ -z "${JAVA_HOME:-}" ] || ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -q '"17\.'; then
  for cand in "$HOME/Library/Java/jdk-17/Contents/Home" "$HOME/Library/Java/jdk-17" "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home" \
              "/usr/lib/jvm/java-17-openjdk-amd64" "$HOME/.jdks/jdk-17"; do
    [ -x "$cand/bin/java" ] && export JAVA_HOME="$cand" && break
  done
fi
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"

# Package id and version used by the scripts.
export APP_ID="com.aitechplay.sudoku3d"
export GODOT_VERSION_DIR="$("$GODOT" --version 2>/dev/null | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?)\.([a-z]+)\..*/\1.\3/')"
