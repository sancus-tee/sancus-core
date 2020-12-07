CC = sancus-cc
LD = sancus-ld
SIM = sancus-sim

main.elf: main.o timer.o
	$(LD) --standalone -o $@ $^

sim: main.elf
	$(SIM) $<
