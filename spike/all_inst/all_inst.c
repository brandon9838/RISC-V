

// This function tests Store (S-type), JALR, and PC+4 logic
void init_and_test_array(int *arr) {
    arr[0] = 100; // sw x10, 0(x11)
    arr[1] = 200; // sw x10, 4(x11)
    arr[2] = 300;
    arr[3] = 400;
    return; // jalr x0, 0(ra)
}

void main() {

    // A1. Test I-Type Arithmetic
    int a = 20;
    int b = (a + 12) - 2; // addi
    int c = (b ^ 0xAA) & 0x55; // xori, andi
    int d = (c | 0x01); // ori

    // A2. Test Shift Logic (Barrel Shifter & Fill Bit)
    int neg = -16; // 0xFFFFFFF0
    int sra_res = neg >> 2;  // srai: Expect 0xFFFFFFFC (-4)
    unsigned int uneg = 0xFFFFFFF0;
    unsigned int srl_res = uneg >> 2; // srli: Expect 0x3FFFFFFC
    int sll_res = a << 3; // slli

    // A3. Test Comparisons (Signed vs Unsigned)
    int slt_s = (neg < a);   // slti (signed): Expect 1
    int slt_u = ((unsigned int)a < uneg); // sltiu (unsigned): Expect 1

    // A4. Test B-Type Branches
    if (a == 20) { // beq
        if (neg != a) { // bne
            if (neg < 0) { // blt
                if (a >= 10) { // bge
                   a = a + 1;
                }
            }
        }
    }
    int test_array[4]; 
    int final_sum = 0;
    // --- B1. JAL and Memory Write Test ---
    // This calls the function and populates the array at runtime.
    init_and_test_array(test_array);

    // --- B2. Load-Use Hazard Test ---
    // Loading a freshly stored value and using it immediately.
    // Your Hazard Unit must insert a 1-cycle bubble.
    int val = test_array[2]; // lw x10, 8(x11)
    int hazard1 = val + 50;  // addi x12, x10, 50 <-- Dependency

    // --- B3. Multiplier-Use Hazard Test ---
    // Testing the 8-cycle multiplier stall with a negative input.
    int m_a = -5;
    int m_b = 20;
    int prod = m_a * m_b;    // mul x13, x14, x15
    int hazard2 = prod + 10; // addi x16, x13, 10 <-- Must stall for 7-8 cycles

    // --- B4. Branch and Comparison Corner Case ---
    // Testing signed vs unsigned logic for the branch condition.
    // hazard1 is 350, hazard2 is -90.
    if (hazard2 < hazard1) {  // blt x16, x12, label (signed)
        final_sum = hazard1 + hazard2; // Should be 260
    } else {
        final_sum = 0xEEEEEEEE; // Error case
    }

    // --- B5. Shift Range Corner Case ---
    // Verifying that only the lower 5 bits of the shift amount are used.
    int shift_val = 1;
    int amt = 35; // 35 & 31 = 3
    final_sum = final_sum + (shift_val << amt); // Should add 8 (1 << 3)

    return;
}

//riscv32-unknown-elf-gcc -O3 -funroll-loops -march=rv32im -mabi=ilp32 test.c -o test.elf
// O0 if test line are removed.
//riscv32-unknown-elf-objdump -d test.elf > test.dis
//riscv-isa-sim/build/spike -d --isa=RV32IMAC riscv-pk/build/pk test.elf
//
//identify clean_log.txt manually from test.dis and golden_trace.txt
//parse_log
//identify inst.txt from test.dis, include only the used ones.
//parse_inst, get the addr/data.
//calculate the instruction memory address
//example: 101c4~103b0
//65988~66480
//4 byte per word, 4 word per cache block
//so we padd address so it is divisible by 16
//65984~66495
//512 bytes
//128 words
//32 blocks
//set inst2cache accordingly
//buffer size=32*4
//offset     =65984/4
//inst2cache.py convert addr/data to full block to better fit in cache space.
//this also print dmem addr min/max
//remember to calculate cache offset according to the above method
//remove the last "return" instruction, and add a few bubbles to let the instructions finish.
//set tb param
//localparam PC_START=    32'h00010238;
//localparam END_PC=      32'h000103c0; 
//localparam OFFSET_D=    2147482908//16=134217681
//localparam OFFSET_I=    65984/16=4124
//identify register initial state
//riscv-isa-sim/build/spike -d --isa=RV32IMAC riscv-pk/build/pk test.elf
//until pc 0 101f8(the start of main)
//reg 0
//assign value using tb or using additiona addi/lui instructions.


