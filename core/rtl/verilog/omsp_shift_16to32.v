module omsp_shift_16to32(
  input  wire        clk,
  input  wire        rst,
  input  wire        enabled,
  input  wire [15:0] data_in,
  output reg  [31:0] data_out
);

`define FIRST  1'b0
`define SECOND 1'b1

reg state;
always @(posedge clk or posedge rst)
  if (rst)
    state <= `FIRST;
  else if (state == `FIRST && enabled)
    state <= `SECOND;
  else
    state <= `FIRST;

reg [15:0] tmp;
always @(posedge clk or posedge rst)
  if (rst)
    tmp <= 16'b0;
  else if (state == `FIRST)
    tmp <= data_in;

always @(posedge clk or posedge rst)
  if (rst)
    data_out <= 32'b0;
  else if (state == `SECOND)
    data_out <= {tmp, data_in};

endmodule
