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
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* ----------------------  INITIALIZATION --------------- */

      $display("waiting for foo entry..");
      while(~sm_0_executing) @(posedge mclk);

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);
      $display(r8);

      stimulus_done = 1;
   end
