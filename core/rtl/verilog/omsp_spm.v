`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_spm(mclk,
                pc,
                eu_mab,
                eu_mb_en,
                eu_mb_wr,
                eu_mdb_out,
                spm_public_start,
                spm_public_end,
                spm_private_start,
                spm_private_end,
                spm_enabled);

input        mclk;
input [15:0] pc;        // Program Counter
input [15:0] eu_mab;    // Execution Unit Memory address bus
input        eu_mb_en;  // Execution Unit Memory bus enable
input  [1:0] eu_mb_wr;  // Execution Unit Memory bus write transfer
input [15:0] eu_mdb_out;

input [15:0] spm_public_start;
input [15:0] spm_public_end;
input [15:0] spm_private_start;
input [15:0] spm_private_end;
input        spm_enabled;

// initial
// begin
//     spm_public_start = 'ha090;
//     spm_public_end = 'ha0ae;
//     spm_private_start = 'h0200;
//     spm_private_end = 'h0202;
//     spm_enabled = 1;
// end

always @(posedge mclk)
begin
    if (eu_mb_en && spm_enabled)
    begin
        if (eu_mab >= spm_private_start && eu_mab < spm_private_end)
        begin
            //memory access to private section
            if (pc < spm_public_start || pc >= spm_public_end)
                $display("Illegal access at %h from %h", eu_mab, pc);
            else
                $display("Allowed access at %h from %h", eu_mab, pc);
        end
    end
end

endmodule
