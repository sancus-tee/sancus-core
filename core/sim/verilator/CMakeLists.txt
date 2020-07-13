add_custom_target(sancus-sim
                   ALL
                   COMMAND make BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/sancus-sim DESTINATION bin)
