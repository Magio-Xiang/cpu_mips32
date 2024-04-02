# Problem

## 文件说明 
- 放置待解决的问题 
- 格式
    - 文件路径：问题

## Problem 
- my_code: 
    - 模块的时序设计，怎样选择使用组合逻辑还是时序逻辑：五级流水的具体阶段内使用组合逻辑，阶段模块间使用时序逻辑消除毛刺 
    - 异常处理：当延迟槽指令发生异常时，返回的是跳转指令的地址。在恢复执行时，继续执行转移指令，会不会导致异常循环发生：目前实现的情况为恢复执行后直接执行转移指令下一条的指令，转移无效
    - 异常处理：异常处理过程中会不会发生新的异常：目前实现的异常不会导致

- my_code/id.v: 
    - 复位阶段指令置为有效 
    - 译值前wd_o信号设置为inst_i[15:11]：大多是r型指令目的寄存器地址为inst_i[15:11] 
    - mthi和mtlo的alusel_o置为EXE_RES_NOP而不是EXE_RES_MOVE，目前代码改成move来进行测试是否对计算结果有影响->无影响
        - alusel_o的设置影响wdata_o的赋值，对于mthi、mtlo指令而言不需要对通用寄存器赋值，所以**wreg_o置WriteDisable，alusel_o置EXE_RES_NOP，双重保护保证不会赋值出错**
        - mult、multu等指令将结果写入HI、LO寄存器，不需要对通用寄存器赋值，应与mthi、mtlo相似wreg_o置WriteDisable，alusel_o置EXE_RES_NOP

- my_code/if_id.v:
    - 流水线暂停没想明白


-