`define DMA_DONE_ADDR           (`DMEM_BASE+16'h60)
`define FOO_SECRET_ADDR         (`DMEM_BASE+16'h62)
`define FOO_SECRET              (mem262)
`define FOO_SECRET_VAL          (16'hf00d)
`define FOO_TEXT_ADDR           (sm_0_public_end-2)
`define FOO_TEXT_VAL            (16'hcafe)

reg [63:0] tsc_val1;
reg [63:0] tsc_val2;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      // Disable automatic DMA verification
      #10;
      dma_verif_on = 0;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* ----------------------  INITIALIZATION --------------- */

      $display("waiting for foo entry..");
      while(~sm_0_executing) @(posedge mclk);

      /* ----------------------  DMA ACCESSES --------------- */
      tsc_val1 <= cur_tsc;
      dma_write_8b(`DMA_DONE_ADDR, 8'h1, 0);
      dma_write_8b(`FOO_TEXT_ADDR + 4, 8'h1, 0);
      dma_write_8b(`DMA_DONE_ADDR, 8'h1, 0);
      dma_write_8b(`DMA_DONE_ADDR, 8'h1, 0);
      // @(`DMA_DONE_ADDR == 0);

      /* ----------------------  END OF TEST --------------- */
      $display("WAIT DIFFERENCE: %d", cur_tsc - tsc_val1);
      @(r15==16'h2000);

      stimulus_done = 1;
   end
