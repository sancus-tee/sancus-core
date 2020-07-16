/*===========================================================================*/
/*                 SANCUS MODULE NON-ENTRY GADGETS                           */
/*---------------------------------------------------------------------------*/
/* Common definitions for the sm_illegal_entry and sm_irq_exec_violation     */
/* test cases.                                                               */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

    /* ---------------------- ENABLE AND INIT VICTIM SM  --------------- */

.set unpr_stack_base, (foo_secret_start-2)

do_main:
    disable_wdt
    eint
    clr &reti_addr
    mov #unpr_stack_base, r1
    sancus_enable #1234, #foo_public_start, #foo_public_end, #foo_secret_start, #foo_secret_end
    mov #abuse_rd_gadget, r4
    br #foo_public_start

    /* ---------------------- SM FOO WITH NON-ENTRY GADGETS --------------- */

.set foo_secret_start, DMEM_240
.set foo_secret_end, DMEM_26E
.set foo_irq_sp, (foo_secret_end-2)
.set foo_private_data, (foo_secret_end-4)
.set foo_stack_base, foo_private_data   ; points above the first stack address

.set secret_val, 0xbeef
.set stack_a_val, 0xcafe
.set stack_b_val, 0xbabe

foo_public_start:
    clr &foo_irq_sp
    mov #stack_a_val, &(foo_stack_base-2)
    mov #stack_b_val, &(foo_stack_base-4)
    mov #secret_val, &foo_private_data
    br r4
foo_gadget_rd:
    mov &foo_private_data, r4
	br #end_of_test
foo_gadget_wr:
    mov r4, &foo_private_data
	br #end_of_test
foo_gadget_wrap:
    .word 0x1384
    br #end_of_test
foo_gadget_disable:
    sancus_disable #end_of_test
foo_public_end:

    /* ----------------------         END OF TEST        --------------- */
end_of_test:
	mov #0x3000, r15
	br #0xffff


    /* ---------------------- MACROS TO PREPARE GADGET ABUSE --------------- */

; try to abuse a gadget in foo to leak data to the ISR
.set attacker_val, 0xdead
.macro prepare_rd_gadget
    mov #abuse_wr_gadget, &reti_addr
    mov #attacker_val, r4
.endm

; try to abuse a gadget in foo to overwrite foo_private_data
.macro prepare_wr_gadget
    mov #abuse_wrap_gadget, &reti_addr
    mov #attacker_val, r4
.endm

; try to abuse a gadget in foo to let it wrap some data with its private key
; memory for sancus_wrap (exclusive-end intervals)
.set ad, DMEM_202
.set ad_end, (ad+2)
.set body, ad_end
.set body_end, (body+2)
.set cipher, body_end
.set tag, (cipher+2)
.set ad_val, 0x1CEB
.set body_val, 0x00DA
.macro prepare_wrap_gadget
    mov #abuse_disable_gadget, &reti_addr
    clr &cipher
    clr &tag
    mov #ad_val, &ad
    mov #body_val, &body
    clr r9 ; use foo's pc-based private key
    mov #ad, r10
    mov #ad_end, r11
    mov #body, r12
    mov #body_end, r13
    mov #cipher, r14
    mov #tag, r15
.endm

; try to abuse a gadget in foo to make it disable itself
.macro prepare_disable_gadget
    mov #end_of_test, &reti_addr
.endm

    /* ---------------------- VIOLATION INTERRUPT ROUTINE --------------- */

.set reti_addr, DMEM_200

VIOLATION_ISR:
    mov #foo_public_start, r15
    sancus_get_id
    tst r15 
    jnz 1f
    ; leak secret after foo has been disabled
    mov &foo_private_data, r4
    mov #0x2000, r15
1:  cmp #abuse_wr_gadget, &reti_addr
    jne 2f
    ; leak secret val in r4
    pop r4
    mov #0x1000, r15
2:  ; re-initialize foo, and continue
    mov &reti_addr, r4
    clr r5
    clr r15
    mov #unpr_stack_base, r1
    do_reti #foo_public_start


    /* ----------------------         INTERRUPT VECTORS  --------------- */
    
.macro init_ivt
    .word end_of_test       ; Interrupt  0 (lowest priority)    <unused>
    .word end_of_test       ; Interrupt  1                      <unused>
    .word end_of_test       ; Interrupt  2                      <unused>
    .word end_of_test       ; Interrupt  3                      <unused>
    .word end_of_test       ; Interrupt  4                      <unused>
    .word end_of_test       ; Interrupt  5                      <unused>
    .word end_of_test       ; Interrupt  6                      <unused>
    .word end_of_test       ; Interrupt  7                      <unused>
    .word end_of_test       ; Interrupt  8                      <unused>
    .word end_of_test       ; Interrupt  9                      TEST IRQ
    .word end_of_test       ; Interrupt 10                      Watchdog timer
    .word end_of_test       ; Interrupt 11                      <unused>
    .word end_of_test       ; Interrupt 12                      <unused>
    .word VIOLATION_ISR     ; Interrupt 13                      SM_IRQ
    .word end_of_test       ; Interrupt 14                      NMI
    .word main              ; Interrupt 15 (highest priority)   RESET
.endm
