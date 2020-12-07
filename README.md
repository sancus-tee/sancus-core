# Installation

The general installation instructions of Sancus can be found [here][sancus install].
What follows are instructions to get everything up and running on Ubuntu (tested on 20.04).

- Prerequisites:
  ```bash
  apt install cmake iverilog tk python3-pip libtinfo5
  pip3 install pyelftools
  ```
- Patched Clang (needed for the Sancus compiler):
  ```bash
  wget https://distrinet.cs.kuleuven.be/software/sancus/downloads/clang-sancus_4.0.1-2_amd64.deb
  apt install ./clang-sancus_4.0.1-2_amd64.deb
  ```
- Sancus compiler:
  ```bash
  wget https://distrinet.cs.kuleuven.be/software/sancus/downloads/sancus-compiler_2.0_amd64.deb
  apt install ./sancus-compiler_2.0_amd64.deb
  ```
- Sancus core with Nemesis defense:
  ```bash
  git clone --branch nemesis https://github.com/sancus-tee/sancus-core.git
  mkdir build
  cd build
  cmake ..
  make install
  ```

# Running

We have provided an [example](nemesis-example) to start experimenting with the Nemesis defense.
It provides a Makefile so running it is easy:
```bash
cd nemesis-example
make sim
```

This produces a waveform in `sancus_sim.fst` which can be viewed with [GTKWave][gtkwave].

The example uses the `timer_irq` function to precisely generate an interrupt while a Sancus module is executing.
With the current value of 100, the interrupt is triggered during the third cycle of a 4-cycle instruction.
Adapt the value to generate interrupts at different points during the execution of the module.

[sancus install]: https://distrinet.cs.kuleuven.be/software/sancus/install.php
[gtkwave]: http://gtkwave.sourceforge.net/
