/*===========================================================================*/
/*                 REGISTER INDIRECT AUTOINCREMENT IRQ                       */
/*---------------------------------------------------------------------------*/
/* Test scenario to ensure the IRQ logic does not increment any registers    */
/* when interrupting _before_ an instruction with register-indirect          */
/* autoincrement addressing mode.                                            */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/
`define STACK_BASE (`PER_SIZE + 'h60)
`define TST_MEM     (mem200)
`define TST_VAL     (16'hbabe)

`define CHECK_REGISTERS( str, R14_VAL, SP_VAL ) \
      $display("checking register values: %s...", str); \
      if (r15!== 16'h0)         tb_error({"====== R15 (", str, ") ====="}); \
      if (r14!== R14_VAL)       tb_error({"====== R14 (", str, ") ====="}); \
      if (r13!== 16'h0)         tb_error({"====== R13 (", str, ") ====="}); \
      if (r12!== 16'h0)         tb_error({"====== R12 (", str, ") ====="}); \
      if (r11!== 16'h0)         tb_error({"====== R11 (", str, ") ====="}); \
      if (r10!== 16'h0)         tb_error({"====== R10 (", str, ") ====="}); \
      if (r9 !== 16'h0)         tb_error({"====== R9 (", str, ") ====="}); \
      if (r8 !== 16'h0)         tb_error({"====== R8 (", str, ") ====="}); \
      if (r7 !== 16'h0)         tb_error({"====== R7 (", str, ") ====="}); \
      if (r6 !== 16'h0)         tb_error({"====== R6 (", str, ") ====="}); \
      if (r5 !== 16'h0)         tb_error({"====== R5 (", str, ") ====="}); \
      if (r4 !== 16'h0)         tb_error({"====== R4 (", str, ") ====="}); \
      if (r1 !== SP_VAL)        tb_error({"====== SP (", str, ") ====="});
      
initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");

`ifndef UNPROTECTED_IRQ_REG_PUSH
      $display(" ===============================================");
      $display("|               SIMULATION SKIPPED              |");
      $display("|  (Requires unprotected IRQ register pushing)  |");
      $display(" ===============================================");
      $finish;
`endif

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      // send an interrupt after the first pop instruction
      @(r14==16'h3);
      $display("Sending interrupt...");
      irq[9] <= 1;

      $display("Waiting for handling IRQ...");
      @(irq_detect);
      $display("interrupted after instruction %s", inst_full);
      @(handling_irq);
      if (~dut.frontend_0.inst_as_nxt[`INDIR_I]) tb_error("inst_as_nxt[`INDIR_I] not set");
      irq[9] <= 0;
      `CHECK_REGISTERS("start of IRQ logic", 16'h2, `STACK_BASE-2)


      $display("Waiting for ISR...");
      @(`TST_MEM);
      if(`TST_MEM!==`TST_VAL)   tb_error("====== ISR INSTR TWO EXT WORDS ======");
      @(r15==16'hffff);
      @(r15==16'h0);
      `CHECK_REGISTERS("ISR pop", 16'h2, `STACK_BASE-6)

      $display("Waiting for completion...");
      @(r15==16'h2000);
      @(r15==16'h0);
      `CHECK_REGISTERS("completion", 16'h1, `STACK_BASE)
      
      stimulus_done = 1;
   end
