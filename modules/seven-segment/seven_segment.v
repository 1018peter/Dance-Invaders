`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/24 20:28:41
// Design Name: 
// Module Name: seven_segment
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
// Module recycled from past labs.
//////////////////////////////////////////////////////////////////////////////////

module clock_refresh_gen(clk, clk_div);   
    parameter n = 12;     
    input clk;   
    output clk_div;   
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num<=next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];
    
endmodule


module seven_segment(
    input clk,
    input [27:0] display_queue,
    output [3:0] digit_select,
    output [6:0] display_select
);
    wire clk_refresh;
    clock_refresh_gen(clk, clk_refresh);
    reg [1:0] step = 0;
    reg [3:0] digit;
    reg [6:0] display;
    always @(posedge clk_refresh) begin
        step <= step + 1;
        case(step)
            0: begin 
            digit <= 4'b0111;
            display <= display_queue[27:21];
            end
            1: begin
            digit <= 4'b1011;
            display <= display_queue[20:14];
            end
            2: begin
            digit <= 4'b1101;
            display <= display_queue[13:7];
            end
            3: begin
            digit <= 4'b1110;
            display <= display_queue[6:0];
            end
            default: begin
            digit <= 4'b1111;
            display <= display_queue[6:0];
            end
        endcase
    end
    
    assign digit_select = digit;
    assign display_select = display;
    
endmodule

module hex_decoder(
    input [3:0] hex_int,
    output reg [6:0] display
);
    // Seven-Segment character set.
    parameter SSCHAR_0 = 7'b1000000;
    parameter SSCHAR_1 = 7'b1111001;
    parameter SSCHAR_2 = 7'b0100100;
    parameter SSCHAR_3 = 7'b0110000;
    parameter SSCHAR_4 = 7'b0011001;
    parameter SSCHAR_5 = 7'b0010010;
    parameter SSCHAR_6 = 7'b0000011;
    parameter SSCHAR_7 = 7'b1011000;
    parameter SSCHAR_8 = 7'b0000000;
    parameter SSCHAR_9 = 7'b0010000;
    parameter SSCHAR_A = 7'b0001000;
    parameter SSCHAR_B = 7'b0000011;
    parameter SSCHAR_C = 7'b0100111;
    parameter SSCHAR_D = 7'b0100001;
    parameter SSCHAR_E = 7'b0000110;
    parameter SSCHAR_F = 7'b0001110;
    parameter SSCHAR_NULL = 7'b1111111;
    always @* begin
    case(hex_int)
    0: display = SSCHAR_0;
    1: display = SSCHAR_1;
    2: display = SSCHAR_2;
    3: display = SSCHAR_3;
    4: display = SSCHAR_4;
    5: display = SSCHAR_5;
    6: display = SSCHAR_6;
    7: display = SSCHAR_7;
    8: display = SSCHAR_8;
    9: display = SSCHAR_9;
    10: display = SSCHAR_A;
    11: display = SSCHAR_B;
    12: display = SSCHAR_C;
    13: display = SSCHAR_D;
    14: display = SSCHAR_E;
    15: display = SSCHAR_F;
    default: display = SSCHAR_NULL;
    endcase
    end
endmodule