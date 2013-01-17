`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_hmac_control(
  input  wire         clk,
  input  wire         reset,
  input  wire         start,
  input  wire   [1:0] mode,
  input  wire         spm_select_valid,
  input  wire  [15:0] spm_data,
  input  wire  [15:0] mem_in,
  input wire   [15:0] hmac_in,
  input  wire  [15:0] r13,
  input  wire  [15:0] r14,
  input  wire  [15:0] r15,
  input  wire  [15:0] pc,
  input  wire         hmac_busy,

  output reg          busy,
  output reg    [2:0] spm_request,
  output wire  [15:0] spm_select,
  output reg          mb_en,
  output reg    [1:0] mb_wr,
  output reg   [15:0] mab,
  output reg          reg_wr,
  output reg   [15:0] data_out,
  output reg          hmac_reset,
  output reg          hmac_start_continue,
  output reg          hmac_data_available,
  output reg          hmac_data_is_long
);

// helper wires
wire sign   = mode == `HMAC_SIGN;
wire cert   = ~sign;
wire verify = mode == `HMAC_CERT_VERIFY;
wire write  = ~verify;

wire spm_ok = spm_select_valid;

// FSM
localparam integer STATE_SIZE = 5;
localparam [STATE_SIZE-1:0] IDLE          = 0,
                            CHECK_SPM     = 1,
                            START_SIGN    = 2,
                            START_VERIFY1 = 3,
                            START_VERIFY2 = 4,
                            HMAC_MEM      = 5,
                            HMAC_MEM_WAIT = 6,
                            HMAC_SPM      = 7,
                            HMAC_SPM_WAIT = 8,
                            HMAC_DONE     = 9,
                            PRE_OUTPUT    = 10,
                            VERIFY        = 11,
                            VERIFY_WAIT   = 12,
                            WRITE_DELAY   = 13,
                            WRITE         = 14,
                            WRITE_WAIT    = 15,
                            FAIL          = 16,
                            SUCCESS       = 17,
                            FINISH        = 18;

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
  case (state)
    IDLE:           next_state = start          ? CHECK_SPM     : IDLE;
    CHECK_SPM:      next_state = ~spm_ok        ? FAIL          :
                                 sign           ? START_SIGN    : START_VERIFY1;
    START_SIGN:     next_state =                  HMAC_MEM_WAIT;
    START_VERIFY1:  next_state =                  START_VERIFY2;
    START_VERIFY2:  next_state =                  HMAC_MEM_WAIT;
    HMAC_MEM:       next_state =                  HMAC_MEM_WAIT;
    HMAC_MEM_WAIT:  next_state = hmac_busy      ? HMAC_MEM_WAIT :
                                 ~mem_done      ? HMAC_MEM      :
                                 cert           ? HMAC_SPM      : WRITE;
    HMAC_SPM:       next_state =                  HMAC_SPM_WAIT;
    HMAC_SPM_WAIT:  next_state = hmac_busy      ? HMAC_SPM_WAIT :
                                 hmac_spm_done  ? HMAC_DONE     : HMAC_SPM;
    HMAC_DONE:      next_state = hmac_busy      ? HMAC_DONE     : PRE_OUTPUT;
    PRE_OUTPUT:     next_state = verify         ? VERIFY_WAIT   : WRITE_WAIT;
    VERIFY:         next_state = ~verify_ok     ? FAIL          :
                                 mem_done       ? SUCCESS       : VERIFY_WAIT;
    VERIFY_WAIT:    next_state = hmac_busy      ? VERIFY_WAIT   : VERIFY;
    WRITE_DELAY:    next_state =                  WRITE;
    WRITE:          next_state = mem_done       ? SUCCESS       : WRITE_WAIT;
    WRITE_WAIT:     next_state = hmac_busy      ? WRITE_WAIT    : WRITE_DELAY;
    FAIL:           next_state =                  FINISH;
    SUCCESS:        next_state =                  FINISH;
    FINISH:         next_state =                  IDLE;

    default:        next_state =                  {STATE_SIZE{1'bx}};
  endcase

always @(posedge clk or posedge reset)
  if (reset)
    state <= IDLE;
  else
    state <= next_state;

// SPM selection
assign spm_select = sign ? pc : r14;

// memory address calculation
reg        mab_init;
reg        mab_inc;
reg [15:0] mab_base;

always @(posedge clk)
  if (mab_init)
    mab <= mab_base;
  else if (mab_inc)
    mab <= mab + 2;

reg [15:0] mab_limit, mab_limit_reg;
reg        mab_limit_init;

always @(posedge clk)
  if (mab_limit_init)
    mab_limit_reg <= mab_limit + 1;

wire mem_done = mab == mab_limit_reg;

// HMAC control signals
reg set_start_continue;
reg set_data_available;

always @(posedge clk or posedge reset)
  if (reset | ~set_data_available)
    hmac_data_available <= 0;
  else
    hmac_data_available <= 1;

always @(posedge clk or posedge reset)
  if (reset | ~set_start_continue)
    hmac_start_continue <= 0;
  else
    hmac_start_continue <= 1;

// HMAC data from SPMs
reg [2:0] spm_requests[0:3];
initial
begin
  spm_requests[0] = `SPM_REQ_PUBSTART;
  spm_requests[1] = `SPM_REQ_PUBEND;
  spm_requests[2] = `SPM_REQ_SECSTART;
  spm_requests[3] = `SPM_REQ_SECEND;
end

reg [1:0] spm_request_idx;
reg       spm_request_idx_inc;
reg       spm_request_idx_clear;

always @(posedge clk)
  if (spm_request_idx_clear)
    spm_request_idx <= 0;
  else if (spm_request_idx_inc)
    spm_request_idx <= spm_request_idx + 1;

wire [2:0] hmac_spm_request = spm_requests[spm_request_idx];
wire       hmac_spm_done    = spm_request_idx == 0; // NOTE wrap around

// HMAC verification
wire verify_ok = {mem_in[7:0], mem_in[15:8]} == hmac_in;

// data output
reg [15:0] data_out_val;
reg        update_data_out;

always @(posedge clk)
  if (update_data_out)
    data_out <= data_out_val;

// control signals
always @(*)
begin
  hmac_reset = 0;
  busy = 1;
  mab_init = 0;
  mab_inc = 0;
  mab_base = 0;
  mab_limit = 0;
  mab_limit_init = 0;
  mb_en = 0;
  mb_wr = 0;
  spm_request = 0;
  reg_wr = 0;
  data_out_val = 0;
  update_data_out = 0;
  set_start_continue = 0;
  set_data_available = 0;
  hmac_data_is_long = 1;
  spm_request_idx_clear = 0;
  spm_request_idx_inc = 0;

  case (next_state)
    IDLE:
    begin
      hmac_reset = 1;
      spm_request_idx_clear = 1;
      busy = 0;
    end

    CHECK_SPM:
    begin
    end

    START_SIGN:
    begin
      mab_init = 1;
      mab_base = r13;
      mab_limit_init = 1;
      mab_limit = r14;
    end

    START_VERIFY1:
    begin
      spm_request = `SPM_REQ_PUBSTART;
      mab_init = 1;
      mab_base = spm_data;
    end

    START_VERIFY2:
    begin
      spm_request = `SPM_REQ_PUBEND;
      mab_limit_init = 1;
      mab_limit = spm_data;
    end

    HMAC_MEM:
    begin
      mab_inc = 1;
      update_data_out = 1;
      data_out_val = {mem_in[7:0], mem_in[15:8]}; // mem is little endian
      set_start_continue = 1;
      set_data_available = 1;
    end

    HMAC_MEM_WAIT:
    begin
      mb_en = 1;
    end

    HMAC_SPM:
    begin
      update_data_out = 1;
      spm_request_idx_inc = 1;
      spm_request = hmac_spm_request;
      data_out_val = spm_data;
      set_start_continue = 1;
      set_data_available = 1;
    end

    HMAC_SPM_WAIT:
    begin
    end

    HMAC_DONE:
    begin
      set_start_continue = 1;
    end

    PRE_OUTPUT:
    begin
      mab_init = 1;
      mab_base = r15;
      mab_limit_init = 1;
      mab_limit = r15 + 15;
    end

    VERIFY:
    begin
      mab_inc = 1;
      mb_en = 1;
      set_start_continue = 1;
    end

    VERIFY_WAIT:
    begin
    end

    WRITE_DELAY:
    begin
      update_data_out = 1;
      data_out_val = {hmac_in[7:0], hmac_in[15:8]};
    end

    WRITE:
    begin
      mab_inc = 1;
      mb_en = 1;
      mb_wr = 2'b11;
      set_start_continue = 1;
    end

    WRITE_WAIT:
    begin
    end

    FAIL:
    begin
      update_data_out = 1;
      data_out_val = 0;
    end

    SUCCESS:
    begin
      spm_request = `SPM_REQ_ID;
      update_data_out = 1;
      data_out_val = spm_data;
    end

    FINISH:
    begin
      reg_wr = 1;
    end
  endcase
end

endmodule

`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_undefines.v"
`endif
 