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
                update_spm,
                enable_spm,
                r12,
                r13,
                r14,
                r15);

input        mclk;
input [15:0] pc;        // Program Counter
input [15:0] eu_mab;    // Execution Unit Memory address bus
input        eu_mb_en;  // Execution Unit Memory bus enable
input  [1:0] eu_mb_wr;  // Execution Unit Memory bus write transfer
input [15:0] eu_mdb_out;
input        update_spm;
input        enable_spm;
input [15:0] r12;
input [15:0] r13;
input [15:0] r14;
input [15:0] r15;

reg [15:0] spm_public_start;
reg [15:0] spm_public_end;
reg [15:0] spm_private_start;
reg [15:0] spm_private_end;
reg        spm_enabled;

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
    if (update_spm)
    begin
        if (enable_spm)
        begin
            spm_public_start <= r12;
            spm_public_end <= r13;
            spm_private_start <= r14;
            spm_private_end <= r15;
            spm_enabled <= 1;
            $display("New SPM config: %h %h %h %h", r12, r13, r14, r15);
        end
        else
        begin
            spm_public_start <= 0;
            spm_public_end <= 0;
            spm_private_start <= 0;
            spm_private_end <= 0;
            spm_enabled <= 0;
            $display("SPM disabled");
        end
    end
end

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
