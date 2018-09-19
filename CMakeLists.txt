project(SancusCore NONE)

cmake_minimum_required(VERSION 2.8)

set(INSTALL_DATA_PATH "share/sancus")
set(FULL_INSTALL_DATA_PATH ${CMAKE_INSTALL_PREFIX}/${INSTALL_DATA_PATH})

set(INSTALL_RTL_PATH "${INSTALL_DATA_PATH}/rtl")
set(FULL_INSTALL_RTL_PATH ${CMAKE_INSTALL_PREFIX}/${INSTALL_RTL_PATH})

set(INSTALL_SIM_PATH "${INSTALL_RTL_PATH}/sim")
set(FULL_INSTALL_SIM_PATH ${CMAKE_INSTALL_PREFIX}/${INSTALL_SIM_PATH})

set(INSTALL_TOOLS_PATH "${INSTALL_DATA_PATH}/tools")
set(FULL_INSTALL_TOOLS_PATH ${CMAKE_INSTALL_PREFIX}/${INSTALL_TOOLS_PATH})

if (NOT NB_MODULES)
    set(NB_MODULES 4)
endif ()

if (NOT SECURITY)
    set(SECURITY 64)
endif ()

if (NOT MASTER_KEY)
    set(MASTER_KEY deadbeefcafebabe)
endif ()

option(RESET_ON_VIOLATION "Enable CPU reset on violation" OFF)

add_subdirectory(core)
add_subdirectory(tools)

set(CPACK_GENERATOR "DEB")

set(CPACK_PACKAGE_NAME "sancus-core")
set(CPACK_PACKAGE_VERSION "1.0")
set(CPACK_PACKAGE_CONTACT "Job Noorman <Job.Noorman@cs.kuleuven.be>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Sancus core")

set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "all")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "iverilog, python3, tk")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE
    "https://distrinet.cs.kuleuven.be/software/sancus/")

include(CPack)
