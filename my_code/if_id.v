`include "defines.v"

module if_id (
    input wire clk,
    input wire rst,
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    input wire[5:0] stall,
    input wire flush,

    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
);
    always@(posedge clk )begin
        if (rst == `RstEnable) begin
            id_inst<=`ZeroWord;
            id_pc<=`ZeroWord;
        end else if (flush == 1'b1 ) begin
            id_inst<=`ZeroWord;
            id_pc<=`ZeroWord;
        end else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            id_inst<=`ZeroWord;
            id_pc<=`ZeroWord;
        end else if (stall[1]==`NoStop)
        begin
            id_inst<=if_inst;
            id_pc<=if_pc;
        end
    
    end
endmodule