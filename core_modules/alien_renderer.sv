`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/31 16:30:53
// Design Name: 
// Module Name: alien_renderer
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
`include "typedefs.svh"

module alien_renderer(
    input clk,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input AlienData obj_data,
    output logic [1:0] deriv_select,
    output logic [10:0] pixel_addr,
    output logic in_frame,
    output logic valid
    );
    parameter QUADRANT = 0;
    parameter [9:0] X_OVERFLOW_GUARD = 128;
    wire [9:0] h_cnt_guarded = h_cnt + X_OVERFLOW_GUARD;
    logic side;
    logic [9:0] halfwidth;
    logic [9:0] halfheight;
    logic [9:0] y_addr_buffer;
    logic [9:0] x_addr_buffer;
    logic [10:0] product_buffer;
    logic [10:0] pixel_addr_buffer;
    logic [9:0] halfwidth_buffer;
    logic [9:0] halfheight_buffer;
    always @* begin
        side = h_cnt_guarded < obj_data._x_pos;
        halfwidth = 32 - obj_data._r;
        halfheight = 32 - obj_data._r;
    end
    
    always @(posedge clk) begin
        if(!obj_data._active || obj_data._quadrant != QUADRANT) begin
             valid <= 0;
             in_frame <= 0;
        end
        else begin
            in_frame <= 1;
            if(v_cnt <= obj_data._y_pos - halfheight_buffer * 4 || v_cnt >= obj_data._y_pos + halfheight_buffer * 4) valid <= 0;
            else if(side == 0) begin // Right-side. No mirror.
                if(h_cnt_guarded - obj_data._x_pos >= halfwidth_buffer * 4) valid <= 0;
                else valid <= 1;
            end
            else begin // Left-side. Mirror.
                if(obj_data._x_pos - h_cnt_guarded >= halfwidth_buffer * 4 - 4) valid <= 0;
                else valid <= 1;
            end
        end
    end
    
    always @(posedge clk) begin
        halfwidth_buffer <= halfwidth;
        halfheight_buffer <= halfheight;
        y_addr_buffer <= (((v_cnt - (obj_data._y_pos - halfheight_buffer * 4))) / 4);
        pixel_addr <= pixel_addr_buffer;
        product_buffer <= y_addr_buffer * halfwidth_buffer;
        if(side == 0) begin // Right-side. No mirror.
            deriv_select <= obj_data._deriv_right;
            x_addr_buffer <= ((h_cnt_guarded - obj_data._x_pos) / 4);
            pixel_addr_buffer <= product_buffer + x_addr_buffer;
        
        end
        else begin // Left-side. Mirror.
            deriv_select <= obj_data._deriv_left;
            x_addr_buffer <= ((obj_data._x_pos - h_cnt_guarded) / 4);
            pixel_addr_buffer <= product_buffer + x_addr_buffer;
        
        end
    end
    
endmodule
