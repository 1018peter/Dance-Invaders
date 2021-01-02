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
	output [OBJ_LIMIT * $size(AlienData) + $size(Laser) - 1: 0] frame_data // The parallel bit output that contains all the information of a frame, waiting to be serialized.
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
        .unsorted(obj_arr),
        .sorted(obj_arr_sorted)
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
    
    wire [9:0] projected_x [0:OBJ_LIMIT-1];
    wire [8:0] mapped_theta [0:OBJ_LIMIT-1];
    // Collapse the frame into the format of { {Alien Data (Sorted by distance, headed by the closest alien}, {Laser Metadata}}
	assign frame_data[0] = laser._active;
	assign frame_data[4:1] = laser._r;
	assign frame_data[13:5] = laser._deg;
	generate
	for(genvar k = 0; k < OBJ_LIMIT; k++) begin
	    localparam startpos = 14 + k * $size(AlienData);
        assign frame_data[startpos] = obj_arr_sorted[k]._state != INACTIVE;
        assign frame_data[startpos+2 :startpos+1] = obj_arr_sorted[k]._type;
        assign frame_data[startpos+4 :startpos+3] = obj_arr_sorted[k]._frame_num;
        assign frame_data[startpos+8 :startpos+5] = obj_arr_sorted[k]._r;
        assign frame_data[startpos+10:startpos+9] = obj_arr_sorted[k]._theta / 90; // (0~359)/90 -> (0~3).
        
        assign mapped_theta[k] = obj_arr_sorted[k]._theta % 90;
        assign projected_x[k] = 320 + (mapped_theta[k] < 45 ? 
        -sin[45 - mapped_theta[k]] 
        : sin[mapped_theta[k] - 45]) / 10000 * (640 + obj_arr_sorted[k]._r * 10);
        
        // x pos
        assign frame_data[startpos+20:startpos+11] = projected_x[k]; // (0~640. Validation is done in the peripheral) 
        // y pos
        assign frame_data[startpos+30:startpos+21] = 80 + obj_arr_sorted[k]._r * 15;
        
        // deriv left
        assign frame_data[startpos+32:startpos+31] = 
        mapped_theta[k] < 33 ? 3
        : mapped_theta[k] < 37 ? 2
        : mapped_theta[k] < 40 ? 1
        : mapped_theta[k] < 50 ? 0
        : mapped_theta[k] < 55 ? 1
        : 2 ;
        
        // deriv right
        assign frame_data[startpos+34:startpos+33] = 
        mapped_theta[k] > 57 ? 3
        : mapped_theta[k] > 53 ? 2
        : mapped_theta[k] > 50 ? 1
        : mapped_theta[k] > 40 ? 0
        : mapped_theta[k] > 35 ? 1
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
                    
                    case(obj_arr[i]._type)
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
                if(laser._r != 15) for(int i = 0; i < OBJ_LIMIT; i++) begin
                    // Test collision with priority encoding.
                    if(obj_arr[i]._state == ACTIVE && obj_arr[i]._r == laser._r
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
                    if(obj_arr[i]._state == ACTIVE && obj_arr[i]._r == laser._r
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
        else begin // Spawning a new laser if requested.
            next_laser._r = 0;
            next_laser._deg = dir * 90 + 45;
            next_laser._active = spawn_laser;
        end
    end
    
endmodule

// Sorter that sorts by distance.
module odd_even_merge_sorter(
    input clk,
    input Alien unordered [0: OBJ_LIMIT-1],
    output Alien ordered[0: OBJ_LIMIT-1]
);

    logic [4:0] sort_layer [0:5][0:OBJ_LIMIT-1];
    
    always @* begin
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            sort_layer[0][i] = i;
            ordered[i] = unordered[sort_layer[5][i]];
        end
    end
    
    always @(posedge clk) begin
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            ordered[i] <= unordered[sort_layer[5][i]];
        end
    end
    
    generate
    for(genvar p = 1; p < OBJ_LIMIT; p = p << 1) begin
        for(genvar k = p; k >= 1; k = k >> 1) begin
            for(genvar j = k % p; j < OBJ_LIMIT-k; j = j + 2 * k) begin
                for(genvar i = 0; i < k; i++) begin
                    if( (i+j) / (2 * p) == (i + j + k) / (2 * p) ) begin
                        alien_comparator(unordered, sort_layer[$clog2(p)][i+j], sort_layer[$clog2(p)][i+j+k], 
                        sort_layer[$clog2(p) + 1][i+j], sort_layer[$clog2(p) + 1][i+j+k]);
                    end
                    else begin
                        assign sort_layer[$clog2(p) + 1][i+j]   = sort_layer[$clog2(p)][i+j];
                        assign sort_layer[$clog2(p) + 1][i+j+k] = sort_layer[$clog2(p)][i+j+k];
                    end
                end
            end
        end
    end
    endgenerate 

endmodule

module alien_comparator(
    input Alien key_ref [0: OBJ_LIMIT-1],
    input [4:0] in_0,
    input [4:0] in_1,
    output logic [4:0] out_0,
    output logic [4:0] out_1
);
    always @* begin
        if(key_ref[in_0]._r < key_ref[in_1]._r) begin
            out_0 = in_0;
            out_1 = in_1;
        end
        else begin
            out_0 = in_1;
            out_1 = in_0;
        end
    end

endmodule