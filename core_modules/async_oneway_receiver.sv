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
input transmit_ctrl,
input packet_pulse,
input [5:0] din,
output logic [MESSAGE_SIZE-1:0] read_buffer
    );
    
    logic [6:0] packet_pre;
    logic [6:0] packet_onepulse = 0;
    generate
    for(genvar g = 0; g < 6; ++g) begin
        debounce(packet_pre[g], din[g], clk_receive);        
    end
    endgenerate
    debounce(packet_pre[6], packet_pulse, clk_receive);
    parameter state_idle = 0;
    parameter state_recv = 1;
    parameter state_save = 2;
    logic [1:0] state = state_idle;
    
    always @(posedge clk_receive) begin
        for(int i = 0; i < 7; ++i)
            if(packet_pre[i]) packet_onepulse <= 1;
            else packet_onepulse <= 0;
    end
    
    logic [MESSAGE_SIZE-1+6:0] recv_buffer = 0;
    
    always @(posedge clk_receive) begin
        if(state == state_idle && transmit_ctrl) begin
            state <= state_recv;
        end
        else if(state == state_recv) begin
            if(packet_onepulse[6]) recv_buffer <= { packet_onepulse[5:0], recv_buffer[MESSAGE_SIZE-1+6:6]};
            if(!transmit_ctrl) begin
                state <= state_save;
            end
        end
        else if(state == state_save) begin
            read_buffer <= recv_buffer;
            state <= state_idle;
        end
        
    end
    
    
    
endmodule
