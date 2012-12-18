`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_spm(
    mclk,
    puc_rst,
    pc,
    prev_pc,
    eu_mab,
    eu_mb_en,
    eu_mb_wr,
    update_spm,
    enable_spm,
    check_new_spm,
    next_id,
    r12,
    r13,
    r14,
    r15,
    data_request,

    enabled,
    violation,
    selected,
    requested_data
);

input        mclk;
input        puc_rst;
input [15:0] pc;        // Program Counter
input [15:0] prev_pc;
input [15:0] eu_mab;    // Execution Unit Memory address bus
input        eu_mb_en;  // Execution Unit Memory bus enable
input  [1:0] eu_mb_wr;  // Execution Unit Memory bus write transfer
input        update_spm;
input        enable_spm;
input        check_new_spm;
input [15:0] next_id;
input [15:0] r12;
input [15:0] r13;
input [15:0] r14;
input [15:0] r15;
input  [2:0] data_request;

output            enabled;
output            violation;
output            selected;
output reg [15:0] requested_data;

reg [15:0] id;
reg [15:0] public_start;
reg [15:0] public_end;
reg [15:0] secret_start;
reg [15:0] secret_end;
reg        enabled;

function exec_spm;
    input [15:0] current_pc;

    begin
        exec_spm = current_pc >= public_start & current_pc <= public_end;
    end
endfunction

function do_overlap;
    input [15:0] start_a;
    input [15:0] end_a;
    input [15:0] start_b;
    input [15:0] end_b;

    begin
        do_overlap = (start_a <= end_b) & (end_a >= start_b);
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

always @(posedge mclk or posedge puc_rst)
begin
    if (puc_rst)
    begin
        id <= 0;
        public_start <= 0;
        public_end <= 0;
        secret_start <= 0;
        secret_end <= 0;
        enabled <= 0;
    end
    else if (update_spm)
    begin
        if (enable_spm)
        begin
            if ((r12 < r13) & (r14 < r15))
            begin
                id <= next_id;
                public_start <= r12;
                public_end <= r13;
                secret_start <= r14;
                secret_end <= r15;
                enabled <= 1;
                $display("New SPM config: %h %h %h %h", r12, r13, r14, r15);
            end
            else
            begin
                $display("Invalid SPM config: %h %h %h %h", r12, r13, r14, r15);
            end
        end
        else if (pc >= public_start && pc < public_end)
        begin
            id <= 0;
            public_start <= 0;
            public_end <= 0;
            secret_start <= 0;
            secret_end <= 0;
            enabled <= 0;
            $display("SPM disabled");
        end
    end
end

wire exec_public = exec_spm(pc);
wire access_secret = eu_mb_en & (eu_mab >= secret_start) & (eu_mab <= secret_end);
wire mem_violation = access_secret & ~exec_public;
wire exec_violation = exec_public & ~exec_spm(prev_pc) & (pc != public_start);
wire create_violation = check_new_spm &
                        (do_overlap(r12, r13, public_start, public_end) |
                         do_overlap(r12, r13, secret_start, secret_end) |
                         do_overlap(r14, r15, public_start, public_end) |
                         do_overlap(r14, r15, secret_start, secret_end));
wire violation = enabled & (mem_violation | exec_violation | create_violation);

always @(posedge mclk)
begin
    if (violation)
    begin
        if (mem_violation)
            $display("mem violation @%h, from %h", eu_mab, pc);
        else if (exec_violation)
            $display("exec violation %h -> %h", prev_pc, pc);
        else if (create_violation)
        begin
            $display("create violation:");
            $display("\tme:  %h %h %h %h", public_start, public_end, secret_start, secret_end);
            $display("\tnew: %h %h %h %h", r12, r13, r14, r15);
        end
    end
end

assign selected = enabled & (r14 == public_start);

always @(*)
  case (data_request)
    `SPM_REQ_PUBSTART: requested_data = public_start;
    `SPM_REQ_PUBEND:   requested_data = public_end;
    `SPM_REQ_SECSTART: requested_data = secret_start;
    `SPM_REQ_SECEND:   requested_data = secret_end;
    `SPM_REQ_ID:       requested_data = id;
  endcase

endmodule
