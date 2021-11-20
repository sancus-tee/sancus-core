# Security analysis of Sancus_V

[![CI](https://github.com/martonbognar/sancus-core-gap/actions/workflows/ci.yaml/badge.svg)](https://github.com/martonbognar/sancus-core-gap/actions/workflows/ci.yaml)

This repository contains part of the source code accompanying our paper
"Showcasing the gap between formal guarantees and real-world security in
embedded architectures" to appear at the IEEE Symposium on Security and Privacy 2022.
More information on the paper and links to other investigated systems can be
found in the top-level [gap-attacks](https://github.com/martonbognar/gap-attacks) repository.

**:heavy_check_mark: Continuous integration.** 
A full reproducible build and reference output for all of the Sancus_V attack
experiments, executed via a cycle-accurate `iverilog` simulation of the
openMSP430 core, can be viewed in the [GitHub Actions log](https://github.com/martonbognar/sancus-core-gap/actions).

## Source code organization

This repository is a fork of the upstream
[sancus-core/tree/nemesis](https://github.com/sancus-tee/sancus-core/tree/nemesis)
repository that contains the source code of a provably secure interruptible
enclave processor, described in the following paper.

> M. Busi, J. Noorman, J. Van Bulck, L. Galletta, P. Degano, J. T. Mühlberg and F. Piessens, "Provably secure isolation for interruptible
enclaved execution on small microprocessors," in 33rd IEEE Computer Security Foundations Symposium (CSF), Jun. 2020, pp. 262–276.

The original upstream Sancus_V system is accessible via commit
[7c7d7fa](https://github.com/martonbognar/sancus-core-gap/commit/7c7d7fa9360439360d1eff0d26135c3d93a4b846)
and earlier. All subsequent commits implement our test framework and
proof-of-concept attacks.

All of our attacks are integrated into the existing openMSP430 testing framework.
Specifically, the `core/sim/rtl_sim/src/gap-attacks/` directory contains one
assembly file per attack (containing therein both the victim enclave and
untrusted runtime attacker code), plus a corresponding Verilog stimulus file
that validates the contextual equivalence breach.

## Installation

The general installation instructions of Sancus can be found [here](https://github.com/sancus-tee/sancus-main).
However, for our experiments we only need the Nemesis-resistant version of the Sancus core.
All attacks are directly written in assembly, so we don't need any custom Sancus compiler or support software.

What follows are instructions to get the experimental environment up and running on Ubuntu (tested on 20.04).

- Prerequisites:
  ```bash
  $ sudo apt install build-essential cmake iverilog tk binutils-msp430 gcc-msp430 msp430-libc msp430mcu expect-dev verilator
  ```
- Build Sancus core with Nemesis defense:
  ```bash
  $ git clone https://github.com/martonbognar/sancus-core-gap.git
  $ cd sancus-core-gap
  $ mkdir build
  $ cd build
  $ cmake -DNEMESIS_RESISTANT=1 ..
  $ cd ..
  ```

## Running the proof-of-concept attacks

**:bulb: Contextual equivalence.** 
As explained in the paper, the security definition of Sancus_V uses the notion
of _contextual equivalence_. This means that our proof-of-concept attacks will
have to distinguish two enclaves that can otherwise not be distinguished
without interrupts. For this, our test framework compiles every victim enclave
two times, once with an environment variable `__SECRET=0` and once with
`__SECRET=1`. We consider the proof-of-concept attack successful if the
attacker context (i.e., the untrusted code outside the enclave) unambiguously
succeeds in telling whether it interacted with an enclave compiled with
`__SECRET=1` or `__SECRET=0`.

To run all of the Sancus_V attacks, simply proceed as follows:

```bash
$ cd core/sim/rtl_sim/run/
$ __SECRET=0 ./run_all_attacks
$ __SECRET=1 ./run_all_attacks
```
