/*
 * Company: KU Leuven
 * Engineer: Anthony Van Herrewege
 *
 * Create Date:    07/12/2011
 * Module Name:    SPONGENT P-layer
 *
 * Description:
 *  Parametrized permutation layer for the SPONGENT hash function
 *
 *  Ports:
 *    data_in     - b-bit data input
 *    data_out    - b-bit data output
 *
 * Revision:
 *  Revision 0.01 - File Created
 *
 */
module spongent_player (
    data_in,
    data_out
  );

  // Define parameters
  parameter integer SPONGENT_B = 136;  // Parameter b of SPONGENT hash

  // Define ports
  input [SPONGENT_B - 1:0] data_in;
  output [SPONGENT_B - 1:0] data_out;

  // Declare "registers"
  reg [SPONGENT_B - 1:0] data_out;

  // Declare integers
  integer i;
  integer pb;

  // Define permutation layer
  always @(*) begin
    data_out = 'bx; // Set output undefined to easily debug errors.

    // Special case for MSB
    data_out[SPONGENT_B - 1] = data_in[SPONGENT_B - 1];

    // Rest of the bits
    for (i = 0; i < (SPONGENT_B - 1); i = i + 1) begin
      // Calculate new bit position & assign it
      pb = (i * (SPONGENT_B / 4)) % (SPONGENT_B - 1);
      data_out[pb] = data_in[i];
    end
  end

  // Debugging - Print permutation layer
  /*
  initial begin
    $display("p_out[%d] = p_in[%d]", SPONGENT_B - 1, SPONGENT_B - 1);
    for (i = 0; i < (SPONGENT_B - 1); i = i + 1) begin
      pb = (i * (SPONGENT_B / 4)) % (SPONGENT_B - 1);
      $display("p_out[%d] = p_in[%d]", pb, i);
    end
  end
  */

endmodule
