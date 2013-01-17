TARGET = hmac-test.elf

$(TARGET): main.c hmac.s
	msp430-gcc -mmcu=msp430f1121 -T msp430.x $^ -o $@

clean:
	rm -f $(TARGET)
