`include "openMSP430_defines.v"

/*
 * Company: KU Leuven
 * Engineer: Anthony Van Herrewege
 *
 * Create Date:    07/12/2011
 * Module Name:    SPONGENT core
 *
 * Description:
 *  Parametrized implementation of the SPONGENT hash function
 *
 *  Ports:
 *    clk                 - clock signal
 *    reset               - active high reset signal
 *    start_continue      - high to start SPONGENT iteration
 *    msg_data_available  - high if there's data to
 *      be absorbed, low to squeeze
 *    busy                - active high busy signal
 *    data_in             - r-bit data input
 *    data_out            - r-bit data output
 *
 *  When the busy signal goes low, the SPONGENT round function
 *  has been executed an appropriate number of times. The output
 *  squeezing phase can then be started by making start_continue
 *  high again, while keeping msg_data_available low. Another r
 *  bits of output will then be generated.
 *
 *  If more data hash to be hashed, raise start_continue while also
 *  keeping msg_data_available high.
 *
 * Parameters:
 *  STATE_SIZE  - Internal state size
 *  RATE        - Rate of input & output (i.e. width of data_in & data_out)
 *  LFSR_POLY   - LFSR polynomial
 *  LFSR_INIT   - LFSR initial value (1 bit smaller than LFSR_POLY)
 *
 * Revision:
 *  Revision 0.01 - File Created
 *
 */
module spongent #(
    parameter integer MIN_CAPACITY = 128,
    parameter integer RATE         = 8    // Input block width
) (
    clk,
    reset,
    start_continue,
    msg_data_available,
    busy,
    data_in,
    data_out
  );

  // Define parameters
  localparam MIN_WIDTH = RATE + MIN_CAPACITY;

  localparam STATE_SIZE = MIN_WIDTH <=  88 ?  88 :
                          MIN_WIDTH <= 136 ? 136 :
                          MIN_WIDTH <= 176 ? 176 :
                          MIN_WIDTH <= 240 ? 240 :
                          MIN_WIDTH <= 264 ? 264 :
                          MIN_WIDTH <= 272 ? 272 :
                          MIN_WIDTH <= 336 ? 336 :
                          MIN_WIDTH <= 384 ? 384 :
                          MIN_WIDTH <= 480 ? 480 :
                          MIN_WIDTH <= 672 ? 672 :
                          MIN_WIDTH <= 768 ? 768 : 'hx;

  localparam LFSR_SIZE = STATE_SIZE <=  88 ? 6 :
                         STATE_SIZE <= 240 ? 7 :
                         STATE_SIZE <= 480 ? 8 : 9;

  localparam LFSR_POLY = LFSR_SIZE == 6 ? 7'b1100001   :
                         LFSR_SIZE == 7 ? 8'b11000001  :
                         LFSR_SIZE == 8 ? 9'b100011101 : 10'b1000010001;

  localparam LFSR_INIT = STATE_SIZE ==  88 ? 6'h05  :
                         STATE_SIZE == 136 ? 7'h7a  :
                         STATE_SIZE == 176 ? 7'h45  :
                         STATE_SIZE == 240 ? 7'h01  :
                         STATE_SIZE == 264 ? 8'hd2  :
                         STATE_SIZE == 272 ? 8'h9e  :
                         STATE_SIZE == 336 ? 8'h52  :
                         STATE_SIZE == 384 ? 8'hfb  :
                         STATE_SIZE == 480 ? 8'ha7  :
                         STATE_SIZE == 672 ? 9'h105 : 9'h015;

  // Define ports
  input clk, reset;
  input start_continue, msg_data_available;
  output busy;

  input [RATE - 1:0] data_in;
  output [RATE - 1:0] data_out;

  // Declare wires
  wire reset_state, sample_state;
  wire init_lfsr, update_lfsr, lfsr_all_1;
  wire select_message;

  // Instantiate modules
  spongent_fsm fsm_instance (
      .clk                  (clk),
      .reset                (reset),
      .start_continue       (start_continue),
      .msg_data_available   (msg_data_available),
      .busy                 (busy),
      .reset_state          (reset_state),
      .sample_state         (sample_state),
      .init_lfsr            (init_lfsr),
      .update_lfsr          (update_lfsr),
      .lfsr_all_1           (lfsr_all_1),
      .select_message       (select_message)
    );

  spongent_datapath #(
    .STATE_SIZE (STATE_SIZE),
    .RATE       (RATE),
    .LFSR_SIZE  (LFSR_SIZE),
    .LFSR_POLY  (LFSR_POLY),
    .LFSR_INIT  (LFSR_INIT)
    ) datapath_instance (
      .clk            (clk),
      .data_in        (data_in),
      .data_out       (data_out),
      .reset_state    (reset_state),
      .sample_state   (sample_state),
      .init_lfsr      (init_lfsr),
      .update_lfsr    (update_lfsr),
      .lfsr_all_1     (lfsr_all_1),
      .select_message (select_message)
    );

// debug output ****************************************************************
`ifndef ASIC
    initial
    begin
        $display("=== Spongent parameters ===");
        $display("Rate:       %3d", RATE);
        $display("State size: %3d", STATE_SIZE);
        $display("===========================");
    end
`endif

endmodule
