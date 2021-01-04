`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/20 16:21:15
// Design Name: Control Core for Dance Invaders
// Module Name: control_core
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

module control_core(
    input clk, // 100MHz
    input rst, // btnC
    input RxD,
    output [MESSAGE_SIZE - 1:0] datagram,
    output [15:0] led,
    output [3:0] DIGIT,
    output [6:0] DISPLAY
    );
    wire clk_main; // Operating frequency.
    clock_divider_two_power(
    .clk(clk),
    .clk_div(clk_main)
    );
    wire clk_frame;
    wire clk_spawn;
    wire [1:0] clock_select;
    clock_wizard(
    .clk_100MHz(clk),
    .rst(rst),
    .select(clock_select),
    .clk_div(clk_frame)
    );
    
    wire [7:0] event_packet;
    logic [7:0] event_buffer;
    wire [7:0] event_onepulse;
    wire [7:0] event_state_onepulse;
    wire packet_valid;
    uart_receiver(
    .clk(clk),
    .reset(rst),
    .valid(packet_valid),
    .RxD(RxD),
    .RxData(event_packet)
    );
    
    always @(posedge clk_main, posedge rst) begin
        if(rst) event_buffer <= 0;
        else if(packet_valid) event_buffer <= event_packet;
    end
    
    genvar k;
    generate
    for(k = 0; k < 8; k++) begin
        onepulse(event_buffer[k], clk_frame, event_onepulse[k]);
        onepulse(event_buffer[k], clk_main, event_state_onepulse[k]);
    end
    endgenerate
    
    FourDir dir;
    always @* begin
    if(event_onepulse[BUTTON_UP]) dir = UP;
    else if(event_onepulse[BUTTON_DOWN]) dir = DOWN;
    else if(event_onepulse[BUTTON_LEFT]) dir = LEFT;
    else dir = DOWN;
    end
    
    // State transition edges.
    wire wire_ready, 
    wire_game_start,
    wire_level_start,
    wire_game_over, 
    wire_level_clear, 
    wire_scoreboard, 
    wire_game_reset;
    assign wire_ready = 1; // Can be changed to when every peripheral is active.
    logic [STATE_SIZE - 1: 0] cur_state;
    logic [LEVEL_SIZE - 1:0] cur_level; // Current level.
    assign wire_game_start = (cur_state == SCENE_GAME_START) && |event_state_onepulse; // "Press any button on the dancepad to start"
    assign clock_select = cur_level[LEVEL_SIZE - 1:LEVEL_SIZE - 2];
    wire clk_10Hz;
    clock_divider_10Hz(
    .clk_100MHz(clk), 
    .rst(rst), 
    .clk_div(clk_10Hz)
    );
    
    wire clk_5s;
    clock_divider_5s(
    .clk_100MHz(clk),
    .rst(rst || wire_level_start),
    .clk_div(clk_5s)
    );
    assign led[5] = clk_5s;
    
    wire wire_script_ended;
    wire [9:0] timer_count;
    wire script_enable;
    script_machine(
    .clk_10Hz(clk_10Hz),
    .rst(rst),
    .en(script_enable),
    .cur_level(cur_level),
    .cur_state(cur_state),
    .script_ended(wire_script_ended),
    .timer_count(timer_count)
    );
    assign wire_level_start = (cur_state == SCENE_LEVEL_START) && wire_script_ended;
    assign wire_scoreboard = (cur_state == SCENE_GAME_OVER) && wire_script_ended;
    
    
    wire [15:0] random_num;
    LFSR(
    .clk(clk),
    .rst(rst),
    .seed(INITIAL_RAND_SEED),
    .rand_out(random_num)
    );
    
    Alien new_alien;
    alien_generator(cur_level, random_num, new_alien);
    
    wire [15:0] wire_score;
    wire signal_clear;
    wire [FRAME_DATA_SIZE - 1: 0] frame_data;
    wire [3:0] object_count;
    event_core(
    .clk_frame(clk_frame),
    .rst(rst || wire_game_start),
    .en(cur_state == SCENE_INGAME),
    .spawn_laser(|event_onepulse[BUTTON_RIGHT:BUTTON_UP]),
    .dir(dir),
    .spawn_object(clk_5s & ~wire_script_ended),
    .spawn_data(new_alien),
    .score_out(wire_score),
    .all_clear(signal_clear),
    .game_over(wire_game_over),
    .object_count(object_count),
    .frame_data(frame_data)
    );
    
    assign wire_level_clear = signal_clear && cur_state == SCENE_INGAME && wire_script_ended;
    // Complete message to be output. Self-explanatory.
    
    wire [FRAME_DATA_SIZE + SCORE_SIZE + LEVEL_SIZE - 1: 0] ingame_data
    = { frame_data, wire_score, cur_level }; // Also doubles as level start data and game over data.
    
    wire [SCOREBOARD_DATA_SIZE - 1:0] scoreboard_data; // Display up to 6 name/score pairs.
    wire scoreboard_done;
    scoreboard_fsm(
    .clk(clk_main), 
    .rst(rst),
    .en(cur_state == SCENE_SCOREBOARD),
    .event_onepulse(event_state_onepulse), // Needed to operate the virtual keyboard.
    .new_score(wire_score),
    .done(scoreboard_done),
    .scoreboard_data(scoreboard_data)
    );
    assign script_enable = scoreboard_done || cur_state == SCENE_LEVEL_START || cur_state == SCENE_INGAME || cur_state == SCENE_GAME_OVER;
    assign wire_game_reset = cur_state == SCENE_SCOREBOARD && scoreboard_done && wire_script_ended;
    
    logic [MESSAGE_SIZE - 1:0] output_message;
    always @* begin 
        output_message = 0; // Pad don't-cares with zeroes.
        case(cur_state)
        SCENE_INGAME: output_message[INGAME_DATA_SIZE + STATE_SIZE - 1:0] = {ingame_data, cur_state};
        SCENE_LEVEL_START: output_message[INGAME_DATA_SIZE + STATE_SIZE - 1:0] = {ingame_data, cur_state};
        SCENE_GAME_OVER: output_message[INGAME_DATA_SIZE + STATE_SIZE - 1:0] = {ingame_data, cur_state};
        SCENE_SCOREBOARD: output_message[SCOREBOARD_DATA_SIZE + STATE_SIZE - 1:0] = {scoreboard_data, cur_state};
        default: output_message[STATE_SIZE - 1:0] = {cur_state};
        endcase
    end
    assign datagram = output_message;
    
    
    always @(posedge clk_main, posedge rst) begin
        if(rst) begin
            cur_state <= SCENE_INITIAL;
            cur_level <= 0;
        end
        else case(cur_state)
        SCENE_INITIAL: if (wire_ready) cur_state <= SCENE_GAME_START;
        SCENE_GAME_START: if (wire_game_start) begin
                            cur_state <= SCENE_LEVEL_START;
                            cur_level <= 0; // Initialize!
                        end
        SCENE_LEVEL_START: if (wire_level_start) cur_state <= SCENE_INGAME;
        SCENE_INGAME: if (wire_level_clear) begin 
                            cur_state <= SCENE_LEVEL_START;
                            cur_level <= cur_level + 1;
                        end
                      else if (wire_game_over) cur_state <= SCENE_GAME_OVER;
        SCENE_GAME_OVER: if (wire_scoreboard) cur_state <= SCENE_SCOREBOARD;
        SCENE_SCOREBOARD: if (wire_game_reset) cur_state <= SCENE_GAME_START;
        endcase
    end
    
    wire [6:0] digit [0:3];
    hex_decoder(cur_level, digit[0]);
    hex_decoder(object_count, digit[1]);
    //hex_decoder(timer_count[9:8], digit[1]);
    hex_decoder(timer_count[7:4], digit[2]);
    hex_decoder(timer_count[3:0], digit[3]);
    /*
    hex_decoder(wire_score[11:8], digit[1]);
    hex_decoder(wire_score[7:4], digit[2]);
    hex_decoder(wire_score[3:0], digit[3]);
    */
    seven_segment(clk, {digit[0], digit[1], digit[2], digit[3]}, DIGIT, DISPLAY);
    assign led[STATE_SIZE - 1:0] = cur_state;
    assign led[15:8] = event_buffer;
    
endmodule

module script_machine(
    input clk_10Hz,
    input rst,
    input en,
    input [LEVEL_SIZE - 1:0] cur_level,
    input [STATE_SIZE - 1:0] cur_state,
    output logic script_ended,
    output [9:0] timer_count
);
    logic [STATE_SIZE - 1:0] prev_state;
    logic [9:0] script_timer; // Counts in 1/10-ths of a second.
    logic [9:0] timer_end; // Upper bound of the timer.
    assign timer_count = script_timer;
    always @* begin
    
        if(cur_state == SCENE_INGAME) 
        case(cur_level[3:1]) // Linearly increasing base time for each level, capping at 65 seconds.
        0: timer_end = 300;
        1: timer_end = 350;
        2: timer_end = 400;
        3: timer_end = 450;
        4: timer_end = 500;
        5: timer_end = 550;
        6: timer_end = 600;
        default: timer_end = 650;
        endcase
        else timer_end = 50; // "Cutscene time", exactly 5 seconds.
        script_ended = script_timer == timer_end;
    end
    
    always @(posedge clk_10Hz, posedge rst) begin
        if(rst) begin
            script_timer <= 0;
            prev_state <= SCENE_INITIAL;
        end
        else if(cur_state != prev_state) begin 
            script_timer <= 0; // Reset after transition.
            prev_state <= cur_state;
        end
        else if(script_timer != timer_end) begin
            if(en) script_timer <= script_timer + 1;
            else script_timer <= 0;
        end
    end
endmodule

module alien_generator(
    input [3:0] cur_level,
    input [15:0] random_num,
    output Alien new_alien
);
    // type distribution for easy variation on scripted spawns.
    parameter AlienType type_distribution_0 [0:1] = { TYPE0, TYPE1 };
    parameter AlienType type_distribution_1 [0:3] = { TYPE0, TYPE0, TYPE0, TYPE1 };
    parameter AlienType type_distribution_2 [0:3] = { TYPE0, TYPE1, TYPE1, TYPE1 };
    parameter AlienType type_distribution_3 [0:7] = { TYPE0, TYPE0, TYPE0, TYPE1, TYPE1, TYPE1, TYPE2, TYPE3 };
    parameter AlienType type_distribution_4 [0:3] = { TYPE0, TYPE1, TYPE2, TYPE3 };
    parameter AlienType type_distribution_5 [0:7] = { TYPE0, TYPE1, TYPE2, TYPE2, TYPE2, TYPE3, TYPE3, TYPE3 };
    parameter AlienType type_distribution_6 [0:1] = { TYPE2, TYPE3 };
    
    // 4 direction.
    parameter Degree deg_distribution_0 [0:3] = { 45, 135, 225, 315 };
    // 8 direction.
    parameter Degree deg_distribution_1 [0:7] = { 0, 45, 90, 135, 180, 225, 270, 315 };
    // 16 direction.
    parameter Degree deg_distribution_2 [0:15] = { 0, 22, 45, 78, 90, 113, 135, 157, 180, 202, 225, 248, 270, 292, 315, 338 };
    
    AlienType rand_type;
    Degree rand_deg;
    always@* begin
        case(cur_level)
        0: begin
        rand_type = type_distribution_0[random_num[0]];
        rand_deg = deg_distribution_0[random_num[1:0]];
        end
        1: begin
        rand_type = type_distribution_1[random_num[1:0]];
        rand_deg = deg_distribution_0[random_num[1:0]];       
        end
        2: begin
        rand_type = type_distribution_2[random_num[1:0]];
        rand_deg = deg_distribution_0[random_num[1:0]];        
        end
        3: begin
        rand_type = type_distribution_3[random_num[2:0]];
        rand_deg = deg_distribution_1[random_num[2:0]];        
        end
        4: begin
        rand_type = type_distribution_4[random_num[1:0]];
        rand_deg = deg_distribution_1[random_num[2:0]];        
        end
        5: begin
        rand_type = type_distribution_5[random_num[2:0]];
        rand_deg = deg_distribution_2[random_num[3:0]];        
        end
        6: begin
        rand_type = type_distribution_6[random_num[0]];
        rand_deg = deg_distribution_1[random_num[2:0]];        
        end
        7: begin
        rand_type = type_distribution_4[random_num[1:0]];
        rand_deg = deg_distribution_2[random_num[3:0]];        
        end
        default: begin
        rand_type = type_distribution_5[random_num[2:0]];
        rand_deg = deg_distribution_2[random_num[3:0]];        
        end
        endcase
    end
    
    always @* begin
    new_alien._state = ACTIVE;
    new_alien._type = rand_type;
    new_alien._frame_num = 0;
    new_alien._r = (cur_level >> 1) + 8;
    new_alien._theta = rand_deg;
    new_alien._hp = { rand_type, 1'b1 };
    end
endmodule

module scoreboard_fsm(
    input clk,
    input rst, 
    input en,
    input [7:0] event_onepulse,
    input [SCORE_SIZE - 1:0] new_score,
    output done,
    output [SCORE_SIZE * 6 + STRING_SIZE * 6 + 2 + 1 - 1:0] scoreboard_data // Format: { (string, score)x5, state }
);

    logic state; // 0: Naming; 1: Displaying
    wire signal_insert;
    logic [1:0] pos;
    logic [CHAR_SIZE - 1:0] chr [0:2];
    wire [STRING_SIZE - 1:0] name [0:4];
    wire [SCORE_SIZE - 1: 0] score [0:4];
    onepulse(state, clk, signal_insert);
    assign done = state;
    assign scoreboard_data = { name[4], score[4], name[3], score[3], 
    name[2], score[2], name[1], score[1], name[0], score[0], { chr[0], chr[1], chr[2]}, new_score, pos, state };
    // Keeps a record. (Verilog module)
    scoreboard(
    .clk(clk),
    .rst(rst),
    .insert(signal_insert),
    .key_insert(new_score),
    .string_insert({ chr[0], chr[1], chr[2] }),
    .score_0(score[0]),
    .string_0(name[0]),
    .score_1(score[1]),
    .string_1(name[1]),
    .score_2(score[2]),
    .string_2(name[2]),
    .score_3(score[3]),
    .string_3(name[3]),
    .score_4(score[4]),
    .string_4(name[4])
    );
    
    always @(posedge clk) begin
        if(!en) begin
            state <= 0;
            pos <= 0;
            chr[0] <= CHAR_A;
            chr[1] <= CHAR_A;
            chr[2] <= CHAR_A;
        end
        else if(state == 0) begin 
            if(pos != 3) begin
                if(event_onepulse[BUTTON_UP]) begin
                    if(chr[pos] == CHAR_SPACE) chr[pos] <= CHAR_A;
                    else chr[pos] <= chr[pos] + 1;
                end
                else if(event_onepulse[BUTTON_DOWN]) begin
                    if(chr[pos] == CHAR_A) chr[pos] <= CHAR_SPACE;
                    else chr[pos] <= chr[pos] - 1;
                end
                else if(event_onepulse[BUTTON_LEFT]) begin
                    pos <= pos - 1;
                end
                else if(event_onepulse[BUTTON_RIGHT]) begin
                    pos <= pos + 1;
                end
            end
            else begin
                if(event_onepulse[BUTTON_LEFT]) begin
                    pos <= pos - 1;
                end
                else if(|event_onepulse) begin
                    state <= 1;
                end
            end
        end
    end

endmodule

module clock_divider_two_power(clk, clk_div);   
    parameter n = 8;     
    input clk;   
    output clk_div;   
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num<=next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];
    
endmodule

