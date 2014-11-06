module spi_master(
    input  wire             clk,
    input  wire             rst,
    input  wire             miso,
    input  wire             start,
    input  wire             cpol,
    input  wire             cpha,
    input  wire [WIDTH-1:0] clk_div,
    input  wire [WIDTH-1:0] data_in,

    output reg              sck,
    output wire             mosi,
    output wire             busy,
    output wire [WIDTH-1:0] data_out
);

localparam WIDTH = 8;

// FSM
localparam STATE_SIZE = 2;
localparam [STATE_SIZE-1:0] IDLE     = 0,
                            INIT     = 1,
                            TRANSFER = 2,
                            FINISH   = 3;

reg [STATE_SIZE-1:0] state, state_next;

always @(*)
    case (state)
        IDLE:       state_next = start         ? INIT   : IDLE;
        INIT:       state_next = TRANSFER;
        TRANSFER:   state_next = transfer_done ? FINISH : TRANSFER;
        FINISH:     state_next = clk_ctr_wrap  ? IDLE   : FINISH;
    endcase

always @(posedge clk)
    if (rst)
        state <= IDLE;
    else
        state <= state_next;

// control signals
wire tx_on_rising = cpol != cpha;
wire rx_on_rising = ~tx_on_rising;
wire ignore_tx    = cpha && (buffer_ctr == 0);

assign busy = state != IDLE;

reg init;
reg sck_run;
reg do_tx;
reg do_rx;

always @(*)
begin
    init = 0;
    sck_run = 0;
    do_tx = 0;
    do_rx = 0;

    case (state_next)
        IDLE:
        begin
        end

        INIT:
        begin
            init = 1;
        end

        TRANSFER:
        begin
            sck_run = 1;

            if (~ignore_tx)
            begin
                do_tx = ( tx_on_rising && sck_rising) ||
                        (~tx_on_rising && sck_falling);
            end

            do_rx = ( rx_on_rising && sck_rising) ||
                    (~rx_on_rising && sck_falling);
        end

        FINISH:
        begin
        end
    endcase
end

// sck generation
reg [WIDTH-1:0] clk_ctr;
wire clk_ctr_wrap = clk_ctr == clk_div;

always @(posedge clk)
    if (rst || init || clk_ctr_wrap)
        clk_ctr <= 0;
    else
        clk_ctr <= clk_ctr + 1;

wire sck_base = cpol;
wire sck_next = ~sck_run ? sck_base : clk_ctr_wrap ? ~sck : sck;

always @(posedge clk)
    if (rst)
        sck <= 0;
    else
        sck <= sck_next;

wire sck_rising  = ~sck &&  sck_next;
wire sck_falling =  sck && ~sck_next;

// capture register
reg capture;

always @(posedge clk)
    if (rst)
        capture <= 0;
    else if (do_rx)
        capture <= miso;

// buffer
reg [WIDTH-1:0] buffer;

assign mosi     = buffer[WIDTH-1];
assign data_out = buffer;

always @(posedge clk)
    if (rst)
        buffer <= 0;
    else if (start)
        buffer <= data_in;
    else if (do_tx)
        buffer <= {buffer[WIDTH-2:0], capture};

// transfer counter
parameter CTR_WIDTH = $clog2(WIDTH + 1);

reg [CTR_WIDTH-1:0] buffer_ctr;
wire do_count = cpol ? sck_rising : sck_falling;

always @(posedge clk)
    if (rst || init)
        buffer_ctr <= 0;
    else if (do_count)
        buffer_ctr <= buffer_ctr + 1;

wire transfer_done = (state == TRANSFER) && (buffer_ctr == WIDTH);

endmodule
