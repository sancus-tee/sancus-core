`include "openMSP430_defines.v"

module crypto_control(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    start,
    input  wire                    cmd_key,
    input  wire                    cmd_wrap,
    input  wire                    cmd_unwrap,
    input  wire                    cmd_verify_addr,
    input  wire                    cmd_verify_prev,
    input  wire                    cmd_id,
    input  wire                    cmd_id_prev,
    input  wire             [15:0] mem_in,
    input  wire             [15:0] pc,
    input  wire             [15:0] r10,
    input  wire             [15:0] r11,
    input  wire             [15:0] r12,
    input  wire             [15:0] r13,
    input  wire             [15:0] r14,
    input  wire             [15:0] r15,
    input  wire             [15:0] sm_data,
    input  wire    [0:`SECURITY-1] sm_key,
    input  wire             [15:0] sm_prev_id,
    input  wire                    sm_data_select_valid,
    input  wire                    sm_key_select_valid,

    output reg                     busy,
    output reg               [2:0] sm_request,
    output wire             [15:0] sm_data_select,
    output wire                    sm_data_select_type,
    output wire             [15:0] sm_key_select,
    output reg                     mb_en,
    output reg               [1:0] mb_wr,
    output wire             [15:0] mab,
    output reg                     reg_write,
    output reg                     sm_key_write,
    output wire [KEY_IDX_SIZE-1:0] sm_key_idx,
    output reg              [15:0] data_out
);

parameter KEY_IDX_SIZE = -1;

// key selection constants
localparam [1:0] KEY_SEL_NONE   = 0,
                 KEY_SEL_MASTER = 1,
                 KEY_SEL_SM     = 2;

function [15:0] swap_bytes;
    input [15:0] word;
    swap_bytes = {word[7:0], word[15:8]};
endfunction

// state machine ***************************************************************
localparam STATE_SIZE = 6;
localparam [STATE_SIZE-1:0] IDLE             =  0,
                            CHECK_SM         =  1,
                            WRAP_AD_INIT     =  2,
                            WRAP_AD          =  3,
                            WRAP_AD_WAIT     =  4,
                            WRAP_BODY_INIT   =  5,
                            WRAP_BODY        =  6,
                            WRAP_BODY_WAIT   =  7,
                            TAG_INIT         =  8,
                            WRITE_TAG        =  9,
                            WRITE_TAG_WAIT   = 10,
                            VERIFY_TAG       = 11,
                            VERIFY_TAG_WAIT  = 12,
                            GEN_VKEY_INIT    = 13,
                            WRAP_VID         = 14,
                            WRAP_VID_WAIT    = 15,
                            WRITE_VKEY_INIT  = 16,
                            WRITE_VKEY       = 17,
                            WRITE_VKEY_WAIT  = 18,
                            GEN_SMKEY_INIT   = 19,
                            GEN_SMKEY_INIT2  = 20,
                            WRAP_TEXT        = 21,
                            WRAP_TEXT_WAIT   = 22,
                            WRAP_PS          = 23,
                            WRAP_PS_WAIT     = 24,
                            WRAP_PE          = 25,
                            WRAP_PE_WAIT     = 26,
                            WRAP_SS          = 27,
                            WRAP_SS_WAIT     = 28,
                            WRAP_SE          = 29,
                            WRAP_SE_WAIT     = 30,
                            WRITE_SMKEY_INIT = 31,
                            WRITE_SMKEY      = 32,
                            WRITE_SMKEY_WAIT = 33,
                            VERIFY_INIT      = 34,
                            VERIFY_INIT2     = 35,
                            MAC_INIT         = 36,
                            MAC_INIT_WAIT    = 37,
                            FAIL             = 38,
                            SUCCESS          = 39,
                            INTERNAL_ERROR   = {STATE_SIZE{1'bx}};

reg [STATE_SIZE-1:0] state, next_state;

always @(*)
    case (state)
        IDLE:             next_state = start       ? CHECK_SM         : IDLE;
        CHECK_SM:         next_state = ~sm_valid   ? FAIL             :
                                       do_wrap     ? WRAP_AD_INIT     :
                                       cmd_key     ? GEN_VKEY_INIT    :
                                       do_verify   ? VERIFY_INIT      :
                                       cmd_id      ? SUCCESS          :
                                       cmd_id_prev ? SUCCESS          : INTERNAL_ERROR;
        WRAP_AD_INIT:     next_state =               WRAP_AD_WAIT;
        WRAP_AD:          next_state =               WRAP_AD_WAIT;
        WRAP_AD_WAIT:     next_state = wrap_busy   ? WRAP_AD_WAIT     :
                                       mem_done    ? WRAP_BODY_INIT   : WRAP_AD;
        WRAP_BODY_INIT:   next_state =               WRAP_BODY_WAIT;
        WRAP_BODY:        next_state =               WRAP_BODY_WAIT;
        WRAP_BODY_WAIT:   next_state = wrap_busy   ? WRAP_BODY_WAIT   :
                                       mem_done    ? TAG_INIT         : WRAP_BODY;
        TAG_INIT:         next_state = cmd_wrap    ? WRITE_TAG_WAIT   : VERIFY_TAG_WAIT;
        WRITE_TAG:        next_state =               WRITE_TAG_WAIT;
        WRITE_TAG_WAIT:   next_state = wrap_busy   ? WRITE_TAG_WAIT   :
                                       mem_done    ? SUCCESS          : WRITE_TAG;
        VERIFY_TAG:       next_state = tag_ok      ? VERIFY_TAG_WAIT  : FAIL;
        VERIFY_TAG_WAIT:  next_state = mem_done    ? SUCCESS          :
                                       wrap_busy   ? VERIFY_TAG_WAIT  : VERIFY_TAG;
        GEN_VKEY_INIT:    next_state =               WRAP_VID;
        WRAP_VID:         next_state =               WRAP_VID_WAIT;
        WRAP_VID_WAIT:    next_state = wrap_busy   ? WRAP_VID_WAIT    : WRITE_VKEY_INIT;
        WRITE_VKEY_INIT:  next_state =               WRITE_VKEY_WAIT;
        WRITE_VKEY:       next_state =               WRITE_VKEY_WAIT;
        WRITE_VKEY_WAIT:  next_state = key_done    ? GEN_SMKEY_INIT   :
                                       wrap_busy   ? WRITE_VKEY_WAIT  : WRITE_VKEY;
        GEN_SMKEY_INIT:   next_state =               GEN_SMKEY_INIT2;
        GEN_SMKEY_INIT2:  next_state =               WRAP_TEXT_WAIT;
        WRAP_TEXT:        next_state =               WRAP_TEXT_WAIT;
        WRAP_TEXT_WAIT:   next_state = wrap_busy   ? WRAP_TEXT_WAIT   :
                                       mem_done    ? WRAP_PS          : WRAP_TEXT;
        WRAP_PS:          next_state =               WRAP_PS_WAIT;
        WRAP_PS_WAIT:     next_state = wrap_busy   ? WRAP_PS_WAIT     : WRAP_PE;
        WRAP_PE:          next_state =               WRAP_PE_WAIT;
        WRAP_PE_WAIT:     next_state = wrap_busy   ? WRAP_PE_WAIT     : WRAP_SS;
        WRAP_SS:          next_state =               WRAP_SS_WAIT;
        WRAP_SS_WAIT:     next_state = wrap_busy   ? WRAP_SS_WAIT     : WRAP_SE;
        WRAP_SE:          next_state =               WRAP_SE_WAIT;
        WRAP_SE_WAIT:     next_state = wrap_busy   ? WRAP_SE_WAIT     :
                                       do_verify   ? MAC_INIT         : WRITE_SMKEY_INIT;
        WRITE_SMKEY_INIT: next_state =               WRITE_SMKEY_WAIT;
        WRITE_SMKEY:      next_state =               WRITE_SMKEY_WAIT;
        WRITE_SMKEY_WAIT: next_state = key_done    ? SUCCESS          :
                                       wrap_busy   ? WRITE_SMKEY_WAIT : WRITE_SMKEY;
        VERIFY_INIT:      next_state =               VERIFY_INIT2;
        VERIFY_INIT2:     next_state =               WRAP_TEXT_WAIT;
        MAC_INIT:         next_state =               MAC_INIT_WAIT;
        MAC_INIT_WAIT:    next_state = wrap_busy   ? MAC_INIT_WAIT    : TAG_INIT;
        FAIL:             next_state =               IDLE;
        SUCCESS:          next_state =               IDLE;

        default:          next_state =               INTERNAL_ERROR;
    endcase

always @(posedge clk)
    if (reset)
        state <= IDLE;
    else
        state <= next_state;

// control signals *************************************************************
reg        wrap_reset;
reg        wrap_start_continue;
reg        wrap_last_block;
reg        wrap_data_empty;
reg [15:0] wrap_data_in_val;
reg        update_wrap_data_in;
reg        set_wrap_start_continue;

always @(*)
begin
    busy = 1;
    wrap_reset = 0;
    wrap_last_block = 0;
    wrap_data_empty = 0;
    wrap_data_in_val = 0;
    update_wrap_data_in = 0;
    set_wrap_start_continue = 0;
    mab_ctr_init = 0;
    mab_ctr_inc = 0;
    mab_ctr_base = 0;
    mab_ctr_limit_init = 0;
    mab_ctr_limit = 0;
    mab_cipher_init = 0;
    mab_cipher_inc = 0;
    mab_cipher_base = 0;
    mab_select_cipher = 0;
    mb_en = 0;
    mb_wr = 0;
    reg_write = 0;
    data_out = 0;
    key_ctr_reset = 0;
    key_ctr_inc = 0;
    update_key_select = 0;
    key_select_val = KEY_SEL_NONE;
    sm_key_write = 0;
    sm_request = 0;

    case (next_state)
        IDLE:
        begin
            busy = 0;
            wrap_reset = 1;
        end

        CHECK_SM:
        begin
        end

        WRAP_AD_INIT:
        begin
            update_key_select = 1;
            key_select_val = KEY_SEL_SM;
            mab_ctr_init = 1;
            mab_ctr_base = r10;
            mab_ctr_limit_init = 1;
            mab_ctr_limit = r11;
        end

        WRAP_AD:
        begin
            wrap_data_in_val = mem_in;
            update_wrap_data_in = 1;
            set_wrap_start_continue = 1;
            mab_ctr_inc = 1;
        end

        WRAP_AD_WAIT:
        begin
            mb_en = 1;
            wrap_last_block = mem_done;
        end

        WRAP_BODY_INIT:
        begin
            mab_ctr_init = 1;
            mab_ctr_base = r12;
            mab_ctr_limit_init = 1;
            mab_ctr_limit = r13;
            mab_cipher_init = 1;
            mab_cipher_base = r14;
        end

        WRAP_BODY:
        begin
            wrap_data_in_val = mem_in;
            update_wrap_data_in = 1;
            set_wrap_start_continue = 1;
            mab_ctr_inc = 1;
        end

        WRAP_BODY_WAIT:
        begin
            mb_en = 1;
            mb_wr = wrap_data_out_ready ? 2'b11 : 2'b00;
            mab_select_cipher = wrap_data_out_ready;
            mab_cipher_inc = wrap_data_out_ready;
            data_out = wrap_data_out;
            wrap_last_block = mem_done;
        end

        TAG_INIT:
        begin
            mab_ctr_init = 1;
            mab_ctr_base = r15;
            mab_ctr_limit_init = 1;
            mab_ctr_limit = r15 + `SECURITY / 8;
        end

        WRITE_TAG:
        begin
            set_wrap_start_continue = 1;
        end

        WRITE_TAG_WAIT:
        begin
            mb_en = wrap_data_out_ready;
            mb_wr = 2'b11;
            mab_ctr_inc = wrap_data_out_ready;
            data_out = wrap_data_out;
        end

        VERIFY_TAG:
        begin
            set_wrap_start_continue = 1;
            mb_en = 1;
        end

        VERIFY_TAG_WAIT:
        begin
            mb_en = 1;
            mab_ctr_inc = wrap_data_out_ready;
        end

        GEN_VKEY_INIT:
        begin
            update_key_select = 1;
            key_select_val = KEY_SEL_MASTER;
        end

        WRAP_VID:
        begin
            wrap_data_in_val = r11;
            update_wrap_data_in = 1;
            set_wrap_start_continue = 1;
        end

        WRAP_VID_WAIT:
        begin
            wrap_last_block = 1;
        end

        WRITE_VKEY_INIT:
        begin
            update_key_select = 1;
            key_select_val = KEY_SEL_SM;
            key_ctr_reset = 1;
            set_wrap_start_continue = 1;
        end

        WRITE_VKEY:
        begin
            sm_key_write = 1;
            data_out = wrap_key_out;
            key_ctr_inc = 1;
            set_wrap_start_continue = 1;
        end

        WRITE_VKEY_WAIT:
        begin
            wrap_last_block = 1;
            wrap_data_empty = 1;
        end

        GEN_SMKEY_INIT:
        begin
            wrap_reset = 1;
            update_key_select = 1;
            key_select_val = KEY_SEL_SM;
            sm_request = `SM_REQ_PUBSTART;
            mab_ctr_init = 1;
            mab_ctr_base = sm_data;
        end

        GEN_SMKEY_INIT2:
        begin
            sm_request = `SM_REQ_PUBEND;
            mab_ctr_limit_init = 1;
            mab_ctr_limit = sm_data;
        end

        WRAP_TEXT:
        begin
            update_wrap_data_in = 1;
            wrap_data_in_val = mem_in;
            mab_ctr_inc = 1;
            set_wrap_start_continue = 1;
        end

        WRAP_TEXT_WAIT:
        begin
            mb_en = 1;
        end

        WRAP_PS:
        begin
            sm_request = `SM_REQ_PUBSTART;
            update_wrap_data_in = 1;
            wrap_data_in_val = sm_data;
            set_wrap_start_continue = 1;
        end

        WRAP_PS_WAIT:
        begin
        end


        WRAP_PE:
        begin
            sm_request = `SM_REQ_PUBEND;
            update_wrap_data_in = 1;
            wrap_data_in_val = sm_data;
            set_wrap_start_continue = 1;
        end

        WRAP_PE_WAIT:
        begin
        end

        WRAP_SS:
        begin
            sm_request = `SM_REQ_SECSTART;
            update_wrap_data_in = 1;
            wrap_data_in_val = sm_data;
            set_wrap_start_continue = 1;
        end

        WRAP_SS_WAIT:
        begin
        end

        WRAP_SE:
        begin
            sm_request = `SM_REQ_SECEND;
            update_wrap_data_in = 1;
            wrap_data_in_val = sm_data;
            set_wrap_start_continue = 1;
        end

        WRAP_SE_WAIT:
        begin
            wrap_last_block = 1;
        end

        WRITE_SMKEY_INIT:
        begin
            set_wrap_start_continue = 1;
            key_ctr_reset = 1;
        end

        WRITE_SMKEY:
        begin
            set_wrap_start_continue = 1;
            sm_key_write = 1;
            data_out = wrap_key_out;
            key_ctr_inc = 1;
        end

        WRITE_SMKEY_WAIT:
        begin
            wrap_last_block = 1;
            wrap_data_empty = 1;
        end

        VERIFY_INIT:
        begin
            update_key_select = 1;
            key_select_val = KEY_SEL_SM;
            sm_request = `SM_REQ_PUBSTART;
            mab_ctr_init = 1;
            mab_ctr_base = sm_data;
        end

        VERIFY_INIT2:
        begin
            sm_request = `SM_REQ_PUBEND;
            mab_ctr_limit_init = 1;
            mab_ctr_limit = sm_data;
        end

        MAC_INIT:
        begin
            set_wrap_start_continue = 1;
        end

        MAC_INIT_WAIT:
        begin
            wrap_last_block = 1;
            wrap_data_empty = 1;
        end

        FAIL:
        begin
            reg_write = 1;
            data_out = 16'h0;
        end

        SUCCESS:
        begin
            reg_write = 1;
            sm_request = `SM_REQ_ID;
            data_out = return_id   ? sm_data    :
                       cmd_id_prev ? sm_prev_id : 16'h1;
        end
    endcase
end

// other logic *****************************************************************
wire do_wrap   = cmd_wrap | cmd_unwrap;
wire do_verify = cmd_verify_addr | cmd_verify_prev;

// memory address counter used when looping over a range of addresses
reg [15:0] mab_ctr;
reg [15:0] mab_ctr_base;
reg        mab_ctr_init;
reg        mab_ctr_inc;

always @(posedge clk)
    if (mab_ctr_init)
        mab_ctr <= mab_ctr_base;
    else if (mab_ctr_inc)
        mab_ctr <= mab_ctr + 2;

reg [15:0] mab_ctr_limit, mab_ctr_limit_reg;
reg        mab_ctr_limit_init;

always @(posedge clk)
    if (mab_ctr_limit_init)
        mab_ctr_limit_reg <= mab_ctr_limit;

wire mem_done = mab_ctr >= mab_ctr_limit_reg;

// secondary memory address used for cipher output
reg [15:0] mab_cipher;
reg [15:0] mab_cipher_base;
reg        mab_cipher_init;
reg        mab_cipher_inc;

always @(posedge clk)
    if (mab_cipher_init)
        mab_cipher <= mab_cipher_base;
    else if (mab_cipher_inc)
        mab_cipher <= mab_cipher + 2;

// mab selection
reg mab_select_cipher;

assign mab = mab_select_cipher ? mab_cipher : mab_ctr;

// input data for sponge wrap
reg [15:0] wrap_data_in;

always @(posedge clk)
    if (update_wrap_data_in)
        wrap_data_in <= wrap_data_in_val;

always @(posedge clk)
    if (reset | !set_wrap_start_continue)
        wrap_start_continue <= 0;
    else
        wrap_start_continue <= 1;

// signal to indicate if the tag matches with the memory contents
wire tag_ok = wrap_data_out_ready ? (wrap_data_out == mem_in) : 1;

reg [KEY_IDX_SIZE-1:0] key_ctr;
reg                    key_ctr_reset;
reg                    key_ctr_inc;

always @(posedge clk)
    if (reset | key_ctr_reset)
        key_ctr <= 0;
    else if (key_ctr_inc)
        key_ctr <= key_ctr + 1;

wire key_done = key_ctr == `SECURITY / 16;

assign sm_key_idx = key_ctr;

// master key
wire [0:`SECURITY-1] master_key = `MASTER_KEY;

// key selection
reg [0:`SECURITY-1] key;
reg           [1:0] key_select;
reg           [1:0] key_select_val;
reg                 update_key_select;

always @(*)
    case (key_select)
        KEY_SEL_MASTER: key = master_key;
        KEY_SEL_SM:     key = sm_key;
        default:        key = `SECURITY'hx;
    endcase

always @(posedge clk)
    if (reset)
        key_select <= KEY_SEL_NONE;
    else if (update_key_select)
        key_select <= key_select_val;

// since the output of the wrap module is LE and keys are stored BE, create a
// swapped version to be used for keys
wire [15:0] wrap_key_out = swap_bytes(wrap_data_out);

// SM key selection
assign sm_key_select = cmd_key ? r12 : pc;

// SM data selection
assign sm_data_select_type =
    cmd_verify_prev ? `SM_SELECT_BY_ID : `SM_SELECT_BY_ADDR;

assign sm_data_select = cmd_key         ? r12        :
                        cmd_id          ? r15        :
                        cmd_verify_addr ? r14        :
                        cmd_verify_prev ? sm_prev_id : 16'hx;

// valid SM selected
wire sm_data_needed = cmd_key | do_verify | cmd_id;
wire sm_key_needed  = !cmd_id;
wire sm_valid = (!sm_data_needed | sm_data_select_valid) &
                (!sm_key_needed  | sm_key_select_valid);

// return value selection
wire return_id = do_verify | cmd_id | cmd_key;

// module instantiations *******************************************************
wire        wrap_busy;
wire [15:0] wrap_data_out;
wire        wrap_data_out_ready;

sponge_wrap #(
    .RATE           (16),
    .SECURITY       (`SECURITY)
) wrap(
    .clk            (clk),
    .reset          (reset | wrap_reset),
    .start_continue (wrap_start_continue),
    .unwrap         (cmd_unwrap),
    .data_in        (wrap_data_in),
    .data_empty     (wrap_data_empty),
    .last_block     (wrap_last_block),
    .key            (key),
    .busy           (wrap_busy),
    .data_out       (wrap_data_out),
    .data_out_ready (wrap_data_out_ready)
);

endmodule
