`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_spm_control(
    mclk,
    pc,
    decode,
    eu_mab,
    eu_mb_en,
    eu_mb_wr,
    update_spm,
    enable_spm,
    r12,
    r13,
    r14,
    r15
);

input        mclk;
input [15:0] pc;        // Program Counter
input        decode;
input [15:0] eu_mab;    // Execution Unit Memory address bus
input        eu_mb_en;  // Execution Unit Memory bus enable
input  [1:0] eu_mb_wr;  // Execution Unit Memory bus write transfer
input        update_spm;
input        enable_spm;
input [15:0] r12;
input [15:0] r13;
input [15:0] r14;
input [15:0] r15;

// input to the SPM array. indicates which SPM(s) should be updated. when a new
// SPM is being created, only one bit will be 1. if an SPM is being destroyed,
// all bits will be 1 since only the SPMs know which one is being destroyed
wire [0:`NB_SPMS-1] spms_update;
// indicates which SPMs should check for an overlap violation
wire [0:`NB_SPMS-1] spms_check;
// helper wire. one-hot encoding of the first disabled SPM
wire [0:`NB_SPMS-1] spms_first_disabled;
// output of the SPM array. indicates which SPMs are enabled
wire [0:`NB_SPMS-1] spms_enabled;
// output of the SPM array. violations detected by the SPMs
wire [0:`NB_SPMS-1] spms_violation;
// helper wire to detect a violation
wire violation;

reg [15:0] current_pc, prev_pc;

assign spms_update = (spms_first_disabled |       // update first disabled SPM
                      {`NB_SPMS{~enable_spm}}) &  // or all for a disable request
                     {`NB_SPMS{update_spm}};      // of course, there should be a request

assign spms_check = (update_spm & enable_spm) ? (~spms_update & spms_enabled)
                                              : `NB_SPMS'b0;

assign violation = |spms_violation;

generate
    genvar i;
    assign spms_first_disabled[0] = ~spms_enabled[0];
    for (i = 1; i < `NB_SPMS; i = i + 1)
        assign spms_first_disabled[i] = ~spms_enabled[i] & ~|spms_first_disabled[0:i-1];
endgenerate

always @(posedge mclk)
begin
    if (violation)
    begin
//         $display("prev:%h, curr:%h", prev_pc, current_pc);
//         $display("Illegal access at %h from %h", eu_mab, pc);
    end
end

always @(pc)
begin
    prev_pc <= current_pc;
    current_pc <= pc;
end

omsp_spm omsp_spms[0:`NB_SPMS-1](
    .mclk               (mclk),
    .pc                 (pc),
    .prev_pc            (prev_pc),
    .eu_mab             (eu_mab),
    .eu_mb_en           (eu_mb_en),
    .eu_mb_wr           (eu_mb_wr),
    .update_spm         (spms_update),
    .enable_spm         (enable_spm),
    .check_new_spm      (spms_check),
    .r12                (r12),
    .r13                (r13),
    .r14                (r14),
    .r15                (r15),
    .enabled            (spms_enabled),
    .violation          (spms_violation)
);

endmodule
