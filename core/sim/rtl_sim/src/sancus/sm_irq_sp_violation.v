/*===========================================================================*/
/*                 SM IRQ SP/MEM VIOLATION                                   */
/*---------------------------------------------------------------------------*/
/* Test forced stack overrun/memory access violations for all 14 pushes by   */
/* IRQ logic.                                                                */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/
`define LONG_TIMEOUT // VERY_LONG_TIMEOUT // NO_TIMEOUT

`define STACK_BASE              (`PER_SIZE + 'h60)
`define STACK_IRQ               (`STACK_BASE - 16'd28)
`define STACK_IRQ_INTERRUPTED   (`STACK_IRQ | 16'h1)

`define SM_ID       (16'h1)
`define SM_SP_SAVE  (mem26A)
`define TST_MEM     (mem200)
`define TST_VAL     (16'hbabe)

`define TRUE        (1'b1)
`define FALSE       (1'b0)

`define CHK_STACK( str,r0v,r2v,r4v,r5v,r6v,r7v,r8v,r9v,r10v,r11v,r12v,r13v,r14v,r15v ) \
      /*$display({"checking stack memory ", str});*/ \
      if (mem260 !==16'h0)     tb_error({"====== STACK MEMORY 0x260 (", str, ") ====="}); \         
      if (mem25E !==r0v)       tb_error({"====== STACK MEMORY PC (", str, ") ====="}); \
      if (mem25C !==r2v)       tb_error({"====== STACK MEMORY SR (", str, ") ====="}); \
      if (mem25A !==r15v)      tb_error({"====== STACK MEMORY r15 (", str, ") ====="}); \
      if (mem258 !==r14v)      tb_error({"====== STACK MEMORY r14 (", str, ") ====="}); \
      if (mem256 !==r13v)      tb_error({"====== STACK MEMORY r13 (", str, ") ====="}); \
      if (mem254 !==r12v)      tb_error({"====== STACK MEMORY r12 (", str, ") ====="}); \
      if (mem252 !==r11v)      tb_error({"====== STACK MEMORY r11 (", str, ") ====="}); \
      if (mem250 !==r10v)      tb_error({"====== STACK MEMORY r10 (", str, ") ====="}); \
      if (mem24E !==r9v)       tb_error({"====== STACK MEMORY r9 (", str, ") ====="}); \
      if (mem24C !==r8v)       tb_error({"====== STACK MEMORY r8 (", str, ") ====="}); \
      if (mem24A !==r7v)       tb_error({"====== STACK MEMORY r7 (", str, ") ====="}); \
      if (mem248 !==r6v)       tb_error({"====== STACK MEMORY r6 (", str, ") ====="}); \
      if (mem246 !==r5v)       tb_error({"====== STACK MEMORY r5 (", str, ") ====="}); \
      if (mem244 !==r4v)       tb_error({"====== STACK MEMORY r4 (", str, ") ====="}); \
      if (mem242 !==16'h0)     tb_error({"====== STACK MEMORY 0x242 (", str, ") ====="});

`define CHK_CLR_STACK( str ) \
     `CHK_STACK( str,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)

`define CHK_INT( str,protected,irq_status,sp_val,r0v,r2v,r4v,r5v,r6v,r7v,r8v,r9v,r10v,r11v,r12v,r13v,r14v,r15v) \
      $display({"\ntesting ", str, " ..."}); \
      /* 1/ send interrupt */ \
      @(r15==`R15_VAL); \
      repeat(10) @(posedge mclk); \
      $display("sending interrupt..."); \
      irq[9] <= 1; \
      $display("waiting for handling IRQ..."); \
      @(posedge handling_irq); \
      irq[9] <= 0; \
      saved_pc <= r0-2; \
      saved_sr <= r2; \
      /* 2/ test initialization before IRQ handling */ \
      `CHK_INIT_REGS("before SM irq", `STACK_BASE) \
      `CHK_CLR_STACK("before SM irq") \
      if (`SM_SP_SAVE!==16'h0)      tb_error("====== SP_SAVE before SM irq != 0x0 ======"); \
      /* 3/ test IRQ logic */ \
      @(negedge handling_irq); \
      if(protected) begin \
        if (!sm_0_enabled)          tb_error("====== SM NOT ENABLED ======"); \
       `CHK_IRQ_REGS("after SM irq", 16'h0, sm_0_public_start, irq_status) \
        if (`SM_SP_SAVE!==sp_val)   tb_error("====== SM IRQ SP WRITE VAL ======"); \
        `CHK_STACK("after SM irq",r0v,r2v,r4v,r5v,r6v,r7v,r8v,r9v,r10v,r11v,r12v,r13v,r14v,r15v) \
      end \
      else begin \
        `ifdef UNPROTECTED_IRQ_REG_PUSH \
            `CHK_STACK("after unprotected irq",r0v,r2v,r4v,r5v,r6v,r7v,r8v,r9v,r10v,r11v,r12v,r13v,r14v,r15v) \
        `endif \
        if (`SM_SP_SAVE!==16'h0)    tb_error("====== UNPROTECTED IRQ SP WRITE ======"); \
      end \
      /* 4/ test ISR */ \
      @(`TST_MEM); \
      if(`TST_MEM!==`TST_VAL)       tb_error("====== ISR INSTR TWO EXT WORDS ======"); \
      @(r15);

reg [15:0] saved_pc;
reg [15:0] saved_sr;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");

`ifndef UNPROTECTED_IRQ_REG_PUSH
`define UNPROTECTED_IRQ_REG_PUSH
`endif

      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      saved_pc <= 0;
      saved_sr <= 0;

      /* ----------------------  UNPROTECTED SM INTERRUPT --------------- */
      // sp value after violation in IRQ logic is undefined; does not matter (?)
      $display("\n--- UNPROTECTED INTERRUPT ---");
      `CHK_INT("PC VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)
      `CHK_INT("SR VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)
      `CHK_INT("R15 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)
      `CHK_INT("R14 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R15_VAL)
      `CHK_INT("R13 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R14_VAL,`R15_VAL)
      `CHK_INT("R12 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R11 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R10 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R9 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R8 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R7 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R6 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,16'h0,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R5 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,16'h0,`R6_VAL,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R4 VIOLATION", `FALSE,`IRQ_UNPR_STATUS,r1,saved_pc,saved_sr,16'h0,`R5_VAL,`R6_VAL,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("NO VIOLATION", `FALSE,`IRQ_UNPR_STATUS,`STACK_IRQ,saved_pc,saved_sr,`R4_VAL,`R5_VAL,`R6_VAL,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)

      /* ----------------------  PROTECTED SM INTERRUPT --------------- */
      $display("\n--- SM INTERRUPT ---");
      $display("waiting for SM switch...");
      @(sm_0_executing);
      
      `CHK_INT("PC VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)
      `CHK_INT("SR VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)
      `CHK_INT("R15 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0)
      `CHK_INT("R14 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R15_VAL)
      `CHK_INT("R13 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R14_VAL,`R15_VAL)
      `CHK_INT("R12 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R11 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R10 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R9 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R8 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,16'h0,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R7 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,16'h0,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R6 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,16'h0,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R5 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,16'h0,`R6_VAL,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("R4 VIOLATION", `TRUE,`IRQ_SM_STATUS,16'h0,saved_pc,saved_sr,16'h0,`R5_VAL,`R6_VAL,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)
      `CHK_INT("NO VIOLATION", `TRUE,`IRQ_SM_STATUS,`STACK_IRQ_INTERRUPTED,saved_pc,saved_sr,`R4_VAL,`R5_VAL,`R6_VAL,`R7_VAL,`R8_VAL,`R9_VAL,`R10_VAL,`R11_VAL,`R12_VAL,`R13_VAL,`R14_VAL,`R15_VAL)

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);
      if (r1!==`STACK_BASE)         tb_error("====== FINAL SP VALUE =====");

      stimulus_done = 1;
   end
