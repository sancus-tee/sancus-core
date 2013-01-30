TARGET = spm-test.elf
CC = spm-compiler
LD = spm-linker
ASFLAGS = --verbose
CFLAGS = --verbose
LDFLAGS = --rom-size 16K --ram-size 16K --verbose

OBJECTS = main.o unprotected.o spm0.o spm1.o

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

download: $(TARGET)
	../../../../tools/bin/openmsp430-loader.tcl -device /dev/ttyUSB0 -baudrate 115200 ${TARGET}

debug:
	msp430-gdb -x debug.gdb

clean:
	rm -f $(TARGET) $(OBJECTS)
