# crystal-kit-sliver/

Source tree for the Crystal Palace ↔ Sliver port. See the [project root README](../README.md) for the overview, build instructions, and operational flow.

## Layout

| Directory | Contents |
|---|---|
| `loader/` | Reflective loader sources (Use case A, implant evasion). Verbatim copy of `loader/` from upstream Crystal-Kit. |
| `postex-loader/` | Post-ex loader sources (Use case B). Crystal-Kit upstream + Xenon patch (DFR → `ror13`, removed `$GMH`/`$GPA` CS smart pointers, added `dll_args` section). |
| `sliver-glue/` | Sliver-specific build glue and Extension wrapper. |
| `libtcg.x64.zip` | Upstream binary dependency. Kept in-tree so `loader.spec`'s `mergelib "../libtcg.x64.zip"` resolves without extra setup. |

## Build entry points

- `make -C loader all` — produce 8 `.o` files + 1 `.bin` under `loader/bin/`
- `make -C postex-loader all` — same for postex
- `make -C sliver-glue/wrapper all` — produce `sliver-glue/crystal-loader.x64.dll` (Sliver Extension)
- `sliver-glue/generate.sh` — Use case B build wrapper
- `sliver-glue/generate-implant.sh` — Use case A build wrapper
- `sliver-glue/bundle-implant.sh` — Use case A drop packager
- `sliver-glue/pack-extension.sh` — Use case B tarball packager

## Required environment

```bash
export CRYSTAL_PALACE_HOME=/path/to/external/crystalpalace/dist
# Optional, only for generate-implant.sh --profile mode:
export SLIVER_SERVER=/path/to/sliver-server
```

## Detailed documentation

- License: [`../LICENSE`](../LICENSE) — MIT, © 2026 Simone Licitra
- Upstream attributions: [`../NOTICE.md`](../NOTICE.md)
