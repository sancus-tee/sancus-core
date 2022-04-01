; GNU assembler syntax (https://sourceware.org/binutils/docs-2.26/as/)

; watchdog register
.set WDTCTL, 0x120

; TIMER_A registers
.set TACTL, 0x160
.set TACCTL0, 0x162
.set TAR, 0x170
.set TACCR0, 0x172

.set TACTL_DISABLE, 0x04
.set TACTL_ENABLE, 0x212
.set TACCTL_DISABLE, 0x0

; return callerID in r15
.macro sancus_get_caller_id
    .word 0x1387
    jz . /* should never fail */
.endm

; return ID of SM @r15 in r15
.macro sancus_get_id
    .word 0x1386
    jz . /* should never fail */
.endm

; set stack overflow guard address (0x0 to disable); clobbers r15
.macro sancus_stack_guard addr:req
    mov \addr, r15
    .word 0x1388
.endm

; set up clix length and call clix; clobbers r15
.macro clix clix_len:req
    mov \clix_len, r15
    .word 0x1389
.endm

.macro sancus_enable vendor:req, ps:req, pe:req, ss:req, se:req
    clr r9
    clr r10
    mov \vendor, r11
    mov \ps, r12
    mov \pe, r13
    mov \ss, r14
1\@:
    mov \se, r15
    .word 0x1381
    jz 1\@b /* restart on IRQ */
.endm

.macro sancus_wrap key:req, ad:req, ad_end:req, body:req, body_end:req, cipher:req, tag:req
    mov \key, r9
    mov \ad, r10
    mov \ad_end, r11
    mov \body, r12
    mov \body_end, r13
    mov \cipher, r14
1\@:
    mov \tag, r15
    .word 0x1384
    jz 1\@b /* restart on IRQ */
.endm

.macro sancus_unwrap key:req, ad:req, ad_end:req, cipher:req, cipher_end:req, body:req, tag:req
    mov \key, r9
    mov \ad, r10
    mov \ad_end, r11
    mov \cipher, r12
    mov \cipher_end, r13
    mov \body, r14
1\@:
    mov \tag, r15
    .word 0x1385
    jz 1\@b /* restart on IRQ */
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
    mov #0x5a80, &WDTCTL
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
    mov.b #1, &0x0100
    mov &0x0100, &\dest_addr
    mov &0x0102, &\dest_addr+2
    mov &0x0104, &\dest_addr+4
    mov &0x0106, &\dest_addr+6
.endm

.macro putchar char:req
    mov \char, &0x0084
    mov #'\n', &0x0084
.endm

