`include "defines.v"

module cp0_reg (
    input wire rst,
    input wire clk,
    input wire[4:0] raddr_i,
    input wire[5:0] int_i,
    input wire we_i,
    input wire[4:0] waddr_i,
    input wire[`RegBus] data_i,
    input wire[31:0] excepttype_i,
    input wire[`RegBus] current_inst_addr_i,
    input wire is_in_delayslot_i,

    output reg[`RegBus] data_o,
    output reg[`RegBus] count_o,
    output reg[`RegBus] compare_o,
    output reg[`RegBus] status_o,
    output reg[`RegBus] cause_o,
    output reg[`RegBus] epc_o,
    output reg[`RegBus] config_o,
    output reg[`RegBus] prid_o,
    output reg timer_int_o

);

    always @(posedge clk ) begin
        if (rst == `RstEnable) begin
            count_o<=`ZeroWord;
            compare_o<=`ZeroWord;
            //CU字段4'b0001，表示CPO存在
            status_o<=32'b0001_0000_0000_0000_0000_0000_0000_0000;
            cause_o<=`ZeroWord;
            epc_o<=`ZeroWord;
            //BE字段为1，MSB
            config_o<=32'b0000_0000_0000_0000_1000_0000_0000_0000;
            //制作者X，8'h88，类型1，版本1.0
            prid_o<=32'b0001_0000_1000_1000_0000_0001_0000_0010;
            timer_int_o<=`InterruptNotAssert;
        end else begin
            count_o<=count_o+1;
            cause_o[15:10]<=int_i;
            if (compare_o!=`ZeroWord && compare_o==count_o) begin
                timer_int_o<=`InterruptAssert;
            end
            if (we_i == `WriteEnable) begin
                case (waddr_i)
                    `CP0_REG_COUNT:begin
                        count_o<=data_i;
                    end
                    `CP0_REG_COMPARE:begin
                        compare_o<=data_i;
                        timer_int_o<=`InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:begin
                        status_o<=data_i;
                    end
                    `CP0_REG_EPC:begin
                        epc_o<=data_i;
                    end
                    `CP0_REG_CAUSE:begin
                        //IP[1:0]
                        cause_o[9:8]<=data_i[9:8];
                        //IV
                        cause_o[23]<=data_i[23];
                        //WP
                        cause_o[22]<=data_i[22];
                    end 
                    default:begin      
                    end 
                endcase
            end

            case (excepttype_i)
                32'h0000001:begin
                   if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o<=current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                   end else begin
                        epc_o<=current_inst_addr_i ;
                        cause_o[31] <= 1'b0;
                   end 
                   status_o[1] <= 1'b1;
                   cause_o[6:2] <= 5'b00000;
                end
                32'h0000008:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31] <=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;                           
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01000;
                end 
                32'h000000a:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31] <=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;                           
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01010;
                end 
                32'h000000d:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31] <=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;                           
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01101;
                end 
                32'h000000c:begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31] <=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;                           
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b0110;
                end 
                32'h000000e:begin
                    status_o[1]<=1'b0;
                end  
                default:begin
                    
                end 
            endcase

        end
    end

    always @(*) begin
        if (rst == `RstEnable) begin
            data_o<=`ZeroWord;
        end else begin
            case (raddr_i)
               `CP0_REG_COUNT:begin
                   data_o<=count_o;
               end
               `CP0_REG_COMPARE:begin
                   data_o<=compare_o;
               end
               `CP0_REG_STATUS:begin
                   data_o<=status_o;
               end
               `CP0_REG_EPC:begin
                   data_o<=epc_o;
               end
               `CP0_REG_CAUSE:begin
                   data_o<=cause_o;
               end 
               `CP0_REG_CONFIG:begin
                    data_o<=config_o;
               end
               `CP0_REG_PrId:begin
                    data_o<=config_o;
               end
               default:begin      
               end 
            endcase
        end
    end

    
endmodule