# Set the reference directory for source file relative paths
set origin_dir [file dirname [info script]]

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "openmsp430"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "build.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Create project
create_project ${_xil_proj_name_} [file normalize "${origin_dir}/${_xil_proj_name_}"] -part xc7z020clg484-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects ${_xil_proj_name_}]
set_property -name "board_part" -value "em.avnet.com:zed:part0:1.4" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/config.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/openMSP430_defines.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/crypto_control.v"] \
 [file normalize "${origin_dir}/rtl/io_mux.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/lfsr.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/openMSP430_undefines.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_alu.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_clock_module.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_dbg.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_dbg_uart.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_execution_unit.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_frontend.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_gpio.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_mem_backbone.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_multiplier.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_register_file.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_sfr.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_spm.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_spm_control.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_sync_cell.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_sync_reset.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_timerA_undefines.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_timerA_defines.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_timerA.v"] \
 [file normalize "${origin_dir}/rtl/omsp_uart.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_watchdog.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/openMSP430.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/sponge_wrap.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/spongent.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/spongent_datapath.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/spongent_fsm.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/spongent_player.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/crypto/spongent_sbox.v"] \
 [file normalize "${origin_dir}/rtl/openMSP430_fpga.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_and_gate.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_clock_gate.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_clock_mux.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_dbg_hwbrk.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_led_digits.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_scan_mux.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_spi_master.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/omsp_tsc.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/omsp_wakeup_cell.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/spi_master.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/template_periph_16b.v"] \
 [file normalize "${origin_dir}/../../../core/rtl/verilog/periph/template_periph_8b.v"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "include_dirs" -value "[file normalize "${origin_dir}/../../../core/rtl/verilog"]" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "${origin_dir}/rtl/openMSP430_fpga.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "${origin_dir}/rtl/openMSP430_fpga.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xc7z020clg484-1 -flow {Vivado Synthesis 2018} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2018" [get_runs synth_1]
}

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part xc7z020clg484-1 -flow {Vivado Implementation 2018} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2018" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:${_xil_proj_name_}"

# Create block design
source [file normalize "${origin_dir}/bd/design_1.tcl"]

# Generate the wrapper
set design_name [get_bd_designs]
make_wrapper -files [get_files $design_name.bd] -top -import

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

puts "INFO: Block design created:design_1"
