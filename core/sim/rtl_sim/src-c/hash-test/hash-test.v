`define NO_TIMEOUT

initial
begin
    $display(" ===============================================");
    $display("|                 START SIMULATION              |");
    $display(" ===============================================");

    //---------------------------------------
    // Check CPU configuration
    //---------------------------------------
//     if ((`PMEM_SIZE !== 4096) || (`DMEM_SIZE !== 2048))
//     begin
//         $display(" ===============================================");
//         $display("|               SIMULATION ERROR                |");
//         $display("|                                               |");
//         $display("|  Core must be configured for:                 |");
//         $display("|               - 60kB program memory           |");
//         $display("|               - 2kB data memory              |");
//         $display(" ===============================================");
//         $finish;
//     end
end

always @(posedge p1_dout[7])
begin
    $write("%c", p1_dout[6:0]);
end
