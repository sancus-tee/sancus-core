//----------------------------------------------------------------------------
// Copyright (C) 2011 Authors
//
// This source file may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// This source file is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// This source is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
// License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this source; if not, write to the Free Software Foundation,
// Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
//
//----------------------------------------------------------------------------
// 
// *File Name: openMSP430_fpga.v
// 
// *Module Description:
//                      openMSP430 FPGA Top-level for the Avnet LX9 Microboard
//
// *Author(s):
//              - Ricardo Ribalda,    ricardo.ribalda@gmail.com
//              - Olivier Girard,    olgirard@gmail.com
//
//----------------------------------------------------------------------------
`include "openmsp430/openMSP430_defines.v"

// include charlieplexer on PM3/HAT (and exclude P3)
`define FPGA_CHARLIE

module openMSP430_fpga (
    // 12MHz clock
	input  wire        fpgaClk_i,
    // SDRAM
    output wire        sdCke_o,
    output wire        sdClk_o,
    input  wire        sdClkFb_i,
    output wire        sdCe_bo,
    output wire        sdRas_bo,
    output wire        sdCas_bo,
    output wire        sdWe_bo,
    output wire        sdDqml_o,
    output wire        sdDqmh_o,
    output wire  [1:0] sdBs_o,
    output wire [12:0] sdAddr_o,
    inout  wire [15:0] sdData_io,
    // Flash
    output wire        usdflashCs_bo,
    output wire        flashCs_bo,
    output wire        sclk_o,
    output wire        mosi_o,
    input  wire        miso_i,
    // Prototyping header
    inout  wire        chanClk_io,
    inout  wire [31:0] chan_io
);

parameter integer foo = $clog2(16);

assign sdCke_o = 1'b0;
assign sdClk_o = 1'b0;
assign sdCe_bo = 1'b0;
assign sdRas_bo = 1'b0;
assign sdCas_bo = 1'b0;
assign sdWe_bo = 1'b0;
assign sdDqml_o = 1'b0;
assign sdDqmh_o = 1'b0;
assign sdBs_o = 2'b0;
assign sdAddr_o = 13'b0;
assign usdflashCs_bo = 1'b0;
assign flashCs_bo = 1'b0;
assign sclk_o = 1'b0;
assign mosi_o = 1'b0;

//=============================================================================
// 1)  INTERNAL WIRES/REGISTERS/PARAMETERS DECLARATION
//=============================================================================

// openMSP430 output buses
wire        [13:0] per_addr;
wire        [15:0] per_din;
wire         [1:0] per_we;
wire [`DMEM_MSB:0] dmem_addr;
wire        [15:0] dmem_din;
wire         [1:0] dmem_wen;
wire         [1:0] dmem_wen_n;
wire [`PMEM_MSB:0] pmem_addr;
wire        [15:0] pmem_din;
wire         [1:0] pmem_wen;
wire         [1:0] pmem_wen_n;
wire        [13:0] irq_acc;

// openMSP430 input buses
wire   	    [13:0] irq_bus;
wire        [15:0] per_dout;
wire        [15:0] dmem_dout;
wire        [15:0] pmem_dout;

// GPIO
wire         [7:0] p1_din;
wire         [7:0] p1_dout;
wire         [7:0] p1_dout_en;
wire         [7:0] p1_sel;
wire         [7:0] p2_din;
wire         [7:0] p2_dout;
wire         [7:0] p2_dout_en;
wire         [7:0] p2_sel;
wire         [7:0] p3_dout;
wire         [7:0] p3_dout_en;
wire         [7:0] p3_din;
wire        [15:0] per_dout_dio;

// Timer A
wire        [15:0] per_dout_tA;

// Simple UART
wire               irq_uart_rx;
wire               irq_uart_tx;
wire        [15:0] per_dout_uart;
wire               hw_uart_txd;
wire               hw_uart_rxd;
wire               hw_uart_txd2;
wire        [15:0] per_dout_uart2;

// PS/2
//wire        [15:0] per_dout_ps2;
//wire               irq_rx_ps2;
//wire               ps2_clk;
//wire               ps2_data;

// TSC
wire        [15:0] per_dout_tsc;

// SPI master
wire        [15:0] per_dout_spi;
wire               spi_mosi;
wire               spi_miso;
wire               spi_sck;
wire        [2:0]  spi_ss;

// Led Digits
wire        [15:0] per_dout_led;
wire         [7:0] led_so;

// Others
wire               reset_pin;

wire               dbg_sw = 1'b1;

// Debug and Hardware UARTs on PM2
assign chan_io[18] = dbg_uart_txd & hw_uart2_txd;
assign dbg_uart_rxd = chan_io[20];
assign chan_io[17] = hw_uart_txd;
assign hw_uart_rxd = chan_io[19];

// LCD UART
//assign chan_io[14] = lcd_uart_txd;

// PS2
//alias alias1(ps2_clk, chanClk_io);
//alias alias2(ps2_data, chan_io[15]);

// SPI master on PM2
assign chan_io[6]  = spi_sck;
assign spi_miso    = chan_io[4];
assign chan_io[2]  = spi_mosi;
assign chan_io[0]  = spi_ss[0];
assign chanClk_io  = spi_ss[1];

// LED digits charlieplexer on PM3
`ifdef FPGA_CHARLIE
    assign chan_io[29] = led_so[6];
    assign chan_io[27] = led_so[4];
    assign chan_io[25] = led_so[2];
    assign chan_io[23] = led_so[0];
    assign chan_io[30] = led_so[7];
    assign chan_io[28] = led_so[5];
    assign chan_io[26] = led_so[3];
    assign chan_io[24] = led_so[1];
`endif

//=============================================================================
// 2)  CLOCK GENERATION
//=============================================================================

// Input buffers
//------------------------
IBUFG ibuf_clk_main   (.O(clk_12M_in),    .I(fpgaClk_i));


// Digital Clock Manager
//------------------------
DCM_SP #(
		.CLKFX_MULTIPLY(5),
		.CLKFX_DIVIDE(3),
		.CLKIN_PERIOD(83.333)
 )dcm_inst(
// OUTPUTs
    .CLKFX        (dcm_clk),
    .CLK0         (CLK0_BUF),
    .LOCKED       (dcm_locked),
// INPUTs
    .CLKFB        (CLKFB_IN),
    .CLKIN        (clk_12M_in),
    .PSEN         (1'b0),
    .RST          (reset_pin)
);

BUFG CLK0_BUFG_INST (
    .I(CLK0_BUF),
    .O(CLKFB_IN)
);

//synthesis translate_off
defparam dcm_inst.CLKFX_MULTIPLY        = 5;
defparam dcm_inst.CLKFX_DIVIDE          = 3;
defparam dcm_int.CLKIN_PERIOD           = 83.333;
//synthesis translate_on

// Clock buffers
//------------------------
BUFG  buf_sys_clock  (.O(clk_sys), .I(dcm_clk));

//assign LED0 = SW0 & SW1;

//=============================================================================
// 3)  RESET GENERATION & FPGA STARTUP
//=============================================================================

// Reset input buffer
//IBUF   ibuf_reset_n   (.O(reset_pin), .I(1'b0));
//wire reset_pin_n = ~reset_pin;
wire reset_pin_n = 1'b1;

// Release the reset only, if the DCM is locked
assign  reset_n = reset_pin_n & dcm_locked;

//=============================================================================
// 4)  OPENMSP430
//=============================================================================
wire spm_violation;
openMSP430 openMSP430_0 (
// OUTPUTs
    .aclk_en      (aclk_en),      // ACLK enable
    .dbg_freeze   (dbg_freeze),   // Freeze peripherals
    .dbg_uart_txd (dbg_uart_txd), // Debug interface: UART TXD
    .dmem_addr    (dmem_addr),    // Data Memory address
    .dmem_cen     (dmem_cen),     // Data Memory chip enable (low active)
    .dmem_din     (dmem_din),     // Data Memory data input
    .dmem_wen     (dmem_wen),     // Data Memory write enable (low active)
    .irq_acc      (irq_acc),      // Interrupt request accepted (one-hot signal)
    .mclk         (mclk),         // Main system clock
    .per_addr     (per_addr),     // Peripheral address
    .per_din      (per_din),      // Peripheral data input
    .per_we       (per_we),       // Peripheral write enable (high active)
    .per_en       (per_en),       // Peripheral enable (high active)
    .pmem_addr    (pmem_addr),    // Program Memory address
    .pmem_cen     (pmem_cen),     // Program Memory chip enable (low active)
    .pmem_din     (pmem_din),     // Program Memory data input (optional)
    .pmem_wen     (pmem_wen),     // Program Memory write enable (low active) (optional)
    .puc_rst      (puc_rst),      // Main system reset
    .smclk_en     (smclk_en),     // SMCLK enable
    //.spm_violation(spm_violation),

// INPUTs
    .cpu_en       (1'b1),         // Enable CPU code execution (asynchronous)
    .dbg_en       (dbg_sw),       // Debug interface enable (asynchronous)
    .dbg_uart_rxd (dbg_uart_rxd), // Debug interface: UART RXD
    .dco_clk      (clk_sys),      // Fast oscillator (fast clock)
    .dmem_dout    (dmem_dout),    // Data Memory data output
    .irq          (irq_bus),      // Maskable interrupts
    .lfxt_clk     (1'b0),         // Low frequency oscillator (typ 32kHz)
    .nmi          (nmi),          // Non-maskable interrupt (asynchronous)
    .per_dout     (per_dout),     // Peripheral data output
    .pmem_dout    (pmem_dout),    // Program Memory data output
    .reset_n      (reset_n)       // Reset Pin (low active)
);


//=============================================================================
// 5)  OPENMSP430 PERIPHERALS
//=============================================================================

//
// Digital I/O
//-------------------------------

omsp_gpio #(.P1_EN(1),
            .P2_EN(1),
            .P3_EN(1),
            .P4_EN(1),
            .P5_EN(0),
            .P6_EN(0)) gpio_0 (

// OUTPUTs
    .irq_port1    (irq_port1),     // Port 1 interrupt
    .irq_port2    (irq_port2),     // Port 2 interrupt
    .p1_dout      (p1_dout),       // Port 1 data output
    .p1_dout_en   (p1_dout_en),    // Port 1 data output enable
    .p1_sel       (p1_sel),        // Port 1 function select
    .p2_dout      (p2_dout),       // Port 2 data output
    .p2_dout_en   (p2_dout_en),    // Port 2 data output enable
    .p2_sel       (p2_sel),        // Port 2 function select
    .p3_dout      (p3_dout),       // Port 3 data output
    .p3_dout_en   (p3_dout_en),    // Port 3 data output enable
    .p3_sel       (),        // Port 3 function select
    .p4_dout      (),              // Port 4 data output
    .p4_dout_en   (),              // Port 4 data output enable
    .p4_sel       (),              // Port 4 function select
    .p5_dout      (),              // Port 5 data output
    .p5_dout_en   (),              // Port 5 data output enable
    .p5_sel       (),              // Port 5 function select
    .p6_dout      (),              // Port 6 data output
    .p6_dout_en   (),              // Port 6 data output enable
    .p6_sel       (),              // Port 6 function select
    .per_dout     (per_dout_dio),  // Peripheral data output
			     
// INPUTs
    .mclk         (mclk),          // Main system clock
    .p1_din       (p1_din),        // Port 1 data input
    .p2_din       (p2_din),        // Port 2 data input
    .p3_din       (p3_din),        // Port 3 data input
    .p4_din       (8'h00),         // Port 4 data input
    .p5_din       (8'h00),         // Port 5 data input
    .p6_din       (8'h00),         // Port 6 data input
    .per_addr     (per_addr),      // Peripheral address
    .per_din      (per_din),       // Peripheral data input
    .per_en       (per_en),        // Peripheral enable (high active)
    .per_we       (per_we),        // Peripheral write enable (high active)
    .puc_rst      (puc_rst)        // Main system reset
);

//
// Timer A
//----------------------------------------------

omsp_timerA timerA_0 (

// OUTPUTs
    .irq_ta0      (irq_ta0),       // Timer A interrupt: TACCR0
    .irq_ta1      (irq_ta1),       // Timer A interrupt: TAIV, TACCR1, TACCR2
    .per_dout     (per_dout_tA),   // Peripheral data output
    .ta_out0      (ta_out0),       // Timer A output 0
    .ta_out0_en   (ta_out0_en),    // Timer A output 0 enable
    .ta_out1      (ta_out1),       // Timer A output 1
    .ta_out1_en   (ta_out1_en),    // Timer A output 1 enable
    .ta_out2      (ta_out2),       // Timer A output 2
    .ta_out2_en   (ta_out2_en),    // Timer A output 2 enable

// INPUTs
    .aclk_en      (aclk_en),       // ACLK enable (from CPU)
    .dbg_freeze   (dbg_freeze),    // Freeze Timer A counter
    .inclk        (inclk),         // INCLK external timer clock (SLOW)
    .irq_ta0_acc  (irq_acc[9]),    // Interrupt request TACCR0 accepted
    .mclk         (mclk),          // Main system clock
    .per_addr     (per_addr),      // Peripheral address
    .per_din      (per_din),       // Peripheral data input
    .per_en       (per_en),        // Peripheral enable (high active)
    .per_we       (per_we),        // Peripheral write enable (high active)
    .puc_rst      (puc_rst),       // Main system reset
    .smclk_en     (smclk_en),      // SMCLK enable (from CPU)
    .ta_cci0a     (ta_cci0a),      // Timer A capture 0 input A
    .ta_cci0b     (ta_cci0b),      // Timer A capture 0 input B
    .ta_cci1a     (ta_cci1a),      // Timer A capture 1 input A
    .ta_cci1b     (1'b0),          // Timer A capture 1 input B
    .ta_cci2a     (ta_cci2a),      // Timer A capture 2 input A
    .ta_cci2b     (1'b0),          // Timer A capture 2 input B
    .taclk        (taclk)          // TACLK external timer clock (SLOW)
);

//
// Simple full duplex UART (8N1 protocol)
//----------------------------------------

omsp_uart #(.BASE_ADDR(15'h0080)) hw_uart (

// OUTPUTs
    .irq_uart_rx  (irq_uart_rx),   // UART receive interrupt
    .irq_uart_tx  (irq_uart_tx),   // UART transmit interrupt
    .per_dout     (per_dout_uart), // Peripheral data output
    .uart_txd     (hw_uart_txd),   // UART Data Transmit (TXD)

// INPUTs
    .mclk         (mclk),          // Main system clock
    .per_addr     (per_addr),      // Peripheral address
    .per_din      (per_din),       // Peripheral data input
    .per_en       (per_en),        // Peripheral enable (high active)
    .per_we       (per_we),        // Peripheral write enable (high active)
    .puc_rst      (puc_rst),       // Main system reset
    .smclk_en     (smclk_en),      // SMCLK enable (from CPU)
    .uart_rxd     (hw_uart_rxd)    // UART Data Receive (RXD)
);

//
// Simple full duplex UART (8N1 protocol)
//----------------------------------------
// Used for debug output, no input, no interrupts

omsp_uart #(.BASE_ADDR(15'h0088)) hw_uart2 (

// OUTPUTs
    .irq_uart_rx  (),                  // UART receive interrupt
    .irq_uart_tx  (),                  // UART transmit interrupt
    .per_dout     (per_dout_uart2),    // Peripheral data output
    .uart_txd     (hw_uart2_txd),      // UART Data Transmit (TXD)

// INPUTs
    .mclk         (mclk),              // Main system clock
    .per_addr     (per_addr),          // Peripheral address
    .per_din      (per_din),           // Peripheral data input
    .per_en       (per_en),            // Peripheral enable (high active)
    .per_we       (per_we),            // Peripheral write enable (high active)
    .puc_rst      (puc_rst),           // Main system reset
    .smclk_en     (smclk_en),          // SMCLK enable (from CPU)
    .uart_rxd     (1'b0)               // UART Data Receive (RXD)
);

// UART used for the PmodCLS LCD module

//omsp_uart #(.BASE_ADDR(15'h0090)) lcd_uart (
//// OUTPUTs
//    .irq_uart_rx  (),                  // UART receive interrupt
//    .irq_uart_tx  (),                  // UART transmit interrupt
//    .per_dout     (per_dout_lcd_uart), // Peripheral data output
//    .uart_txd     (lcd_uart_txd),      // UART Data Transmit (TXD)
//
//// INPUTs
//    .mclk         (mclk),              // Main system clock
//    .per_addr     (per_addr),          // Peripheral address
//    .per_din      (per_din),           // Peripheral data input
//    .per_en       (per_en),            // Peripheral enable (high active)
//    .per_we       (per_we),            // Peripheral write enable (high active)
//    .puc_rst      (puc_rst),           // Main system reset
//    .smclk_en     (smclk_en),          // SMCLK enable (from CPU)
//    .uart_rxd     (1'b0)               // UART Data Receive (RXD)
//);

// PS/2

//omsp_ps2 ps2(
//    .per_dout (per_dout_ps2),
//    .irq_rx   (irq_rx_ps2),
//    .ps2_clk  (ps2_clk),
//    .ps2_data (ps2_data),
//    .mclk     (mclk),
//    .per_addr (per_addr),
//    .per_din  (per_din),
//    .per_en   (per_en),
//    .per_we   (per_we),
//    .puc_rst  (puc_rst)
//);

// TSC
omsp_tsc tsc(
    .per_dout (per_dout_tsc),
    .mclk     (mclk),
    .per_addr (per_addr),
    .per_din  (per_din),
    .per_en   (per_en),
    .per_we   (per_we),
    .puc_rst  (puc_rst)
);

// SPI master
omsp_spi_master spi_master(
    .per_dout   (per_dout_spi),
    .sck        (spi_sck),
    .ss         (spi_ss),
    .mosi       (spi_mosi),

    .mclk       (mclk),
    .miso       (spi_miso),
    .per_addr   (per_addr),
    .per_din    (per_din),
    .per_en     (per_en),
    .per_we     (per_we),
    .puc_rst    (puc_rst)
);

// LED digits
omsp_led_digits led_digits(
    .per_dout   (per_dout_led),
    .so         (led_so),

    .mclk       (mclk),
    .per_addr   (per_addr),
    .per_din    (per_din),
    .per_en     (per_en),
    .per_we     (per_we),
    .puc_rst    (puc_rst)
);


//
// Combine peripheral data buses
//-------------------------------

assign per_dout = per_dout_dio      |
                  per_dout_tA       |
                  per_dout_uart     |
                  per_dout_uart2    |
                  //per_dout_ps2      |
                  per_dout_tsc      |
                  per_dout_led      |
                  per_dout_spi;
//
// Assign interrupts
//-------------------------------

assign nmi        =  1'b0;
assign irq_bus    = {1'b0,         // Vector 13  (0xFFFA)
                     1'b0,         // Vector 12  (0xFFF8)
                     1'b0,         // Vector 11  (0xFFF6)
                     1'b0,         // Vector 10  (0xFFF4) - Watchdog -
                     irq_ta0,      // Vector  9  (0xFFF2)
                     irq_ta1,      // Vector  8  (0xFFF0)
                     irq_uart_rx,  // Vector  7  (0xFFEE)
                     irq_uart_tx,  // Vector  6  (0xFFEC)
                     1'b0, //irq_rx_ps2,   // Vector  5  (0xFFEA)
                     1'b0,         // Vector  4  (0xFFE8)
                     irq_port2,    // Vector  3  (0xFFE6)
                     irq_port1,    // Vector  2  (0xFFE4)
                     1'b0,         // Vector  1  (0xFFE2)
                     1'b0};        // Vector  0  (0xFFE0)

//
// GPIO Function selection
//--------------------------

// P1.0/TACLK      I/O pin / Timer_A, clock signal TACLK input
// P1.1/TA0        I/O pin / Timer_A, capture: CCI0A input, compare: Out0 output
// P1.2/TA1        I/O pin / Timer_A, capture: CCI1A input, compare: Out1 output
// P1.3/TA2        I/O pin / Timer_A, capture: CCI2A input, compare: Out2 output
// P1.4/SMCLK      I/O pin / SMCLK signal output
// P1.5/TA0        I/O pin / Timer_A, compare: Out0 output
// P1.6/TA1        I/O pin / Timer_A, compare: Out1 output
// P1.7/TA2        I/O pin / Timer_A, compare: Out2 output
wire [7:0] p1_io_mux_b_unconnected;
wire [7:0] p1_io_dout;
wire [7:0] p1_io_dout_en;
wire [7:0] p1_io_din;

io_mux #8 io_mux_p1 (
		     .a_din      (p1_din),
		     .a_dout     (p1_dout),
		     .a_dout_en  (p1_dout_en),

		     .b_din      ({p1_io_mux_b_unconnected[7],
                                   p1_io_mux_b_unconnected[6],
                                   p1_io_mux_b_unconnected[5],
                                   p1_io_mux_b_unconnected[4],
                                   ta_cci2a,
                                   ta_cci1a,
                                   ta_cci0a,
                                   taclk
                                  }),
		     .b_dout     ({ta_out2,
                                   ta_out1,
                                   ta_out0,
                                   (smclk_en & mclk),
                                   ta_out2,
                                   ta_out1,
                                   ta_out0,
                                   1'b0
                                  }),
		     .b_dout_en  ({ta_out2_en,
                                   ta_out1_en,
                                   ta_out0_en,
                                   1'b1,
                                   ta_out2_en,
                                   ta_out1_en,
                                   ta_out0_en,
                                   1'b0
                                  }),

   	 	     .io_din     (p1_io_din),
		     .io_dout    (p1_io_dout),
		     .io_dout_en (p1_io_dout_en),

		     .sel        (p1_sel)
);



// P2.0/ACLK       I/O pin / ACLK output
// P2.1/INCLK      I/O pin / Timer_A, clock signal at INCLK
// P2.2/TA0        I/O pin / Timer_A, capture: CCI0B input
// P2.3/TA1        I/O pin / Timer_A, compare: Out1 output
// P2.4/TA2        I/O pin / Timer_A, compare: Out2 output
wire [7:0] p2_io_mux_b_unconnected;
wire [7:0] p2_io_dout;
wire [7:0] p2_io_dout_en;
wire [7:0] p2_io_din;

io_mux #8 io_mux_p2 (
		     .a_din      (p2_din),
		     .a_dout     (p2_dout),
		     .a_dout_en  (p2_dout_en),

		     .b_din      ({p2_io_mux_b_unconnected[7],
                                   p2_io_mux_b_unconnected[6],
                                   p2_io_mux_b_unconnected[5],
                                   p2_io_mux_b_unconnected[4],
                                   p2_io_mux_b_unconnected[3],
                                   ta_cci0b,
                                   inclk,
                                   p2_io_mux_b_unconnected[0]
                                  }),
		     .b_dout     ({1'b0,
                                   1'b0,
                                   1'b0,
                                   ta_out2,
                                   ta_out1,
                                   1'b0,
                                   1'b0,
                                   (aclk_en & mclk)
                                  }),
		     .b_dout_en  ({1'b0,
                                   1'b0,
                                   1'b0,
                                   ta_out2_en,
                                   ta_out1_en,
                                   1'b0,
                                   1'b0,
                                   1'b1
                                  }),

  	 	     .io_din     (p2_io_din),
		     .io_dout    (p2_io_dout),
		     .io_dout_en (p2_io_dout_en),

		     .sel        (p2_sel)
);

// P1: 8 general purpose I/O pins on HAT connector
assign p1_io_din[0] = chan_io[7];
assign p1_io_din[1] = chan_io[8]; 
assign p1_io_din[2] = chan_io[9];
assign p1_io_din[3] = chan_io[10]; 
assign p1_io_din[4] = chan_io[11];
assign p1_io_din[5] = chan_io[12];
assign p1_io_din[6] = chan_io[13];
assign p1_io_din[7] = chan_io[14];

assign chan_io[7]  = p1_io_dout_en[0] ? p1_io_dout[0] : 1'bz;
assign chan_io[8]  = p1_io_dout_en[1] ? p1_io_dout[1] : 1'bz;
assign chan_io[9]  = p1_io_dout_en[2] ? p1_io_dout[2] : 1'bz;
assign chan_io[10] = p1_io_dout_en[3] ? p1_io_dout[3] : 1'bz;
assign chan_io[11] = p1_io_dout_en[4] ? p1_io_dout[4] : 1'bz;
assign chan_io[12] = p1_io_dout_en[5] ? p1_io_dout[5] : 1'bz;
assign chan_io[13] = p1_io_dout_en[6] ? p1_io_dout[6] : 1'bz;
assign chan_io[14] = p1_io_dout_en[7] ? p1_io_dout[7] : 1'bz;

// P3: 8 general purpose I/O pins on PM3/HAT connector
`ifndef FPGA_CHARLIE
    assign p3_din[0] = chan_io[29];
    assign p3_din[1] = chan_io[27]; 
    assign p3_din[2] = chan_io[25];
    assign p3_din[3] = chan_io[23]; 
    assign p3_din[4] = chan_io[30];
    assign p3_din[5] = chan_io[28];
    assign p3_din[6] = chan_io[26];
    assign p3_din[7] = chan_io[24];

    assign chan_io[29] = p3_dout_en[0] ? p3_dout[0] : 1'bz;
    assign chan_io[27] = p3_dout_en[1] ? p3_dout[1] : 1'bz;
    assign chan_io[25] = p3_dout_en[2] ? p3_dout[2] : 1'bz;
    assign chan_io[23] = p3_dout_en[3] ? p3_dout[3] : 1'bz;
    assign chan_io[30] = p3_dout_en[4] ? p3_dout[4] : 1'bz;
    assign chan_io[28] = p3_dout_en[5] ? p3_dout[5] : 1'bz;
    assign chan_io[26] = p3_dout_en[6] ? p3_dout[6] : 1'bz;
    assign chan_io[24] = p3_dout_en[7] ? p3_dout[7] : 1'bz;
`endif

//=============================================================================
// 6)  PROGRAM AND DATA MEMORIES
//=============================================================================

assign dmem_cen_n = ~ dmem_cen;
assign pmem_cen_n = ~ pmem_cen;
assign dmem_wen_n = ~ dmem_wen;
assign pmem_wen_n = ~ pmem_wen;


// Data Memory
ram_8x8k ram_hi (
    .addra         (dmem_addr),
    .clka          (clk_sys),
    .dina          (dmem_din[15:8]),
    .douta         (dmem_dout[15:8]),
    .ena           (dmem_cen_n),
    .wea           (dmem_wen_n[1])
);
ram_8x8k ram_lo (
    .addra         (dmem_addr),
    .clka          (clk_sys),
    .dina          (dmem_din[7:0]),
    .douta         (dmem_dout[7:0]),
    .ena           (dmem_cen_n),
    .wea           (dmem_wen_n[0])
);


// Program Memory
rom_8x20_5k rom_hi (
    .addra         (pmem_addr),
    .clka          (clk_sys),
    .dina          (pmem_din[15:8]),
    .douta         (pmem_dout[15:8]),
    .ena           (pmem_cen_n),
    .wea           (pmem_wen_n[1])
);

rom_8x20_5k rom_lo (
    .addra         (pmem_addr),
    .clka          (clk_sys),
    .dina          (pmem_din[7:0]),
    .douta         (pmem_dout[7:0]),
    .ena           (pmem_cen_n),
    .wea           (pmem_wen_n[0])
);
//
////assign chipscope_debug[15:0] =pmem_din;
////assign chipscope_debug[31:16] =pmem_dout;
////assign chipscope_debug[42:32] =pmem_addr;
////assign chipscope_debug[44:43] =pmem_wen_n;
////assign chipscope_debug[45] =pmem_cen_n;
//////assign chipscope_debug[46] =reset_n;
////assign chipscope_debug[46] = openMSP430_0.spm_violation;
////assign chipscope_debug[47] =reset_pin;
////assign chipscope_debug[48] =dcm_locked;
//////assign chipscope_debug[49] =DBG_OFF;
////assign chipscope_debug[49] =0;
////assign chipscope_debug[62:50] = 14'h000000;
////assign chipscope_debug[63] = mclk;
//
//
////=============================================================================
//// 7)  I/O CELLS
////=============================================================================
//
//
//// Slide Switches (Port 1 inputs)
////--------------------------------
//IBUF  SW3_PIN        (.O(p4_din[3]),                   .I(SW3));
//IBUF  SW2_PIN        (.O(p4_din[2]),                   .I(SW2));
//IBUF  SW1_PIN        (.O(p4_din[1]),                   .I(SW1));
//IBUF  SW0_PIN        (.O(dbg_sw),                      .I(SW0));
//assign p4_din[0] = dbg_sw;

// LEDs (Port 1 outputs)
//-----------------------
//OBUF  LED3_PIN       (.I(p3_dout[3] & p3_dout_en[3]),  .O(LED3));
//OBUF  LED2_PIN       (.I(p3_dout[2] & p3_dout_en[2]),  .O(LED2));
//OBUF  LED1_PIN       (.I(p3_dout[1] & p3_dout_en[1]),  .O(LED1));
//OBUF  LED0_PIN       (.I(p3_dout[0] & p3_dout_en[0]),  .O(LED0));
//OBUF  LED0_PIN       (.I(spm_violation),  .O(LED0));
//OBUF  PULSE_PIN      (.I(p3_dout[1] & p3_dout_en[1]),  .O(PULSE));

// RS-232 Port
//----------------------
// P1.1 (TX) and P2.2 (RX)
//assign p2_io_din[1:0] = 2'h00;
//assign p2_io_din[7:3] = 5'h00;

//assign DBG_OFF = 1'b0;
//wire   uart_txd_out =  DBG_OFF ? p1_io_dout[1] : dbg_uart_txd;
//wire   uart_rxd_in;
//assign p2_io_din[2] =  DBG_OFF ? uart_rxd_in  :1'b1;
//assign dbg_uart_rxd =  DBG_OFF ? 1'b1 :uart_rxd_in ;


//IBUF  UART_RXD_PIN   (.O(dbg_uart_rxd),                .I(UART_RXD));
//OBUF  UART_TXD_PIN   (.I(dbg_uart_txd),                .O(UART_TXD));
//
//IBUF  EXT_UART_RXD_PIN   (.O(hw_uart_rxd),             .I(EXT_UART_RXD));
//OBUF  EXT_UART_TXD_PIN   (.I(hw_uart_txd),             .O(EXT_UART_TXD));
//
//OBUF  EXT_UART_TXD2_PIN  (.I(hw_uart2_txd),            .O(EXT_UART_TXD2));

//
////DEBUG
////wire        [64:0] chipscope_debug;
////wire        [35:0] chipscope_control;
////chipscope_ila chipscope_ila (
////    .CONTROL (chipscope_control),
////    .CLK (clk_sys),
////    .TRIG0 (chipscope_debug));
////
////chipscope_icon chipscope_icon(
////    .CONTROL0 (chipscope_control) );
//
//assign MCLK = clk_sys;

endmodule // openMSP430_fpga
