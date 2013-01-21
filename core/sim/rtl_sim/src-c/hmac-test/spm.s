    .data
    .global secret_start, secret_end
secret_start:
    .byte 0xde
    .byte 0xad
    .byte 0xbe
    .byte 0xef
secret_end:

    .global signature
signature:
    .space 16, 0x00

    .text
    .global public_start, public_end, spm
spm:
public_start:
    mov #secret_start, r13
    mov #secret_end, r14
    mov #signature, r15
    .word 0x1384
    ret
public_end:
