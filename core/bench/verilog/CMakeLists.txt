set(SRC
    tb_openMSP430.v
    timescale.v
    registers.v
    ram.v
    omsp_uart_print.v
    msp_debug.v
    file_io.v
    dbg_uart_tasks.v
    dma_tasks.v #(Sergio)
    sancus-def.v
    irq_macros.v
)
 install(FILES ${SRC} DESTINATION ${INSTALL_SIM_PATH})
