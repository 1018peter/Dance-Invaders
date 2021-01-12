`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/20 20:41:09
// Design Name: Event Core
// Module Name: event_core
// Project Name: Dance Invaders
// Target Devices: Basys3
// Tool Versions: Vivado 2020.1.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "typedefs.svh"
`include "constants.svh"

module event_core(
    input clk_frame, // Base frequency of around 30 Hz, and up to 60 Hz. Note: Any clock switching may cause frame glitches and should be handled with care.
    input clk_dsp,
    input clk_sort, // Operating frequency of the sorter
    input rst,
    input en,
    input spawn_laser, // Onepulse signal that represents a request to spawn a laser.
    input FourDir dir, // Four-direction orientation.
    input spawn_object, // Onepulse signal that represents a request to spawn a new alien.
    input Alien spawn_data,
    output [SCORE_SIZE - 1:0] score_out,
    output logic all_clear, // Signal to indicate that no aliens are active.
    output game_over,
    output logic [3:0] object_count,
	output [FRAME_DATA_SIZE - 1: 0] frame_data // The parallel bit output that contains all the information of a frame, waiting to be serialized.
    );
    logic flag_game_over;
    assign game_over = flag_game_over;
    Laser laser;
    Laser next_laser;
    logic [SCORE_SIZE - 1:0] score;
    logic [SCORE_SIZE - 1:0] next_score;
    assign score_out = score;
    Alien obj_arr [0:OBJ_LIMIT-1];
    Alien obj_arr_sorted [0:OBJ_LIMIT-1];
    odd_even_merge_sorter(
        .clk(clk_sort),
        .unordered(obj_arr),
        .ordered(obj_arr_sorted)
    );
    
    logic [15:0] frame_ctr; // Useful for cyclic behavior. "Every X frame, enter a different state"
    wire [15:0]  frame_onepulse; // Onepulse of select frames. "Every X frame, do something for 1 frame"
    generate 
    for(genvar g = 0; g < 16; g++)
        onepulse(frame_ctr[g], clk_frame, frame_onepulse[g]);
    endgenerate
    
    wire spawn_object_op;
    onepulse(spawn_object, clk_frame, spawn_object_op);
    
    always @*begin
        all_clear = 1;
        flag_game_over = 0;
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            if(obj_arr[i]._state != INACTIVE) all_clear = 0;
            if(obj_arr[i]._r == 0 && obj_arr[i]._state == ACTIVE) flag_game_over = 1;
        end
    end

    always @(posedge clk_frame, posedge rst) begin
        if(rst) begin
            frame_ctr <= 0;
        end
        else if(en) begin
            frame_ctr <= frame_ctr + 1;
        end
    end
    
    // Registered because Vivado does not like me not doing it.
    logic [3:0] r_buffer [0:OBJ_LIMIT-1];
    logic [9+14:0] result_buffer [0:OBJ_LIMIT-1];
    logic [9:0] projected_x [0:OBJ_LIMIT-1];
    logic [9:0] y_buffer [0:OBJ_LIMIT-1];
    logic [9+14:0] product_buffer [0:OBJ_LIMIT-1];
    logic [9+14:0] diff_buffer [0:OBJ_LIMIT-1];
    logic [9+14:0] reg_product [0:OBJ_LIMIT-1];
    logic [13:0] reg_sine [0:OBJ_LIMIT-1];
    logic [13:0] sine_buffer [0:OBJ_LIMIT-1];
    logic [9:0] reg_dist [0:OBJ_LIMIT-1];
    logic [9:0] dist_buffer [0:OBJ_LIMIT-1];
    logic [8:0] mapped_theta [0:OBJ_LIMIT-1];
    logic [OBJ_LIMIT-1:0] out_of_bound;
    parameter X_UNDERFLOW_GUARD = 1280000;
    always @(posedge clk_dsp) begin
        for(int k = 0; k < OBJ_LIMIT; k++) begin
            r_buffer[k] <= obj_arr_sorted[k]._r;
            mapped_theta[k] <= obj_arr_sorted[k]._theta % 90;
            reg_sine[k] <=  mapped_theta[k] < 45 ? 
        sin[45 - mapped_theta[k]] 
        : sin[mapped_theta[k] - 45];
            sine_buffer[k] <= reg_sine[k];
            reg_dist[k] <= 640 + r_buffer[k] * 10;
            dist_buffer[k] <= reg_dist[k];
            reg_product[k] <= sine_buffer[k] * dist_buffer[k];
            product_buffer[k] <= reg_product[k];
            out_of_bound[k] <= mapped_theta[k] < 45 ? (product_buffer[k] >= 3200001 + X_UNDERFLOW_GUARD) : 
            (product_buffer[k] >= 3200000 + X_UNDERFLOW_GUARD);
            diff_buffer[k] <= (mapped_theta[k] < 45 ? 3200000 + X_UNDERFLOW_GUARD - product_buffer[k] : 3200000 + X_UNDERFLOW_GUARD + product_buffer[k]);
            result_buffer[k] <= diff_buffer[k] / 10000;
            projected_x[k] <= result_buffer[k][9:0];
            y_buffer[k] <= 480 - 80 - r_buffer[k] * 15;
        end
    end
    
    // Collapse the frame into the format of { {Alien Data (Sorted by distance, headed by the closest alien}, {Laser Metadata}}
	assign frame_data[0] = laser._active;
	assign frame_data[4:1] = laser._r;
	assign frame_data[6:5] = laser._deg / 90; // Quadrant
	generate
	for(genvar k = 0; k < OBJ_LIMIT; k++) begin
	    localparam startpos = 7 + k * $size(AlienData);
        assign frame_data[startpos] = obj_arr_sorted[k]._state != INACTIVE && !out_of_bound[k];
        assign frame_data[startpos+2 :startpos+1] = obj_arr_sorted[k]._type;
        assign frame_data[startpos+4 :startpos+3] = obj_arr_sorted[k]._frame_num;
        assign frame_data[startpos+8 :startpos+5] = obj_arr_sorted[k]._r;
        assign frame_data[startpos+10:startpos+9] = obj_arr_sorted[k]._theta / 90; // (0~359)/90 -> (0~3).
        
        // x pos
        assign frame_data[startpos+20:startpos+11] = projected_x[k]; // (0~640. Validation is done in the peripheral) 
        // y pos
        assign frame_data[startpos+30:startpos+21] = y_buffer[k];
        
        // deriv left
        assign frame_data[startpos+32:startpos+31] = 
        mapped_theta[k] < 30 ? 3
        : mapped_theta[k] < 35 ? 2
        : mapped_theta[k] < 40 ? 1
        : mapped_theta[k] < 50 ? 0
        : mapped_theta[k] < 55 ? 1
        : 2 ;
        
        // deriv right
        assign frame_data[startpos+34:startpos+33] = 
        mapped_theta[k] > 55 ? 3
        : mapped_theta[k] > 50 ? 2
        : mapped_theta[k] > 40 ? 1
        : mapped_theta[k] > 35 ? 0
        : mapped_theta[k] > 30 ? 1
        : 2 ;
        
        
    end
	endgenerate
	
    always @(posedge clk_frame, posedge rst) begin
        if(rst) begin
            object_count <= 0;
            for(int i = 0; i < OBJ_LIMIT; i++) begin
                obj_arr[i]._r <= R_LIMIT;
                obj_arr[i]._theta <= 0;
                obj_arr[i]._hp <= 0;
                obj_arr[i]._state <= INACTIVE;
                obj_arr[i]._type <= TYPE0;
                obj_arr[i]._frame_num <= 0;
            end
            laser._active <= 0;
            score <= 0;
        end
        else if(en) begin // Enabled: Keep advancing frames.
            // Updating every object.
            for(int i = 0; i < OBJ_LIMIT; i++) begin
                case(obj_arr[i]._state)
                ACTIVE: begin // Object is active. Move.
                    if (frame_onepulse[7]) begin // Move forward once every 128 frames.
                        obj_arr[i]._r <= obj_arr[i]._r - 1;
                        
                    end
                    
                    if(frame_onepulse[4]) obj_arr[i]._frame_num[0] <= obj_arr[i]._frame_num[0] ^ 1;
                    
                    if(frame_ctr[0]) case(obj_arr[i]._type)
                    TYPE0: begin // Type 0: Basic alien. Circles in a simple pattern.
                        // Movement behavior description.
                        if (frame_ctr[6]) begin // Move counterclockwise.
                            if(obj_arr[i]._theta == 0) obj_arr[i]._theta <= 359;
                            else obj_arr[i]._theta <= obj_arr[i]._theta - 1;
                        end
                        else begin // Move clockwise.
                            if(obj_arr[i]._theta == 359) obj_arr[i]._theta <= 0;
                            else obj_arr[i]._theta <= obj_arr[i]._theta + 1;
                        end
                    end
                    TYPE1: begin // Type 1: The inverse of Type 0. Circles in a simple pattern, but in opposite directions.
                        // Movement behavior description.
                        if (!frame_ctr[6]) begin // Move counterclockwise.
                            if(obj_arr[i]._theta == 0) obj_arr[i]._theta <= 359;
                            else obj_arr[i]._theta <= obj_arr[i]._theta - 1;
                        end
                        else begin // Move clockwise.
                            if(obj_arr[i]._theta == 359) obj_arr[i]._theta <= 0;
                            else obj_arr[i]._theta <= obj_arr[i]._theta + 1;
                        end
                    end
                    TYPE2: begin // Type 2: Advanced alien. Moves faster than Type 0/1, but only moves clockwise.
                        // Every second frame, moves by 2 steps instead of 1. This results in it being 50% faster than Type 0/1.
                        if(frame_ctr[0]) begin
                            if(obj_arr[i]._theta == 358) obj_arr[i]._theta <= 0;
                            else if(obj_arr[i]._theta == 359) obj_arr[i]._theta <= 1;
                            else obj_arr[i]._theta <= obj_arr[i]._theta + 2;
                        end
                        else begin
                            if(obj_arr[i]._theta == 359) obj_arr[i]._theta <= 0;
                            else obj_arr[i]._theta <= obj_arr[i]._theta + 1;
                        end
                    end
                    TYPE3: begin // Inverse of type 2.
                        // Every second frame, moves by 2 steps instead of 1. This results in it being 50% faster than Type 0/1.
                        if(frame_ctr[0]) begin
                            if(obj_arr[i]._theta == 0) obj_arr[i]._theta <= 358;
                            else if(obj_arr[i]._theta == 1) obj_arr[i]._theta <= 359;
                            else obj_arr[i]._theta <= obj_arr[i]._theta - 2;
                        end
                        else begin
                            if(obj_arr[i]._theta == 0) obj_arr[i]._theta <= 359;
                            else obj_arr[i]._theta <= obj_arr[i]._theta - 1;
                        end
                    end
                    endcase
                    
                    
                end
                DYING: begin // death animation
                    if (frame_onepulse[2]) 
                        if(obj_arr[i]._frame_num == 3) obj_arr[i]._state <= INACTIVE;
                        else obj_arr[i]._frame_num <= obj_arr[i]._frame_num + 1;
                    
                end
                endcase
            end
            
            if(laser._active) begin
                for(int i = 0; i < OBJ_LIMIT; i++) begin
                    // Test collision with priority encoding.
                    if(obj_arr[i]._state == ACTIVE && obj_arr[i]._r <= laser._r + 1
                    && obj_arr[i]._theta <= laser._deg + LSR_WIDTH
                    && obj_arr[i]._theta >= laser._deg - LSR_WIDTH) begin 
                        if(obj_arr[i]._hp == 1) begin
                            obj_arr[i]._state <= DYING;
                            obj_arr[i]._frame_num <= 2; // Advance to death animation frames.
                            object_count <= object_count - 1;
                        end
                        obj_arr[i]._hp <= obj_arr[i]._hp - 1;
                        break;
                    end
                end
            end 
            laser <= next_laser;
            score <= next_score;
            
            // Spawning a new object if requested.
            if(spawn_object_op) begin
                object_count <= object_count + 1;
                // Priority encoding to achieve linear scan.
                for(int i = 0; i < OBJ_LIMIT; i++) begin
                    if(obj_arr[i]._state == INACTIVE) begin
                        obj_arr[i] <= spawn_data;
                        break;
                    end
                end
            end
            
        end
    end
    
    
    // Guess who had to wrestle with multi-driven nets?
    always@* begin
        next_score = score;
        next_laser = laser;
        if(laser._active) begin // Move laser, keeping the same orientation.
            next_laser._r = laser._r + 1;
            
            if(laser._r == 15) next_laser._active = 0;
            else for(int i = 0; i < OBJ_LIMIT; i++) begin
                // Test collision with priority encoding.
                if(obj_arr[i]._state == ACTIVE && obj_arr[i]._r <= laser._r + 1
                && obj_arr[i]._theta <= laser._deg + LSR_WIDTH
                && obj_arr[i]._theta >= laser._deg - LSR_WIDTH) begin 
                    if(obj_arr[i]._hp == 1) begin
                        next_score = score + 100;
                    end
                    else begin 
                        next_score = score + 10;
                    end
                    next_laser._active = 0;
                    //break;
                end
            end
        end 
        else if(spawn_laser) begin // Spawning a new laser if requested.
            next_laser._r = 0;
            next_laser._deg = dir * 90 + 45;
            next_laser._active = 1;
        end
    end
    
endmodule

// Sorter that sorts by distance.
module odd_even_merge_sorter(
    input clk,
    input Alien unordered [0: OBJ_LIMIT-1],
    output Alien ordered[0: OBJ_LIMIT-1]
);

    logic [4:0] sort_layer [0:10][0:OBJ_LIMIT-1];
    logic [3:0] key_layer [0:10][0:OBJ_LIMIT-1];
    always @* begin
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            sort_layer[0][i] = i;
            key_layer[0][i] = unordered[i]._r;
        end
    end
    
    always @(posedge clk) begin
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            ordered[i] <= unordered[sort_layer[10][i]];
        end
    end
    
// Python manages to be a better macro system than the generate statement. Seriously, every genvar must have a matching for-loop? Just, f**cking why!?
alien_comparator(key_layer[0][0], key_layer[0][1], sort_layer[0][0],sort_layer[0][1], key_layer[1][0], key_layer[1][1], sort_layer[1][0], sort_layer[1][1]);
alien_comparator(key_layer[0][2], key_layer[0][3], sort_layer[0][2],sort_layer[0][3], key_layer[1][2], key_layer[1][3], sort_layer[1][2], sort_layer[1][3]);
alien_comparator(key_layer[0][4], key_layer[0][5], sort_layer[0][4],sort_layer[0][5], key_layer[1][4], key_layer[1][5], sort_layer[1][4], sort_layer[1][5]);
alien_comparator(key_layer[0][6], key_layer[0][7], sort_layer[0][6],sort_layer[0][7], key_layer[1][6], key_layer[1][7], sort_layer[1][6], sort_layer[1][7]);
alien_comparator(key_layer[0][8], key_layer[0][9], sort_layer[0][8],sort_layer[0][9], key_layer[1][8], key_layer[1][9], sort_layer[1][8], sort_layer[1][9]);
alien_comparator(key_layer[0][10], key_layer[0][11], sort_layer[0][10],sort_layer[0][11], key_layer[1][10], key_layer[1][11], sort_layer[1][10], sort_layer[1][11]);
alien_comparator(key_layer[0][12], key_layer[0][13], sort_layer[0][12],sort_layer[0][13], key_layer[1][12], key_layer[1][13], sort_layer[1][12], sort_layer[1][13]);
alien_comparator(key_layer[0][14], key_layer[0][15], sort_layer[0][14],sort_layer[0][15], key_layer[1][14], key_layer[1][15], sort_layer[1][14], sort_layer[1][15]);
alien_comparator(key_layer[1][0], key_layer[1][2], sort_layer[1][0],sort_layer[1][2], key_layer[2][0], key_layer[2][2], sort_layer[2][0], sort_layer[2][2]);
alien_comparator(key_layer[1][1], key_layer[1][3], sort_layer[1][1],sort_layer[1][3], key_layer[2][1], key_layer[2][3], sort_layer[2][1], sort_layer[2][3]);
alien_comparator(key_layer[1][4], key_layer[1][6], sort_layer[1][4],sort_layer[1][6], key_layer[2][4], key_layer[2][6], sort_layer[2][4], sort_layer[2][6]);
alien_comparator(key_layer[1][5], key_layer[1][7], sort_layer[1][5],sort_layer[1][7], key_layer[2][5], key_layer[2][7], sort_layer[2][5], sort_layer[2][7]);
alien_comparator(key_layer[1][8], key_layer[1][10], sort_layer[1][8],sort_layer[1][10], key_layer[2][8], key_layer[2][10], sort_layer[2][8], sort_layer[2][10]);
alien_comparator(key_layer[1][9], key_layer[1][11], sort_layer[1][9],sort_layer[1][11], key_layer[2][9], key_layer[2][11], sort_layer[2][9], sort_layer[2][11]);
alien_comparator(key_layer[1][12], key_layer[1][14], sort_layer[1][12],sort_layer[1][14], key_layer[2][12], key_layer[2][14], sort_layer[2][12], sort_layer[2][14]);
alien_comparator(key_layer[1][13], key_layer[1][15], sort_layer[1][13],sort_layer[1][15], key_layer[2][13], key_layer[2][15], sort_layer[2][13], sort_layer[2][15]);
alien_comparator(key_layer[2][1], key_layer[2][2], sort_layer[2][1],sort_layer[2][2], key_layer[3][1], key_layer[3][2], sort_layer[3][1], sort_layer[3][2]);
alien_comparator(key_layer[2][5], key_layer[2][6], sort_layer[2][5],sort_layer[2][6], key_layer[3][5], key_layer[3][6], sort_layer[3][5], sort_layer[3][6]);
alien_comparator(key_layer[2][9], key_layer[2][10], sort_layer[2][9],sort_layer[2][10], key_layer[3][9], key_layer[3][10], sort_layer[3][9], sort_layer[3][10]);
alien_comparator(key_layer[2][13], key_layer[2][14], sort_layer[2][13],sort_layer[2][14], key_layer[3][13], key_layer[3][14], sort_layer[3][13], sort_layer[3][14]);
assign sort_layer[3][0] = sort_layer[2][0];
assign key_layer[3][0] = key_layer[2][0];
assign sort_layer[3][3] = sort_layer[2][3];
assign key_layer[3][3] = key_layer[2][3];
assign sort_layer[3][4] = sort_layer[2][4];
assign key_layer[3][4] = key_layer[2][4];
assign sort_layer[3][7] = sort_layer[2][7];
assign key_layer[3][7] = key_layer[2][7];
assign sort_layer[3][8] = sort_layer[2][8];
assign key_layer[3][8] = key_layer[2][8];
assign sort_layer[3][11] = sort_layer[2][11];
assign key_layer[3][11] = key_layer[2][11];
assign sort_layer[3][12] = sort_layer[2][12];
assign key_layer[3][12] = key_layer[2][12];
assign sort_layer[3][15] = sort_layer[2][15];
assign key_layer[3][15] = key_layer[2][15];
alien_comparator(key_layer[3][0], key_layer[3][4], sort_layer[3][0],sort_layer[3][4], key_layer[4][0], key_layer[4][4], sort_layer[4][0], sort_layer[4][4]);
alien_comparator(key_layer[3][1], key_layer[3][5], sort_layer[3][1],sort_layer[3][5], key_layer[4][1], key_layer[4][5], sort_layer[4][1], sort_layer[4][5]);
alien_comparator(key_layer[3][2], key_layer[3][6], sort_layer[3][2],sort_layer[3][6], key_layer[4][2], key_layer[4][6], sort_layer[4][2], sort_layer[4][6]);
alien_comparator(key_layer[3][3], key_layer[3][7], sort_layer[3][3],sort_layer[3][7], key_layer[4][3], key_layer[4][7], sort_layer[4][3], sort_layer[4][7]);
alien_comparator(key_layer[3][8], key_layer[3][12], sort_layer[3][8],sort_layer[3][12], key_layer[4][8], key_layer[4][12], sort_layer[4][8], sort_layer[4][12]);
alien_comparator(key_layer[3][9], key_layer[3][13], sort_layer[3][9],sort_layer[3][13], key_layer[4][9], key_layer[4][13], sort_layer[4][9], sort_layer[4][13]);
alien_comparator(key_layer[3][10], key_layer[3][14], sort_layer[3][10],sort_layer[3][14], key_layer[4][10], key_layer[4][14], sort_layer[4][10], sort_layer[4][14]);
alien_comparator(key_layer[3][11], key_layer[3][15], sort_layer[3][11],sort_layer[3][15], key_layer[4][11], key_layer[4][15], sort_layer[4][11], sort_layer[4][15]);
alien_comparator(key_layer[4][2], key_layer[4][4], sort_layer[4][2],sort_layer[4][4], key_layer[5][2], key_layer[5][4], sort_layer[5][2], sort_layer[5][4]);
alien_comparator(key_layer[4][3], key_layer[4][5], sort_layer[4][3],sort_layer[4][5], key_layer[5][3], key_layer[5][5], sort_layer[5][3], sort_layer[5][5]);
alien_comparator(key_layer[4][10], key_layer[4][12], sort_layer[4][10],sort_layer[4][12], key_layer[5][10], key_layer[5][12], sort_layer[5][10], sort_layer[5][12]);
alien_comparator(key_layer[4][11], key_layer[4][13], sort_layer[4][11],sort_layer[4][13], key_layer[5][11], key_layer[5][13], sort_layer[5][11], sort_layer[5][13]);
assign sort_layer[5][0] = sort_layer[4][0];
assign key_layer[5][0] = key_layer[4][0];
assign sort_layer[5][1] = sort_layer[4][1];
assign key_layer[5][1] = key_layer[4][1];
assign sort_layer[5][6] = sort_layer[4][6];
assign key_layer[5][6] = key_layer[4][6];
assign sort_layer[5][7] = sort_layer[4][7];
assign key_layer[5][7] = key_layer[4][7];
assign sort_layer[5][8] = sort_layer[4][8];
assign key_layer[5][8] = key_layer[4][8];
assign sort_layer[5][9] = sort_layer[4][9];
assign key_layer[5][9] = key_layer[4][9];
assign sort_layer[5][14] = sort_layer[4][14];
assign key_layer[5][14] = key_layer[4][14];
assign sort_layer[5][15] = sort_layer[4][15];
assign key_layer[5][15] = key_layer[4][15];
alien_comparator(key_layer[5][1], key_layer[5][2], sort_layer[5][1],sort_layer[5][2], key_layer[6][1], key_layer[6][2], sort_layer[6][1], sort_layer[6][2]);
alien_comparator(key_layer[5][3], key_layer[5][4], sort_layer[5][3],sort_layer[5][4], key_layer[6][3], key_layer[6][4], sort_layer[6][3], sort_layer[6][4]);
alien_comparator(key_layer[5][5], key_layer[5][6], sort_layer[5][5],sort_layer[5][6], key_layer[6][5], key_layer[6][6], sort_layer[6][5], sort_layer[6][6]);
alien_comparator(key_layer[5][9], key_layer[5][10], sort_layer[5][9],sort_layer[5][10], key_layer[6][9], key_layer[6][10], sort_layer[6][9], sort_layer[6][10]);
alien_comparator(key_layer[5][11], key_layer[5][12], sort_layer[5][11],sort_layer[5][12], key_layer[6][11], key_layer[6][12], sort_layer[6][11], sort_layer[6][12]);
alien_comparator(key_layer[5][13], key_layer[5][14], sort_layer[5][13],sort_layer[5][14], key_layer[6][13], key_layer[6][14], sort_layer[6][13], sort_layer[6][14]);
assign sort_layer[6][0] = sort_layer[5][0];
assign key_layer[6][0] = key_layer[5][0];
assign sort_layer[6][7] = sort_layer[5][7];
assign key_layer[6][7] = key_layer[5][7];
assign sort_layer[6][8] = sort_layer[5][8];
assign key_layer[6][8] = key_layer[5][8];
assign sort_layer[6][15] = sort_layer[5][15];
assign key_layer[6][15] = key_layer[5][15];
alien_comparator(key_layer[6][0], key_layer[6][8], sort_layer[6][0],sort_layer[6][8], key_layer[7][0], key_layer[7][8], sort_layer[7][0], sort_layer[7][8]);
alien_comparator(key_layer[6][1], key_layer[6][9], sort_layer[6][1],sort_layer[6][9], key_layer[7][1], key_layer[7][9], sort_layer[7][1], sort_layer[7][9]);
alien_comparator(key_layer[6][2], key_layer[6][10], sort_layer[6][2],sort_layer[6][10], key_layer[7][2], key_layer[7][10], sort_layer[7][2], sort_layer[7][10]);
alien_comparator(key_layer[6][3], key_layer[6][11], sort_layer[6][3],sort_layer[6][11], key_layer[7][3], key_layer[7][11], sort_layer[7][3], sort_layer[7][11]);
alien_comparator(key_layer[6][4], key_layer[6][12], sort_layer[6][4],sort_layer[6][12], key_layer[7][4], key_layer[7][12], sort_layer[7][4], sort_layer[7][12]);
alien_comparator(key_layer[6][5], key_layer[6][13], sort_layer[6][5],sort_layer[6][13], key_layer[7][5], key_layer[7][13], sort_layer[7][5], sort_layer[7][13]);
alien_comparator(key_layer[6][6], key_layer[6][14], sort_layer[6][6],sort_layer[6][14], key_layer[7][6], key_layer[7][14], sort_layer[7][6], sort_layer[7][14]);
alien_comparator(key_layer[6][7], key_layer[6][15], sort_layer[6][7],sort_layer[6][15], key_layer[7][7], key_layer[7][15], sort_layer[7][7], sort_layer[7][15]);
alien_comparator(key_layer[7][4], key_layer[7][8], sort_layer[7][4],sort_layer[7][8], key_layer[8][4], key_layer[8][8], sort_layer[8][4], sort_layer[8][8]);
alien_comparator(key_layer[7][5], key_layer[7][9], sort_layer[7][5],sort_layer[7][9], key_layer[8][5], key_layer[8][9], sort_layer[8][5], sort_layer[8][9]);
alien_comparator(key_layer[7][6], key_layer[7][10], sort_layer[7][6],sort_layer[7][10], key_layer[8][6], key_layer[8][10], sort_layer[8][6], sort_layer[8][10]);
alien_comparator(key_layer[7][7], key_layer[7][11], sort_layer[7][7],sort_layer[7][11], key_layer[8][7], key_layer[8][11], sort_layer[8][7], sort_layer[8][11]);
assign sort_layer[8][0] = sort_layer[7][0];
assign key_layer[8][0] = key_layer[7][0];
assign sort_layer[8][1] = sort_layer[7][1];
assign key_layer[8][1] = key_layer[7][1];
assign sort_layer[8][2] = sort_layer[7][2];
assign key_layer[8][2] = key_layer[7][2];
assign sort_layer[8][3] = sort_layer[7][3];
assign key_layer[8][3] = key_layer[7][3];
assign sort_layer[8][12] = sort_layer[7][12];
assign key_layer[8][12] = key_layer[7][12];
assign sort_layer[8][13] = sort_layer[7][13];
assign key_layer[8][13] = key_layer[7][13];
assign sort_layer[8][14] = sort_layer[7][14];
assign key_layer[8][14] = key_layer[7][14];
assign sort_layer[8][15] = sort_layer[7][15];
assign key_layer[8][15] = key_layer[7][15];
alien_comparator(key_layer[8][2], key_layer[8][4], sort_layer[8][2],sort_layer[8][4], key_layer[9][2], key_layer[9][4], sort_layer[9][2], sort_layer[9][4]);
alien_comparator(key_layer[8][3], key_layer[8][5], sort_layer[8][3],sort_layer[8][5], key_layer[9][3], key_layer[9][5], sort_layer[9][3], sort_layer[9][5]);
alien_comparator(key_layer[8][6], key_layer[8][8], sort_layer[8][6],sort_layer[8][8], key_layer[9][6], key_layer[9][8], sort_layer[9][6], sort_layer[9][8]);
alien_comparator(key_layer[8][7], key_layer[8][9], sort_layer[8][7],sort_layer[8][9], key_layer[9][7], key_layer[9][9], sort_layer[9][7], sort_layer[9][9]);
alien_comparator(key_layer[8][10], key_layer[8][12], sort_layer[8][10],sort_layer[8][12], key_layer[9][10], key_layer[9][12], sort_layer[9][10], sort_layer[9][12]);
alien_comparator(key_layer[8][11], key_layer[8][13], sort_layer[8][11],sort_layer[8][13], key_layer[9][11], key_layer[9][13], sort_layer[9][11], sort_layer[9][13]);
assign sort_layer[9][0] = sort_layer[8][0];
assign key_layer[9][0] = key_layer[8][0];
assign sort_layer[9][1] = sort_layer[8][1];
assign key_layer[9][1] = key_layer[8][1];
assign sort_layer[9][14] = sort_layer[8][14];
assign key_layer[9][14] = key_layer[8][14];
assign sort_layer[9][15] = sort_layer[8][15];
assign key_layer[9][15] = key_layer[8][15];
alien_comparator(key_layer[9][1], key_layer[9][2], sort_layer[9][1],sort_layer[9][2], key_layer[10][1], key_layer[10][2], sort_layer[10][1], sort_layer[10][2]);
alien_comparator(key_layer[9][3], key_layer[9][4], sort_layer[9][3],sort_layer[9][4], key_layer[10][3], key_layer[10][4], sort_layer[10][3], sort_layer[10][4]);
alien_comparator(key_layer[9][5], key_layer[9][6], sort_layer[9][5],sort_layer[9][6], key_layer[10][5], key_layer[10][6], sort_layer[10][5], sort_layer[10][6]);
alien_comparator(key_layer[9][7], key_layer[9][8], sort_layer[9][7],sort_layer[9][8], key_layer[10][7], key_layer[10][8], sort_layer[10][7], sort_layer[10][8]);
alien_comparator(key_layer[9][9], key_layer[9][10], sort_layer[9][9],sort_layer[9][10], key_layer[10][9], key_layer[10][10], sort_layer[10][9], sort_layer[10][10]);
alien_comparator(key_layer[9][11], key_layer[9][12], sort_layer[9][11],sort_layer[9][12], key_layer[10][11], key_layer[10][12], sort_layer[10][11], sort_layer[10][12]);
alien_comparator(key_layer[9][13], key_layer[9][14], sort_layer[9][13],sort_layer[9][14], key_layer[10][13], key_layer[10][14], sort_layer[10][13], sort_layer[10][14]);
assign sort_layer[10][0] = sort_layer[9][0];
assign key_layer[10][0] = key_layer[9][0];
assign sort_layer[10][15] = sort_layer[9][15];
assign key_layer[10][15] = key_layer[9][15];
endmodule

module alien_comparator(
    input [3:0] key_in_0,
    input [3:0] key_in_1,
    input [4:0] in_0,
    input [4:0] in_1,
    output logic [3:0] key_out_0,
    output logic [3:0] key_out_1,
    output logic [4:0] out_0,
    output logic [4:0] out_1
);
    always @* begin
        if(key_in_0 < key_in_1) begin
            out_0 = in_0;
            out_1 = in_1;
            key_out_0 = key_in_0;
            key_out_1 = key_in_1;
        end
        else begin
            out_0 = in_1;
            out_1 = in_0;
            key_out_0 = key_in_1;
            key_out_1 = key_in_0;
        end
    end

endmodule