# 5-Stage Pipelined RISC-V Processor

A **RISC-V (RV32IM)** processor implementation in Verilog.

## Supported Instruction Set
The following table lists the specific RV32IM subset currently implemented in the hardware.

| Category | Supported Instructions | Notes |
| :--- | :--- | :--- |
| **Arithmetic (I-Type)** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI` | Full support. |
| **Arithmetic (R-Type)** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | Full support. |
| **Logical Shifts** | `SLLI`, `SRLI`, `SRAI` | [cite_start]Full support[cite: 19, 44, 50]. |
| **Memory Access** | `LW`, `SW` | Half-word (`LH`) and Byte (`LB`) not supported. |
| **Branches** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | Full support.  |
| **Jumps** | `JAL`, `JALR` | Full support.  |
| **Upper Imm** | `LUI`, `AUIPC` | Full support. |
| **M-Extension** | `MUL` | 8-cycle accumulating multiplier. |

> **Note:** System instructions (`ECALL`, `EBREAK`, `FENCE`, `PAUSE`)  are **unsupported**.
