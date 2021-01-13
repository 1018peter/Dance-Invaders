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
input sync_load,
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
    logic [MESSAGE_SIZE-1:0] send_buffer;
    
    always @(posedge clk_send, posedge rst) begin
    if(rst) begin
        state <= state_idle;
        ptr <= 0;
    end
    else if(state == state_idle) begin
        state <= state_load;
        send_buffer <= datagram_in;
        packet_pulse <= 0;
        ptr <= 0;
        transmit_ctrl <= 0;
    end
    else begin
        if(state == state_load) begin
            state <= state_send;
        end
        else if(state == state_send) begin
            state <= state_pulse;
            packet_out <= send_buffer[5:0];
            ptr <= ptr + 6;
            send_buffer <= send_buffer >> 6;
            packet_pulse <= 1;
        end
        else if(state == state_pulse) begin
            packet_pulse <= 0;
            if(ptr >= MESSAGE_SIZE) begin
                state <= state_idle;
                send_buffer <= datagram_in;
                transmit_ctrl <= 1;
            end
            else state <= state_send;
        end
    end
    end
    
endmodule
