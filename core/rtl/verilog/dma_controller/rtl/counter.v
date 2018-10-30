module counter (clk, cnt_en, load, data_in, rst, cnt,end_cnt);
parameter L = 8; // cnt[0:7] 

input clk;
input load;
input rst;
input cnt_en;
input [L-1:0] data_in;
output reg [L-1:0] cnt; 
output end_cnt;

always @(rst)
begin
	if (rst) begin cnt = 0; end
end	

always @(posedge clk)
begin
	if (cnt_en) begin
		cnt <= load ? data_in : cnt+1;
	end
end

assign end_cnt = &cnt;

endmodule
