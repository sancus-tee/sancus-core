module omsp_clock_div2(
  input  wire clk,
  input  wire rst,
  input  wire sync,

  output wire clk_div2
);

// initial clk_div2_tmp = 1'b0;

reg clk_div2_tmp;
always @(posedge clk or posedge rst)
  if (rst)
    clk_div2_tmp <= clk;
  else
    clk_div2_tmp <= ~clk_div2;

assign clk_div2 = !sync && clk_div2_tmp;

endmodule
