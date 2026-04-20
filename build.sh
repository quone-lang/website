#!/usr/bin/env bash
# Build the Quone marketing site into dist/.
#
# Steps:
#   1. Copy static/ contents into dist/
#   2. Compile src/Main.elm to a temporary dist/elm.js with --optimize
#   3. Rename it to elm-<hash>.js
#   4. Fingerprint each woff/woff2 font file under dist/fonts/ to
#      <name>-<hash>.<ext>
#   5. Replace the placeholders in dist/index.html with the hashed
#      filenames (the Elm bundle and each font)
#
# Self-hosting and fingerprinting the fonts means we can long-cache
# them with the same `immutable` policy as the Elm bundle (see
# netlify.toml) and avoid the FOUT / cross-origin round trips that
# came with loading them from fonts.googleapis.com.
#
# This script is invoked by Netlify (see netlify.toml) and is also the
# canonical local build command; see README.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DIST="dist"
TMP_BUNDLE="$DIST/elm.js"
ELM_BIN="node_modules/.bin/elm"

rm -rf "$DIST"
mkdir -p "$DIST"

echo "Copying static assets..."
cp -R static/. "$DIST/"

if [ ! -x "$ELM_BIN" ]; then
  echo "Installing Elm..."
  npm install --no-save elm@0.19.1-5
fi

echo "Compiling Elm..."
npx --no-install elm make src/Main.elm --optimize --output="$TMP_BUNDLE"

BUNDLE_HASH="$(shasum -a 256 "$TMP_BUNDLE" | awk '{print $1}' | cut -c1-12)"
BUNDLE_NAME="elm-${BUNDLE_HASH}.js"

mv "$TMP_BUNDLE" "$DIST/$BUNDLE_NAME"

echo "Fingerprinting fonts..."
FONT_REPLACEMENTS=""
if [ -d "$DIST/fonts" ]; then
  for FONT_PATH in "$DIST/fonts"/*.woff "$DIST/fonts"/*.woff2; do
    [ -e "$FONT_PATH" ] || continue
    FONT_BASENAME="$(basename "$FONT_PATH")"
    FONT_NAME="${FONT_BASENAME%.*}"
    FONT_EXT="${FONT_BASENAME##*.}"
    FONT_HASH="$(shasum -a 256 "$FONT_PATH" | awk '{print $1}' | cut -c1-12)"
    HASHED_NAME="${FONT_NAME}-${FONT_HASH}.${FONT_EXT}"
    mv "$FONT_PATH" "$DIST/fonts/$HASHED_NAME"

    PLACEHOLDER="__FONT_$(echo "$FONT_NAME" | tr '[:lower:]' '[:upper:]')__"
    FONT_REPLACEMENTS="${FONT_REPLACEMENTS}${PLACEHOLDER}=${HASHED_NAME}"$'\n'
  done
fi

python3 - "$DIST/index.html" "$BUNDLE_NAME" "$FONT_REPLACEMENTS" <<'PY'
from pathlib import Path
import sys

index_path = Path(sys.argv[1])
bundle_name = sys.argv[2]
font_replacements_blob = sys.argv[3]

contents = index_path.read_text()

bundle_placeholder = "__ELM_BUNDLE__"
if bundle_placeholder not in contents:
    raise SystemExit(f"Missing {bundle_placeholder} in {index_path}")
contents = contents.replace(bundle_placeholder, bundle_name)

for line in font_replacements_blob.splitlines():
    line = line.strip()
    if not line:
        continue
    placeholder, hashed_name = line.split("=", 1)
    if placeholder not in contents:
        raise SystemExit(f"Missing {placeholder} in {index_path}")
    contents = contents.replace(placeholder, hashed_name)

index_path.write_text(contents)
PY

echo "Build complete. Output is in $DIST/ ($BUNDLE_NAME)."
