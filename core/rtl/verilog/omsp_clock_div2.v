module omsp_clock_div2(
  input  wire clk,
  input  wire rst,
  output reg  clk_div2
);

always @(posedge clk or posedge rst)
  if (rst)
    clk_div2 <= clk;
  else
    clk_div2 <= ~clk_div2;

endmodule
