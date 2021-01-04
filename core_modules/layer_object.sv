`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/04 23:41:29
// Design Name: 
// Module Name: layer_object
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


module layer_object(
    input clk_25MHz,
    input AlienData obj_data [0:OBJ_LIMIT-1],
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output logic layer_valid,
    output logic [11:0] pixel_out
    );
    parameter QUADRANT = 0;
    
    wire [10:0] pixel_addr [0:OBJ_LIMIT-1];
	wire pixel_valid [0:OBJ_LIMIT-1];
	wire [1:0] deriv_select [0:OBJ_LIMIT-1];
	generate
        for(genvar g = 0; g < OBJ_LIMIT; g++)
            alien_renderer(
            .h_cnt(h_cnt),
            .v_cnt(v_cnt),
            .obj_data(obj_data[g]),
            .pixel_addr(pixel_addr[g]),
            .deriv_select(deriv_select[g]),
            .valid(pixel_valid[g])
            );
	endgenerate
	
	logic [10:0] pixel_addr_obj;
	logic [11:0] palette_color;
	logic [3:0] distance;
	logic [1:0] deriv;
	logic [1:0] alien_type;
	logic [1:0] frame_num;
	logic obj_layer_valid;
	always @* begin
	   pixel_addr_obj = 0;
	   palette_color = 0;
	   deriv = 0;
	   alien_type = 0;
	   frame_num = 0;
	   distance = 0;
	   // Priority encoding to render the closest alien on the current pixel.
	   for(int i = 0;i < OBJ_LIMIT; ++i) begin
	       if(obj_data[i]._active && obj_data[i]._quadrant == QUADRANT && pixel_valid[i]) begin
	           pixel_addr_obj = pixel_addr[i];
	           distance = obj_data[i]._r;
	           deriv = deriv_select[i];
	           alien_type = obj_data[i]._type;
	           frame_num = obj_data[i]._frame_num;
	           break;
	       end
	   end
	end
	
	wire palette_out;
	alien_pixel_reader(
	.clk(clk_25MHz),
	.frame_num(frame_num),
	.alien_type(alien_type),
	.size_select(distance),
	.deriv_select(deriv),
	.read_addr(pixel_addr_obj),
	.palette_out(palette_out)
	);
	
	logic [11:0] obj_pixel_out;
	always @* begin
	   pixel_out = 0;
	   layer_valid = 0;
        if(palette_out) begin
            layer_valid = 1;
            case(alien_type)
            0: pixel_out = { 4'h4 - (distance >> 4), 4'h4 - (distance >> 4), 4'hF - (distance >> 1) };
            1: pixel_out = { 4'h4 - (distance >> 4), 4'hF - (distance >> 1), 4'h4 - (distance >> 4) };
            2: pixel_out = { 4'hF - (distance >> 1), 4'h4 - (distance >> 4), 4'h4 - (distance >> 4) };
            3: pixel_out = { 4'hF - (distance >> 1), 4'h4 - (distance >> 4), 4'hF - (distance >> 1) };
            endcase
        end
	end
endmodule
