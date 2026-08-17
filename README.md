# RV32I 5-Stage Pipelined CPU Core

An educational 32-bit RISC-V RTL core implementing a useful RV32I subset in a classic five-stage IF/ID/EX/MEM/WB microarchitecture.

## Implemented instruction subset
- R-type: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`
- I-type: `ADDI`
- Memory: `LW`, `SW`
- Branch: `BEQ`, `BNE`
- Control flow: `JAL`

## Microarchitecture
- Five pipeline stages: IF, ID, EX, MEM, WB
- EX/MEM and MEM/WB forwarding paths
- One-cycle load-use interlock
- Taken branch/JAL redirect with younger-instruction flush
- x0 hard-wired to zero
- Harvard-style instruction/data interfaces for a simple testbench memory model

## Verification
The self-checking regression explicitly checks:
- arithmetic correctness
- back-to-back forwarding dependencies
- load/store behavior
- load-use stalling
- taken-branch flushing
- x0 architectural invariant
- PC alignment

An optional SVA module documents architectural properties for simulators with fuller assertion support.

## Run
```bash
make test
```
Requires Icarus Verilog with SystemVerilog support.

## Repository structure
```text
rtl/alu.sv
rtl/regfile.sv
rtl/rv32i_pipeline.sv
tb/tb_rv32i_pipeline.sv
tb/rv32i_sva.sv
tools/encode.py
```

## Skills demonstrated
SystemVerilog RTL, RISC-V ISA encoding, pipelined CPU design, hazard detection, forwarding, control hazards, self-checking verification, architectural assertions and regression debugging.
