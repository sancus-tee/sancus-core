NAME            = spm-test
OBJECTS         = main.o
CFLAGS          = -Wall -g -mmcu=msp430f149
CC              = msp430-gcc


.PHONY: all clean

all: ${NAME}.elf

${NAME}.elf: ${OBJECTS}
	${CC} -T linker.x -o $@ ${OBJECTS}

clean:
	rm -f ${NAME}.elf ${OBJECTS}
