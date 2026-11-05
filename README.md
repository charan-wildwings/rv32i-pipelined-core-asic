# rv32i-pipelined-core-asic
Five-stage pipelined 32-bit RISC-V core implementing an RV32I instruction subset in Verilog, with data forwarding, load-use hazard handling, branch/jump flushing, regression testbenches, and Yosys/OpenROAD ASIC implementation artifacts targeting Nangate45.


# Five-Stage Pipelined RISC-V Processor: RTL to ASIC Layout

## Project Overview

This project implements a 32-bit RISC-V processor in Verilog using a five-stage pipeline. It demonstrates processor datapath design, instruction decoding, dependency handling, simulation-based verification, logic synthesis, and ASIC physical implementation.

The processor implements a subset of the RV32I base integer instruction set. The project includes RTL modules, testbenches, simulation waveforms, a regression report, synthesis outputs, timing reports, and physical-design artifacts, including DEF and GDS files.

The ASIC flow targets the Nangate45 standard-cell platform using Yosys and OpenROAD flow resources.

## 1. Processor Architecture

The processor divides instruction execution into five stages:

`Instruction Fetch → Instruction Decode → Execute → Memory Access → Write Back`

Pipeline registers separate the stages and carry instruction data and control signals between clock cycles. This allows several instructions to be processed at different stages simultaneously.

### Instruction Fetch — IF

The program counter supplies the address of the instruction to fetch.

For sequential execution, the next address is:

`next_pc = current_pc + 4`

When a taken branch or jump is resolved, the processor redirects the program counter to the target address.

The core exposes an instruction-memory interface rather than embedding instruction memory inside the top-level processor module.

### Instruction Decode — ID

The fetched instruction is separated into fields such as opcode, source registers, destination register, and function bits.

The control unit generates signals that determine:

- Whether a register will be written.
- Whether memory will be read or written.
- Whether the ALU uses a register operand or an immediate.
- Whether the instruction is a branch or jump.
- Which value will be selected during write back.

The immediate generator extracts and extends the instruction’s immediate value.

The register file contains 32 registers, each 32 bits wide. Register x0 always reads as zero, and writes to x0 are ignored.

### Execute — EX

The arithmetic logic unit performs arithmetic, logical, shift, and comparison operations.

For load and store instructions, it calculates the memory address by adding a base-register value to an immediate offset.

The branch unit compares source operands. Branch and JAL target addresses are calculated from the instruction’s program counter and immediate offset.

### Memory Access — MEM

The core exposes separate data-memory signals for:

- Address.
- Write data.
- Read enable.
- Write enable.
- Read data.

For a load, data returned by memory passes toward the write-back stage. For a store, the processor supplies the address and data to write.

The current interface has no memory-ready or wait-state handshake, so integration must match the timing assumptions of the core.

### Write Back — WB

The processor selects the value to write into the destination register:

- ALU result for arithmetic and logical instructions.
- Memory data for loads.
- PC + 4 for JAL.

## 2. Implemented Instruction Subset

The inspected RTL includes decoding and datapath support for the following instructions:

| Category | Instructions |
|---|---|
| Register arithmetic | ADD, SUB |
| Register logical operations | AND, OR, XOR |
| Register shifts | SLL, SRL |
| Signed comparison | SLT |
| Immediate arithmetic and logic | ADDI, ANDI, ORI, XORI |
| Immediate shifts and comparison | SLLI, SRLI, SLTI |
| Word memory access | LW, SW |
| Conditional branches | BEQ, BNE, BLT, BGE |
| Jump and link | JAL |

This is a partial RV32I implementation. Full RV32I compliance is not established by the supplied tests.

Instructions such as LUI, AUIPC, JALR, unsigned comparisons and branches, arithmetic right shifts, and byte/halfword memory operations are not implemented as distinct operations in the inspected RTL. Unsupported encodings are not comprehensively rejected.

## 3. Pipeline Hazard Handling

### Data Forwarding

An instruction may require a result before an earlier instruction has written it into the register file.

For example:

    ADD x3, x1, x2
    SUB x4, x3, x1

The SUB instruction depends on the ADD result. Forwarding paths supply recent results directly from later pipeline stages to the execute-stage operands.

The implementation includes forwarding from EX/MEM and MEM/WB.

### Load-Use Hazard Detection

A load result is available later than a normal ALU result.

For example:

    LW  x5, 0(x1)
    ADD x6, x5, x2

The hazard unit detects the dependency and controls the program-counter update, IF/ID register update, and insertion of a bubble into the execution pipeline.

### Write-Back-to-Decode Bypass

The core also includes a bypass from the write-back value to the decode-stage operands.

This handles the case where an instruction reads a register during the same cycle that an older instruction writes that register.

### Branch and Jump Flushing

Branches and jumps are resolved in the execute stage.

When the processor redirects execution, it flushes younger instructions in IF/ID and ID/EX so that instructions fetched along the previous path do not continue normally.

## 4. Main Verilog Modules

| Module | Purpose |
|---|---|
| rv32i_core.v | Connects the processor pipeline and external interfaces |
| pc.v | Stores and updates the program counter |
| regfile.v | Implements the 32 × 32-bit register file |
| control_unit.v | Generates main control signals from the opcode |
| imm_gen.v | Extracts instruction immediate values |
| alu_control.v | Selects the ALU operation |
| alu.v | Performs arithmetic, logic, shift, and comparison operations |
| branch_unit.v | Evaluates supported branch conditions |
| forwarding_unit.v | Selects forwarded execute-stage operands |
| hazard_unit.v | Detects load-use dependencies |
| if_id_reg.v | Stores fetch-to-decode pipeline state |
| id_ex_reg.v | Stores decode-to-execute pipeline state |
| ex_mem_reg.v | Stores execute-to-memory pipeline state |
| mem_wb_reg.v | Stores memory-to-write-back pipeline state |

Separate instruction-memory and data-memory modules are also supplied for use around the core.

## 5. Verification

The project contains testbenches for:

- ALU behavior.
- Control-unit decoding.
- Branch behavior.
- JAL behavior.
- Integrated processor operation.
- Regression checking.

The saved regression report records nine passing register-value checks and one passing memory-value check, followed by:

“FINAL RESULT: ALL TESTS PASSED”

These results describe the supplied regression program. They do not establish exhaustive instruction coverage or formal ISA compliance.

Simulation waveform files are included for inspecting signal activity and pipeline behavior.

## 6. ASIC Implementation Flow

The project contains artifacts corresponding to these implementation stages:

1. Logic synthesis — converts Verilog into a gate-level netlist.
2. Floorplanning — defines the chip and core regions.
3. Power distribution — provides the physical power network.
4. Placement — positions standard cells.
5. Clock-tree synthesis — distributes the clock to sequential cells.
6. Routing — connects cells through metal interconnect.
7. Timing analysis — checks signal arrival times against constraints.
8. Final output generation — produces netlists, layout data, constraints, and parasitic information.

The supplied configuration targets Nangate45 and specifies:

| Parameter | Configured value |
|---|---|
| Die area | 260 × 260 µm |
| Core area | 220 × 220 µm |
| Placement density target | 0.55 |
| Clock period | 10 ns |
| Corresponding target clock frequency | 100 MHz |

The frequency is the configured target, rather than a measured silicon result.

## 7. Recorded Implementation Results

The supplied final timing report records:

| Metric | Reported result |
|---|---|
| Worst setup slack | Approximately +7.97 ns |
| Setup violations | 0 |
| Hold violations | 0 |
| Maximum slew violations | 0 |
| Maximum fanout violations | 0 |
| Maximum capacitance violations | 2 |
| Estimated total power | Approximately 2.09 mW |

Positive setup slack indicates that the reported paths meet the configured setup timing requirements under the analyzed conditions.

Two maximum-capacitance violations remain in the final report. The implementation should therefore be described as having generated physical-design outputs with remaining electrical violations, rather than as fully signoff-clean.

The power figure is a tool estimate under the report’s analysis assumptions, not measured hardware power.

## 8. Project Folder Organization

The supplied project contains three main folders:

| Folder | Contents |
|---|---|
| rv32i-pipeline/ | Organized RTL, testbenches, synthesis scripts, constraints, reports, and results |
| rv32i_core/base/ | Physical-design reports, intermediate databases, final layout files, and images |
| ALL_VERILOG_FILES/ | A collected set of RTL, testbench, backup, and generated Verilog files |

The rv32i-pipeline folder is the clearest starting point for presenting the source project on GitHub. Generated netlists and older backup versions should be clearly separated from the current RTL.

## 9. Project Significance

This project demonstrates how processor architecture connects to digital implementation:

- Instructions are translated into datapath and control actions.
- Pipelining overlaps instruction execution.
- Forwarding and stalling manage dependencies.
- Branch flushing handles changes in control flow.
- Testbenches check selected functional behavior.
- Synthesis translates RTL into standard cells.
- Physical implementation produces placement, routing, and layout artifacts.

It provides a practical foundation for studying computer architecture, Verilog design, processor verification, and ASIC implementation.

## 10. Future Improvements

Potential extensions include:

- Completing the remaining RV32I instructions.
- Adding explicit illegal-instruction handling.
- Expanding instruction and dependency coverage.
- Adding automated self-checking regression execution.
- Supporting memory wait states.
- Reviewing register initialization and reset behavior for ASIC integration.
- Resolving the remaining capacitance violations.
- Packaging tool versions, configuration, and execution steps for reproducibility.

The results documented here are based on the supplied RTL and saved reports. Simulation and physical implementation were not rerun for this documentation.
