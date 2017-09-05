set(RESET_CONFIG "`define RESET_ON_VIOLATION")

if (NOT RESET_ON_VIOLATION)
    set(RESET_CONFIG "// ${RESET_CONFIG}")
endif ()

configure_file(config.v.in ${CMAKE_CURRENT_SOURCE_DIR}/config.v)

set(SRC
    config.v
    omsp_alu.v
    omsp_and_gate.v
    omsp_clock_gate.v
    omsp_clock_module.v
    omsp_clock_mux.v
    omsp_dbg_hwbrk.v
    omsp_dbg_uart.v
    omsp_dbg.v
    omsp_execution_unit.v
    omsp_frontend.v
    omsp_mem_backbone.v
    omsp_multiplier.v
    omsp_register_file.v
    omsp_scan_mux.v
    omsp_sfr.v
    omsp_spm_control.v
    omsp_spm.v
    omsp_sync_cell.v
    omsp_sync_reset.v
    omsp_wakeup_cell.v
    omsp_watchdog.v
    openMSP430_defines.v
    openMSP430_undefines.v
    openMSP430.v
    crypto/crypto_control.v
    crypto/sponge_wrap.v
    crypto/spongent_datapath.v
    crypto/spongent_fsm.v
    crypto/spongent_player.v
    crypto/spongent_sbox.v
    crypto/spongent.v
    crypto/lfsr.v
    periph/omsp_gpio.v
    periph/omsp_timerA_defines.v
    periph/omsp_timerA_undefines.v
    periph/omsp_timerA.v
    periph/template_periph_16b.v
    periph/template_periph_8b.v
    periph/omsp_tsc.v
    periph/omsp_spi_master.v
    periph/spi_master.v
    periph/omsp_led_digits.v
)

install(FILES ${SRC} DESTINATION ${INSTALL_RTL_PATH})
