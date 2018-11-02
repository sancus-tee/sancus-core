module fifo (clk,
			fifo_enable,
			fifo_wr_rd,
			rst,
			full,
			empty,
			empty_partial,
			fifo_in,
			fifo_out,
			fifo_old_add_flag);
			
parameter DATA = 8;
parameter ADDR_SIZE = 4; //2^ADDR_SIZE = addressable words
parameter DIV_FACTOR = 3; //by default divide by 8 by 
parameter ADD_PARTIAL = (2**ADDR_SIZE) >> DIV_FACTOR;

//Inputs
input clk;
input fifo_enable; 
input fifo_wr_rd; //1: write || 0: read 
input rst;
input [DATA-1:0] fifo_in;
input fifo_old_add_flag;
//Outputs
output full;
output empty;
output empty_partial;
output [DATA-1:0] fifo_out;

//Internal Variables
wire [2**ADDR_SIZE-1:0] flag; 
wire [2**ADDR_SIZE-1:0] en_wire;
wire    [ADDR_SIZE-1:0] fifo_addr;
wire                    increment_wr;
wire                    increment_rd;
wire                    decoder_en;
`ifdef SIM | DMA_CONTR_TEST
wire [DATA:0] fifo_regs [2**ADDR_SIZE-1:0]; //DATA and not DATA-1 since 1 bit stores the read/write state of the reg
`endif
reg     [ADDR_SIZE-1:0] wr_addr;
reg     [ADDR_SIZE-1:0] rd_addr;
reg     [ADDR_SIZE-1:0] fifo_old_addr; 

//Generate Full or Empty signals
assign full = &flag;
assign empty = ~|flag;
assign empty_partial = ~|flag[ADD_PARTIAL-1:0];

//Instantiate the FIFO registers 
genvar gi;
generate for (gi=0; gi<2**ADDR_SIZE; gi=gi+1) begin : genregs
fifo_reg #(.REG_DEPTH(DATA)) fifo ( 
				.clk(clk),
				.reg_en(en_wire[gi] ), 
				.wr_rd(fifo_wr_rd),
				.data_in(fifo_in),
				.rst(rst),
				.data_out(fifo_out),
				`ifdef SIM 
				.register(fifo_regs[gi]), 
				`endif
				.flag(flag[gi]));
end 
endgenerate	

//Asynch. reset
always @(rst) begin
	if (rst == 1) begin
		wr_addr = 0;
		rd_addr = 0;
		fifo_old_addr = 0;
	end
end

//Update write and read addresses 
assign increment_wr = fifo_enable & fifo_wr_rd & ~full & ~fifo_old_add_flag;
assign increment_rd = fifo_enable & ~fifo_wr_rd & ~empty & ~fifo_old_add_flag;

always @(posedge clk) begin
		fifo_old_addr <= fifo_wr_rd ? wr_addr : 
						fifo_old_add_flag ? fifo_old_addr : rd_addr;
		wr_addr <= increment_wr ? wr_addr+1'b1 : wr_addr;
		rd_addr <= increment_rd ? rd_addr+1'b1 : rd_addr; 	
end

//Mux the read or write addresses
assign fifo_addr = fifo_old_add_flag ? fifo_old_addr :
					(fifo_wr_rd) ? wr_addr : rd_addr; 

//Decoder for enabling the right register
assign decoder_en = fifo_enable & ~(full & fifo_wr_rd) & ~(empty & ~fifo_wr_rd);
decoder #(.DIM(ADDR_SIZE)) address_decoder (.bin_in(fifo_addr), 
											.en(decoder_en),
											.out(en_wire));
											
//XXX Il fatto che il fifo_reg abbia un output non "clockato" fa sì che sia soggetto ad eventuali glitch del fifo_wr_rd_: magari devi farlo passare per un flip flop--> in tal caso, devi controllare che wr_rd sia asserito 1 colpo di clock prima del FIFO_EN. Vista la FSM del DMA_COTROLLER, non dovrebbe essere troppo difficile (forse già lo fa in realtà)
// Il fifo_reg non è soggetto a glitch dell'enable perchè l'enable arriva direttamente dal decoder che prende il 'fifo_add' pilotato dal 'flag_old_addr' che arriva direttamente dalla FSM del DMA_CONTROLLER, quindi sicuro; inoltre rd_addr e wr_addr sono clockati, quindi non soggetti a glitch particolari.  
																						
endmodule
