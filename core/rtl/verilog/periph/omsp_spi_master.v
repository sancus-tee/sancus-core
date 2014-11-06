module  omsp_spi_master (

// OUTPUTs
    per_dout,                       // Peripheral data output
    sck,
    ss,
    mosi,

// INPUTs
    mclk,                           // Main system clock
    miso,
    per_addr,                       // Peripheral address
    per_din,                        // Peripheral data input
    per_en,                         // Peripheral enable (high active)
    per_we,                         // Peripheral write enable (high active)
    puc_rst                         // Main system reset
);

// OUTPUTs
//=========
output      [15:0] per_dout;        // Peripheral data output
output             sck;
output             ss;
output             mosi;

// INPUTs
//=========
input              mclk;            // Main system clock
input              miso;
input       [13:0] per_addr;        // Peripheral address
input       [15:0] per_din;         // Peripheral data input
input              per_en;          // Peripheral enable (high active)
input        [1:0] per_we;          // Peripheral write enable (high active)
input              puc_rst;         // Main system reset


//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h0150;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  2;

// Register addresses offset
parameter [DEC_WD-1:0] DATA   = 'h0,
                       CNTRL  = 'h1,
                       STATUS = 'h2;

   
// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] DATA_D   = (BASE_REG << DATA),
                       CNTRL_D  = (BASE_REG << CNTRL),
                       STATUS_D = (BASE_REG << STATUS);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};

// Register address decode
wire [DEC_SZ-1:0] reg_dec      = (DATA_D   &  {DEC_SZ{(reg_addr==(DATA >>1))}})  |
                                 (CNTRL_D  &  {DEC_SZ{(reg_addr==(CNTRL >>1))}}) |
                                 (STATUS_D &  {DEC_SZ{(reg_addr==(STATUS >>1))}});

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

// DATA Register: writes start an SPI transfer if not busy
//-----------------
wire       data_wr     = DATA[0] ? reg_hi_wr[DATA] : reg_lo_wr[DATA];
wire [7:0] spi_data_in = DATA[0] ? per_din[15:8]   : per_din[7:0];

reg spi_start;

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)
    spi_start <= 0;
  else if (data_wr && ~spi_busy)
    spi_start <= 1;
  else
    spi_start <= 0;


// CNTRL Register
//-----------------
reg  [7:0] cntrl;

wire       cntrl_wr  = CNTRL[0] ? reg_hi_wr[CNTRL] : reg_lo_wr[CNTRL];
wire [7:0] cntrl_nxt = CNTRL[0] ? per_din[15:8]     : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)
    cntrl <=  8'h00;
  else if (cntrl_wr)
    cntrl <=  cntrl_nxt;

wire       spi_cpol    =  cntrl[0];
wire       spi_cpha    =  cntrl[1];
assign     ss          = ~cntrl[2];
wire [7:0] spi_clk_div =  {3'b0, cntrl[7:3]};

// STATUS Register
//-----------------
wire [7:0] status = {7'b0, spi_busy};


//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

// Data output mux
wire [15:0] data_rd   = {8'h00, (spi_data_out & {8{reg_rd[DATA]}})}   << (8 & {4{DATA[0]}});
wire [15:0] status_rd = {8'h00, (status       & {8{reg_rd[STATUS]}})} << (8 & {4{STATUS[0]}});

wire [15:0] per_dout  =  data_rd | status_rd;

// SPI instantiation
wire       spi_busy;
wire [7:0] spi_data_out;

spi_master spi (
    .clk        (mclk),
    .rst        (puc_rst),
    .miso       (miso),
    .start      (spi_start),
    .cpol       (spi_cpol),
    .cpha       (spi_cpha),
    .clk_div    (spi_clk_div),
    .data_in    (spi_data_in),

    .sck        (sck),
    .mosi       (mosi),
    //.ss         (ss),
    .busy       (spi_busy),
    .data_out   (spi_data_out)
);


endmodule
