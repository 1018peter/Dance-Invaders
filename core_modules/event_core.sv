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
    input clk, // Base frequency of around 30 Hz, and up to 60 Hz. Note: Any clock switching may cause frame glitches and should be handled with care.
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
    logic [15:0] frame_ctr; // Useful for cyclic behavior. "Every X frame, enter a different state"
    wire [15:0]  frame_onepulse; // Onepulse of select frames. "Every X frame, do something for 1 frame"
    generate 
    for(genvar g = 0; g < 16; g++)
        onepulse(frame_ctr[g], clk, frame_onepulse[g]);
    endgenerate
    
    wire spawn_object_op;
    onepulse(spawn_object, clk, spawn_object_op);
    
    always @*begin
        all_clear = 1;
        flag_game_over = 0;
        for(int i = 0; i < OBJ_LIMIT; i++) begin
            if(obj_arr[i]._state != INACTIVE) all_clear = 0;
            if(obj_arr[i]._r == 0 && obj_arr[i]._state == ACTIVE) flag_game_over = 1;
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            frame_ctr <= 0;
        end
        else if(en) begin
            frame_ctr <= frame_ctr + 1;
        end
    end
    
    // Collapse the frame into the format of { {AlienData}}
	assign frame_data[0] = laser._active;
	assign frame_data[4:1] = laser._r;
	assign frame_data[13:5] = laser._deg;
	generate
	for(genvar k = 0; k < OBJ_LIMIT; k++) begin
        assign frame_data[14 + k * $size(AlienData)] = obj_arr[k]._state != INACTIVE;
        assign frame_data[14 + k * $size(AlienData)+2:14 + k * $size(AlienData)+1] = obj_arr[k]._type;
        assign frame_data[14 + k * $size(AlienData)+4:14 + k * $size(AlienData)+3] = obj_arr[k]._frame_num;
        assign frame_data[14 + k * $size(AlienData)+8:14 + k * $size(AlienData)+5] = obj_arr[k]._r;
        assign frame_data[14 + k * $size(AlienData)+17:14 + k * $size(AlienData)+9] = obj_arr[k]._theta;

    end
	endgenerate
	
    always @(posedge clk, posedge rst) begin
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
                DYING: begin // TODO: Four-frame death animation. Here specifies the end frame of each animation set.
                    if (frame_onepulse[2]) case(obj_arr[i]._type)
                    TYPE0: begin
                        if(obj_arr[i]._frame_num == 3) obj_arr[i]._state <= INACTIVE;
                        else obj_arr[i]._frame_num <= obj_arr[i]._frame_num + 1;
                    end
                    TYPE1: begin
                        if(obj_arr[i]._frame_num == 7) obj_arr[i]._state <= INACTIVE;
                        else obj_arr[i]._frame_num <= obj_arr[i]._frame_num + 1;
                    end
                    TYPE2: begin
                        if(obj_arr[i]._frame_num == 11) obj_arr[i]._state <= INACTIVE;
                        else obj_arr[i]._frame_num <= obj_arr[i]._frame_num + 1;
                    end
                    TYPE3: begin
                        if(obj_arr[i]._frame_num == 15) obj_arr[i]._state <= INACTIVE;
                        else obj_arr[i]._frame_num <= obj_arr[i]._frame_num + 1;
                    end
                    endcase
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
                            obj_arr[i]._frame_num <= obj_arr[i]._frame_num + 1; // Advance to death animation frames.
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
