configure_file(run_sim.py sancus-sim)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/sancus-sim DESTINATION bin)

configure_file(commands.f commands.f)

set(SRC
    ${CMAKE_CURRENT_BINARY_DIR}/commands.f
)

install(FILES ${SRC} DESTINATION ${INSTALL_SIM_PATH})
