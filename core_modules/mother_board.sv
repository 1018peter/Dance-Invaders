`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 15:54:03
// Design Name: Mother Board
// Module Name: mother_board
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// The top module of the central board.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "typedefs.svh"
`include "constants.svh"

module mother_board(
    input clk,
    input rst,
    input RxD,
    output [15:0] led,
    output [3:0] DIGIT,
    output [6:0] DISPLAY
    );
    
    wire [MESSAGE_SIZE-1:0] datagram;
    control_core (
    .clk(clk),
    .rst(rst),
    .RxD(RxD),
    .datagram(datagram),
    .led(led),
    .DIGIT(DIGIT),
    .DISPLAY(DISPLAY)
    );
endmodule
