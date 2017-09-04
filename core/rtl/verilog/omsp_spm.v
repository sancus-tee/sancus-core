`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_spm(
  input  wire                    mclk,
  input  wire                    puc_rst,
  input  wire             [15:0] pc,
  input  wire             [15:0] prev_pc,
  input  wire             [15:0] eu_mab,
  input  wire                    eu_mb_en,
  input  wire              [1:0] eu_mb_wr,
  input  wire                    update_spm,
  input  wire                    enable_spm,
  input  wire                    disable_spm,
  input  wire                    check_new_spm,
  input  wire                    verify_spm,
  input  wire             [15:0] next_id,
  input  wire             [15:0] r10,
  input  wire             [15:0] r12,
  input  wire             [15:0] r13,
  input  wire             [15:0] r14,
  input  wire             [15:0] r15,
  input  wire              [2:0] data_request,
  input  wire             [15:0] spm_data_select,
  input  wire                    spm_data_select_type,
  input  wire             [15:0] spm_key_select,
  input  wire                    write_key,
  input  wire             [15:0] key_in,
  input  wire [KEY_IDX_SIZE-1:0] key_idx,
  output reg                     enabled,
  output wire                    executing,
  output wire                    violation,
  output wire                    data_selected,
  output wire                    key_selected,
  output reg              [15:0] requested_data,
  output reg     [0:`SECURITY-1] key,
  output reg              [15:0] id
);

parameter KEY_IDX_SIZE = -1;

reg [15:0] public_start;
reg [15:0] public_end;
reg [15:0] secret_start;
reg [15:0] secret_end;

function exec_spm;
  input [15:0] current_pc;

  begin
    exec_spm = current_pc >= public_start & current_pc < public_end;
  end
endfunction

function do_overlap;
  input [15:0] start_a;
  input [15:0] end_a;
  input [15:0] start_b;
  input [15:0] end_b;

  begin
    do_overlap = (start_a < end_b) & (end_a > start_b);
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
      if ((r12 < r13) & (r14 <= r15))
      begin
        id <= next_id;
        public_start <= r12;
        public_end <= r13;
        secret_start <= r14;
        secret_end <= r15;
        enabled <= 1;
        $display("New SM config: %h %h %h %h, %b", r12, r13, r14, r15, |r10);
      end
      else
      begin
        $display("Invalid SM config: %h %h %h %h, %b", r12, r13, r14, r15, |r10);
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
      $display("SM disabled");
    end
  end
  else if (key_selected & write_key)
    key[16*key_idx+:16] <= key_in;
end

wire exec_public = exec_spm(pc);
wire access_public = eu_mb_en & (eu_mab >= public_start) & (eu_mab < public_end);
wire access_secret = eu_mb_en & (eu_mab >= secret_start) & (eu_mab < secret_end);
wire mem_violation = (access_public & ~(enable_spm | disable_spm | verify_spm |
                                        (executing & ~eu_mb_wr)) |
                     (access_secret & ~exec_public));
wire exec_violation = exec_public & ~exec_spm(prev_pc) & (pc != public_start);
wire create_violation = check_new_spm &
                        (do_overlap(r12, r13, public_start, public_end));// |
                         //do_overlap(r12, r13, secret_start, secret_end) |
                         //do_overlap(r14, r15, public_start, public_end) |
                         //do_overlap(r14, r15, secret_start, secret_end));
assign violation = enabled & (mem_violation | exec_violation | create_violation);
assign executing = enabled & exec_public;

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

// FIXME: WTF? exec_spm() somehow doesn't work when executing HKDF
wire   ps_selected   = (spm_data_select >= public_start) &
                       (spm_data_select < public_end);
wire   id_selected   = spm_data_select == id;
wire   select_id     = spm_data_select_type == `SM_SELECT_BY_ID;
assign data_selected = enabled & (select_id ? id_selected : ps_selected);

always @(*)
  case (data_request)
    `SM_REQ_PUBSTART: requested_data = public_start;
    `SM_REQ_PUBEND:   requested_data = public_end;
    `SM_REQ_SECSTART: requested_data = secret_start;
    `SM_REQ_SECEND:   requested_data = secret_end;
    `SM_REQ_ID:       requested_data = id;
    default:          requested_data = 16'bx;
  endcase

assign key_selected = enabled & (spm_key_select >= public_start) &
                                (spm_key_select < public_end);

endmodule
