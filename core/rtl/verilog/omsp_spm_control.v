`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_spm_control(
  input  wire                 mclk,
  input  wire                 puc_rst,
  input  wire          [15:0] pc,
  input  wire          [15:0] eu_mab,
  input  wire                 eu_mb_en,
  input  wire           [1:0] eu_mb_wr,
  input  wire                 update_spm,
  input  wire                 enable_spm,
  input  wire          [15:0] r12,
  input  wire          [15:0] r13,
  input  wire          [15:0] r14,
  input  wire          [15:0] r15,
  input  wire          [15:0] spm_data_select,
  input  wire                 spm_data_select_type,
  input  wire          [15:0] spm_key_select,
  input  wire           [2:0] data_request,
  input  wire                 write_key,
  input  wire          [15:0] key_in,
  output wire                 violation,
  output wire                 spm_data_select_valid,
  output wire                 spm_key_select_valid,
  output reg           [15:0] spm_current_id,
  output reg           [15:0] spm_prev_id,
  output reg           [15:0] requested_data,
  output reg  [0:`SECURITY-1] key_out
);

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

wire [0:`NB_SPMS-1] spms_data_selected;
wire [0:`NB_SPMS-1] spms_key_selected;

reg [15:0] current_pc, prev_pc;
reg [15:0] next_id;

assign spms_update = (spms_first_disabled |       // update first disabled SPM
                      {`NB_SPMS{~enable_spm}}) &  // or all for a disable request
                     {`NB_SPMS{update_spm}};      // of course, there should be a request

assign spms_check = (update_spm & enable_spm) ? (~spms_update & spms_enabled)
                                              : `NB_SPMS'b0;

always @(posedge mclk or posedge puc_rst)
  if (puc_rst)
    next_id <= 16'h1;
  else if (update_spm && enable_spm)
    next_id <= next_id + 16'h1;

assign violation = |spms_violation || (next_id == 16'h0);

generate
  genvar i;
  assign spms_first_disabled[0] = ~spms_enabled[0];
  for (i = 1; i < `NB_SPMS; i = i + 1)
    assign spms_first_disabled[i] = ~spms_enabled[i] & ~|spms_first_disabled[0:i-1];
endgenerate

assign spm_data_select_valid = |spms_data_selected;
assign spm_key_select_valid  = |spms_key_selected;

always @(pc)
begin
  prev_pc <= current_pc;
  current_pc <= pc;
end

wire [0:`NB_SPMS*`SECURITY-1] spms_key;

integer spm_i;
always @(*)
begin
  key_out = `SECURITY'hx;
  for (spm_i = 0; spm_i < `NB_SPMS; spm_i = spm_i + 1)
    if (spms_key_selected[spm_i])
      key_out = spms_key[spm_i*`SECURITY+:`SECURITY];
end

wire [0:`NB_SPMS*16-1] spms_requested_data;

integer spm_j;
always @(*)
begin
  requested_data = 16'hx;
  for (spm_j = 0; spm_j < `NB_SPMS; spm_j = spm_j + 1)
    if (spms_data_selected[spm_j])
      requested_data = spms_requested_data[spm_j*16+:16];
end

// keep track of the currently and previously executing SM
wire [0:`NB_SPMS-1] spms_executing;
wire [0:`NB_SPMS*16-1] spms_id;

integer spm_k;
always @(*)
begin
  spm_current_id = 16'h0;
  for (spm_k = 0; spm_k < `NB_SPMS; spm_k = spm_k + 1)
    if (spms_executing[spm_k])
      spm_current_id = spms_id[spm_k*16+:16];
end

reg [15:0] prev_cycle_spm_id;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)
    prev_cycle_spm_id <= 16'h0;
  else
    prev_cycle_spm_id <= spm_current_id;

always @(posedge mclk or posedge puc_rst)
  if (puc_rst)
    spm_prev_id <= 16'h0;
  else if (prev_cycle_spm_id != spm_current_id)
    spm_prev_id <= prev_cycle_spm_id;

omsp_spm omsp_spms[0:`NB_SPMS-1](
  .mclk                 (mclk),
  .puc_rst              (puc_rst),
  .pc                   (pc),
  .prev_pc              (prev_pc),
  .eu_mab               (eu_mab),
  .eu_mb_en             (eu_mb_en),
  .eu_mb_wr             (eu_mb_wr),
  .update_spm           (spms_update),
  .enable_spm           (enable_spm),
  .check_new_spm        (spms_check),
  .next_id              (next_id),
  .r12                  (r12),
  .r13                  (r13),
  .r14                  (r14),
  .r15                  (r15),
  .data_request         (data_request),
  .spm_data_select      (spm_data_select),
  .spm_data_select_type (spm_data_select_type),
  .spm_key_select       (spm_key_select),
  .write_key            (write_key),
  .key_in               (key_in),
  .enabled              (spms_enabled),
  .executing            (spms_executing),
  .violation            (spms_violation),
  .data_selected        (spms_data_selected),
  .key_selected         (spms_key_selected),
  .requested_data       (spms_requested_data),
  .key                  (spms_key),
  .id                   (spms_id)
);

endmodule
