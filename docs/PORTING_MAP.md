# Porting Map — Crystal-Kit → crystal-kit-sliver

File-by-file mapping of upstream sources to this repository, with the literal Xenon-style patch applied to `postex-loader/`. Read this together with the project README before modifying any file under `loader/` or `postex-loader/`.

**Verified upstreams (snapshot @ 2026-04-03):**

- `rasta-mouse/Crystal-Kit` (MIT) — base implementation for Cobalt Strike
- `nickswink/Crystal-Kit-Xenon` (MIT) — cross-C2 patch template for Mythic Xenon, applies 1:1 to Sliver

## 1. Inventory and action per file

### `loader/` (main reflective loader — Use case A)

Every file is a **verbatim copy** of the same path in `rasta-mouse/Crystal-Kit/loader/`. No modifications.

| File | Action |
|---|---|
| `Makefile` | copy 1:1 |
| `loader.spec` | copy 1:1 |
| `local-loader.spec` | copy 1:1 |
| `pico.spec` | copy 1:1 |
| `src/loader.c` + `loader.h` | copy 1:1 |
| `src/services.c` | copy 1:1 |
| `src/hooks.c` | copy 1:1 |
| `src/spoof.c` + `spoof.h` | copy 1:1 |
| `src/mask.c` + `mask.h` | copy 1:1 |
| `src/cleanup.c` + `cleanup.h` | copy 1:1 |
| `src/cfg.c` + `cfg.h` | copy 1:1 |
| `src/pico.c` | copy 1:1 |
| `src/draugr.asm` | copy 1:1 |
| `src/memory.h`, `tcg.h` | copy 1:1 |

### `postex-loader/` (post-ex loader — Use case B)

Copied from `rasta-mouse/Crystal-Kit/postex-loader/` with **two patched files**. The patches are identical to `nickswink/Crystal-Kit-Xenon/postex-loader/` and replace Cobalt-Strike-specific glue with the Sliver-compatible variant.

| File | Action |
|---|---|
| `Makefile` | copy 1:1 |
| `loader.spec` | **patched** (§2.1) |
| `pico.spec` | copy 1:1 |
| `src/loader.c` | **patched** (§2.2) |
| `src/loader.h` | copy 1:1 |
| `src/services.c`, `hooks.c`, `spoof.c` + `.h`, `draugr.asm` | copy 1:1 |
| `src/cleanup.c` + `.h`, `cfg.c` + `.h`, `pico.c` | copy 1:1 |
| `src/hash.h` | copy 1:1 (ror13 constants) |
| `src/memory.h`, `tcg.h` | copy 1:1 |

### Root-level upstream files

| File | Action | Note |
|---|---|---|
| `Makefile` (top-level) | not copied | upstream version only chains into `loader/` and `postex-loader/`; replaced by our `sliver-glue/Makefile` |
| `README.md` | replaced | new README in repo root + per-project README under `crystal-kit-sliver/` |
| `LICENSE` | replaced | new MIT LICENSE under Simone Licitra; upstream rasta-mouse and nickswink MIT notices preserved in `NOTICE.md` |
| `crystalkit.cna` | **NOT copied** | Aggressor Script is Cobalt-Strike-only; replaced by `sliver-glue/extension.json` + scripts |
| `crystalkit.yar` | not copied (optional) | YARA self-detection rule; can be regenerated with Crystal Palace `-g` flag if needed |
| `libtcg.x64.zip` | kept in tree | binary dependency referenced as `../libtcg.x64.zip` by both spec files; located at `crystal-kit-sliver/libtcg.x64.zip` |
| `.gitattributes`, `.gitignore` | replaced | repo-specific |

## 2. Literal patches in `postex-loader/`

Both patches are byte-identical to `nickswink/Crystal-Kit-Xenon` and verified locally with `diff -u`.

### 2.1 `postex-loader/loader.spec`

```diff
--- crystal-kit/postex-loader/loader.spec
+++ crystal-kit-sliver/postex-loader/loader.spec
@@ -6,13 +6,9 @@
     load "bin/services.x64.o"
         merge

-    dfr "patch_resolve" "strings"
+    dfr "patch_resolve" "ror13"
     mergelib "../libtcg.x64.zip"

-    # patch smart pointers in
-    patch "get_module_handle" $GMH
-    patch "get_proc_address"  $GPA
-
     # merge hooks into the loader
     load "bin/hooks.x64.o"
         merge
@@ -42,6 +38,11 @@
         preplen
         link "mask"

+    # DLL Args from File
+    load %ARGFILE
+        preplen
+        link "dll_args"
+
     # now get the tradecraft as a PICO
     run "pico.spec"
         link "pico"
```

**Per-line rationale:**

| Line change | Why |
|---|---|
| `dfr "patch_resolve" "strings"` → `"ror13"` | Cobalt Strike injects pre-resolved smart pointers (`$GMH`, `$GPA`) at build time, so `strings` mode is fine there. Sliver does not, so we need runtime ror13 hash resolution. |
| `patch "get_module_handle" $GMH` | Removed. `$GMH` is a CS smart pointer; Sliver has nothing equivalent. |
| `patch "get_proc_address" $GPA` | Removed. Same reason as above for `$GPA`. |
| `load %ARGFILE … link "dll_args"` | Added. The post-ex DLL's runtime arguments are baked into a `dll_args` section at link time, read by the loader via `GETRESOURCE` at execution. |

### 2.2 `postex-loader/src/loader.c`

```diff
--- crystal-kit/postex-loader/src/loader.c   (139 lines)
+++ crystal-kit-sliver/postex-loader/src/loader.c (143 lines)
@@ -10,6 +10,7 @@
 char _PICO_ [ 0 ] __attribute__ ( ( section ( "pico" ) ) );
 char _MASK_ [ 0 ] __attribute__ ( ( section ( "mask" ) ) );
 char _DLL_  [ 0 ] __attribute__ ( ( section ( "dll" ) ) );
+char _DLLARGS_ [ 0 ] __attribute__ ( ( section ( "dll_args" ) ) );

 int __tag_setup_hooks  ( );
 int __tag_setup_memory ( );

@@ -132,9 +133,12 @@
     /* now run the DLL */
     DLLMAIN_FUNC entry_point = EntryPoint ( &dll_data, dll_dst );

+    /* Pointer to DLL arguments */
+	char * dll_arguments = GETRESOURCE ( _DLLARGS_ );
+
     /* free the unmasked copy */
     KERNEL32$VirtualFree ( dll_src, 0, MEM_RELEASE );

-    entry_point ( ( HINSTANCE ) dll_dst, DLL_PROCESS_ATTACH, NULL );
-    entry_point ( ( HINSTANCE ) ( char * ) go, 0x4, loader_arguments );
+    entry_point ( ( HINSTANCE ) dll_dst, DLL_PROCESS_ATTACH, dll_arguments );
+    // entry_point ( ( HINSTANCE ) ( char * ) go, 0x4, NULL );
 }
```

**Per-line rationale:**

| Line | Why |
|---|---|
| `_DLLARGS_` section attribute | Declares an empty 0-length array tied to the `dll_args` section so the linker can emit a symbol the loader can address. |
| `dll_arguments = GETRESOURCE(_DLLARGS_)` | Reads the section data at runtime. `GETRESOURCE` is a macro defined in `memory.h` (upstream). |
| `DllMain(... , dll_arguments)` | Forwards the embedded arguments as `lpReserved` of `DllMain`. The wrapped DLL can ignore them or parse them. |
| Second `entry_point(... , 0x4, loader_arguments)` commented out | Reason code `0x4` is a Beacon-specific second entrypoint used by Cobalt Strike post-ex DLLs (e.g. `RDLL_GENERATE` callback). Sliver does not need it. |

**Whitespace note:** the `dll_arguments` line in the Xenon fork uses a TAB instead of 4 spaces, and the file has no trailing newline. Preserved verbatim for byte-identity with the upstream fork.

## 3. CS-specific concepts → Sliver mapping

| Cobalt Strike concept | Where it lives in CS | Sliver equivalent |
|---|---|---|
| `BEACON_RDLL_GENERATE` Aggressor hook | Server-side script run during stager generation | Build-time wrapper script: `sliver-glue/generate-implant.sh` |
| `POSTEX_RDLL_GENERATE` Aggressor hook | Server-side script run during post-ex DLL generation | Build-time wrapper script: `sliver-glue/generate.sh` |
| `BEACON_RDLL_GENERATE_LOCAL` | Stageless variant | Same script with `--profile` mode (or `--dll`) |
| `$GMH` smart pointer (kernel32!GetModuleHandleA) | Injected at build time | None — resolved at runtime via ror13 hash |
| `$GPA` smart pointer (kernel32!GetProcAddress) | Injected at build time | None — same as above |
| `$DLL` | Beacon DLL passed by CS server | Sliver implant DLL passed by `generate-implant.sh` |
| `$MASK` | XOR key generated by Crystal Palace | Identical — generated in `.spec` with `generate $MASK 128` |
| `%ARGFILE` (introduced by Xenon) | Path to args file at build time | Identical — passed as positional `%ARGFILE=...` to `./link` |
| `DllMain` reason `0x4` | CS Beacon post-ex second call | Inexistent on Sliver — commented out in `loader.c` |

## 4. Sliver Extension model

The post-ex pipeline (Use case B) produces a PICO `.bin`, but Sliver Extensions are loaded as DLLs into the implant runtime. The bridge is `crystal-kit-sliver/sliver-glue/wrapper/crystal-loader.c`:

- exports a single function `go(char *argsBuffer, uint32_t bufferSize, goCallback callback)` matching COFFLoader's `LoadAndRun` signature
- parses `argsBuffer` via `BeaconDataParse` / `BeaconDataExtract` (BOF compatibility layer from TrustedSec COFFLoader, BSD-3-Clause)
- allocates RWX memory, copies the PICO blob, jumps to offset 0 (the `+gofirst` flag in `loader.spec` guarantees the `go` symbol lands there)

The manifest `crystal-kit-sliver/sliver-glue/extension.json` declares:

```json
{
  "name": "crystal-loader",
  "command_name": "crystal",
  "entrypoint": "go",
  "files": [{"os":"windows","arch":"amd64","path":"crystal-loader.x64.dll"}],
  "arguments": [{"name":"payload","type":"file","optional":false}]
}
```

Schema validated against the live `sliverarmory/CredManBOF` and `sliverarmory/COFFLoader` manifests at the time of writing.

## 5. Files that fix at packaging time

| Sliver-glue file | Produced by | Consumed by |
|---|---|---|
| `crystal-loader.x64.dll` | `sliver-glue/wrapper/Makefile` | Sliver implant runtime |
| `crystal-loader-0.1.0.tar.gz` | `sliver-glue/pack-extension.sh` | Sliver client `extensions install` |
| `<name>.crystal.bin` (PICO) | `sliver-glue/generate-implant.sh` or `generate.sh` | Crystal Palace stager (`run.x64.exe`) or `crystal` Sliver command |
| `drop.zip` | `sliver-glue/bundle-implant.sh` | Operator manual delivery to target |

## 6. Attribution checklist (required by upstream licenses)

- `NOTICE.md` reproduces copyright notices for rasta-mouse (Crystal-Kit), nickswink (Crystal-Kit-Xenon), TrustedSec (COFFLoader BOF compat), Raphael Mudge / AFF-WG (Crystal Palace), plus bundled iced (MIT) and JSON-java (CC0).
- Source files copied verbatim retain their original copyright headers where present.
- `crystal-loader.c` carries a fresh MIT header (Simone Licitra) since it is newly written.
