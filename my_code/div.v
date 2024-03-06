`include "defines.v"

module div (
    input wire rst,
    input wire clk,
    input wire signed_div_i,
    input wire[`RegBus] opdata1_i,
    input wire[`RegBus] opdata2_i,
    input wire start_i,
    input wire annul_i,

    output reg[`DoubleRegBus] result_o,
    output reg ready_o
);
    wire[32:0] div_temp;
    reg[5:0] cnt;
    reg[64:0] dividend;
    reg[1:0] state;
    reg[31:0] divisor;
    reg[31:0] temp_op1;
    reg[31:0] temp_op2;

    
endmodule