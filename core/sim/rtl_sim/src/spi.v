/*===========================================================================*/
/* Copyright (C) 2001 Authors                                                */
/*                                                                           */
/* This source file may be used and distributed without restriction provided */
/* that this copyright statement is not removed from the file and that any   */
/* derivative work contains the original copyright notice and the associated */
/* disclaimer.                                                               */
/*                                                                           */
/* This source file is free software; you can redistribute it and/or modify  */
/* it under the terms of the GNU Lesser General Public License as published  */
/* by the Free Software Foundation; either version 2.1 of the License, or    */
/* (at your option) any later version.                                       */
/*                                                                           */
/* This source is distributed in the hope that it will be useful, but WITHOUT*/
/* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or     */
/* FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public       */
/* License for more details.                                                 */
/*                                                                           */
/* You should have received a copy of the GNU Lesser General Public License  */
/* along with this source; if not, write to the Free Software Foundation,    */
/* Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA        */
/*                                                                           */
/*===========================================================================*/
/*                      MMIO PERIPHERAL: SPI MASTER                          */
/*---------------------------------------------------------------------------*/
/* Test the SPI master peripheral                                            */
/*                                                                           */
/* Author(s):                                                                */
/*             - Jo Van Bulck,    jo.vanbulck@cs.kuleuven.be                 */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/* $Rev$                                                                */
/* $LastChangedBy$                                          */
/* $LastChangedDate$          */
/*===========================================================================*/

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      if (spi_ss !==3'b111) tb_error("SPI master SS initialization");

      @(r15==16'hbeef);
      if (spi_ss !==3'b111) tb_error("SPI master SS write 0x00");
      @(r15==16'h0000);

      @(r15==16'hbeef);
      if (spi_ss !==3'b110) tb_error("SPI master SS write 0x04");
      @(r15==16'h0000);

      @(r15==16'hbeef);
      if (spi_ss !==3'b101) tb_error("SPI master SS write 0x08");
      @(r15==16'h0000);

      @(r15==16'hbeef);
      if (spi_ss !==3'b011) tb_error("SPI master SS write 0x0c");

      @(r15==16'hdead);
      stimulus_done = 1;
   end

