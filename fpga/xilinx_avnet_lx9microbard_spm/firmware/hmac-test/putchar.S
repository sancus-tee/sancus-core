#include "hardware.h"

.global putchar_impl
        .type putchar_impl, @function
putchar_impl:                                ;send a byte
    mov     #0, &CCTL1              ;select compare mode
    mov     #10, r13                ;ten bits: Start, 8 Data, Stop
    rla     r15                     ;shift in start bit (0)
    bis     #0x0200, r15            ;set tenth bit (1), thats the stop bit
    mov     &TAR, &CCR1             ;set up start time
.Lt1lp:
    add     #BAUD, &CCR1            ;set up for one bit
    rrc     r15                     ;shift data trough carry
    jc      .Lt1                    ;test carry bit
.Lt0:
    bic.b   #TX, &P1OUT             ;generate pulse
    jmp     .Ltc                    ;
.Lt1:
    bis.b   #TX, &P1OUT             ;just use the same amount of time as for a zero
    jmp     .Ltc                    ;
.Ltc:
    bit     #CCIFG, &CCTL1          ;wait for compare
    jz      .Ltc                    ;loop until the bit is set
    bic     #CCIFG, &CCTL1          ;clear for next loop
    dec     r13                     ;decrement bit counter
    jnz     .Lt1lp                  ;loop until all bits are transmitted
    ret
