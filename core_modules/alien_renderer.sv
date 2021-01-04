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
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input AlienData obj_data,
    output logic [1:0] deriv_select,
    output logic [10:0] pixel_addr,
    output logic valid
    );
    
    logic side;
    logic [9:0] halfwidth;
    logic [9:0] halfheight;
    always @* begin
    
        side = h_cnt < obj_data._x_pos;
        halfwidth = 32 - obj_data._r;
        halfheight = 32 - obj_data._r;
        valid = 1;
        if(side == 0) begin // Right-side. No mirror.
            deriv_select = obj_data._deriv_right;
            if(h_cnt - obj_data._x_pos >= halfwidth) valid = 0;
            pixel_addr = ((v_cnt - (obj_data._y_pos - halfheight)) * halfwidth) + (h_cnt - obj_data._x_pos);
        
        end
        else begin // Left-side. Mirror.
            deriv_select = obj_data._deriv_left;
            if(obj_data._x_pos >= halfwidth) valid = 0;
            pixel_addr = ((v_cnt - (obj_data._y_pos - halfheight)) * halfwidth) + (obj_data._x_pos - h_cnt);
        
        end
    end
    
endmodule
