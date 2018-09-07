; GNU assembler syntax (https://sourceware.org/binutils/docs-2.26/as/)

; return callerID in r15
.macro sancus_get_caller_id
    .word 0x1387
.endm

; return ID of SM @r15 in r15
.macro sancus_get_id
    .word 0x1386
.endm

; set stack overflow guard address (0x0 to disable); clobbers r15
.macro sancus_stack_guard addr:req
    mov \addr, r15
    .word 0x1388
.endm

.macro sancus_enable vendor:req, ps:req, pe:req, ss:req, se:req
    clr r9
    clr r10
    mov \vendor, r11
    mov \ps, r12
    mov \pe, r13
    mov \ss, r14
    mov \se, r15
    .word 0x1381
.endm

.macro sancus_wrap
    .word 0x1384
.endm

.macro sancus_unwrap
    .word 0x1385
.endm

; TODO should take continuation argument
.macro sancus_disable cont:req
    mov \cont, r15
    .word 0x1380
.endm

; convienence macro to repeat an operation on a list of register operands
.macro repeat op regs:vararg
    .irp reg,\regs
        \op \reg
    .endr
.endm
.macro repeat_to op, src regs:vararg
    .irp reg,\regs
        \op \src, \reg
    .endr
.endm

; watchdog config
.set wdt_mdly_0_064, 0x5a1b
.set wdt_mdly_8, 0x5a19

; status register flags
.set sr_gie_flag, 0x0008

.macro do_reti addr:req
    push \addr
    ; status word with gie to terminate (early-out) ISR atomic section
    push #sr_gie_flag
    reti
.endm

.macro disable_wdt
    mov #0x5a80, &0x0120
.endm

.macro enable_wdt_irq
	bis.b #0x01, &IE1
.endm

.macro disable_wdt_irq
	bic.b #0x01, &IE1
.endm

; store current time stamp count in the 64bit memory ptr dest_addr
; note: write overhead is 29 cycles 4*6 (mov &ede,&ede) + 1*5 (mov #n, &ede)
.macro tsc_read dest_addr:req
    mov.b #1, &0x0190
    mov &0x0190, &\dest_addr
    mov &0x0192, &\dest_addr+2
    mov &0x0194, &\dest_addr+4
    mov &0x0196, &\dest_addr+6
.endm
