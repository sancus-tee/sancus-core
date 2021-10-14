/*===========================================================================*/
/*                 SANCUS MODULE INTERRUPT LAST INSTRUCTION                  */
/*---------------------------------------------------------------------------*/
/* Edge case test when interrupting the last instruction of an SM's code     */
/* section; subject of memory access control should be the interrupted SM,   */
/* and PC saved by IRQ logic should be frontend_0.pc at interrupt.           */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

//`define LONG_TIMEOUT
`define FOO_SSA_PC      (mem26A)

reg [15:0] saved_pc;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      saved_pc <= 0;

      /* ----------------------  INIT --------------- */
      @(r15==16'h1000);

      /* ----------------------  INTERRUPT FOO --------------- */
      @(r15==16'h3000);
      @(posedge mclk);
      irq[9] <= 1;
      @(irq_detect);
      $display("interrupting after instruction %s", inst_full);
      if (~sm_1_executing)              tb_error("====== SM foo not interrupted ======");
      
      $display("waiting for handling IRQ...");
      @(posedge handling_irq);
      irq[9] <= 0;
      if (`FOO_SSA_PC !==16'h0)         tb_error("====== SSA MEMORY PC (before irq) ======");
      saved_pc <= r0-2;
      
      @(negedge handling_irq);
      if (r15!==sm_1_public_start)      tb_error("====== SM CALLER ADDR != SM_FOO_ENTRY ======");
      if (`FOO_SSA_PC!==saved_pc)       tb_error("====== SSA MEMORY PC (after irq) ======");

      /* ----------------------  RETI via foo to bar --------------- */
      $display("waiting for foo reti to bar...");
      while(~sm_1_executing) @(posedge mclk);
      while(~sm_0_executing) @(posedge mclk);
      @(r15==16'h4000);

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);
      stimulus_done = 1;
   end
