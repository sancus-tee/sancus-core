module  simple_dma_device (

// OUTPUTs to uP 
    per_dout,			// Peripheral data output
// OUTPUTs to DMA
	dev_ack,			// Ackowledge for the 2-phase handshake
	dev_out,			// Output to DMA in write op.
	dma_num_words,		// Number of words to be read
	dma_rd_wr,			// Read or write request
	dma_rqst,			// DMA op. request
	dma_start_address,  // Starting address for DMA op.
// INPUTs from uP
    clk,				// Main system clock
    per_addr,			// Peripheral address
    per_din, 			// Peripheral data input
    per_en,				// Peripheral enable (high active)
    per_we,				// Peripheral write enable (high active)
    reset,				// Main system reset
// INPUTs from DMA
	dev_in,
	dma_ack,
	dma_end_flag
);


// OUTPUTs
//===================
// OUTPUTs to uP 
output		[15:0] 		per_dout;			// Peripheral data output
// OUTPUTs to DMA
output					dev_ack;			// Ackowledge for the 2-phase handshake
output			[15:0] 	dev_out;			// Data to DMA Controller
output			[15:0]	dma_num_words;		// Number of words to be read
output 					dma_rd_wr;			// Read or write request
output					dma_rqst;			// DMA op. request
output			[15:0]	dma_start_address;	// Starting address for DMA op.
	
// INPUTs
//===================
// INPUTs from uP
input					clk;			// Main system clock
input			[13:0]	per_addr;		// Peripheral address
input			[15:0] 	per_din;		// Peripheral data input
input       	        per_en;         // Peripheral enable (high active)
input	          [1:0] per_we;         // Peripheral write enable (high active)
input   	            reset;	        // Main system reset
// INPUTs from DMA
input			 [15:0] dev_in;			// Data from DMA Controller
input					dma_ack;
input					dma_end_flag;


//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR	= 15'h0100;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD		=  4;

// Register addresses offset
parameter [DEC_WD-1:0] START_ADDR	= 'h00,
                       N_WORDS	    = 'h02,
                       CONFIG 		= 'h04,
                       DATA_REG		= 'h06,
                       OUT_REG      = 'h08;  

// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] START_ADDR_D 	= (BASE_REG << START_ADDR),
                       N_WORDS_D    	= (BASE_REG << N_WORDS),
                       CONFIG_D    		= (BASE_REG << CONFIG),
                       DATA_REG_D    	= (BASE_REG << DATA_REG),
                       OUT_REG_D    	= (BASE_REG << OUT_REG);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};

// Register address decode
wire [DEC_SZ-1:0] reg_dec   =  (START_ADDR_D  &  {DEC_SZ{(reg_addr == START_ADDR )}}) |
                               (N_WORDS_D     &  {DEC_SZ{(reg_addr == N_WORDS )}})    |
                               (CONFIG_D      &  {DEC_SZ{(reg_addr == CONFIG )}})     |	 		
                               (DATA_REG_D    &  {DEC_SZ{(reg_addr == DATA_REG )}})   | 		
                               (OUT_REG_D     &  {DEC_SZ{(reg_addr == OUT_REG )}});

// Read/Write probes
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

// START_ADDR Register
//-----------------   
reg  [15:0] start_addr;
wire        start_addr_wr = reg_wr[START_ADDR];

always @ (posedge clk or posedge reset)
  if (reset)              start_addr <=  16'h0000;
  else if (start_addr_wr) start_addr <=  per_din;
  else                    start_addr <= start_addr;

assign dma_start_address = start_addr;

   
// N_WORDS Register
//-----------------   
reg  [15:0] n_words;
wire        n_words_wr = reg_wr[N_WORDS];

always @ (posedge clk or posedge reset)
  if (reset)           n_words <=  16'h0000;
  else if (n_words_wr) n_words <=  per_din;
  else	               n_words <= n_words;

assign dma_num_words = n_words;

   
// CONFIG Register
//-----------------   
// Only half of the config register is for CPU configuration; the other half is for the device itself. (Sergio)
//
localparam START     = 0;
localparam RD_WR     = 2;
localparam AUTORESET = 3;
localparam ACK_SET   = 4;
localparam END_OP    = 15;

// ---------------------------------------------------------------------------
// | END_OP	| 0 | ~DEV_ACK | ---  |  ACK_SET  | AUTORESET | RD_WR | 0 | START |
// ---------------------------------------------------------------------------
// |  15   | 14	|    13    | ---  |     4     |     3     |   2   | 1  |  0   |
// ---------------------------------------------------------------------------

reg  [15:0] config_reg;
wire        config_wr_ext = reg_wr[CONFIG];
reg 		config_wr_intern;

always @ (posedge clk or posedge reset ) 
  if (reset)        		 config_reg <= 16'h0000;
  else if (config_wr_ext) 	 config_reg <= {config_reg[15:8], per_din[7:0]}; 
  else if (config_wr_intern) config_reg <= {internal_status, config_reg[7:5], config_reg[ACK_SET] & ~internal_status[5], 
                                             config_reg[3:1], config_reg[START] & ~internal_status[7]}; 
  else                       config_reg <= config_reg;

// DATA_REG: Bridge between DMA Contr. and Dev.- It's Read-only for the CPU!
//---------------------------------------   
reg  [15:0] data_reg;
wire        data_wr = dma_ack & dma_rqst & dma_rd_wr;

always @ (posedge clk or posedge reset)
  if (reset)        data_reg <=  16'h0000;
  else if (data_wr) data_reg <=  dev_in; // input from the DMA controller
  else 				data_reg <= data_reg;


// OUT_REG: config what to be written in the memory
//---------------------------------------   
reg [15:0] out_reg;
wire out_reg_wr = reg_wr[OUT_REG];
always @ (posedge clk or posedge reset)
  if (reset)           out_reg <= 16'hf00d;
  else if (out_reg_wr) out_reg <= per_din;
  else	               out_reg <= out_reg;
  
//assign dev_out 			= (~dma_rd_wr & dma_rqst) ? out_reg : 16'h0000; (sergio) it's not a problem to have the device always outputing the out_reg value. Memory is still written as usual
assign dev_out 			= out_reg;


		

//=============================================================
// 4) READ DATA GENERATION
//=============================================================

// Data output mux
//-----------------  
wire [15:0] start_addr_rd  	= start_addr  & {16{reg_rd[START_ADDR]}};
wire [15:0] n_words_rd  	= n_words     & {16{reg_rd[N_WORDS]}};
wire [15:0] config_rd  		= config_reg  & {16{reg_rd[CONFIG]}};
wire [15:0] data_rd  		= data_reg    & {16{reg_rd[DATA_REG]}};
wire [15:0] out_rd  		= out_reg     & {16{reg_rd[OUT_REG]}};

wire [15:0] per_dout   		= start_addr_rd  |
		                      n_words_rd  	 |
		                      config_rd  	 |
		                   	  data_rd        |
		                   	  out_rd;
		                      
//=============================================================
// 5) DMA Device behaviour
//=============================================================
reg [7:0] internal_status;
initial 
begin
 internal_status <= 'h0;
end 

// Configuration register - internal flags to CPU.
// Possibilities to extend the set of flags
// -------------------------------------
// | END_OP	| 0 | ~DEV_ACK | --- | 0 | 0 |
// -------------------------------------
// |  7     | 6 |	 5   | --- | 1 | 0 |
// -------------------------------------

always @(posedge config_reg[START]) begin
	config_wr_intern   <= 1'b1;	
	internal_status[7] <= 1'b0;
	@(posedge clk)  config_wr_intern   <= 1'b0;		
end

always @(posedge dma_end_flag) begin
	config_wr_intern   <= 1'b1;	
	internal_status[7] <= 1'b1;
	@(posedge clk)  config_wr_intern   <= 1'b0;		
end

always @(posedge data_wr & config_reg[AUTORESET]) begin
	internal_status[5] <= 1'b1;
	config_wr_intern   <= 1'b1;
	@(posedge clk)  config_wr_intern   <= 1'b0;		
end 

always @(posedge config_reg[ACK_SET] & config_reg[AUTORESET]) begin
	internal_status[5] <= 1'b0;
	config_wr_intern   <= 1'b1;
	@(posedge clk)  config_wr_intern   <= 1'b0;	
end


assign dev_ack   = config_reg[AUTORESET] ? ~internal_status[5] : 1'b1;
assign dma_rqst  = config_reg[START];   
assign dma_rd_wr = config_reg[RD_WR]; // 1: Read | 0: Write

endmodule 
