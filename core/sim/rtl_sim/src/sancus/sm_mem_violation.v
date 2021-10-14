/*===========================================================================*/
/*                 SANCUS MODULE MEMORY VIOLATION                            */
/*---------------------------------------------------------------------------*/
/* Test the violation IRQ by accessing secret SM memory from outside.        */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

`define LONG_TIMEOUT

`define STACK_BASE              (`PER_SIZE + 'h60)

`define BAR_SECRET              (mem220)
`define BAR_SECRET_VAL          (16'hf00d)
`define FOO_PUBLIC_VAL          (16'hcafe)
`define FOO_ENTRY_VAL           (16'h4303) // NOP

`define BAR_SSA_BASE            (mem23E)
`define BAR_SSA_BASE_ADDR       (16'h23E)
`define BAR_SSA_PT              (mem240)

`define CHK_VIOLATION_IRQ_SM( str, r15val, sm_pubstart) \
      $display({"\n--- ", str, " ---"}); \
      $display("waiting for handling IRQ..."); \
      @(posedge handling_irq); \
      saved_pc = r0-2; \
      saved_sr = r2; \
      if (~r2[14]) tb_error("====== SR MEM VIOLATION BIT NOT SET ======"); \
      `CHK_INIT_REGS_R15("before SM irq", `STACK_BASE, r15val) \
      @(negedge handling_irq); \
      `CHK_IRQ_REGS("after SM irq", 16'h0, sm_pubstart, `IRQ_SM_STATUS) \
      if (r2[14]) tb_error("====== SR MEM VIOLATION BIT NOT CLEARED ======"); \
 
`define CHK_VIOLATION_IRQ( str, r15val ) \
      `CHK_VIOLATION_IRQ_SM( str, r15val, sm_1_public_start); \
      `CHK_IRQ_SSA_R15("after SM irq", saved_pc, saved_sr, r15val, 1) \
      $display("waiting for foo re-entry..."); \
      while(~sm_1_executing) @(posedge mclk); \
      while(~inst_branch) @(posedge mclk); \
      @(exec_done); \
      repeat(2) @(posedge mclk);\
      while(~inst_branch) @(posedge mclk); \
      @(exec_done); \
      repeat(2) @(posedge mclk);\
      `CHK_INIT_REGS_R15("foo reti", `STACK_BASE, r15val)

reg [15:0] saved_pc;
reg [15:0] saved_sr;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");

`ifdef RESET_ON_VIOLATION
      $display(" ===============================================");
      $display("|               SIMULATION SKIPPED              |");
      $display("|     (Incompatible with RESET_ON_VIOLATION)    |");
      $display(" ===============================================");
      $finish;
`endif

      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      saved_pc <= 0;
      saved_sr <= 0;
      
      /* ----------------------  INITIALIZATION --------------- */

      $display("waiting for bar entry...");
      while(~sm_0_executing) @(posedge mclk);
      @(`BAR_SECRET);
      if (`BAR_SECRET !== `BAR_SECRET_VAL) tb_error("====== BAR SECRET INIT ======");
      
      $display("waiting for foo entry...");
      while(~sm_1_executing) @(posedge mclk);
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

      `ifdef ATOMICITY_MONITOR
        if (`BAR_SSA_PT !== `BAR_SSA_BASE_ADDR)   tb_error("====== BAR SSA_PT INIT ======");
        if (`BAR_SSA_BASE !== 16'h0)              tb_error("====== BAR SSA INIT ======");
        `CHK_VIOLATION_IRQ_SM("ATOM VIOLATION (CLIX)", 16'hdead, sm_0_public_start);
        if (`BAR_SECRET !== `BAR_SECRET_VAL)      tb_error("====== BAR SECRET AFTER ATOM IRQ ======");
        if (`BAR_SSA_PT !== `BAR_SSA_BASE_ADDR)   tb_error("====== BAR SSA_PT AFTER ATOM IRQ ======");
        if (`BAR_SSA_BASE !== 16'h0)              tb_error("====== BAR SSA AFTER ATOM IRQ ======");
      `endif
      
      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test...");
      @(r15==16'h2000);

      stimulus_done = 1;
   end
