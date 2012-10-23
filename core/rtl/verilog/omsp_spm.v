`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_spm(
    mclk,
    pc,
    prev_pc,
    eu_mab,
    eu_mb_en,
    eu_mb_wr,
    update_spm,
    enable_spm,
    r12,
    r13,
    r14,
    r15,
    enabled,
    violation
);

input        mclk;
input [15:0] pc;        // Program Counter
input [15:0] prev_pc;
input [15:0] eu_mab;    // Execution Unit Memory address bus
input        eu_mb_en;  // Execution Unit Memory bus enable
input  [1:0] eu_mb_wr;  // Execution Unit Memory bus write transfer
input        update_spm;
input        enable_spm;
input [15:0] r12;
input [15:0] r13;
input [15:0] r14;
input [15:0] r15;

output       enabled;
output       violation;

reg [15:0] public_start;
reg [15:0] public_end;
reg [15:0] secret_start;
reg [15:0] secret_end;
reg        enabled;

function exec_spm;
    input [15:0] current_pc;

    begin
        exec_spm = current_pc >= public_start & current_pc < public_end;
    end
endfunction

initial
begin
    public_start = 0;
    public_end = 0;
    secret_start = 0;
    secret_end = 0;
    enabled = 0;
end

always @(posedge mclk)
begin
    if (update_spm)
    begin
        if (enable_spm)
        begin
            public_start <= r12;
            public_end <= r13;
            secret_start <= r14;
            secret_end <= r15;
            enabled <= 1;
            $display("New SPM config: %h %h %h %h", r12, r13, r14, r15);
        end
        else if (pc >= public_start && pc < public_end)
        begin
            public_start <= 0;
            public_end <= 0;
            secret_start <= 0;
            secret_end <= 0;
            enabled <= 0;
            $display("SPM disabled");
        end
        else if (enabled) $display("%h %h %h", public_start, pc, public_end);
    end
end

wire exec_public = exec_spm(pc);
wire access_secret = eu_mb_en & (eu_mab >= secret_start) & (eu_mab < secret_end);
wire mem_violation = access_secret & ~exec_public;
wire exec_violation = exec_public & ~exec_spm(prev_pc) & (pc != public_start);
wire violation = enabled & (mem_violation | exec_violation);

always @(posedge mclk)
begin
    if (mem_violation)
        $display("mem violation @%h, from %h", eu_mab, pc);
    else if (exec_violation)
        $display("exec violation %h -> %h", prev_pc, pc);
end

endmodule
