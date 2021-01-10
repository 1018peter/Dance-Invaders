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
Sprites are preprocessed into various transforms, because performing linear transformations
is highly expensive (especially to store intermediate results) and their results are very 
likely to repeat. 
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
    wire [STATE_SIZE - 1:0] core_state;
    wire [INGAME_DATA_SIZE - 1:0] ingame_data;
    assign { ingame_data, core_state } = datagram;
    wire [SCORE_SIZE - 1:0] score_data;
    wire [LEVEL_SIZE - 1:0] level_data;
    wire [FRAME_DATA_SIZE - 1:0] frame_data;
    assign { frame_data, score_data, level_data } = ingame_data;
    wire laser_active = frame_data[0];
    wire [3:0] laser_r = frame_data[4:1];
    wire [1:0] laser_quadrant = frame_data[6:5];
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
    assign { name[4], score[4], name[3], score[3], name[2], score[2], name[1], score[1],
    name[0], score[0], player_name, player_score, input_pos, scoreboard_state } = scoreboard_data;
	
	
	wire clk_25MHz;
	clock_divider_25MHz(clk_25MHz, clk);
	wire clk_30FPS;
	clock_divider_half(clk_30FPS, clk_25MHz);
	wire clk_frame = clk_25MHz;
	
	
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    
    vga_controller vga_inst(
      .pclk(clk_frame),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
	
	wire [11:0] pixel_bg;
	layer_background(
	.clk(clk_frame),
	.h_cnt(h_cnt),
	.v_cnt(v_cnt),
	.pixel(pixel_bg)
	);
	
	
	logic obj_layer_valid;
	logic [11:0] obj_pixel_out;
	layer_object #(.QUADRANT(QUADRANT))(
	.clk_100MHz(clk),
	.clk_frame(clk_frame),
	.obj_data(obj_data),
	.h_cnt(h_cnt),
	.v_cnt(v_cnt),
	.layer_valid(obj_layer_valid),
	.pixel_out(obj_pixel_out)
	);
	
	logic laser_layer_valid;
	logic [11:0] laser_pixel_out;
	
	layer_laser #(.QUADRANT(QUADRANT))(
	.clk(clk_frame),
	.laser_active(laser_active),
	.laser_r(laser_r),
	.laser_quadrant(laser_quadrant),
	.h_cnt(h_cnt),
	.v_cnt(v_cnt),
	.layer_valid(laser_layer_valid),
	.pixel_out(laser_pixel_out)
	);
	
	logic txt_valid;
    logic [11:0] txt_pixel_out;
    logic [STRING_SIZE*5-1:0] name_stream={name[4],name[3],name[2],name[1],name[0]};
    logic [SCORE_SIZE*5-1:0] score_stream={score[4],score[3],score[2],score[1],score[0]};
    txt_pixel(
        .clk(clk_25MHz),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .state(core_state),
        .level(level_data),
        .input_pos(input_pos),
        .player_name(player_name),
        .score(player_score),
        .player_name_record(name_stream),
        .score_record(score_stream),
        .pixel_out(txt_pixel_out),
        .valid(txt_valid)
        );

	logic [11:0] rendered_pixel;
	assign {vgaRed, vgaGreen, vgaBlue} = rendered_pixel;
    always @* begin
        rendered_pixel = pixel_bg;
        if(valid) case(core_state)
        SCENE_GAME_START: begin
            if(txt_valid) begin
                rendered_pixel =txt_pixel_out;
            end
        end
        SCENE_LEVEL_START: begin
            if(txt_valid) begin
                rendered_pixel =txt_pixel_out;
            end  
        end
        SCENE_INGAME: begin
            if(laser_layer_valid) begin
                rendered_pixel = laser_pixel_out;
            end
            else if(obj_layer_valid) begin
                rendered_pixel = obj_pixel_out;
            end
        end
        SCENE_GAME_OVER: begin
            if(txt_valid) begin
                rendered_pixel =txt_pixel_out;
            end
        end
        SCENE_SCOREBOARD: begin
            if(txt_valid) begin
                rendered_pixel =txt_pixel_out;
            end
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

module clock_divider_half(clk1, clk);
input clk;
output clk1;

reg num;
always @(posedge clk) begin
    num <= num + 1;
end
assign clk1 = num;
endmodule

