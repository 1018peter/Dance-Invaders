`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 21:15:00
// Design Name: 
// Module Name: output_interface
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

/*
The VGA resolution is 640 x 480 px, and the degree range is up to a delta of 90 degrees.
The projected horizontal distance from cylindrical coordinates to Cartesian coordinates is given
by R * sin(theta - phi), where theta is the object's degree and phi is the degree of the axis.

We add an additional constraint, that the edge of the screen represents 30 degrees from the central
axis at minimum render distance, 1 * alpha * sin(30) = 240 -> alpha = 480. We will use sine tables
since there are only 91 cases. (Integral degrees)

Sprites are preprocessed into various transforms, because performing linear transformations
is highly expensive (especially to store intermediate results) and their results are very 
likely to repeat. 
90 x 15 = up to 1350 configurations -> symmetry breaking 
-> 45 x 15 = 675 configurations, and roughly half of these will be invisible, another quarter
being repeats.
For every configuration set in the same distance, we will approximate using only 4 derivatives.
-> 4 x 15 = 60 configurations!
We'll use monochrome sprite sizes from 64x64 (full resolution) to 32x32 (smallest sprite)
64x64 -> 62x62 -> 60x60 -> ... -> 34x34 -> 32x32.
Sprites are horizontally symmetric, so for every sprite, we only need to store half of the sprites'
bits.

This yields a rough memory cost of 86.5k / 2 x 4 = 169 kbits per alien, less than 10% of the 
1800 kbits available.

By making the four alien types into two pairs of palette-swapped sprites, the number of 
bits used can be cut down to 84.5 kbits per alien.

That gives us the opportunity to add a two-frame global animation, so in total we can deal
with aliens in just 84.5 x 2 x 2 = 338 kbits.



TODO:
Resolve priority for all objects first, thus only using one read operation on a particular image at any time, allowing for 
clean memory synthesis.

TODO:
Change datagram format so that the (y, x) coordinates are passed rather than the less useful (r, theta) coordinates.
The object data in the datagram should be sorted according to distance.
We can accomplish this easily using 16 parallel units that sort the objects into 16 buffers, and concatenate the buffers into a sorted output 
sequence, ranked implicitly by the keys (distance, index).
*/

module output_interface(
    input clk,
    input rst,
    input [MESSAGE_SIZE - 1:0] datagram,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    );
    // The quadrant the output interface displays.
    parameter QUADRANT = 0;
    
    parameter VGA_XRES = 640;
    parameter VGA_YRES = 480;
    
    // Syntactic sugar that illustrates the recovery of essential variables from the datagram.
    wire [STATE_SIZE - 1:0] core_state = datagram[STATE_SIZE - 1:0];
    wire [INGAME_DATA_SIZE - 1:0] ingame_data = datagram[STATE_SIZE + INGAME_DATA_SIZE - 1:STATE_SIZE];
    wire [SCORE_SIZE - 1:0] score_data = ingame_data[SCORE_SIZE + LEVEL_SIZE - 1:LEVEL_SIZE];
    wire [LEVEL_SIZE - 1:0] level_data = ingame_data[LEVEL_SIZE - 1:0];
    wire [FRAME_DATA_SIZE - 1:0] frame_data = ingame_data[SCORE_SIZE + LEVEL_SIZE + FRAME_DATA_SIZE - 1: SCORE_SIZE + LEVEL_SIZE];
    wire laser_active = frame_data[0];
    wire laser_r = frame_data[4:1];
    wire laser_quadrant = frame_data[6:5];
    AlienData obj_data[0:OBJ_LIMIT-1];
    generate
	for(genvar k = 0; k < OBJ_LIMIT; k++) begin
	    localparam startpos = 7 + k * $size(AlienData);
        assign obj_data[k]._active = frame_data[startpos];
        assign obj_data[k]._type = frame_data[startpos+2:startpos+1];
        assign obj_data[k]._frame_num = frame_data[startpos+4:startpos+3];
        assign obj_data[k]._r = frame_data[startpos+8:startpos+5];
        assign obj_data[k]._quadrant = frame_data[startpos+10:startpos+9];
        assign obj_data[k]._x_pos = frame_data[startpos+20:startpos+11];
        assign obj_data[k]._y_pos = frame_data[startpos+30:startpos+21];
        assign obj_data[k]._deriv_left = frame_data[startpos+32:startpos+31];
        assign obj_data[k]._deriv_right = frame_data[startpos+34:startpos+33];
    end
	endgenerate
	wire [SCOREBOARD_DATA_SIZE - 1:0] scoreboard_data = datagram[STATE_SIZE + SCOREBOARD_DATA_SIZE - 1:STATE_SIZE];
    wire scoreboard_state;
    wire [SCORE_SIZE - 1:0] player_score;
    wire [STRING_SIZE - 1:0] player_name;
    wire [SCORE_SIZE - 1:0] score [0:4];
    wire [STRING_SIZE - 1:0] name [0:4];
    wire [1:0] input_pos;
    assign { score[4], name[4], score[3], name[3], score[2], name[2], score[1], name[1],
    score[0], name[0], player_score, player_name, input_pos, scoreboard_state } = scoreboard_data;
	
	
	wire clk_25MHz;
	clock_divider_25MHz(clk_25MHz, clk);
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    
    vga_controller vga_inst(
      .pclk(clk_25MHz),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
	
	wire [11:0] pixel_bg;
	layer_background(
	.clk(clk_25MHz),
	.h_cnt(h_cnt),
	.v_cnt(v_cnt),
	.pixel(pixel_bg)
	);
	
	
	wire [15:0] pixel_addr [0:OBJ_LIMIT-1];
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
	
	logic [15:0] pixel_addr_obj;
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
	.pixel_addr(pixel_addr_obj),
	.palette_out(palette_out)
	);
	
	logic [11:0] obj_pixel_out;
	always @* begin
	   obj_pixel_out = 0;
	   obj_layer_valid = 0;
        if(palette_out) begin
            obj_layer_valid = 1;
            case(alien_type)
            0: obj_pixel_out = { 4'h4 - (distance >> 4), 4'h4 - (distance >> 4), 4'hF - (distance >> 1) };
            1: obj_pixel_out = { 4'h4 - (distance >> 4), 4'hF - (distance >> 1), 4'h4 - (distance >> 4) };
            2: obj_pixel_out = { 4'hF - (distance >> 1), 4'h4 - (distance >> 4), 4'h4 - (distance >> 4) };
            3: obj_pixel_out = { 4'hF - (distance >> 1), 4'h4 - (distance >> 4), 4'hF - (distance >> 1) };
            endcase
        end
	end
	
	logic laser_layer_valid;
	wire [9:0] laser_end_y = 480 - 80 - laser_r * 15;
	always @* begin
	   laser_layer_valid = 0;
	   if(laser_quadrant == QUADRANT && laser_active && ((v_cnt >= laser_end_y
	   && h_cnt <= laser_end_y + 20 && h_cnt >= laser_end_y - 20) ||
	   h_cnt <= 20 || h_cnt >= VGA_XRES - 20 || v_cnt >= VGA_YRES - 20 || v_cnt <= 20)) begin
	       // Set union of the laser itself and a square frame around the screen.
	       laser_layer_valid = 1;
	   end
	end
	
	logic [11:0] rendered_pixel;
	assign {vgaRed, vgaGreen, vgaBlue} = rendered_pixel;
    always @* begin
        rendered_pixel = pixel_bg;
        case(core_state)
        SCENE_GAME_START: begin
        
        end
        SCENE_LEVEL_START: begin
        
        end
        SCENE_INGAME: begin
            if(laser_layer_valid) begin
                rendered_pixel = 12'h4_8_F; // Laser color.
            end
            else if(obj_layer_valid) begin
                rendered_pixel = obj_pixel_out;
            end
        end
        SCENE_GAME_OVER: begin
        
        end
        SCENE_SCOREBOARD: begin
        
        end
        default: begin
        
        end
        endcase
    end
    
endmodule

module clock_divider_25MHz(clk1, clk);
input clk;
output clk1;

reg [1:0] num;
wire [1:0] next_num;

always @(posedge clk) begin
  num <= next_num;
end

assign next_num = num + 1'b1;
assign clk1 = num[1];

endmodule

