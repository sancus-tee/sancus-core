TARGET = hash-test.elf

$(TARGET): main.c
	msp430-gcc -mmcu=msp430f1121 $< -o $@

clean:
	rm -f $(TARGET)
