
module ID_stage(
    input               clk,
    input               rst_n,
    input               stall,
    input               IFID_ctrl_itype,
    input               IFID_ctrl_stype,
    input               IFID_ctrl_btype,
    input               IFID_ctrl_utype,
    input               IFID_ctrl_jtype,
    input               IDEX_ctrl_regw, 
    input               EXMEM_ctrl_regw,
    input               MEMWB_ctrl_regw,
    input       [31:0]  IFID_inst,
    input       [31:0]  IFID_pc,
    input       [4 :0]  EXMEM_regw_addr,
    input       [4 :0]  MEMWB_regw_addr,
    input       [31:0]  MEMWB_regw_data,
    input       [31:0]  alu_out,
    output  reg [31:0]  IDEX_rs1_data,
    output  reg [31:0]  IDEX_rs2_data,
    output  reg [ 4:0]  IDEX_regw_addr,
    output  reg [31:0]  IDEX_pc,
    output  reg [31:0]  IDEX_imm,
    output  reg [ 2:0]  IDEX_func3
);
    genvar i;
    //IDEX stage
	reg [31:0] IDEX_rs1_data_w;
    reg [31:0] IDEX_rs2_data_w;
    reg [ 4:0] IDEX_regw_addr_w; //will be used when passed to wb stage, not in id stage
    reg [31:0] IDEX_pc_w;
    reg [ 2:0] IDEX_func3_w;

	//Register file
	reg [31:0]register_r[31:0],register_w[31:0];
	reg [4:0] rs1_addr, rs2_addr;
	reg [31:0]rs1_data, rs2_data;


    always@(*)begin	//Combinational circuit
		rs1_addr=IFID_inst[19:15];
		rs2_addr=IFID_inst[24:20];
		rs1_data=register_r[rs1_addr];
		rs2_data=register_r[rs2_addr];
	end
	
    generate
    always @(posedge clk)
        register_r[0]<=0;
    for (i=1;i<32;i=i+1) begin
        always @(posedge clk)
            if (MEMWB_regw_addr==i && MEMWB_ctrl_regw) 
                register_r[MEMWB_regw_addr]<=MEMWB_regw_data;
    end
    endgenerate	

//====  IDEX stage combinational/sequential circuit ==============================
    wire jalr_or_jal=(IFID_inst[6:0]==7'b1100111) && (IFID_inst[11:7]==3'b000); 
    wire EX_forward_rs1 =(IDEX_regw_addr==rs1_addr   && IDEX_ctrl_regw   && rs1_addr!=0);
    wire MEM_forward_rs1=(EXMEM_regw_addr==rs1_addr  && EXMEM_ctrl_regw  && rs1_addr!=0);
    wire WB_forward_rs1 =(MEMWB_regw_addr==rs1_addr  && MEMWB_ctrl_regw  && rs1_addr!=0);
	always@(posedge clk)begin //Rs1 combinational circuit(forwarding)
		if (!stall)begin
            if      (jalr)              IDEX_rs1_data   <=  IFID_pc;	
    		else if (EX_forward_rs1)	IDEX_rs1_data   <=  alu_out;
            else if (MEM_forward_rs1)   IDEX_rs1_data   <=  MEMWB_regw_data_w;
    														//cannot use EXMEM_regw_data because it could be a lw 
    		else if (WB_forward_rs1)	IDEX_rs1_data   <=  MEMWB_regw_data;
    		else 						IDEX_rs1_data   <=  rs1_data;
        end
	end

    wire EX_forward_rs2 =(IDEX_regw_addr==rs2_addr   && IDEX_reg_write   && rs2_addr!=0);
    wire MEM_forward_rs2=(EXMEM_regw_addr==rs2_addr  && EXMEM_reg_write  && rs2_addr!=0);
    wire WB_forward_rs2 =(MEMWB_regw_addr==rs2_addr  && MEMWB_reg_write  && rs2_addr!=0);
	always@(posedge clk)begin //Rs2 combinational circuit(forwarding)
		if (!stall)begin
            if      (jalr)              IDEX_rs2_data   <=  0;	
    		else if (EX_forward_rs2)	IDEX_rs2_data   <=  alu_out;
            else if (MEM_forward_rs2)   IDEX_rs2_data   <=  MEMWB_regw_data_w;
    														//cannot use EXMEM_regw_data because it could be a lw 
    		else if (WB_forward_rs2)	IDEX_rs2_data   <=  MEMWB_regw_data;
    		else 						IDEX_rs2_data   <=  rs2_data;
        end
	end

    always@(posedge clk)begin //IMM combinational circuit
		if (!stall)begin
    		if      (IFID_ctrl_itype)	IDEX_imm   <=  {{21{IFID_inst[31]}},IFID_inst[30:20]};
            else if (IFID_ctrl_stype)	IDEX_imm   <=  {{21{IFID_inst[31]}},IFID_inst[30:25],IFID_inst[11:7]};
            else if (IFID_ctrl_btype)	IDEX_imm   <=  {{20{IFID_inst[31]}},IFID_inst[7],IFID_inst[30:25],IFID_inst[11:8],1'b0};
            else if (IFID_ctrl_utype)	IDEX_imm   <=  {IFID_inst[31:12],12'd0};
            else if (IFID_ctrl_jtype)   IDEX_imm   <=  {IFID_inst[31],IFID_inst[19:12],IFID_inst[20],IFID_inst[30:21],1'd0};
            else                        IDEX_imm   <=  IFID_inst; //Rtype unused, store func7 for later use
        end
	end
	
	always@(*)begin //Combinational circuit
		if(stall)begin 
			IDEX_pc_w=IDEX_pc;
			IDEX_regw_addr_w=IDEX_regw_addr;
            IDEX_func3_w=IDEX_func3;
		end
		else begin
			IDEX_pc_w=IFID_pc;
            IDEX_regw_addr_w=IFID_inst[11:7];
            IDEX_func3_w=IFID_inst[14:12];
		end
	end
	
	always@( posedge clk or negedge rst_n ) begin	//Sequential circuit
		if(!rst_n)begin
			IDEX_pc<=0;
            IDEX_regw_addr<=0;
            IDEX_func3<=0;
		end
		else begin
			IDEX_pc<=IDEX_pc_w;
            IDEX_regw_addr<=IDEX_regw_addr_w;
            IDEX_func3<=IDEX_func3_w;
        end
	end
endmodule