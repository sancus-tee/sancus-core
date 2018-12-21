
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# openMSP430_fpga

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg484-1
   set_property BOARD_PART em.avnet.com:zed:part0:1.4 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
openMSP430_fpga\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set BTND [ create_bd_port -dir I BTND ]
  set GCLK [ create_bd_port -dir I -type clk GCLK ]
  set_property -dict [ list \
   CONFIG.CLK_DOMAIN {design_1_sys_clock} \
   CONFIG.FREQ_HZ {100000000} \
 ] $GCLK
  set LED0 [ create_bd_port -dir O LED0 ]
  set LED1 [ create_bd_port -dir O LED1 ]
  set LED2 [ create_bd_port -dir O LED2 ]
  set LED3 [ create_bd_port -dir O LED3 ]
  set LED4 [ create_bd_port -dir O LED4 ]
  set LED5 [ create_bd_port -dir O LED5 ]
  set LED6 [ create_bd_port -dir O LED6 ]
  set LED7 [ create_bd_port -dir O LED7 ]
  set SW0 [ create_bd_port -dir I SW0 ]
  set SW1 [ create_bd_port -dir I SW1 ]
  set SW2 [ create_bd_port -dir I SW2 ]
  set SW3 [ create_bd_port -dir I SW3 ]
  set SW4 [ create_bd_port -dir I SW4 ]
  set SW5 [ create_bd_port -dir I SW5 ]
  set SW6 [ create_bd_port -dir I SW6 ]
  set SW7 [ create_bd_port -dir I SW7 ]
  set UART_RXD [ create_bd_port -dir I UART_RXD ]
  set UART_TXD [ create_bd_port -dir O UART_TXD ]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_JITTER {193.154} \
   CONFIG.CLKOUT1_PHASE_ERROR {109.126} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {20.000} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {8.500} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {42.500} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_0

  # Create instance: dmem_gen_0, and set properties
  set dmem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 dmem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {false} \
   CONFIG.Read_Width_A {16} \
   CONFIG.Read_Width_B {16} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {false} \
   CONFIG.Write_Depth_A {8192} \
   CONFIG.Write_Width_A {16} \
   CONFIG.Write_Width_B {16} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $dmem_gen_0

  # Create instance: openMSP430_fpga_0, and set properties
  set block_name openMSP430_fpga
  set block_cell_name openMSP430_fpga_0
  if { [catch {set openMSP430_fpga_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $openMSP430_fpga_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: pmem_gen_0, and set properties
  set pmem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 pmem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {false} \
   CONFIG.Read_Width_A {16} \
   CONFIG.Read_Width_B {16} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {false} \
   CONFIG.Write_Depth_A {20992} \
   CONFIG.Write_Width_A {16} \
   CONFIG.Write_Width_B {16} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $pmem_gen_0

  # Create port connections
  connect_bd_net -net BTND_1 [get_bd_ports BTND] [get_bd_pins openMSP430_fpga_0/BTND]
  connect_bd_net -net GCLK_1 [get_bd_ports GCLK] [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net SW0_1 [get_bd_ports SW0] [get_bd_pins openMSP430_fpga_0/SW0]
  connect_bd_net -net SW1_1 [get_bd_ports SW1] [get_bd_pins openMSP430_fpga_0/SW1]
  connect_bd_net -net SW2_1 [get_bd_ports SW2] [get_bd_pins openMSP430_fpga_0/SW2]
  connect_bd_net -net SW3_1 [get_bd_ports SW3] [get_bd_pins openMSP430_fpga_0/SW3]
  connect_bd_net -net SW4_1 [get_bd_ports SW4] [get_bd_pins openMSP430_fpga_0/SW4]
  connect_bd_net -net SW5_1 [get_bd_ports SW5] [get_bd_pins openMSP430_fpga_0/SW5]
  connect_bd_net -net SW6_1 [get_bd_ports SW6] [get_bd_pins openMSP430_fpga_0/SW6]
  connect_bd_net -net SW7_1 [get_bd_ports SW7] [get_bd_pins openMSP430_fpga_0/SW7]
  connect_bd_net -net UART_RXD_1 [get_bd_ports UART_RXD] [get_bd_pins openMSP430_fpga_0/UART_RXD]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins openMSP430_fpga_0/clk_sys]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins openMSP430_fpga_0/clk_locked]
  connect_bd_net -net dmem_gen_0_douta [get_bd_pins dmem_gen_0/douta] [get_bd_pins openMSP430_fpga_0/dmem_dout]
  connect_bd_net -net openMSP430_fpga_0_LED0 [get_bd_ports LED0] [get_bd_pins openMSP430_fpga_0/LED0]
  connect_bd_net -net openMSP430_fpga_0_LED1 [get_bd_ports LED1] [get_bd_pins openMSP430_fpga_0/LED1]
  connect_bd_net -net openMSP430_fpga_0_LED2 [get_bd_ports LED2] [get_bd_pins openMSP430_fpga_0/LED2]
  connect_bd_net -net openMSP430_fpga_0_LED3 [get_bd_ports LED3] [get_bd_pins openMSP430_fpga_0/LED3]
  connect_bd_net -net openMSP430_fpga_0_LED4 [get_bd_ports LED4] [get_bd_pins openMSP430_fpga_0/LED4]
  connect_bd_net -net openMSP430_fpga_0_LED5 [get_bd_ports LED5] [get_bd_pins openMSP430_fpga_0/LED5]
  connect_bd_net -net openMSP430_fpga_0_LED6 [get_bd_ports LED6] [get_bd_pins openMSP430_fpga_0/LED6]
  connect_bd_net -net openMSP430_fpga_0_LED7 [get_bd_ports LED7] [get_bd_pins openMSP430_fpga_0/LED7]
  connect_bd_net -net openMSP430_fpga_0_UART_TXD [get_bd_ports UART_TXD] [get_bd_pins openMSP430_fpga_0/UART_TXD]
  connect_bd_net -net openMSP430_fpga_0_dmem_addr [get_bd_pins dmem_gen_0/addra] [get_bd_pins openMSP430_fpga_0/dmem_addr]
  connect_bd_net -net openMSP430_fpga_0_dmem_cen_n [get_bd_pins dmem_gen_0/ena] [get_bd_pins openMSP430_fpga_0/dmem_cen_n]
  connect_bd_net -net openMSP430_fpga_0_dmem_din [get_bd_pins dmem_gen_0/dina] [get_bd_pins openMSP430_fpga_0/dmem_din]
  connect_bd_net -net openMSP430_fpga_0_dmem_wen_n [get_bd_pins dmem_gen_0/wea] [get_bd_pins openMSP430_fpga_0/dmem_wen_n]
  connect_bd_net -net openMSP430_fpga_0_mclk [get_bd_pins dmem_gen_0/clka] [get_bd_pins openMSP430_fpga_0/mclk] [get_bd_pins pmem_gen_0/clka]
  connect_bd_net -net openMSP430_fpga_0_pmem_addr [get_bd_pins openMSP430_fpga_0/pmem_addr] [get_bd_pins pmem_gen_0/addra]
  connect_bd_net -net openMSP430_fpga_0_pmem_cen_n [get_bd_pins openMSP430_fpga_0/pmem_cen_n] [get_bd_pins pmem_gen_0/ena]
  connect_bd_net -net openMSP430_fpga_0_pmem_din [get_bd_pins openMSP430_fpga_0/pmem_din] [get_bd_pins pmem_gen_0/dina]
  connect_bd_net -net openMSP430_fpga_0_pmem_wen_n [get_bd_pins openMSP430_fpga_0/pmem_wen_n] [get_bd_pins pmem_gen_0/wea]
  connect_bd_net -net pmem_gen_0_douta [get_bd_pins openMSP430_fpga_0/pmem_dout] [get_bd_pins pmem_gen_0/douta]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


