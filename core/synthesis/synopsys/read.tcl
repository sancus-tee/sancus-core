##############################################################################
#                                                                            #
#                               READ DESING RTL                              #
#                                                                            #
##############################################################################

set DESIGN_NAME      "openMSP430"
set RTL_SOURCE_FILES {${FULL_INSTALL_RTL_PATH}/openMSP430_defines.v
                      ${FULL_INSTALL_RTL_PATH}/openMSP430.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_frontend.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_execution_unit.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_register_file.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_alu.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_sfr.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_clock_module.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_mem_backbone.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_watchdog.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_dbg.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_dbg_uart.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_dbg_hwbrk.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_multiplier.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_sync_reset.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_sync_cell.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_scan_mux.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_and_gate.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_wakeup_cell.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_clock_gate.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_clock_mux.v

                      ${FULL_INSTALL_RTL_PATH}/omsp_spm.v
                      ${FULL_INSTALL_RTL_PATH}/omsp_spm_control.v

                      ${FULL_INSTALL_RTL_PATH}/crypto_control.v
                      ${FULL_INSTALL_RTL_PATH}/sponge_wrap.v
                      ${FULL_INSTALL_RTL_PATH}/spongent.v
                      ${FULL_INSTALL_RTL_PATH}/spongent_fsm.v
                      ${FULL_INSTALL_RTL_PATH}/spongent_datapath.v
                      ${FULL_INSTALL_RTL_PATH}/spongent_player.v
                      ${FULL_INSTALL_RTL_PATH}/spongent_sbox.v
                      ${FULL_INSTALL_RTL_PATH}/lfsr.v
}

set_svf ./results/$DESIGN_NAME.svf
define_design_lib WORK -path ./WORK
analyze -format verilog $RTL_SOURCE_FILES

elaborate $DESIGN_NAME
link


# Check design structure after reading verilog
current_design $DESIGN_NAME
redirect ./results/report.check {check_design}
