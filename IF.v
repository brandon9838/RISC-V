module IF_stage#(
    parameter PC_START = 32'h000100b4
)(
    input               clk,
    input               rst_n,
    input       [31:0]  ICACHE_rdata,
    output  reg         ICACHE_ren,
    output  reg         ICACHE_wen,
    output  reg [31:0]  ICACHE_addr,
    output  reg [31:0]  ICACHE_wdata,
    output  reg [31:0]  IFID_inst,
    output  reg [31:0]  IFID_pc,
    input               loaduse_bubble,
	input               stall,
	input 				IF_ctrl_jal,
    input               IDEX_ctrl_beq_taken,
    input               IDEX_ctrl_jalr,
    input       [31:0]  IDEX_beq_addr,
    input       [31:0]  IDEX_jalr_addr
);

    reg         [31:0] pc_r,pc_w,pc4;
    reg         [31:0] IFID_pc_w;
    reg         [31:0] IFID_inst_w,
    reg signed  [31:0] jal_offset;
    reg signed  [31:0] jal_addr;
    

    //I cache combinational circuit
    always@(*)begin
        ICACHE_ren=1'b1;
        ICACHE_wen=1'b0;
        ICACHE_wdata=32'd0;
        ICACHE_addr=pc_r[31:2];
    end

    always@(*)begin
		jal_offset={{12{ICACHE_rdata[31]}},   // Sign extension (bits 31:20)
                        ICACHE_rdata[19:12],      // imm[19:12]
                        ICACHE_rdata[20],         // imm[11]
                        ICACHE_rdata[30:21],      // imm[10:1]
                        1'b0              // imm[0] is always 0
                      };
		jal_addr=$signed(pc_r)+$signed(jal_offset);
        pc4=pc_r+4;
    end

	always@(*)begin //Combinational circuit 
		if(stall || loaduse_bubble)	                pc_w=pc_r;
		else if (IDEX_ctrl_beq_taken)				pc_w=IDEX_beq_addr;
		else if (IDEX_ctrl_jalr)					pc_w=IDEX_jalr_addr;
		else if (IF_ctrl_jal)						pc_w=jal_addr; //keep io simple, does not pass this to 
		else 										pc_w=pc4;
	end                                 

	always@( posedge clk or negedge rst_n ) begin	//Sequential circuit
		if(!rst_n) pc_r<=PC_START;
		else 	pc_r<=pc_w;
	end

    always@(*)begin
		if (stall || loaduse_bubble)begin
			IFID_inst_w=IFID_inst;
			IFID_pc_w=IFID_pc;
		end //flush handled in control unit
		else begin
			IFID_inst_w=ICACHE_rdata;
			IFID_pc_w=pc_r;
		end
	end
		
	always@( posedge clk or negedge rst_n ) begin	//Sequential circuit
		if(!rst_n)begin
			IFID_inst<=32'h00000000;
			IFID_pc<=32'h00000000;
		end
		else begin
			IFID_inst<=IFID_inst_w;
			IFID_pc<=IFID_pc_w;
		end
	end
endmodule