module control(
    //input
	input           clk,
    input           rst_n,
    input   [6 :0]  IF_opcode,
	input   [31:0]  EX_alu_out,    //used for branch comparison result
    input           EX_forward_rs1,//for load_use detection
    input           EX_forward_rs2,//for load_use detection
	input           I_mem_stall,
	input           D_mem_stall,
    input           mult_stall,
	//output
	output          IF_ctrl_jal,
	
    output  reg     IFID_ctrl_rtype,
    output  reg     IFID_ctrl_itype,
    output  reg     IFID_ctrl_stype,
    output  reg     IFID_ctrl_btype,
    output  reg     IFID_ctrl_utype,
    output  reg     IFID_ctrl_jtype,
    output  reg     IFID_ctrl_alusrc,
    output  reg     IFID_ctrl_auipc,
    output  reg     IFID_ctrl_lui,
    output  reg     IFID_ctrl_jalr,
    output  reg     IFID_ctrl_regw,
    output  reg     IFID_ctrl_lw,
    output  reg     IFID_ctrl_sw,

    output  reg     IDEX_ctrl_rtype,
    output  reg     IDEX_ctrl_itype,
    output  reg     IDEX_ctrl_stype,
    output  reg     IDEX_ctrl_btype,
    output  reg     IDEX_ctrl_utype,
    output  reg     IDEX_ctrl_jtype,
    output  reg     IDEX_ctrl_alusrc,
    output  reg     IDEX_ctrl_auipc,
    output  reg     IDEX_ctrl_lui,
    output  		IDEX_ctrl_beq_taken,
    output  reg     IDEX_ctrl_jalr,
    output  reg     IDEX_ctrl_regw,
    output  reg     IDEX_ctrl_lw,
    output  reg     IDEX_ctrl_sw,

    output  reg     EXMEM_ctrl_regw,
    output  reg     EXMEM_ctrl_lw,
    output  reg     EXMEM_ctrl_sw,

    output  reg     MEMWB_ctrl_regw,
	
	output 			stall,
    output 			mem_stall,
	output 			loaduse_bubble
);
//OPcode
localparam OP_LUI   = 7'b0110111;
localparam OP_AUIPC = 7'b0110111;
localparam OP_JAL   = 7'b1101111;
localparam OP_JALR  = 7'b1100111;
localparam OP_BTYPE = 7'b1100011;
localparam OP_LW    = 7'b0000011;
localparam OP_SW    = 7'b0100011;
localparam OP_ITYPE = 7'b0010011;
localparam OP_RTYPE = 7'b0110011;
localparam OP_NOP   = 7'b0000000;
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


assign IF_ctrl_jal = (IF_opcode==OP_JAL) 
assign mem_stall=I_mem_stall || D_mem_stall;
assign stall=mem_stall||mult_stall;
assign loaduse_bubble=  EXMEM_ctrl_lw &&
                        (EX_forward_rs1 || EX_forward_rs2);
wire flush=IDEX_ctrl_beq_taken || IDEX_ctrl_jalr;
assign IDEX_ctrl_beq_taken=(IDEX_ctrl_btype && EX_alu_out[0]);
always@(posedge clk or negedege rst_n)begin
    if (!rst_n)begin
        IFID_ctrl_rtype     <=0;     
        IFID_ctrl_itype     <=0;     
        IFID_ctrl_stype     <=0;     
        IFID_ctrl_btype     <=0;     
        IFID_ctrl_utype     <=0;     
        IFID_ctrl_jtype     <=0;     
        IFID_ctrl_alusrc    <=0;         
        IFID_ctrl_auipc     <=0;     
        IFID_ctrl_lui       <=0;     
        IFID_ctrl_jalr      <=0;     
        IFID_ctrl_regw      <=0;     
        IFID_ctrl_lw        <=0;     
        IFID_ctrl_sw        <=0;     
    end
    else if (!stall && !loaduse_bubble)begin
		if (flush)begin
			IFID_ctrl_rtype     <=0;     
        	IFID_ctrl_itype     <=0;     
        	IFID_ctrl_stype     <=0;     
        	IFID_ctrl_btype     <=0;     
        	IFID_ctrl_utype     <=0;     
        	IFID_ctrl_jtype     <=0;     
        	IFID_ctrl_alusrc    <=0;         
        	IFID_ctrl_auipc     <=0;     
        	IFID_ctrl_lui       <=0;     
        	IFID_ctrl_jalr      <=0;     
        	IFID_ctrl_regw      <=0;     
        	IFID_ctrl_lw        <=0;     
        	IFID_ctrl_sw        <=0; 
		end
		else begin
        	IFID_ctrl_rtype     <=(IF_opcode==OP_RTYPE);     
        	IFID_ctrl_itype     <=(IF_opcode==OP_ITYPE || IF_opcode==OP_LW || IF_opcode==OP_JALR);     
        	IFID_ctrl_stype     <=(IF_opcode==OP_STYPE);     
        	IFID_ctrl_btype     <=(IF_opcode==OP_BTYPE);     
        	IFID_ctrl_utype     <=(IF_opcode==OP_LUI || IF_opcode==OP_AUIPC);     
        	IFID_ctrl_jtype     <=(IF_opcode==OP_JAL);     
        	IFID_ctrl_alusrc    <=(IF_opcode==OP_ITYPE || IF_opcode==OP_LW || IF_opcode==OP_JALR || IF_opcode==OP_SW || IF_opcode==OP_LUI || IF_opcode==OP_AUIPC);      //?? check input  if rs2 should be immediate 
        	IFID_ctrl_auipc     <=(IF_opcode==OP_AUIPC);     
        	IFID_ctrl_lui       <=(IF_opcode==OP_LUI);     
        	IFID_ctrl_jalr      <=(IF_opcode==OP_JALR);     
        	IFID_ctrl_regw      <=!(IF_opcode==NOP || IF_opcode==OP_BTYPE || IF_opcode==OP_SW);     
        	IFID_ctrl_lw        <=(IF_opcode==OP_LW);     
        	IFID_ctrl_sw        <=(IF_opcode==OP_SW);
		end     
    end
end
always@(posedge clk or negedge rst_n)begin
	if (!rst_n)begin
		IDEX_ctrl_rtype			<=0;
		IDEX_ctrl_itype			<=0;
		IDEX_ctrl_stype			<=0;
		IDEX_ctrl_btype			<=0;
		IDEX_ctrl_utype			<=0;
		IDEX_ctrl_jtype			<=0;
		IDEX_ctrl_alusrc		<=0;	
		IDEX_ctrl_auipc			<=0;
		IDEX_ctrl_lui			<=0;
		IDEX_ctrl_jalr			<=0;
		IDEX_ctrl_regw			<=0;
		IDEX_ctrl_lw			<=0;
		IDEX_ctrl_sw			<=0;
	end
	else if (!stall)begin
		if (flush || loaduse_bubble)begin
			IDEX_ctrl_rtype			<=0;
			IDEX_ctrl_itype			<=0;
			IDEX_ctrl_stype			<=0;
			IDEX_ctrl_btype			<=0;
			IDEX_ctrl_utype			<=0;
			IDEX_ctrl_jtype			<=0;
			IDEX_ctrl_alusrc		<=0;	
			IDEX_ctrl_auipc			<=0;
			IDEX_ctrl_lui			<=0;	
			IDEX_ctrl_jalr			<=0;
			IDEX_ctrl_regw			<=0;
			IDEX_ctrl_lw			<=0;
			IDEX_ctrl_sw			<=0;
		end
		else begin
			IDEX_ctrl_rtype			<=IFID_ctrl_rtype;
			IDEX_ctrl_itype			<=IFID_ctrl_itype;
			IDEX_ctrl_stype			<=IFID_ctrl_stype;
			IDEX_ctrl_btype			<=IFID_ctrl_btype;
			IDEX_ctrl_utype			<=IFID_ctrl_utype;
			IDEX_ctrl_jtype			<=IFID_ctrl_jtype;
			IDEX_ctrl_alusrc		<=IFID_ctrl_alusrc;	
			IDEX_ctrl_auipc			<=IFID_ctrl_auipc;
			IDEX_ctrl_lui			<=IFID_ctrl_lui;	
			IDEX_ctrl_jalr			<=IFID_ctrl_jalr;
			IDEX_ctrl_regw			<=IFID_ctrl_regw;
			IDEX_ctrl_lw			<=IFID_ctrl_lw;
			IDEX_ctrl_sw			<=IFID_ctrl_sw;
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if (!rst_n)begin
		EXMEM_ctrl_regw		<=0;
		EXMEM_ctrl_lw		<=0;
		EXMEM_ctrl_sw		<=0;
	end
	else if (!stall)begin
		EXMEM_ctrl_regw		<=IDEX_ctrl_regw;
		EXMEM_ctrl_lw		<=IDEX_ctrl_lw;
		EXMEM_ctrl_sw		<=IDEX_ctrl_sw;
	end
end
always@(posedge clk or negedge rst_n)begin
	if (!rst_n)begin
		MEMWB_ctrl_regw		<=0;
	end
	else if (!stall)begin
		MEMWB_ctrl_regw		<=EXMEM_ctrl_regw;
	end
end

endmodule