if (TECHNOLOGY_LIBRARIES_DIR)
    if (NOT CLOCK_PERIOD)
        set(CLOCK_PERIOD 40.0)
    endif ()

    configure_file(run_syn sancus-syn)
    install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/sancus-syn DESTINATION bin)

    configure_file(constraints.tcl constraints.tcl)
    configure_file(library.tcl library.tcl)
    configure_file(read.tcl read.tcl)

    set(SRC
        ${CMAKE_CURRENT_BINARY_DIR}/constraints.tcl
        ${CMAKE_CURRENT_BINARY_DIR}/library.tcl
        ${CMAKE_CURRENT_BINARY_DIR}/read.tcl
        synthesis.tcl
    )

    install(FILES ${SRC} DESTINATION ${INSTALL_SYN_PATH})
endif ()
