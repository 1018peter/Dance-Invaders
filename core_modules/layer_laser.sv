`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/04 23:48:34
// Design Name: 
// Module Name: layer_laser
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


module layer_laser(
    input clk,
    input laser_active,
    input [3:0] laser_r,
    input [1:0] laser_quadrant,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output logic layer_valid,
    output logic [11:0] pixel_out
    );
    parameter QUADRANT = 0;
    parameter VGA_XRES = 640;
    parameter VGA_YRES = 480;
    wire [9:0] laser_end_y = VGA_YRES - 80 - laser_r * 15;
	always @* begin
	   pixel_out = 12'h4_8_F;
	   
	end
	
	always @(posedge clk) begin
	   if(laser_quadrant == QUADRANT && laser_active && ((v_cnt >= laser_end_y
	   && h_cnt <= VGA_XRES / 2 + laser_end_y / 4 + 20 && h_cnt >= VGA_XRES / 2 - laser_end_y / 4 - 20) ||
	   h_cnt <= 20 || h_cnt >= VGA_XRES - 20 || v_cnt >= VGA_YRES - 20 || v_cnt <= 20)) begin
	       // Set union of the laser itself and a square frame around the screen.
	       layer_valid <= 1;
	   end
	   else layer_valid <= 0;
	end
	
endmodule
