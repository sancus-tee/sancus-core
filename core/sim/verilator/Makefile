BASE_DIR = ../..
ifndef $(BUILD_DIR)
    BUILD_DIR = build
endif
TOPLEVEL_MODULE = tb_openMSP430
TOPLEVEL_DIR = bench/verilog
VERILOG_FILE_NAME = $(TOPLEVEL_MODULE).v
VERILOG_INPUT = $(BASE_DIR)/$(TOPLEVEL_DIR)/$(VERILOG_FILE_NAME)
VERILATOR_NAME = V$(TOPLEVEL_MODULE)
EXE_NAME = sancus-sim
EXE_FILE = $(BUILD_DIR)/$(EXE_NAME)
# OPTIMIZATION 
CFLAGS = -O3 -std=c++11 -DLOGURU_STACKTRACES=0
OPTIMIZATION = -O3 -CFLAGS "$(CFLAGS)"
DEPENDENCIES = $(shell pwd)/main.cpp $(shell pwd)/cpp-optparse/OptionParser.cpp $(shell pwd)/loguru/loguru.cpp

IN_ELF_FILE = program.elf

VERILATOR_INCLUDES = -I$(BASE_DIR)/rtl/verilog -I$(BASE_DIR)/rtl/verilog/crypto -I$(BASE_DIR)/bench/verilog -I$(BASE_DIR)/rtl/verilog/periph
VERILATOR_LIBRARIES = '-lpthread'

# hotfix timescale Verilator errors
UBUNTU_VERSION = $(shell lsb_release -rs)
ifeq ($(UBUNTU_VERSION), 22.04)
    VERILATOR_TIMESCALE = -Wno-TIMESCALEMOD
endif

all: $(EXE_FILE)

$(EXE_FILE): $(BUILD_DIR)/$(VERILATOR_NAME).mk $(DEPENDENCIES)
	make -C $(BUILD_DIR) -f $(VERILATOR_NAME).mk $(EXE_NAME)

$(BUILD_DIR)/$(VERILATOR_NAME).mk: FORCE
	verilator --cc --exe --trace $(OPTIMIZATION) -Wno-fatal $(VERILATOR_TIMESCALE) -Mdir $(BUILD_DIR) $(VERILOG_INPUT) -LDFLAGS $(VERILATOR_LIBRARIES) $(VERILATOR_INCLUDES) $(DEPENDENCIES) -o $(EXE_NAME)

FORCE:

clean:
	rm -rf $(BUILD_DIR)
