# 5-Stage Pipelined RISC-V Processor

A **RISC-V (RV32IM)** processor implementation in Verilog.

## Supported Instruction Set
[cite_start]The following table lists the specific RV32IM subset currently implemented in the hardware[cite: 7, 13, 29, 34].

| Category | Supported Instructions | Notes |
| :--- | :--- | :--- |
| **Arithmetic (I-Type)** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI` | [cite_start]Full support[cite: 7, 8, 27, 28]. |
| **Arithmetic (R-Type)** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | [cite_start]Full support[cite: 9, 10, 11, 31, 33]. |
| **Logical Shifts** | `SLLI`, `SRLI`, `SRAI` | [cite_start]Full support[cite: 19, 44, 50]. |
| **Memory Access** | `LW`, `SW` | [cite_start]Half-word (`LH`) and Byte (`LB`) not supported[cite: 29, 36]. |
| **Branches** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | [cite_start]Full support[cite: 12, 13, 35, 40]. |
| **Jumps** | `JAL`, `JALR` | [cite_start]Full support[cite: 27, 37, 40]. |
| **Upper Imm** | `LUI`, `AUIPC` | [cite_start]Full support[cite: 24, 38, 39]. |
| **M-Extension** | `MUL` | [cite_start]8-cycle accumulating implementation[cite: 21, 29, 53]. |

> **Note:** System instructions (`ECALL`, `EBREAK`, `FENCE`, `PAUSE`)  are **unsupported**.
