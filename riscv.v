module riscv#(
    parameter PC_START = 32'h000100b4
)(
    input           clk,
    input           rst_n,
	output          ICACHE_ren,
	output          ICACHE_wen,
	output  [31:0]  ICACHE_addr,
	output  [31:0]  ICACHE_wdata,
	input           ICACHE_stall,
	input   [31:0]  ICACHE_rdata,
	output          DCACHE_ren,
	output          DCACHE_wen,
	output  [31:0]  DCACHE_addr,
	output  [31:0]  DCACHE_wdata,
	input           DCACHE_stall,
	input   [31:0]  DCACHE_rdata
);

wire    [31:0]  IFID_inst;
wire    [31:0]  IFID_pc;

wire    [31:0]  IDEX_rs1_data;
wire    [31:0]  IDEX_rs2_data;
wire    [ 4:0]  IDEX_regw_addr;
wire    [31:0]  IDEX_pc;
wire    [31:0]  IDEX_imm;
wire    [ 2:0]  IDEX_func3;
wire            EX_forward_rs1;
wire            EX_forward_rs2;

wire    [4 :0]  EXMEM_regw_addr;
wire    [31:0]  EXMEM_regw_data;
wire    [31:0]  EXMEM_sw_data;
wire    [31:0]  EX_alu_out;
wire    [31:0]  EX_branch_addr;
wire            mult_stall;

wire    [31:0]  MEMWB_regw_data;
wire    [31:0]  MEMWB_regw_data_w;
wire    [4 :0]  MEMWB_regw_addr;

wire            IF_ctrl_jal;
wire            IFID_ctrl_rtype;
wire            IFID_ctrl_itype;
wire            IFID_ctrl_stype;
wire            IFID_ctrl_btype;
wire            IFID_ctrl_utype;
wire            IFID_ctrl_jtype;
wire            IFID_ctrl_alusrc;
wire            IFID_ctrl_auipc;
wire            IFID_ctrl_lui;
wire            IFID_ctrl_jalr;
wire            IFID_ctrl_regw;
wire            IFID_ctrl_lw;
wire            IFID_ctrl_sw;
wire            IDEX_ctrl_rtype;
wire            IDEX_ctrl_itype;
wire            IDEX_ctrl_stype;
wire            IDEX_ctrl_btype;
wire            IDEX_ctrl_utype;
wire            IDEX_ctrl_jtype;
wire            IDEX_ctrl_alusrc;
wire            IDEX_ctrl_auipc;
wire            IDEX_ctrl_lui;
wire            IDEX_ctrl_beq_taken;
wire            IDEX_ctrl_jalr;
wire            IDEX_ctrl_regw;
wire            IDEX_ctrl_lw;
wire            IDEX_ctrl_sw;
wire            EXMEM_ctrl_regw;
wire            EXMEM_ctrl_lw;
wire            EXMEM_ctrl_sw;
wire            MEMWB_ctrl_regw;
wire            stall;
wire            mem_stall;
wire            loaduse_bubble;

IF_stage#(
    .PC_START(PC_START)
)(
    .clk                    (clk                ),    
    .rst_n                  (rst_n              ),    
    .ICACHE_rdata           (ICACHE_rdata       ),            
    .ICACHE_ren             (ICACHE_ren         ),        
    .ICACHE_wen             (ICACHE_wen         ),        
    .ICACHE_addr            (ICACHE_addr        ),            
    .ICACHE_wdata           (ICACHE_wdata       ),            
    .IFID_inst              (IFID_inst          ),        
    .IFID_pc                (IFID_pc            ),        
    .loaduse_bubble         (loaduse_bubble     ),            
	.stall                  (stall              ),    
	.IF_ctrl_jal            (IF_ctrl_jal        ),            
    .IDEX_ctrl_beq_taken    (IDEX_ctrl_beq_taken),                    
    .IDEX_ctrl_jalr         (IDEX_ctrl_jalr     ),            
    .IDEX_beq_addr          (IDEX_beq_addr      ),            
    .IDEX_jalr_addr         (IDEX_jalr_addr     )            
);

ID_stage u_id_stage(
    .clk                    (clk              ),
    .rst_n                  (rst_n            ),
    .stall                  (stall            ),
    .IFID_ctrl_itype        (IFID_ctrl_itype  ),            
    .IFID_ctrl_stype        (IFID_ctrl_stype  ),            
    .IFID_ctrl_btype        (IFID_ctrl_btype  ),            
    .IFID_ctrl_utype        (IFID_ctrl_utype  ),            
    .IFID_ctrl_jtype        (IFID_ctrl_jtype  ),            
    .IDEX_ctrl_regw,        (IDEX_ctrl_regw,  ),            
    .EXMEM_ctrl_regw        (EXMEM_ctrl_regw  ),            
    .MEMWB_ctrl_regw        (MEMWB_ctrl_regw  ),            
    .IFID_inst              (IFID_inst        ),    
    .IFID_pc                (IFID_pc          ),    
    .EXMEM_regw_addr        (EXMEM_regw_addr  ),            
    .EXMEM_regw_data_w      (EXMEM_regw_data_w),            
    .MEMWB_regw_addr        (MEMWB_regw_addr  ),            
    .MEMWB_regw_data_w      (MEMWB_regw_data_w),            
    .MEMWB_regw_data        (MEMWB_regw_data  ),            
    .IDEX_rs1_data          (IDEX_rs1_data    ),        
    .IDEX_rs2_data          (IDEX_rs2_data    ),        
    .IDEX_regw_addr         (IDEX_regw_addr   ),        
    .IDEX_pc                (IDEX_pc          ),    
    .IDEX_imm               (IDEX_imm         ),    
    .IDEX_func3             (IDEX_func3       ),    
    .EX_forward_rs1         (EX_forward_rs1   ),        
    .EX_forward_rs          (EX_forward_rs    )        
);

EX_stage u_ex_stage(
    .clk                     (clk             ),
    .rst_n                   (rst_n           ),    
    .mem_stall               (mem_stall       ),        
    .stall                   (stall           ),    
    .IDEX_ctrl_rtype         (IDEX_ctrl_rtype ),            
    .IDEX_ctrl_itype         (IDEX_ctrl_itype ),            
    .IDEX_ctrl_jalr          (IDEX_ctrl_jalr  ),            
    .IDEX_ctrl_auipc         (IDEX_ctrl_auipc ),            
    .IDEX_ctrl_lui           (IDEX_ctrl_lui   ),            
    .IDEX_ctrl_stype         (IDEX_ctrl_stype ),            
    .IDEX_ctrl_btype         (IDEX_ctrl_btype ),            
    .IDEX_ctrl_utype         (IDEX_ctrl_utype ),            
    .IDEX_ctrl_jtype         (IDEX_ctrl_jtype ),            
    .IDEX_ctrl_alusrc        (IDEX_ctrl_alusrc),                
    .IDEX_rs1_data           (IDEX_rs1_data   ),            
    .IDEX_rs2_data           (IDEX_rs2_data   ),            
    .IDEX_pc                 (IDEX_pc         ),    
    .IDEX_imm                (IDEX_imm        ),          
    .IDEX_func3              (IDEX_func3      ),        
    .EXMEM_regw_addr         (EXMEM_regw_addr ),            
    .EXMEM_regw_data         (EXMEM_regw_data ),             
    .EXMEM_sw_data           (EXMEM_sw_data   ),             
    .EX_alu_out              (EX_alu_out      ),             
    .EX_branch_addr          (EX_branch_addr  ),             
    .mult_stall              (mult_stall      )        
);

MEM_stage umem_stage(
    .clock                  (clock                 ),
    .rst_nclock             (rst_nclock            ),    
    .stallclock             (stallclock            ),    
    .EXMEM_ctrl_lwclock     (EXMEM_ctrl_lwclock    ),            
    .EXMEM_ctrl_swclock     (EXMEM_ctrl_swclock    ),            
    .EXMEM_regw_addrclock   (EXMEM_regw_addrclock  ),                
    .EXMEM_regw_dataclock   (EXMEM_regw_dataclock  ),                
    .EXMEM_sw_dataclock     (EXMEM_sw_dataclock    ),            
    .DCACHE_rdataclock      (DCACHE_rdataclock     ),            
    .DCACHE_renclock        (DCACHE_renclock       ),            
    .DCACHE_wenclock        (DCACHE_wenclock       ),            
    .DCACHE_addrclock       (DCACHE_addrclock      ),            
    .DCACHE_wdatclock       (DCACHE_wdatclock      ),            
    .MEMWB_regw_dataclock   (MEMWB_regw_dataclock  ),                
    .MEMWB_regw_data_wclock (MEMWB_regw_data_wclock),                
    .MEMWB_regw_addrclock   (MEMWB_regw_addrclock  )                
);

control u_sontrol(
	.clk                    (clk                    ),        
    .rst_n                  (rst_n                  ),      
    .IF_opcode              (IF_opcode              ),          
	.EX_alu_out             (EX_alu_out             ),             
    .EX_forward_rs1         (EX_forward_rs1         ),             
    .EX_forward_rs2         (EX_forward_rs2         ),             
	.I_mem_stall            (I_mem_stall            ),                
	.D_mem_stall            (D_mem_stall            ),                
    .mult_stall             (mult_stall             ),         
	.IF_ctrl_jal            (IF_ctrl_jal            ),                
    .IFID_ctrl_rtype        (IFID_ctrl_rtype        ),                    
    .IFID_ctrl_itype        (IFID_ctrl_itype        ),                    
    .IFID_ctrl_stype        (IFID_ctrl_stype        ),                    
    .IFID_ctrl_btype        (IFID_ctrl_btype        ),                    
    .IFID_ctrl_utype        (IFID_ctrl_utype        ),                    
    .IFID_ctrl_jtype        (IFID_ctrl_jtype        ),                    
    .IFID_ctrl_alusrc       (IFID_ctrl_alusrc       ),                   
    .IFID_ctrl_auipc        (IFID_ctrl_auipc        ),                    
    .IFID_ctrl_lui          (IFID_ctrl_lui          ),              
    .IFID_ctrl_jalr         (IFID_ctrl_jalr         ),             
    .IFID_ctrl_regw         (IFID_ctrl_regw         ),             
    .IFID_ctrl_lw           (IFID_ctrl_lw           ),               
    .IFID_ctrl_sw           (IFID_ctrl_sw           ),               
    .IDEX_ctrl_rtype        (IDEX_ctrl_rtype        ),                    
    .IDEX_ctrl_itype        (IDEX_ctrl_itype        ),                    
    .IDEX_ctrl_stype        (IDEX_ctrl_stype        ),                    
    .IDEX_ctrl_btype        (IDEX_ctrl_btype        ),                    
    .IDEX_ctrl_utype        (IDEX_ctrl_utype        ),                    
    .IDEX_ctrl_jtype        (IDEX_ctrl_jtype        ),                    
    .IDEX_ctrl_alusrc       (IDEX_ctrl_alusrc       ),                   
    .IDEX_ctrl_auipc        (IDEX_ctrl_auipc        ),                    
    .IDEX_ctrl_lui          (IDEX_ctrl_lui          ),              
    .IDEX_ctrl_beq_taken    (IDEX_ctrl_beq_taken    ),                        
    .IDEX_ctrl_jalr         (IDEX_ctrl_jalr         ),             
    .IDEX_ctrl_regw         (IDEX_ctrl_regw         ),             
    .IDEX_ctrl_lw           (IDEX_ctrl_lw           ),               
    .IDEX_ctrl_sw           (IDEX_ctrl_sw           ),               
    .EXMEM_ctrl_regw        (EXMEM_ctrl_regw        ),                    
    .EXMEM_ctrl_lw          (EXMEM_ctrl_lw          ),              
    .EXMEM_ctrl_sw          (EXMEM_ctrl_sw          ),              
    .MEMWB_ctrl_regw        (MEMWB_ctrl_regw        ),                    
	.stall                  (stall                  ),      
    .mem_stall              (mem_stall              ),          
	.loaduse_bubble         (loaduse_bubble         )             
    );
endmodule