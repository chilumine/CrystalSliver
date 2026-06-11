# crystal-kit-sliver/

Source tree for the Crystal Palace ↔ Sliver port. See the [project root README](../README.md) for the overview, build instructions, and operational flow.

## Layout

| Directory | Contents |
|---|---|
| `loader/` | Reflective loader sources (Use case A, implant evasion). Verbatim copy of `loader/` from upstream Crystal-Kit. |
| `postex-loader/` | Post-ex loader sources (Use case B). Crystal-Kit upstream + Xenon patch (DFR → `ror13`, removed `$GMH`/`$GPA` CS smart pointers, added `dll_args` section). |
| `sliver-glue/` | Sliver-specific build glue and Extension wrapper. |
| `sliver-glue/wrapper/` | `crystal-loader.c` — Sliver Extension DLL for Use case B (`crystal` command). |
| `sliver-glue/crystal-exec/` | `crystalexec.c` + `crystal-exec.c` — built-in shell executor via Crystal Palace (`crystal-exec` command). 4-step build: DLL → PICO → embedded header → extension DLL. |
| `sliver-glue/stager/` | Custom Use case A stager. `stager.c` reads `payload.dat` (AES-256-CBC), decrypts via BCrypt, and executes the PICO. `gen_payload.py` encrypts with `openssl`. `manifest.xml` declares `asInvoker`. |
| `libtcg.x64.zip` | Upstream binary dependency. Kept in-tree so `loader.spec`'s `mergelib "../libtcg.x64.zip"` resolves without extra setup. |

## Build entry points

- `make -C loader all` — produce 8 `.o` files + 1 `.bin` under `loader/bin/`
- `make -C postex-loader all` — same for postex
- `make -C sliver-glue/wrapper all` — produce `sliver-glue/crystal-loader.x64.dll` (Sliver Extension, `crystal` command)
- `make -C sliver-glue/crystal-exec all` — produce `sliver-glue/crystal-exec.x64.dll` (built-in shell executor, `crystal-exec` command)
- `sliver-glue/postex.sh <dll> [args]` — Use case B convenience wrapper: DLL → PICO, prints ready-to-paste Sliver command
- `sliver-glue/generate.sh` — lower-level Use case B build wrapper (called by `postex.sh`)
- `sliver-glue/generate-implant.sh` — Use case A build wrapper
- `sliver-glue/bundle-stager.sh <pico.bin> [stager.exe]` — Use case A primary: AES-encrypt PICO, compile stager → `csvchelper.exe` + `payload.dat`
- `sliver-glue/bundle-implant.sh` — Use case A legacy: Crystal Palace demo stager `run.x64.exe` (detected by Defender, kept for reference)
- `sliver-glue/pack-extension.sh` — package both DLLs + `extension.json` into Sliver Extension tarball

## Required environment

```bash
export CRYSTAL_PALACE_HOME=/path/to/external/crystalpalace/dist
# Optional, only for generate-implant.sh --profile mode:
export SLIVER_SERVER=/path/to/sliver-server
```

## Detailed documentation

- License: [`../LICENSE`](../LICENSE) — MIT, © 2026 Simone Licitra
- Upstream attributions: [`../NOTICE.md`](../NOTICE.md)
