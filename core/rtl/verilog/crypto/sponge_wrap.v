`include "openMSP430_defines.v"

module sponge_wrap #(
    parameter RATE     = 16,
    parameter SECURITY = 64
) (
    input  wire                clk,
    input  wire                reset,
    input  wire                start_continue,
    input  wire                unwrap,
    input  wire     [RATE-1:0] data_in,
    input  wire                data_empty,
    input  wire                last_block,
    input  wire [0:SECURITY-1] key,
    output wire                busy,
    output wire     [RATE-1:0] data_out,
    output reg                 data_out_ready
);

localparam SPONGE_RATE      = RATE + 2;
localparam SPONGE_CAPACITY  = SECURITY * 2;
localparam KEY_SIZE         = SECURITY;
localparam KEY_BLOCKS       = KEY_SIZE / RATE;

`ifdef ASIC
    localparam KEY_COUNTER_SIZE = $clog2(KEY_BLOCKS + 1);
`else
    // use parameter instead of localparam to work around a bug in XST
    parameter KEY_COUNTER_SIZE = $clog2(KEY_BLOCKS + 1);
`endif

// control signal declarations *************************************************
reg  duplex_key;
reg  duplex_output;
reg  duplex_blank;
reg  xor_data_out;

// other signal declarations ***************************************************
wire key_done;
wire sponge_busy;
wire [SPONGE_RATE-1:0] sponge_data_out;

// helper functions ************************************************************
integer i;
function [RATE-1:0] reverse_bytes;
    input [RATE-1:0] word;
    for (i = 0; i < RATE; i = i + 8)
        reverse_bytes[RATE-i-1-:8] = word[i+7-:8];
endfunction

// state machine ***************************************************************
localparam STATE_SIZE = 4;
localparam [STATE_SIZE-1:0] RESET     =  0,
                            IDLE      =  1,
                            KEY       =  2,
                            KEY_WAIT  =  3,
                            AD_IDLE   =  4,
                            AD        =  5,
                            AD_WAIT   =  6,
                            BODY_IDLE =  7,
                            BODY      =  8,
                            BODY_WAIT =  9,
                            TAG_IDLE  = 10,
                            TAG       = 11,
                            TAG_WAIT  = 12;

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
    case (state)
        RESET:      next_state =                  IDLE;
        IDLE:       next_state = start_continue ? KEY       : IDLE;
        KEY:        next_state =                  KEY_WAIT;
        KEY_WAIT:   next_state = sponge_busy    ? KEY_WAIT  :
                                 key_done       ? AD        : KEY;
        AD_IDLE:    next_state = start_continue ? AD        : AD_IDLE;
        AD:         next_state =                  AD_WAIT;
        AD_WAIT:    next_state = sponge_busy    ? AD_WAIT   :
                                 last_block     ? BODY_IDLE : AD_IDLE;
        BODY_IDLE:  next_state = start_continue ? BODY      : BODY_IDLE;
        BODY:       next_state =                  BODY_WAIT;
        BODY_WAIT:  next_state = sponge_busy    ? BODY_WAIT :
                                 last_block     ? TAG_IDLE  : BODY_IDLE;
        TAG_IDLE:   next_state = start_continue ? TAG       : TAG_IDLE;
        TAG:        next_state =                  TAG_WAIT;
        TAG_WAIT:   next_state = sponge_busy    ? TAG_WAIT  : TAG_IDLE;

        default:    next_state = {STATE_SIZE{1'bx}};
    endcase

always @(posedge clk)
    if (reset)
        state <= RESET;
    else
        state <= next_state;

// control signals *************************************************************
always @(*)
begin
    duplex_key = 0;
    duplex_output = 0;
    duplex_blank = 0;
    data_out_ready = 0;
    xor_data_out = 0;

    case (next_state)
        RESET:
        begin
        end

        IDLE:
        begin
        end

        KEY:
        begin
            duplex_key = 1;
        end

        KEY_WAIT:
        begin
        end

        AD_IDLE:
        begin
        end

        AD:
        begin
        end

        AD_WAIT:
        begin
        end

        BODY_IDLE:
        begin
        end

        BODY:
        begin
            data_out_ready = 1;
            xor_data_out = 1;
            duplex_output = unwrap;
        end

        BODY_WAIT:
        begin
        end

        TAG_IDLE:
        begin
        end

        TAG:
        begin
            duplex_blank = 1;
            data_out_ready = 1;
        end

        TAG_WAIT:
        begin
        end
    endcase
end

// internal logic **************************************************************

wire idle = (state == RESET)     |
            (state == IDLE)      |
            (state == AD_IDLE)   |
            (state == BODY_IDLE) |
            (state == TAG_IDLE);

assign busy = !idle;

// counter used to keep track how much of the key has been duplexed
reg [KEY_COUNTER_SIZE-1:0] key_counter;

always @(posedge clk)
    if (reset)
        key_counter <= 0;
    else if (duplex_key)
        key_counter <= key_counter + 1;

assign key_done = key_counter == KEY_BLOCKS;

// frame bit generation
wire key_next  = (state == IDLE | state == KEY_WAIT) & ~key_done;
wire ad_next   = state == KEY_WAIT | state == AD_IDLE | state == AD_WAIT;
wire body_next = state == BODY_IDLE | state == BODY_WAIT;

wire frame_bit = key_next  ? key_counter != KEY_BLOCKS - 1 :
                 ad_next   ? last_block                    :
                 body_next ? ~last_block                   :
                             1'b0;

// sponge start_continue genereation
wire idle_start = state == IDLE;
wire ad_start   = state == AD_IDLE;
wire body_start = state == BODY_IDLE;
wire tag_start  = state == TAG_IDLE;
wire all_start  = idle_start | ad_start | body_start | tag_start;

wire sponge_start_continue = (all_start & start_continue) |
                             (state == KEY_WAIT & ~sponge_busy);

// sponge input generation
wire [RATE-1:0] key_block = reverse_bytes(key[key_counter*RATE+:RATE]);
// wire [RATE-1:0] block = reverse_bytes(duplex_key    ? key_block :
//                                       duplex_output ? data_out  : data_in);
wire [RATE-1:0] block = duplex_key    ? key_block :
                        duplex_output ? data_out  : data_in;

wire [SPONGE_RATE-1:0] sponge_data_in =
    duplex_blank ? 'b1                                      :
    data_empty   ? {{SPONGE_RATE-2{1'b0}}, 1'b1, frame_bit} :
                   {1'b1, frame_bit, block};

// output generation
// assign data_out = reverse_bytes(sponge_data_out[RATE-1:0]) ^
//                   (xor_data_out ? data_in : {RATE{1'b0}});
assign data_out = sponge_data_out[RATE-1:0] ^
                  (xor_data_out ? data_in : {RATE{1'b0}});

// module instantiations *******************************************************
spongent #(
    .RATE               (SPONGE_RATE),
    .MIN_CAPACITY       (SPONGE_CAPACITY)
) sponge (
    .clk                (clk),
    .reset              (reset),
    .start_continue     (sponge_start_continue),
    .msg_data_available (sponge_start_continue),
    .busy               (sponge_busy),
    .data_in            (sponge_data_in),
    .data_out           (sponge_data_out)
);

// debug output ****************************************************************
`ifndef ASIC
    initial
    begin
        $display("=== SpongeWrap parameters ===");
        $display("Rate:          %3d", RATE);
        $display("Security:      %3d", SECURITY);
        $display("Blocks in key: %3d", KEY_BLOCKS);
        $display("=============================");
    end
`endif

endmodule
