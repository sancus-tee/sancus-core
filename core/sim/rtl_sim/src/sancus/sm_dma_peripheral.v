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
      @(r8==16'b0000000000100000);
      @(r9==16'b0000000010100000);
      @(r15==16'h2000);

      stimulus_done = 1;
   end
