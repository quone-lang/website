#!/usr/bin/env bash
# Build the Quone marketing site into dist/.
#
# Steps:
#   1. Compile src/Main.elm to dist/elm.js with --optimize
#   2. Copy static/ contents into dist/
#
# This script is invoked by Netlify (see netlify.toml) and is also the
# canonical local build command; see README.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DIST="dist"

rm -rf "$DIST"
mkdir -p "$DIST"

echo "Compiling Elm..."
elm make src/Main.elm --optimize --output="$DIST/elm.js"

echo "Copying static assets..."
cp -R static/. "$DIST/"

echo "Build complete. Output is in $DIST/."
