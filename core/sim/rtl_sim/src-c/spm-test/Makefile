TARGET = spm-test.elf

$(TARGET):
	make -C build
	cp build/spm-test $(TARGET)

clean:
	make -C build clean
	rm -f $(TARGET)
