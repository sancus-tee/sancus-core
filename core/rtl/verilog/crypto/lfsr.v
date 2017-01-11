module lfsr #(
  parameter integer         LFSR_SIZE = 7,
  parameter [LFSR_SIZE:0]   LFSR_POLY = 8'b11000001,
  parameter [LFSR_SIZE-1:0] LFSR_INIT = 7'b1111010
) (
  input  wire                 clk,
  input  wire                 reset,
  input  wire                 enable,
  output reg  [LFSR_SIZE-1:0] data_out
);

integer i;

wire feedback = ^(data_out & LFSR_POLY[LFSR_SIZE:1]);

// generate
//   genvar gen_i;
//   wire feedback = 1'b0;
//
//   for (gen_i = 0; gen_i < LFSR_SIZE; gen_i = gen_i + 1)
//   begin : gen_for
//     if (LFSR_POLY[gen_i])
//     begin : gen_if
//       assign feedback = feedback ^ data_out[gen_i];
//     end
//   end
// endgenerate

`ifndef ASIC
  initial data_out = LFSR_INIT;
`endif

always @(posedge clk)
  if (reset)
    data_out <= LFSR_INIT;
  else if (enable)
    data_out <= { data_out[(LFSR_SIZE - 2):0], feedback };

endmodule
