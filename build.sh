#!/usr/bin/env bash
# Build the Quone marketing site into dist/.
#
# Steps:
#   1. Copy static/ contents into dist/
#   2. Compile src/Main.elm to a temporary dist/elm.js with --optimize
#   3. Rename it to elm-<hash>.js
#   4. Replace the placeholder in dist/index.html with that hashed filename
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

python3 - "$DIST/index.html" "$BUNDLE_NAME" <<'PY'
from pathlib import Path
import sys

index_path = Path(sys.argv[1])
bundle_name = sys.argv[2]
placeholder = "__ELM_BUNDLE__"

contents = index_path.read_text()

if placeholder not in contents:
    raise SystemExit(f"Missing {placeholder} in {index_path}")

index_path.write_text(contents.replace(placeholder, bundle_name))
PY

echo "Build complete. Output is in $DIST/ ($BUNDLE_NAME)."
