# IOb-SoC-OpenCryptoHW

This project aims to develop reconfigurable open-source cryptographic hardware
IP cores for Next Generation Internet. With the Internet of Things upon us,
security and privacy are more important than ever. On the one hand, the risks
are high if the security and privacy features are exclusively implemented in
software. On the other hand, if implemented solely in hardware, it is impossible
to fix bugs or deploy critical updates, a threat to security and privacy. Hence,
we propose to use reconfigurable hardware, providing the flexibility of software
and the trustworthiness of hardware.  There have been proposals to implement
cryptographic IP cores using Field Programmable Gate Array (FPGAs). However, the
FPGA configuration infrastructure is cumbersome and proprietary, increasing
device cost and compromising safety. Hacking into it requires first hacking the
device’s configuration infrastructure and then hacking the algorithm itself,
which is way more complicated.  Therefore, we propose to use open-source
Coarse-Grained Reconfigurable Arrays (CGRAs) instead of FPGAs. CGRAs have much
lighter configuration circuits and are not controlled by any private entity.

# Setup
Clone the repository and the submodules with:
```
git clone --recursive git@github.com:IObundle/IOb-SoC-OpenCryptoHW.git
```
or using the url:
```
git clone --recursive https://github.com/IObundle/IOb-SoC-OpenCryptoHW.git
```
* * *
# Supported Algorithms
Currently, the IOb-SoC-OpenCryptoHW supports two algorithms: SHA256 and AES256.

## Test Vectors
### SHA256
The test vectors for the SHA256 algorithm performs the Short Message Test for
Byte-Oriented `sha256()` implementations from the 
[NIST Cryptographic Algorithm Validation
Program](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/secure-hashing).

The test vectors are a set of 65 messages from 0 to 64 byte length. The 
implementation program only receives the messages and outputs the corresponding
message digests (MD). An external script compares the implementation output with
the expected MD from the test vectors.

### AES256
The test vectors for the AES256 algorithm perform 10 encryptions adapted from
the [NIST cryptographic Algorithm Validation
Program](https://csrc.nist.gov/Projects/cryptographic-algorithm-validation-program/Block-Ciphers).

Each test vector is adapted from the [AES Multiblock Message Test (MMT) Sample
Vectors](https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/aes/aesmct_intermediate.zip)
where each plaintext is the first block from each multiblock vector.

### MCELIECE
The McEliece test vector is the first keypair test from the [NIST Classic
McEliece Post-Quantum Cryptography Round 4
Submission](https://csrc.nist.gov/csrc/media/Projects/post-quantum-cryptography/documents/round-4/submissions/mceliece-kat-Round4.tar.gz)
for the McEliece348864 version.

# PC Emulation
The IOb-SoC-OpenCryptoHW system can build and run an environment for PC with:
```
# SHA256 pc-emul test
make test-pc-emul ALGORITHM=SHA256
# AES256 pc-emul test
make test-pc-emul ALGORITHM=AES256
# MCELIECE pc-emul test
make test-pc-emul ALGORITHM=MCELIECE
```

The implementation output can be checked manually from terminal and
`software/pc-emul/ethernet.log`

### Clean environment
To clean the workspace after PC emulation:
```
make test-pc-emul-clean ALGORITHM={SHA256,AES256,MCELIECE}
```
### Requirements
PC emulation program requires:
- Git
- Make
- gcc
- Python 3.6+

* * *
# RISCV Emulation
The IOb-SoC-OpenCryptoHW system can be emulated using a verilog simulator like
icarus with:
```Make
# Test with all supported simulators
make test-sim
# Test with a specific simulator
make sim-test SIMULATOR=icarus ALGORITHM={SHA256,AES256,MCELIECE}
make sim-test SIMULATOR=verilator ALGORITHM={SHA256,AES256,MCELIECE}
```

### Clean environment
To clean the workspace after the RISCV emulation:
```
make test-sim-clean ALGORITHM={SHA256,AES256,MCELIECE}
```

### Requirements/Setup
RISCV emulation requires:
- PC Emulation requirements
- RISCV toolchain
    - Add the RISCV toolchain to you `PATH` variable in `$HOME/.bashrc`:
    ```
    export RISCV=/path/to/riscv/bin
    export PATH=$RISCV:$PATH
    ```
- Verilog simulator, for example: 
    - [icarus verilog](https://github.com/steveicarus/iverilog)  
    - [verilator](https://github.com/verilator/verilator)

# FPGA Synthesis
The system can be synthetized for FPGA with:
```
make fpga-build
```

The synthesis results can be found in: `hardware/fpga/vivado/AES-KU040-DB-G`. 

## FPGA Test
For a complete FPGA test (synthesis, load and execution), run:
```
make test-fpga ALGORITHM={SHA256,AES256,MCELIECE}
```

### Clean environment
To clean the workspace after the FPGA execution:
```
make test-fpga-clean ALGORITHM={SHA256,AES256,MCELIECE}
```

### Requirements/Setup
FPGA execution requires:
- Supported FPGA board
- Setup environment for FPGA execution
    - Add the executable paths and license servers in `$HOME/.bashrc`:
    ```
    export VIVADOPATH=/path/to/vivado
    ...
    export LM_LICENSE_FILE=port@licenseserver.myorg.com;lic_or_dat_file
    ```
    - Follow [IOb-soc's README](https://github.com/IObundle/iob-soc#readme) for
    more installation details.

# Ethernet
The system supports ethernet communication using the 
[IOb-Eth core](https://github.com/IObundle/iob-eth).

Check [IO-Eth's README](https://github.com/IObundle/iob-eth#readme) for setup 
instructions and further details.

# Versat
### Versat Custom Functional Units
The acceleration of SHA application requires the design of custom functional
units (FUs). These FUs can be validated with unit tests by running the command:
```
make test-versat-fus
```
The custom FUs are in `hardware/src/units/`.

### Spinal HDL Version
Alternatively, the same FUs can be generated from SpinalHDL using the command:
```
make test-versat-fus SPINAL=1
```
The SpinalHDL sources are in `hardware/src/spinalHDL`.

#### SpinalHDL Setup
Check `hardware/src/spinalHDL/README.md` for more details to setup the
requirements to use SpinalHDL.

### Versat FPGA Synthesis
The Versat Accelerator can be synthetized with the command:
```
make fpga-build-versat
```
The log file can be reviewed in
`hardware/fpga/vivado/AES-KU040-DB-G/versat.log`.
The netlist file can be reviewed in
`hardware/fpga/vivado/AES-KU040-DB-G/iob_versat.edif`.

# FuseSoC
IOb-SoC-OpenCryptoHW supports alternative
[FuseSoC](https://github.com/olofk/fusesoc) flows for simulation and fpga.
Run the targets:
```
# FuseSoC simulation flow
make fusesoc-sim-run ALGORITHM={SHA256,AES256,MCELIECE}
make fusesoc-clean ALGORITHM={SHA256,AES256,MCELIECE}
# FuseSoC fpga flow
make fusesoc-fpga-run ALGORITHM={SHA256,AES256,MCELIECE}
make fusesoc-fpga-clean ALGORITHM={SHA256,AES256,MCELIECE}
```

# OpenLane (SHA256 currently)
IOb-SoC-OpenCryptoHW supports
[OpenLane](https://github.com/The-OpenROAD-Project/OpenLane) flows.
To generate `.gds` file for the system:
```
make openlane-run
```
**Note**: requires 128 GB RAM and takes almost 5 days to complete

To perform post-synthesis or post-layout simulation in icarus:
```
# post-synthesis simulation
make openlane-post-synth-sim
make openlane-sim-clean
# post-layout simulation
make openlane-post-layout-sim
make openlane-sim-clean
```
**Note**: requires 32GB of RAM and takes about 12 hours to complete.

# Acknowledgement
This project is funded through the NGI Assure Fund, a fund established by NLnet
with financial support from the European Commission's Next Generation Internet
programme, under the aegis of DG Communications Networks, Content and Technology
under grant agreement No 957073.
