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
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input ACK [0:3],
    output [5:0] DOUT [0:3],
    output REQ [0:3],
    output [15:0] led,
    output [3:0] DIGIT,
    output [6:0] DISPLAY,
    
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    
    );
    
    wire [MESSAGE_SIZE-1:0] datagram;
    wire sending_clk;
    control_core (
    .clk(clk),
    .rst(rst),
    .btnU(btnU),
    .btnD(btnD),
    .btnL(btnL),
    .btnR(btnR),
    .RxD(RxD),
    .sending_clk(sending_clk),
    .datagram(datagram),
    .led(led),
    .DIGIT(DIGIT),
    .DISPLAY(DISPLAY)
    );
    wire packet_valid = 1;
    
    generate
    for(genvar g = 0; g < 4; ++g) begin
        async_oneway_transmitter(
        .clk_sender(sending_clk),
        .packet_pulse(ACK[g]),
        .packet_out(DOUT[g]),
        .transmit_ctrl(REQ[g]),
        .async_load(sending_clk),
        .datagram_in(datagram)
        );
    end
    endgenerate
    
    /*
    wire [MESSAGE_SIZE-1:0] recv_data;
    receiver #(.n(MESSAGE_SIZE))
    (
    .clk_receiver(clk),
    .wire_req(ctrl_req),
    .wire_data_deliver(ctrl_out),
    .wire_data_out(recv_data),
    .reg_ack(interface_ack),
    .reg_valid(packet_valid)
    );
    
    
    reg [MESSAGE_SIZE-1:0] reg_datagram;
    always @(posedge clk) begin
        if(rst) reg_datagram <= 0;
        else if(packet_valid) reg_datagram <= datagram;
    end
    
    output_interface(
    .clk(clk),
    .rst(rst),
    .datagram(reg_datagram),
    .vgaRed(vgaRed),
    .vgaGreen(vgaGreen),
    .vgaBlue(vgaBlue),
    .hsync(hsync),
    .vsync(vsync)
    );
    
    */
endmodule
