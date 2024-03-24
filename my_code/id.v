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

    input wire[`AluOpBus] ex_aluop_i,

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
    output reg next_inst_in_delayslot_o,
    output wire[`RegBus] inst_o,
    output wire[31:0] excepttype_o,
    output wire[`RegBus] current_inst_address_o

);

wire[5:0] op = inst_i[31:26];
wire[4:0] op2= inst_i[10:6];
wire[5:0] op3= inst_i[5:0];
wire[4:0] op4= inst_i[20:16];
wire[`RegBus] pc_plus_8;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_sll2_signedext;
wire pre_inst_is_load;

reg[`RegBus]	imm;
reg instvalid;
reg stallreq_for_reg1_loadrelate;
reg stallreq_for_reg2_loadrelate;

reg excepttype_is_syscall;
reg excepttype_is_eret;

assign stallreq = stallreq_for_reg1_loadrelate||stallreq_for_reg2_loadrelate;
assign pc_plus_8 = pc_i + 8;
assign pc_plus_4 = pc_i + 4;
assign imm_sll2_signedext = {{14{inst_i[15]}},inst_i[15:0],2'b00};
assign inst_o=inst_i;
assign pre_inst_is_load =((ex_aluop_i==`EXE_LB_OP)||
                            (ex_aluop_i==`EXE_LBU_OP)||
                            (ex_aluop_i==`EXE_LH_OP)||
                            (ex_aluop_i==`EXE_LHU_OP)||
                            (ex_aluop_i==`EXE_LW_OP)||
                            (ex_aluop_i==`EXE_LWR_OP)||
                            (ex_aluop_i==`EXE_LWL_OP)||
                            (ex_aluop_i==`EXE_LL_OP)||
                            (ex_aluop_i==`EXE_SC_OP)) ? 1'b1:1'b0;
assign excepttype_o = {19'b0,excepttype_is_eret,2'b0,instvalid,excepttype_is_syscall,8'b0};
assign current_inst_address_o = pc_i;


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
        excepttype_is_eret=`False_v;
        excepttype_is_syscall=`False_v;
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
        excepttype_is_eret=`False_v;
        excepttype_is_syscall=`False_v;
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

                case (op3)
                    `EXE_TEQ:begin
                        aluop_o<=`EXE_TEQ_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TGE:begin
                        aluop_o<=`EXE_TGE_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TGEU:begin
                        aluop_o<=`EXE_TGEU_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TLT:begin
                        aluop_o<=`EXE_TLT_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TLTU:begin
                        aluop_o<=`EXE_TLTU_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TNE:begin
                        aluop_o<=`EXE_TNE_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadEnable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_SYSCALL:begin
                        aluop_o<=`EXE_SYSCALL_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadDisable;
                        reg2_read_o<=`ReadDisable;
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                        excepttype_is_syscall<=`True_v;
                    end 
                    default: begin
                      
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
                    `EXE_TEQI:begin
                        aluop_o<=`EXE_TEQI_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        imm<={{16{inst_i[15]}},inst_i[15:0]};
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TGEI:begin
                        aluop_o<=`EXE_TGEI_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        imm<={{16{inst_i[15]}},inst_i[15:0]};
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TGEIU:begin
                        aluop_o<=`EXE_TGEIU_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        imm<={{16{inst_i[15]}},inst_i[15:0]};
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TLTI:begin
                        aluop_o<=`EXE_TLTI_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        imm<={{16{inst_i[15]}},inst_i[15:0]};
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TLTIU:begin
                        aluop_o<=`EXE_TLTIU_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        imm<={{16{inst_i[15]}},inst_i[15:0]};
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    `EXE_TNEI:begin
                        aluop_o<=`EXE_TNEI_OP;
                        alusel_o<=`EXE_RES_NOP;
                        reg1_read_o<=`ReadEnable;
                        reg2_read_o<=`ReadDisable;
                        imm<={{16{inst_i[15]}},inst_i[15:0]};
                        wreg_o<=`WriteDisable;
                        instvalid<=`InstValid;
                    end
                    default:begin
                      
                    end 
                endcase
            end 
            `EXE_LB:begin
                aluop_o<=`EXE_LB_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                instvalid<=`InstValid;

            end
            `EXE_LBU:begin
                aluop_o<=`EXE_LBU_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                instvalid<=`InstValid;
            end
            `EXE_LH:begin
                aluop_o<=`EXE_LH_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                instvalid<=`InstValid;
            end
            `EXE_LHU:begin
                aluop_o<=`EXE_LHU_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                instvalid<=`InstValid;
            end
            `EXE_LW:begin
                aluop_o<=`EXE_LW_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                instvalid<=`InstValid;
            end
            `EXE_LWL:begin
                aluop_o<=`EXE_LWL_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_LWR:begin
                aluop_o<=`EXE_LWR_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteEnable;
                wd_o<=inst_i[20:16];
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_SB:begin
                aluop_o<=`EXE_SB_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteDisable;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_SH:begin
                aluop_o<=`EXE_SH_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteDisable;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_SW:begin
                aluop_o<=`EXE_SW_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteDisable;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_SWL:begin
                aluop_o<=`EXE_SWL_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteDisable;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_SWR:begin
                aluop_o<=`EXE_SWR_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                wreg_o<=`WriteDisable;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                instvalid<=`InstValid;
            end
            `EXE_LL:begin
                wreg_o<=`WriteEnable;
                aluop_o<=`EXE_LL_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadDisable;
                wd_o<=inst_i[20:16];
                instvalid<=`InstValid;
            end
            `EXE_SC:begin
                wreg_o<=`WriteEnable;
                aluop_o<=`EXE_SC_OP;
                alusel_o<=`EXE_RES_LOAD_STORE;
                reg1_read_o<=`ReadEnable;
                reg2_read_o<=`ReadEnable;
                wd_o<=inst_i[20:16];
                instvalid<=`InstValid;
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
        if (inst_i[31:21] == 11'b0100_0000_000 &&
            inst_i[10:0]  == 11'b0000_0000_000) begin
            aluop_o<=`EXE_MFC0_OP;
            alusel_o<=`EXE_RES_MOVE;
            reg1_read_o<=`ReadDisable;
            reg2_read_o<=`ReadDisable;
            wreg_o<=`WriteEnable;
            wd_o<=inst_i[20:16];
            instvalid<=`InstValid;
        end else if (inst_i[31:21] == 11'b0100_0000_100 &&
                    inst_i[10:0]  == 11'b0000_0000_000) begin
            aluop_o<=`EXE_MTC0_OP;
            alusel_o<=`EXE_RES_NOP;
            reg1_read_o<=`ReadEnable;
            reg1_addr_o<=inst_i[20:16];
            reg2_read_o<=`ReadDisable;
            wreg_o<=`WriteDisable;
            instvalid<=`InstValid;
        end
        if (inst_i == `EXE_ERET) begin
            aluop_o<=`EXE_ERET_OP;
            alusel_o<=`EXE_RES_NOP;
            reg1_read_o<=`ReadDisable;
            reg2_read_o<=`ReadDisable;
            wreg_o<=`WriteDisable;
            instvalid<=`InstValid;
            excepttype_is_eret<=`True_v;
        end
    end
end

always @(*) begin
    stallreq_for_reg1_loadrelate<=`NoStop;
    if(rst==`RstEnable) begin
        reg1_o<=`ZeroWord;
    end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_addr_o==1'b1) begin
        stallreq_for_reg1_loadrelate<=`Stop;
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
    stallreq_for_reg2_loadrelate<=`NoStop;
    if(rst==`RstEnable) begin
        reg2_o<=`ZeroWord;
    end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_addr_o==1'b1) begin
        stallreq_for_reg2_loadrelate<=`Stop;
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