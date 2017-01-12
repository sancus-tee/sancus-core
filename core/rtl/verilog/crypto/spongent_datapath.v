/*
 * Company: KU Leuven
 * Engineer: Anthony Van Herrewege
 *
 * Create Date:    07/12/2011
 * Module Name:    SPONGENT datapath
 *
 * Description:
 *  Parametrized datapath for the SPONGENT hash function
 *
 *  Ports:
 *    clk             - clock
 *    data_in         - message data input
 *    data_out        - hash data output
 *    reset_state     - high to reset state to all 0
 *    sample_state    - high to let state sample result of round function
 *    init_lfsr       - high to initialize LFSR
 *    update_lfsr     - high to clock LFSR for 1 cycle
 *    lfsr_all_1      - high if LFSR is all 1s
 *    select_message  - high to xor message input data into state
 *
 * Parameters:
 *  STATE_SIZE  - Internal state size
 *  RATE        - Rate at which input arrives (i.e. width of data_in port)
 *  LFSR_POLY   - LFSR polynomial
 *  LFSR_INIT   - LFSR initial value (1 bit smaller than LFSR_POLY)
 *
 * Revision:
 *  Revision 0.01 - File Created
 *
 */
module spongent_datapath (
    clk,
    data_in,
    data_out,
    reset_state,
    sample_state,
    init_lfsr,
    update_lfsr,
    lfsr_all_1,
    select_message
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
  parameter integer LFSR_SIZE           = 8;            // Size of LFSR
  parameter         LFSR_POLY           = 8'b11000001;  // LFSR polynomial
  parameter         LFSR_INIT           = 7'b1111010;   // LFSR initial value

  localparam integer NUM_SBOXES         = (STATE_SIZE + 3) / 4; // Number of S-boxes needed

  // Define ports
  input clk;

  input [(RATE - 1):0] data_in;
  output [(RATE - 1):0] data_out;

  input reset_state, sample_state;
  input init_lfsr, update_lfsr;
  input select_message;

  output lfsr_all_1;

  // Declare registers
  reg [(STATE_SIZE - 1):0] reg_state;

  // Declare wires
  wire [(STATE_SIZE - 1):0] player_input;
  wire [(STATE_SIZE - 1):0] player_output;

  wire [3:0] sbox_input [(NUM_SBOXES - 1):0];
  wire [3:0] sbox_output [(NUM_SBOXES - 1):0];

  wire [(LFSR_SIZE - 1):0] lfsr_data;
  wire [(LFSR_SIZE - 1):0] lfsr_data_inverse;

  wire [(RATE - 1):0] message_select_output;
  wire [(RATE - 1):0] message_lfsr_xor;     // Message xored with LFSR

  wire [(STATE_SIZE - 1):0] input_xor_result; // State xored with mask

  //wire clk_state /* synthesis attribute clock_signal of clk_state is yes */;
  //wire clk_state_buffered;

  // Instantiate & generate modules
  spongent_player #(
      .SPONGENT_B (STATE_SIZE)
    ) player_instance (
      .data_in  (player_input),
      .data_out (player_output)
    );

  lfsr #(
      .LFSR_POLY (LFSR_POLY),
      .LFSR_INIT (LFSR_INIT),
      .LFSR_SIZE (LFSR_SIZE)
    ) lfsr_instance (
      .clk      (clk),
      .reset    (init_lfsr),
      .enable   (update_lfsr),
      .data_out (lfsr_data)
    );

  // Create lfsr output with inversed bits
  generate
    genvar gen_i;
    for (gen_i = 0; gen_i < LFSR_SIZE; gen_i = gen_i + 1) begin : gen_for_lfsr
      assign lfsr_data_inverse[gen_i] = lfsr_data[LFSR_SIZE - 1 - gen_i];
    end
  endgenerate

  // Generate all S-boxes & connect signals
  generate
    genvar gen_j;

    for (gen_j = 0; gen_j < NUM_SBOXES; gen_j = gen_j + 1) begin : gen_for_sbox
      spongent_sbox sbox_instance (
        .data_in  (sbox_input[gen_j]),
        .data_out (sbox_output[gen_j])
        );

      assign sbox_input[gen_j] = input_xor_result[(4 * gen_j)+:4];
      assign player_input[(4 * gen_j)+:4] = sbox_output[gen_j];
    end
  endgenerate

  // Assign wire values
  assign message_select_output = select_message ? data_in : { RATE { 1'b0 } };

  assign message_lfsr_xor = lfsr_data ^ message_select_output;
  assign input_xor_result = { lfsr_data_inverse ^ reg_state[(STATE_SIZE - 1)-:LFSR_SIZE], reg_state[(STATE_SIZE - 1 - LFSR_SIZE):RATE], message_lfsr_xor ^ reg_state[RATE - 1:0] };

  assign data_out = reg_state[RATE - 1:0];

  assign lfsr_all_1 = &lfsr_data;

  /*
  // Clock gating for state register
  assign clk_state = ~(sample_state | reset_state) | clk;
  */

  // Buffer clock to prevent skew
  /*
  BUFG instance_bufg (
    .I  (clk_state),
    .O  (clk_state_buffered)
  );
  */
 //assign clk_state_buffered = clk_state;

  // Logic for state register
  // Clock gating with synchronous reset
  //always @ (posedge clk_state_buffered) begin
  always @ (posedge clk) begin
    if (reset_state)        reg_state <= 0;
    else if (sample_state)  reg_state <= player_output;
    else                    reg_state <= reg_state;

    //if (reset_state | sample_state)  #1 $display("%d\tS: %h", $time, reg_state);
  end

endmodule
