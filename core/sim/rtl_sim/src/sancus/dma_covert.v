initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done <= 0;

      /* ----------------------  INITIALIZATION --------------- */

      $display("waiting for end of test...");

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);

      stimulus_done <= 1;
   end
