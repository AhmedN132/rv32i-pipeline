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
## Notes and Reflection

### Challenges Encountered

#### 1. Handling Data Hazards
One of the more challenging parts of designing the five-stage pipeline was managing dependencies between consecutive instructions. Since multiple instructions execute simultaneously, an instruction may need a register value that a previous instruction has not written back yet.
To address this, I implemented forwarding paths from the EX/MEM and MEM/WB pipeline stages, allowing the ALU to receive results directly from earlier instructions without unnecessarily waiting for register writeback. Understanding when forwarding should occur, and which pipeline stage should take priority, was an important part of getting the datapath to function correctly.

#### 2. Load-Use Hazards and Pipeline Stalling
Unlike arithmetic instructions, load instructions introduce an additional complication because the requested data is not available until the memory access stage. This means forwarding alone cannot resolve an immediate dependency on a load result.
I addressed this by implementing a hazard detection mechanism that introduces a one-cycle stall when an instruction immediately depends on a preceding load. The challenge was ensuring that the program counter and IF/ID pipeline register were held while the dependent instruction was delayed, without disrupting subsequent execution.

#### 3. Branch Handling and Pipeline Flushing
Another challenging aspect was handling control flow instructions such as BEQ, BNE, and JAL. Since branch decisions are resolved in the execution stage, the processor may have already fetched instructions from the wrong execution path.
To handle this, I implemented logic to redirect the program counter and flush younger instructions whenever a taken branch or jump occurs. This helped reinforce how pipelining improves instruction throughput while introducing additional control complexity.

#### 4. Verification and Debugging
Verifying the processor was arguably as important as implementing the datapath itself. Individual components can behave correctly in isolation while still producing incorrect results when connected in a pipeline.
To improve confidence in the design, I used a self-checking SystemVerilog testbench covering arithmetic operations, forwarding dependencies, memory access, load-use stalls, branch flushing, and architectural invariants such as keeping register x0 equal to zero.
These tests helped establish a more systematic approach to verification rather than relying entirely on visual waveform inspection.

### What I Would Do Differently
If I were to rebuild this project, I would make a few improvements to both the development process and the processor itself.
- **Develop incrementally:** Begin with a simple single-cycle processor before introducing pipelining, forwarding, and hazard detection. This would make it easier to isolate functionality and identify where errors originate.
- **Expand verification coverage:** Introduce more directed corner-case tests, randomized instruction sequences, and reference-model comparisons to verify behavior beyond the existing regression tests.
- **Improve modularity:** Further separate pipeline control, forwarding, and hazard detection logic into dedicated modules to simplify debugging and future modifications.
- **Expand instruction support:** Extend the currently implemented RV32I subset to support additional arithmetic, shift, comparison, load/store, and control-flow instructions.
- **Evaluate timing and performance:** Use synthesis and timing analysis to better understand the critical path, hardware resource utilization, and maximum achievable clock frequency.

### Final Takeaway

The biggest lesson from this project was that implementing individual CPU components is only part of the challenge. The real complexity comes from coordinating those components so that multiple instructions can move through the pipeline without violating dependencies or producing incorrect results.

Working through forwarding, stalling, and branch handling gave me a much stronger understanding of how processor architecture translates into actual RTL, while developing the verification environment reinforced the importance of testing interactions between components rather than only testing them individually.
```

## Skills demonstrated
SystemVerilog RTL, RISC-V ISA encoding, pipelined CPU design, hazard detection, forwarding, control hazards, self-checking verification, architectural assertions and regression debugging.
