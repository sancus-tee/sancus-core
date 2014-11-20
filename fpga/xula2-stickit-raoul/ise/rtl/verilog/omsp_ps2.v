module omsp_ps2(
    output wire [15:0] per_dout,
    output wire        irq_rx,
    inout  wire        ps2_clk,
    inout  wire        ps2_data,
    input  wire        mclk,
    input  wire [13:0] per_addr,
    input  wire [15:0] per_din,
    input  wire        per_en,
    input  wire  [1:0] per_we,
    input  wire        puc_rst
);


//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h00a0;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  2;

// Register addresses offset
parameter [DEC_WD-1:0] STATUS      =  'h0,
                       DATA        =  'h1;

// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] STATUS_D    = (BASE_REG << STATUS),
                       DATA_D      = (BASE_REG << DATA);

//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};

// Register address decode
wire [DEC_SZ-1:0] reg_dec      = (STATUS_D & {DEC_SZ{(reg_addr==(STATUS >> 1))}}) |
                                 (DATA_D   & {DEC_SZ{(reg_addr==(DATA   >> 1))}});

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

// DATA Register
//-----------------
reg  [7:0] ps2_tx_data;
reg        ps2_send_request;

wire       data_wr  = DATA[0] ? reg_hi_wr[DATA] : reg_lo_wr[DATA];
wire [7:0] data_nxt = DATA[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)
  begin
      ps2_send_request <= 1'b00;
      ps2_tx_data      <= 8'b0;
  end
  else if (data_wr & ps2_ready)
  begin
      ps2_send_request <= 1'b1;
      ps2_tx_data      <= data_nxt;
  end

// STATUS Register
// ---------------
wire [7:0] status = {3'b0,
                     ps2_extended,
                     ps2_released,
                     ps2_error,
                     ps2_busy,
                     ps2_ready};

//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

// Data output mux
wire [15:0] status_rd = {8'h00, (status      & {8{reg_rd[STATUS]}})} << (8 & {4{STATUS[0]}});
wire [15:0] data_rd   = {8'h00, (ps2_rx_data & {8{reg_rd[DATA]}})}   << (8 & {4{DATA[0]}});

assign      per_dout  =  status_rd | data_rd;
assign      irq_rx    =  ps2_ready;

wire [7:0] ps2_rx_data;
wire       ps2_ready;
wire       ps2_busy;
wire       ps2_error;
wire       ps2_extended;
wire       ps2_released;

ps2_keyboard_interface ps2 (
    .clk                        (mclk),
    .reset                      (puc_rst),
    .ps2_clk                    (ps2_clk),
    .ps2_data                   (ps2_data),
    .rx_extended                (ps2_extended),
    .rx_released                (ps2_released),
    .rx_shift_key_on            (),
    .rx_scan_code               (ps2_rx_data),
    .rx_data_ready              (ps2_ready),
    .rx_read                    (reg_rd[DATA]),
    .tx_data                    (ps2_tx_data),
    .tx_write                   (ps2_send_request),
    .tx_write_ack_o             (),
    .tx_error_no_keyboard_ack   ()
  );

endmodule // template_periph_8b

