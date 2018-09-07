/*===========================================================================*/
/*                 SANCUS MODULE MEMORY VIOLATION                            */
/*---------------------------------------------------------------------------*/
/* Test the violation IRQ by accessing secret SM memory from outside.        */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

`define LONG_TIMEOUT

`define STACK_BASE              (`PER_SIZE + 'h60)
`define STACK_IRQ               (`STACK_BASE - 16'd28)
`define STACK_IRQ_INTERRUPTED   (`STACK_IRQ | 16'h1)
`define STACK_RETI              (`STACK_BASE - 16'd4)

`define FOO_SP_SAVE             (mem264)
`define BAR_SECRET              (mem268)
`define BAR_SECRET_VAL          (16'hf00d)
`define FOO_PUBLIC_VAL          (16'hcafe)
`define FOO_ENTRY_VAL           (16'h4303) // NOP

`define CHK_VIOLATION_IRQ( str, r15val ) \
      $display({"\n--- ", str, " ---"}); \
      $display("waiting for handling IRQ..."); \
      @(posedge handling_irq); \
      saved_pc = r0-2; \
      saved_sr = r2; \
      /*if (~saved_sr[9]) tb_error("====== SR MEM VIOLATION BIT NOT SET ======");*/ \
      `CHK_INIT_REGS_R15("before SM irq", `STACK_BASE, r15val) \
      if (`FOO_SP_SAVE!==16'h0) tb_error("====== SP_SAVE before SM irq != 0x0 ======"); \
      @(negedge handling_irq); \
      `CHK_IRQ_REGS("after SM irq", 16'h0, sm_0_public_start, `IRQ_SM_STATUS) \
      `CHK_IRQ_STACK_R15("after SM irq", saved_pc, saved_sr, r15val) \
      if (`FOO_SP_SAVE!==`STACK_IRQ_INTERRUPTED) tb_error("====== SM IRQ SP WRITE VAL ======"); \
      $display("waiting for foo re-entry..."); \
      while(~sm_0_executing) @(posedge mclk); \
      @(inst_so[`RETI]); \
      @(exec_done); \
      `CHK_INIT_REGS_R15("foo reti", `STACK_BASE, r15val)

reg [15:0] saved_pc;
reg [15:0] saved_sr;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      saved_pc <= 0;
      saved_sr <= 0;
      
      /* ----------------------  INITIALIZATION --------------- */

      $display("waiting for bar entry...");
      while(~sm_1_executing) @(posedge mclk);
      @(`BAR_SECRET);
      if (`BAR_SECRET !== `BAR_SECRET_VAL) tb_error("====== BAR SECRET INIT ======");
      
      $display("waiting for foo entry...");
      while(~sm_0_executing) @(posedge mclk);
      @(r15);
      `CHK_INIT_REGS("foo init", `STACK_BASE)

      /* ----------------------  MEMORY VIOLATIONS --------------- */

      `CHK_VIOLATION_IRQ("SECRET DATA WRITE", `R15_VAL)
      if (`BAR_SECRET !== `BAR_SECRET_VAL) tb_error("====== BAR SECRET AFTER DATA WRITE IRQ ======");

      `CHK_VIOLATION_IRQ("SECRET DATA READ", 16'h0)
      if (`BAR_SECRET !== `BAR_SECRET_VAL) tb_error("====== BAR SECRET AFTER DATA READ IRQ ======");
      
      `CHK_VIOLATION_IRQ("TEXT WRITE", `R15_VAL)
      @(r15);
      if (r15 !== `FOO_PUBLIC_VAL) tb_error("====== FOO PUBLIC AFTER TEXT WRITE IRQ ======");
      
      `CHK_VIOLATION_IRQ("ENTRY POINT WRITE", `R15_VAL)
      @(r15);
      if (r15 !== `FOO_ENTRY_VAL)  tb_error("====== FOO ENTRY POINT AFTER TEXT WRITE IRQ ======");
      
      `CHK_VIOLATION_IRQ("TEXT READ", 16'h0)
      
      `CHK_VIOLATION_IRQ("ENTRY POINT READ", 16'h0)
      
      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test...");
      @(r15==16'h2000);
      if (r1!==`STACK_BASE)         tb_error("====== FINAL SP VALUE =====");

      stimulus_done = 1;
   end
