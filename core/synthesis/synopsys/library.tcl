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
        set LIB_WC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/umc_130nm/fsa0l_a_sc_wc.db"
        set LIB_WC_NAME   "$LIB_WC_FILE:fsa0l_a_sc_wc"

        # Define best case library
        set LIB_BC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/umc_130nm/fsa0l_a_sc_bc.db"
        set LIB_BC_NAME   "$LIB_BC_FILE:fsa0l_a_sc_bc"

        # Define operating conditions
        set LIB_WC_OPCON  "WCCOM"
        set LIB_BC_OPCON  "BCCOM"

        # Define wire-load model
        set LIB_WIRE_LOAD "G0K"

        # Define nand2 gate name for aera size calculation
        set NAND2_NAME    "ND2"
    }
    "umc_180nm" {
        # Define worst case library
        set LIB_WC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/umc_180nm/fsa0l_a_sc_wc.db"
        set LIB_WC_NAME   "$LIB_WC_FILE:fsa0l_a_sc_wc"

        # Define best case library
        set LIB_BC_FILE   "${TECHNOLOGY_LIBRARIES_DIR}/umc_180nm/fsa0l_a_sc_bc.db"
        set LIB_BC_NAME   "$LIB_BC_FILE:fsa0l_a_sc_bc"

        # Define operating conditions
        set LIB_WC_OPCON  "WCCOM"
        set LIB_BC_OPCON  "BCCOM"

        # Define wire-load model
        set LIB_WIRE_LOAD "G0K"

        # Define nand2 gate name for aera size calculation
        set NAND2_NAME    "ND2"
    }
}

# Set library
set target_library $LIB_WC_FILE
set link_library   $LIB_WC_FILE
set_min_library    $LIB_WC_FILE  -min_version $LIB_BC_FILE
