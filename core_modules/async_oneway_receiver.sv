`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/13 19:58:10
// Design Name: 
// Module Name: async_oneway_receiver
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
`include "constants.svh"

module async_oneway_receiver(
input clk_receive,
input clk_db,
input transmit_ctrl,
input packet_pulse,
input [5:0] din,
output logic [MESSAGE_SIZE-1:0] read_buffer
    );
    
    logic [7:0] packet_pre;
    generate
    for(genvar g = 0; g < 6; ++g) begin
        debounce(packet_pre[g], din[g], clk_db);        
    end
    endgenerate
    debounce(packet_pre[6], packet_pulse, clk_db);
    debounce(packet_pre[7], transmit_ctrl, clk_db);
    logic [MESSAGE_SIZE-1+6:0] recv_buffer = 0;
    
	always @(posedge packet_pre[6]) begin
		recv_buffer <= { packet_pre[5:0], recv_buffer[MESSAGE_SIZE-1+6:6]};
	end
    
	always @(posedge packet_pre[7]) begin
        read_buffer <= recv_buffer[MESSAGE_SIZE-1+6:MESSAGE_SIZE%6];
	end
    
endmodule
