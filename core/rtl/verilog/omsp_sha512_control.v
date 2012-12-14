module omsp_sha512_control(
  input  wire        clk,
  input  wire        rst,
  input  wire        start,
  input  wire [15:0] hash_address,
  input  wire [15:0] spm_data,
  input  wire [15:0] mem_data,

  output reg   [1:0] spm_request,
  output reg  [15:0] mab,
  output wire        mb_en,
  output wire  [1:0] mb_wr,
  output wire [15:0] mdb_out,
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
parameter READ_START  = 13;
parameter READ_WAIT   = 14;
parameter READ_HASH   = 15;

parameter WRITE_LAST  = WRITE_SE;

wire write_mem_done = mab - 1 == public_end;
wire read_count_zero = read_wait_count == 5'h0;

assign busy = state != IDLE || start;

reg [3:0] state, state_next, resume_state;
always @(*)
  case (state)
    IDLE:         state_next = start ? READ_PS : IDLE;
    READ_PS:      state_next = READ_PE;
    READ_PE:      state_next = READ_SS;
    READ_SS:      state_next = READ_SE;
    READ_SE:      state_next = WRITE_START;
    WRITE_START:  state_next = WRITE_MEM;
    WRITE_MEM:    state_next = write_mem_done  ? WRITE_PS   :
                               sha512_ready    ? WRITE_MEM  : WRITE_WAIT;
    WRITE_PS:     state_next = sha512_ready    ? WRITE_PE   : WRITE_WAIT;
    WRITE_PE:     state_next = sha512_ready    ? WRITE_SS   : WRITE_WAIT;
    WRITE_SS:     state_next = sha512_ready    ? WRITE_SE   : WRITE_WAIT;
    WRITE_SE:     state_next = WRITE_DONE;
    WRITE_WAIT:   state_next = sha512_ready    ? WRITE_WAIT : resume_state;
    WRITE_DONE:   state_next = sha512_busy     ? WRITE_DONE : READ_START;
    READ_START:   state_next = READ_WAIT;
    READ_WAIT:    state_next = read_count_zero ? READ_HASH  : READ_WAIT;
    READ_HASH:    state_next = read_count_zero ? IDLE       : READ_HASH;
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
  endcase

reg [1:0] sha512_cmd;
always @(*)
  case (state)
    WRITE_START,
    WRITE_MEM,
    WRITE_PS,
    WRITE_PE,
    WRITE_SS:   sha512_cmd = 2'b10;
    READ_START: sha512_cmd = 2'b01;
    default:    sha512_cmd = 2'b00;
  endcase

always @(posedge clk or posedge rst)
  if (rst)
    mab <= 16'b0;
  else
    case (state_next)
      WRITE_START:  mab <= public_start;
      READ_START:   mab <= hash_address;
      WRITE_MEM,
      READ_HASH:    mab <= mab + 2;
    endcase

assign mb_en = (state_next == WRITE_MEM) || (state_next == READ_HASH);
assign mb_wr = state_next == READ_HASH ? 2'b11 : 2'b00;

reg [15:0] sha512_data;
always @(*)
  case (state)
    WRITE_MEM:  sha512_data = mem_data;
    WRITE_PS:   sha512_data = public_start;
    WRITE_PE:   sha512_data = public_end;
    WRITE_SS:   sha512_data = secret_start;
    WRITE_SE:   sha512_data = secret_end;
  endcase

reg [4:0] read_wait_count;
always @(posedge clk or posedge rst)
  if (rst)
    read_wait_count <= 5'd0;
  else if (state == READ_START)
    read_wait_count <= 5'd6;
  else if (state == READ_WAIT && state_next == READ_HASH)
    read_wait_count <= 5'd31;
  else if (state == READ_WAIT || state == READ_HASH)
    read_wait_count <= read_wait_count - 1;

wire sha512_busy, sha512_ready;
omsp_sha512_frontend sha512_frontend(
  .clk             (clk),
  .rst             (rst),
  .cmd_in          (sha512_cmd),
  .data            (sha512_data),
  .data_size       (1'b1),

  .hash            (mdb_out),
  .busy            (sha512_busy),
  .ready_for_data  (sha512_ready)
);

endmodule
