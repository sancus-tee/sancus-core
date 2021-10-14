/*===========================================================================*/
/*                 SANCUS MODULE EINT ENTRY                                  */
/*---------------------------------------------------------------------------*/
/* Test entering a Sancus module with interrupts enabled (SM should be able  */
/* to restore its internal private call stack before handling interrupts).   */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/
//`define LONG_TIMEOUT

`define TST_MEM                 (mem242)
`define TST_VAL                 (16'hbabe)

reg [15:0] saved_pc;
reg [15:0] saved_sr;

reg [63:0] tsc_val1;
reg [63:0] tsc_val2;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");

      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      saved_pc <= 0;
      saved_sr <= 0;
      tsc_val1 <= 0;
      tsc_val2 <= 0;

      /* ----------------------  SM INITIALIZATION --------------- */
      $display("\n--- SM INIT ---");
      @(posedge crypto_start);
      tsc_val1 <= cur_tsc;
      @(posedge exec_done);
      tsc_val2 <= cur_tsc;
      repeat(2) @(posedge mclk);
      $display("SM enabled: %d crypto cycles", tsc_val2 - tsc_val1);
      if (!sm_0_enabled)                    tb_error("====== SM NOT ENABLED ======");

      @(posedge crypto_start);
      tsc_val1 <= cur_tsc;
      @(posedge exec_done);
      tsc_val2 <= cur_tsc;
      repeat(2) @(posedge mclk);
      $display("SM enabled: %d crypto cycles", tsc_val2 - tsc_val1);
      if (!sm_1_enabled)                    tb_error("====== SM NOT ENABLED ======");

      /* ----------------------  PROTECTED SM INTERRUPT --------------- */
      $display("\n--- SM ENTRY AND INTERRUPT ---");

      @(posedge sm_1_executing);
      if(`TST_MEM !== 16'h0)        tb_error("====== TST_MEM init ======");
      $display("sending interrupt...");
      irq[9] <= 1;
      
      $display("waiting for handling IRQ...");
      @(posedge handling_irq);
      tsc_val1 <= cur_tsc;
      irq[9] <= 0;
      
      @(negedge handling_irq);
      tsc_val2 <= cur_tsc;
      repeat(2) @(posedge mclk);
      $display("IRQ logic done: %d cycles", tsc_val2 - tsc_val1);
      if(`TST_MEM !== 16'h0)       tb_error("====== SM IRQ served too early (TST_MEM clobbered) ======");
      if(`TST_MEM==`TST_VAL)       tb_error("====== PoC arbitrary in-enclave write ======");

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);

      stimulus_done = 1;
   end
