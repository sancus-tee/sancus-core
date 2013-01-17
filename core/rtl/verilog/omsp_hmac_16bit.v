module omsp_hmac_16bit(
  input  wire                clk,
  input  wire                reset,
  input  wire                start_continue,
  input  wire                data_available,
  input  wire                data_is_long,
  input  wire [0:KEY_SIZE-1] key,
  input  wire         [15:0] data_in,
  output reg          [15:0] data_out,
  output reg                 busy
);

parameter integer KEY_SIZE = 128;

// FSM
parameter integer STATE_SIZE = 4;
parameter [STATE_SIZE-1:0] RESET      = 0,
                           INIT       = 1,
                           IDLE       = 2,
                           DLY_IN1    = 3,
                           IN1        = 4,
                           WAIT_IN1   = 5,
                           DLY_IN2    = 6,
                           IN2        = 7,
                           WAIT_IN2   = 8,
                           WAIT_OUT1  = 9,
                           OUT1       = 10,
                           DLY_OUT2   = 11,
                           WAIT_OUT2  = 12,
                           OUT2       = 13;

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
  case (state)
    RESET:      next_state = start_continue   ? INIT        : RESET;
    INIT:       next_state = hmac_busy        ? INIT        : DLY_IN2;
    IDLE:       next_state = ~start_continue  ? IDLE        :
                             data_available   ? DLY_IN1     : WAIT_OUT1;
    DLY_IN1:    next_state =                    IN1;
    IN1:        next_state =                    WAIT_IN1;
    WAIT_IN1:   next_state = hmac_busy        ? WAIT_IN1    :
                             data_is_long     ? DLY_IN2     : IDLE;
    DLY_IN2:    next_state =                    IN2;
    IN2:        next_state =                    WAIT_IN2;
    WAIT_IN2:   next_state = hmac_busy        ? WAIT_IN2    : IDLE;
    WAIT_OUT1:  next_state = hmac_busy        ? WAIT_OUT1   : OUT1;
    OUT1:       next_state =                    WAIT_OUT2;
    WAIT_OUT2:  next_state = hmac_busy        ? WAIT_OUT2   : OUT2;
    OUT2:       next_state =                    IDLE;

    default:    next_state =                    {STATE_SIZE{1'bx}};
  endcase

always @(posedge clk)
  if (reset)
    state <= RESET;
  else
    state <= next_state;

// hmac input data register
reg [7:0] hmac_data_in;
reg       first_input;

always @(posedge clk)
  if (reset)
    hmac_data_in <= 8'b0;
  else if (first_input)
    hmac_data_in <= data_in[15:8];
  else
    hmac_data_in <= data_in[7:0];

// hmac data output
wire [7:0] hmac_data_out;
reg        update_output;
reg        first_output;

always @(posedge clk)
  if (reset)
    data_out <= 16'b0;
  else if (update_output)
    if (first_output)
      data_out[15:8] <= hmac_data_out;
    else
      data_out[7:0]  <= hmac_data_out;

// output logic
always @(*)
begin
  first_input = data_is_long;
  update_output = 0;
  first_output = 1;
  busy = 1;
  hmac_start_continue = 0;
  hmac_data_available = 0;

  case (next_state)
    RESET:
    begin
      busy = 0;
    end

    INIT:
    begin
      hmac_start_continue = 1;
      hmac_data_available = 1;
    end

    IDLE:
    begin
      busy = 0;
    end

    IN1:
    begin
      hmac_start_continue = 1;
      hmac_data_available = 1;
    end

    WAIT_IN1:
    begin
    end

    DLY_IN2:
    begin
      first_input = 0;
    end

    IN2:
    begin
      hmac_start_continue = 1;
      hmac_data_available = 1;
    end

    WAIT_IN2:
    begin
    end

    WAIT_OUT1:
    begin
      hmac_start_continue = 1;
    end

    OUT1:
    begin
      update_output = 1;
    end

    WAIT_OUT2:
    begin
      hmac_start_continue = 1;
    end

    OUT2:
    begin
      update_output = 1;
      first_output = 0;
    end
  endcase
end

// hmac instantiation
wire hmac_busy;
reg  hmac_start_continue;
reg  hmac_data_available;

omsp_hmac #(.KEY_SIZE(KEY_SIZE)) hmac(
  .clk            (clk),
  .reset          (reset),
  .start_continue (hmac_start_continue),
  .data_available (hmac_data_available),
  .key            (key),
  .data_in        (hmac_data_in),
  .data_out       (hmac_data_out),
  .busy           (hmac_busy)
);

endmodule
