`include "defines.v"

module id (
    input wire rst,
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,

    input wire[`RegBus] reg1_data_i,
    input wire[`RegBus] reg2_data_i,

    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_wd_i,
    input wire mem_wreg_i,
    
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_wd_i,
    input wire ex_wreg_i,

    input wire is_in_delayslot_i,

    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`RegAddrBus] reg1_addr_o,
    output reg[`RegAddrBus] reg2_addr_o,

    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] reg1_o,
    output reg[`RegBus] reg2_o,
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,

    output wire stallreq,

    output reg branch_flag_o,
    output reg[`RegBus] branch_target_address_o,
    output reg is_in_delayslot_o,
    output reg[`RegBus] link_addr_o,
    output reg next_inst_in_delayslot_o

);

wire[5:0] op = inst_i[31:26];
wire[4:0] op2= inst_i[10:6];
wire[5:0] op3= inst_i[5:0];
wire[4:0] op4= inst_i[20:16];
wire[`RegBus] pc_plus_8;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_sll2_signedext;

reg[`RegBus]	imm;
reg instvalid;


assign stallreq = `NoStop;
assign pc_plus_8 = pc_i + 8;
assign pc_plus_4 = pc_i + 4;
assign imm_sll2_signedext = {{14{inst_i[15]}},inst_i[15:0],2'b00};


always @(*) begin
    if (rst == `RstEnable) begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= `NOPRegAddr;
        wreg_o <= `WriteDisable;
        instvalid <=`InstValid;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        imm <= 32'h0;
        link_addr_o<=`ZeroWord;
        branch_target_address_o<=`ZeroWord;
        branch_flag_o<=`NotBranch;
        next_inst_in_delayslot_o<=`NotInDelaySlot;
    end
    else begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= inst_i[15:11];
        wreg_o <= `WriteDisable;
        instvalid <=`InstInvalid;
        reg1_addr_o <= inst_i[25:21];
        reg2_addr_o <= inst_i[20:16];
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        imm <= 32'h0;
        link_addr_o<=`ZeroWord;
        branch_target_address_o<=`ZeroWord;
        branch_flag_o<=`NotBranch;
        next_inst_in_delayslot_o<=`NotInDelaySlot;
        //default rd<=rs*rt
        case (op)
            `EXE_SPECIAL_INST:begin
                case (op2)
                    5'b00000:begin
                        case (op3)
                            `EXE_OR:begin
                                aluop_o<=`EXE_OR_OP;
                                alusel_o<=`EXE_RES_LOGIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_AND:begin
                                aluop_o<=`EXE_AND_OP;
                                alusel_o<=`EXE_RES_LOGIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end 
                            `EXE_XOR:begin
                                aluop_o<=`EXE_XOR_OP;
                                alusel_o<=`EXE_RES_LOGIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_NOR:begin
                                aluop_o<=`EXE_NOR_OP;
                                alusel_o<=`EXE_RES_LOGIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SLLV:begin
                                aluop_o<=`EXE_SLL_OP;
                                alusel_o<=`EXE_RES_SHIFT;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SRLV:begin
                                aluop_o<=`EXE_SRL_OP;
                                alusel_o<=`EXE_RES_SHIFT;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SRAV:begin
                                aluop_o<=`EXE_SRA_OP;
                                alusel_o<=`EXE_RES_SHIFT;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SYNC:begin
                                aluop_o<=`EXE_NOP_OP;
                                alusel_o<=`EXE_RES_NOP;
                                reg1_read_o<=`ReadDisable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_MOVZ:begin
                                aluop_o<=`EXE_MOVZ_OP;
                                alusel_o<=`EXE_RES_MOVE;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                if (reg2_o==`ZeroWord) begin
                                    wreg_o<=`WriteEnable;
                                end else begin
                                    wreg_o<=`WriteDisable;
                                end
                                instvalid<=`InstValid;
                            end
                            `EXE_MOVN:begin
                                aluop_o<=`EXE_MOVN_OP;
                                alusel_o<=`EXE_RES_MOVE;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                if (reg2_o !=`ZeroWord) begin
                                    wreg_o<=`WriteEnable;
                                end else begin
                                    wreg_o<=`WriteDisable;
                                end
                                instvalid<=`InstValid;
                            end
                            `EXE_MFHI:begin
                                aluop_o<=`EXE_MFHI_OP;
                                alusel_o<=`EXE_RES_MOVE;
                                reg1_read_o<=`ReadDisable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_MTHI:begin
                                aluop_o<=`EXE_MTHI_OP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_MFLO:begin
                                aluop_o<=`EXE_MFLO_OP;
                                alusel_o<=`EXE_RES_MOVE;
                                reg1_read_o<=`ReadDisable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_MTLO:begin
                                aluop_o<=`EXE_MTLO_OP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_ADD:begin
                                aluop_o<=`EXE_ADD_OP;
                                alusel_o<=`EXE_RES_ARITHMETIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_ADDU:begin
                                aluop_o<=`EXE_ADDU_OP;
                                alusel_o<=`EXE_RES_ARITHMETIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SUB:begin
                                aluop_o<=`EXE_SUB_OP;
                                alusel_o<=`EXE_RES_ARITHMETIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SUBU:begin
                                aluop_o<=`EXE_SUBU_OP;
                                alusel_o<=`EXE_RES_ARITHMETIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SLT:begin
                                aluop_o<=`EXE_SLT_OP;
                                alusel_o<=`EXE_RES_ARITHMETIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_SLTU:begin
                                aluop_o<=`EXE_SLTU_OP;
                                alusel_o<=`EXE_RES_ARITHMETIC;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                            end
                            `EXE_MULT:begin
                                aluop_o<=`EXE_MULT_OP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_MULTU:begin
                                aluop_o<=`EXE_MULTU_OP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_DIV:begin
                                aluop_o<=`EXE_DIV_OP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_DIVU:begin
                                aluop_o<=`EXE_DIVU_OP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadEnable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                            end
                            `EXE_JR:begin
                                aluop_o<=`EXE_JR_OP;
                                alusel_o<=`EXE_RES_NOP;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteDisable;
                                instvalid<=`InstValid;
                                link_addr_o<=`ZeroWord;
                                branch_target_address_o<=reg1_o;
                                branch_flag_o<=`Branch;
                                next_inst_in_delayslot_o<=`InDelaySlot;
                            end
                            `EXE_JALR:begin
                                aluop_o<=`EXE_JALR_OP;
                                alusel_o<=`EXE_RES_JUMP_BRANCH;
                                reg1_read_o<=`ReadEnable;
                                reg2_read_o<=`ReadDisable;
                                wreg_o<=`WriteEnable;
                                instvalid<=`InstValid;
                                link_addr_o<=pc_plus_8;
                                branch_target_address_o<=reg1_o;
                                branch_flag_o<=`Branch;
                                next_inst_in_delayslot_o<=`InDelaySlot;
                            end
                            default:begin
                            end 
                        endcase
                    end 
                    default:begin
                        
                    end 
                endcase
            end
            `EXE_SPECIAL2_INST:begin
                case (op3)
                    `EXE_CLZ:begin
                        aluop_o<=`EXE_CLZ_OP;
                        alusel_o<=`EXE_RES_ARITHMETIC;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteEnable;
                        instvalid<=`InstValid;
                    end 
                    `EXE_CLO:begin
                        aluop_o<=`EXE_CLO_OP;
                        alusel_o<=`EXE_RES_ARITHMETIC;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteEnable;
                        instvalid<=`InstValid;
                    end
                    `EXE_MUL:begin
                        aluop_o<=`EXE_MUL_OP;
                        alusel_o<=`EXE_RES_MUL;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteEnable;
                        instvalid<=`InstValid;
                    end
                    `EXE_MADD:begin
                        aluop_o<=`EXE_MADD_OP;
                        alusel_o<=`EXE_RES_MUL;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_MADDU:begin
                        aluop_o<=`EXE_MADDU_OP;
                        alusel_o<=`EXE_RES_MUL;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_MSUB:begin
                        aluop_o<=`EXE_MSUB_OP;
                        alusel_o<=`EXE_RES_MUL;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_MSUBU:begin
                        aluop_o<=`EXE_MSUBU_OP;
                        alusel_o<=`EXE_RES_MUL;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    default:begin
                        
                    end 
                endcase
            end
            `EXE_ORI: begin
                wreg_o <= `WriteEnable;
                aluop_o<= `EXE_OR_OP;
                alusel_o<=`EXE_RES_LOGIC;
                reg1_read_o<=1'b1;
                reg2_read_o<=1'b0;
                imm<={16'h0,inst_i[15:0]};
                wd_o<=inst_i[20:16];
                instvalid<=`InstValid;
            end
            `EXE_ANDI:begin
                wreg_o <= `WriteEnable;
                aluop_o<= `EXE_AND_OP;
                alusel_o<=`EXE_RES_LOGIC;
                reg1_read_o<=1'b1;
                reg2_read_o<=1'b0;
                imm<={16'h0,inst_i[15:0]};
                wd_o<=inst_i[20:16];
                instvalid<=`InstValid;
            end
            `EXE_XORI:begin
                wreg_o <= `WriteEnable;
                aluop_o<= `EXE_XOR_OP;
                alusel_o<=`EXE_RES_LOGIC;
                reg1_read_o<=1'b1;
                reg2_read_o<=1'b0;
                imm<={16'h0,inst_i[15:0]};
                wd_o<=inst_i[20:16];
                instvalid<=`InstValid;
            end
            `EXE_LUI:begin
                wreg_o <= `WriteEnable;
                aluop_o<= `EXE_OR_OP;
                alusel_o<=`EXE_RES_LOGIC;
                reg1_read_o<=1'b1;
                reg2_read_o<=1'b0;
                imm<={inst_i[15:0],16'h0};
                wd_o<=inst_i[20:16];
                instvalid<=`InstValid;
            end
            `EXE_PREF:begin
                aluop_o<=`EXE_NOP_OP;
                alusel_o<=`EXE_RES_NOP;
                reg1_read_o<=`ReadDisable;
                reg2_read_o<=`ReadDisable;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
            end
            `EXE_ADDI:begin
                aluop_o<=`EXE_ADDI_OP;
                alusel_o<=`EXE_RES_ARITHMETIC;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                imm<={{16{inst_i[15]}},inst_i[15:0]};
                wd_o<=inst_i[20:16];
                wreg_o<=`WriteEnable;
                instvalid<=`InstValid;
            end
            `EXE_ADDIU:begin
                aluop_o<=`EXE_ADDIU_OP;
                alusel_o<=`EXE_RES_ARITHMETIC;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                imm<={{16{inst_i[15]}},inst_i[15:0]};
                wd_o<=inst_i[20:16];
                wreg_o<=`WriteEnable;
                instvalid<=`InstValid;
            end
            `EXE_SLTI:begin
                aluop_o<=`EXE_SLT_OP;
                alusel_o<=`EXE_RES_ARITHMETIC;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                imm<={{16{inst_i[15]}},inst_i[15:0]};
                wd_o<=inst_i[20:16];
                wreg_o<=`WriteEnable;
                instvalid<=`InstValid;
            end
            `EXE_SLTIU:begin
                aluop_o<=`EXE_SLTU_OP;
                alusel_o<=`EXE_RES_ARITHMETIC;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                imm<={{16{inst_i[15]}},inst_i[15:0]};
                wd_o<=inst_i[20:16];
                wreg_o<=`WriteEnable;
                instvalid<=`InstValid;
            end
            `EXE_J:begin
                aluop_o<=`EXE_J_OP;
                alusel_o<=`EXE_RES_NOP;
                reg1_read_o<=`ReadDisable;
                reg2_read_o<=`ReadDisable;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
                link_addr_o<=`ZeroWord;
                branch_target_address_o<={pc_plus_4[31:28],inst_i[25:0],2'b00};
                branch_flag_o<=`Branch;
                next_inst_in_delayslot_o<=`InDelaySlot;
            end
            `EXE_JAL:begin
                aluop_o<=`EXE_JAL_OP;
                alusel_o<=`EXE_RES_JUMP_BRANCH;
                reg1_read_o<=`ReadDisable;
                reg2_read_o<=`ReadDisable;
                wreg_o<=`WriteEnable;
                wd_o<=5'b11111;
                instvalid<=`InstValid;
                link_addr_o<=pc_plus_8;
                branch_target_address_o<={pc_plus_4[31:28],inst_i[25:0],2'b00};
                branch_flag_o<=`Branch;
                next_inst_in_delayslot_o<=`InDelaySlot;
            end
            `EXE_BEQ:begin
                aluop_o<=`EXE_BEQ_OP;
                alusel_o<=`EXE_RES_NOP;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
                link_addr_o<=`ZeroWord;
                if (reg1_o==reg2_o) begin
                    branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                    branch_flag_o<=`Branch;
                    next_inst_in_delayslot_o<=`InDelaySlot;
                end
            end
            `EXE_BGTZ:begin
                aluop_o<=`EXE_BGTZ_OP;
                alusel_o<=`EXE_RES_NOP;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
                link_addr_o<=`ZeroWord;
                if ((reg1_o[31]==1'b0 )&&(reg1_o!=`ZeroWord) ) begin
                    branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                    branch_flag_o<=`Branch;
                    next_inst_in_delayslot_o<=`InDelaySlot;
                end
            end
            `EXE_BLEZ:begin
                aluop_o<=`EXE_BLEZ_OP;
                alusel_o<=`EXE_RES_NOP;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
                link_addr_o<=`ZeroWord;
                if ((reg1_o[31]==1'b1 )||(reg1_o==`ZeroWord) ) begin
                    branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                    branch_flag_o<=`Branch;
                    next_inst_in_delayslot_o<=`InDelaySlot;
                end
            end
            `EXE_BNE:begin
                aluop_o<=`EXE_BNE_OP;
                alusel_o<=`EXE_RES_NOP;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
                link_addr_o<=`ZeroWord;
                if (reg1_o!=reg2_o) begin
                    branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                    branch_flag_o<=`Branch;
                    next_inst_in_delayslot_o<=`InDelaySlot;
                end
            end
            `EXE_REGIMM_INST:begin
                case (op4)
                    `EXE_BLTZ:begin
                        aluop_o<=`EXE_BLTZ_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                        link_addr_o<=`ZeroWord;
                        if (reg1_o[31]==1'b1 ) begin
                            branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                            branch_flag_o<=`Branch;
                            next_inst_in_delayslot_o<=`InDelaySlot;
                        end
                    end
                    `EXE_BLTZAL:begin
                        aluop_o<=`EXE_BLTZAL_OP;
                        alusel_o<=`EXE_RES_JUMP_BRANCH;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteEnable;
                        wd_o<=5'b11111;
                        instvalid<=`InstValid;
                        link_addr_o<=pc_plus_8;
                        if (reg1_o[31]==1'b1 ) begin
                            branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                            branch_flag_o<=`Branch;
                            next_inst_in_delayslot_o<=`InDelaySlot;
                        end
                    end
                    `EXE_BGEZ:begin
                        aluop_o<=`EXE_BGEZ_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                        link_addr_o<=`ZeroWord;
                        if (reg1_o[31]==1'b0 ) begin
                            branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                            branch_flag_o<=`Branch;
                            next_inst_in_delayslot_o<=`InDelaySlot;
                        end
                    end
                    `EXE_BGEZAL:begin
                        aluop_o<=`EXE_BGEZAL_OP;
                        alusel_o<=`EXE_RES_JUMP_BRANCH;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteEnable;
                        wd_o<=5'b11111;
                        instvalid<=`InstValid;
                        link_addr_o<=pc_plus_8;
                        if (reg1_o[31]==1'b0 ) begin
                            branch_target_address_o<=imm_sll2_signedext+pc_plus_4;
                            branch_flag_o<=`Branch;
                            next_inst_in_delayslot_o<=`InDelaySlot;
                        end
                    end 
                    default:begin
                      
                    end 
                endcase
            end 
            default:begin              
            end 
        endcase

        if(inst_i[31:21]==11'b00000000000)
        begin
            case (op3)
                `EXE_SLL:begin
                    aluop_o<=`EXE_SLL_OP;
                    alusel_o<=`EXE_RES_SHIFT;
                    reg1_read_o<=`ReadDisable;
                    reg2_read_o<=`ReadEnable;
                    wreg_o<=`WriteEnable;
                    imm[4:0]<=inst_i[10:6];
                    instvalid<=`InstValid;
                end 
                `EXE_SRL:begin
                    aluop_o<=`EXE_SRL_OP;
                    alusel_o<=`EXE_RES_SHIFT;
                    reg1_read_o<=`ReadDisable;
                    reg2_read_o<=`ReadEnable;
                    wreg_o<=`WriteEnable;
                    imm[4:0]<=inst_i[10:6];
                    instvalid<=`InstValid;
                end
                `EXE_SRA:begin
                    aluop_o<=`EXE_SRA_OP;
                    alusel_o<=`EXE_RES_SHIFT;
                    reg1_read_o<=`ReadDisable;
                    reg2_read_o<=`ReadEnable;
                    wreg_o<=`WriteEnable;
                    imm[4:0]<=inst_i[10:6];
                    instvalid<=`InstValid;
                end
                default:begin
                    
                end 
            endcase    
        end
    end
end

always @(*) begin
    if(rst==`RstEnable) begin
        reg1_o<=`ZeroWord;
    end else if ((reg1_read_o==`ReadEnable)&&(ex_wreg_i==`WriteEnable)&&(reg1_addr_o==ex_wd_i)) begin
        reg1_o<=ex_wdata_i;
    end else if ((reg1_read_o==`ReadEnable)&&(mem_wreg_i==`WriteEnable)&&(reg1_addr_o==mem_wd_i)) begin
        reg1_o<=mem_wdata_i;
    end else if (reg1_read_o==1'b1) begin
        reg1_o<=reg1_data_i;
    end else if (reg1_read_o ==1'b0) begin
        reg1_o<=imm;
    end else begin
        reg1_o<=`ZeroWord;
    end
end

always @(*) begin
    if(rst==`RstEnable) begin
        reg2_o<=`ZeroWord;
    end else if ((reg2_read_o==`ReadEnable)&&(ex_wreg_i==`WriteEnable)&&(reg2_addr_o==ex_wd_i)) begin
        reg2_o<=ex_wdata_i;
    end else if ((reg2_read_o==`ReadEnable)&&(mem_wreg_i==`WriteEnable)&&(reg2_addr_o==mem_wd_i)) begin
        reg2_o<=mem_wdata_i;
    end  else if (reg2_read_o==1'b1) begin
        reg2_o<=reg2_data_i;
    end else if (reg2_read_o ==1'b0) begin
        reg2_o<=imm;
    end else begin
        reg2_o<=`ZeroWord;
    end
end

always @(*) begin
    if (rst==`RstEnable) begin
        is_in_delayslot_o<= `NotInDelaySlot;
    end else begin
        is_in_delayslot_o<=is_in_delayslot_i;
    end
end


endmodule