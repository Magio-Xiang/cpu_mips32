`include "defines.v"

module openmips_min_sopc (
    input wire clk,
    input wire rst
);
    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;

    wire[`DataBus] ram_data_i;
    wire[`DataBus] ram_data_o;
    wire[`DataAddrBus] ram_addr;
    wire[3:0] ram_sel;
    wire ram_we;
    wire ram_ce;


    inst_rom u_inst_rom(
        .ce   ( rom_ce   ),
        .addr ( inst_addr ),
        .inst  ( inst  )
    );

    openmips u_openmips(
        .rst        ( rst        ),
        .clk        ( clk        ),
        .rom_data_i ( inst ),
        .rom_addr_o ( inst_addr ),
        .rom_ce_o   ( rom_ce   ),

        .ram_data_i(ram_data_i),
        .ram_data_o(ram_data_o),
        .ram_addr_o(ram_addr),
        .ram_sel_o(ram_sel),
        .ram_we_o(ram_we),
        .ram_ce_o(ram_ce)
    );

    data_ram u_data_ram(
    .ce     ( ram_ce     ),
    .clk    ( clk    ),
    .data_i ( ram_data_o ),
    .addr   ( ram_addr  ),
    .we     ( ram_we     ),
    .sel    ( ram_sel ),
    .data_o  ( ram_data_i  )
);


endmodule