`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module omsp_hmac_control(
  input  wire         clk,
  input  wire         reset,
  input  wire         start,
  input  wire   [2:0] mode,
  input  wire         spm_data_select_valid,
  input  wire         spm_key_select_valid,
  input  wire  [15:0] spm_data,
  input  wire  [15:0] mem_in,
  input  wire  [15:0] hmac_in,
  input  wire  [15:0] r11,
  input  wire  [15:0] r12,
  input  wire  [15:0] r13,
  input  wire  [15:0] r14,
  input  wire  [15:0] r15,
  input  wire  [15:0] pc,
  input  wire         hmac_busy,

  output reg          busy,
  output reg    [2:0] spm_request,
  output wire  [15:0] spm_data_select,
  output wire  [15:0] spm_key_select,
  output wire   [1:0] key_select,
  output reg          mb_en,
  output reg    [1:0] mb_wr,
  output reg   [15:0] mab,
  output reg          reg_wr,
  output reg          spm_write_key,
  output reg          vendor_write_key,
  output reg   [15:0] data_out,
  output reg          hmac_reset,
  output reg          hmac_start_continue,
  output reg          hmac_data_available,
  output reg          hmac_data_is_long
);

// helper wires
reg sign, cert, verify, write, hkdf, id;

always @(*)
begin
  sign = 0;
  cert = 0;
  verify = 0;
  write = 0;
  hkdf = 0;
  id = 0;

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

    `HMAC_ID:
    begin
      id = 1;
    end
  endcase
end

wire spm_ok = spm_data_select_valid & spm_key_select_valid;

// FSM
localparam integer STATE_SIZE = 5;
localparam [STATE_SIZE-1:0] IDLE          = 0,
                            HKDF_DELAY    = 1,
                            CHECK_SPM     = 2,
                            HMAC_VID      = 3,
                            HMAC_VID_WAIT = 4,
                            START_SIGN    = 5,
                            START_VERIFY1 = 6,
                            START_VERIFY2 = 7,
                            HMAC_MEM      = 8,
                            HMAC_MEM_WAIT = 9,
                            HMAC_SPM      = 10,
                            HMAC_SPM_WAIT = 11,
                            HKDF_PAD      = 12,
                            HKDF_PAD_WAIT = 13,
                            HMAC_DONE     = 14,
                            PRE_OUTPUT    = 15,
                            VERIFY        = 16,
                            VERIFY_WAIT   = 17,
                            WRITE_DELAY   = 18,
                            WRITE         = 19,
                            WRITE_WAIT    = 20,
                            PRE_KEY_OUT   = 21,
                            KEY_OUT_DELAY = 22,
                            KEY_OUT       = 23,
                            KEY_OUT_WAIT  = 24,
                            HKDF_2ND_RUN  = 25,
                            FAIL          = 26,
                            SUCCESS       = 27,
                            FINISH        = 28;

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
  case (state)
    IDLE:           next_state = ~start         ? IDLE          :
                                 hkdf           ? HKDF_DELAY    : CHECK_SPM;
    HKDF_DELAY:     next_state =                  CHECK_SPM;
    CHECK_SPM:      next_state = ~spm_ok        ? FAIL          :
                                 sign           ? START_SIGN    :
                                 hkdf           ? HMAC_VID      :
                                 id             ? SUCCESS       : START_VERIFY1;
    HMAC_VID:       next_state =                  HMAC_VID_WAIT;
    HMAC_VID_WAIT:  next_state = hmac_busy      ? HMAC_VID_WAIT : HKDF_PAD;
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
    KEY_OUT:        next_state = ~mem_done      ? KEY_OUT_WAIT  :
                                 hkdf_2nd_run   ? SUCCESS       : HKDF_2ND_RUN;
    KEY_OUT_WAIT:   next_state = hmac_busy      ? KEY_OUT_WAIT  : KEY_OUT_DELAY;
    HKDF_2ND_RUN:   next_state =                  HMAC_MEM_WAIT;
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
assign spm_data_select = hkdf ? r12 :
                         sign ? pc  :
                         id   ? r15 : r14;
assign spm_key_select  = hkdf ? r12 :
                         id   ? r15 : pc;

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

// HKDF second run signal. Stays low until the vendor key has been generated
reg hkdf_2nd_run;
reg set_hkdf_2nd_run;
reg unset_hkdf_2nd_run;

always @(posedge clk)
  if (set_hkdf_2nd_run)
    hkdf_2nd_run <= 1;
  else if (unset_hkdf_2nd_run)
    hkdf_2nd_run <= 0;

// HMAC input key selection
assign key_select = ~hkdf        ? `KEY_SEL_SPM    :
                    hkdf_2nd_run ? `KEY_SEL_VENDOR : `KEY_SEL_MASTER;

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
  spm_write_key = 0;
  vendor_write_key = 0;
  set_hkdf_2nd_run = 0;
  unset_hkdf_2nd_run = 0;

  case (next_state)
    IDLE:
    begin
      hmac_reset = 1;
      spm_request_idx_clear = 1;
      busy = 0;
      unset_hkdf_2nd_run = 1;
    end

    HKDF_DELAY:
    begin
    end

    CHECK_SPM:
    begin
    end

    HMAC_VID:
    begin
      update_data_out = 1;
      data_out_val = r11;
      set_start_continue = 1;
      set_data_available = 1;
    end

    HMAC_VID_WAIT:
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
      spm_write_key = hkdf_2nd_run;
      vendor_write_key = ~hkdf_2nd_run;
      mab_inc = 1;
    end

    KEY_OUT_WAIT:
    begin
    end

    HKDF_2ND_RUN:
    begin
      set_hkdf_2nd_run = 1;
      hmac_reset = 1;
      mab_init = 1;
      mab_base = r12;
      mab_limit_init = 1;
      mab_limit = r13;
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
 
