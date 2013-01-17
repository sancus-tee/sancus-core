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
module spongent_parallel (
    clk,
    reset,
    start_continue,
    msg_data_available,
    busy,
    data_in,
    data_out
  );

  /*
  // Constant functions
  function integer clog2;
    input integer value;
    begin
      value = value-1;
      for (clog2=0; value>0; clog2=clog2+1)
        value = value>>1;
    end
  endfunction
  */

  // Define parameters
  parameter integer STATE_SIZE          = 136;          // State size
  parameter integer RATE                = 8;            // Input block width
  parameter LFSR_POLY                   = 8'b11000001;  // LFSR polynomial

  //localparam integer LFSR_SIZE          = clog2(LFSR_POLY + 1) - 1;  // Size of LFSR
  parameter integer LFSR_SIZE          = $clog2(LFSR_POLY + 1) - 1;  // Size of LFSR

  parameter [LFSR_SIZE - 1:0] LFSR_INIT = 7'b1111010;   // LFSR initial value

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
    .LFSR_POLY  (LFSR_POLY),
    .LFSR_INIT  (LFSR_INIT),
    .LFSR_SIZE  (LFSR_SIZE)
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

endmodule
