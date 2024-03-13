`include "defines.v"

module openmips (
    input wire rst,
    input wire clk,
    input wire[`InstBus] rom_data_i,
    output wire[`InstAddrBus] rom_addr_o,
    output wire rom_ce_o
);

//if
wire[`InstAddrBus] pc;

//id
wire[`InstAddrBus] id_pc_i;
wire[`InstBus] id_inst_i;
wire id_is_in_delayslot_i;

wire[`AluOpBus] id_aluop_o;
wire[`AluSelBus] id_alusel_o;
wire[`RegBus] id_reg1_o;
wire[`RegBus] id_reg2_o;
wire[`RegAddrBus] id_wd_o;
wire id_wreg_o;
wire id_is_in_delayslot_o;
wire[`RegBus] id_link_addr_o;
wire id_next_inst_in_delayslot_o;
wire[`RegBus] id_branch_target_address_o;
wire id_branch_flag_o;

//ex
wire[`AluOpBus] ex_aluop_i;
wire[`AluSelBus] ex_alusel_i;
wire[`RegBus] ex_reg1_i;
wire[`RegBus] ex_reg2_i;
wire[`RegAddrBus] ex_wd_i;
wire ex_wreg_i;
wire ex_is_in_delayslot_i;
wire[`RegBus] ex_link_address_i;

wire[`RegAddrBus] ex_wd_o;
wire[`RegBus] ex_wdata_o;
wire ex_wreg_o;
wire ex_whilo_o;
wire[`RegBus] ex_hi_o;
wire[`RegBus] ex_lo_o;

//mem
wire[`RegAddrBus] mem_wd_i;
wire[`RegBus] mem_wdata_i;
wire mem_wreg_i;
wire mem_whilo_i;
wire[`RegBus] mem_hi_i;
wire[`RegBus] mem_lo_i;

wire[`RegAddrBus] mem_wd_o;
wire[`RegBus] mem_wdata_o;
wire mem_wreg_o;
wire mem_whilo_o;
wire[`RegBus] mem_hi_o;
wire[`RegBus] mem_lo_o;

//wb
wire[`RegAddrBus] wb_wd_i;
wire[`RegBus] wb_wdata_i;
wire wb_wreg_i;
wire wb_whilo_i;
wire[`RegBus] wb_hi_i;
wire[`RegBus] wb_lo_i;

//regfile
wire[`RegBus] reg1_data;
wire[`RegBus] reg2_data;
wire[`RegAddrBus] reg1_addr;
wire[`RegAddrBus] reg2_addr;
wire reg1_read;
wire reg2_read;

//hi/lo reg
wire[`RegBus] hi_o;
wire[`RegBus] lo_o;

// stall
wire[5:0] stall;
wire stallreq_from_id;	
wire stallreq_from_ex;

//连接执行阶段与ex_reg模块，用于多周期的MADD、MADDU、MSUB、MSUBU指令
wire[`DoubleRegBus] hilo_temp_o;
wire[1:0] cnt_o;

wire[`DoubleRegBus] hilo_temp_i;
wire[1:0] cnt_i;

//div连接ex
wire signed_div;
wire[`RegBus] div_opdata1;
wire[`RegBus] div_opdata2;
wire div_start;
wire[`DoubleRegBus] div_result;
wire div_ready;

assign rom_addr_o = pc;

pc_reg u_pc_reg(
    .clk ( clk ),
    .rst ( rst ),
    .stall(stall),
    .branch_flag_i(id_branch_flag_o),
    .branch_target_address_i(id_branch_target_address_o),
    .pc  ( pc  ),
    .ce  ( rom_ce_o  )
);

if_id u_if_id(
    .clk     ( clk     ),
    .rst     ( rst     ),
    .if_pc   ( pc   ),
    .if_inst ( rom_data_i ),
    .stall   (stall),
    .id_pc   ( id_pc_i   ),
    .id_inst  ( id_inst_i  )
);

id u_id(
    .rst         ( rst         ),
    .pc_i        ( id_pc_i        ),
    .inst_i      ( id_inst_i      ),
    .reg1_data_i ( reg1_data ),
    .reg2_data_i ( reg2_data ),
    .mem_wdata_i ( mem_wdata_o ),
    .mem_wd_i    ( mem_wd_o    ),
    .mem_wreg_i  ( mem_wreg_o  ),
    .ex_wdata_i  ( ex_wdata_o  ),
    .ex_wd_i     ( ex_wd_o     ),
    .ex_wreg_i   ( ex_wreg_o   ),
    .is_in_delayslot_i(id_is_in_delayslot_i),

    .reg1_read_o ( reg1_read ),
    .reg2_read_o ( reg2_read ),
    .reg1_addr_o ( reg1_addr ),
    .reg2_addr_o ( reg2_addr ),
    .aluop_o     ( id_aluop_o     ),
    .alusel_o    ( id_alusel_o    ),
    .reg1_o      ( id_reg1_o      ),
    .reg2_o      ( id_reg2_o      ),
    .wd_o        ( id_wd_o        ),
    .wreg_o      ( id_wreg_o      ),
    .stallreq    ( stallreq_from_id),
    .branch_flag_o(id_branch_flag_o),
    .branch_target_address_o(id_branch_target_address_o),
    .is_in_delayslot_o(id_is_in_delayslot_o),
    .link_addr_o(id_link_addr_o),
    .next_inst_in_delayslot_o(id_next_inst_in_delayslot_o)
);

ctrl u_ctrl(
    .rst              ( rst              ),
    .stallreq_from_id ( stallreq_from_id ),
    .stallreq_from_ex ( stallreq_from_ex ),
    .stall            ( stall            )
);


id_ex u_id_ex(
    .clk       ( clk       ),
    .rst       ( rst       ),
    .id_aluop  ( id_aluop_o  ),
    .id_alusel ( id_alusel_o ),
    .id_reg1   ( id_reg1_o   ),
    .id_reg2   ( id_reg2_o   ),
    .id_wd     ( id_wd_o     ),
    .id_wreg   ( id_wreg_o   ),
    .stall     (stall        ),
    .id_link_address(id_link_addr_o),
    .id_is_in_delayslot(id_is_in_delayslot_o),
    .next_inst_in_delayslot_i(id_next_inst_in_delayslot_o),

    .ex_aluop  ( ex_aluop_i  ),
    .ex_alusel ( ex_alusel_i ),
    .ex_reg1   ( ex_reg1_i   ),
    .ex_reg2   ( ex_reg2_i   ),
    .ex_wd     ( ex_wd_i     ),
    .ex_wreg   ( ex_wreg_i   ),
    .ex_is_in_delayslot(ex_is_in_delayslot_i),
    .ex_link_address(ex_link_address_i),
    .is_in_delayslot_o(id_is_in_delayslot_i)

);

ex u_ex(
    .rst      ( rst      ),
    .alusel_i ( ex_alusel_i ),
    .aluop_i  ( ex_aluop_i  ),
    .reg1_i   ( ex_reg1_i   ),
    .reg2_i   ( ex_reg2_i   ),
    .wd_i     ( ex_wd_i     ),
    .wreg_i   ( ex_wreg_i   ),
    .hi_i        ( hi_o        ),
    .lo_i        ( lo_o        ),
    .mem_whilo_i ( mem_whilo_o ),
    .mem_hi_i    ( mem_hi_o    ),
    .mem_lo_i    ( mem_lo_o    ),
    .wb_whilo_i  ( wb_whilo_i  ),
    .wb_hi_i     ( wb_hi_i     ),
    .wb_lo_i     ( wb_lo_i     ),
    .hilo_temp_i (hilo_temp_i),
	.cnt_i       (cnt_i),
    .div_result_i  ( div_result  ),
    .div_ready_i   ( div_ready   ),
    .is_in_delayslot_i(ex_is_in_delayslot_i),
    .link_address_i(ex_link_address_i),


    .wd_o     ( ex_wd_o     ),
    .wreg_o   ( ex_wreg_o   ),
    .wdata_o  ( ex_wdata_o  ),
    .whilo_o     ( ex_whilo_o     ),
    .hi_o        ( ex_hi_o        ),
    .lo_o        ( ex_lo_o     ),
    .stallreq    ( stallreq_from_ex),
    .hilo_temp_o(hilo_temp_o),
	.cnt_o      (cnt_o),
    .signed_div_o  ( signed_div  ),
    .div_start_o   ( div_start   ),
    .div_opdata1_o ( div_opdata1 ),
    .div_opdata2_o  ( div_opdata2  )

);


ex_mem u_ex_mem(
    .clk       ( clk       ),
    .rst       ( rst       ),
    .ex_wd     ( ex_wd_o     ),
    .ex_wdata  ( ex_wdata_o  ),
    .ex_wreg   ( ex_wreg_o   ),
    .ex_whilo  ( ex_whilo_o  ),
    .ex_hi     ( ex_hi_o     ),
    .ex_lo     ( ex_lo_o     ),
    .stall     (stall        ),
    .hilo_i    (hilo_temp_o),
	.cnt_i     (cnt_o),	

    .mem_wd    ( mem_wd_i    ),
    .mem_wdata ( mem_wdata_i ),
    .mem_wreg  ( mem_wreg_i  ),
    .mem_whilo ( mem_whilo_i ),
    .mem_hi    ( mem_hi_i    ),
    .mem_lo    ( mem_lo_i    ),
    .hilo_o    (hilo_temp_i),
	.cnt_o     (cnt_i)
);

mem u_mem(
    .rst     ( rst     ),
    .wd_i    ( mem_wd_i    ),
    .wreg_i  ( mem_wreg_i  ),
    .wdata_i ( mem_wdata_i ),
    .whilo_i ( mem_whilo_i ),
    .hi_i    ( mem_hi_i    ),
    .lo_i    ( mem_lo_i    ),
    .wd_o    ( mem_wd_o    ),
    .wdata_o ( mem_wdata_o ),
    .wreg_o  ( mem_wreg_o  ),
    .whilo_o ( mem_whilo_o ),
    .hi_o    ( mem_hi_o    ),
    .lo_o    ( mem_lo_o    )
);

mem_wb u_mem_wb(
    .clk       ( clk       ),
    .rst       ( rst       ),
    .mem_wd    ( mem_wd_o    ),
    .mem_wreg  ( mem_wreg_o  ),
    .mem_wdata ( mem_wdata_o ),
    .mem_whilo ( mem_whilo_o ),
    .mem_hi    ( mem_hi_o    ),
    .mem_lo    ( mem_lo_o    ),
    .stall     (stall        ),
    .wb_wd     ( wb_wd_i     ),
    .wb_wreg   ( wb_wreg_i   ),
    .wb_wdata  ( wb_wdata_i  ),
    .wb_whilo  ( wb_whilo_i  ),
    .wb_hi     ( wb_hi_i     ),
    .wb_lo     ( wb_lo_i     )
);

regfile u_regfile(
    .clk    ( clk    ),
    .rst    ( rst    ),
    .we     ( wb_wreg_i     ),
    .waddr  ( wb_wd_i  ),
    .wdata  ( wb_wdata_i  ),
    .re1    ( reg1_read    ),
    .raddr1 ( reg1_addr ),
    .rdata1 ( reg1_data),
    .re2    ( reg2_read ),
    .raddr2 ( reg2_addr),
    .rdata2 ( reg2_data)
);

hilo_reg u_hilo_reg(
    .rst  ( rst  ),
    .clk  ( clk  ),
    .we   ( wb_whilo_i   ),
    .hi_i ( wb_hi_i ),
    .lo_i ( wb_lo_i ),
    .hi_o ( hi_o ),
    .lo_o  ( lo_o  )
);

div u_div(
    .rst          ( rst          ),
    .clk          ( clk          ),
    .signed_div_i ( signed_div ),
    .opdata1_i    ( div_opdata1    ),
    .opdata2_i    ( div_opdata2  ),
    .start_i      ( div_start  ),
    .annul_i      ( 1'b0    ),
    .result_o     ( div_result     ),
    .ready_o      ( div_ready     )
);

endmodule