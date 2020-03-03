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
parameter       [14:0] BASE_ADDR   = 15'h0080;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  2;

// Register addresses offset
parameter [DEC_WD-1:0] DMA_PER_ADDR_LO =  'h0,
                       DMA_PER_ADDR_HI =  'h1,
                       DMA_PER_TRACE   =  'h2,
                       DMA_PER_CNT     =  'h3;


// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] DMA_PER_ADDR_D  = (BASE_REG << DMA_PER_ADDR_LO),
                       DMA_PER_EN_D    = (BASE_REG << DMA_PER_ADDR_HI),
                       DMA_PER_TRACE_D = (BASE_REG << DMA_PER_TRACE),
                       DMA_PER_CNT_D   = (BASE_REG << DMA_PER_CNT);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};

// Register address decode
wire [DEC_SZ-1:0] reg_dec      = (DMA_PER_ADDR_D   &  {DEC_SZ{(reg_addr==(DMA_PER_ADDR_LO >>1))}}) |
                                 (DMA_PER_EN_D     &  {DEC_SZ{(reg_addr==(DMA_PER_ADDR_HI >>1))}}) |
                                 (DMA_PER_TRACE_D  &  {DEC_SZ{(reg_addr==(DMA_PER_TRACE >>1))}}) |
                                 (DMA_PER_CNT_D    &  {DEC_SZ{(reg_addr==(DMA_PER_CNT >>1))}});

// Read/Write probes
wire              reg_lo_write =  per_we[0] & reg_sel;
wire              reg_hi_write =  per_we[1] & reg_sel;
wire              reg_read     = ~|per_we   & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_hi_wr    = reg_dec & {DEC_SZ{reg_hi_write}};
wire [DEC_SZ-1:0] reg_lo_wr    = reg_dec & {DEC_SZ{reg_lo_write}};
wire [DEC_SZ-1:0] reg_rd       = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

// DMA_PER_ADDR_LO Register
//-----------------
reg  [7:0] dma_per_addr_lo;

wire       dma_per_addr_lo_wr  = DMA_PER_ADDR_LO[0] ? reg_hi_wr[DMA_PER_ADDR_LO] : reg_lo_wr[DMA_PER_ADDR_LO];
wire [7:0] dma_per_addr_lo_nxt = DMA_PER_ADDR_LO[0] ? per_din[15:8]     : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        dma_per_addr_lo <=  8'h00;
  else if (dma_per_addr_lo_wr) dma_per_addr_lo <=  dma_per_addr_lo_nxt;


// DMA_PER_ADDR_HI Register
//-----------------
reg  [7:0] dma_per_addr_hi;

wire       dma_per_addr_hi_wr  = DMA_PER_ADDR_HI[0] ? reg_hi_wr[DMA_PER_ADDR_HI] : reg_lo_wr[DMA_PER_ADDR_HI];
wire [7:0] dma_per_addr_hi_nxt = DMA_PER_ADDR_HI[0] ? per_din[15:8]     : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        dma_per_addr_hi <=  8'h00;
  else if (dma_per_addr_hi_wr) dma_per_addr_hi <=  dma_per_addr_hi_nxt;


// DMA_PER_TRACE Register
//-----------------
reg  [15:0] dma_per_trace = 16'h0;

// DMA_PER_CNT Register
//-----------------
reg  [7:0] dma_per_cnt;

wire       dma_per_cnt_wr  = DMA_PER_CNT[0] ? reg_hi_wr[DMA_PER_CNT] : reg_lo_wr[DMA_PER_CNT];
wire [7:0] dma_per_cnt_nxt = DMA_PER_CNT[0] ? per_din[15:8]     : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        dma_per_cnt <=  8'h00;
  else if (dma_per_cnt_wr) dma_per_cnt <=  dma_per_cnt_nxt;

//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

wire [15:0] per_dout = |reg_rd ? dma_per_trace : 16'h0;

reg      [15:1] dma_addr = 15'h0;
reg             dma_en = 1'b1;
reg       [1:0] dma_we = 2'b00;

reg [3:0] internal_cnt = 4'h0;

always @(posedge mclk) begin
  case (dma_per_cnt)
    8'h0: begin
        if (internal_cnt != 4'h0) begin
          dma_per_trace <= {dma_per_trace[14:0], ~dma_ready};
          dma_en <= 1'b1;
          dma_addr <= {dma_per_addr_hi[6:0], dma_per_addr_lo};
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

endmodule
