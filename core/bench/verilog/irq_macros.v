
`define REG_OFFSET    (16'h1234)
`define R4_VAL      (`REG_OFFSET + 16'h4)
`define R5_VAL      (`REG_OFFSET + 16'h5)
`define R6_VAL      (`REG_OFFSET + 16'h6)
`define R7_VAL      (`REG_OFFSET + 16'h7)
`define R8_VAL      (`REG_OFFSET + 16'h8)
`define R9_VAL      (`REG_OFFSET + 16'h9)
`define R10_VAL     (`REG_OFFSET + 16'ha)
`define R11_VAL     (`REG_OFFSET + 16'hb)
`define R12_VAL     (`REG_OFFSET + 16'hc)
`define R13_VAL     (`REG_OFFSET + 16'hd)
`define R14_VAL     (`REG_OFFSET + 16'he)
`define R15_VAL     (`REG_OFFSET + 16'hf)

`define IRQ_SM_STATUS           16'h0000
`define IRQ_UNPR_STATUS         16'h0000

`define CHK_INIT_REGS_R15(str, sp_val, r15Val) \
      /*$display({"checking registers ", str});*/ \
      if (r15 !==r15Val)    tb_error({"====== r15 value (", str, ") ====="}); \
      if (r14 !==`R14_VAL)  tb_error({"====== r14 value (", str, ") ====="}); \
      if (r13 !==`R13_VAL)  tb_error({"====== r13 value (", str, ") ====="}); \
      if (r12 !==`R12_VAL)  tb_error({"====== r12 value (", str, ") ====="}); \
      if (r11 !==`R11_VAL)  tb_error({"====== r11 value (", str, ") ====="}); \
      if (r10 !==`R10_VAL)  tb_error({"====== r10 value (", str, ") ====="}); \
      if (r9  !==`R9_VAL)   tb_error({"====== r9 value (", str, ") ====="});  \
      if (r8  !==`R8_VAL)   tb_error({"====== r8 value (", str, ") ====="});  \
      if (r7  !==`R7_VAL)   tb_error({"====== r7 value (", str, ") ====="});  \
      if (r6  !==`R6_VAL)   tb_error({"====== r6 value (", str, ") ====="});  \
      if (r5  !==`R5_VAL)   tb_error({"====== r5 value (", str, ") ====="});  \
      if (r4  !==`R4_VAL)   tb_error({"====== r4 value (", str, ") ====="});  \
      if (r1  !==sp_val)    tb_error({"====== sp value (", str, ") ====="});

`define CHK_INIT_REGS( str, sp_val ) \
    `CHK_INIT_REGS_R15(str, sp_val, `R15_VAL)

`define CHK_IRQ_REGS_SP( str, spVal, retiAddr, irqStatus, chkSp ) \
      /*$display({"checking IRQ registers ", str});*/ \
      if (r15 !==retiAddr)  tb_error({"====== r15 IRQ reti address (", str, ") ====="}); \
      if (r14 !==16'h0)     tb_error({"====== r14 IRQ clear (", str, ") ====="}); \
      if (r13 !==16'h0)     tb_error({"====== r13 IRQ clear (", str, ") ====="}); \
      if (r12 !==16'h0)     tb_error({"====== r12 IRQ clear (", str, ") ====="}); \
      if (r11 !==16'h0)     tb_error({"====== r11 IRQ clear (", str, ") ====="}); \
      if (r10 !==16'h0)     tb_error({"====== r10 IRQ clear (", str, ") ====="}); \
      if (r9  !==16'h0)     tb_error({"====== r9 IRQ clear (", str, ") ====="}); \
      if (r8  !==16'h0)     tb_error({"====== r8 IRQ clear (", str, ") ====="}); \
      if (r7  !==16'h0)     tb_error({"====== r7 IRQ clear (", str, ") ====="}); \
      if (r6  !==16'h0)     tb_error({"====== r6 IRQ clear (", str, ") ====="}); \
      if (r5  !==16'h0)     tb_error({"====== r5 IRQ clear (", str, ") ====="}); \
      if (r4  !==16'h0)     tb_error({"====== r4 IRQ clear (", str, ") ====="}); \
      if (r2  !==irqStatus) tb_error({"====== r2 IRQ sr value (", str, ") ====="}); \
      if (chkSp && (r1!==spVal)) tb_error({"====== r1 IRQ sp value (", str, ") ====="}); \
      if (gie)              tb_error({"====== GIE IRQ clear (", str, ") ====="}); \
      //if (stack_guard !==16'h0)  tb_error({"====== stack guard IRQ clear (", str, ") ====="});

`define CHK_IRQ_REGS( str, spVal, retiAddr, irqStatus) \
    `CHK_IRQ_REGS_SP( str, spVal, retiAddr, irqStatus, 1'b1 )
   
`define CHK_IRQ_STACK_R15( str, pc, sr, r15Val ) \
      /*$display({"checking stack memory ", str});*/ \
      if (mem25E !==pc)        tb_error({"====== STACK MEMORY PC (", str, ") ====="});  \
      if (mem25C !==sr)        tb_error({"====== STACK MEMORY SR (", str, ") ====="});  \
      if (mem25A !==r15Val)    tb_error({"====== STACK MEMORY r15 (", str, ") ====="}); \
      if (mem258 !==`R14_VAL)  tb_error({"====== STACK MEMORY r14 (", str, ") ====="}); \
      if (mem256 !==`R13_VAL)  tb_error({"====== STACK MEMORY r13 (", str, ") ====="}); \
      if (mem254 !==`R12_VAL)  tb_error({"====== STACK MEMORY r12 (", str, ") ====="}); \
      if (mem252 !==`R11_VAL)  tb_error({"====== STACK MEMORY r11 (", str, ") ====="}); \
      if (mem250 !==`R10_VAL)  tb_error({"====== STACK MEMORY r10 (", str, ") ====="}); \
      if (mem24E !==`R9_VAL)   tb_error({"====== STACK MEMORY r9 (", str, ") ====="});  \
      if (mem24C !==`R8_VAL)   tb_error({"====== STACK MEMORY r8 (", str, ") ====="});  \
      if (mem24A !==`R7_VAL)   tb_error({"====== STACK MEMORY r7 (", str, ") ====="});  \
      if (mem248 !==`R6_VAL)   tb_error({"====== STACK MEMORY r6 (", str, ") ====="});  \
      if (mem246 !==`R5_VAL)   tb_error({"====== STACK MEMORY r5 (", str, ") ====="});  \
      if (mem244 !==`R4_VAL)   tb_error({"====== STACK MEMORY r4 (", str, ") ====="});

`define CHK_IRQ_STACK( str, pc, sr ) \
    `CHK_IRQ_STACK_R15( str, pc, sr, `R15_VAL )
