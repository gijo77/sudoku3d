#!/usr/bin/env bash
# Creates the RELEASE (upload) keystore with keytool and a keystore.env that export_release.sh reads.
# The keystore lives OUTSIDE the repo by default (~/sudoku3d-keystore/) and is also gitignored.
#
# BACK UP release.keystore AND its passwords somewhere safe (password manager + offline copy).
# With Play App Signing this is only your *upload* key (Google holds the real signing key), and Google
# can reset it if lost - but treat it like a password anyway. NEVER commit it.
#
# Usage: scripts_tools/make_keystore.sh [output-dir]
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts_tools/_env.sh
OUT="${1:-$HOME/sudoku3d-keystore}"
KS="$OUT/release.keystore"
ALIAS="sudoku3d"
[ -f "$KS" ] && { echo "Keystore already exists: $KS (not overwriting)"; exit 1; }
mkdir -p "$OUT"; chmod 700 "$OUT"

read -r -p "Your name or company (certificate CN): " CN
read -r -s -p "Choose a keystore password (min 6 chars; also used for the key): " PASS; echo
read -r -s -p "Repeat password: " PASS2; echo
[ "$PASS" = "$PASS2" ] || { echo "Passwords differ"; exit 1; }
[ ${#PASS} -ge 6 ] || { echo "Password too short"; exit 1; }

# Godot requires the keystore and key passwords to be the same.
keytool -genkeypair -v -keystore "$KS" -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" -dname "CN=$CN, O=com.aitechplay, C=US"

ENVF="$OUT/keystore.env"
umask 077
cat > "$ENVF" <<ENV
# Source by scripts_tools/export_release.sh. Keep private.
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KS"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PASS"
ENV
chmod 600 "$ENVF" "$KS"
echo
echo "Created: $KS"
echo "Env file: $ENVF  (export_release.sh loads it automatically)"
echo "Certificate fingerprint:"
keytool -list -v -keystore "$KS" -alias "$ALIAS" -storepass "$PASS" | grep -E "SHA1|SHA256"
echo "NOW: back this folder up securely. Do not commit it."
