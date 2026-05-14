#!/usr/bin/env bash
#
# pack-extension.sh — package the crystal-loader Sliver Extension as a tarball
# installable via 'extensions install' in the Sliver client.
#
# Usage:
#   ./pack-extension.sh [output.tar.gz]
#
# Expects crystal-loader.x64.dll (the runtime DLL wrapper around the PICO loader)
# to be present in this directory. That DLL is the step-6 deliverable and is NOT
# produced by generate.sh — generate.sh produces the PICO .bin that the wrapper
# consumes at runtime.

set -euo pipefail

OUTPUT="${1:-./build/crystal-loader-0.1.0.tar.gz}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$OUTPUT")"

mkdir -p "$BUILD_DIR"

DLL="$SCRIPT_DIR/crystal-loader.x64.dll"
MANIFEST="$SCRIPT_DIR/extension.json"

if [[ ! -f "$DLL" ]]; then
    echo "error: $DLL not found." >&2
    echo "       The DLL wrapper around the PICO loader is a step-6 deliverable." >&2
    echo "       See docs/PORTING_MAP.md §7 point 1 for context." >&2
    exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
    echo "error: $MANIFEST not found." >&2
    exit 2
fi

echo "[*] Creating Sliver Extension tarball: $OUTPUT"
tar -C "$SCRIPT_DIR" -czf "$OUTPUT" extension.json crystal-loader.x64.dll

echo "[+] Done. Install on Sliver client with:"
echo "    extensions install $OUTPUT"
