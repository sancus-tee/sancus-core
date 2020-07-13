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

      if(r8 !== 16'b0000000001000000)
         tb_error("====== r8 does not mach expected value ======");
      if(r9 !== 16'b0000000101000000)
         tb_error("====== r9 does not mach expected value ======");

      stimulus_done = 1;
   end
