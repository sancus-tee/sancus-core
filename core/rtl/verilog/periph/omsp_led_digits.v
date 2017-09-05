module  omsp_led_digits (

// OUTPUTs
    per_dout,                       // Peripheral data output
    so,

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
output      [15:0] per_dout;        // Peripheral data output
output       [7:0] so;

// INPUTs
//=========
input              mclk;            // Main system clock
input       [13:0] per_addr;        // Peripheral address
input       [15:0] per_din;         // Peripheral data input
input              per_en;          // Peripheral enable (high active)
input        [1:0] per_we;          // Peripheral write enable (high active)
input              puc_rst;         // Main system reset


//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h0090;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  3;

// Register addresses offset
parameter [DEC_WD-1:0] LED1 =  'h0,
                       LED2 =  'h1,
                       LED3 =  'h2,
                       LED4 =  'h3,
                       LED5 =  'h4,
                       LED6 =  'h5,
                       LED7 =  'h6,
                       LED8 =  'h7;
   
// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] LED1_D  = (BASE_REG << LED1),
                       LED2_D  = (BASE_REG << LED2), 
                       LED3_D  = (BASE_REG << LED3), 
                       LED4_D  = (BASE_REG << LED4), 
                       LED5_D  = (BASE_REG << LED5), 
                       LED6_D  = (BASE_REG << LED6), 
                       LED7_D  = (BASE_REG << LED7), 
                       LED8_D  = (BASE_REG << LED8); 


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};

// Register address decode
wire [DEC_SZ-1:0] reg_dec      = (LED1_D  &  {DEC_SZ{(reg_addr==(LED1 >>1))}}) |
                                 (LED2_D  &  {DEC_SZ{(reg_addr==(LED2 >>1))}}) |
                                 (LED3_D  &  {DEC_SZ{(reg_addr==(LED3 >>1))}}) |
                                 (LED4_D  &  {DEC_SZ{(reg_addr==(LED4 >>1))}}) |
                                 (LED5_D  &  {DEC_SZ{(reg_addr==(LED5 >>1))}}) |
                                 (LED6_D  &  {DEC_SZ{(reg_addr==(LED6 >>1))}}) |
                                 (LED7_D  &  {DEC_SZ{(reg_addr==(LED7 >>1))}}) |
                                 (LED8_D  &  {DEC_SZ{(reg_addr==(LED8 >>1))}});

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

// LED1 Register
//-----------------
reg  [7:0] led1;

wire       led1_wr  = LED1[0] ? reg_hi_wr[LED1] : reg_lo_wr[LED1];
wire [7:0] led1_nxt = LED1[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led1 <=  8'h00;
  else if (led1_wr) led1 <=  led1_nxt;

   
// LED2 Register
//-----------------
reg  [7:0] led2;

wire       led2_wr  = LED2[0] ? reg_hi_wr[LED2] : reg_lo_wr[LED2];
wire [7:0] led2_nxt = LED2[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led2 <=  8'h00;
  else if (led2_wr) led2 <=  led2_nxt;

   
// LED3 Register
//-----------------
reg  [7:0] led3;

wire       led3_wr  = LED3[0] ? reg_hi_wr[LED3] : reg_lo_wr[LED3];
wire [7:0] led3_nxt = LED3[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led3 <=  8'h00;
  else if (led3_wr) led3 <=  led3_nxt;

   
// LED4 Register
//-----------------
reg  [7:0] led4;

wire       led4_wr  = LED4[0] ? reg_hi_wr[LED4] : reg_lo_wr[LED4];
wire [7:0] led4_nxt = LED4[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led4 <=  8'h00;
  else if (led4_wr) led4 <=  led4_nxt;

// LED5 Register
//-----------------
reg  [7:0] led5;

wire       led5_wr  = LED5[0] ? reg_hi_wr[LED5] : reg_lo_wr[LED5];
wire [7:0] led5_nxt = LED5[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led5 <=  8'h00;
  else if (led5_wr) led5 <=  led5_nxt;

// LED6 Register
//-----------------
reg  [7:0] led6;

wire       led6_wr  = LED6[0] ? reg_hi_wr[LED6] : reg_lo_wr[LED6];
wire [7:0] led6_nxt = LED6[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led6 <=  8'h00;
  else if (led6_wr) led6 <=  led6_nxt;

// LED7 Register
//-----------------
reg  [7:0] led7;

wire       led7_wr  = LED7[0] ? reg_hi_wr[LED7] : reg_lo_wr[LED7];
wire [7:0] led7_nxt = LED7[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led7 <=  8'h00;
  else if (led7_wr) led7 <=  led7_nxt;

// LED8 Register
//-----------------
reg  [7:0] led8;

wire       led8_wr  = LED8[0] ? reg_hi_wr[LED8] : reg_lo_wr[LED8];
wire [7:0] led8_nxt = LED8[0] ? per_din[15:8]   : per_din[7:0];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      led8 <=  8'h00;
  else if (led8_wr) led8 <=  led8_nxt;


//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

// Data output mux
wire [15:0] led1_rd   = {8'h00, (led1  & {8{reg_rd[LED1]}})}  << (8 & {4{LED1[0]}});
wire [15:0] led2_rd   = {8'h00, (led2  & {8{reg_rd[LED2]}})}  << (8 & {4{LED2[0]}});
wire [15:0] led3_rd   = {8'h00, (led3  & {8{reg_rd[LED3]}})}  << (8 & {4{LED3[0]}});
wire [15:0] led4_rd   = {8'h00, (led4  & {8{reg_rd[LED4]}})}  << (8 & {4{LED4[0]}});
wire [15:0] led5_rd   = {8'h00, (led5  & {8{reg_rd[LED5]}})}  << (8 & {4{LED5[0]}});
wire [15:0] led6_rd   = {8'h00, (led6  & {8{reg_rd[LED6]}})}  << (8 & {4{LED6[0]}});
wire [15:0] led7_rd   = {8'h00, (led7  & {8{reg_rd[LED7]}})}  << (8 & {4{LED7[0]}});
wire [15:0] led8_rd   = {8'h00, (led8  & {8{reg_rd[LED8]}})}  << (8 & {4{LED8[0]}});

wire [15:0] per_dout  =  led1_rd  |
                         led2_rd  |
                         led3_rd  |
                         led4_rd  |
                         led5_rd  |
                         led6_rd  |
                         led7_rd  |
                         led8_rd;

// combine input leds in a single array; drop MSB
wire [6:0] leds[0:7];
assign leds[0] = led1[6:0];
assign leds[1] = led2[6:0];
assign leds[2] = led3[6:0];
assign leds[3] = led4[6:0];
assign leds[4] = led5[6:0];
assign leds[5] = led6[6:0];
assign leds[6] = led7[6:0];
assign leds[7] = led8[6:0];

// consider the next input led every few cycles, but not too fast to allow
// the leds to hold a stable, seemingly persistent, state
reg [3:0] div;
always @(negedge mclk or posedge puc_rst) begin
    if (puc_rst) div = 0;
    else         div = div + 1;
end

integer cur_led;
always @(posedge mclk or posedge puc_rst) begin
    if (puc_rst)      cur_led = 0;
    else if (div==15) cur_led = (cur_led + 1) % 8;
end

// generate tri-state signal for led digits module, based on current input led
reg [7:0] so;
integer i,k;
always @(*) begin
    k = 0;
    so = 8'bzzzzzzzz;
    for (i = 0; i < 7; i = i + 1) begin
        if (i == cur_led)
            k = k + 1;
        if (leds[cur_led][i])
            so[k] = 1'b0;
        k = k + 1;
    end
    so[cur_led] = 1'b1;
end

endmodule // omsp_led_digits
