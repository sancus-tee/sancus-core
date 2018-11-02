module dma_controller ( 
	clk,
	reset,
	// Inputs from Device
	num_words,
	start_addr,
	rd_wr,
	rqst,
	dev_ack,
	dev_in,
	// Outputs to Device
	dma_ack,
	dev_out,
	end_flag,
	
	// Inputs from OpenMSP430
	dma_in,
	dma_ready, 
	dma_resp,
	// Outputs to OpenMSP430
	dma_addr,
	dma_out,
	dma_en,
	dma_priority,
	dma_we
);

initial begin
`ifdef SIM $display("DMA: Simulation acquired at %2d",$time) `endif;
end

parameter ADD_LEN = 16; // Number of bits for the addresses
parameter DATA_LEN = 16; // Number of bits for the data
parameter FIFO_DEPTH = 5; //2^FIFO_DEPTH = regs in the FIFO.
parameter FIFO_DIV_FACTOR = 3; //by default divide by 8

input clk, reset;

//-------Device interface ------//
input [FIFO_DEPTH-1:0] num_words;	//I should be able to write at max. as many words as the fifo can handle (=2^FIFO_DEPTH words),
								//which you write onto FIFO_DEPTH bits.
								//Or num_words can bigger and let FIFO_FULL FSM-branch handle the situation.It's up to you.
input [ADD_LEN-1:0] start_addr;
input rd_wr;
input rqst;
input dev_ack;
input [DATA_LEN-1:0] dev_in;
output [DATA_LEN-1:0] dev_out;
output reg dma_ack;
output reg end_flag;

//-------OpenMSP430 interface----//
input [DATA_LEN-1:0] dma_in;
input dma_ready;
input dma_resp;
output [ADD_LEN-1:0] dma_addr;
output [DATA_LEN-1:0] dma_out;
output reg dma_en;
output reg dma_priority; 
output reg [1:0] dma_we;


//--------------------------------//
//--------------------------------//
//  Internal variables and wires  //
//--------------------------------//
//--------------------------------//
//Fifo
wire fifo_full, fifo_empty, fifo_empty_partial;
wire [DATA_LEN-1:0] fifo_out, fifo_in;
reg fifo_rst, fifo_old_add_flag;
reg fifo_en, fifo_wr_rd;
//Address register 
wire [ADD_LEN-1:0] start_address;
wire [ADD_LEN-1:0] address;
reg addr0_rst, addr0_reg_en;
//Old Address register
wire [ADD_LEN-1:0] old_address;
reg old_addr_reg_en, old_addr_rst;
//Flip-flop Mux Add
reg mux;
//Num_words register
wire [FIFO_DEPTH-1:0] words;
reg words_rst, words_reg_en;
//Counter
wire end_count;
wire [FIFO_DEPTH-1:0] count;	
wire [FIFO_DEPTH-1:0] count_in;	
reg count_rst, count_en;
wire count_en_1;
reg count_load;
//FSM control logic  
reg flag_cnt_words; //end-count for the FSM
reg msp_or_dev; //1: FIFO out to DMA || 0: FIFO out to DEV
reg error_flag;  
reg drive_dma_addr; //0: dma_addr = 'hz || 1: dma_addr


//FSM States Definition
reg [4:0] state, next_state; // codifies the states

localparam 	IDLE  = 0,
			GET_REGS  = 1,
			// Read
			LOAD_DMA_ADD = 2,
			READ_MEM  = 3,
			ERROR  = 4,
			OLD_ADDR_RD  = 5,
			SEND_TO_DEV0  = 6,
			WAIT_READ  = 7,
			SEND_TO_DEV1  = 8,
			NOP  = 9,
			END_READ  = 10,
			//Write
			READ_DEV0  = 11,
			READ_DEV1  = 12,
			WAIT_WRITE  = 13,
			SEND_TO_MEM0  = 14,
			SEND_TO_MEM1  = 15,
			OLD_ADDR_WR  = 16,
			END_WRITE  = 17,
			// Fifo full
			FIFO_FULL_READ  = 18,
			EMPTY_FIFO_READ  = 19,
			RESET  = 20;

//--------------------------------//
//--------------------------------//
//  		Datapath			  //
//--------------------------------//
//--------------------------------//

//Mux fifo in's and out's
assign dma_out = msp_or_dev ? fifo_out : {DATA_LEN{1'bz}};
assign dev_out = msp_or_dev ? {DATA_LEN{1'bz}} : fifo_out;
assign fifo_in = msp_or_dev ? dev_in : dma_in;

fifo #(	.DATA(DATA_LEN), 
		.ADDR_SIZE(FIFO_DEPTH),
		.DIV_FACTOR(FIFO_DIV_FACTOR)) fifo_mem (
		.clk(clk), 
		.fifo_enable(fifo_en),
		.fifo_wr_rd(fifo_wr_rd),
		.rst(fifo_rst),
		.full(fifo_full),
		.empty(fifo_empty),
		.empty_partial(fifo_empty_partial),
		.fifo_in(fifo_in), 
		.fifo_out(fifo_out),
		.fifo_old_add_flag(fifo_old_add_flag));

//DMA's internal registers
register #(.REG_DEPTH(FIFO_DEPTH)) word0 (
				.clk(clk),
				.reg_en(words_reg_en),
				.data_in(num_words),
				.rst(words_rst),
				.data_out(words));

register #(.REG_DEPTH(ADD_LEN)) addr0 (
				.clk(clk),
				.reg_en(addr0_reg_en),
				.data_in(start_addr),
				.rst(addr0_rst),
				.data_out(start_address));
				
register #(.REG_DEPTH(ADD_LEN)) old_addr0 (
				.clk(clk),
				.reg_en(old_addr_reg_en),
				.data_in(address),
				.rst(old_addr_rst),
				.data_out(old_address));

								
assign address = start_address + count;
assign dma_addr = drive_dma_addr ? ( mux ? old_address : address) :
					{ADD_LEN{1'bz}};

//Counter
assign count_en_1 = count_en | ((state == LOAD_DMA_ADD) & (next_state == READ_MEM));
//XXX È un po' una suinata ma è la cosa più semplice che ho trovato! Alla fine si trattava di gestire un solo maledetto caso, quindi ho scelto di fare l'hardware ad-hoc. Sono pure due stati consecutivi, quindi hanno solo l'ultimo bit diverso! Vuol dire che solo per l'ultimo bit ho bisogno di 2 AND gate, per gli altri possono essere condivisi.

counter #(.L(FIFO_DEPTH)) count0 (
	.clk(clk),
	.load(count_load),
	.rst(count_rst),
	.cnt_en(count_en_1),
	.data_in({{FIFO_DEPTH-1{1'b0}},1'b1}), //necessary for write states, where you need to count 1 time less: the idea is to make the counter start from 1 instead of 0.
	.cnt(count),
	.end_cnt(end_count));

always @(count,words) begin
	flag_cnt_words = (count == words); //NON words-1 PERCHÈ IL CONTEGGIO È FATTO SUL TERZO COLPO DI CLOCK in lettura
end	

//State Assignment
always @(posedge clk,posedge reset)	begin
	if (reset) begin
		state <= RESET; //Asynchronus reset	
		next_state <= RESET;
	end	else state <= next_state;
end

//Next State Generation
always @(state, rqst, rd_wr, dma_ready, fifo_full, dma_resp, flag_cnt_words, flag_cnt_words, dev_ack, fifo_empty_partial, reset) begin
		next_state <= IDLE; //default
		case (state)
			RESET :
				next_state <= reset ? RESET : IDLE;
			IDLE : 		
				next_state <= rqst ? GET_REGS : IDLE;
			GET_REGS : 
				next_state <= rd_wr ? LOAD_DMA_ADD : READ_DEV0;
			//Read 
			LOAD_DMA_ADD :
				next_state <= dma_ready ? READ_MEM : LOAD_DMA_ADD;
			READ_MEM :
				next_state <= dma_resp? ERROR : 
							fifo_full ? FIFO_FULL_READ :
							flag_cnt_words ? SEND_TO_DEV0 :
							dma_ready ? READ_MEM : OLD_ADDR_RD;
			OLD_ADDR_RD : 
				next_state <= dma_ready ? READ_MEM : OLD_ADDR_RD;
			ERROR :
				next_state <= END_READ; //FIXME check!	
			SEND_TO_DEV0 :
				next_state <= dev_ack ? SEND_TO_DEV1 : WAIT_READ;
			WAIT_READ :
				next_state <= dev_ack ? SEND_TO_DEV1 : WAIT_READ;				
			SEND_TO_DEV1 :
				next_state <= flag_cnt_words ? END_READ : (dev_ack ? SEND_TO_DEV1 : NOP);
			NOP :
				next_state <= dev_ack ? SEND_TO_DEV1 : NOP;
			END_READ :
				next_state <= IDLE;
			// Write
			READ_DEV0 :
				next_state <= dev_ack ? READ_DEV1 : READ_DEV0;
			READ_DEV1 :
				next_state <= flag_cnt_words ? SEND_TO_MEM0 : (dev_ack ? READ_DEV1 : WAIT_WRITE);
			WAIT_WRITE :
				next_state <= dev_ack ? READ_DEV1 : WAIT_WRITE;
			SEND_TO_MEM0 :
				next_state <= SEND_TO_MEM1;
			SEND_TO_MEM1 :
				next_state <= dma_resp ? ERROR : 
							flag_cnt_words ? END_WRITE :
							dma_ready ? SEND_TO_MEM1 : OLD_ADDR_WR;
			OLD_ADDR_WR :
				next_state <= dma_ready ? SEND_TO_MEM1 : OLD_ADDR_WR ;
			END_WRITE : 
				next_state <= IDLE;
			// Fifo full
			FIFO_FULL_READ : 
				next_state <= dev_ack ? EMPTY_FIFO_READ : FIFO_FULL_READ;
			EMPTY_FIFO_READ :
			next_state <= fifo_empty_partial ? READ_MEM : 
							dev_ack ? EMPTY_FIFO_READ : FIFO_FULL_READ;
		endcase
end

//Control Signals Generation
always @(state) begin
	//default
	addr0_reg_en <= 1'b0;
	addr0_rst <= 1'b0;	
	count_en <= 1'b0;
	count_load<= 1'b0;
	count_rst <= 1'b0;
	dma_ack <= 1'b0;
	dma_en <= 1'b0;
	msp_or_dev <= 1'b0;
	dma_priority <= 1'b0;
	dma_we  <= 2'b00;
	drive_dma_addr <= 1'b0;
	end_flag <= 1'b0;
	error_flag <= 1'b0;
	fifo_en <= 1'b0;
	fifo_rst <= 1'b0;
	fifo_wr_rd <= 1'b0;
	fifo_old_add_flag <= 1'b0;
	mux <= 1'b0;
	old_addr_reg_en <= 1'b0;
	old_addr_rst <= 1'b0;
	words_reg_en <= 1'b0;
	words_rst <= 1'b0;
	
	case (state)		
		RESET : 
		begin
			fifo_rst <= 1'b1;
			addr0_rst <= 1'b1;
			old_addr_rst <= 1'b1;
			count_rst <= 1'b1;
			fifo_rst <= 1'b1; 
			words_rst <= 1'b1;
		end
		IDLE : 
		begin
			count_rst <= 1'b1;	
			fifo_rst <= 1'b1;//XXX controlla: secondo me in IDLE ci sta svuotare la FIFO e resettare i WR_ADDR e RD_ADDR, no?
			addr0_rst <= 1'b1;
			words_rst <= 1'b1;
		end
		GET_REGS : 
		begin
			addr0_reg_en <= 1'b1;
			words_reg_en <= 1'b1;
			`ifdef SIM 
			dma_ack <= 1'b1; // signal "rqst aquired" to DEV
			`endif
		end
		//Read 
		LOAD_DMA_ADD :  
		begin
			fifo_wr_rd <= 1'b1;
			dma_en <= 1'b1; // needed to generate dma_ready (#171 in memory_backbone)
			drive_dma_addr <= 1'b1;
		end
		READ_MEM : 
		begin
			dma_en <= 1'b1;
			drive_dma_addr <= 1'b1;
			fifo_en <= 1'b1;
			fifo_wr_rd <= 1'b1;
			count_en <= 1'b1;
			old_addr_reg_en <= 1'b1;
		end
		OLD_ADDR_RD:
		begin
			mux <= 1'b1;
			fifo_old_add_flag <= 1'b1;
			fifo_wr_rd <= 1'b1;
			dma_en <= 1'b1;
			drive_dma_addr <= 1'b1;
		end
		ERROR :
		begin
			error_flag <= 1'b1;
			drive_dma_addr <= 1'b1;
		end
		SEND_TO_DEV0 : 
		begin
			count_rst <= 1'b1;
			`ifdef SIM 
			dma_ack <= 1'b1; // signal "rqst aquired" to DEV
			`endif
		end
		WAIT_READ :
		begin
			//NOP: it's not important to signal the DMA request, since the DMA is the master! Every time dev_ack goes LOW, device will say when it's ready again, then it will re-synch again passing by its synchronization 'START_READING' state. 
			//Furthermore, dma_ack will be used as "data_valid" flag and now the avaiabla data is not valid at all
		end
		SEND_TO_DEV1 :
		begin
			count_en <= 1'b1;
			fifo_en <= 1'b1;
			dma_ack <= 1'b1;
		end
		NOP : ;//dma_ack <= 1'b1;
		END_READ : 
		begin
			end_flag <= 1'b1;
		end
		// Write
		READ_DEV0 :
		begin
			count_en <= 1'b1; //this count_en is here only to 
			count_load <= 1'b1; //enable the this load!
			msp_or_dev <= 1'b1;
			fifo_wr_rd <= 1'b1;			
		end
		READ_DEV1 :
		begin
			msp_or_dev <= 1'b1;
			fifo_wr_rd <= 1'b1;
			fifo_en <= 1'b1;
			dma_ack <= 1'b1;
			count_en <= 1'b1;
		end
		WAIT_WRITE :
		begin
			msp_or_dev <= 1'b1;
			fifo_wr_rd <= 1'b1;
		end
		SEND_TO_MEM0 :
		begin
			count_rst <= 1'b1;
			dma_we <= 2'b11;
			msp_or_dev <= 1'b1;
			drive_dma_addr <= 1'b1;
		end
		SEND_TO_MEM1 :
		begin
			count_en <= 1'b1;
			dma_en <= 1'b1;
			msp_or_dev <= 1'b1;
			dma_we <= 2'b11;
			drive_dma_addr <= 1'b1;
			fifo_en <= 1'b1;		
			old_addr_reg_en <= 1'b1;
		end
		OLD_ADDR_WR :
		begin
			mux <= 1'b1; 
			dma_en <= 1'b1;
			msp_or_dev <= 1'b1;
			dma_we <= 2'b11;
			drive_dma_addr <= 1'b1;
			fifo_en <= 1'b1;
			fifo_old_add_flag <= 1'b1;
		end
		END_WRITE : 
		begin
			msp_or_dev <= 1'b1; //to correctly write the last data
			drive_dma_addr <= 1'b1;
			end_flag <= 1'b1;
		end
		// Fifo full
		FIFO_FULL_READ : 
		begin
			dma_ack <= 1'b1;
			dma_en <= 1'b1;
		end
		EMPTY_FIFO_READ :
		begin
			fifo_en <= 1'b1;
		end
		endcase	
end

`ifdef SIM
always @(posedge clk) begin
	$display("DMA: %2s at %2d",state,$time);
	//$display("\t --> Next State %1s",next_state);
end
always @(dev_in) begin
	$display("DMA: Received '%1d' at %2d",dev_in,$time);
end
`endif

	
endmodule 
