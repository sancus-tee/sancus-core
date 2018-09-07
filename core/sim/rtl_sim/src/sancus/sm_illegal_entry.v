/*===========================================================================*/
/*                 SANCUS MODULE ILLEGAL ENTRY (BRANCH OR IRQ-VECTOR)        */
/*---------------------------------------------------------------------------*/
/* Branch/vector to a non-entry SM address to attempt reading/writing        */
/* private memory before vectoring to violation ISR.                         */
/*                                                                           */
/* The instruction is still executed, but should be harmless:                */
/*  => r/w memory accesses by execution unit (including crypto unit) are     */
/*     masked in the memory backbone;                                        */
/*  => IRQ logic should not touch private memory of the victim SM;           */
/*  => other program-counter-based instructions (e.g. sancus_disable) should */
/*     _not_ be executed.                                                    */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

`define STACK_BASE      (16'h23e)
`define FOO_STACK_BASE  (16'h26a)
`define FOO_STACK_A     (mem268)
`define FOO_STACK_A_VAL (16'hcafe)
`define FOO_STACK_B     (mem266)
`define FOO_STACK_B_VAL (16'hbabe)
`define FOO_IRQ_SP      (mem26C)
`define FOO_PRIVATE_MEM (mem26A)
`define FOO_SECRET      (16'hbeef)
`define ATTACKER_VAL    (16'hdead)
`define FOO_ID          (16'h1)

`define AD              (mem202)
`define BODY            (mem204)
`define CIPHER          (mem206)
`define TAG             (mem208)
`define AD_VAL          (16'h1CEB)
`define BODY_VAL        (16'h00DA)

`define CHK_FOO_INIT \
      while(~sm_0_executing) @(posedge mclk); /* to avoid glitches only check at clock */ \
      if (sm_current_id!==`FOO_ID)          tb_error("====== SM foo ID (init) ======"); \      
      while(sm_0_executing) @(posedge mclk); \
      if (`FOO_PRIVATE_MEM!==`FOO_SECRET)   tb_error("====== foo private memory init ======"); \
      if (`FOO_IRQ_SP!==16'h0)              tb_error("====== foo IRQ sp-save memory init ======"); \
      if (`FOO_STACK_A!==`FOO_STACK_A_VAL)  tb_error("====== foo stack memory init ======"); \
      if (`FOO_STACK_B!==`FOO_STACK_B_VAL)  tb_error("====== foo stack memory init ======"); \
`ifdef SM_IRQ_EXEC_VIOLATION_TEST \
      @(r5==16'h1); \
      irq[9] <= 1; \
      @(posedge handling_irq); \
      irq[9] <= 0; \
`endif

`define FOO_EXEC_RAS      1'b0
`define IRQ_CALLER_ADDR   sm_0_public_start

`define CHK_ISR( str ) \
      if (r2!==`IRQ_SM_STATUS)         tb_error({"====== IRQ_STATUS (", str, ") ======"}); \
      if (r15!==`IRQ_CALLER_ADDR)   tb_error({"====== SM CALLER ADDR (", str, ") ======"});

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      
      $display("\n---- SM FOO INIT SECRET ----");
      `CHK_FOO_INIT
      
      $display("\n---- SM FOO READ GADGET EXEC VIOLATION ----");
      // check SM instruction
      while(~sm_0_executing) @(posedge mclk);
      repeat(1) @(posedge mclk);
      $display("Foo executing: %s", inst_full);
      if ( (sm_prev_id < 16'hfff0) & (r4!==`ATTACKER_VAL)) tb_error("====== r4 init (branch read gadget) ======"); // r4 was cleared by IRQ logic
      if (r1 > `STACK_BASE)                 tb_error("====== sp not unprotected (read gadget) ======");
      @(posedge handling_irq);
      if (r4!==16'h0)                       tb_error("====== read gadged attempt not masked ======");
      if (r4==`FOO_SECRET)                  tb_error("====== secret value leaked in r4 (read gadget) ======");
      // check IRQ
      @(negedge handling_irq);
      if (`FOO_IRQ_SP!==16'h0)              tb_error("====== exec violation should not write to victim SM irq sp (read gadget IRQ) ======");
      if (r4!==16'h0)                       tb_error("====== r4 not cleared (read gadget IRQ) ======");
      `CHK_ISR("read gadget")
      @(r15==16'h1000);
      if (r4==`FOO_SECRET)                  tb_error("====== secret value leaked to ISR via unprotected call stack ======");
      
      $display("\n---- SM FOO WRITE GADGET EXEC VIOLATION ----");
      `CHK_FOO_INIT
      // check SM instruction
      while(~sm_0_executing) @(posedge mclk);
      $display("Foo executing: %s", inst_full);
      // check IRQ
      @(negedge handling_irq);
      if (`FOO_IRQ_SP!==16'h0)              tb_error("====== exec violation should not write to victim SM irq sp (write gadget) ======");
      if (`FOO_STACK_A!==`FOO_STACK_A_VAL)  tb_error("====== exec violation should not write to victim SM stack (write gadget) ======");
      if (`FOO_STACK_B!==`FOO_STACK_B_VAL)  tb_error("====== exec violation should not write to victim SM stack (write gadget) ======");
      if (`FOO_PRIVATE_MEM==`ATTACKER_VAL)  tb_error("====== secret value overwritten (write gadget) ======");
      `CHK_ISR("write gadget")

      $display("\n---- SM FOO SANCUS_WRAP GADGET EXEC VIOLATION ----");
      `CHK_FOO_INIT
      // check SM instruction
      while(~sm_0_executing) @(posedge mclk);
      $display("Foo executing: %s", inst_full);
      if (`AD!==`AD_VAL)                    tb_error("====== AD INIT VALUE (sancus_wrap gadget) ======");
      if (`BODY!==`BODY_VAL)                tb_error("====== BODY INIT VALUE (sancus_wrap gadget) ======");
      if (`CIPHER!==16'h0)                  tb_error("====== CIPHER INIT VALUE (sancus_wrap gadget) ======");
      if (`TAG!==16'h0)                     tb_error("====== TAG INIT VALUE (sancus_wrap gadget) ======");
      //if (crypto_start)                     tb_error("====== CRYPTO START (sancus_wrap gadget) ======");
      // check IRQ
      @(negedge handling_irq);
      if (`FOO_IRQ_SP!==16'h0)              tb_error("====== exec violation should not write to victim SM irq sp (sancus_wrap gadget) ======");
      if (`CIPHER!==16'h0)                  tb_error("====== CIPHER VALUE after IRQ (sancus_wrap gadget) ======");
      if (`TAG!==16'h0)                     tb_error("====== TAG VALUE after IRQ (sancus_wrap gadget) ======");
      `CHK_ISR("sancus_wrap gadget")

      $display("\n---- SM FOO SANCUS_DISABLE GADGET EXEC VIOLATION ----");
      `CHK_FOO_INIT
      while(~sm_0_executing) @(posedge mclk);
      $display("Foo executing: %s", inst_full);
      // check IRQ
      @(negedge handling_irq);
      if (`FOO_IRQ_SP!==16'h0)              tb_error("====== exec violation should not write to victim SM irq sp (sancus_disable gadget) ======");
      if (~sm_0_enabled) begin
        tb_error("====== SM foo disabled (sancus_disable gadget) ======");
        // check ISR
        if (r15!==16'h0)                    tb_error("====== SM CALLER ADDR != 0x0 after sancus_disable ======");
        @(r15==16'h2000);
        if (r4==`FOO_SECRET)                tb_error("====== secret value leaked to ISR after sancus_disable ======");
      end
      else begin
        `CHK_ISR("sancus_disable gadget")
      end

      @(r15==16'h3000);
      stimulus_done = 1;
   end
