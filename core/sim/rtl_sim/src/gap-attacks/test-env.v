initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      $display("__SECRET=%d", `__SECRET);

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      @(r15==16'h1000);
      if (r14!=0)                           tb_error("====== R14 INIT ======");

      /* ----------------------  SM INITIALIZATION --------------- */
      $display("\n--- SM INIT ---");
      @(posedge crypto_start);
      @(posedge exec_done);
      repeat(2) @(posedge mclk);
      $display("SM enabled");
      if (!sm_0_enabled)                    tb_error("====== SM NOT ENABLED ======");

      $display("\n--- SM ENTRY ---");
      @(posedge sm_0_executing);
     
      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h2000);

      if (r14!=`__SECRET)                    tb_error("====== R14 FINAL ======");
      stimulus_done = 1;
   end
