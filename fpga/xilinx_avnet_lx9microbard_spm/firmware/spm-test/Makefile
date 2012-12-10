NAME            = spm-test
OBJECTS         = main.o entry.o exit.o spm.o spm_stubs.o unprotected.o unprotected_stubs.o
CFLAGS          = -Wall -mmcu=msp430f1121
CC              = msp430-gcc
CPPFLAGS        = -DSPM_ID=foo
CPP             = msp430-cpp

CC = /home/job/sources/llvm/build-shared/bin/clang
CFLAGS = -target msp430-elf -Wall -g -mllvm -msp430-hwmult-mode=no -I/usr/local/msp430/include/ -D__MSP430F1121__
ASFLAGS         = -mmcu=msp430f1121 -x assembler-with-cpp -D_GNU_ASSEMBLER_ -c
ASM_FILES = main.s spm.s unprotected.s

${NAME}.elf: ${ASM_FILES} ${ASM_STUBS} putchar.S linker.xpp
	msp430-gcc -g -mmcu=msp430f1121 ${CPPFLAGS} ${ASM_FILES} putchar.S -T linker.xpp -o $@

spm.s: spm.c
	${CC} ${CFLAGS} ${CPPFLAGS} -c -emit-llvm $< -o spm.bc
	opt -load ~/phd/spm/compiler/build/src/llvm/SpmCreator.so -create-spm -spm-id=foo -spm-stack-size=128 spm.bc -o spm2.bc
	llc -O0 spm2.bc -o $@

%.s: %.c
	${CC} ${CFLAGS} ${CPPFLAGS} -S $< -o $@

# default: llvm

.PHONY: all clean

all: ${NAME}.elf

# ${NAME}.elf: ${OBJECTS} linker.xpp
# 	${CC} -T linker.xpp -o $@ ${OBJECTS}

linker.x: spm.x

linker.xpp: linker.x
	${CPP} ${CPPFLAGS} -P -x assembler-with-cpp $< $@

clean:
	rm -f ${ASM_FILES} ${NAME}.elf linker.xpp
	#rm -f ${NAME}.elf ${OBJECTS} linker.xpp

llvm:
	clang -target msp430-elf -I/usr/local/msp430/include/ -D__MSP430F149__ -S main.c -o main.s
	${CC} -T linker.x -o ${NAME}.elf main.s entry.S

download: all
	../../../../tools/bin/openmsp430-loader.tcl -device /dev/ttyUSB0 -baudrate 115200 ${NAME}.elf

debug:
	msp430-gdb -x debug.gdb
