`include "openMSP430_defines.v"

module omsp_sha512_control(
  input  wire        clk,
  input  wire        rst,
  input  wire        start,
  input  wire [15:0] hash_address,
  input  wire [15:0] spm_data,
  input  wire [15:0] mem_data,

  output reg   [2:0] spm_request,
  output reg  [15:0] mab,
  output wire        mb_en,
  output wire  [1:0] mb_wr,
  output wire [15:0] data_out,
  output wire        reg_write,
  output wire        busy
);

parameter IDLE        = 0;
parameter READ_PS     = 1;
parameter READ_PE     = 2;
parameter READ_SS     = 3;
parameter READ_SE     = 4;
parameter WRITE_START = 5;
parameter WRITE_MEM   = 6;
parameter WRITE_PS    = 7;
parameter WRITE_PE    = 8;
parameter WRITE_SS    = 9;
parameter WRITE_SE    = 10;
parameter WRITE_WAIT  = 11;
parameter WRITE_DONE  = 12;
parameter CHECK_START = 13;
parameter CHECK_WAIT  = 14;
parameter CHECK_HASH  = 15;
parameter DONE        = 16;

parameter WRITE_LAST  = WRITE_SE;

wire write_mem_done = mab - 1 == public_end;
wire read_count_zero = read_wait_count == 5'h0;
wire hash_words_equal = mem_data == {sha512_hash[7:0], sha512_hash[15:8]};

reg start_mem;
always @(posedge clk or posedge rst)
  if (rst)
    start_mem <= 1'b0;
  else
    start_mem <= start;

wire do_start = (start || start_mem) && sha512_sync;
assign busy = state != IDLE || do_start;

reg [4:0] state, state_next, resume_state;
always @(*)
  case (state)
    IDLE:         state_next = do_start        ? READ_PS      : IDLE;
    READ_PS:      state_next = READ_PE;
    READ_PE:      state_next = READ_SS;
    READ_SS:      state_next = READ_SE;
    READ_SE:      state_next = WRITE_START;
    WRITE_START:  state_next = WRITE_MEM;
    WRITE_MEM:    state_next = !sha512_ready   ? WRITE_WAIT   :
                               write_mem_done  ? WRITE_PS     : WRITE_MEM;
    WRITE_PS:     state_next = sha512_ready    ? WRITE_PE     : WRITE_WAIT;
    WRITE_PE:     state_next = sha512_ready    ? WRITE_SS     : WRITE_WAIT;
    WRITE_SS:     state_next = sha512_ready    ? WRITE_SE     : WRITE_WAIT;
    WRITE_SE:     state_next = WRITE_DONE;
    WRITE_WAIT:   state_next = sha512_ready    ? resume_state : WRITE_WAIT;
    WRITE_DONE:   state_next = sha512_busy     ? WRITE_DONE   : CHECK_START;
    CHECK_START:  state_next = CHECK_WAIT;
    CHECK_WAIT:   state_next = read_count_zero ? CHECK_HASH   : CHECK_WAIT;
    CHECK_HASH:   state_next = read_count_zero ? DONE         :
                               check_fail      ? DONE         : CHECK_HASH;
    DONE:         state_next = IDLE;
    default:      state_next = 5'bxxxxx;
  endcase

always @(posedge clk or posedge rst)
  if (rst)
    state <= IDLE;
  else
    state <= state_next;

always @(posedge clk or posedge rst)
  if (rst)
    resume_state <= IDLE;
  else
    case (state)
      WRITE_MEM: resume_state <= write_mem_done ? WRITE_PS : WRITE_MEM;
      WRITE_PS:  resume_state <= WRITE_PE;
      WRITE_PE:  resume_state <= WRITE_SS;
      WRITE_SS:  resume_state <= WRITE_SE;
    endcase

reg [15:0] public_start, public_end, secret_start, secret_end;
always @(posedge clk or posedge rst)
  if (rst)
  begin
    public_start <= 16'b0;
    public_end   <= 16'b0;
    secret_start <= 16'b0;
    secret_end   <= 16'b0;
  end
  else
    case (state)
      READ_PS: public_start <= spm_data;
      READ_PE: public_end   <= spm_data;
      READ_SS: secret_start <= spm_data;
      READ_SE: secret_end   <= spm_data;
    endcase

always @(*)
  case (state)
    READ_PS: spm_request = `SPM_REQ_PUBSTART;
    READ_PE: spm_request = `SPM_REQ_PUBEND;
    READ_SS: spm_request = `SPM_REQ_SECSTART;
    READ_SE: spm_request = `SPM_REQ_SECEND;
    default: spm_request = `SPM_REQ_ID;
  endcase

reg [1:0] sha512_cmd;
always @(*)
  case (state)
    WRITE_START,
    WRITE_MEM,
    WRITE_PS,
    WRITE_PE,
    WRITE_SS,
    WRITE_WAIT:  sha512_cmd = 2'b10;
    CHECK_START: sha512_cmd = 2'b01;
    default:     sha512_cmd = 2'b00;
  endcase

always @(posedge clk or posedge rst)
  if (rst)
    mab <= 16'b0;
  else
    case (state_next)
      WRITE_START:   mab <= public_start;
      CHECK_START:   mab <= hash_address;
      WRITE_MEM,
      CHECK_HASH:    mab <= mab + 2;
    endcase

assign mb_en = (state_next == WRITE_MEM && !write_mem_done) ||
               (state_next == CHECK_HASH);
assign mb_wr = 2'b00;

reg [15:0] sha512_data;
always @(*)
  case (state)
    WRITE_MEM:  sha512_data = {mem_data[7:0], mem_data[15:8]};
    WRITE_PS:   sha512_data = public_start;
    WRITE_PE:   sha512_data = public_end;
    WRITE_SS:   sha512_data = secret_start;
    WRITE_SE:   sha512_data = secret_end;
    default:    sha512_data = 16'bx;
  endcase

reg [4:0] read_wait_count;
always @(posedge clk or posedge rst)
  if (rst)
    read_wait_count <= 5'd0;
  else if (state == CHECK_START)
    read_wait_count <= 5'd5;
  else if (state == CHECK_WAIT && state_next == CHECK_HASH)
    read_wait_count <= 5'd31;
  else if (state == CHECK_WAIT || state == CHECK_HASH)
    read_wait_count <= read_wait_count - 1;

reg check_fail;
always @(posedge clk or posedge rst)
  if (rst || state == IDLE)
    check_fail <= 1'b0;
  else if (state == CHECK_HASH && !hash_words_equal)
    check_fail <= 1'b1;

assign data_out  = check_fail ? 16'b0 : spm_data;
assign reg_write = state == DONE;

wire sha512_busy, sha512_ready, sha512_sync;
wire [15:0] sha512_hash;
omsp_sha512_frontend sha512_frontend(
  .clk             (clk),
  .rst             (rst),
  .cmd_in          (sha512_cmd),
  .data            (sha512_data),
  .data_size       (1'b1),

  .hash            (sha512_hash),
  .busy            (sha512_busy),
  .ready_for_data  (sha512_ready),
  .sync            (sha512_sync)
);

endmodule
