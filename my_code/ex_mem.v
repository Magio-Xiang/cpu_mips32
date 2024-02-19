`include "defines.v"

module ex_mem (
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus] ex_wd,
    input wire[`RegBus] ex_wdata,
    input wire ex_wreg,

    output reg[`RegAddrBus] mem_wd,
    output reg[`RegBus] mem_wdata,
    output reg mem_wreg
);
    always @(posedge clk ) begin
        if (rst==`RstEnable) begin
            mem_wd<=`NOPRegAddr;
            mem_wdata<=`ZeroWord;
            mem_wreg<=`WriteDisable;
        end else begin
            mem_wd<=ex_wd;
            mem_wdata<=ex_wdata;
            mem_wreg<=ex_wreg;
        end
    end




endmodule