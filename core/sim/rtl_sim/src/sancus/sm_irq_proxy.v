/*===========================================================================*/
/*                 SANCUS MODULE INTERRUPT LOGIC                             */
/*---------------------------------------------------------------------------*/
/* Test interrupting/resuming a protected and unprotected Sancus module.     */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/
//`define LONG_TIMEOUT

reg [63:0] tsc_val1;
reg [63:0] tsc_val2;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");

`define LONG_TIMEOUT
      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      tsc_val1 <= 0;
      tsc_val2 <= 0;

      /* ----------------------  SM INITIALIZATION --------------- */
      $display("\n--- SM INIT ---");
      @(posedge sm_0_enabled);
      @(posedge sm_1_enabled);
      @(posedge sm_2_enabled);
      repeat(2) @(posedge mclk);
      @(posedge exec_done);

      /* ----------------------  SM IRQ --------------- */
      @(posedge sm_2_executing);
      $display("\n--- SM IRQ ---");
      $display("waiting for Timer_A IRQ...");
      @(posedge irq_ta1);
      tsc_val1 <= cur_tsc;

      /* ----------------------  OS ISR --------------- */
      $display("\n--- UNTRUSTED OS ---");
      $display("waiting for ISR...");
      @(r10==16'hdead);
      tsc_val2 <= cur_tsc;
      repeat(2) @(posedge mclk);
      $display("IRQ logic done: %d cycles", tsc_val2 - tsc_val1);

      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test...");
      @(r15==16'h2000);

      stimulus_done = 1;
   end
