`include "timescale.v"
`define SIM

module dma_controller_tb ();

parameter ADD = 5;
parameter DATA = 8;
parameter FIFO = 4;
parameter FIFO_DIV_FACTOR = 3; //divide by 2^FIFO_DIV_FACTOR
localparam FILL_FIFO = 2**FIFO;

//Inputs from the Device
wire rdWr_out, Rqst, devAck;
wire [DATA-1:0] devOut;
wire [ADD-1:0] startAddress_out;
wire [FIFO:0] numWords_out;
wire devReady;
reg clk, reset;

//Inputs from OpenMSP430
wire [DATA-1:0] dmaOut;
wire dmaReady, dmaResp;

//Outputs to Device
reg [ADD-1:0] startAddress;
reg [FIFO:0] numWords;
wire dmaAck, endFlag;
wire [DATA-1:0] devIn;
reg start_device; 

//Outputs to OpenMSP430
wire [ADD-1:0] dmaAddr;
wire [DATA-1:0] dmaDin; 
wire dmaEn, dmaPriority;
wire [1:0] dmaWe;
reg start_msp;
reg rdWr;

initial 
begin 
	$display("SIM: Testbench started at %2d", $time);
	$dumpfile("gtk_views/dma_controller_tb.vcd");
	$dumpvars(0,dma_controller_tb);
	clk = 0;
	startAddress = 0;
	//numWords = FILL_FIFO-1;
	numWords = 1;
	start_device = 1'b0;
	reset = 1'b0;
	#1 start_msp = 1'b1;
	reset = 1'b1;
	rdWr = 1'b1; //Test read
	start_device = 1'b1;
	#1 reset = 1'b0;
	#4 start_device = 1'b0;
	@(posedge devReady) $display("Finished 1!!!!!!!!!!!!!!!!!!!!");
	rdWr = 1'b0; //Test write
	start_device = 1'b1;
	@(posedge devReady) #7 $finish;
end

//Clock generation
always #1 clk = ~clk;

device #(	.ADD(ADD),
			.DATA(DATA),
			.WORD(FIFO)) 		device_dut ( 
			//Inputs from DMA
			.dma_ack(dmaAck),
			.dev_in(devIn),
			.dma_end_flag(endFlag),
			//Inputs from higer logic
			.clk(clk), //device is sequential
			.start(start_device),
			.in_num_words(numWords),
			.in_start_address(startAddress),
			.in_rd_wr(rdWr),
			.reset(reset),
			//Outputs to DMA
			.num_words(numWords_out),
			.start_address(startAddress_out),
			.rd_wr(rdWr_out),
			.rqst(Rqst),
			.dev_ack(devAck),
			.dev_out(devOut),
			//Outputs to higher logic
			.dev_ready(devReady));
				
				
				
dma_controller #(	.ADD_LEN(ADD),
					.DATA_LEN(DATA),
					.FIFO_DEPTH(FIFO),//2^FIFO_DEPTH regs
					.FIFO_DIV_FACTOR(FIFO_DIV_FACTOR))	dut ( 
			.clk(clk),
			.reset(reset),
			// Inputs from Device
			.rd_wr(rdWr_out),
			.rqst(Rqst),
			.dev_ack(devAck),
			.dev_in(devOut),
			// Outputs to Device
			.num_words(numWords_out),
			.dev_addr(startAddress_out),
			.dma_ack(dmaAck),
			.dev_out(devIn),
			.end_flag(endFlag),
			// Inputs from OpenMSP430
			.dma_in(dmaOut),
			.dma_ready(dmaReady), 
			.dma_resp(dmaResp),
			// Outputs to OpenMSP430
			.dma_addr(dmaAddr),
			.dma_out(dmaDin),
			.dma_en(dmaEn),
			.dma_priority(dmaPriority),
			.dma_we(dmaWe));



MSP430_sim #(	.ADD(ADD),
				.DATA(DATA)) 	msp_dut ( 
			//Outputs to DMA
			.dma_out(dmaOut),
			.dma_ready(dmaReady), 
			.dma_resp(dmaResp),
			 //Inputs from DMA
			.dma_addr(dmaAddr),
			.dma_din(dmaDin),
			.dma_en(dmaEn),
			.dma_priority(dmaPriority),
			.dma_we(dmaWe),
			.clk(clk),
			.reset(reset));


endmodule
