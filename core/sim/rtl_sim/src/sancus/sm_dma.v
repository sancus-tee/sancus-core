/*===========================================================================*/
/*                 SANCUS MODULE DMA VIOLATION                               */
/*---------------------------------------------------------------------------*/
/* Test DMA violations by accessing secret SM memory from outside.           */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/*===========================================================================*/

`define DMA_DONE_ADDR           (`DMEM_BASE+16'h60)
`define FOO_SECRET_ADDR         (`DMEM_BASE+16'h62)
`define FOO_SECRET              (mem262)
`define FOO_SECRET_VAL          (16'hf00d)
`define FOO_TEXT_ADDR           (sm_0_public_end-2)
`define FOO_TEXT_VAL            (16'hcafe)

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      // Disable automatic DMA verification
      #10;
      dma_verif_on = 0;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      
      /* ----------------------  INITIALIZATION --------------- */

      $display("waiting for foo entry...");
      while(~sm_0_executing) @(posedge mclk);
      @(`FOO_SECRET);
      if (`FOO_SECRET !== `FOO_SECRET_VAL) tb_error("====== FOO SECRET INIT ======");

      $display("waiting for DMA loop entry...");
      @(r15==16'h1000);
      
      /* ----------------------  DMA ACCESSES --------------- */
      $display("DMA rd/wr foo data...");
      dma_read_16b(`FOO_SECRET_ADDR, 16'h0, /*fail=*/1);
      dma_write_16b(`FOO_SECRET_ADDR, `FOO_SECRET_VAL+3, /*fail=*/1);
      dma_read_16b(`FOO_SECRET_ADDR, 16'h0, /*fail=*/1);

      $display("DMA rd/wr foo text...");
      dma_read_16b(`FOO_TEXT_ADDR, 16'h0, /*fail=*/1);
      dma_write_16b(`FOO_TEXT_ADDR, `FOO_TEXT_VAL+3, /*fail=*/1);
      dma_read_16b(`FOO_TEXT_ADDR, 16'h0, /*fail=*/1);

      dma_write_16b(`DMA_DONE_ADDR, 1, /*fail=*/0);
      
      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test...");
      @(r15==16'h2000);

      stimulus_done = 1;
   end
