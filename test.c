int A[4][4];
int B[4][4];
int C[4][4];

void init_data() {
    // These become real instructions that your CPU executes
    A[0][0] = 1; A[0][1] = 2; A[0][2] = 3; A[0][3] = 4;
    A[1][0] = 4; A[1][1] = 5; A[1][2] = 6; A[1][3] = 7;
    A[2][0] = 8; A[2][1] = 9; A[2][2] =10; A[2][3] =11;
    A[3][0] =12; A[3][1] =13; A[3][2] =14; A[3][3] =15; 
    
    B[0][0] = 2; B[0][1] = 4; B[0][2] = 1; B[0][3] = 1;
    B[1][0] = 3; B[1][1] =24; B[1][2] =51; B[1][3] = 3;
    B[2][0] = 2; B[2][1] =41; B[2][2] =13; B[2][3] = 5;
    B[3][0] = 3; B[3][1] =14; B[3][2] =19; B[3][3] = 7;

    C[0][0] = 0; C[0][1] = 0; C[0][2] = 0; C[0][3] = 0;
    C[1][0] = 0; C[1][1] = 0; C[1][2] = 0; C[1][3] = 0;
    C[2][0] = 0; C[2][1] = 0; C[2][2] = 0; C[2][3] = 0;
    C[3][0] = 0; C[3][1] = 0; C[3][2] = 0; C[3][3] = 0;
}

void matmul(int a[4][4], int b[4][4], int c[4][4]) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            int sum = 0;
            // Unroll this loop in your assembly to show off OoO!
            for (int k = 0; k < 4; k++) {
                sum += a[i][k] * b[k][j];
            }
            c[i][j] = sum;
        }
    }
}



int main() {
    init_data();    // Your CPU fills its own RAM here
    matmul(A, B, C);
    *(volatile int*)0xFFFFFFF0 = 1;
    return 0;
}

//(spike) until pc 0 101f8
//(spike) reg 0
//zero: 0x00000000  ra: 0x000100ec  sp: 0x7ffffd90  gp: 0x00013dd8
//  tp: 0x00000000  t0: 0x00010fe0  t1: 0x0000000f  t2: 0x00000000
//  s0: 0x00000000  s1: 0x00000000  a0: 0x00000001  a1: 0x7ffffda4
//  a2: 0x7ffffdac  a3: 0x00000000  a4: 0x00000001  a5: 0x00000000
//  a6: 0x00000000  a7: 0x00000000  s2: 0x00000000  s3: 0x00000000
//  s4: 0x00000000  s5: 0x00000000  s6: 0x00000000  s7: 0x00000000
//  s8: 0x00000000  s9: 0x00000000 s10: 0x00000000 s11: 0x00000000
//  t3: 0x00000000  t4: 0x00000000  t5: 0x00000000  t6: 0x00000000