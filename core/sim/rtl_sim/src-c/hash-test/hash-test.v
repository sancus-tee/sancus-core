`define NO_TIMEOUT

initial
begin
    $display(" ===============================================");
    $display("|                 START SIMULATION              |");
    $display(" ===============================================");

    //---------------------------------------
    // Check CPU configuration
    //---------------------------------------
    if ((`PMEM_SIZE !== 24576) || (`DMEM_SIZE !== 16384))
    begin
        $display(" ===============================================");
        $display("|               SIMULATION ERROR                |");
        $display("|                                               |");
        $display("|  Core must be configured for:                 |");
        $display("|               - 24kB program memory           |");
        $display("|               - 16kB data memory              |");
        $display(" ===============================================");
        $finish;
    end

    @(posedge p2_dout[0]);
    $finish;
end

always @(posedge p1_dout[7])
begin
    $write("%c", p1_dout[6:0]);
end
