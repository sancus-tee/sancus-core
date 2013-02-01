/*
 * Company: KU Leuven
 * Engineer: Anthony Van Herrewege
 *
 * Create Date:    07/12/2011
 * Module Name:    SPONGENT S-box
 *
 * Description:
 *  4-bit S-box for the SPONGENT hash function
 *
 *  Ports:
 *    data_in     - 4-bit data input
 *    data_out    - 4-bit data output
 *
 * Revision:
 *  Revision 0.01 - File Created
 *
 */
module spongent_sbox (
    data_in,
    data_out
  );

  // Define ports
  input [3:0] data_in;
  output [3:0] data_out;

  // Declare "registers"
  reg [3:0] data_out;

  // Define S-box
  always @(*) begin
    data_out = 4'bx; // Set output undefined to easily debug errors.

    case (data_in)
      4'h0:  data_out = 4'he;
      4'h1:  data_out = 4'hd;
      4'h2:  data_out = 4'hb;
      4'h3:  data_out = 4'h0;
      4'h4:  data_out = 4'h2;
      4'h5:  data_out = 4'h1;
      4'h6:  data_out = 4'h4;
      4'h7:  data_out = 4'hf;
      4'h8:  data_out = 4'h7;
      4'h9:  data_out = 4'ha;
      4'ha:  data_out = 4'h8;
      4'hb:  data_out = 4'h5;
      4'hc:  data_out = 4'h9;
      4'hd:  data_out = 4'hc;
      4'he:  data_out = 4'h3;
      4'hf:  data_out = 4'h6;
    endcase
  end

endmodule
