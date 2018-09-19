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

`define STACK_BASE      (`PER_SIZE + 'h60)
`define STACK_IRQ       (`STACK_BASE - 16'd28)
`define STACK_IRQ_INTERRUPTED (`STACK_IRQ | 16'h1)

`define FOO_SP_SAVE     (mem264)
`define BAR_SP_SAVE     (mem26A)

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
      if (r1!==`STACK_BASE) tb_error("====== SP INIT ======");

      /* ----------------------  INTERRUPT FOO --------------- */
      @(r15==16'h3000);
      @(posedge mclk);
      irq[9] <= 1;
      @(irq_detect);
      $display("interrupting after instruction %s", inst_full);
      if (~sm_0_executing)              tb_error("====== SM foo not interrupted ======");
      
      $display("waiting for handling IRQ...");
      @(posedge handling_irq);
      irq[9] <= 0;
      if (mem25E!==16'h0)               tb_error("====== STACK MEMORY PC (before irq) ======");
      if (`FOO_SP_SAVE!==16'h0)         tb_error("====== SM IRQ FOO SP_SAVE (before irq) ======");
      if (`BAR_SP_SAVE!==16'h0)         tb_error("====== SM IRQ BAR SP_SAVE (before irq) ======");
      saved_pc <= r0-2;
      
      @(negedge handling_irq);
      if (r15!==sm_0_public_start)      tb_error("====== SM CALLER ADDR != SM_FOO_ENTRY ======");
      if (mem25E!==saved_pc)            tb_error("====== STACK MEMORY PC (after irq) ======");
      if (`FOO_SP_SAVE!==`STACK_IRQ_INTERRUPTED)    tb_error("====== SM IRQ FOO SP_SAVE (after irq) ======");
      if (`BAR_SP_SAVE!==16'h0)         tb_error("====== SM IRQ BAR SP_SAVE (after irq) ======");

      /* ----------------------  RETI via foo to bar --------------- */
      $display("waiting for foo reti to bar...");
      while(~sm_0_executing) @(posedge mclk);
      @(inst_so[`RETI]);
      @(exec_done);
      repeat(2) @(negedge mclk);
      if (~sm_1_executing)              tb_error("====== reti did not return to SM bar ======");
      @(r15==16'h4000);

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);
      stimulus_done = 1;
   end
