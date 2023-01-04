`timescale 1ns / 1ps
`include "global_defines.vh"

module iob_rom_sp
  #(
    parameter DATA_W = 8,
    parameter ADDR_W = 10,
    parameter HEXFILE = "none"
	)
   (
    input                    clk,
    input                    r_en,
    input [ADDR_W-1:0]       addr,
    output reg [DATA_W-1:0]  r_data
    );
   
    `include "boot_case.vh"
  
endmodule
