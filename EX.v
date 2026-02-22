
module EX_stage(
    input                   clk,
    input                   rst_n,
    input                   mem_stall,
    input                   stall,
    input                   IDEX_ctrl_rtype,
    input                   IDEX_ctrl_itype,
    input                   IDEX_ctrl_jalr,
    input                   IDEX_ctrl_auipc,
    input                   IDEX_ctrl_lui,
    input                   IDEX_ctrl_stype,
    input                   IDEX_ctrl_btype,
    input                   IDEX_ctrl_utype,
    input                   IDEX_ctrl_jtype,
    input                   IDEX_ctrl_alusrc,
    input           [31:0]  IDEX_rs1_data,
    input           [31:0]  IDEX_rs2_data,
    input           [31:0]  IDEX_pc,
    input           [31:0]  IDEX_imm,       //for rtype, this is simply inst, get func7 from here
    input           [ 2:0]  IDEX_func3,
    input           [ 4:0]  IDEX_regw_addr,
    output reg      [4 :0]  EXMEM_regw_addr,
    output reg      [31:0]  EXMEM_regw_data, //also sw addr
    output reg      [31:0]  EXMEM_regw_data_w,
    output reg      [31:0]  EXMEM_sw_data, // sw data
    output          [31:0]  EX_alu_out,       // all b type comparison res and jalr addr
    output          [31:0]  EX_branch_addr,   // all b type addr
    output                  mult_stall
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
    //Btype fun3
    localparam BEQ  =3'b000;
    localparam BNE  =3'b001;
    localparam BLT  =3'b100;
    localparam BGE  =3'b101;
    localparam BLTU =3'b110;
    localparam BGEU =3'b111;

    reg [31:0]  ALU_in1;
    reg [31:0]  ALU_in2;
    reg [31:0]  ALU_out;
    reg [31:0]  ALU_add;
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
    
    reg [31:0]  EXMEM_extra_out_w;

    wire        shift_left=~IDEX_func3[2];
    wire        logical_shift=IDEX_ctrl_itype?~IDEX_imm[10]:IDEX_imm[30];
    Barrel_Shift u_barrel_shift (
    .data_in        (ALU_in1        ),          
    .shamt          (ALU_shamt      ),      
    .shift_left     (shift_left     ),          
    .logical_shift  (logical_shift  ),              
    .data_out       (ALU_shift      )                
    );
    wire mult_start = IDEX_ctrl_rtype && (IDEX_func3==ADD) && (IDEX_imm[25]);
    wire mult_ready;
    wire[31:0] mult_out;
    Cycle_8_mult u_cycle_8_mult(
    .clk            (clk        ),
    .rst_n          (rst_n      ),
    .mem_stall      (mem_stall  ),
    .start          (mult_start ),
    .data_in_1      (ALU_in1    ),
    .data_in_2      (ALU_in2    ),
    .ready          (mult_ready ),
    .data_out       (mult_out   )
    );
    assign mult_stall=mult_start && !mult_ready;
    always@(*)begin //ALU combinational circuit
		//ALU input assignment
		ALU_in1=(IDEX_ctrl_auipc)?IDEX_pc:IDEX_rs1_data;
        ALU_in2=(IDEX_ctrl_alusrc)?IDEX_imm:IDEX_rs2_data;
		
		//ALU operations
		ALU_add=ALU_in1 + ALU_in2;
		ALU_sub=ALU_in1 - ALU_in2;
		ALU_and=ALU_in1 & ALU_in2;
		ALU_or =ALU_in1 | ALU_in2;
		ALU_xor=ALU_in1 ^ ALU_in2;
		//ALU comparison
        ALU_not_zero=(|ALU_sub);
		ALU_zero=!ALU_not_zero;
        ALU_less_unsigned=ALU_sub[32];
        ALU_overflow=(ALU_in1[31]!=ALU_in2[31]) && (ALU_sub[31]!=ALU_in1[31]);
        ALU_less_signed=ALU_sub[31]^ALU_overflow;

		//ALU output MUX
		if (IDEX_ctrl_itype) begin	//Itype
            if      (IDEX_ctrl_jalr)    ALU_out={ALU_add[31:1],1'b0}; //this is the jalr jump address
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
			if      (IDEX_func3==ADD)begin
                if      (IDEX_imm[25])      ALU_out=mult_out;  //reserved for mul, not implemented yet
                else if (!IDEX_imm[30])		ALU_out=ALU_add;
                else                        ALU_out=ALU_sub[31:0];
            end
            else if (IDEX_func3==SLT)		ALU_out=ALU_less_signed;
            else if (IDEX_func3==SLTU)		ALU_out=ALU_less_unsigned;
            else if (IDEX_func3==XOR)		ALU_out=ALU_xor;
            else if (IDEX_func3==OR)		ALU_out=ALU_or;
            else if (IDEX_func3==AND)		ALU_out=ALU_and;
            else 		                    ALU_out=ALU_shift; //SLL/SRL/SRA
        end
        else if (IDEX_ctrl_btype) begin //Btype
            if      (IDEX_func3==BEQ)   ALU_out=ALU_zero;
			else if (IDEX_func3==BNE)   ALU_out=ALU_not_zero;
            else if (IDEX_func3==BLT)   ALU_out=ALU_less_signed;
			else if (IDEX_func3==BGE)	ALU_out=!ALU_less_signed;
            else if (IDEX_func3==BLTU)  ALU_out=ALU_less_unsigned;
            else                        ALU_out=!ALU_less_unsigned;//BGEU
        end
		else 	                        ALU_out=ALU_add;//Stype addr/auipc data **lui/jal will not use ALU_out 
	end
	assign EX_comp_res=ALU_out[0]; //control unit decides whether jump or not
    always@(*)begin
        //if      (stall)             EXMEM_regw_data_w=EXMEM_regw_data; //sequential clock gating
        if      (IDEX_ctrl_jtype||
                 IDEX_ctrl_jalr)    EXMEM_regw_data_w=IDEX_pc+4;  //jal/jalr return pc
        else if (IDEX_ctrl_lui)     EXMEM_regw_data_w=IDEX_imm; //lui data, could use 0+imm, but decide to use a mux 
        else                        EXMEM_regw_data_w=ALU_out;  //other
    end

    assign EX_branch_addr=IDEX_pc+IDEX_imm;
    assign EX_alu_out=ALU_out;

    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)         EXMEM_regw_addr<=0;
        else if (!stall)    EXMEM_regw_addr<=IDEX_regw_addr;
    end
    
	always@( posedge clk) begin
		if (!stall) begin
            EXMEM_regw_data<=EXMEM_regw_data_w;
            EXMEM_sw_data<=IDEX_rs2_data;
		end
	end
endmodule


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

module Cycle_8_mult(
    input               clk,
    input               rst_n,
    input               mem_stall,  //in case of cache miss, long stall, hold result temporarily
    input               start,      //start stays up, as multiply introduce a mult stall.
    input       [31:0]  data_in_1,
    input       [31:0]  data_in_2,
    output              ready,
    output reg  [31:0]  data_out
);

reg [7:0]   progress;
assign ready=progress[7];

reg [3 :0]  mult_in2;
reg [31:0]  shift_res;

always@(*)begin
    if      (start && !(|progress))  mult_in2=data_in_2[3    :0];
    else if (progress[0])            mult_in2=data_in_2[7    :4];
    else if (progress[1])            mult_in2=data_in_2[11   :8];
    else if (progress[2])            mult_in2=data_in_2[15   :12];
    else if (progress[3])            mult_in2=data_in_2[19   :16];
    else if (progress[4])            mult_in2=data_in_2[23   :20];
    else if (progress[5])            mult_in2=data_in_2[27   :24];
    else                                mult_in2=data_in_2[31   :28];
end
wire[31:0]mult_res=data_in_1*mult_in2;

always@(*)begin
    if      (start && !(|progress))  shift_res=mult_res;
    else if (progress[0])            shift_res=mult_res<<4;
    else if (progress[1])            shift_res=mult_res<<8;
    else if (progress[2])            shift_res=mult_res<<12;
    else if (progress[3])            shift_res=mult_res<<16;
    else if (progress[4])            shift_res=mult_res<<20;
    else if (progress[5])            shift_res=mult_res<<24;
    else                             shift_res=mult_res<<28;
end
always@(posedge clk)begin
    if (!(mem_stall && ready))begin
        if      (start && !(|progress))         data_out<=shift_res;
        else if (start || (|progress[6:0]))     data_out<=data_out+shift_res;
    end    
end
always@(posedge clk or negedge rst_n)begin
    if (!rst_n)                                 progress<=0;
    else if (!(mem_stall && ready))begin
        if (start && !(|progress))              progress<=1;
        else                                    progress<=progress<<1;
    end    
end
endmodule