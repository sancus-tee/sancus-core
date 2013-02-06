TARGET_NO_HMAC = hmac-test-no-hmac.elf
TARGET = hmac-test.elf
OBJECTS = main.o putchar.o

CC = spm-compiler
AS = spm-compiler
LD = spm-linker
ASFLAGS = --verbose -c
CFLAGS = --verbose
LDFLAGS = --debug --rom-size 48K --ram-size 10K
KEY = d52f34e3f298b79bf377d770f4f5808e

all: $(TARGET)

$(TARGET_NO_HMAC): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

$(TARGET): $(TARGET_NO_HMAC)
	spm-hmac --verbose --key $(KEY) -o $@ $^

clean:
	rm -f $(TARGET_NO_HMAC) $(TARGET) $(OBJECTS)

download: all
	../../../../tools/bin/openmsp430-loader.tcl -device /dev/ttyUSB0 -baudrate 115200 ${TARGET}
