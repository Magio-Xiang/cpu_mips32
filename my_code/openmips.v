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

wire[`AluOpBus] id_aluop_o;
wire[`AluSelBus] id_alusel_o;
wire[`RegBus] id_reg1_o;
wire[`RegBus] id_reg2_o;
wire[`RegAddrBus] id_wd_o;
wire id_wreg_o;

//ex
wire[`AluOpBus] ex_aluop_i;
wire[`AluSelBus] ex_alusel_i;
wire[`RegBus] ex_reg1_i;
wire[`RegBus] ex_reg2_i;
wire[`RegAddrBus] ex_wd_i;
wire ex_wreg_i;
wire[`RegAddrBus] ex_wd_o;
wire[`RegBus] ex_wdata_o;
wire ex_wreg_o;

//mem
wire[`RegAddrBus] mem_wd_i;
wire[`RegBus] mem_wdata_i;
wire mem_wreg_i;
wire[`RegAddrBus] mem_wd_o;
wire[`RegBus] mem_wdata_o;
wire mem_wreg_o;

//wb
wire[`RegAddrBus] wb_wd_i;
wire[`RegBus] wb_wdata_i;
wire wb_wreg_i;

//regfile
wire[`RegBus] reg1_data;
wire[`RegBus] reg2_data;
wire[`RegAddrBus] reg1_addr;
wire[`RegAddrBus] reg2_addr;
wire reg1_read;
wire reg2_read;

assign rom_addr_o = pc;



endmodule