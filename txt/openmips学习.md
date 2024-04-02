# OpenMIPS学习笔记

## Chapter3  
- 五级流水线：取指、译码、执行、访存、回写  
- 指令的5个阶段  
    1.取指令阶段 IF (使用PC(Program counter)寄存器组和存储器)   
        取指令(Instruction Fetch，IF)阶段是将一条指令从主存中取到指令寄存器的过程。程序计数器PC中的数值，用来指示当前指令在主存中的位置。当一条指令被取出后，PC中的数值将根据指令字长度而自动递增：若为单字长指令，则(PC)+1 -> PC；若为双字长指令，则(PC)+2 -> PC，依此类推。    

    2.指令译码阶段 ID (指令寄存器组):  
        取出指令后，计算机当即进入指令译码(Instruction Decode，ID)阶段。在指令译码阶段，指令译码器按照预约的指令格式，对取回的指令进行拆分和解释，识别区分出不一样的指令类别以及各类获取操做数的方法。在组合逻辑控制的计算机中，指令译码器对不一样的指令操做码产生不一样的控制电位，以造成不一样的微操做序列；在微程序控制的计算机中，指令译码器用指令操做码来找到执行该指令的微程序的入口，并今后入口开始执行。    

    3.执行指令阶段 EX (ALU算术逻辑单元)  
        在取指令和指令译码阶段以后，接着进入执行指令(Execute，EX)阶段。此阶段的任务是完成指令所规定的各类操做，具体实现指令的功能。为此，CPU的不一样部分被链接起来，以执行所需的操做。例如，若是要求完成一个加法运算，算术逻辑单元ALU将被链接到一组输入和一组输出，输入端提供须要相加的数值，输出端将含有最后的运算结果。    

    4.访存取数阶段 MEM   
        根据指令须要，有可能要访问主存，读取操做数，这样就进入了访存取数(Memory，MEM)阶段。    此阶段的任务是：根据指令地址码，获得操作数在主存中的地址，并从主存中读取该操做数用于运算。  

    5.结果写回阶段 WB (寄存器组)    
        做为最后一个阶段，结果写回(Writeback，WB)阶段把执行指令阶段的运行结果数据“写回”到某种存储形式：结果数据常常被写到CPU的内部寄存器中，以便被后续的指令快速地存取；在有些状况下，结果数据也可被写入相对较慢、但较廉价且容量较大的主存。许多指令还会改变程序状态字寄存器中标志位的状态，这些标志位标识着不一样的操做结果，可被用来影响程序的动做。  


## Chapter4 第一条ori指令实现
- ori指令格式
    - 31：26：指令码 ORI：6'b001101
    - 25：21：寄存器rs
    - 20：16：寄存器rt
    - 15：0：立即数 immediate
- ori指令作用：将16位立即数immediate无符号扩展到32位，与rs寄存器值进行逻辑或运算，再存到rt寄存器中  
- 无符号扩展：高位全部置零；符号扩展：高位全部置原数据最高位
- 状态机与流水线  
    - 状态机：寄存器的输出端和输入端存在环路
    - 流水线：寄存器之间有连接，没有上述环路
- RTL：Register Transfer Level 寄存器传输级
- PC模块
    - 给出指令地址
    - 接口 

    | 接口名                     | 宽度（bit） | Input/Output      | 作用             | 
    | -----------               | ----------- | -----------   | -----------      | 
    | rst                       | 1           |Input            |复位信号           | 
    | clk                       |1            | Input           |时钟信号           |
    | stall                     |6            | Input           |流水线暂停控制信号  |
    | branch_flag_i             |1            | Input           |是否发生转移           |
    | branch_target_address_i   |32           | Input           |转移到的目的地址  |      
    | pc                        |32           |Output           |要读取的指令地址    | 
    | ce                        |1            | Output          |指令存储器使能信号  | 
    - OpenMIPS按照字节寻址，一条指令对应4个字节，32位，每时钟周期PC自加4 

- IF/ID模块
    - 暂存取指阶段的指令及地址，在下一个时钟传到译指阶段
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            | Input           |时钟信号                    | 
    | if_pc       |32           |Input            |取指阶段得到的指令地址       | 
    | if_inst     |32           |Input            |取指阶段得到的指令           | 
    | stall       |6            | Input           |流水线暂停控制信号  |
    | id_pc       |32           |Output           |译码阶段的指令地址           | 
    | id_inst     |32           | Output          |译码阶段的指令               | 
    - 时钟缓冲电路 

- Regfile模块 
    - 实现32个32位通用寄存器，可以同时执行两个寄存器的读操作和一个寄存器的写操作 
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            |Input            |时钟信号                    | 
    | we          |1            |Input            |写使能                     |     
    | waddr       |5            |Input            |写寄存器地址                 | 
    | wdata       |32           |Input            |写入数据                    | 
    | re1         |1            |Input            |第一个寄存器读使能          | 
    | raddr1      | 5           |Input            |第一个寄存器读地址           | 
    | rdata1      |32           |Output           |第一个寄存器读输出数据        | 
    | re2         |1            |Input            |第二个寄存器读使能            | 
    | raddr2      |5            |Input            |第二个寄存器读地址            | 
    | rdata2      |32           |Output           |第二个寄存器读输出数据         | 
    - $0寄存器规定值只能为0，不能写入，读取时直接读0 
    - 读寄存器为组合逻辑，不需要时钟周期，立即读出 
    - 写寄存器为时序逻辑操作，需要一个时钟周期 

- ID模块 
    - 对指令进行译码，得到运算类型、子类型、源操作数1和2、要写入的寄存器信息 
    - 接口 

    | 接口名                         | 宽度（bit） | Input/Output      | 作用                      | 
    | -----------                   | ----------- | -----------   | -----------               | 
    | rst                           | 1           |Input            |复位信号                    | 
    | pc_i                          |32           |Input            |指令地址                    | 
    | inst_i                        |32           |Input            |指令                        | 
    | reg1_data_i                   |32           |Input            |第一个寄存器端口输入         | 
    | reg2_data_i                   |32           |Input            |第二个寄存器端口输入         | 
    | mem_wd_i                      |5            |Input            |访存阶段的指令要写入的目的寄存器地址        | 
    | mem_wreg_i                    |1            |Input            |访存阶段的指令是否要写入目的寄存器          | 
    | mem_wdata_i                   |32           |Input            |访存阶段的指令要写入目的寄存器的值          | 
    | ex_wd_i                       |5            |Input            |执行阶段的指令要写入的目的寄存器地址        | 
    | ex_wreg_i                     |1            |Input            |执行阶段的指令是否要写入目的寄存器          | 
    | ex_wdata_i                    |32           |Input            |执行阶段的指令要写入目的寄存器的值          | 
    | is_in_delayslot_i             |1            |Input            |当前处于译指阶段的指令是否位于延迟槽        | 
    | reg1_read_o                   |1            |Output           |第一个寄存器读使能          | 
    | reg2_read_o                   | 1           |Output           |第二个寄存器读使能           | 
    | reg1_addr_o                   |5            |Output           |第一个寄存器地址            | 
    | reg2_addr_o                   |5            |Output           |第二个寄存器地址            | 
    | aluop_o                       |8            |Output           |运算子类型                        | 
    | alusel_o                      |3            |Output           |运算类型           | 
    | reg1_o                        |32           |Output           |运算的源操作数1               | 
    | reg2_o                        |32           |Output           |运算的源操作数2             | 
    | wd_o                          |5            |Output           |输出结果要写入的目的寄存器地址   | 
    | wreg_o                        |1            |Output           |输出结果是否要写入目的寄存器       |  
    | stallreq                      |6            |Output           |译指阶段输出流水线暂停请求信号       | 
    |branch_flag_o                  |1            |Output           |是否发生转移               | 
    |branch_target_address_o        |32           |Output           |转移到的目的地址            | 
    |is_in_delayslot_o              |1            |Output           |当前处于译指阶段的指令是否位于延迟槽   | 
    |link_addr_o                    |32           |Output           |转移指令要保存的返回地址   |  
    |next_inst_in_delayslot_o       |1            |Output           |下一条进入译指阶段的指令是否位于延迟槽       | 
    |inst_o                         |32           |Output           |当前处于译码阶段的指令       | 
    - 源操作数可以来自寄存器或者立即数 
    - 运算类型由两个参数决定，alusel_o决定运算类型包括逻辑运算、移位运算、算术运算等，aluop_o决定子类型，对逻辑运算而言包括或与非异或等 

- ID/EX模块 
    - 暂存译指阶段的运算类型、源操作数、目的寄存器信息，在下一个时钟传到执行阶段 
    - 接口 

    | 接口名                      | 宽度（bit） | Input/Output      | 作用                      | 
    | -----------                | ----------- | -----------   | -----------               | 
    | rst                        | 1           |Input            |复位信号                    | 
    | clk                        |1            |Input            |时钟信号                    | 
    | id_aluop                   |8            |Input            |译码阶段的指令要进行的运算子类型                   | 
    | id_alusel                  |3            |Input            |译码阶段的指令要进行的运算类型                    | 
    | id_reg1                    |32           |Input            |译码阶段的指令要进行的运算源操作数1                   | 
    | id_reg2                    |32           |Input            |译码阶段的指令要进行的运算源操作数2                   | 
    | id_wd                      | 5           |Input            |译码阶段的指令要写入的目的寄存器地址                |
    | id_reg1                    |32           |Input            |译码阶段的指令要进行的运算源操作数1                   | 
    | id_reg2                    |32           |Input            |译码阶段的指令要进行的运算源操作数2                   | 
    | id_wd                      | 5           |Input            |译码阶段的指令要写入的目的寄存器地址                |  
    | stall                      |6            |Input            |流水线暂停控制信号  |
    | id_link_address            |32           |Input            |处于译指阶段的转移指令要保存的返回地址                   | 
    | id_is_in_delayslot         | 1           |Input            |处于译指阶段的指令是否位于延迟槽              |  
    | next_inst_in_delayslot_i   |1            |Input            |下一条进入译指阶段的指令是否位于延迟槽|
    | id_inst                    |32           |Input            |当前处于译码阶段的指令|
    | id_wreg                    |1            |Output           |译码阶段的指令是否写入目的寄存器            | 
    | ex_aluop                   |8            |Output           |执行阶段的指令要进行的运算子类型                  | 
    | ex_alusel                  |3            |Output           |执行阶段的指令要进行的运算类型                          | 
    | ex_reg1                    |32           |Output           |执行阶段的指令要进行的运算源操作数1          | 
    | ex_reg2                    |32           |Output           |执行阶段的指令要进行的运算源操作数2                     | 
    | ex_wd                      | 5           |Output           |执行阶段的指令要写入的目的寄存器地址              | 
    | ex_wreg                    |1            |Output           |执行阶段的指令是否写入目的寄存器       | 
    | ex_link_address            |32           |Output           |处于执行阶段的转移指令要保存的返回地址                   | 
    | ex_is_in_delayslot         | 5           |Output           |处于执行阶段的指令是否位于延迟槽              |  
    | is_in_delayslot_o          |1            |Output           |当前处于译指阶段的指令是否位于延迟槽|
    | ex_inst                    |32           |Output           |当前处于执行阶段的指令|
    - 时钟缓冲作用 

- EX模块 
    - 对源操作数1、2进行指定运算 
    - 接口 

    | 接口名                             | 宽度（bit） | Input/Output      | 作用                      | 
    | -----------                       | ----------- | -----------   | -----------               | 
    | rst                               | 1           |Input            |复位信号                    | 
    | alusel_i                          |3            |Input            |运算类型                    | 
    | aluop_i                           |8            |Input            |运算子类型                    | 
    | reg1_i                            |32           |Input            |源操作数1                   | 
    | reg2_i                            |32           |Input            |源操作数2                   | 
    | wd_i                              |5            |Input            |要写入的目的寄存器地址        | 
    | wreg_i                            | 1           |Input            |是否要写入目的寄存器          | 
    | hi_i                              |32           |Input            |HILO模块给出的HI寄存器的值           | 
    | lo_i                              |32           |Input            |HILO模块给出的LO寄存器的值            | 
    | mem_whilo_i                       |1            |Input            |访存阶段的指令是否要写入HI、LO寄存器                 | 
    | mem_hi_i                          |32           |Input            |访存阶段的指令要写入HI寄存器的值                    | 
    | mem_lo_i                          |32           |Input            |访存阶段的指令要写入LO寄存器的值                  | 
    | wb_whilo_i                        |1            |Input            |回写阶段的指令是否要写入HI、LO寄存器    | 
    | wb_hi_i                           |32           |Input            |回写阶段的指令要写入HI寄存器的值          | 
    | wb_lo_i                           |32           |Input            |回写阶段的指令要写入LO寄存器的值          | 
    | div_result_i                      |64           |Input            |除法运算结果          | 
    | div_ready_i                       |1            |Input            |除法运算是否结束          |
    | link_address_i                    |32           |Input            |处于执行阶段的转移指令要保存的返回地址      | 
    | is_in_delayslot_i                 | 1           |Input            |处于执行阶段的指令是否位于延迟槽              |  
    | inst_i                            |32           |Input            |当前处于执行阶段的指令          |
    | wd_o                              |32           |Output           |执行阶段的指令要写入的目的寄存器地址        | 
    | wreg_o                            |1            |Output           |执行阶段的指令是否要写入目的寄存器          | 
    | wdata_o                           |32           |Output           |执行阶段的指令要写入目的寄存器的值          | 
    | whilo_o                           |1            |Output           |执行阶段的指令是否要写入HI、LO寄存器        | 
    | hi_o                              |32           |Output           |执行阶段的指令要写入HI寄存器的值            | 
    | lo_o                              |32           |Output           |执行阶段的指令要写入LO寄存器的值            | 
    | stallreq                          |6            |Output           |执行阶段输出流水线暂停请求信号       |
    | signed_div_o                      |1            |Output           |是否为有符号除法          | 
    | div_opdata1_o                     |32           |Output           |被除数        | 
    | div_opdata2_o                     |32           |Output           |除数            | 
    | div_start_o                       |1            |Output           |是否开始除法运算            | 
    | aluop_o                           |8            |Output           |执行阶段要进行的运算子类型        | 
    | mem_addr_o                        |32           |Output           |加载、存储指令对应的存储器地址| 
    | reg2_o                            |32           |Output           |存储指令要存储的数据、或lwl、lwr指令要加载到目的寄存器的原始值| 

    - 纯组合逻辑，先进行子运算，再进行最终运算 

- EX/MEM模块 
    - 暂存处理阶段的运算结果、要写入目的寄存器信息，在下一个时钟传到访存阶段 
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            |Input            |时钟信号                    | 
    | ex_wd       | 5           |Input            |执行阶段的指令要写入的目的寄存器地址                | 
    | ex_wreg     |1            |Input            |执行阶段的指令是否写入目的寄存器            | 
    | ex_wdata    |32           |Input            |执行阶段的指令得到的运算结果                  | 
    | ex_whilo    |1            |Input            |执行阶段的指令是否要写入HI、LO寄存器               | 
    | ex_hi       |32           |Input            |执行阶段的指令要写入HI寄存器的值           | 
    | ex_lo       |32           |Input            |执行阶段的指令要写入LO寄存器的值             | 
    | stall       |6            |Input            |流水线暂停控制信号  |
    | hilo_i      |64           |Input            |保存的乘法结果             | 
    | cnt_i       |2            |Input            |下一个时钟周期是执行阶段的第几个时钟周期  |
    | ex_aluop    |8            |Input            |执行阶段要进行的运算子类型        | 
    | ex_mem_addr |32           |Input            |加载、存储指令对应的存储器地址| 
    | ex_reg2     |32           |Input            |存储指令要存储的数据、或lwl、lwr指令要加载到目的寄存器的原始值| 
    | mem_wdata   |32           |Output           |访存阶段的指令得到的运算结果                          | 
    | mem_wd      | 5           |Output           |访存阶段的指令要写入的目的寄存器地址              | 
    | mem_wreg    |1            |Output           |访存阶段的指令是否写入目的寄存器       | 
    | mem_whilo   |1            |Output           |访存阶段的指令是否要写入HI、LO寄存器               | 
    | mem_hi      |32           |Output           |访存阶段的指令要写入HI寄存器的值           | 
    | mem_lo      |32           |Output           |访存阶段的指令要写入LO寄存器的值             | 
    | hilo_o      |64           |Output           |保存的乘法结果             | 
    | cnt_o       |2            |Output           |当前处于执行阶段的第几个时钟周期  |
    | mem_aluop   |8            |Output           |访存阶段要进行的运算子类型        | 
    | mem_mem_addr|32           |Output           |访存阶段加载、存储指令对应的存储器地址| 
    | mem_reg2    |32           |Output           |访存阶段的指令要存储的数据、或lwl、lwr指令要加载到目的寄存器的原始值| 
    - 时钟缓冲作用 


- MEM模块 
    - 访存阶段 
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | wd_i        |5            |Input            |访存阶段的指令要写入的目的寄存器地址        | 
    | wreg_i      | 1           |Input            |访存阶段的指令是否要写入目的寄存器          | 
    | wdata_i     |32           |Input            |访存阶段的指令要写入目的寄存器的值          | 
    | whilo_i     |1            |Input            |访存阶段的指令最终是否要写入HI、LO寄存器               | 
    | hi_i        |32           |Input            |访存阶段的指令最终要写入HI寄存器的值           | 
    | lo_i        |32           |Input            |访存阶段的指令最终要写入LO寄存器的值             | 
    | aluop_i     |8            |Input            |访存阶段要进行的运算子类型        | 
    | mem_addr_i  |32           |Input            |访存阶段加载、存储指令对应的存储器地址| 
    | reg2_i      |32           |Input            |访存阶段存储指令要存储的数据、或lwl、lwr指令要加载到目的寄存器的原始值| 
    | mem_data_i  |32           |Input            |从数据存储器读取的数据 | 
    | LLbit_i     |1            |Input            |LLbit寄存器的值| 
    | wb_LLbit_we_i|1           |Input            |回写阶段的指令是否要写LLbit寄存器| 
    | wb_LLbit_value_i|1        |Input            |回写阶段的指令要写入LLBIt寄存器的值 | 
    | wd_o        |5            |Output           |访存阶段的指令最终要写入的目的寄存器地址        | 
    | wreg_o      |1            |Output           |访存阶段的指令最终是否要写入目的寄存器          | 
    | wdata_o     |32           |Output           |访存阶段的指令最终要写入目的寄存器的值          | 
    | whilo_o     |1            |Output           |访存阶段的指令最终是否要写入HI、LO寄存器               | 
    | hi_o        |32           |Output           |访存阶段的指令最终要写入HI寄存器的值           | 
    | lo_o        |32           |Output           |访存阶段的指令最终要写入LO寄存器的值             |
    | mem_addr_o  |32           |Output           |要访问的数据存储器的地址          | 
    | mem_we_o    |1            |Output           |是否进行写操作          | 
    | mem_sel_o   |4            |Output           |字节选择信号               | 
    | mem_data_o  |32           |Output           |要写入数据存储器的数据          | 
    | mem_ce_o    |1            |Output           |数据存储器使能信号             |
    | LLbit_we_o  |1            |Output           |访存阶段的指令是否要写LLbit寄存器| 
    | LLbit_value_o|1           |Output           |访存阶段的指令要写入LLBIt寄存器的值 | 



    - 目前ori指令本阶段不需要执行操作，简单传递 

- MEM/WB模块 
    - 暂存访存阶段的运算结果，在下一个时钟传到回写阶段 
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            |Input            |时钟信号                    | 
    | mem_wd      | 5           |Input            |访存阶段的指令要写入的目的寄存器地址                | 
    | mem_wreg    |1            |Input            |访存阶段的指令是否写入目的寄存器            | 
    | mem_wdata   |32           |Input            |访存阶段的指令得到的运算结果                  | 
    | mem_whilo   |1            |Input            |访存阶段的指令是否要写入HI、LO寄存器               | 
    | mem_hi      |32           |Input            |访存阶段的指令要写入HI寄存器的值           | 
    | mem_lo      |32           |Input            |访存阶段的指令要写入LO寄存器的值             | 
    | stall       |6            | Input           |流水线暂停控制信号  |
    | mem_LLbit_we    |1        |Intput           |访存阶段的指令是否要写LLbit寄存器| 
    | mem_LLbit_value |1        |Intput           |访存阶段的指令要写入LLBIt寄存器的值 | 
    | wb_wdata    |32           |Output           |回写阶段的指令得到的运算结果                          | 
    | wb_wd       | 5           |Output           |回写阶段的指令要写入的目的寄存器地址              | 
    | wb_wreg     |1            |Output           |回写阶段的指令是否写入目的寄存器       | 
    | wb_whilo    |1            |Output           |回写阶段的指令是否要写入HI、LO寄存器               | 
    | wb_hi       |32           |Output           |回写阶段的指令要写入HI寄存器的值           | 
    | wb_lo       |32           |Output           |回写阶段的指令要写入LO寄存器的值             | 
    | wb_LLbit_we   |1          |Output           |回写阶段的指令是否要写LLbit寄存器| 
    | wb_LLbit_value|1          |Output           |回写阶段的指令要写入LLBIt寄存器的值 | 
    - 时钟缓冲作用 

- MIPS编译环境建立 
    - 使用MIPS32架构下已有的GNU工具链 
    - 虚拟机安装： 
        - VisualBox：最新版本即可 
        - Ubuntu：使用22.04desktop版本 
        - 共享文件夹设置 
    - GNU工具链安装： 
        - 参考链接：https://blog.csdn.net/qq_38305370/article/details/114676603
        - 工具链命令：mips-linux-gnu- 
        - 流程：inst_rom.s编译->inst_rom.o链接ram.ld->inst_rom.om格式转化->inst_rom.bin转化格式->inst_rom.data 
        - Makefile：集成脚本 命令：make all


## Chapter5 逻辑、移位操作与空指令的实现 

- 数据相关 
    - 指令数据依赖于前面指令的执行结果 
    - 分类： 
        - Read After Write(RAW)：读该寄存器数据必须在先前指令写入之后 
        - Write After Read(WAR) ：写该寄存器不能影响前面指令的读操作 
        - Write After Write(WAW) ：写指令按序发生 
    - OpenMIPS只存在RAW相关 
    - RAW相关类型： 
        - 相邻指令间（译码、执行阶段） 
        - 相隔1条指令间（译码、访存阶段） 
        - 相隔2条指令间（译码、回写阶段）：该情况在Regfile中已经解决 
    - 解决方式： 
        - 插入暂停周期 
        - 编译器调度：更改指令顺序 
        - 数据前推：将计算结果从产生处直接推送到其他指令需要的位置-->采用此方法 
    - 数据前推： 
        - 将执行阶段、访存阶段的结果前推给译码阶段，包含信息为是否要写目的寄存器、要写的目的寄存器地址、要写入目的寄存器的数据。 
        - 使用MUX实现源操作数赋值，赋值优先级为：**复位>执行阶段相关>访存阶段相关>回写阶段相关（该处理在regfile.v中）>正常赋值**，原因为需要使用最新的寄存器数据进行运算 

- 逻辑、移位操作与空指令 
    - 逻辑操作（B1）： and,andi,or,ori,xor,xori,nor,lui(load upper immediate,rt<-immediate||0^16)  
        - 含有字母i的表示源操作数2为立即数，否则源操作数都来自寄存器数据 
    - 移位指令（B2）： sll,sllv,sra,srav,srl,srlv 
        - 第一个字母s表示移位 
        - 第二个字母表示移位方向 
        - 第三个字母表示移位方式：逻辑移位（l）或算术移位（a） 
        - 第四个字母表示移位位数确定方式：v表示由rs[4:0]确定移位位数，否则由5bit数据sa确定移位位数 
    - 空指令与其他指令（B9）：nop,ssnop,sync,pref 
        - nop,ssnop:空指令，其中ssnop为一种特殊空指令，在每个周期发射多条指令的CPU中，确保单独占用一个发射周期。在OpenMIPS中与nop处理方式相同 
        - sync：保证加载、存储的顺序，在OpenMIPS中当作空指令处理 
        - pref：缓存预取，OpenMIPS无缓存，当作空指令处理  
    - 指令冲突： 
        - nop   =  sll $0,$0,0 
        - ssnop =  sll $0,$0,1 
        - 实际不影响，$0始终为0，所以nop、ssnop不用特殊处理，当成sll处理即可 

- 修改后的模块接口说明已在上文中更改 

## Chapter6 移动指令的实现 

- 指令说明： 
    - movn(move condition on not zero) 
    - movz(move condition on zero) 
    - mfhi(move from HI) 
    - mthi(move to HI) 
    - mflo(move from LO) 
    - mtlo(move to LO) 
- HI/LO特殊寄存器：32bit，用于保存乘法、除法结果 
    - 乘法：HI保存高32位，LO保存低32位 
    - 除法：HI保存余数，LO保存商 
    - HI/LO寄存器不是通用寄存器，涉及该寄存器的读写操作时wreg_o信号置为WriteDisable，wd_o信号置为NOPRegAddr。 
    - HI/LO寄存器于执行阶段进行读取数据，于回写阶段写入数据 
    - HI/LO寄存器在流水线中**单独享有一条数据路径：EX->EX/MEM->MEM->MEM/WB->HILO->EX**；传递数据包含写使能信号whilo、读写数据hi、lo。 
    - 由于存在数据相关，HI/LO数据流水线需要进行数据前推，在访存阶段和回写阶段需要将数据前推到执行阶段。 
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            |Input            |时钟信号                    | 
    | we          | 5           |Input            |HI、LO寄存器写使能信号      | 
    | hi_i        |1            |Input            |要写入HI寄存器的值          | 
    | lo_i        |32           |Input            |要写入LO寄存器的值           | 
    | hi_o        |32           |Output           |HI寄存器的值                | 
    | lo_o        | 5           |Output           |LO寄存器的值              | 
 
- 修改后的模块接口说明已在上文中更改 

## Chapter7 算术指令的实现
- 随记： 
    - 进行有符号数据计算时，寄存器中的数据当做补码处理 
    - 有符号数据加减法：在不产生溢出的情况下，补码二进制数据直接计算的结果为计算结果的补码；对于有限位减法，结果等于加上被减数按位取反加一的值（无符号位补码）。
    - 有符号数据乘法：结果由64位寄存器保存，不存在溢出问题，直接取两操作数的真值相乘，再根据操作数的符号判定结果的符号，进行对应修改。
    - 除法：试商法，需要32个时钟周期，流程类似大除法竖式。
- 流水线暂停
    - 一些指令在执行阶段占用多个时钟周期，需要暂停流水线
    - 增加CTRL模块，用于接收各阶段传递过来的暂停请求信号，发送流水线暂停控制信号。
    - CTRL 接口 

    | 接口名           | 宽度（bit） | Input/Output      | 作用                      | 
    | -----------     | ----------- | -----------   | -----------               | 
    | rst             | 1           |Input            |复位信号                    | 
    | stallreq_from_id| 1           |Input            |处于译指阶段的指令是否请求流水线暂停                    | 
    | stallreq_from_ex| 1           |Input            |处于执行阶段的指令是否请求流水线暂停      | 
    | stall           | 6           |Output           |流水线暂停控制信号              | 

- 除法模块DIV模块
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            |Input            |时钟信号                    | 
    | signed_div_i| 1           |Input            |是否为有符号除法               | 
    | opdata1_i   |32           |Input            |被除数          | 
    | opdata2_i   |32           |Input            |除数         | 
    | start_i     | 1           |Input            |是否开始除法运算                    | 
    | annul_i     |1            |Input            |是否去消除法运算            | 
    | result_o    |64           |Output           |除法运算结果            | 
    | ready_o     | 1           |Output           |除法运算是否结束              | 

- 暂停、除法等导致的模块修改连线已在上文体现修改


## Chapter8 转移指令的实现
- 控制相关：流水线中的转移指令或者其他需要改写PC的指令造成的相关。这些指令改写了PC的值，导致后面已经进入流水线的几条指令无效。
    - 如果在执行阶段进行转移判断，取指和译指阶段的指令无效，浪费两个时钟周期
    - 延迟槽：规定转移指令后面的指令位置为延迟槽，延迟槽中的指令成为延迟指令。延迟指令总被执行，与转移是否发生没有关系。
    - 在译指时进行判断转移，延迟槽中会有一个延迟指令
- 译指阶段需要把指令转移信息返送给取指阶段。
- 转移指令导致的模块修改连线已在上文体现修改

## Chapter9 加载存储指令的实现
- 加载和存储：mips的寄存器和ram内存之间的数据交互。
- 数据位数：字节byte、半字hb、字word。半字和字一般要求地址对齐
- openmips 字节寻址，大端模式，数据高位保存在存储器低位。
- lwl&lwr、swl&swr指令配合可以从非对齐地址加载、存储字
- load造成的数据相关：读写相差超过一个时钟周期，不能用数据前推实现，需要stall
- RMW（Read-Modif—Write）：在多线程系统中，需要RMW操作序列保证对某个资源的独占性。读取内存中某个地址中的数据、读取的数据经过修改，再保存回内存原地址，这个过程不能有任何打扰，因此需要建立一个临界区域（Critical Region），临界区域中完成的操作成为原子操作，原子操作不被打扰。操作系统建立临界区域的方式成为信号量机制。
- mips采用链接加载指令ll、条件存储指令sc实现信号量机制。使用链接状态位寄存器LLbit_reg存储链接状态，置1表示发生链接加载操作，受到干扰后会置0。执行sc指令时，会检查llbit，为1则RMW序列未受干扰，sc正常执行写回操作，并设置一个通用寄存器为1；反之不写回，并设置一个通用寄存器为0，表示失败
- 加载存储指令导致的模块修改连线已在上文体现修改
- LLbit_reg模块
    - 接口 

    | 接口名       | 宽度（bit） | Input/Output      | 作用                      | 
    | ----------- | ----------- | -----------   | -----------               | 
    | rst         | 1           |Input            |复位信号                    | 
    | clk         |1            |Input            |时钟信号                    | 
    | flush       | 1           |Input            |是否有异常发生               | 
    | we          |1            |Input            |是否要写LLbit寄存器          | 
    | LLbit_i     | 1           |Input            |要写到LLbit寄存器的值                 | 
    | LLbit_o     |1            |Output           |LLbit寄存器的值        | 


## Chapter10 协处理器访问指令的实现
- MIPS32提供至多四个协处理器，分别为CP0~CP3，CP0用作系统控制，CP1、CP3用作浮点处理，CP2用于特定实现，此次仅实现CP0；
- CP0：配置工作CPU工作状态、异常控制等，此处实现以下寄存器（32bit）：
    - count：计数器
    - compare：与count一同完成定时中断
    - status：控制操作模式、中断使能等
    - cause：记录异常发生原因
    - epc：存储异常返回地址
    - prid：处理器标志（Processor Identifier）
    - config：配置功能信息
- 指令：mtc0、mfc0，读写CP0；流程与通用寄存器相似，注意数据前推

## Chapter11 异常相关指令的实现
- 精准异常：异常发生时，有一个被异常打断的指令，成为异常受害者（Exception Victim），该指令前的所有指令正常执行，之后的指令取消。为了实现精准异常，异常处理的顺序需要与指令顺序相同。对于使用流水线的处理器，需要在流水器的特定阶段处理异常，来实现精准异常。本处理器在访存阶段统一处理异常。
- 此处实现异常包括：
    - reset：硬件复位
    - interrupt：6个外部硬件中断、2个软件中断
    - syscall：系统调用指令
    - ri：无效指令
    - ov：算术指令溢出
    - tr：自陷指令
- 各异常判断时间：
    - 译码：syscall，eret，ri
    - 执行：trap，ova
    - 访存：interrupt



## OpenMIPS指令及机器码 
![OpenMIPS指令及机器码](/pic/OpenMPIS_INST.jpg "OpenMIPS指令及机器码") 
























