// MSP430_sim with DMA_READY always READY memory write operation
// Used in combo with FIFO_REG_SYNCH it shows the error induced by the synchronous FIFO_REG, hence the need for an asynch. one.


module MSP430_sim ( 
			//Outputs to DMA
			dma_out,
			dma_ready, 
			dma_resp,
			//Inputs from DMA
			dma_addr,
			dma_din,
			dma_en,
			dma_priority,
			dma_we,
			clk,
			reset);

parameter DATA = 6;
parameter ADD= 2;

output reg [DATA-1:0] dma_out;
output reg dma_ready, dma_resp;
input [ADD-1:0] dma_addr;
input [DATA-1:0] dma_din; 
input dma_en, dma_priority, clk, reset;
input [1:0] dma_we;

//Internal Variables
wire tc_rd, tc_wr;
reg [2:0] count;
reg [DATA-1:0] out;
reg [7*8+2*DATA-1:0] received_data;
reg [2*8-1:0] asci_dma_din; //to nicely write info in the testbench
integer flag_first_read_entrance;
//FSM States definition
reg [15*8:0] state, next_state; //states stored in ASCII 

localparam 	RESET  = "RESET ",
			WAIT_ADDR = "WAIT_ADDR",
			READ = "READ",
			WAIT_READ = "WAIT_READ",
			WRITE = "WRITE",
			WAIT_WRITE = "WAIT_WRITE";

always @(dma_addr) begin
	case (dma_addr)
		'h00: out <='h20;
		'h01: out <='h21;
		'h02: out <='h22;
		'h03: out <='h23;
		'h04: out <='h24;
		'h05: out <='h25;
		'h06: out <='h26;
		'h07: out <='h27;
		'h08: out <='h28;
		'h09: out <='h29;
		'h0A: out <='h30;
		'h0B: out <='h31;
		'h0C: out <='h32;
		'h0D: out <='h33;
		'h0E: out <='h34;
		'h0F: out <='h35;
		default: out <= 'hz;
	endcase
end
			
//State Assignment
always @(posedge clk, posedge reset)	begin
	if (reset) state <= RESET; //Asynchronus reset			
	else state <= next_state;
end

//Next state generation
always @(reset, dma_en, dma_we, dma_addr, tc_rd, tc_wr) begin
	case (state)
		RESET:
			next_state <= WAIT_ADDR;
		WAIT_ADDR:	
			next_state <= dma_en ? (dma_we == 2'b00 ? READ : WRITE) : WAIT_ADDR;	
		READ:	
			next_state <= dma_en ? (tc_rd ? WAIT_READ : READ) :
							RESET;
		WAIT_READ:	
			next_state <= dma_en ? (tc_rd ? READ : WAIT_READ) :
							RESET;
		WRITE: 
			next_state <=  dma_en ? (tc_wr ? WAIT_WRITE : WRITE) :
							RESET;
		WAIT_WRITE:
			next_state <= dma_en ? (tc_wr ? WRITE : WAIT_WRITE) :
							RESET;
	endcase
end			

//End count flag
assign tc_rd = (count == 3'b100); // generate different duration
assign tc_wr = (count == 3'b011); // WAIT states

always @(state, posedge clk) begin
	count <= count;
	dma_ready <= 1'b0;
	dma_resp <= 1'b0;
	dma_out <= 'hz;
		
	case (state)
		RESET:
			begin
			count <= 'h0;
			dma_out <= 'hz;
			flag_first_read_entrance = 1;
			//dma_ready <= 1'b1; //Always ready|| CHANGE IT WHEN YOU DO NOT WANT IT TO BE ALWAYS READY
			end
		WAIT_ADDR: count <= 'h0; 
		READ:
			begin	
			$display("MSP: %2s at %2d",state,$time);
			dma_ready <= 1'b1;
			count <= count+1;
			dma_out <= flag_first_read_entrance ? 'bz : out;
			flag_first_read_entrance <= 0; // it's just the openMSP behavior. Infact openMSP dma_ready is combinatorially signalling that the output data is valid. This flag enhance to internally fake the combinatorial logic: without this flag it would appear that the MSP_OUT is driven at the same moment dma_ready is driven high, which is not what happen according to the opneMSP protocol. In fact openMSP outputr should be asserted only on the next clock edge AFTER dma_ready is asserted. 
//Basically this flag is used to just handle the FIRST data out. 
			end
		WAIT_READ:
			begin
			count <= count+1;
			dma_out <= out;
			end	
		WRITE:
			begin
				dma_ready <= 1'b1;
				count <= count+1;
			end	
		WAIT_WRITE:
			begin
				count <= count+1;
			end
	endcase
end

always @(posedge clk) begin
	received_data <= 'hz;
	if (state == WAIT_READ) dma_out <= 'hz;
	if (dma_en) begin
		if (dma_ready == 1'b1) received_data <= {"DATA ",asci_dma_din};
		else received_data <= {"NOT READY"};
	end else received_data <= {"OFF"};
	
	if ((tc_wr)&(dma_we == 2'b11)) count <= 'b0;
end

always @(dma_din) begin
	case (dma_din)
	'hF5:
		asci_dma_din <= "FA";
	'h0A:
		asci_dma_din <= "0A";
	'hz:
		asci_dma_din <= "ZZ";
	default: 
		asci_dma_din <= "XX";
	endcase
end

endmodule
