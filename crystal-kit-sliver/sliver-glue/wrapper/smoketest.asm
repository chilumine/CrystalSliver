; smoketest.asm
;
; Minimal x64 shellcode used to validate the crystal-loader.x64.dll wrapper
; on a Sliver implant WITHOUT depending on Crystal Palace.
;
; Signature expected by the wrapper: void entry(void* unused).
; This shellcode immediately returns, so the wrapper's plumbing
; (BeaconDataParse + VirtualAlloc + exec + return) can be exercised
; end-to-end on a Windows lab target.
;
; Build: nasm -f bin smoketest.asm -o smoketest.bin

BITS 64

_start:
    ; Microsoft x64 ABI: first arg in RCX (unused here).
    xor eax, eax    ; return 0
    ret
