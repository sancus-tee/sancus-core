module file_io (
    output wire [15:0] per_dout,
    input  wire        mclk,
    input  wire [13:0] per_addr,
    input  wire [15:0] per_din,
    input  wire        per_en,
    input  wire  [1:0] per_we,
`ifdef VERILATOR
    input  wire [7:0]  fio_din,
    input  wire        fio_dready,
    output reg [7:0]   fio_dout,
    output reg         fio_dnxt,
    output reg         fio_dout_rdy,
`endif
    input  wire        puc_rst
);

//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR = 15'h00c0;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD    = 2;

// Register addresses offset
parameter [DEC_WD-1:0] STATUS    = 'h0,
                       DATA      = 'h2;

// Register one-hot decoder utilities
parameter              DEC_SZ    = (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG  = {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] STATUS_D  = (BASE_REG << STATUS),
                       DATA_D    = (BASE_REG << DATA);

//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel      = per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr     = {1'b0, per_addr[DEC_WD-2:0]};

// Register address decode
wire [DEC_SZ-1:0] reg_dec      = (STATUS_D & {DEC_SZ{(reg_addr==(STATUS >> 1))}}) |
                                 (DATA_D   & {DEC_SZ{(reg_addr==(DATA   >> 1))}});

// Read/Write probes
wire              reg_lo_write =  per_we[0] & reg_sel;
wire              reg_hi_write =  per_we[1] & reg_sel;
wire              reg_read     = ~|per_we   & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_hi_wr    = reg_dec & {DEC_SZ{reg_hi_write}};
wire [DEC_SZ-1:0] reg_lo_wr    = reg_dec & {DEC_SZ{reg_lo_write}};
wire [DEC_SZ-1:0] reg_rd       = reg_dec & {DEC_SZ{reg_read}};

//============================================================================
// 3) REGISTERS
//============================================================================

// File handles
integer in_file, out_file;

initial
begin
`ifndef VERILATOR
    $display("=== File I/O ===");

`ifdef FILEIO_IN
    in_file = $fopen(`FILEIO_IN, "rb+");
    if (in_file == 0)
    begin
        $display("Fail: unable to open '%s' for reading", `FILEIO_IN);
        $finish;
    end
    $display("Input:  '%s'", `FILEIO_IN);
`endif

`ifdef FILEIO_OUT
    out_file = $fopen(`FILEIO_OUT, "wb+");
    if (out_file == 0)
    begin
        $display("Fail: unable to open '%s' for writing", `FILEIO_OUT);
        $finish;
    end
    $display("Output: '%s'", `FILEIO_OUT);
`endif

    $display("================");
`endif /* VERILATOR */
end

// DATA Register
//-----------------
reg  [7:0] data;

wire       data_wr  = DATA[0] ? reg_hi_wr[DATA] : reg_lo_wr[DATA];
wire [7:0] data_nxt = DATA[0] ? per_din[15:8]   : per_din[7:0];

// Writes to the DATA register
`ifndef VERILATOR
reg        data_ready;

`ifdef FILEIO_OUT
always @ (posedge mclk or posedge puc_rst)
    if (data_wr)
        if ($fputc(data_nxt, out_file) != 0)
            $display("File I/O: write error");
        else
            $fflush(out_file);
`endif

// Reads from the DATA register
`ifdef FILEIO_IN
integer in_char;

always @(posedge mclk or posedge puc_rst)
    if (puc_rst | reg_rd[DATA])
    begin
        data <= 8'hab;
        data_ready <= 1'b0;
    end
    else if (!data_ready)
    begin
        in_char = $fgetc(in_file);
        if (in_char != -1)
        begin
            data <= in_char;
            data_ready <= 1'b1;
        end
    end
`else
initial begin
    data_ready <= 1'b0;
end
`endif

// STATUS Register
//-----------------
wire [7:0] status = {7'b0, data_ready};

`else /* VERILATOR */

// Writes to the DATA register
always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)
        fio_dout_rdy <= 0;
    else if (data_wr) begin
        fio_dout <= data_nxt;
        fio_dout_rdy <= 1;
    end else
        fio_dout_rdy <= 0;

// Reads from the DATA register
always @(posedge mclk or posedge puc_rst)
    if (puc_rst)
    begin
        data <= 8'hff;
        fio_dnxt <= 1'b0;
    end
    else if (reg_rd[DATA])
        fio_dnxt <= 1'b1;
    else begin
        data <= fio_din;
        fio_dnxt <= 1'b0;
    end

// STATUS Register
//-----------------
wire [7:0] status = {7'b0, fio_dready};

`endif /* VERILATOR */

//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

// Data output mux
wire [15:0] status_rd = {8'h00, (status & {8{reg_rd[STATUS]}})} << (8 & {4{STATUS[0]}});
wire [15:0] data_rd   = {8'h00, (data   & {8{reg_rd[DATA]}})}   << (8 & {4{DATA[0]}});

assign      per_dout  =  status_rd | data_rd;

endmodule
