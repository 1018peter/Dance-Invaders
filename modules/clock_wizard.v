`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/22 11:33:22
// Design Name: 
// Module Name: clock_wizard
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

module clock_wizard(
    input clk_100MHz,
    input rst,
    input [1:0] select, // 0: 60 Hz, 1: 50 Hz, 2: 40 Hz, 3: 30 Hz
    output clk_div
    );
    parameter div_3 = 833333; // Corresponds to 60 Hz
    parameter div_2 = 1000000;    // Corresponds to 50 Hz
    parameter div_1 = 1250000;  // Corresponds to 40 Hz
    parameter div_0 = 1666666;  // Corresponds to 30 Hz
    reg [21:0] div;
    reg [1:0] cur_state;
    
    always @* begin
        case(cur_state)
        0: div = div_0;
        1: div = div_1;
        2: div = div_2;
        3: div = div_3;
        default: div = div_0;
        endcase
    end
    reg[21:0] ctr;
    reg clk_div_reg;
    assign clk_div = clk_div_reg;
    always @(posedge clk_100MHz, posedge rst) begin
        if(rst) begin
            cur_state <= 0;
            ctr <= 0;
            clk_div_reg <= 0;
        end
        else if(cur_state != select) begin // Smooth clock select transition.
            cur_state <= select;
            ctr <= 0;
        end
        else if(ctr != div - 1) begin
            ctr <= ctr + 1;
        end
        else begin
            ctr <= 0;
            clk_div_reg <= ~clk_div_reg;
        end
    end
endmodule
