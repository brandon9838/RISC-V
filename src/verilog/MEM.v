module MEM_stage(
    input               clk,
    input               rst_n,
    input               stall,
    input               EXMEM_ctrl_lw,
    input               EXMEM_ctrl_sw,
    input       [4 :0]  EXMEM_regw_addr,
    input       [31:0]  EXMEM_regw_data, //also sw addr
    input       [31:0]  EXMEM_sw_data, // sw data
    input       [31:0]  DCACHE_rdata,
    output              DCACHE_ren,
    output              DCACHE_wen,
    output      [31:0]  DCACHE_addr,
    output      [31:0]  DCACHE_wdata,
    output reg  [31:0]  MEMWB_regw_data,
    output reg  [31:0]  MEMWB_regw_data_w,
    output reg  [4 :0]  MEMWB_regw_addr
);

    //====  MEMWB stage combinational/sequential circuit ==============================
	//D cache combinational circuit
	assign DCACHE_ren=EXMEM_ctrl_lw;
	assign DCACHE_wen=EXMEM_ctrl_sw;
	assign DCACHE_addr=EXMEM_regw_data;	//ALU output, lw/sw address is calculated by ALU
	assign DCACHE_wdata=EXMEM_sw_data;		//save rt when sw
	
    
    reg [4 :0] MEMWB_regw_addr_w;
	always@(*)begin //Combinational circuit
		MEMWB_regw_addr_w=EXMEM_regw_addr;
		MEMWB_regw_data_w=(EXMEM_ctrl_lw)? DCACHE_rdata:EXMEM_regw_data;
	end
    always@(posedge clk)begin
        if(!stall)begin
            MEMWB_regw_addr<=MEMWB_regw_addr_w;
            MEMWB_regw_data<=MEMWB_regw_data_w;
        end
    end
endmodule