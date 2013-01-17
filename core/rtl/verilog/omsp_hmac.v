module omsp_hmac(
  input  wire                clk,
  input  wire                reset,
  input  wire                start_continue,
  input  wire                data_available,
  input  wire [0:KEY_SIZE-1] key,
  input  wire     [RATE-1:0] data_in,
  output wire     [RATE-1:0] data_out,
  output reg                 busy
);

parameter integer KEY_SIZE = 128;
parameter integer RATE     = 8;

wire            spongent_busy;

// FSM
localparam integer STATE_SIZE = 5;
localparam [STATE_SIZE-1:0] IDLE            = 0,
                            INNER_KEY       = 1,
                            INNER_KEY_WAIT  = 2,
                            INNER_MSG       = 3,
                            INNER_MSG_WAIT  = 4,
                            INNER_IDLE      = 5,
                            INNER_PAD       = 6,
                            INNER_PAD_WAIT  = 7,
                            INNER_HASH      = 8,
                            INNER_HASH_WAIT = 9,
                            RESET_SPONGENT  = 10,
                            OUTER_KEY_INIT  = 11,
                            OUTER_KEY       = 12,
                            OUTER_KEY_WAIT  = 13,
                            OUTER_MSG_INIT  = 14,
                            OUTER_MSG       = 15,
                            OUTER_MSG_WAIT  = 16,
                            OUTER_PAD       = 17,
                            OUTER_PAD_WAIT  = 18,
                            OUTPUT          = 19,
                            OUTPUT_WAIT     = 20;

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
  case (state)
    IDLE:             next_state = ~start_continue ? IDLE            :
                                   data_available  ? INNER_KEY       : OUTPUT;
    INNER_KEY:        next_state =                   INNER_KEY_WAIT;
    INNER_KEY_WAIT:   next_state = spongent_busy   ? INNER_KEY_WAIT  :
                                   counter_done    ? INNER_MSG       : INNER_KEY;
    INNER_MSG:        next_state =                   INNER_MSG_WAIT;
    INNER_MSG_WAIT:   next_state = spongent_busy   ? INNER_MSG_WAIT  : INNER_IDLE;
    INNER_IDLE:       next_state = ~start_continue ? INNER_IDLE      :
                                   data_available  ? INNER_MSG       : INNER_PAD;
    INNER_PAD:        next_state =                   INNER_PAD_WAIT;
    INNER_PAD_WAIT:   next_state = spongent_busy   ? INNER_PAD_WAIT  : INNER_HASH;
    INNER_HASH:       next_state = counter_done    ? RESET_SPONGENT  : INNER_HASH_WAIT;
    INNER_HASH_WAIT:  next_state = spongent_busy   ? INNER_HASH_WAIT : INNER_HASH;
    RESET_SPONGENT:   next_state =                   OUTER_KEY_INIT;
    OUTER_KEY_INIT:   next_state =                   OUTER_KEY;
    OUTER_KEY:        next_state =                   OUTER_KEY_WAIT;
    OUTER_KEY_WAIT:   next_state = spongent_busy   ? OUTER_KEY_WAIT  :
                                   counter_done    ? OUTER_MSG_INIT  : OUTER_KEY;
    OUTER_MSG_INIT:   next_state =                   OUTER_MSG;
    OUTER_MSG:        next_state =                   OUTER_MSG_WAIT;
    OUTER_MSG_WAIT:   next_state = spongent_busy   ? OUTER_MSG_WAIT  :
                                   counter_done    ? OUTER_PAD       : OUTER_MSG;
    OUTER_PAD:        next_state =                   OUTER_PAD_WAIT;
    OUTER_PAD_WAIT:   next_state = spongent_busy   ? OUTER_PAD_WAIT  : IDLE;
    OUTPUT:           next_state =                   OUTPUT_WAIT;
    OUTPUT_WAIT:      next_state = spongent_busy   ? OUTPUT_WAIT     :
                                   counter_done    ? IDLE            : OUTPUT;

    default:          next_state = {STATE_SIZE{1'bx}};
  endcase

always @(posedge clk)
  if (reset)
    state <= IDLE;
  else
    state <= next_state;

// counter that keeps track of how many bits of the key are processed
// TODO parameter for the counter size
localparam COUNTER_SIZE = 8;

reg [COUNTER_SIZE-1:0] counter;
reg                    count;
reg                    reset_counter;
wire                   counter_done = counter == KEY_SIZE;// / RATE;

always @(posedge clk)
  if (reset | reset_counter)
    counter <= {COUNTER_SIZE{1'b0}};
  else if (count)
    counter <= counter + RATE;

// key selection
reg             is_inner_key;
wire [RATE-1:0] key_select = key[counter+:RATE];
wire [RATE-1:0] key_data   = key_select ^ {RATE/8{is_inner_key ? 8'h36 : 8'h5c}};

// inner hash storage
reg                 store_inner_hash;
reg  [0:KEY_SIZE-1] inner_hash;
wire     [RATE-1:0] hash_data = inner_hash[counter+:RATE];

always @(posedge clk)
  if (reset)
    inner_hash <= {KEY_SIZE{1'b0}};
  else if (store_inner_hash)
    inner_hash[counter+:RATE] <= data_out;

// data selection
localparam integer DATA_SELECT_SIZE = 3;
localparam [DATA_SELECT_SIZE-1:0] DATA_NONE = 0,
                                  DATA_MSG  = 1,
                                  DATA_KEY  = 2,
                                  DATA_HASH = 3,
                                  DATA_PAD  = 4;

reg [DATA_SELECT_SIZE-1:0] data_select;
reg             [RATE-1:0] spongent_data_in;

always @(*)
  case (data_select)
    DATA_MSG:  spongent_data_in = data_in;
    DATA_KEY:  spongent_data_in = key_data;
    DATA_HASH: spongent_data_in = hash_data;
    DATA_PAD:  spongent_data_in = {1'b1, {RATE-1{1'b0}}};

    default:   spongent_data_in = {DATA_SELECT_SIZE{1'bx}};
  endcase

// control signals
always @(*)
begin
  busy = 1;
  count = 0;
  reset_counter = 1;
  spongent_reset = 0;
  is_inner_key = 0;
  data_select = DATA_NONE;
  store_inner_hash = 0;
  spongent_start_continue = 0;
  spongent_data_available = 0;

  case (next_state)
    IDLE:
    begin
      busy = 0;
    end

    INNER_KEY:
    begin
      count = 1;
      reset_counter = 0;
      is_inner_key = 1;
      data_select = DATA_KEY;
      spongent_start_continue = 1;
      spongent_data_available = 1;
    end

    INNER_KEY_WAIT:
    begin
      reset_counter = 0;
    end

    INNER_MSG:
    begin
      data_select = DATA_MSG;
      spongent_start_continue = 1;
      spongent_data_available = 1;
    end

    INNER_MSG_WAIT:
    begin
    end

    INNER_IDLE:
    begin
      busy = 0;
    end

    INNER_PAD:
    begin
      data_select = DATA_PAD;
      spongent_start_continue = 1;
      spongent_data_available = 1;
    end

    INNER_PAD_WAIT:
    begin
    end

    INNER_HASH:
    begin
      count = 1;
      reset_counter = counter_done;
      store_inner_hash = 1;
      spongent_start_continue = 1;
    end

    INNER_HASH_WAIT:
    begin
      reset_counter = 0;
    end

    RESET_SPONGENT:
    begin
      spongent_reset = 1;
    end

    OUTER_KEY_INIT:
    begin
    end

    OUTER_KEY:
    begin
      count = 1;
      reset_counter = 0;
      data_select = DATA_KEY;
      spongent_start_continue = 1;
      spongent_data_available = 1;
    end

    OUTER_KEY_WAIT:
    begin
      reset_counter = 0;
    end

    OUTER_MSG_INIT:
    begin
    end

    OUTER_MSG:
    begin
      count = 1;
      reset_counter = 0;
      data_select = DATA_HASH;
      spongent_start_continue = 1;
      spongent_data_available = 1;
    end

    OUTER_MSG_WAIT:
    begin
      reset_counter = 0;
    end

    OUTER_PAD:
    begin
      data_select = DATA_PAD;
      spongent_start_continue = 1;
      spongent_data_available = 1;
    end

    OUTER_PAD_WAIT:
    begin
    end

    OUTPUT:
    begin
      busy = 0;
      spongent_start_continue = 1;
    end

    OUTPUT_WAIT:
    begin
    end

  endcase
end

// spongent instantiation
reg spongent_data_available;
reg spongent_start_continue;
reg spongent_reset;

spongent_parallel spongent(
  .clk                (clk),
  .reset              (spongent_reset | reset),
  .start_continue     (spongent_start_continue),
  .msg_data_available (spongent_data_available),
  .busy               (spongent_busy),
  .data_in            (spongent_data_in),
  .data_out           (data_out)
);

endmodule
