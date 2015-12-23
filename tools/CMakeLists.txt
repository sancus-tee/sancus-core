set(BIN_FILES
    bin/openmsp430-gdbproxy.tcl
    bin/openmsp430-loader.tcl
    bin/openmsp430-minidebug.tcl
)

set(LIB_FILES
    lib/tcl-lib/combobox.tcl
    lib/tcl-lib/dbg_functions.tcl
    lib/tcl-lib/dbg_uart.tcl
    lib/tcl-lib/xml.tcl
)

set(GDB_FILES
    openmsp430-gdbproxy/commands.tcl
    openmsp430-gdbproxy/server.tcl
)

set(XML_FILES
    omsp_alias.xml
)

install(PROGRAMS ${BIN_FILES} DESTINATION ${INSTALL_TOOLS_PATH}/bin)
install(FILES    ${LIB_FILES} DESTINATION ${INSTALL_TOOLS_PATH}/lib/tcl-lib)
install(FILES    ${GDB_FILES} DESTINATION ${INSTALL_TOOLS_PATH}/openmsp430-gdbproxy)
install(FILES    ${XML_FILES} DESTINATION ${INSTALL_TOOLS_PATH})

configure_file(sancus-gdbproxy.in sancus-gdbproxy)
configure_file(sancus-loader.in sancus-loader)
configure_file(sancus-minidebug.in sancus-minidebug)

set(WRAP_FILES
    ${CMAKE_CURRENT_BINARY_DIR}/sancus-gdbproxy
    ${CMAKE_CURRENT_BINARY_DIR}/sancus-loader
    ${CMAKE_CURRENT_BINARY_DIR}/sancus-minidebug
)

install(PROGRAMS ${WRAP_FILES} DESTINATION bin)
