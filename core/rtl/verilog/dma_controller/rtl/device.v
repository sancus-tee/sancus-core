module device ( //Outputs to higher logic
				dev_ready,				
				//Outputs to DMA
				num_words,
				start_address,
				rd_wr,
				rqst,
				dev_ack,
				dev_out,
				//Inputs from higer logic
				clk,
				start,
				in_num_words,
				in_start_address,
				in_rd_wr,
				reset,
				//Inputs from DMA
				dma_ack,
				dev_in,
				dma_end_flag);
				
parameter DATA = 8;
parameter ADD = 7;
parameter WORD = 5;

// Outputs
output [WORD:0] 	num_words; 
output [ADD-1:0]	start_address;
output  			rd_wr;
output [DATA-1:0] 	dev_out;
output reg 			rqst;
output reg 			dev_ack;
output reg 			dev_ready;
// Inputs from DMA
input 				dma_ack;
input 				dma_end_flag;
input [DATA-1:0] 	dev_in;
// Inputs from higer logic
input 				clk;
input		 		start;
input [WORD:0] 		in_num_words; 
input [ADD-1:0] 	in_start_address;
input 				reset;
input 				in_rd_wr;


// Internal variables
reg start_add_en, start_add_rst; 
reg num_words_en, num_word_rst;
reg rd_wr_en, rd_wr_rst;
reg [DATA-1:0] out;

// Counter
//wire tc_flag;
//reg [WORD:0] count;
//reg count_en, count_rst;

// Error Flags
reg error_rd;
//reg error_wr; 

// Testbench 
integer i; //used to test wait states in read op.
wire tb_count_wait;

// FSM States Definition
`ifdef SIM
	reg [15*8:0] state, next_state; //states stored in ASCII 
`else
	reg [4:0]state, next_state; //just codifies the states
`endif

`ifdef SIM
localparam 	RESET = "RESET", 
			IDLE  = "IDLE ",
			GET_ADDRESS = "GET_ADDRESS",
			GENERATE_RQST = "GENERATE_RQST",
			//Read
			WAIT_RD_DATA = "WAIT_RD_DATA", 
			START_RECEIVING = "START_RECEIVING",
			GET_RD_DATA = "GET_RD_DATA",
			ERROR_RD = "ERROR_RD",
			END_READ = "END_READ",
			WAIT_RQ_RD = "WAIT_RQ_RD",
			WAIT_RD = "WAIT_RD",
			//Write
			TB_WAIT_WR = "TB_WAIT_WR", 
			START_SENDING = "START_SENDING",
			SEND_DATA = "SEND_DATA", 
			END_WRITE = "END_WRITE",
			DATA_WRITTEN = "DATA_WRITTEN",
			WAIT_RQ_WR = "WAIT_RQ_WR",
			WAIT_WR = "WAIT_WR",
			DMA_WRITING_MEM = "DMA_WRITING_MEM";
`else
localparam	RESET = 0, 
			IDLE  = 1,
			GET_ADDRESS = 2,
			GENERATE_RQST = 3,
			//Read
			WAIT_RD_DATA = 4, 
			START_RECEIVING = 18,
			GET_RD_DATA = 5,
			ERROR_RD = 7,
			END_READ = 6,
			WAIT_RQ_RD = 8,
			WAIT_RD = 9,
			//Write
			TB_WAIT_WR = 10,
			START_SENDING = 11,
			SEND_DATA =12,
			END_WRITE = 16,
			DATA_WRITTEN = 15,
			WAIT_RQ_WR = 13,
			WAIT_WR = 14,
			DMA_WRITING_MEM = 17;

`endif


always @(posedge clk) begin
			if (state == SEND_DATA) out <= ~out;			
end

// Output assignment
assign dev_out = out;

/*//Counter
always @(posedge clk) begin
	if (count_rst) count <= 'h0;
	else if (count_en) count <= count+1;
end
XXX Affinchè il device sia il più generale possibile, non si può assumere che esso abbia un counter che tenga traccia delle parole scritte, altrimenti sarebbe rindondante con il controllo che il DMA_CONTROLLER effettua già di suo, essendo LUI l'arbiter della situazione.
PErtanto si opta per lasciare tutto in mano al DMA, che ha potere decisionale e che controlla il semplice protocollo di comunicazione, consci del fatto che il DMA non può sbagliare, dovendo servire esclusivamente il device in questione, quindi impossibile che non abbia risorse disponibili per esso.*/

//assign tc_flag = (count == num_words);

//Insert Wait States in RD/WR op. 
always @(posedge clk) begin
	if ((state == GET_RD_DATA) | (state == SEND_DATA) | (state == WAIT_RD)) i = i+1;
end
assign tb_count_wait = (i == 4);


// ------------ FSM --------------------------------
//State Assignment
always @(posedge clk,posedge reset)	begin
	if (reset) state <= RESET; //Asynchronus reset			
	else state <= next_state;
end

// Next State Generation
always @(state, reset, start, dma_ack, rd_wr, tb_count_wait, dma_end_flag, i) begin
	case (state)
		RESET:
			next_state <= reset ? RESET : IDLE;
		IDLE:
			next_state <= start ? GET_ADDRESS : IDLE;
		GET_ADDRESS:
			next_state <= GENERATE_RQST;
		GENERATE_RQST:
			next_state <= dma_ack ? (rd_wr ? WAIT_RD_DATA : TB_WAIT_WR) : GENERATE_RQST; //OCCHIO QUI al rd_wr se è valid				
		//Read
		WAIT_RD_DATA:
			next_state <= dma_ack ? START_RECEIVING : WAIT_RD_DATA;
		START_RECEIVING: 
			next_state <= dma_ack ? GET_RD_DATA : START_RECEIVING;
		GET_RD_DATA:
			next_state <= dma_ack ? (tb_count_wait ? WAIT_RQ_RD : GET_RD_DATA) :
							(dma_end_flag ? END_READ : ERROR_RD);
		WAIT_RQ_RD:
			next_state <= WAIT_RD;
		WAIT_RD:
			next_state <= (i == 2) ? START_RECEIVING : WAIT_RD;
		ERROR_RD:
			next_state <= RESET;
		END_READ:
			next_state <= IDLE;
			
		//Write
		TB_WAIT_WR: 
			next_state <= START_SENDING;
		START_SENDING:
			next_state <= dma_ack ? SEND_DATA : START_SENDING;
		/*SEND_DATA: 
			next_state <= dma_ack ? (tb_count_wait ? WAIT_RQ_WR : SEND_DATA) : 
							tc_flag ? (dma_end_flag ? END_WRITE : DMA_WRITING_MEM) : ERROR_WR;*/
		SEND_DATA:
			next_state <= dma_ack ? (tb_count_wait ? WAIT_RQ_WR : SEND_DATA) : DATA_WRITTEN;						  
		WAIT_RQ_WR:
			next_state <= WAIT_WR;
		WAIT_WR:
			next_state <= START_SENDING; //SEND_DATA;
		DATA_WRITTEN:
			next_state <=  dma_end_flag ? END_WRITE : DMA_WRITING_MEM;		
		DMA_WRITING_MEM:
			next_state <= dma_end_flag ? END_WRITE : DMA_WRITING_MEM;
		END_WRITE:
			next_state <= IDLE;
	endcase
end


//Control Signals Generation
always @(state) begin
	//Default
	
	//count_en <= 1'b0;
	//count_rst <= 1'b0;
	dev_ack <= 1'b0;
	dev_ready <= 1'b0;
	//error_wr <= 1'b0;
	error_rd <= 1'b0;
	out <= 'hz;
	num_words_en <= 1'b0;
	num_word_rst <= 1'b0;
	rd_wr_en <= 1'b0;
	rd_wr_rst <= 1'b0;
	rqst <= 1'b0;
	start_add_en <= 1'b0;
	start_add_rst <= 1'b0;
	
	
	case(state) 
		RESET:
		begin
			start_add_rst <= 1'b1;
			num_word_rst <= 1'b1;
			rd_wr_rst <= 1'b1;
			//count_rst <= 1'b1;
			i = 0;
		end
		IDLE: 
		begin
			;
		end
		GET_ADDRESS:
		begin
			num_words_en <= 1'b1;
			start_add_en <= 1'b1;
			rd_wr_en <= 1'b1;
		end	
		GENERATE_RQST:
		begin
			rqst <= 1'b1;
		end
		WAIT_RD_DATA:
		begin	
			// NOP, wait data from DMA controller
		end
		START_RECEIVING:
		begin
			dev_ack <= 1'b1;
		end		
		GET_RD_DATA:
		begin
			dev_ack <= 1'b1;
		end
		WAIT_RQ_RD:
		begin
			i = 0;
		end
		WAIT_RD:
		begin
			//i = 0;
		end
		ERROR_RD: 
		begin
			$display("DEV: %2s at %2d",state,$time);
			error_rd <= 1'b1;
		end
		END_READ: 
		begin
			$display("DEV: %2s at %2d",state,$time);
			dev_ready <= 1'b1;
		end
		//Write
		TB_WAIT_WR:
		begin
			//count <= 'b1; //to properly count the words written to FIFO on the posedge clk
			out <= 'h0A; //setting the output
		end
		START_SENDING:
		begin
			//rqst <= 1'b1;
			dev_ack <= 1'b1;
			out <= ~out;	
		end
		SEND_DATA: 
		begin
			dev_ack <= 1'b1;
			//count_en <= 1'b1;
			out <= ~out;
		end
		WAIT_RQ_WR:
		begin
			i = 0;
			out <= out; //keep output stable
			//count_en <= 1'b1; //correctly keep count of the sampled data 
		end
		WAIT_WR:
		begin
			i = 0; 
			out <= out; //keep output stable
		end
		DMA_WRITING_MEM: ;//NOP
		DATA_WRITTEN: ; //NOP
		END_WRITE:
		begin
			$display("DEV: %2s at %2d",state,$time);
			dev_ready <= 1'b1;
		end
	endcase
end

//Instantiation
register #(.REG_DEPTH(WORD+1)) num_word (
				.clk(clk),
				.reg_en(num_words_en),
				.data_in(in_num_words),
				.rst(num_word_rst),
				.data_out(num_words));

register #(.REG_DEPTH(WORD+1)) address0 (
				.clk(clk),
				.reg_en(start_add_en),
				.data_in(in_start_address),
				.rst(start_add_rst),
				.data_out(start_address));

register #(.REG_DEPTH(1)) read_write_reg (
				.clk(clk),
				.reg_en(rd_wr_en),
				.data_in(in_rd_wr),
				.rst(rd_wr_rst),
				.data_out(rd_wr));

endmodule
