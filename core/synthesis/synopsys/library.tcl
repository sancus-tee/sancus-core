##############################################################################
#                                                                            #
#                            SPECIFY LIBRARIES                               #
#                                                                            #
##############################################################################

switch $WITH_LIBRARY {
    "nangate_15nm" {
        # Define worst case library
        set LIB_WC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/nangate_15nm/front_end/timing_power_noise/CCS/NanGate_15nm_OCL_slow_conditional_ccs.db"
        set LIB_WC_NAME   "$LIB_WC_FILE:NanGate_15nm_OCL"

        # Define best case library
        set LIB_BC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/nangate_15nm/front_end/timing_power_noise/CCS/NanGate_15nm_OCL_fast_conditional_ccs.db"
        set LIB_BC_NAME   "$LIB_BC_FILE:NanGate_15nm_OCL"

        # Define operating conditions
        set LIB_WC_OPCON  "slow"
        set LIB_BC_OPCON  "fast"

        # Define wire-load model
        set LIB_WIRE_LOAD ""

        # Define nand2 gate name for aera size calculation
        set NAND2_NAME    "NAND2_X1"
    }
    "umc_130nm" {
        # Define worst case library
        set LIB_WC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/umc_130nm/fsc0l_d_sc_wc.db"
        set LIB_WC_NAME   "$LIB_WC_FILE:fsc0l_d_sc_wc"

        # Define best case library
        set LIB_BC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/umc_130nm/fsc0l_d_sc_bc.db"
        set LIB_BC_NAME   "$LIB_BC_FILE:fsc0l_d_sc_bc"

        # Define operating conditions
        set LIB_WC_OPCON  "WCCOM"
        set LIB_BC_OPCON  "BCCOM"

        # Define wire-load model
        set LIB_WIRE_LOAD "G5K"

        # Define nand2 gate name for aera size calculation
        set NAND2_NAME    "ND2CLD"
    }
}

# Set library
set target_library $LIB_WC_FILE
set link_library   $LIB_WC_FILE
set_min_library    $LIB_WC_FILE  -min_version $LIB_BC_FILE
