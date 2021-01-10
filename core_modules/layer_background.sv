`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/31 15:59:06
// Design Name: 
// Module Name: layer_background
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module layer_background(
    input clk,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [11:0] pixel
    );
    
    // TODO: Instantiate a memory block for the (sparse?) background using its .coe form.
    
    // Default.
    wire [15:0] pixel_addr = (v_cnt >> 1) * 4 * 240 + (h_cnt >> 1);
    wire [7:0] hex_bus;
    wire [3:0] palette_select;
    assign palette_select = pixel_addr[0] ? hex_bus[7:4] : hex_bus[3:0];
    
    parameter [11:0] PALETTE_COLOR = {
    12'h122, 12'h112, 12'h112, 12'haaa,
    12'h122, 12'h122, 12'h111, 12'h112,
    12'h222, 12'h112, 12'h112, 12'h112,
    12'h112, 12'h112, 12'h112, 12'h112
    };
    assign pixel = PALETTE_COLOR[palette_select];
    background_block_mem(
    .clka(clk),
    .addra({pixel_addr[15:4], 3'b0}),
    .douta(hex_bus)
    );
    
endmodule
