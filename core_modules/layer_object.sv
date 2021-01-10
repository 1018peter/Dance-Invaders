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
    input clk_100MHz,
    input clk_frame,
    input AlienData obj_data [0:OBJ_LIMIT-1],
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output logic layer_valid,
    output logic [11:0] pixel_out
    );
    parameter QUADRANT = 0;
    parameter VGA_XRES = 640;
    parameter VGA_YRES = 480;
    wire clk_50MHz;
    clock_divider_half(
    clk_50MHz, clk_100MHz
    );
    
    wire [10:0] pixel_addr [0:OBJ_LIMIT-1];
	wire pixel_valid [0:OBJ_LIMIT-1];
	wire in_frame [0:OBJ_LIMIT-1];
	wire [1:0] deriv_select [0:OBJ_LIMIT-1];
	generate
        for(genvar g = 0; g < OBJ_LIMIT; g++)
            alien_renderer #(.QUADRANT(QUADRANT))(
            .clk(clk_50MHz),
            .h_cnt(h_cnt),
            .v_cnt(v_cnt),
            .obj_data(obj_data[g]),
            .pixel_addr(pixel_addr[g]),
            .deriv_select(deriv_select[g]),
            .in_frame(in_frame[g]),
            .valid(pixel_valid[g])
            );
	endgenerate
	
	wire [OBJ_LIMIT-1:0] pixel_valid_unpacked;
	generate
	   for(genvar g = 0; g < OBJ_LIMIT; g++)
	       assign pixel_valid_unpacked[g] = pixel_valid[g];
	endgenerate
	
	logic [3:0] distance [0:OBJ_LIMIT-1];
	logic [1:0] alien_type [0:OBJ_LIMIT-1];
	logic [1:0] frame_num [0:OBJ_LIMIT-1];
	always @* begin
	   for(int i = 0; i < OBJ_LIMIT; ++i) begin
	       distance[i] = obj_data[i]._r;
	       alien_type[i] = obj_data[i]._type;
	       frame_num[i] = obj_data[i]._frame_num;
	   end
	end
	
	logic [3:0] init_select [0:3];
	logic [3:0] init_select_buf [0:3];
	logic [3:0] select_end;
	always @* begin
	   init_select[0] = 0;
	   for(int i = 0; i < OBJ_LIMIT; ++i) begin
	       if(in_frame[i]) begin
	           init_select[0] = i;
	           break;
	       end
	   end
	   select_end = 0;
	   for(int i = OBJ_LIMIT-1; i >= 0; --i) begin
	       if(in_frame[i]) begin
	           select_end = i;
	           break;
	       end
	   end
	   
	   for(int g = 1; g < 4; ++g) begin
	       init_select[g] = init_select[g-1];
	       for(int i = 0; i < OBJ_LIMIT; ++i) begin
	           if(in_frame[i] && i > init_select[g-1]) begin
	               init_select[g] = i;
	               break;
	           end
	       end
	   end
	end
	
	
	
	logic [3:0] alien_select [0:3];
	
	always @* begin
	   alien_select = init_select_buf;
	end
	
	logic select_reset = 0;
	always @(posedge clk_50MHz) begin
	   if(h_cnt == VGA_XRES - 1 && v_cnt == VGA_YRES - 1) begin
           init_select_buf <= init_select;
       end
	end
	
	wire [3:0] palette;
	wire [18:0] addr [0:3];
	generate
	   for(genvar g = 0; g < 4; ++g) begin
	       alien_pixel_reader(
            .clk(clk_frame),
            .frame_num(frame_num[alien_select[g]]),
            .alien_type(alien_type[alien_select[g]]),
            .size_select(distance[alien_select[g]]),
            .deriv_select(deriv_select[alien_select[g]]),
            .read_addr(pixel_addr[alien_select[g]]),
            .addr_out(addr[g])
	       );
	   end
	endgenerate
	
	
	alien_block_mem ABM0(
	.clka(clk_frame),
	.addra(addr[0]),
	.douta(palette[0]),
	.clkb(clk_frame),
	.addrb(addr[1]),
	.doutb(palette[1])
	);
	
	alien_block_mem ABM1(
	.clka(clk_frame),
	.addra(addr[2]),
	.douta(palette[2]),
	.clkb(clk_frame),
	.addrb(addr[3]),
	.doutb(palette[3])
	);
	
	always @* begin
	    pixel_out = 0;
	    layer_valid = 0;
	    for(int i = 0; i < 4; ++i) begin
	       if(pixel_valid[alien_select[i]] && ((!palette[i] && deriv_select[alien_select[i]] <= 1 && alien_type[alien_select[i]] > 1)
	       || (palette[i] && alien_type[alien_select[i]] <= 1))) begin
	           layer_valid = 1;
	           if(frame_num[alien_select[i]] <= 1) 
                   case(alien_type[alien_select[i]])
                    0: pixel_out = { 4'h4 - (distance[i] >> 3), 4'h4 - (distance[i] >> 3), 4'hF - distance[i] };
                    1: pixel_out = { 4'h4 - (distance[i] >> 3), 4'hF - distance[i], 4'h4 - (distance[i] >> 3) };
                    2: pixel_out = { 4'hF - distance[i], 4'h4 - (distance[i] >> 3), 4'h4 - (distance[i] >> 3) };
                    3: pixel_out = { 4'hF - distance[i], 4'h4 - (distance[i] >> 3), 4'hF - distance[i] };
                   endcase
               else pixel_out = 12'h2_2_2;
               break;
	       end
	    end
	    
	end
endmodule
