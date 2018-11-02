module fifo_reg_synch (
	clk,
	reg_en,
	wr_rd,
	data_in,
	rst,
	data_out,
	flag,
	`ifdef SIM register `endif	
);
parameter REG_DEPTH = 16; // 16 bits words by default, regs[0:15] 
input clk;
input wr_rd; // 1 for write, 0 for read
input rst;
input reg_en;
input [REG_DEPTH-1:0] data_in;
output reg [REG_DEPTH-1:0] data_out; 
output flag;
`ifdef SIM
	output reg [REG_DEPTH:0] register;   
`else
 //Internal variables
	reg [REG_DEPTH:0] register;
`endif

// reg's content is expanded with the Write_or_read bit, which informs if it has been written or read in the current operation

assign flag = register[REG_DEPTH];

always @(rst)
begin
	if(rst) begin register = 0; end
end	

always @(posedge clk)
begin
	data_out <= {REG_DEPTH{1'bz}};
	if (reg_en) begin
		register[REG_DEPTH] <= wr_rd;
		if (wr_rd==1) begin //write
			register[REG_DEPTH-1:0] <= data_in;
		end
		data_out <= (wr_rd==0) ? register[REG_DEPTH-1:0] : {REG_DEPTH{1'bz}};
	end
end


endmodule
