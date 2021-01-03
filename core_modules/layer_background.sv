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
    assign pixel = 12'h0_0_0;
    
endmodule
