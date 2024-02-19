`include "defines.v"

module id (
    input wire rst,
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,

    input wire[`RegBus] reg1_data_i,
    input wire[`RegBus] reg2_data_i,

    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`RegAddrBus] reg1_addr_o,
    output reg[`RegAddrBus] reg2_addr_o,

    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] reg1_o,
    output reg[`RegBus] reg2_o,
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o
);
    
    wire[5:0] op = inst_i[31:26];
    wire[4:0] op2= inst_i[10:6];
    wire[5:0] op3= inst_i[5:0];
    wire[4:0] op4= inst_i[20:16];

    reg[`RegBus]	imm;
    reg instvalid;

always @(*) begin
    if (rst == `RstEnable) begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= `NOPRegAddr;
        wreg_o <= `WriteDisable;
        instvalid <=`InstInvalid;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        imm <= 32'h0;
    end
    else begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= inst_i[20:16];
        wreg_o <= `WriteDisable;
        instvalid <=`InstInvalid;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        imm <= 32'h0;
    end
end


endmodule