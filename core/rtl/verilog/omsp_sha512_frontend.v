module omsp_sha512_frontend(
  input  wire        clk,
  input  wire        rst,
  input  wire  [1:0] cmd_in,
  input  wire [15:0] data,
  input  wire        data_size,

  output wire [15:0] hash,
  output wire        busy,
  output wire        ready_for_data
);

wire read, write;
assign read  = cmd_in[0];
assign write = cmd_in[1];

wire sha512_clk;
omsp_clock_div2 clock_div2(
  .clk      (clk),
  .rst      (rst),
  .sync     (first_write),
  .clk_div2 (sha512_clk)
);

reg data_shift_enable;
always @(posedge clk or posedge rst)
  if (rst)
    data_shift_enable <= 1'b0;
  else
    data_shift_enable <= cmd_in[1];

// the write signal is always 1 cycle behind, write_cycle is a synced version
reg write_cycle;
always @(posedge clk or posedge rst)
  write_cycle <= write;

reg [15:0] sha512_data_in;
always @(*)
  if (write_cycle)
    sha512_data_in = data_size ? data : {data[7:0], 8'b0};
  else
    sha512_data_in = 16'b0;

wire [31:0] sha512_data;
omsp_shift_16to32 data_shift(
  .clk      (clk),
  .rst      (rst),
  .enabled  (data_shift_enable),
  .data_in  (sha512_data_in),
  .data_out (sha512_data)
);

reg hash_shift_enable;
always @(posedge clk or posedge rst)
  if (rst)
    hash_shift_enable <= 1'b0;
  else
    hash_shift_enable <= read;

wire [31:0] sha512_hash;
omsp_shift_32to16 hash_shift(
  .clk      (sha512_clk),
  .data_in  (sha512_hash),
  .data_out (hash)
);

reg [1:0] prev_data_sizes;
always @(posedge clk or posedge rst)
  if (rst || first_write)
    prev_data_sizes <= 2'b00;
  else if (write_cycle)
    if (prev_data_sizes == 2'b11)
      prev_data_sizes <= {1'b0, data_size};
    else
      prev_data_sizes <= {prev_data_sizes[0], data_size};

reg [1:0] sha512_data_size;
always @(posedge sha512_clk or posedge rst)
  if (rst)
    sha512_data_size <= 2'b0;
  else
    sha512_data_size <= prev_data_sizes;

reg [1:0] sha512_cmd, sha512_cmd_next;
always @(posedge clk or posedge rst)
  if (rst)
    sha512_cmd_next <= 2'b0;
  else if ((cmd_in != sha512_cmd) && (ready_for_data || !busy))
    sha512_cmd_next <= cmd_in;

always @(posedge sha512_clk or posedge rst)
  if (rst)
    sha512_cmd <= 2'b0;
  else
    sha512_cmd <= sha512_cmd_next;

wire first_write;
assign first_write = write && !write_cycle;

wire sha512_ready_for_data;
reg  ready_for_data_start;
always @(posedge clk or posedge rst)
  if (rst)
    ready_for_data_start <= 1'b0;
  else if (first_write)
    ready_for_data_start <= 1'b1;
  else if (sha512_ready_for_data)
    ready_for_data_start <= 1'b0;

assign ready_for_data = ready_for_data_start  ||
                        sha512_ready_for_data ||
                        first_write;

wire sha512_busy;
reg  busy_start;
always @(posedge clk or posedge rst)
  if (rst)
    busy_start <= 1'b0;
  else if (first_write)
    busy_start <= 1'b1;
  else if (sha512_busy)
    busy_start <= 1'b0;

assign busy = busy_start || sha512_busy;

omsp_sha512_padder sha512_padder(
  .clk            (sha512_clk),
  .rst            (rst),
  .cmd_in         (sha512_cmd),
  .data           (sha512_data),
  .data_size      (sha512_data_size),

  .hash           (sha512_hash),
  .busy           (sha512_busy),
  .ready_for_data (sha512_ready_for_data)
);

endmodule
