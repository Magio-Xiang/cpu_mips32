`include "defines.v"

module mem_wb(

	input	wire										clk,
	input wire										rst,
	

	//来自访存阶段的信息	
	input wire[`RegAddrBus]       mem_wd,
	input wire                    mem_wreg,
	input wire[`RegBus]					 mem_wdata,

	input wire mem_whilo,
	input wire[`RegBus] mem_hi,
	input wire[`RegBus] mem_lo,

	input wire[5:0] stall,
	input wire mem_LLbit_we,
	input wire mem_LLbit_value,

	input wire              mem_cp0_reg_we,
    input wire[`RegBus]     mem_cp0_reg_data,
    input wire[`RegAddrBus] mem_cp0_reg_write_addr,

	//送到回写阶段的信息
	output reg[`RegAddrBus]      wb_wd,
	output reg                   wb_wreg,
	output reg[`RegBus]					 wb_wdata,

	output reg wb_whilo,
	output reg[`RegBus] wb_hi,
	output reg[`RegBus] wb_lo,
	output reg wb_LLbit_we,
	output reg wb_LLbit_value,

    output reg              wb_cp0_reg_we,
    output reg[`RegBus]     wb_cp0_reg_data,
    output reg[`RegAddrBus] wb_cp0_reg_write_addr	       
	

);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;	
			wb_whilo<=`WriteDisable;
			wb_hi<=`ZeroWord;
			wb_lo<=`ZeroWord;
			wb_LLbit_we<=`WriteDisable;
			wb_LLbit_value<=1'b0;
            wb_cp0_reg_we<=`WriteDisable;
            wb_cp0_reg_data<=`ZeroWord;
            wb_cp0_reg_write_addr<=5'b00000;
		end else if(stall[4]==`Stop && stall[5]==`NoStop) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;	
			wb_whilo<=`WriteDisable;
			wb_hi<=`ZeroWord;
			wb_lo<=`ZeroWord;
			wb_LLbit_we<=`WriteDisable;
			wb_LLbit_value<=1'b0;
			wb_cp0_reg_we<=`WriteDisable;
            wb_cp0_reg_data<=`ZeroWord;
            wb_cp0_reg_write_addr<=5'b00000;
		end else if(stall[4]==`NoStop) begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_whilo<=mem_whilo;
			wb_hi<=mem_hi;
			wb_lo<=mem_lo;
			wb_LLbit_we<=mem_LLbit_we;
			wb_LLbit_value<=mem_LLbit_value;
			wb_cp0_reg_we<=mem_cp0_reg_we;
            wb_cp0_reg_data<=mem_cp0_reg_data;
            wb_cp0_reg_write_addr<=mem_cp0_reg_write_addr;
		end    //if
	end      //always
			

endmodule