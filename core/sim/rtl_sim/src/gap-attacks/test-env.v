initial
   begin
      $display(" =============================================== ");
      $display("|                 START SIMULATION              |");
      $display(" =============================================== ");

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      $display("\n--- SM INIT ---");
      @(posedge crypto_start);
      @(posedge exec_done);
      repeat(2) @(posedge mclk);
      $display("SM enabled");
      if (!sm_0_enabled)                    tb_error("====== SM NOT ENABLED ======");

      $display("\n--- SM ENTRY ---");
      @(posedge sm_0_executing);
      $display("SM entered");

      $display("\n--- END OF TEST ---");
      @(r15==16'h2000);

      $display("Validating contextual equivalence breach (__SECRET=%1d)", `__SECRET);
      if (r14!=`__SECRET)                    tb_error("====== R14 FINAL ======");
      else $display("OK");
      stimulus_done = 1;
   end
