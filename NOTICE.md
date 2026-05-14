# NOTICE

This project (`crystal-kit-sliver`) is a port to Sliver C2 of upstream
evasion tooling. It includes and/or derives from third-party software
distributed under the MIT License. All required copyright notices are
reproduced below.

---

## crystal-kit-sliver

Copyright (c) 2026 Simone Licitra
Licensed under the MIT License (see [LICENSE](LICENSE)).

This work adapts the `postex-loader` of the upstream Crystal-Kit project,
applies the cross-C2 porting pattern introduced by Crystal-Kit-Xenon, and
adds Sliver-specific build glue, manifest, and packaging.

---

## Upstream — Crystal-Kit

Source: <https://github.com/rasta-mouse/Crystal-Kit>
License: MIT
Copyright (c) rasta-mouse

The contents of `crystal-kit-sliver/loader/` and
`crystal-kit-sliver/postex-loader/` are direct copies (with the Xenon
adjustments noted below) of the corresponding directories in this
upstream repository. All original copyright notices in source files are
preserved.

---

## Upstream — COFFLoader (BOF compatibility layer)

Source: <https://github.com/sliverarmory/COFFLoader> (originally TrustedSec)
License: BSD-3-Clause
Copyright (c) 2020 TrustedSec, LLC

The files `crystal-kit-sliver/sliver-glue/wrapper/beacon.h`,
`beacon_compatibility.h` and `beacon_compatibility.c` are unmodified
copies of COFFLoader's Cobalt Strike BOF compatibility layer. They
provide `BeaconDataParse`/`BeaconDataExtract`/`BeaconPrintf` used by
our Sliver Extension wrapper to decode arguments passed by the implant.
All original copyright notices in those source files are preserved.

---

## Upstream — Crystal-Kit-Xenon

Source: <https://github.com/nickswink/Crystal-Kit-Xenon>
License: MIT
Copyright (c) nickswink

The Mythic Xenon porting fork introduced two targeted modifications in
`postex-loader/`:

1. `postex-loader/loader.spec`: switched DFR resolution mode from
   `"strings"` to `"ror13"`; removed Cobalt Strike smart-pointer patches
   (`$GMH`, `$GPA`); added a `dll_args` section linked from `%ARGFILE`.

2. `postex-loader/src/loader.c`: added the `_DLLARGS_` section attribute
   and the `dll_arguments` variable read via `GETRESOURCE`; routed those
   arguments into the `DLL_PROCESS_ATTACH` entrypoint call; commented out
   the Cobalt-Strike-specific second `entry_point` call with reason
   `0x4`.

These same changes apply unchanged to the Sliver port and are reused as-is.

---

## External runtime dependencies (NOT bundled in this repository)

The following components are required for a successful build but are
NOT included in this source tree:

### Crystal Palace linker (`crystalpalace.jar`)

Source: <https://tradecraftgarden.org/> (`download/cpdist-latest.tgz`)
License: BSD-3-Clause
Copyright (c) 2025 Raphael Mudge, Adversary Fan Fiction Writers Guild

Crystal Palace also bundles:
  - iced disassembler — Copyright (c) iced project and contributors, MIT
  - JSON in Java (org.json) — Public Domain (CC0 1.0)

This jar must be downloaded separately. It is invoked at build time via
the bundled `./link` wrapper (or directly with `java -jar crystalpalace.jar run ...`).
The `generate.sh` script uses the verified positional CLI:
  `./link <loader.spec> <input.dll> <out.bin> [%KEY=value ...]`

### `libtcg.x64.zip`

Source: distributed alongside the upstream Crystal-Kit repository.
License: see upstream notice.

This library appears to be derived from QEMU's Tiny Code Generator (TCG)
and may carry LGPL/GPL obligations. Users redistributing builds that
include `libtcg.x64.zip` should verify license compliance with their own
counsel.

---

## Third-party C2 framework

Sliver C2 — <https://github.com/BishopFox/sliver> — is licensed under
GPLv3. This project produces a Sliver Extension that is loaded into the
Sliver implant at runtime; the present source code is not a derivative
work of Sliver itself.
