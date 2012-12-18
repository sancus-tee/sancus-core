TARGET = hash-test.elf

$(TARGET): main.c hash.s
	msp430-gcc -mmcu=msp430f1121 -T msp430.x $^ -o $@

clean:
	rm -f $(TARGET)
