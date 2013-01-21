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
  input  wire  [15:0] r12,
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
  output reg          write_key,
  output reg   [15:0] data_out,
  output reg          hmac_reset,
  output reg          hmac_start_continue,
  output reg          hmac_data_available,
  output reg          hmac_data_is_long
);

// helper wires
reg sign, cert, verify, write, hkdf;

always @(*)
begin
  sign = 0;
  cert = 0;
  verify = 0;
  write = 0;
  hkdf = 0;

  case (mode)
    `HMAC_CERT_VERIFY:
    begin
      cert = 1;
      verify = 1;
    end

    `HMAC_CERT_WRITE:
    begin
      cert = 1;
      write = 1;
    end

    `HMAC_SIGN:
    begin
      sign = 1;
      write = 1;
    end

    `HMAC_HKDF:
    begin
      hkdf = 1;
    end

  endcase
end

wire spm_ok = spm_select_valid;

// FSM
localparam integer STATE_SIZE = 5;
localparam [STATE_SIZE-1:0] IDLE          = 0,
                            HKDF_DELAY    = 1,
                            CHECK_SPM     = 2,
                            START_SIGN    = 3,
                            START_VERIFY1 = 4,
                            START_VERIFY2 = 5,
                            HMAC_MEM      = 6,
                            HMAC_MEM_WAIT = 7,
                            HMAC_SPM      = 8,
                            HMAC_SPM_WAIT = 9,
                            HKDF_PAD      = 10,
                            HKDF_PAD_WAIT = 11,
                            HMAC_DONE     = 12,
                            PRE_OUTPUT    = 13,
                            VERIFY        = 14,
                            VERIFY_WAIT   = 15,
                            WRITE_DELAY   = 16,
                            WRITE         = 17,
                            WRITE_WAIT    = 18,
                            PRE_KEY_OUT   = 19,
                            KEY_OUT_DELAY = 20,
                            KEY_OUT       = 21,
                            KEY_OUT_WAIT  = 22,
                            FAIL          = 23,
                            SUCCESS       = 24,
                            FINISH        = 25;

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
  case (state)
    IDLE:           next_state = ~start         ? IDLE          :
                                 hkdf           ? HKDF_DELAY    : CHECK_SPM;
    HKDF_DELAY:     next_state =                  CHECK_SPM;
    CHECK_SPM:      next_state = ~spm_ok        ? FAIL          :
                                 sign           ? START_SIGN    :
                                 hkdf           ? HMAC_MEM_WAIT : START_VERIFY1;
    START_SIGN:     next_state =                  HMAC_MEM_WAIT;
    START_VERIFY1:  next_state =                  START_VERIFY2;
    START_VERIFY2:  next_state =                  HMAC_MEM_WAIT;
    HMAC_MEM:       next_state =                  HMAC_MEM_WAIT;
    HMAC_MEM_WAIT:  next_state = hmac_busy      ? HMAC_MEM_WAIT :
                                 ~mem_done      ? HMAC_MEM      :
                                 cert           ? HMAC_SPM      :
                                 hkdf           ? HKDF_PAD      : HMAC_DONE;
    HMAC_SPM:       next_state =                  HMAC_SPM_WAIT;
    HMAC_SPM_WAIT:  next_state = hmac_busy      ? HMAC_SPM_WAIT :
                                 hmac_spm_done  ? HMAC_DONE     : HMAC_SPM;
    HKDF_PAD:       next_state =                  HKDF_PAD_WAIT;
    HKDF_PAD_WAIT:  next_state = hmac_busy      ? HKDF_PAD_WAIT : HMAC_DONE;
    HMAC_DONE:      next_state = hmac_busy      ? HMAC_DONE     :
                                 hkdf           ? PRE_KEY_OUT   : PRE_OUTPUT;
    PRE_OUTPUT:     next_state = verify         ? VERIFY_WAIT   : WRITE_WAIT;
    VERIFY:         next_state = ~verify_ok     ? FAIL          :
                                 mem_done       ? SUCCESS       : VERIFY_WAIT;
    VERIFY_WAIT:    next_state = hmac_busy      ? VERIFY_WAIT   : VERIFY;
    WRITE_DELAY:    next_state =                  WRITE;
    WRITE:          next_state = mem_done       ? SUCCESS       : WRITE_WAIT;
    WRITE_WAIT:     next_state = hmac_busy      ? WRITE_WAIT    : WRITE_DELAY;
    PRE_KEY_OUT:    next_state =                  KEY_OUT_DELAY;
    KEY_OUT_DELAY:  next_state =                  KEY_OUT;
    KEY_OUT:        next_state = mem_done       ? SUCCESS       : KEY_OUT_WAIT;
    KEY_OUT_WAIT:   next_state = hmac_busy      ? KEY_OUT_WAIT  : KEY_OUT_DELAY;
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
assign spm_select = hkdf ? r12 :
                    sign ? pc  : r14;

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
    mab_limit_reg <= mab_limit;

wire mem_done = mab >= mab_limit_reg;

// HMAC control signals
reg set_start_continue;
reg set_data_available;
reg set_hmac_data_is_long;

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

always @(posedge clk or posedge reset)
  if (reset | ~set_hmac_data_is_long)
    hmac_data_is_long <= 0;
  else
    hmac_data_is_long <= 1;

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
  set_hmac_data_is_long = 1;
  spm_request_idx_clear = 0;
  spm_request_idx_inc = 0;
  write_key = 0;

  case (next_state)
    IDLE:
    begin
      hmac_reset = 1;
      spm_request_idx_clear = 1;
      busy = 0;
    end

    HKDF_DELAY:
    begin
      mab_init = 1;
      mab_base = r12;
      mab_limit_init = 1;
      mab_limit = r13;
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

    HKDF_PAD:
    begin
      update_data_out = 1;
      data_out_val = 16'h01;
      set_start_continue = 1;
      set_data_available = 1;
      set_hmac_data_is_long = 0;
    end

    HKDF_PAD_WAIT:
    begin
      set_hmac_data_is_long = 0;
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
      mab_limit = r15 + 16;
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

    PRE_KEY_OUT:
    begin
      // HACK: we use mab as counter so that the mem_done signal can be reused
      // to indicate that the whole key has been written
      mab_init = 1;
      mab_base = 0;
      mab_limit_init = 1;
      mab_limit = 16;
    end

    KEY_OUT_DELAY:
    begin
      update_data_out = 1;
      data_out_val = hmac_in;
    end

    KEY_OUT:
    begin
      set_start_continue = 1;
      write_key = 1;
      mab_inc = 1;
    end

    KEY_OUT_WAIT:
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
 