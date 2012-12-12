// Module to add padding for SHA-512 calculation
// API:
//  - Set cmd to 10 to start writing sequence; wait 1 clk cycle
//  - While ready_for_data is asserted, set data to the next 32 bits on every
//    clk cycle
//  - Set data_size to the numer of bytes put in data minus 1. If less than
//    4 bytes are put in data, they should fill the MSBs. So, for example, if
//    2 bytes are passed, put them in data[31:16] and set data_size to 01
//  - If ready_for_data is deasserted and not all data has been sent, wait
//    for it to become asserted again and resume sending data.
//  - During the same clk cycle as the last data is sent, set cmd to 00.
//  - Wait for busy to get deasserted.
//  - Set cmd to 01; wait 1 clk cycle; set cmd to 00; wait 3 clk cycles
//  - Read the 16 32 bits words of hash over the next 16 clk cycles
module omsp_sha512_padder(
  input  wire        clk,
  input  wire        rst,
  input  wire  [1:0] cmd_in,
  input  wire [31:0] data,
  input  wire  [1:0] data_size,

  output wire [31:0] hash,
  output wire        busy,
  output wire        ready_for_data
);

// Helper wires
wire write, read;
assign write = cmd_in[1];
assign read  = cmd_in[0];

wire chunk_done;
assign chunk_done = last_chunk_words == 31;

wire pad_done;
assign pad_done = pad_word_count == 0;

wire [4:0] sha512_state;
wire sha512_busy;
assign sha512_busy = sha512_state[4];

// State machine
`define IDLE 2'b00
`define COPY 2'b01
`define WAIT 2'b10
`define PAD  2'b11

reg [1:0] state, state_next;

always @(*)
  case (state)
    `IDLE:    state_next = write       ? `COPY : `IDLE;
    `COPY:    state_next = chunk_done  ? `WAIT :
                           write       ? `COPY : `PAD;
    `WAIT:    state_next = sha512_busy ? `WAIT :
                           write       ? `COPY :
                           pad_done    ? `IDLE : `PAD;
    `PAD:     state_next = chunk_done  ? `WAIT : `PAD;

    default:  state_next = `IDLE;
  endcase

assign ready_for_data = state_next == `COPY;

always @(posedge clk or posedge rst)
  if (rst)
    state <= `IDLE;
  else
    state <= state_next;

assign busy = state != `IDLE;

// The padding always start with a 1 bit. This signal indicates whether this
// bit still needs to be added to the output.
reg need_one;
always @(posedge clk or posedge rst)
  if (rst || state == `IDLE)
    need_one <= 1'b1;
  else if (state == `COPY)
    need_one <= data_size == 2'b11;
  else if (state == `PAD)
    need_one <= 1'b0;

reg [31:0] sha512_data;
always @(*)
  case (state)
    `COPY:
      case (data_size)
        2'b00: sha512_data  = {data[31:24], 1'b1, 23'b0};
        2'b01: sha512_data  = {data[31:16], 1'b1, 15'b0};
        2'b10: sha512_data  = {data[31: 8], 1'b1,  7'b0};
        // FIXME: I only seem to get reliable simulation results when using
        // a nonblocking assignment here but, AFAICS, this shouldn't be
        // necessary...
        2'b11: sha512_data <=  data;
      endcase
    `PAD:      sha512_data = pad_val;
    default:   sha512_data = 32'b0;
  endcase

reg [0:127] length;
always @(posedge clk or posedge rst)
  if (rst || state == `IDLE)
    length <= 128'b0;
  else if (state == `COPY)
    length <= length + ((data_size + 1) * 8);

reg [5:0] last_chunk_words;
always @(posedge clk or posedge rst)
  if (rst || state == `IDLE || state == `WAIT)
    last_chunk_words <= 6'b0;
  else if (state == `COPY || state == `PAD)
    last_chunk_words <= last_chunk_words + 1;

wire [5:0] last_chunk_pad;
assign last_chunk_pad = 32 - last_chunk_words;

wire [6:0] total_pad_length;
assign total_pad_length = last_chunk_pad < (need_one ? 6 : 5) ?
                                        last_chunk_pad + 32 :
                                        last_chunk_pad;

reg [6:0] pad_word_count;
always @(posedge clk or posedge rst)
  if (rst || state == `IDLE)
    pad_word_count <= 7'b0;
  else if (state == `COPY)
    pad_word_count <= total_pad_length - 1;
  else if (state == `PAD)
    pad_word_count <= pad_word_count - 1;

reg [31:0] pad_val;
always @(*)
  if (state == `PAD)
    case (pad_word_count)
      4:        pad_val = length[ 0: 31];
      3:        pad_val = length[32: 63];
      2:        pad_val = length[64: 95];
      1:        pad_val = length[96:127];
      default:  pad_val = {need_one, 31'b0};
    endcase
  else
    pad_val = 32'b0;

reg round;
always @(posedge clk or posedge rst)
  if (rst || state == `IDLE)
    round <= 1'b0;
  else if (state == `WAIT)
    round <= 1'b1;

wire next_round;
assign next_round = state == `WAIT && (state_next == `COPY || state_next == `PAD);

wire cmd_write;
assign cmd_write = state == `IDLE || next_round;

omsp_sha512 sha512(
  .clk_i    (clk),
  .rst_i    (rst),
  .text_i   (sha512_data),
  .text_o   (hash),
  .cmd_i    ({1'b1, round, write | next_round, read}),
  .cmd_w_i  (cmd_write),
  .cmd_o    (sha512_state)
);

endmodule
