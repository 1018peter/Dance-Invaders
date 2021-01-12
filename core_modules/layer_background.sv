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
    wire [16:0] pixel_addr = (v_cnt >> 1) * 320 + (h_cnt >> 1);
    wire [3:0] palette_select;
    
    parameter [11:0] PALETTE_COLOR [0:15] = {
    12'h2_2_2, 12'h2_3_3, 12'h2_3_3, 12'hc_c_c,
    12'h2_2_3, 12'h2_3_3, 12'h2_3_3, 12'h1_1_3,
    12'h3_3_3, 12'h2_3_3, 12'h1_4_4, 12'h1_3_3,
    12'h2_3_3, 12'h3_2_3, 12'h4_4_4, 12'h1_3_3
    };
    assign pixel = PALETTE_COLOR[palette_select];
    background_block_mem(
    .clka(clk),
    .addra(pixel_addr[15:0]),
    .douta(palette_select)
    );
    
endmodule
