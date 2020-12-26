`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/22 09:19:27
// Design Name: 10 Hertz Clock Generator from a 100 MHz clock.
// Module Name: clock_divider_10Hz
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
// Original design used in lab4_2.
//////////////////////////////////////////////////////////////////////////////////


module clock_divider_10Hz(
    input clk_100MHz,
    input rst,
    output clk_div
    );
    
    reg[23:0] ctr;
    reg clk_div_reg;
    assign clk_div = clk_div_reg;
    always @(posedge clk_100MHz, posedge rst) begin
        if(rst) begin
            ctr <= 0;
            clk_div_reg <= 0;
        end
        else if(ctr != 5000000 - 1) begin
            ctr <= ctr + 1;
        end
        else begin
            ctr <= 0;
            clk_div_reg <= ~clk_div_reg;
        end
    end
endmodule
