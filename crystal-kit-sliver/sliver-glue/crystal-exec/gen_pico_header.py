#!/usr/bin/env python3
"""
gen_pico_header.py — XOR-encrypt a Crystal Palace PICO and emit a C header.

Fresh random 256-byte key every build so each crystal-exec.x64.dll has a
unique byte pattern — defeats static signature matching on the embedded PICO.

Usage: gen_pico_header.py <input.bin> <output.h>
"""
import os, sys

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input.bin> <output.h>", file=sys.stderr)
    sys.exit(1)

infile, outfile = sys.argv[1:]
key = os.urandom(256)

with open(infile, 'rb') as f:
    raw = f.read()

enc = bytes([b ^ key[i % len(key)] for i, b in enumerate(raw)])

def c_array(name, data):
    lines = [f'static const unsigned char {name}[] = {{']
    for i in range(0, len(data), 16):
        chunk = data[i:i+16]
        lines.append('    ' + ','.join(f'0x{b:02x}' for b in chunk) + ',')
    lines.append('};')
    return '\n'.join(lines)

with open(outfile, 'w') as f:
    f.write('/* auto-generated — do not edit */\n\n')
    f.write(c_array('crystalexec_pico_key', key))
    f.write(f'\nstatic const unsigned int crystalexec_pico_key_len = {len(key)};\n\n')
    f.write(c_array('crystalexec_pico', enc))
    f.write(f'\nstatic const unsigned int crystalexec_pico_len = {len(enc)};\n')

print(f'[+] {outfile}: {len(raw)} bytes encrypted, key_len={len(key)}', file=sys.stderr)
