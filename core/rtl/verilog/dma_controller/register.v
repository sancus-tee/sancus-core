module register (clk, reg_en, data_in, rst, data_out);
parameter REG_DEPTH = 16; // 16 bits words by default, regs[0:15] 
input clk;
input rst;
input reg_en;
input [REG_DEPTH-1:0] data_in;
output reg [REG_DEPTH-1:0] data_out; 

always @(rst)
begin
	if(rst) begin data_out <= 0; end
end	

always @(posedge clk)
begin
	//data_out <= {REG_DEPTH-1{1'bz}};
	if (reg_en) begin
		data_out <= data_in;
		//data_out <= (wr_rd==0) ? data_out : {REG_DEPTH-1{1'bz}};
	end else
		data_out <= data_out;
end

endmodule
