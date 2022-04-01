module  omsp_tsc (

// OUTPUTs
    per_dout,                       // Peripheral data output
    tsc,                            // tsc copy to make it available externally

// INPUTs
    mclk,                           // Main system clock
    per_addr,                       // Peripheral address
    per_din,                        // Peripheral data input
    per_en,                         // Peripheral enable (high active)
    per_we,                         // Peripheral write enable (high active)
    puc_rst                         // Main system reset
);

// OUTPUTs
//=========
output       [15:0] per_dout;       // Peripheral data output
output       [63:0] tsc;            // tsc copy to make it available externally

// INPUTs
//=========
input               mclk;           // Main system clock
input        [13:0] per_addr;       // Peripheral address
input        [15:0] per_din;        // Peripheral data input
input               per_en;         // Peripheral enable (high active)
input         [1:0] per_we;         // Peripheral write enable (high active)
input               puc_rst;        // Main system reset


//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h0100;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  3;

// Register addresses offset
parameter [DEC_WD-1:0] TSC1      = 'h0,
                       TSC2      = 'h2,
                       TSC3      = 'h4,
                       TSC4      = 'h6;

// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] TSC1_D    = (BASE_REG << TSC1),
                       TSC2_D    = (BASE_REG << TSC2),
                       TSC3_D    = (BASE_REG << TSC3),
                       TSC4_D    = (BASE_REG << TSC4);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};

// Register address decode
wire [DEC_SZ-1:0] reg_dec   =  (TSC1_D  &  {DEC_SZ{(reg_addr == TSC1 )}})  |
                               (TSC2_D  &  {DEC_SZ{(reg_addr == TSC2 )}})  |
                               (TSC3_D  &  {DEC_SZ{(reg_addr == TSC3 )}})  |
                               (TSC4_D  &  {DEC_SZ{(reg_addr == TSC4 )}});

// Read/Write probes
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

// Time Stamp Counter Register
//-----------------
reg [63:0] tsc;

always @(posedge mclk or posedge puc_rst)
    if (puc_rst)
        tsc <= 64'h0;
    else
        tsc <= tsc + 1;

// Snapshot of TSC used for reading a stable value
//-----------------
reg [63:0] tsc_snapshot;

always @(posedge mclk or posedge puc_rst)
    if (puc_rst)
        tsc_snapshot <= 64'h0;
    else if (reg_write)
        tsc_snapshot <= tsc;

//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

// Data output mux
wire [15:0] tsc1_rd = tsc_snapshot[15:0]  & {16{reg_rd[TSC1]}};
wire [15:0] tsc2_rd = tsc_snapshot[31:16] & {16{reg_rd[TSC2]}};
wire [15:0] tsc3_rd = tsc_snapshot[47:32] & {16{reg_rd[TSC3]}};
wire [15:0] tsc4_rd = tsc_snapshot[63:48] & {16{reg_rd[TSC4]}};

wire [15:0] per_dout   =  tsc1_rd  |
                          tsc2_rd  |
                          tsc3_rd  |
                          tsc4_rd;


endmodule
