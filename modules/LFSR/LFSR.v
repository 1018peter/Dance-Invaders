`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/22 22:05:28
// Design Name: 
// Module Name: LFSR
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

// 16-bit Fibonacci LFSR featured on Wikipedia.
module LFSR(
    input clk,
    input rst,
    input [15:0] seed, // Must be non-zero.
    output [15:0] rand_out
    );
    reg [15:0] reg_shift;
    assign rand_out = reg_shift;
    always @(posedge clk, posedge rst) begin
        if (rst) reg_shift <= seed;
        else reg_shift <= { reg_shift[14:0], reg_shift[10] ^ reg_shift[12] ^ reg_shift[13] ^ reg_shift[15] };
    end
endmodule
