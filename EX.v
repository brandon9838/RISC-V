

module Barrel_Shift(
    input   [31:0]    data_in,
    input   [ 4:0]    shamt,
    input             shift_left,
    input             logical_shift,
    output  [31:0]    data_out
);
    genvar i;
    reg [31:0] mid_res [0:4];
    wire fill_bit=logical_shift?1'b0:data_in[31];
    generate
    always@(*)begin
        if (shamt[0]) begin
            if      (shift_left)    mid_res[0]={data_in[30:0],1'b0};
            else                    mid_res[0]={fill_bit,data_in[31:1]};
        end 
        else mid_res[0]=data_in;
    end
    for (i=1;i<5;i=i+1)begin
        always@(*)begin
            if (shamt[i]) begin
                if      (shift_left)    mid_res[i]={mid_res[i-1][31-(2**i):0],{(2**i){1'b0}}};
                else                    mid_res[i]={{(2**i){fill_bit}},mid_res[i-1][31:(2**i)]};
            end 
            else mid_res[i]=mid_res[i-1];
        end
    end 
    endgenerate
    assign data_out = mid_res[4];
endmodule
module EX_stage(
    input                   clk,
    input                   rst_n,
    input                   stall,
    input                   IDEX_ctrl_rtype,
    input                   IDEX_ctrl_itype,
    input                   IDEX_ctrl_jalr,
    input                   IDEX_ctrl_stype,
    input                   IDEX_ctrl_btype,
    input                   IDEX_ctrl_utype,
    input                   IDEX_ctrl_jtype,
    input                   IDEX_ctrl_alusrc,
    input           [31:0]  IDEX_rs1_data,
    input           [31:0]  IDEX_rs2_data,
    input           [31:0]  IDEX_imm,
    input           [ 2:0]  IDEX_func3,
);
    genvar i;
    //Itype func3
    localparam ADDI = 3'b000;
    localparam SLTI = 3'b010;
    localparam SLTIU= 3'b011;
    localparam XORI = 3'b100;
    localparam ORI  = 3'b110;    
    localparam ANDI = 3'b111;
    localparam SLLI = 3'b001;
    localparam SRLI = 3'b101;
    localparam SRAI = 3'b101;
    //Rtype fun3
    localparam ADD  =3'b000;
    localparam SUB  =3'b000;
    localparam SLL  =3'b001;
    localparam SLT  =3'b010;
    localparam SLTU =3'b011;
    localparam XOR  =3'b100;
    localparam SRL  =3'b101;
    localparam SRA  =3'b101;
    localparam OR   =3'b110;
    localparam AND  =3'b111;

    reg [31:0]  ALU_add;
    reg [31:0]  ALU_addr_add;
    reg [32:0]  ALU_sub;
    reg [31:0]  ALU_and;
    reg [31:0]  ALU_or; 
    reg [31:0]  ALU_xor;
    wire[31:0]  ALU_shift;
    wire[ 4:0]  ALU_shamt=ALU_in2[4:0];
    reg         ALU_zero;
    reg         ALU_not_zero;
    reg         ALU_overflow;
    reg         ALU_less_unsigned;
    reg         ALU_less_signed;
    
    wire        shift_left=~IDEX_func3[2];
    wire        logical_shift=IDEX_ctrl_itype?~IDEX_imm[10]:IDEX_imm[30];
    Barrel_Shift u_barrel_shift (
    .data_in        (ALU_in1        ),          
    .shamt          (ALU_shamt      ),      
    .shift_left     (shift_left     ),          
    .logical_shift  (logical_shift  ),              
    .data_out       (ALU_shift      )                
    );

    always@(*)begin //ALU combinational circuit
		//ALU input assignment
		ALU_in1=IDEX_rs1_data;
        ALU_in2=(IDEX_ctrl_alusrc)?IDEX_rs2_data:IDEX_imm;
		
		//ALU operations
		ALU_add=ALU_in1 + ALU_in2;
		ALU_sub=ALU_in1 - ALU_in2;
		ALU_and=ALU_in1 & ALU_in2;
		ALU_or =ALU_in1 | ALU_in2;
		ALU_xor=ALU_in1 ^ ALU_in2;
		
        ALU_not_zero=(|ALU_sub);
		ALU_zero=!ALU_not_zero;
        ALU_less_unsigned=ALU_sub[32];
        ALU_overflow=(ALU_in1[31]!=ALU_in2[31]) && (ALU_sub[31]!=ALU_in1[31]);
        ALU_less_signed=ALU_sub[31]^ALU_overflow;

		//ALU output MUX
		if (IDEX_ctrl_itype) begin	//Itype
            if      (IDEX_ctrl_jalr)    ALU_out={ALU_add[31:1],1'b0}
			else if (IDEX_func3==SLTI)  ALU_out=ALU_less_signed;
            else if (IDEX_func3==SLTIU) ALU_out=ALU_less_unsigned;
			else if (IDEX_func3==ANDI)	ALU_out=ALU_and;
			else if (IDEX_func3==ORI)	ALU_out=ALU_or;
			else if (IDEX_func3==XORI)	ALU_out=ALU_xor;
			else if (IDEX_func3==SLLI || 
                     IDEX_func3==SRLI || 
                     IDEX_func3==SRAI)	ALU_out=ALU_shift;
			else						ALU_out=ALU_add; // addi/lw
		end
        else if (IDEX_ctrl_rtype) begin	//Rtype
			if      (IDEX_func3==ADD &&
                     !IDEX_imm[30])		    ALU_out=ALU_add;
            else if (IDEX_func3==SUB &&
                     IDEX_imm[30])		    ALU_out=ALU_sub[31:0];
            else if (IDEX_func3==SUB &&
                     IDEX_imm[25])		    ALU_out=0;  //reserved for mul
            else if (IDEX_func3==SLT)		ALU_out=ALU_less_signed;
            else if (IDEX_func3==SLTU)		ALU_out=ALU_less_unsigned;
            else if (IDEX_func3==XOR)		ALU_out=ALU_xor;
            else if (IDEX_func3==OR)		ALU_out=ALU_or;
            else if (IDEX_func3==AND)		ALU_out=ALU_and;
            else if (IDEX_func3==SLL ||
                     IDEX_func3==SRL ||
                     IDEX_func3==SRA)		ALU_out=ALU_shift;
        end
			default:						ALU_out=ALU_sub; // beq/jal
	end
	
	always@(*)begin //Combinational circuit
		imm_sign_ext_IDEX={{16{imm_IDEX_r[15]}}, imm_IDEX_r};
		imm_zero_ext_IDEX={16'h0000,imm_IDEX_r};
		beq_addr_IDEX={{14{imm_IDEX_r[15]}}, imm_IDEX_r,2'b00} + PC4_IDEX_r;
		jr_addr_IDEX=rs_data_IDEX_r;
		
		if (ctrl_mem_stall)begin
			reg_write_addr_EXMEM_w=reg_write_addr_EXMEM_r;
			reg_write_data_EXMEM_w=reg_write_data_EXMEM_r;
			sw_rt_data_EXMEM_w=sw_rt_data_EXMEM_r;
		end
		else begin
			reg_write_addr_EXMEM_w=reg_write_addr_IDEX_r;
			reg_write_data_EXMEM_w=ALU_out;
			sw_rt_data_EXMEM_w=rt_data_IDEX_r;
		end
	end
	
	always@( posedge clk or negedge rst_n ) begin	//Sequential circuit
		if(!rst_n)begin
			reg_write_addr_EXMEM_r<=5'b00000;
			reg_write_data_EXMEM_r<=32'h00000000;
			sw_rt_data_EXMEM_r<=32'h00000000;
		end
		else begin
			reg_write_addr_EXMEM_r<=reg_write_addr_EXMEM_w;
			reg_write_data_EXMEM_r<=reg_write_data_EXMEM_w;
			sw_rt_data_EXMEM_r<=sw_rt_data_EXMEM_w;
		end
	end
endmodule
