# Security analysis of Sancus_V

[![CI](https://github.com/martonbognar/sancus-core-gap/actions/workflows/ci.yaml/badge.svg)](https://github.com/martonbognar/sancus-core-gap/actions/workflows/ci.yaml)

This repository contains part of the source code accompanying our paper "Mind
the Gap: Studying the Insecurity of Provably Secure Embedded Trusted Execution
Architectures" to appear at the IEEE Symposium on Security and Privacy 2022.
More information on the paper and links to other investigated systems can be
found in the top-level [gap-attacks](https://github.com/martonbognar/gap-attacks) repository.

> M. Bognar, J. Van Bulck, and F. Piessens, "Mind the Gap: Studying the Insecurity of Provably Secure Embedded Trusted Execution Architectures," in 2022 IEEE Symposium on Security and Privacy (S&P).

**:heavy_check_mark: Continuous integration.** 
A full reproducible build and reference output for all of the Sancus_V attack
experiments, executed via a cycle-accurate `iverilog` simulation of the
openMSP430 core, can be viewed in the [GitHub Actions log](https://github.com/martonbognar/sancus-core-gap/actions).

**:no_entry_sign: Mitigations.**
Where applicable, we provide simple patches for the identified implementation
flaws in a separate [mitigations](https://github.com/martonbognar/sancus-core-gap/tree/mitigations)
branch, referenced in the table below.
Note, however, that these patches merely fix the identified vulnerabilities in
the Sancus_V reference implementation in an _ad-hoc_ manner.
Specifically, our patches do not address the root cause for these oversights
(i.e., in terms of preventing implementation-model mismatch, missing attacker
capabilities) and cannot in any other way guarantee the absence of further
vulnerabilities.
We provide more discussion on mitigations and guidelines in the paper.

## Overview

### Implementation/model mismatches

| Paper reference | Proof-of-concept attack | Patch? | Description |
|-----------------|---------------|:-------------:|-------------|
| V-B1            | [B-1-dependent-length.s43](core/sim/rtl_sim/src/gap-attacks/B-1-dependent-length.s43) | [`e8cf011`](https://github.com/martonbognar/sancus-core-gap/commit/e8cf0114c9b3d2b823cd5a5f38e06da5049225ce) | Variable instruction length following `reti`. |
| V-B2            | [B-2-maxlen.s43](core/sim/rtl_sim/src/gap-attacks/B-2-maxlen.s43) | [`3170d5d`](https://github.com/martonbognar/sancus-core-gap/commit/3170d5d6a4431db93bac4f11a7f91559f7c07620) | Instructions with execution time T > 6. |
| V-B3            | [B-3-shadow-register.s43](core/sim/rtl_sim/src/gap-attacks/B-3-shadow-register.s43) | [`6475709`](https://github.com/martonbognar/sancus-core-gap/commit/64757098191824238df9a502f7fd8cfbcadb61b2) | Resuming an enclave with `reti` multiple times. |
| V-B4            | [B-4-reentering-from-isr.s43](core/sim/rtl_sim/src/gap-attacks/B-4-reentering-from-isr.s43) | [`3636536`](https://github.com/martonbognar/sancus-core-gap/commit/3636536772baac7523d59fa3708df6b52518d267) | Restarting enclaves from the ISR. |
| V-B5            | [B-5-multiple-enclaves.s43](core/sim/rtl_sim/src/gap-attacks/B-5-multiple-enclaves.s43) | [`b17b013`](https://github.com/martonbognar/sancus-core-gap/commit/b17b013e65411df1d557cc34a2c4f7c46ebf7a58) | Multiple enclaves. |
| V-B6            | [B-6-untrusted-memory.s43](core/sim/rtl_sim/src/gap-attacks/B-6-untrusted-memory.s43) | [`d54f031`](https://github.com/martonbognar/sancus-core-gap/commit/d54f031b8705109509f598602899dec9c9dbd871) | Enclave accessing unprotected memory. |
| V-B7            | [B-7-gie.s43](core/sim/rtl_sim/src/gap-attacks/B-7-gie.s43); [B-7-ivt.s43](core/sim/rtl_sim/src/gap-attacks/B-7-ivt.s43); [B-7-peripheral.s43](core/sim/rtl_sim/src/gap-attacks/B-7-peripheral.s43) | [`264f135`](https://github.com/martonbognar/sancus-core-gap/commit/264f135e9fb7d903a90933861cfb81d6d2fba51d) [`093f51c`](https://github.com/martonbognar/sancus-core-gap/commit/093f51c73abdd84fbb95165bd6100ab8315993a3) | Manipulating interrupt behavior from the enclave. |

### Missing attacker capabilities

| Paper reference | Proof-of-concept attack | Patch? | Description |
|-----------------|---------------|:-------------:|-------------|
| V-C1            | [sancus-examples/dma](https://github.com/sancus-tee/sancus-examples/blob/master/dma/main.c) | :x: | DMA side-channel leakage (see also note below). |
| V-C2            | [C-2-watchdog.s43](core/sim/rtl_sim/src/gap-attacks/C-2-watchdog.s43) | [`c3dcf6e`](https://github.com/martonbognar/sancus-core-gap/commit/c3dcf6ef08d62e63ff66a8a69125abd66b7c892b) | Scheduling interrupts with the watchdog timer. |

**:bulb: DMA side channel.** As explained in our paper, the Sancus_V implementation is
based on an older version of the openMSP430 core without DMA capabilities.
Hence, the DMA attack does _not_ directly affect the current version of Sancus_V, and we
demonstrate the DMA side channel on the more recent (non-formalized) [upstream
version of Sancus](https://github.com/sancus-tee/sancus-core/).
Continuous integration for the DMA side-channel attack is, therefore,
integrated in the separate
[sancus-examples](https://github.com/sancus-tee/sancus-examples) repository,
referenced in the table above.
Also note that, as discussed in the paper, no straightforward mitigation
(apart from disabling DMA completely) exists at this point for the DMA side channel.

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
Specifically, the [`core/sim/rtl_sim/src/gap-attacks/`](core/sim/rtl_sim/src/gap-attacks) directory contains one
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
