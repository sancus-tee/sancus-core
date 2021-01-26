/*===========================================================================*/
/*                 INTERRUPTIBLE CRYPTO CORE                                 */
/*---------------------------------------------------------------------------*/
/* An IRQ while executing a crypto instruction should fail that instruction. */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

`define LONG_TIMEOUT
`define IRQ_TIMEOUT         16'd10
`define NB_IRQS             16'd2

`define AD_MEM              mem202
`define AD_VAL              16'hc0de
`define BODY_MEM            mem204
`define BODY_VAL            16'hbeef
`define CIPHER_MEM          mem206
`define TAG_MEM_0           mem208
`define TAG_MEM_1           mem20A
`define TAG_MEM_2           mem20C
`define TAG_MEM_3           mem20E

`define DUMP_WRAP \
    $display("ad=0x%h; body=0x%h; cipher=0x%h; tag=0x%h/0x%h/0x%h/0x%h", `AD_MEM, `BODY_MEM, `CIPHER_MEM, `TAG_MEM_0, `TAG_MEM_1, `TAG_MEM_2, `TAG_MEM_3);

`define CHK_WRAP(adVal, bodyVal, cipherVal, tag0, tag1, tag2, tag3) \
      if (`AD_MEM != adVal)         tb_error("====== AD VAL ======"); \
      if (`BODY_MEM != bodyVal)     tb_error("====== BODY VAL ======"); \
      if (`CIPHER_MEM != cipherVal) tb_error("====== CIPHER VAL ======"); \
      if (`TAG_MEM_0 != tag0)       tb_error("====== TAG 0 VAL ======"); \
      if (`TAG_MEM_1 != tag1)       tb_error("====== TAG 1 VAL ======"); \
      if (`TAG_MEM_2 != tag2)       tb_error("====== TAG 2 VAL ======"); \
      if (`TAG_MEM_3 != tag3)       tb_error("====== TAG 3 VAL ======");

`define CHK_RV(r15Val) \
    if (r2_z) tb_error("====== R2 ZERO FLAG SET ====="); \
    if (r15!=r15Val) tb_error("====== CRYPTO RETURN VALUE =====");

`define SEND_CRYPTO_IRQ( str, chk_irq, nb, timeout ) \
    $display({"\n--- IRQ: ", str, " %2d ---"}, nb); \
    @(posedge crypto_start); \
    $display("crypto started; sending interrupt in %2d cycles", timeout); \
    irq_cntdwn = timeout; \
    while(irq_cntdwn !== 16'd0) begin \
      irq_cntdwn = irq_cntdwn - 16'd1; \
      @(posedge mclk); \
    end \
    irq[9] = 1; \
    tsc_val1 = cur_tsc; \
    /*while(~handling_irq) @(posedge mclk); */\
    $display("crypto irq at 0x%h : \t%s", current_inst_pc, inst_full); \
    @(posedge handling_irq); \
    chk_irq \
    irq[9] = 0; \
    @(negedge handling_irq); \
    tsc_val2 = cur_tsc; \
    repeat(2) @(posedge mclk); \
    $display("In ISR with reti 0x%h; IRQ latency was %2d", r15, tsc_val2 - tsc_val1);

`define PASS_CRYPTO( str ) \
    $display({"\n--- PASS: ", str, " ---"}); \
    @(posedge crypto_start); \
    @(posedge exec_done); \
    $display("crypto passed at 0x%h : \t%s", current_inst_pc, inst_full); \
    if (r2_z)  tb_error("====== R2 ZERO FLAG SET ====="); \
    repeat(2) @(posedge mclk);

`define INTERRUPT_CRYPTO( str, chk_irq, chk_final ) \
    nb = `NB_IRQS; \
    while(nb !== 16'd0) begin \
        `SEND_CRYPTO_IRQ( str, chk_irq, nb, `IRQ_TIMEOUT ) \
        nb = nb - 16'd1; \
    end \
    `PASS_CRYPTO( str ) \
    chk_final

`define CHK_NOT_ENABLED( sm_en) \
    if (~r2_z) tb_error("====== R2 ZERO FLAG NOT SET ====="); \
    if (sm_en) tb_error("====== SM ENABLED TOO EARLY ====="); \
    if (r15!=0) tb_error("====== SANCUS_ENABLE RETURN VALUE =====");
    
`define CHK_ENABLED( sm_en, sm_id, sm_id_val ) \
    if (~sm_en)             tb_error("====== SM FINAL NOT ENABLED ====="); \
    if (r15!=sm_id)         tb_error("====== SANCUS_ENABLE FINAL RETURN VALUE ====="); \
    if (sm_id!=sm_id_val)   tb_error("====== SM FINAL ID VALUE =====");

reg [15:0] irq_cntdwn;
reg [15:0] nb;

reg [15:0] cipherVal;
reg [15:0] tagVal_0;
reg [15:0] tagVal_1;
reg [15:0] tagVal_2;
reg [15:0] tagVal_3;

reg [63:0] tsc_val1;
reg [63:0] tsc_val2;
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
      tsc_val1 <= 0;
      tsc_val2 <= 0;

      @(r4==16'h1000);
      `CHK_WRAP(`AD_VAL, `BODY_VAL, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0)
      `DUMP_WRAP
      
      `INTERRUPT_CRYPTO("UNPROTECTED ENABLE", `CHK_NOT_ENABLED(sm_0_enabled), `CHK_ENABLED(sm_0_enabled, sm_0_id, 1))

      `SEND_CRYPTO_IRQ( "CALLER ID" ,`CHK_RV(0), 0, 1)

      `INTERRUPT_CRYPTO("PROTECTED ENABLE", `CHK_NOT_ENABLED(sm_1_enabled), `CHK_ENABLED(sm_1_enabled, sm_1_id, 2))

      `SEND_CRYPTO_IRQ( "GET ID" ,`CHK_RV(2), 0, 1)

      `CHK_WRAP(`AD_VAL, `BODY_VAL, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0)
      `INTERRUPT_CRYPTO("SANCUS WRAP", `CHK_WRAP(`AD_VAL, `BODY_VAL, `CIPHER_MEM, `TAG_MEM_0, `TAG_MEM_1, `TAG_MEM_2, `TAG_MEM_3), )
      cipherVal = `CIPHER_MEM;
      tagVal_0 = `TAG_MEM_0;
      tagVal_1 = `TAG_MEM_1;
      tagVal_2 = `TAG_MEM_2;
      tagVal_3 = `TAG_MEM_3;
      @(r4==16'h1000);
      `DUMP_WRAP
      
      `INTERRUPT_CRYPTO("SANCUS UNWRAP",
        `CHK_WRAP(`AD_VAL, `BODY_MEM, cipherVal, tagVal_0, tagVal_1, tagVal_2, tagVal_3),
        `CHK_WRAP(`AD_VAL, `BODY_VAL, cipherVal, tagVal_0, tagVal_1, tagVal_2, tagVal_3))
      `DUMP_WRAP
      
      /* ----------------------  END OF TEST ---------------- */
      @(r4==16'h2000);
      stimulus_done = 1;
   end
