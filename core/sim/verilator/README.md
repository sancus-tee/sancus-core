# Sancus fastsim

This is a Sancus Simulator implementation based on Verilator. Features include:

- C++ driven clock
- Program and data memory implemented in C++
- Faster than the old Icarus Simulator

## Installation
Run `cmake` once on the top directory of sancus-core (to generate some input.v
variables). Then run `make` in this directory. You can simulate elf
files with `./build/sancus-fastsim path-to-elf-file`. Fastsim can be used as
drop-in replacement for sancus-sim, but some options are not possible with
verilator and are as such removed (--ram, --rom).

## Limitations / TODOs

- Some bug remains revolving enclaves...
- Verilator does not support [$fflush without arguments](https://github.com/verilator/verilator/issues/1638) which would be useful for crypto-controls.v to update key generation.
- Verilator generated Warnings Warning-UNOPTFLAT can have a major impact on the performance. These should be fixed to make simulation even faster.
- No I/O support yet besides stdout.
