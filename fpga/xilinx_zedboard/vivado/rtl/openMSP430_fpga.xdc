# ----------------------------------------------------------------------------
#     _____
#    /     \
#   /____   \____
#  / \===\   \==/
# /___\===\___\/  AVNET Design Resource Center
#      \======/         www.em.avnet.com/drc
#       \====/    
# ----------------------------------------------------------------------------
# 
#  Created With Avnet UCF Generator V0.4.0 
#     Date: Saturday, June 30, 2012 
#     Time: 12:18:55 AM 
# 
#  This design is the property of Avnet.  Publication of this
#  design is not authorized without written consent from Avnet.
#  
#  Please direct any questions to:
#     ZedBoard.org Community Forums
#     http://www.zedboard.org
# 
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2012 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------

# TODO: Break reported combinational loops
set_property SEVERITY {Warning} [get_drc_checks LUTLP-1]

# ----------------------------------------------------------------------------
# Clock Source - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN Y9 [get_ports {GCLK}];

# ----------------------------------------------------------------------------
# JA Pmod - Bank 13 
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN AA11 [get_ports {UART_TXD}];
set_property PACKAGE_PIN Y10  [get_ports {UART_RXD}];

# ----------------------------------------------------------------------------
# JC Pmod - Bank 13
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN R6 [get_ports {UART_TXD}];
#set_property PACKAGE_PIN U4 [get_ports {UART_RXD}];

# ----------------------------------------------------------------------------
# User LEDs - Bank 33
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN T22 [get_ports {LED0}];
set_property PACKAGE_PIN T21 [get_ports {LED1}];
set_property PACKAGE_PIN U22 [get_ports {LED2}];
set_property PACKAGE_PIN U21 [get_ports {LED3}];
set_property PACKAGE_PIN V22 [get_ports {LED4}];
set_property PACKAGE_PIN W22 [get_ports {LED5}];
set_property PACKAGE_PIN U19 [get_ports {LED6}];
set_property PACKAGE_PIN U14 [get_ports {LED7}];

# ----------------------------------------------------------------------------
# User Push Buttons - Bank 34
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN R16 [get_ports {BTND}];

# ----------------------------------------------------------------------------
# User DIP Switches - Bank 35
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN F22 [get_ports {SW0}];
set_property PACKAGE_PIN G22 [get_ports {SW1}];
set_property PACKAGE_PIN H22 [get_ports {SW2}];
set_property PACKAGE_PIN F21 [get_ports {SW3}];
set_property PACKAGE_PIN H19 [get_ports {SW4}];
set_property PACKAGE_PIN H18 [get_ports {SW5}];
set_property PACKAGE_PIN H17 [get_ports {SW6}];
set_property PACKAGE_PIN M15 [get_ports {SW7}];

# ----------------------------------------------------------------------------
# IOSTANDARD Constraints
#
# Note that these IOSTANDARD constraints are applied to all IOs currently
# assigned within an I/O bank.  If these IOSTANDARD constraints are 
# evaluated prior to other PACKAGE_PIN constraints being applied, then 
# the IOSTANDARD specified will likely not be applied properly to those 
# pins.  Therefore, bank wide IOSTANDARD constraints should be placed 
# within the XDC file in a location that is evaluated AFTER all 
# PACKAGE_PIN constraints within the target bank have been evaluated.
#
# Un-comment one or more of the following IOSTANDARD constraints according to
# the bank pin assignments that are required within a design.
# ---------------------------------------------------------------------------- 

# Note that the bank voltage for IO Bank 33 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

# Set the bank voltage for IO Bank 34 to 1.8V by default.
# set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]];
# set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

# Set the bank voltage for IO Bank 35 to 1.8V by default.
# set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 35]];
# set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 35]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
