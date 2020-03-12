module dma_attacker (

// OUTPUTs
    per_dout,                       // Peripheral data output
    dma_addr,
    dma_en,
    dma_we,

// INPUTs
    mclk,                           // Main system clock
    per_addr,                       // Peripheral address
    per_din,                        // Peripheral data input
    per_en,                         // Peripheral enable (high active)
    per_we,                         // Peripheral write enable (high active)
    puc_rst,                        // Main system reset
    dma_ready,
);

// OUTPUTs
//=========
output      [15:0] per_dout;        // Peripheral data output
output      [15:1] dma_addr;
output             dma_en;
output       [1:0] dma_we;

// INPUTs
//=========
input              mclk;            // Main system clock
input       [13:0] per_addr;        // Peripheral address
input       [15:0] per_din;         // Peripheral data input
input              per_en;          // Peripheral enable (high active)
input        [1:0] per_we;          // Peripheral write enable (high active)
input              puc_rst;         // Main system reset
input              dma_ready;

//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h0070;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  3;

// Register addresses offset
parameter [DEC_WD-1:0] DMA_PER_ADDR  =  'h0,
                       DMA_PER_CNT   =  'h2,
                       DMA_PER_TRACE =  'h4;


// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] DMA_PER_ADDR_D  = (BASE_REG << DMA_PER_ADDR),
                       DMA_PER_CNT_D   = (BASE_REG << DMA_PER_CNT),
                       DMA_PER_TRACE_D = (BASE_REG << DMA_PER_TRACE);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};

// Register address decode
wire [DEC_SZ-1:0] reg_dec      = (DMA_PER_ADDR_D   &  {DEC_SZ{(reg_addr==DMA_PER_ADDR)}}) |
                                 (DMA_PER_CNT_D    &  {DEC_SZ{(reg_addr==DMA_PER_CNT)}}) |
                                 (DMA_PER_TRACE_D  &  {DEC_SZ{(reg_addr==DMA_PER_TRACE)}});

// Read/Write probes
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

// DMA_PER_ADDR Register
//-----------------
reg  [15:0] dma_per_addr;

wire        dma_per_addr_wr = reg_wr[DMA_PER_ADDR];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        dma_per_addr <=  16'h00;
  else if (dma_per_addr_wr) dma_per_addr <=  per_din;

// DMA_PER_CNT Register
//-----------------
reg  [15:0] dma_per_cnt;

wire        dma_per_cnt_wr = reg_wr[DMA_PER_CNT];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        dma_per_cnt <=  16'h00;
  else if (dma_per_cnt_wr) dma_per_cnt <=  per_din;
  else begin
    case (dma_per_cnt)
      8'h0: begin
          if (internal_cnt != 4'h0) begin
            dma_per_trace <= {dma_per_trace[14:0], ~dma_ready};
            dma_en <= 1'b1;
            dma_addr <= dma_per_addr[14:0];
            dma_we <= 2'b00;
            internal_cnt <= internal_cnt - 1;
          end
        end
      8'h1: begin
          internal_cnt <= 8'd15;
          dma_per_cnt <= dma_per_cnt - 1;
        end
      default: begin
          dma_per_cnt <= dma_per_cnt - 1;
        end
    endcase
  end

// DMA_PER_TRACE Register
//-----------------
reg  [15:0] dma_per_trace = 16'h0;

//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

wire [15:0] per_dout = |reg_rd ? dma_per_trace : 16'h0;

reg      [15:1] dma_addr = 15'h0;
reg             dma_en = 1'b0;
reg       [1:0] dma_we = 2'b00;

reg [3:0] internal_cnt = 4'h0;

endmodule
