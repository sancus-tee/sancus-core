/*===========================================================================*/
/*                 STACK OVERRUN GUARD ADDRESS                               */
/*---------------------------------------------------------------------------*/
/* Test stack overrun detection for push/call instructions in all possible   */
/* addressing modes.                                                         */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

`define STACK_BASE (`PER_SIZE + 'h60)
`define STACK_SIZE ('d6)
`define STACK_TOP  (`STACK_BASE - `STACK_SIZE)
`define CANARY_A   (16'hbeef)
`define CANARY_B   (16'hc0de)
`define TST_MEM    (mem200)
`define TST_VAL    (16'hbabe)

`define IRQ_STATUS_OVF 16'h0 // stack overrun during IRQ logic

`define CHK_OVERRUN(AS) \
      $display({"testing ", AS, " ..."}); \
      @(irq_detect); \
      if (mem258 !==`CANARY_A)              tb_error({"====== ", AS, ": CANARY (@0x258 before irq) ====="}); \
      if (mem256 !==`CANARY_B)              tb_error({"====== ", AS, ": CANARY (@0x256 before irq) ====="}); \
      @(negedge handling_irq); \
      if (mem258 !==`CANARY_A)              tb_error({"====== ", AS, ": CANARY (@0x258 after irq) ====="}); \
      if (mem256 !==`CANARY_B)              tb_error({"====== ", AS, ": CANARY (@0x256 after irq) ====="}); \
      @(`TST_MEM);  \
      if(`TST_MEM!==`TST_VAL)               tb_error("====== ISR INSTR TWO EXT WORDS ======"); \
      @(r15==16'h5000); \
      if (r1 !==`STACK_TOP)                 tb_error({"====== ", AS, ": SP RE-INIT ====="}); \
      if (stack_guard !==(`STACK_TOP))      tb_error("====== Stack Guard re-initialization =====");

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      // initialisation
      @(r15==16'h1000);
      $display("testing stack init...");
      if (r1     !==(`STACK_BASE))          tb_error("====== SP initialization (R1 value) =====");
      if (stack_guard !==(`STACK_TOP))      tb_error("====== Stack Guard initialization =====");
      if (mem25E !==16'h0000)               tb_error("====== RAM Initialization (@0x025E value) =====");
      if (mem25C !==16'h0000)               tb_error("====== RAM Initialization (@0x025C value) =====");
      if (mem25A !==16'h0000)               tb_error("====== RAM Initialization (@0x025A value) =====");
      if (mem258 !==`CANARY_A)              tb_error("====== RAM Initialization (@0x248 canary) =====");
      if (mem256 !==`CANARY_B)              tb_error("====== RAM Initialization (@0x246 canary) =====");

      // push until stack full
      @( r15==16'h2000);
      $display("testing valid stack pushes...");
      if ((r1!==`STACK_BASE-2) | (mem25E!==16'h0121)) tb_error("====== PUSH (@0x025E value) =====");
      @( r15==16'h3000);
      if ((r1!==`STACK_BASE-4) | (mem25C!==16'h0122)) tb_error("====== PUSH (@0x025C value) =====");
      @(r15==16'h4000);      
      if ((r1!==`STACK_TOP) | (mem25A!==16'h0123)) tb_error("====== PUSH (@0x025A value) =====");
      
      $display("\n--- PUSH OVERRUN IN WORD MODE ---");
      `CHK_OVERRUN("push Rn")
      `CHK_OVERRUN("push @Rn")
      `CHK_OVERRUN("push @Rn+")
      `CHK_OVERRUN("push X(Rn)")
      `CHK_OVERRUN("push cst")
      `CHK_OVERRUN("push #N")
      `CHK_OVERRUN("push &EDE")
      
      $display("\n--- PUSH OVERRUN IN BYTE MODE ---");
      `CHK_OVERRUN("push.b Rn")
      `CHK_OVERRUN("push.b @Rn")
      `CHK_OVERRUN("push.b @Rn+")
      `CHK_OVERRUN("push.b X(Rn)")
      `CHK_OVERRUN("push.b cst")
      `CHK_OVERRUN("push.b #N")
      `CHK_OVERRUN("push.b &EDE")
      
      $display("\n--- MOV R1 OVERRUN ---");
      `CHK_OVERRUN("mov Rn, r1")
      `CHK_OVERRUN("mov @Rn, r1")
      `CHK_OVERRUN("mov @Rn+, r1")
      `CHK_OVERRUN("mov X(Rn), r1")
      `CHK_OVERRUN("mov #N, r1")
      `CHK_OVERRUN("mov &EDE, r1")
            
      $display("\n--- CALL OVERRUN ---");
      `CHK_OVERRUN("call Rn")
      `CHK_OVERRUN("call @Rn")
      `CHK_OVERRUN("call @Rn+")
      `CHK_OVERRUN("call X(Rn)")
      `CHK_OVERRUN("call #N")
      `CHK_OVERRUN("call &EDE")

      $display("\n--- STACK POINTER CLEAR ---");
      $display("testing clr r1 ...");
      @(r1 == 16'h0);
      if (stack_guard !==16'h0)      tb_error("====== Stack Guard not cleared =====");
      
      stimulus_done = 1;
   end
