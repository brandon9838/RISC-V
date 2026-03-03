# 5-Stage Pipelined RISC-V Processor

A **RISC-V (RV32IM)** processor implementation in Verilog.

## Key Feature: Pattern Generation & Verification with Spike
A key feature of this project is the simulation framework using Spike (RISC-V ISA Simulator). Rather than manually written test cases, C programs are compiled and executed on Spike to generate "golden" instruction traces and memory dumps. Custom Python scripts (parse_log.py, inst2cache.py) then translate these traces into binary patterns (.bin) that are loaded directly into the Verilog testbench. This ensures that every register write and memory store in the 5-stage pipeline is cycle-accurate and functionally identical to the official RISC-V ISA specification.

## Supported Instruction Set
The following table lists the specific RV32IM subset currently implemented in the hardware.

| Category | Supported Instructions | Notes |
| :--- | :--- | :--- |
| **Arithmetic (I-Type)** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI` | Full support. |
| **Arithmetic (R-Type)** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | Full support. |
| **Logical Shifts** | `SLLI`, `SRLI`, `SRAI` | Full support.  |
| **Memory Access** | `LW`, `SW` | Half-word (`LH`) and Byte (`LB`) not supported. |
| **Branches** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | Full support.  |
| **Jumps** | `JAL`, `JALR` | Full support.  |
| **Upper Imm** | `LUI`, `AUIPC` | Full support. |
| **M-Extension** | `MUL` | 8-cycle accumulating multiplier. |

> **Note:** System instructions (`ECALL`, `EBREAK`, `FENCE`, `PAUSE`)  are **unsupported**.

---

## Project Structure
The repository is organized into pre-compiled patterns from the Spike simulator, Python translation scripts, and hardware source code.

```text
├── spike/                  # Golden traces and binary patterns generated from spike
│   ├── all_inst/           # Comprehensive instruction test
│   └── mat_mul/            # Matrix multiplication 
├── src/
│   ├── python/             # Log translation scripts
│   └── verilog/            # Verilog Source Files
│       ├── *.v             # RISC-V core implementation
│       ├── tb_mat.v        # Testbench for matrix multiplication
│       └── tb_all_inst.v   # Testbench for comprehensive instruction tesst
```

## Verification Flow
### Prerequisites
- iverilog
- GTKWave (Optional, for waveform viewing)
### How to Run
1. Select a Pattern: Copy the necessary .bin files from the desired spike subfolder (e.g., /spike/mat_mul/) into the /src/verilog/ directory.
   ```
   These files are required for simulation.
   instr_final.bin
   reg_addr.bin
   reg_data.bin
   sw_addr.bin
   sw_data.bin
   lw_addr.bin
   lw_data.bin
   ```
2. Execute Simulation: Navigate to /src/verilog/ and run the following commands:
   ```
   iverilog -o test.out tb_mat.v slow_memory.v CHIP.v cache.v riscv.v control.v MEM.v EX.v ID.v IF.v
   vvp test.out
   ```
