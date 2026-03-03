# 5-Stage Pipelined RISC-V Processor

A **RISC-V (RV32IM)** processor implementation in Verilog.

##Key Feature: Pattern Generation & Verification with Spike
A key feature of this project is the simulation framework using Spike (RISC-V ISA Simulator). Rather than manually writing test cases, C programs are compiled and executed on Spike to generate "golden" instruction traces and memory dumps. Custom Python scripts (parse_log.py, inst2cache.py) then translate these traces into binary patterns (.bin) that are loaded directly into the Verilog testbench. This ensures that every register write and memory store in the 5-stage pipeline is cycle-accurate and functionally identical to the official RISC-V ISA specification.

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
The repository is organized into hardware source code, Python verification scripts, and pre-compiled patterns from the Spike simulator.

```text
├── spike/                  # Golden traces and binary patterns generated from spike
│   ├── all_inst/           # Comprehensive instruction test
│   └── mat_mul/            # Matrix multiplication 
├── src/
│   ├── python/             # Log parsing and bin generation scripts
│   └── verilog/            # Verilog Source Files
│       ├── *.v             # RISC-V core implementation
│       ├── tb_mat.v        # Testbench for matrix multiplication
│       └── tb_all_inst.v   # Testbench for comprehensive instruction tesst

