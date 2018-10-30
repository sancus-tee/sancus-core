module decoder (bin_in, en, out);
parameter DIM = 8;
input [DIM-1:0] bin_in;
input en;
output [2**DIM-1:0] out;

assign out = (en) ? (1'b1 << bin_in) : {DIM{1'b0}};

endmodule

