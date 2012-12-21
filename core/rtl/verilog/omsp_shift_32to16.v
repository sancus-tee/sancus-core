module omsp_shift_32to16(
  input  wire        select,
  input  wire [31:0] data_in,
  output wire [15:0] data_out
);

assign data_out = select ? data_in[31:16] : data_in[15:0];

endmodule
