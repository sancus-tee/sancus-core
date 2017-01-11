/*
 * Company: KU Leuven
 * Engineer: Anthony Van Herrewege
 *
 * Create Date:    07/12/2011
 * Module Name:    SPONGENT FSM
 *
 * Description:
 *  FSM for the SPONGENT hash function
 *
 *  Ports:
 *    clk               - clock signal
 *    reset             - active high, synchronous reset signal
 *    start_continue    - high to start SPONGENT iteration
 *    msg_data_avaiable - high if absorbing data, low to squeeze
 *    busy              - active high busy signal
 *    reset_state       - high to reset state to all 0
 *    sample_state      - high to let state sample result of round function
 *    init_lfsr         - high to initialize LFSR
 *    update_lfsr       - high to clock LFSR for 1 cycle
 *    lfsr_all_1        - high if LFSR is all 1s
 *    select_message    - high to xor message input data into state
 *
 * Revision:
 *  Revision 0.01 - File Created
 *
 */
module spongent_fsm (
    clk,
    reset,
    start_continue,
    msg_data_available,
    busy,
    reset_state,
    sample_state,
    init_lfsr,
    update_lfsr,
    lfsr_all_1,
    select_message
  );

  // Define parameters
  localparam integer STATE_SIZE = 4;
  localparam [STATE_SIZE - 1:0] UNDEFINED = {STATE_SIZE{1'bx}},
                                RESET     = 'b1,
                                IDLE      = 'b10,
                                ABSORB    = 'b100,
                                ROUNDS    = 'b1000;

  // Define ports
  input clk, reset;
  input start_continue, msg_data_available;
  output busy;

  output reset_state, sample_state;
  output init_lfsr, update_lfsr;
  input lfsr_all_1;
  output select_message;

  // Declare registers
  reg [STATE_SIZE - 1:0] state_current;
  reg [STATE_SIZE - 1:0] state_next;

  reg reg_busy;

  // Declare "registers" for FSM
  wire reset_state;
  wire init_lfsr;

  reg sample_state;
  reg update_lfsr;
  reg select_message;

  reg set_busy;
  reg unset_busy;

  // Reset for datapath
  assign reset_state = reset;
  assign init_lfsr = reset | lfsr_all_1;

  // Busy signal
  assign busy = reg_busy;

  `ifndef ASIC
    initial reg_busy <= 0;
  `endif
  always @(posedge clk) begin
    if (unset_busy)     reg_busy <= 0;
    else if (set_busy)  reg_busy <= 1;
    else                reg_busy <= reg_busy;
  end

  // State machine
  always @ (posedge clk or posedge reset) begin
    if (reset)  state_current <= RESET;
    else        state_current <= state_next;
  end

  // State transitions
  always @ (*) begin
    state_next = UNDEFINED;

    case (state_current)
      RESET:  state_next = IDLE;
      IDLE: begin
        if (start_continue) begin
          if (msg_data_available) state_next = ABSORB;
          else                    state_next = ROUNDS;
        end else                  state_next = IDLE;
      end
      ABSORB: state_next = ROUNDS;
      ROUNDS: begin // Continue as long as not all LFSR bits are one
        if (lfsr_all_1) state_next = IDLE;
        else            state_next = ROUNDS;
      end
    endcase
  end

  // State dependent outputs
  always @ (*) begin
    // Default outputs
    sample_state = 0;

    update_lfsr = 0;

    select_message = 0;

    set_busy = 0;
    unset_busy = 0;

    case (state_next)
      IDLE: begin
        unset_busy = 1;
      end

      ABSORB: begin
        select_message = 1;
        sample_state = 1;
        update_lfsr = 1;

        set_busy = 1;
      end

      ROUNDS: begin
        sample_state = 1;
        update_lfsr = 1;

        set_busy = 1;
      end
    endcase
  end

  /*
  always @ (negedge clk) begin
    case (state_current)
      RESET:    $display("%d [RESET]", $time);
      IDLE:     $display("%d [IDLE]", $time);
      ABSORB:   $display("%d [ABSORB]", $time);
      ROUNDS:   $display("%d [ROUNDS]", $time);

      default:  $display("%d [RESET]", $time);
    endcase
  end
  */

endmodule
