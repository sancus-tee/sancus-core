BASE_DIR = ../..
BUILD_DIR = build
TOPLEVEL_MODULE = tb_openMSP430
TOPLEVEL_DIR = bench/verilog
VERILOG_FILE_NAME = $(TOPLEVEL_MODULE).v
VERILOG_INPUT = $(BASE_DIR)/$(TOPLEVEL_DIR)/$(VERILOG_FILE_NAME)
VERILATOR_NAME = V$(TOPLEVEL_MODULE)
EXE_NAME = sim
EXE_FILE = $(BUILD_DIR)/$(EXE_NAME)
# OPTIMIZATION 
CFLAGS = -O3 -std=c++11
OPTIMIZATION = -O3 -CFLAGS "$(CFLAGS)"
DEPENDENCIES = main.cpp OptionParser.cpp

IN_ELF_FILE = program.elf

VERILATOR_INCLUDES = -I$(BASE_DIR)/rtl/verilog -I$(BASE_DIR)/rtl/verilog/crypto -I$(BASE_DIR)/bench/verilog -I$(BASE_DIR)/rtl/verilog/periph

all: $(EXE_FILE)

$(EXE_FILE): $(BUILD_DIR)/$(VERILATOR_NAME).mk $(DEPENDENCIES)
	make -C $(BUILD_DIR) -f $(VERILATOR_NAME).mk $(EXE_NAME)

$(BUILD_DIR)/$(VERILATOR_NAME).mk: FORCE
	verilator --cc --exe --trace $(OPTIMIZATION) -Wno-fatal -Mdir $(BUILD_DIR) $(VERILOG_INPUT) $(VERILATOR_INCLUDES) $(DEPENDENCIES) -o $(EXE_NAME)

mem-file: 
	@echo "Building memory file.."
	msp430-objcopy -O binary $(IN_ELF_FILE) $(BUILD_DIR)/mem_file
	# /usr/local/share/sancus/tools/ihex2mem.tcl -ihex $(BUILD_DIR)/ihex -out $(BUILD_DIR)/pmem.mem -mem_size 41984

sim: all mem-file
	cd $(BUILD_DIR); ./$(EXE_NAME) -f $(BUILD_DIR)/mem_file -c 1000

FORCE:

clean:
	rm -rf $(BUILD_DIR)