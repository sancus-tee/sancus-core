    .text
    .global hmac_verify
hmac_verify:
    .word 0x1382
    ret

    .global hmac_write
hmac_write:
    .word 0x1383
    ret
