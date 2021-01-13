`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/13 19:38:50
// Design Name: 
// Module Name: async_oneway_transmitter
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

module async_oneway_transmitter(
input clk_send,
input rst,
input async_load,
input [MESSAGE_SIZE-1:0] datagram_in,
output logic [5:0] packet_out,
output logic transmit_ctrl,
output logic packet_pulse
    );
    parameter state_idle = 0;
    parameter state_load = 1;
    parameter state_send = 2;
    parameter state_pulse = 3;
    logic [15:0] ptr;
    logic [1:0] state;
    logic [MESSAGE_SIZE-1 + 6:0] send_buffer;
    always @* begin
        transmit_ctrl = state[1];
    end
    
    always @(posedge clk_send, posedge rst, posedge async_load) begin
    if(rst) begin
        state <= state_idle;
        ptr <= 5;
    end
    else if(async_load && state == state_idle) begin
        state <= state_load;
        packet_pulse <= 0;
        ptr <= 5;    
    end
    else begin
        if(state == state_load) begin
            send_buffer <= datagram_in;
            state <= state_send;
        end
        else if(state == state_send) begin
            if(ptr >= MESSAGE_SIZE) begin
                state <= state_idle;
                
            end
            packet_out <= send_buffer[5:0];
            ptr <= ptr + 6;
            send_buffer <= send_buffer >> 6;
            packet_pulse <= 1;
            state <= state_pulse;
        end
        else if(state == state_pulse) begin
            packet_pulse <= 0;
            state <= state_send;
        end
    end
    end
    
    
endmodule
