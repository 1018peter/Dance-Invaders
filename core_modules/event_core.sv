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
    
    wire [9:0] projected_x [0:OBJ_LIMIT-1];
    wire [8:0] mapped_theta [0:OBJ_LIMIT-1];
    // Collapse the frame into the format of { {Alien Data (Sorted by distance, headed by the closest alien}, {Laser Metadata}}
	assign frame_data[0] = laser._active;
	assign frame_data[4:1] = laser._r;
	assign frame_data[6:5] = laser._deg / 90; // Quadrant
	generate
	for(genvar k = 0; k < OBJ_LIMIT; k++) begin
	    localparam startpos = 7 + k * $size(AlienData);
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
        assign frame_data[startpos+30:startpos+21] = 480 - 80 - obj_arr_sorted[k]._r * 15;
        
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

    logic [4:0] sort_layer [0:15][0:OBJ_LIMIT-1];
    logic [3:0] key_ref [0: OBJ_LIMIT-1];
    always @* begin
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            sort_layer[0][i] = i;
            key_ref[i] = unordered[i]._r;
        end
    end
    
    always @(posedge clk) begin
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            ordered[i] <= unordered[sort_layer[15][i]];
        end
    end
    
// Python manages to be a better macro system than the generate statement. Seriously, every genvar must have a matching for-loop? Just, f**cking why!?
alien_comparator(key_ref, sort_layer[0][0],sort_layer[0][1], sort_layer[1][0], sort_layer[1][1]);
alien_comparator(key_ref, sort_layer[0][2],sort_layer[0][3], sort_layer[1][2], sort_layer[1][3]);
alien_comparator(key_ref, sort_layer[0][4],sort_layer[0][5], sort_layer[1][4], sort_layer[1][5]);
alien_comparator(key_ref, sort_layer[0][6],sort_layer[0][7], sort_layer[1][6], sort_layer[1][7]);
alien_comparator(key_ref, sort_layer[0][8],sort_layer[0][9], sort_layer[1][8], sort_layer[1][9]);
alien_comparator(key_ref, sort_layer[0][10],sort_layer[0][11], sort_layer[1][10], sort_layer[1][11]);
alien_comparator(key_ref, sort_layer[0][12],sort_layer[0][13], sort_layer[1][12], sort_layer[1][13]);
alien_comparator(key_ref, sort_layer[0][14],sort_layer[0][15], sort_layer[1][14], sort_layer[1][15]);
alien_comparator(key_ref, sort_layer[0][16],sort_layer[0][17], sort_layer[1][16], sort_layer[1][17]);
alien_comparator(key_ref, sort_layer[0][18],sort_layer[0][19], sort_layer[1][18], sort_layer[1][19]);
alien_comparator(key_ref, sort_layer[0][20],sort_layer[0][21], sort_layer[1][20], sort_layer[1][21]);
alien_comparator(key_ref, sort_layer[0][22],sort_layer[0][23], sort_layer[1][22], sort_layer[1][23]);
alien_comparator(key_ref, sort_layer[0][24],sort_layer[0][25], sort_layer[1][24], sort_layer[1][25]);
alien_comparator(key_ref, sort_layer[0][26],sort_layer[0][27], sort_layer[1][26], sort_layer[1][27]);
alien_comparator(key_ref, sort_layer[0][28],sort_layer[0][29], sort_layer[1][28], sort_layer[1][29]);
alien_comparator(key_ref, sort_layer[0][30],sort_layer[0][31], sort_layer[1][30], sort_layer[1][31]);
alien_comparator(key_ref, sort_layer[1][0],sort_layer[1][2], sort_layer[2][0], sort_layer[2][2]);
alien_comparator(key_ref, sort_layer[1][1],sort_layer[1][3], sort_layer[2][1], sort_layer[2][3]);
alien_comparator(key_ref, sort_layer[1][4],sort_layer[1][6], sort_layer[2][4], sort_layer[2][6]);
alien_comparator(key_ref, sort_layer[1][5],sort_layer[1][7], sort_layer[2][5], sort_layer[2][7]);
alien_comparator(key_ref, sort_layer[1][8],sort_layer[1][10], sort_layer[2][8], sort_layer[2][10]);
alien_comparator(key_ref, sort_layer[1][9],sort_layer[1][11], sort_layer[2][9], sort_layer[2][11]);
alien_comparator(key_ref, sort_layer[1][12],sort_layer[1][14], sort_layer[2][12], sort_layer[2][14]);
alien_comparator(key_ref, sort_layer[1][13],sort_layer[1][15], sort_layer[2][13], sort_layer[2][15]);
alien_comparator(key_ref, sort_layer[1][16],sort_layer[1][18], sort_layer[2][16], sort_layer[2][18]);
alien_comparator(key_ref, sort_layer[1][17],sort_layer[1][19], sort_layer[2][17], sort_layer[2][19]);
alien_comparator(key_ref, sort_layer[1][20],sort_layer[1][22], sort_layer[2][20], sort_layer[2][22]);
alien_comparator(key_ref, sort_layer[1][21],sort_layer[1][23], sort_layer[2][21], sort_layer[2][23]);
alien_comparator(key_ref, sort_layer[1][24],sort_layer[1][26], sort_layer[2][24], sort_layer[2][26]);
alien_comparator(key_ref, sort_layer[1][25],sort_layer[1][27], sort_layer[2][25], sort_layer[2][27]);
alien_comparator(key_ref, sort_layer[1][28],sort_layer[1][30], sort_layer[2][28], sort_layer[2][30]);
alien_comparator(key_ref, sort_layer[1][29],sort_layer[1][31], sort_layer[2][29], sort_layer[2][31]);
alien_comparator(key_ref, sort_layer[2][1],sort_layer[2][2], sort_layer[3][1], sort_layer[3][2]);
alien_comparator(key_ref, sort_layer[2][5],sort_layer[2][6], sort_layer[3][5], sort_layer[3][6]);
alien_comparator(key_ref, sort_layer[2][9],sort_layer[2][10], sort_layer[3][9], sort_layer[3][10]);
alien_comparator(key_ref, sort_layer[2][13],sort_layer[2][14], sort_layer[3][13], sort_layer[3][14]);
alien_comparator(key_ref, sort_layer[2][17],sort_layer[2][18], sort_layer[3][17], sort_layer[3][18]);
alien_comparator(key_ref, sort_layer[2][21],sort_layer[2][22], sort_layer[3][21], sort_layer[3][22]);
alien_comparator(key_ref, sort_layer[2][25],sort_layer[2][26], sort_layer[3][25], sort_layer[3][26]);
alien_comparator(key_ref, sort_layer[2][29],sort_layer[2][30], sort_layer[3][29], sort_layer[3][30]);
assign sort_layer[3][0] = sort_layer[2][0];
assign sort_layer[3][3] = sort_layer[2][3];
assign sort_layer[3][4] = sort_layer[2][4];
assign sort_layer[3][7] = sort_layer[2][7];
assign sort_layer[3][8] = sort_layer[2][8];
assign sort_layer[3][11] = sort_layer[2][11];
assign sort_layer[3][12] = sort_layer[2][12];
assign sort_layer[3][15] = sort_layer[2][15];
assign sort_layer[3][16] = sort_layer[2][16];
assign sort_layer[3][19] = sort_layer[2][19];
assign sort_layer[3][20] = sort_layer[2][20];
assign sort_layer[3][23] = sort_layer[2][23];
assign sort_layer[3][24] = sort_layer[2][24];
assign sort_layer[3][27] = sort_layer[2][27];
assign sort_layer[3][28] = sort_layer[2][28];
assign sort_layer[3][31] = sort_layer[2][31];
alien_comparator(key_ref, sort_layer[3][0],sort_layer[3][4], sort_layer[4][0], sort_layer[4][4]);
alien_comparator(key_ref, sort_layer[3][1],sort_layer[3][5], sort_layer[4][1], sort_layer[4][5]);
alien_comparator(key_ref, sort_layer[3][2],sort_layer[3][6], sort_layer[4][2], sort_layer[4][6]);
alien_comparator(key_ref, sort_layer[3][3],sort_layer[3][7], sort_layer[4][3], sort_layer[4][7]);
alien_comparator(key_ref, sort_layer[3][8],sort_layer[3][12], sort_layer[4][8], sort_layer[4][12]);
alien_comparator(key_ref, sort_layer[3][9],sort_layer[3][13], sort_layer[4][9], sort_layer[4][13]);
alien_comparator(key_ref, sort_layer[3][10],sort_layer[3][14], sort_layer[4][10], sort_layer[4][14]);
alien_comparator(key_ref, sort_layer[3][11],sort_layer[3][15], sort_layer[4][11], sort_layer[4][15]);
alien_comparator(key_ref, sort_layer[3][16],sort_layer[3][20], sort_layer[4][16], sort_layer[4][20]);
alien_comparator(key_ref, sort_layer[3][17],sort_layer[3][21], sort_layer[4][17], sort_layer[4][21]);
alien_comparator(key_ref, sort_layer[3][18],sort_layer[3][22], sort_layer[4][18], sort_layer[4][22]);
alien_comparator(key_ref, sort_layer[3][19],sort_layer[3][23], sort_layer[4][19], sort_layer[4][23]);
alien_comparator(key_ref, sort_layer[3][24],sort_layer[3][28], sort_layer[4][24], sort_layer[4][28]);
alien_comparator(key_ref, sort_layer[3][25],sort_layer[3][29], sort_layer[4][25], sort_layer[4][29]);
alien_comparator(key_ref, sort_layer[3][26],sort_layer[3][30], sort_layer[4][26], sort_layer[4][30]);
alien_comparator(key_ref, sort_layer[3][27],sort_layer[3][31], sort_layer[4][27], sort_layer[4][31]);
alien_comparator(key_ref, sort_layer[4][2],sort_layer[4][4], sort_layer[5][2], sort_layer[5][4]);
alien_comparator(key_ref, sort_layer[4][3],sort_layer[4][5], sort_layer[5][3], sort_layer[5][5]);
alien_comparator(key_ref, sort_layer[4][10],sort_layer[4][12], sort_layer[5][10], sort_layer[5][12]);
alien_comparator(key_ref, sort_layer[4][11],sort_layer[4][13], sort_layer[5][11], sort_layer[5][13]);
alien_comparator(key_ref, sort_layer[4][18],sort_layer[4][20], sort_layer[5][18], sort_layer[5][20]);
alien_comparator(key_ref, sort_layer[4][19],sort_layer[4][21], sort_layer[5][19], sort_layer[5][21]);
alien_comparator(key_ref, sort_layer[4][26],sort_layer[4][28], sort_layer[5][26], sort_layer[5][28]);
alien_comparator(key_ref, sort_layer[4][27],sort_layer[4][29], sort_layer[5][27], sort_layer[5][29]);
assign sort_layer[5][0] = sort_layer[4][0];
assign sort_layer[5][1] = sort_layer[4][1];
assign sort_layer[5][6] = sort_layer[4][6];
assign sort_layer[5][7] = sort_layer[4][7];
assign sort_layer[5][8] = sort_layer[4][8];
assign sort_layer[5][9] = sort_layer[4][9];
assign sort_layer[5][14] = sort_layer[4][14];
assign sort_layer[5][15] = sort_layer[4][15];
assign sort_layer[5][16] = sort_layer[4][16];
assign sort_layer[5][17] = sort_layer[4][17];
assign sort_layer[5][22] = sort_layer[4][22];
assign sort_layer[5][23] = sort_layer[4][23];
assign sort_layer[5][24] = sort_layer[4][24];
assign sort_layer[5][25] = sort_layer[4][25];
assign sort_layer[5][30] = sort_layer[4][30];
assign sort_layer[5][31] = sort_layer[4][31];
alien_comparator(key_ref, sort_layer[5][1],sort_layer[5][2], sort_layer[6][1], sort_layer[6][2]);
alien_comparator(key_ref, sort_layer[5][3],sort_layer[5][4], sort_layer[6][3], sort_layer[6][4]);
alien_comparator(key_ref, sort_layer[5][5],sort_layer[5][6], sort_layer[6][5], sort_layer[6][6]);
alien_comparator(key_ref, sort_layer[5][9],sort_layer[5][10], sort_layer[6][9], sort_layer[6][10]);
alien_comparator(key_ref, sort_layer[5][11],sort_layer[5][12], sort_layer[6][11], sort_layer[6][12]);
alien_comparator(key_ref, sort_layer[5][13],sort_layer[5][14], sort_layer[6][13], sort_layer[6][14]);
alien_comparator(key_ref, sort_layer[5][17],sort_layer[5][18], sort_layer[6][17], sort_layer[6][18]);
alien_comparator(key_ref, sort_layer[5][19],sort_layer[5][20], sort_layer[6][19], sort_layer[6][20]);
alien_comparator(key_ref, sort_layer[5][21],sort_layer[5][22], sort_layer[6][21], sort_layer[6][22]);
alien_comparator(key_ref, sort_layer[5][25],sort_layer[5][26], sort_layer[6][25], sort_layer[6][26]);
alien_comparator(key_ref, sort_layer[5][27],sort_layer[5][28], sort_layer[6][27], sort_layer[6][28]);
alien_comparator(key_ref, sort_layer[5][29],sort_layer[5][30], sort_layer[6][29], sort_layer[6][30]);
assign sort_layer[6][0] = sort_layer[5][0];
assign sort_layer[6][7] = sort_layer[5][7];
assign sort_layer[6][8] = sort_layer[5][8];
assign sort_layer[6][15] = sort_layer[5][15];
assign sort_layer[6][16] = sort_layer[5][16];
assign sort_layer[6][23] = sort_layer[5][23];
assign sort_layer[6][24] = sort_layer[5][24];
assign sort_layer[6][31] = sort_layer[5][31];
alien_comparator(key_ref, sort_layer[6][0],sort_layer[6][8], sort_layer[7][0], sort_layer[7][8]);
alien_comparator(key_ref, sort_layer[6][1],sort_layer[6][9], sort_layer[7][1], sort_layer[7][9]);
alien_comparator(key_ref, sort_layer[6][2],sort_layer[6][10], sort_layer[7][2], sort_layer[7][10]);
alien_comparator(key_ref, sort_layer[6][3],sort_layer[6][11], sort_layer[7][3], sort_layer[7][11]);
alien_comparator(key_ref, sort_layer[6][4],sort_layer[6][12], sort_layer[7][4], sort_layer[7][12]);
alien_comparator(key_ref, sort_layer[6][5],sort_layer[6][13], sort_layer[7][5], sort_layer[7][13]);
alien_comparator(key_ref, sort_layer[6][6],sort_layer[6][14], sort_layer[7][6], sort_layer[7][14]);
alien_comparator(key_ref, sort_layer[6][7],sort_layer[6][15], sort_layer[7][7], sort_layer[7][15]);
alien_comparator(key_ref, sort_layer[6][16],sort_layer[6][24], sort_layer[7][16], sort_layer[7][24]);
alien_comparator(key_ref, sort_layer[6][17],sort_layer[6][25], sort_layer[7][17], sort_layer[7][25]);
alien_comparator(key_ref, sort_layer[6][18],sort_layer[6][26], sort_layer[7][18], sort_layer[7][26]);
alien_comparator(key_ref, sort_layer[6][19],sort_layer[6][27], sort_layer[7][19], sort_layer[7][27]);
alien_comparator(key_ref, sort_layer[6][20],sort_layer[6][28], sort_layer[7][20], sort_layer[7][28]);
alien_comparator(key_ref, sort_layer[6][21],sort_layer[6][29], sort_layer[7][21], sort_layer[7][29]);
alien_comparator(key_ref, sort_layer[6][22],sort_layer[6][30], sort_layer[7][22], sort_layer[7][30]);
alien_comparator(key_ref, sort_layer[6][23],sort_layer[6][31], sort_layer[7][23], sort_layer[7][31]);
alien_comparator(key_ref, sort_layer[7][4],sort_layer[7][8], sort_layer[8][4], sort_layer[8][8]);
alien_comparator(key_ref, sort_layer[7][5],sort_layer[7][9], sort_layer[8][5], sort_layer[8][9]);
alien_comparator(key_ref, sort_layer[7][6],sort_layer[7][10], sort_layer[8][6], sort_layer[8][10]);
alien_comparator(key_ref, sort_layer[7][7],sort_layer[7][11], sort_layer[8][7], sort_layer[8][11]);
alien_comparator(key_ref, sort_layer[7][20],sort_layer[7][24], sort_layer[8][20], sort_layer[8][24]);
alien_comparator(key_ref, sort_layer[7][21],sort_layer[7][25], sort_layer[8][21], sort_layer[8][25]);
alien_comparator(key_ref, sort_layer[7][22],sort_layer[7][26], sort_layer[8][22], sort_layer[8][26]);
alien_comparator(key_ref, sort_layer[7][23],sort_layer[7][27], sort_layer[8][23], sort_layer[8][27]);
assign sort_layer[8][0] = sort_layer[7][0];
assign sort_layer[8][1] = sort_layer[7][1];
assign sort_layer[8][2] = sort_layer[7][2];
assign sort_layer[8][3] = sort_layer[7][3];
assign sort_layer[8][12] = sort_layer[7][12];
assign sort_layer[8][13] = sort_layer[7][13];
assign sort_layer[8][14] = sort_layer[7][14];
assign sort_layer[8][15] = sort_layer[7][15];
assign sort_layer[8][16] = sort_layer[7][16];
assign sort_layer[8][17] = sort_layer[7][17];
assign sort_layer[8][18] = sort_layer[7][18];
assign sort_layer[8][19] = sort_layer[7][19];
assign sort_layer[8][28] = sort_layer[7][28];
assign sort_layer[8][29] = sort_layer[7][29];
assign sort_layer[8][30] = sort_layer[7][30];
assign sort_layer[8][31] = sort_layer[7][31];
alien_comparator(key_ref, sort_layer[8][2],sort_layer[8][4], sort_layer[9][2], sort_layer[9][4]);
alien_comparator(key_ref, sort_layer[8][3],sort_layer[8][5], sort_layer[9][3], sort_layer[9][5]);
alien_comparator(key_ref, sort_layer[8][6],sort_layer[8][8], sort_layer[9][6], sort_layer[9][8]);
alien_comparator(key_ref, sort_layer[8][7],sort_layer[8][9], sort_layer[9][7], sort_layer[9][9]);
alien_comparator(key_ref, sort_layer[8][10],sort_layer[8][12], sort_layer[9][10], sort_layer[9][12]);
alien_comparator(key_ref, sort_layer[8][11],sort_layer[8][13], sort_layer[9][11], sort_layer[9][13]);
alien_comparator(key_ref, sort_layer[8][18],sort_layer[8][20], sort_layer[9][18], sort_layer[9][20]);
alien_comparator(key_ref, sort_layer[8][19],sort_layer[8][21], sort_layer[9][19], sort_layer[9][21]);
alien_comparator(key_ref, sort_layer[8][22],sort_layer[8][24], sort_layer[9][22], sort_layer[9][24]);
alien_comparator(key_ref, sort_layer[8][23],sort_layer[8][25], sort_layer[9][23], sort_layer[9][25]);
alien_comparator(key_ref, sort_layer[8][26],sort_layer[8][28], sort_layer[9][26], sort_layer[9][28]);
alien_comparator(key_ref, sort_layer[8][27],sort_layer[8][29], sort_layer[9][27], sort_layer[9][29]);
assign sort_layer[9][0] = sort_layer[8][0];
assign sort_layer[9][1] = sort_layer[8][1];
assign sort_layer[9][14] = sort_layer[8][14];
assign sort_layer[9][15] = sort_layer[8][15];
assign sort_layer[9][16] = sort_layer[8][16];
assign sort_layer[9][17] = sort_layer[8][17];
assign sort_layer[9][30] = sort_layer[8][30];
assign sort_layer[9][31] = sort_layer[8][31];
alien_comparator(key_ref, sort_layer[9][1],sort_layer[9][2], sort_layer[10][1], sort_layer[10][2]);
alien_comparator(key_ref, sort_layer[9][3],sort_layer[9][4], sort_layer[10][3], sort_layer[10][4]);
alien_comparator(key_ref, sort_layer[9][5],sort_layer[9][6], sort_layer[10][5], sort_layer[10][6]);
alien_comparator(key_ref, sort_layer[9][7],sort_layer[9][8], sort_layer[10][7], sort_layer[10][8]);
alien_comparator(key_ref, sort_layer[9][9],sort_layer[9][10], sort_layer[10][9], sort_layer[10][10]);
alien_comparator(key_ref, sort_layer[9][11],sort_layer[9][12], sort_layer[10][11], sort_layer[10][12]);
alien_comparator(key_ref, sort_layer[9][13],sort_layer[9][14], sort_layer[10][13], sort_layer[10][14]);
alien_comparator(key_ref, sort_layer[9][17],sort_layer[9][18], sort_layer[10][17], sort_layer[10][18]);
alien_comparator(key_ref, sort_layer[9][19],sort_layer[9][20], sort_layer[10][19], sort_layer[10][20]);
alien_comparator(key_ref, sort_layer[9][21],sort_layer[9][22], sort_layer[10][21], sort_layer[10][22]);
alien_comparator(key_ref, sort_layer[9][23],sort_layer[9][24], sort_layer[10][23], sort_layer[10][24]);
alien_comparator(key_ref, sort_layer[9][25],sort_layer[9][26], sort_layer[10][25], sort_layer[10][26]);
alien_comparator(key_ref, sort_layer[9][27],sort_layer[9][28], sort_layer[10][27], sort_layer[10][28]);
alien_comparator(key_ref, sort_layer[9][29],sort_layer[9][30], sort_layer[10][29], sort_layer[10][30]);
assign sort_layer[10][0] = sort_layer[9][0];
assign sort_layer[10][15] = sort_layer[9][15];
assign sort_layer[10][16] = sort_layer[9][16];
assign sort_layer[10][31] = sort_layer[9][31];
alien_comparator(key_ref, sort_layer[10][0],sort_layer[10][16], sort_layer[11][0], sort_layer[11][16]);
alien_comparator(key_ref, sort_layer[10][1],sort_layer[10][17], sort_layer[11][1], sort_layer[11][17]);
alien_comparator(key_ref, sort_layer[10][2],sort_layer[10][18], sort_layer[11][2], sort_layer[11][18]);
alien_comparator(key_ref, sort_layer[10][3],sort_layer[10][19], sort_layer[11][3], sort_layer[11][19]);
alien_comparator(key_ref, sort_layer[10][4],sort_layer[10][20], sort_layer[11][4], sort_layer[11][20]);
alien_comparator(key_ref, sort_layer[10][5],sort_layer[10][21], sort_layer[11][5], sort_layer[11][21]);
alien_comparator(key_ref, sort_layer[10][6],sort_layer[10][22], sort_layer[11][6], sort_layer[11][22]);
alien_comparator(key_ref, sort_layer[10][7],sort_layer[10][23], sort_layer[11][7], sort_layer[11][23]);
alien_comparator(key_ref, sort_layer[10][8],sort_layer[10][24], sort_layer[11][8], sort_layer[11][24]);
alien_comparator(key_ref, sort_layer[10][9],sort_layer[10][25], sort_layer[11][9], sort_layer[11][25]);
alien_comparator(key_ref, sort_layer[10][10],sort_layer[10][26], sort_layer[11][10], sort_layer[11][26]);
alien_comparator(key_ref, sort_layer[10][11],sort_layer[10][27], sort_layer[11][11], sort_layer[11][27]);
alien_comparator(key_ref, sort_layer[10][12],sort_layer[10][28], sort_layer[11][12], sort_layer[11][28]);
alien_comparator(key_ref, sort_layer[10][13],sort_layer[10][29], sort_layer[11][13], sort_layer[11][29]);
alien_comparator(key_ref, sort_layer[10][14],sort_layer[10][30], sort_layer[11][14], sort_layer[11][30]);
alien_comparator(key_ref, sort_layer[10][15],sort_layer[10][31], sort_layer[11][15], sort_layer[11][31]);
alien_comparator(key_ref, sort_layer[11][8],sort_layer[11][16], sort_layer[12][8], sort_layer[12][16]);
alien_comparator(key_ref, sort_layer[11][9],sort_layer[11][17], sort_layer[12][9], sort_layer[12][17]);
alien_comparator(key_ref, sort_layer[11][10],sort_layer[11][18], sort_layer[12][10], sort_layer[12][18]);
alien_comparator(key_ref, sort_layer[11][11],sort_layer[11][19], sort_layer[12][11], sort_layer[12][19]);
alien_comparator(key_ref, sort_layer[11][12],sort_layer[11][20], sort_layer[12][12], sort_layer[12][20]);
alien_comparator(key_ref, sort_layer[11][13],sort_layer[11][21], sort_layer[12][13], sort_layer[12][21]);
alien_comparator(key_ref, sort_layer[11][14],sort_layer[11][22], sort_layer[12][14], sort_layer[12][22]);
alien_comparator(key_ref, sort_layer[11][15],sort_layer[11][23], sort_layer[12][15], sort_layer[12][23]);
assign sort_layer[12][0] = sort_layer[11][0];
assign sort_layer[12][1] = sort_layer[11][1];
assign sort_layer[12][2] = sort_layer[11][2];
assign sort_layer[12][3] = sort_layer[11][3];
assign sort_layer[12][4] = sort_layer[11][4];
assign sort_layer[12][5] = sort_layer[11][5];
assign sort_layer[12][6] = sort_layer[11][6];
assign sort_layer[12][7] = sort_layer[11][7];
assign sort_layer[12][24] = sort_layer[11][24];
assign sort_layer[12][25] = sort_layer[11][25];
assign sort_layer[12][26] = sort_layer[11][26];
assign sort_layer[12][27] = sort_layer[11][27];
assign sort_layer[12][28] = sort_layer[11][28];
assign sort_layer[12][29] = sort_layer[11][29];
assign sort_layer[12][30] = sort_layer[11][30];
assign sort_layer[12][31] = sort_layer[11][31];
alien_comparator(key_ref, sort_layer[12][4],sort_layer[12][8], sort_layer[13][4], sort_layer[13][8]);
alien_comparator(key_ref, sort_layer[12][5],sort_layer[12][9], sort_layer[13][5], sort_layer[13][9]);
alien_comparator(key_ref, sort_layer[12][6],sort_layer[12][10], sort_layer[13][6], sort_layer[13][10]);
alien_comparator(key_ref, sort_layer[12][7],sort_layer[12][11], sort_layer[13][7], sort_layer[13][11]);
alien_comparator(key_ref, sort_layer[12][12],sort_layer[12][16], sort_layer[13][12], sort_layer[13][16]);
alien_comparator(key_ref, sort_layer[12][13],sort_layer[12][17], sort_layer[13][13], sort_layer[13][17]);
alien_comparator(key_ref, sort_layer[12][14],sort_layer[12][18], sort_layer[13][14], sort_layer[13][18]);
alien_comparator(key_ref, sort_layer[12][15],sort_layer[12][19], sort_layer[13][15], sort_layer[13][19]);
alien_comparator(key_ref, sort_layer[12][20],sort_layer[12][24], sort_layer[13][20], sort_layer[13][24]);
alien_comparator(key_ref, sort_layer[12][21],sort_layer[12][25], sort_layer[13][21], sort_layer[13][25]);
alien_comparator(key_ref, sort_layer[12][22],sort_layer[12][26], sort_layer[13][22], sort_layer[13][26]);
alien_comparator(key_ref, sort_layer[12][23],sort_layer[12][27], sort_layer[13][23], sort_layer[13][27]);
assign sort_layer[13][0] = sort_layer[12][0];
assign sort_layer[13][1] = sort_layer[12][1];
assign sort_layer[13][2] = sort_layer[12][2];
assign sort_layer[13][3] = sort_layer[12][3];
assign sort_layer[13][28] = sort_layer[12][28];
assign sort_layer[13][29] = sort_layer[12][29];
assign sort_layer[13][30] = sort_layer[12][30];
assign sort_layer[13][31] = sort_layer[12][31];
alien_comparator(key_ref, sort_layer[13][2],sort_layer[13][4], sort_layer[14][2], sort_layer[14][4]);
alien_comparator(key_ref, sort_layer[13][3],sort_layer[13][5], sort_layer[14][3], sort_layer[14][5]);
alien_comparator(key_ref, sort_layer[13][6],sort_layer[13][8], sort_layer[14][6], sort_layer[14][8]);
alien_comparator(key_ref, sort_layer[13][7],sort_layer[13][9], sort_layer[14][7], sort_layer[14][9]);
alien_comparator(key_ref, sort_layer[13][10],sort_layer[13][12], sort_layer[14][10], sort_layer[14][12]);
alien_comparator(key_ref, sort_layer[13][11],sort_layer[13][13], sort_layer[14][11], sort_layer[14][13]);
alien_comparator(key_ref, sort_layer[13][14],sort_layer[13][16], sort_layer[14][14], sort_layer[14][16]);
alien_comparator(key_ref, sort_layer[13][15],sort_layer[13][17], sort_layer[14][15], sort_layer[14][17]);
alien_comparator(key_ref, sort_layer[13][18],sort_layer[13][20], sort_layer[14][18], sort_layer[14][20]);
alien_comparator(key_ref, sort_layer[13][19],sort_layer[13][21], sort_layer[14][19], sort_layer[14][21]);
alien_comparator(key_ref, sort_layer[13][22],sort_layer[13][24], sort_layer[14][22], sort_layer[14][24]);
alien_comparator(key_ref, sort_layer[13][23],sort_layer[13][25], sort_layer[14][23], sort_layer[14][25]);
alien_comparator(key_ref, sort_layer[13][26],sort_layer[13][28], sort_layer[14][26], sort_layer[14][28]);
alien_comparator(key_ref, sort_layer[13][27],sort_layer[13][29], sort_layer[14][27], sort_layer[14][29]);
assign sort_layer[14][0] = sort_layer[13][0];
assign sort_layer[14][1] = sort_layer[13][1];
assign sort_layer[14][30] = sort_layer[13][30];
assign sort_layer[14][31] = sort_layer[13][31];
alien_comparator(key_ref, sort_layer[14][1],sort_layer[14][2], sort_layer[15][1], sort_layer[15][2]);
alien_comparator(key_ref, sort_layer[14][3],sort_layer[14][4], sort_layer[15][3], sort_layer[15][4]);
alien_comparator(key_ref, sort_layer[14][5],sort_layer[14][6], sort_layer[15][5], sort_layer[15][6]);
alien_comparator(key_ref, sort_layer[14][7],sort_layer[14][8], sort_layer[15][7], sort_layer[15][8]);
alien_comparator(key_ref, sort_layer[14][9],sort_layer[14][10], sort_layer[15][9], sort_layer[15][10]);
alien_comparator(key_ref, sort_layer[14][11],sort_layer[14][12], sort_layer[15][11], sort_layer[15][12]);
alien_comparator(key_ref, sort_layer[14][13],sort_layer[14][14], sort_layer[15][13], sort_layer[15][14]);
alien_comparator(key_ref, sort_layer[14][15],sort_layer[14][16], sort_layer[15][15], sort_layer[15][16]);
alien_comparator(key_ref, sort_layer[14][17],sort_layer[14][18], sort_layer[15][17], sort_layer[15][18]);
alien_comparator(key_ref, sort_layer[14][19],sort_layer[14][20], sort_layer[15][19], sort_layer[15][20]);
alien_comparator(key_ref, sort_layer[14][21],sort_layer[14][22], sort_layer[15][21], sort_layer[15][22]);
alien_comparator(key_ref, sort_layer[14][23],sort_layer[14][24], sort_layer[15][23], sort_layer[15][24]);
alien_comparator(key_ref, sort_layer[14][25],sort_layer[14][26], sort_layer[15][25], sort_layer[15][26]);
alien_comparator(key_ref, sort_layer[14][27],sort_layer[14][28], sort_layer[15][27], sort_layer[15][28]);
alien_comparator(key_ref, sort_layer[14][29],sort_layer[14][30], sort_layer[15][29], sort_layer[15][30]);
assign sort_layer[15][0] = sort_layer[14][0];
assign sort_layer[15][31] = sort_layer[14][31];

endmodule

module alien_comparator(
    input [3:0] key_ref [0: OBJ_LIMIT-1],
    input [4:0] in_0,
    input [4:0] in_1,
    output logic [4:0] out_0,
    output logic [4:0] out_1
);
    always @* begin
        out_0 = (key_ref[in_0] < key_ref[in_1]) ? in_0 : in_1;
        out_1 = (key_ref[in_0] < key_ref[in_1]) ? in_1 : in_0;
    end

endmodule