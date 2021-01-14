`timescale 1ns / 1ps
`ifndef _TYPEDEFS_SVH
`define _TYPEDEFS_SVH 
// Remember that "$bits()" is the SystemVerilog-equivalent of "sizeof" in C!


// Enumeration type for determining behavior.
typedef enum bit[1:0]{
    TYPE0, TYPE1, TYPE2, TYPE3
} AlienType; 

typedef enum bit[1:0]{
    INACTIVE, ACTIVE, DYING
} AlienState;

typedef enum bit[1:0] {
    UP = 0, DOWN = 2, LEFT = 1, RIGHT = 3
} FourDir;


typedef bit[8:0] Degree; // Integer degree from 0 to 359.

// The aggregate of an alien consists of { distance (4), degree (9), hit point (3),
// state (2), sprite type (4)  }, for a total of 19 bits. 1k~ bits is enough to control 60~ aliens 
// to be rendered simultaneously.
typedef struct packed {
    AlienState _state;
    AlienType _type;
    bit [1:0] _frame_num;
    bit [3:0] _r; // Integer distance from origin.
    Degree _theta; 
    bit [2:0] _hp; // Health point.
} Alien;

// Parallel output format for rendering. TODO!
typedef struct packed{
	bit _active;
	bit [$size(AlienType)-1:0] _type;
	bit [1:0] _frame_num;
	bit [3:0] _r; // The distance between the alien and the player, used for determining transform.
	//bit [$size(Degree) - 1:0] _theta;
	bit [1:0] _quadrant; // Tag that identifies the quadrant the alien is in for rendering purposes.
	bit [9:0] _x_pos; // The projected coordinates of the alien onto the 2D display screen. (0~640)
	bit [9:0] _y_pos; // (0~480)
	bit [1:0] _deriv_left; // The identifier of the derivative transform that should be displayed.
	bit [1:0] _deriv_right; // See above. 
} AlienData;


typedef struct packed {
    bit _active;
    bit [3:0] _r; // Integer distance from origin.
    Degree _deg; // Orientation.
} Laser;

// Supported alphabet set. Fits into a 5-bit representation rather than the ASCII 8-bit representation.
typedef enum bit[4:0]{
    CHAR_A, CHAR_B, CHAR_C, CHAR_D, 
    CHAR_E, CHAR_F, CHAR_G, CHAR_H, 
    CHAR_I, CHAR_J, CHAR_K, CHAR_L,
    CHAR_M, CHAR_N, CHAR_O, CHAR_P,
    CHAR_Q, CHAR_R, CHAR_S, CHAR_T,
    CHAR_U, CHAR_V, CHAR_W, CHAR_X,
    CHAR_Y, CHAR_Z, CHAR_SPACE
} AlphaSet;

// Supported decimal set. Fits into a 4-bit representation.
typedef enum bit [3:0]{
    CHAR_0, CHAR_1, CHAR_2, CHAR_3,
    CHAR_4, CHAR_5, CHAR_6, CHAR_7,
    CHAR_8, CHAR_9, CHAR_COMMA, CHAR_DOT
} DecimalSet;


`endif

`include "typedefs.svh"
`ifndef CONSTANTS_SVH
`define CONSTANTS_SVH
// Global constants that can be referenced across the entire project.
parameter OBJ_LIMIT = 16;
parameter R_LIMIT = 15;
parameter LSR_WIDTH = 20;
parameter LSR_DATA_SIZE = 7;

parameter SCORE_SIZE = 16;
parameter CHAR_SIZE = 5;
parameter STRING_SIZE = 15;
parameter LEVEL_SIZE = 4;
parameter INITIAL_RAND_SEED = 16'he7cb;

parameter BUTTON_UP = 0;
parameter BUTTON_DOWN = 1;
parameter BUTTON_LEFT = 2;
parameter BUTTON_RIGHT = 3;
parameter BUTTON_SELECT = 4;
parameter BUTTON_START = 5;

/*
The initial state. The control core waits until every peripheral becomes ready 
(ie. powered-on) before advancing to the game states.
*/
parameter SCENE_INITIAL = 3'd0;

/*
The start state.
 INITIAL
    |
    |
    V
GAME_START -> LEVEL_START -> INGAME -> GAME_OVER -> SCOREBOARD
     |             |            |                       |
     |             -- - - <- - --                       |
     ----------<----------<----------<---------<---------
*/
parameter SCENE_GAME_START = 3'd1;

parameter SCENE_LEVEL_START = 3'd2;

parameter SCENE_INGAME = 3'd3;

parameter SCENE_GAME_OVER = 3'd4;

parameter SCENE_SCOREBOARD = 3'd5;

parameter STATE_SIZE = 3;

parameter ALIEN_DATA_SIZE = $size(AlienData);

parameter LASER_DATA_SIZE = 7;

parameter FRAME_DATA_SIZE = ALIEN_DATA_SIZE * OBJ_LIMIT + LASER_DATA_SIZE;

parameter INGAME_DATA_SIZE = FRAME_DATA_SIZE + SCORE_SIZE + LEVEL_SIZE;

parameter SCOREBOARD_DATA_SIZE = SCORE_SIZE * 6 + STRING_SIZE * 6 + 2 + 1;

parameter MESSAGE_SIZE = INGAME_DATA_SIZE + STATE_SIZE;

parameter [13:0] sin [0:90] = { 0, 174, 349, 523, 698, 
872, 1045, 1219, 1392, 1564, 
1736, 1908, 2079, 2249, 2419, 
2588, 2756, 2924, 3090, 3256, 
3420, 3584, 3746, 3907, 4067, 
4226, 4384, 4540, 4695, 4848, 
5000, 5150, 5299, 5446, 5592, 
5736, 5878, 6018, 6157, 6293, 
6428, 6561, 6691, 6820, 6947, 
7071, 7193, 7314, 7431, 7547, 
7660, 7772, 7880, 7986, 8090, 
8191, 8290, 8387, 8480, 8571, 
8660, 8746, 8829, 8910, 8988, 
9063, 9135, 9205, 9272, 9336, 
9397, 9455, 9511, 9563, 9613, 
9659, 9703, 9744, 9781, 9816, 
9848, 9877, 9903, 9926, 9945, 
9962, 9962, 9976, 9986, 9994, 
10000};

`endif

module clock_wizard(
    input clk_100MHz,
    input rst,
    input [1:0] select, // 0: 60 Hz, 1: 50 Hz, 2: 40 Hz, 3: 30 Hz
    output clk_div
    );
    parameter div_3 = 833333; // Corresponds to 60 Hz
    parameter div_2 = 1000000;    // Corresponds to 50 Hz
    parameter div_1 = 1250000;  // Corresponds to 40 Hz
    parameter div_0 = 1666666;  // Corresponds to 30 Hz
    reg [21:0] div;
    reg [1:0] cur_state;
    
    always @* begin
        case(cur_state)
        0: div = div_0;
        1: div = div_1;
        2: div = div_2;
        3: div = div_3;
        default: div = div_0;
        endcase
    end
    reg[21:0] ctr;
    reg clk_div_reg;
    assign clk_div = clk_div_reg;
    always @(posedge clk_100MHz, posedge rst) begin
        if(rst) begin
            cur_state <= 0;
            ctr <= 0;
            clk_div_reg <= 0;
        end
        else if(cur_state != select) begin // Smooth clock select transition.
            cur_state <= select;
            ctr <= 0;
        end
        else if(ctr != div - 1) begin
            ctr <= ctr + 1;
        end
        else begin
            ctr <= 0;
            clk_div_reg <= ~clk_div_reg;
        end
    end
endmodule
module clock_divider_5s(
    input clk_100MHz,
    input rst,
    output clk_div
    );
    reg[28:0] ctr;
    reg clk_div_reg;
    assign clk_div = clk_div_reg;
    always @(posedge clk_100MHz, posedge rst) begin
        if(rst) begin
            ctr <= 0;
            clk_div_reg <= 0;
        end
        else if(ctr != 250000000 - 1) begin
            ctr <= ctr + 1;
        end
        else begin
            ctr <= 0;
            clk_div_reg <= ~clk_div_reg;
        end
    end
endmodule
module clock_divider_10Hz(
    input clk_100MHz,
    input rst,
    output clk_div
    );
    
    reg[23:0] ctr;
    reg clk_div_reg;
    assign clk_div = clk_div_reg;
    always @(posedge clk_100MHz, posedge rst) begin
        if(rst) begin
            ctr <= 0;
            clk_div_reg <= 0;
        end
        else if(ctr != 5000000 - 1) begin
            ctr <= ctr + 1;
        end
        else begin
            ctr <= 0;
            clk_div_reg <= ~clk_div_reg;
        end
    end
endmodule
module debounce(pb_debounced, pb ,clk);
    output pb_debounced;
    input pb;
    input clk;
    
    reg [6:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[6:1] <= shift_reg[5:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = shift_reg == 7'b111_1111 ? 1'b1 : 1'b0;
endmodule
module onepulse(signal, clk, op);
    input signal, clk;
    output op;
    
    reg op;
    reg delay;
    
    always @(posedge clk) begin
        if((signal == 1) & (delay == 0)) op <= 1;
        else op <= 0; 
        delay = signal;
    end
endmodule
module LFSR(
    input clk,
    input rst,
    input [15:0] seed, // Must be non-zero.
    output [15:0] rand_out
    );
    reg [15:0] reg_shift;
    assign rand_out = reg_shift;
    always @(posedge clk, posedge rst) begin
        if (rst) reg_shift <= seed;
        else reg_shift <= { reg_shift[14:0], reg_shift[10] ^ reg_shift[12] ^ reg_shift[13] ^ reg_shift[15] };
    end
endmodule
`define ALPHABET_SIZE 5
`define SCORE_SIZE 16
`define score reg [`SCORE_SIZE - 1:0]
`define string reg [3 * `ALPHABET_SIZE - 1:0]
`define score_pipe wire [`SCORE_SIZE - 1:0]
`define string_pipe wire [3 * `ALPHABET_SIZE - 1:0]

module comparator_tb(

    );
    
    reg clk = 0;
    `score_pipe score [0:2];
    `string_pipe string [0:2];
    `score new_score [0:2];
    `string new_string [0:2];
    
    generic_comparator cmp_tb(new_score[0], new_string[0], new_score[1], new_string[1], score[0], string[0], score[1], string[1]);
    generic_identity id_tb(new_score[2], new_string[2], score[2], string[2]);
    always #10 clk = ~clk;
    
    
    initial begin
        @(posedge clk) begin
        new_score[0] <= 10;
        new_string[0] <= 122;
        new_score[1] <= 15;
        new_string[1] <= 66;
        new_score[2] <= 1111;
        new_string[2] <= 333;
        end
        @(posedge clk)
        $display("(%d: %d), (%d: %d)", string[0], score[0], string[1], score[1], string[2], score[2]);
        new_score[0] <= 77;
        new_string[0] <= 172;
        new_score[1] <= 35;
        new_string[1] <= 20;
        new_score[2] <= 0;
        new_string[2] <= 323;
        
        @(posedge clk)
        $display("(%d: %d), (%d: %d)", string[0], score[0], string[1], score[1], string[2], score[2]);
        new_score[0] <= 11;
        new_string[0] <= 10;
        new_score[1] <= 11;
        new_string[1] <= 33;
        new_score[2] <= 11111;
        new_string[2] <= 23;
        @(posedge clk)
        $display("(%d: %d), (%d: %d)", string[0], score[0], string[1], score[1], string[2], score[2]);
        $finish;
    end
endmodule
`define ALPHABET_SIZE 5
`define SCORE_SIZE 16


// Generic variables so that the sorting algorithm becomes more generalized.
`define KEY_SIZE `SCORE_SIZE
`define VALUE_SIZE 3 * `ALPHABET_SIZE
`define key_pipe wire [`KEY_SIZE - 1:0]
`define value_pipe wire [`VALUE_SIZE - 1:0]



module scoreboard(
    input clk,
    input rst,
    input insert, // Assert for 1 clock pulse to insert once.
    input [`KEY_SIZE - 1:0] key_insert,
    input [`VALUE_SIZE - 1:0] string_insert,
    output [`KEY_SIZE - 1:0] score_0,
    output [`VALUE_SIZE - 1:0] string_0,
    output [`KEY_SIZE - 1:0] score_1,
    output [`VALUE_SIZE - 1:0] string_1,
    output [`KEY_SIZE - 1:0] score_2,
    output [`VALUE_SIZE - 1:0] string_2,
    output [`KEY_SIZE - 1:0] score_3,
    output [`VALUE_SIZE - 1:0] string_3,
    output [`KEY_SIZE - 1:0] score_4,
    output [`VALUE_SIZE - 1:0] string_4
    );
    
    integer i;
    genvar g;
    reg [`KEY_SIZE - 1:0] reg_score [0:5];
    reg [`VALUE_SIZE - 1:0] reg_string [0:5];
    assign score_0 = reg_score[0];
    assign string_0 = reg_string[0];
    assign score_1 = reg_score[1];
    assign string_1 = reg_string[1];
    assign score_2 = reg_score[2];
    assign string_2 = reg_string[2];
    assign score_3 = reg_score[3];
    assign string_3 = reg_string[3];
    assign score_4 = reg_score[4];
    assign string_4 = reg_string[4];
    
    // Buses used for the sorting network, numbered according to their layers.
    `key_pipe key_pipe_0 [0:5];
    `value_pipe value_pipe_0 [0:5];
    
    `key_pipe key_pipe_1 [0:5];
    `value_pipe value_pipe_1 [0:5];
    
    `key_pipe key_pipe_2 [0:5];
    `value_pipe value_pipe_2 [0:5];
    
    `key_pipe key_pipe_3 [0:5];
    `value_pipe value_pipe_3 [0:5];
    
    `key_pipe key_pipe_4 [0:5];
    `value_pipe value_pipe_4 [0:5];
    
    `key_pipe key_pipe_5 [0:5];
    `value_pipe value_pipe_5 [0:5];
    
    // Building the six layers of comparators of the optimal sorting network.
    
    // Layer 0
    generate 
        for(g = 0; g < 5; g = g + 2) begin
            generic_comparator cmp(reg_score[g], reg_string[g],
            reg_score[g+1], reg_string[g+1],
            key_pipe_0[g], value_pipe_0[g],
            key_pipe_0[g+1], value_pipe_0[g+1]);
        end
    endgenerate
    
    // Layer 1
    generate 
        for(g = 0; g <= 5; g = g + 1) begin
            if(g == 0 || g == 3) begin
                generic_comparator cmp(key_pipe_0[g], value_pipe_0[g],
                key_pipe_0[g+2], value_pipe_0[g+2],
                key_pipe_1[g], value_pipe_1[g],
                key_pipe_1[g+2], value_pipe_1[g+2]);
            end
            else if(g == 1 || g == 4)begin
                generic_identity id(key_pipe_0[g], value_pipe_0[g], 
                key_pipe_1[g], value_pipe_1[g]);
            end
        end
    endgenerate
    
    // Layer 2
    generate 
        for(g = 0; g <= 5; g = g + 1) begin
            if(g == 1) begin
                generic_comparator cmp(key_pipe_1[g], value_pipe_1[g],
                key_pipe_1[g+3], value_pipe_1[g+3],
                key_pipe_2[g], value_pipe_2[g],
                key_pipe_2[g+3], value_pipe_2[g+3]);
            end
            else if (g != 4) begin
                generic_identity id(key_pipe_1[g], value_pipe_1[g], 
                key_pipe_2[g], value_pipe_2[g]);
            end
        end
    endgenerate
    
    // Layer 3
    generate 
        for(g = 0; g < 5; g = g + 2) begin
            generic_comparator cmp(key_pipe_2[g], value_pipe_2[g],
            key_pipe_2[g+1], value_pipe_2[g+1],
            key_pipe_3[g], value_pipe_3[g],
            key_pipe_3[g+1], value_pipe_3[g+1]);
        end
    endgenerate
    
    // Layer 4
    generate 
        for(g = 0; g <= 5; g = g + 1) begin
            if(g == 1 || g == 3) begin
                generic_comparator cmp(key_pipe_3[g], value_pipe_3[g],
                key_pipe_3[g+1], value_pipe_3[g+1],
                key_pipe_4[g], value_pipe_4[g],
                key_pipe_4[g+1], value_pipe_4[g+1]);
            end
            else if (g == 0 || g == 5) begin
                generic_identity id(key_pipe_3[g], value_pipe_3[g], 
                key_pipe_4[g], value_pipe_4[g]);
            end
        end
    endgenerate
    
    // Layer 5
    generate 
        for(g = 0; g <= 5; g = g + 1) begin
            if(g == 2) begin
                generic_comparator cmp(key_pipe_4[g], value_pipe_4[g],
                key_pipe_4[g+1], value_pipe_4[g+1],
                key_pipe_5[g], value_pipe_5[g],
                key_pipe_5[g+1], value_pipe_5[g+1]);
            end
            else if (g != 3) begin
                generic_identity id(key_pipe_4[g], value_pipe_4[g], 
                key_pipe_5[g], value_pipe_5[g]);
            end
        end
    endgenerate
    
    
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            for(i = 0; i <= 5; i = i + 1) begin
                reg_score[i] <= 0;
                reg_string[i] <= 0;
            end
        end
        else if (insert) begin
            // Overwrite the smallest element at position 5.
            // The sorting network will then sift it to the correct position.
            reg_score[5] <= key_insert;
            reg_string[5] <= string_insert;
        end
        else begin // Update the list.
            for(i = 0; i <= 5; i = i + 1) begin
                reg_score[i] <= key_pipe_5[i];
                reg_string[i] <= value_pipe_5[i];
            end
        end
    end
    
    
    
    
endmodule

// Sorts two key-value pairs.
module generic_comparator(
    input [`KEY_SIZE - 1:0] key_A,
    input [`VALUE_SIZE - 1:0] value_A,
    input [`KEY_SIZE - 1:0] key_B,
    input [`VALUE_SIZE - 1:0] value_B,
    output [`KEY_SIZE - 1:0] key_greater,
    output [`VALUE_SIZE - 1:0] value_greater,
    output [`KEY_SIZE - 1:0] key_lesser,
    output [`VALUE_SIZE - 1:0] value_lesser
);
    wire greater;
    assign greater = key_A >= key_B;
    assign key_greater = greater ? key_A : key_B;
    assign key_lesser = greater ? key_B : key_A;
    assign value_greater = greater ? value_A : value_B;
    assign value_lesser = greater ? value_B : value_A;
endmodule

// Identity function for key-value pairs. Should be optimized out by the synthesizer.
module generic_identity(
    input [`KEY_SIZE - 1:0] key_in,
    input [`VALUE_SIZE - 1:0] value_in,
    output [`KEY_SIZE - 1:0] key_out,
    output [`VALUE_SIZE - 1:0] value_out
);
    assign key_out = key_in;
    assign value_out = value_in;
endmodule
`define ALPHABET_SIZE 5
`define SCORE_SIZE 16
`define score reg [`SCORE_SIZE - 1:0]
`define string reg [3 * `ALPHABET_SIZE - 1:0]
`define score_pipe wire [`SCORE_SIZE - 1:0]
`define string_pipe wire [3 * `ALPHABET_SIZE - 1:0]

module scoreboard_tb(

    );
    
    reg clk = 0, rst;
    reg insert;
    `score_pipe score [0:4];
    `string_pipe string [0:4];
    `score new_score;
    `string new_string;
    scoreboard sb(clk, rst, insert,
    new_score, new_string,
    score[0], string[0],
    score[1], string[1],
    score[2], string[2],
    score[3], string[3],
    score[4], string[4]);
    
    
    always #5 clk = ~clk;
    
    task display_scoreboard;
        begin
            $display("{(1st: %d, %d)(2nd: %d, %d)(3rd: %d, %d)(4th: %d, %d)(5th: %d, %d)}", 
            score[0], string[0], score[1], string[1], score[2], string[2], score[3], string[3],
            score[4], string[4]);
        end
    endtask
    
    initial begin
        rst <= 1;
        insert <= 0;
        $display("Start simulation.");
        @(posedge clk) begin
            display_scoreboard;
            rst <= 0;
        end
        @(posedge clk) begin
            new_score <= 15;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd3, `ALPHABET_SIZE'd0, `ALPHABET_SIZE'd3 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 10;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd2, `ALPHABET_SIZE'd0, `ALPHABET_SIZE'd2 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 12;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd1, `ALPHABET_SIZE'd1, `ALPHABET_SIZE'd1 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 14;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd0, `ALPHABET_SIZE'd5, `ALPHABET_SIZE'd0 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 25;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd9, `ALPHABET_SIZE'd10, `ALPHABET_SIZE'd10 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 5;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd8, `ALPHABET_SIZE'd10, `ALPHABET_SIZE'd10 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 7;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd8, `ALPHABET_SIZE'd10, `ALPHABET_SIZE'd10 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 13;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd8, `ALPHABET_SIZE'd10, `ALPHABET_SIZE'd10 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin 
            display_scoreboard;
            new_score <= 19;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd6, `ALPHABET_SIZE'd7, `ALPHABET_SIZE'd2 };
        end
        @(negedge clk) insert <= 0;
        @(posedge clk) begin
            display_scoreboard;
            new_score <= 50;
            insert <= 1;
            new_string <= { `ALPHABET_SIZE 'd5, `ALPHABET_SIZE'd1, `ALPHABET_SIZE'd1 };
        end
        @(negedge clk) insert <= 0;
        
        @(posedge clk) display_scoreboard;
        $display("End simulation.");
        $finish;
        
    end
    
endmodule
module clock_refresh_gen(clk, clk_div);   
    parameter n = 12;     
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


module seven_segment(
    input clk,
    input [27:0] display_queue,
    output [3:0] digit_select,
    output [6:0] display_select
);
    wire clk_refresh;
    clock_refresh_gen(clk, clk_refresh);
    reg [1:0] step = 0;
    reg [3:0] digit;
    reg [6:0] display;
    always @(posedge clk_refresh) begin
        step <= step + 1;
        case(step)
            0: begin 
            digit <= 4'b0111;
            display <= display_queue[27:21];
            end
            1: begin
            digit <= 4'b1011;
            display <= display_queue[20:14];
            end
            2: begin
            digit <= 4'b1101;
            display <= display_queue[13:7];
            end
            3: begin
            digit <= 4'b1110;
            display <= display_queue[6:0];
            end
            default: begin
            digit <= 4'b1111;
            display <= display_queue[6:0];
            end
        endcase
    end
    
    assign digit_select = digit;
    assign display_select = display;
    
endmodule

module hex_decoder(
    input [3:0] hex_int,
    output reg [6:0] display
);
    // Seven-Segment character set.
    parameter SSCHAR_0 = 7'b1000000;
    parameter SSCHAR_1 = 7'b1111001;
    parameter SSCHAR_2 = 7'b0100100;
    parameter SSCHAR_3 = 7'b0110000;
    parameter SSCHAR_4 = 7'b0011001;
    parameter SSCHAR_5 = 7'b0010010;
    parameter SSCHAR_6 = 7'b0000011;
    parameter SSCHAR_7 = 7'b1011000;
    parameter SSCHAR_8 = 7'b0000000;
    parameter SSCHAR_9 = 7'b0010000;
    parameter SSCHAR_A = 7'b0001000;
    parameter SSCHAR_B = 7'b0000011;
    parameter SSCHAR_C = 7'b0100111;
    parameter SSCHAR_D = 7'b0100001;
    parameter SSCHAR_E = 7'b0000110;
    parameter SSCHAR_F = 7'b0001110;
    parameter SSCHAR_NULL = 7'b1111111;
    always @* begin
    case(hex_int)
    0: display = SSCHAR_0;
    1: display = SSCHAR_1;
    2: display = SSCHAR_2;
    3: display = SSCHAR_3;
    4: display = SSCHAR_4;
    5: display = SSCHAR_5;
    6: display = SSCHAR_6;
    7: display = SSCHAR_7;
    8: display = SSCHAR_8;
    9: display = SSCHAR_9;
    10: display = SSCHAR_A;
    11: display = SSCHAR_B;
    12: display = SSCHAR_C;
    13: display = SSCHAR_D;
    14: display = SSCHAR_E;
    15: display = SSCHAR_F;
    default: display = SSCHAR_NULL;
    endcase
    end
endmodule
module uart_receiver(

input clk, //input clock
input reset, //input reset 
input RxD, //input receving data line
output valid, //indicate the current RxData is a valid packet (rather than a packet in the process of being shifted in)
output [7:0]RxData // output for 8 bits data
// output [7:0]LED // output 8 LEDs
    );
    
//internal variables
reg shift; // shift signal to trigger shifting data
reg state, nextstate; // initial state and next state variable
reg [3:0] bitcounter; // 4 bits counter to count up to 9 for UART receiving
reg [1:0] samplecounter; // 2 bits sample counter to count up to 4 for oversampling
reg [13:0] counter; // 14 bits counter to count the baud rate
reg [9:0] rxshiftreg; //bit shifting register
reg [7:0] rxbuffer; // receiver buffer for complete packets
reg clear_bitcounter,inc_bitcounter,inc_samplecounter,clear_samplecounter; //clear or increment the counter

// constants
parameter clk_freq = 100_000_000;  // system clock frequency
parameter baud_rate = 9_600; //baud rate
parameter div_sample = 4; //oversampling
parameter div_counter = clk_freq/(baud_rate*div_sample);  // this is the number we have to divide the system clock frequency to get a frequency (div_sample) time higher than (baud_rate)
parameter mid_sample = (div_sample/2);  // this is the middle point of a bit where you want to sample it
parameter div_bit = 10; // 1 start, 8 data, 1 stop


assign RxData = rxshiftreg [8:1]; // assign the RxData from the shiftregister
assign valid = state == 0; // The packet is valid when the receiver is idle.
//UART receiver logic
always @ (posedge clk)
    begin 
        if (reset)begin // if reset is asserted
            state <=0; // set state to idle 
            rxshiftreg <= 0;
            bitcounter <=0; // reset the bit counter
            counter <=0; // reset the counter
            samplecounter <=0; // reset the sample counter
        end else begin // if reset is not asserted
            counter <= counter +1; // start count in the counter
            if (counter >= div_counter-1) begin // if counter reach the baud rate with sampling 
                counter <=0; //reset the counter
                state <= nextstate; // assign the state to nextstate
                if (shift)rxshiftreg <= {RxD,rxshiftreg[9:1]}; //if shift asserted, load the receiving data
                if (clear_samplecounter) samplecounter <=0; // if clear sampl counter asserted, reset sample counter
                if (inc_samplecounter) samplecounter <= samplecounter +1; //if increment counter asserted, start sample count
                if (clear_bitcounter) bitcounter <=0; // if clear bit counter asserted, reset bit counter
                if (inc_bitcounter)bitcounter <= bitcounter +1; // if increment bit counter asserted, start count bit counter
            end
        end
    end
   
//state machine

always @ (posedge clk) //trigger by clock
begin 
    shift <= 0; // set shift to 0 to avoid any shifting 
    clear_samplecounter <=0; // set clear sample counter to 0 to avoid reset
    inc_samplecounter <=0; // set increment sample counter to 0 to avoid any increment
    clear_bitcounter <=0; // set clear bit counter to 0 to avoid claring
    inc_bitcounter <=0; // set increment bit counter to avoid any count
    nextstate <=0; // set next state to be idle state
    case (state)
        0: begin // idle state
            if (RxD) // if input RxD data line asserted
              begin
              nextstate <=0; // back to idle state because RxD needs to be low to start transmission    
              end
            else begin // if input RxD data line is not asserted
                nextstate <=1; //jump to receiving state 
                clear_bitcounter <=1; // trigger to clear bit counter
                clear_samplecounter <=1; // trigger to clear sample counter
            end
        end
        1: begin // receiving state
            nextstate <= 1; // DEFAULT 
            if (samplecounter== mid_sample - 1) shift <= 1; // if sample counter is 1, trigger shift 
                if (samplecounter== div_sample - 1) begin // if sample counter is 3 as the sample rate used is 3
                    if (bitcounter == div_bit - 1) begin // check if bit counter if 9 or not
                nextstate <= 0; // back to idle state if bit counter is 9 as receving is complete
                end 
                inc_bitcounter <=1; // trigger the increment bit counter if bit counter is not 9
                clear_samplecounter <=1; //trigger the sample counter to reset the sample counter
            end else inc_samplecounter <=1; // if sample is not equal to 3, keep counting
        end
       default: nextstate <=0; //default idle state
     endcase
end         
endmodule

`include "constants.svh"
module txt_pixel(
    input clk,
    input [LEVEL_SIZE-1:0] level,
    input [1:0] input_pos,
    input [STRING_SIZE-1:0] player_name,
    input [STRING_SIZE*5-1:0] player_name_record,
    input [SCORE_SIZE-1:0] score,
    input [SCORE_SIZE-1:0] score_cur,
    input [SCORE_SIZE*5-1:0] score_record,
    input [STATE_SIZE-1:0] state,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input rst,
    output logic [11:0] pixel_out,
    output logic valid
    );
parameter G = 16;
parameter A = 10;
parameter M = 22;
parameter E = 14;
parameter S = 28;
parameter C = 12;
parameter O = 24;
parameter R = 27;
parameter T = 29;
parameter V = 31;
parameter L = 21;
parameter D = 13;
parameter N = 23;
parameter I = 18;
logic [CHAR_SIZE-1:0] ch[0:2];
logic [CHAR_SIZE-1:0] ch_record[4:0][0:2];
logic [SCORE_SIZE-1:0] score_rank[4:0];
wire [11:0] pixel_out_ready;
logic bound;
logic [5:0] mem_txt_addr;
reg [9:0] reg_h_cnt_compressed;
reg [9:0] reg_v_cnt_compressed;
assign {ch[0],ch[1],ch[2]}=player_name;
assign {ch_record[4][0],ch_record[4][1],ch_record[4][2],ch_record[3][0],ch_record[3][1],
        ch_record[3][2],ch_record[2][0],ch_record[2][1],ch_record[2][2],ch_record[1][0],
        ch_record[1][1],ch_record[1][2],ch_record[0][0],ch_record[0][1],ch_record[0][2]}=player_name_record;
assign {score_rank[4],score_rank[3],score_rank[2],score_rank[1],score_rank[0]}=score_record;
assign pixel_out=(bound)?12'hfff:pixel_out_ready;


logic [24:0] counter;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter <=0 ;
    end
    else begin
        if(counter<25'd25_000_000) begin
            counter<=counter+1;
        end
        else begin
           counter<=0; 
        end
    end
end




always @* begin
        valid=0;
        mem_txt_addr=0;
        reg_h_cnt_compressed=0;
        reg_v_cnt_compressed=0;
        bound=0;
        if(state==SCENE_GAME_START&&counter<25'd12_500_000) begin //scene begin
            if(v_cnt>=28&&v_cnt<140) begin
            if(h_cnt>=100&&h_cnt<180) begin
            mem_txt_addr=D;
            reg_h_cnt_compressed=(h_cnt-100)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=190&&h_cnt<270) begin
            reg_h_cnt_compressed=(h_cnt-190)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=A;
            valid=1;
            end
            else if(h_cnt>=280&&h_cnt<360) begin
            mem_txt_addr=N;
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=370&&h_cnt<450)begin
            mem_txt_addr=C;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=460&&h_cnt<540)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-460)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
        end
        else if(v_cnt>=160&&v_cnt<216) begin
            if(h_cnt>=125&&h_cnt<165) begin
                mem_txt_addr=I;
                reg_h_cnt_compressed=(h_cnt-125)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=175&&h_cnt<215) begin
                mem_txt_addr=N;
                reg_h_cnt_compressed=(h_cnt-175)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=225&&h_cnt<265) begin
                mem_txt_addr=V;
                reg_h_cnt_compressed=(h_cnt-225)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=275&&h_cnt<315) begin
                mem_txt_addr=A;
                reg_h_cnt_compressed=(h_cnt-275)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=325&&h_cnt<365) begin
                mem_txt_addr=D;
                reg_h_cnt_compressed=(h_cnt-325)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=375&&h_cnt<415) begin
                mem_txt_addr=E;
                reg_h_cnt_compressed=(h_cnt-375)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=425&&h_cnt<465) begin
                mem_txt_addr=R;
                reg_h_cnt_compressed=(h_cnt-425)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=475&&h_cnt<515) begin
                mem_txt_addr=S;
                reg_h_cnt_compressed=(h_cnt-475)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
        end
        end//scene end

        else if(state==SCENE_LEVEL_START) begin//scene begin
            if(v_cnt>=28&&v_cnt<140) begin
            if(h_cnt>=100&&h_cnt<180) begin
            mem_txt_addr=L;
            reg_h_cnt_compressed=(h_cnt-100)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=190&&h_cnt<270) begin
            reg_h_cnt_compressed=(h_cnt-190)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=E;
            valid=1;
            end
            else if(h_cnt>=280&&h_cnt<360) begin
            mem_txt_addr=V;
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=370&&h_cnt<450)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=460&&h_cnt<540)begin
            mem_txt_addr=L;
            reg_h_cnt_compressed=(h_cnt-460)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
        end

        else if(v_cnt>=160&&v_cnt<272) begin
            if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            mem_txt_addr=level/10;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=level%10;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end

        end
        end//scene end
        else if(state==SCENE_INGAME) begin//scene begin
            if(v_cnt>=18&&v_cnt<74) begin

        if(h_cnt>=200&&h_cnt<240) begin
            mem_txt_addr=(score_cur/10000)%10;
            reg_h_cnt_compressed=(h_cnt-200)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=250&&h_cnt<290) begin
            mem_txt_addr=(score_cur/1000)%10;
            reg_h_cnt_compressed=(h_cnt-250)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=300&&h_cnt<340) begin
            reg_h_cnt_compressed=(h_cnt-300)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            mem_txt_addr=(score_cur/100)%10;
            bound=0;
            valid=1;
        end
        else if(h_cnt>=350&&h_cnt<390) begin
            mem_txt_addr=(score_cur/10)%10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-350)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
        end
        else if(h_cnt>=400&&h_cnt<440) begin
            mem_txt_addr=(score_cur)%10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-400)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
        end

        end
        end//scene end
        else if(state==SCENE_GAME_OVER) begin //scene begin
            if(v_cnt>=28&&v_cnt<140) begin
        if(h_cnt>=145&&h_cnt<225) begin
            mem_txt_addr=G;
            reg_h_cnt_compressed=(h_cnt-145)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=A;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=M;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        else if(h_cnt>=415&&h_cnt<495)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-415)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        end



        else if(v_cnt>=160&&v_cnt<272) begin
            if(h_cnt>=145&&h_cnt<225) begin
            mem_txt_addr=O;
            reg_h_cnt_compressed=(h_cnt-145)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            mem_txt_addr=V;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end
        else if(h_cnt>=415&&h_cnt<495)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-415)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end
        end
        end//scene end

        else if(state==SCENE_SCOREBOARD) begin //scene begin
        if(v_cnt>=18&&v_cnt<74) begin


        if(h_cnt>=245&&h_cnt<285) begin
            mem_txt_addr=ch[0]+10;
            reg_h_cnt_compressed=(h_cnt-245)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=300&&h_cnt<340) begin
            reg_h_cnt_compressed=(h_cnt-300)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            mem_txt_addr=ch[1]+10;
            bound=0;
            valid=1;
        end
        else if(h_cnt>=355&&h_cnt<395) begin
            mem_txt_addr=ch[2]+10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-355)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
        end

        end

        if(v_cnt>=13&&v_cnt<79) begin//left right bound
        if(h_cnt>=235&&h_cnt<240&&(input_pos==2'd3||input_pos==2'd0)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=290&&h_cnt<295&&(input_pos==2'd0||input_pos==2'd1)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=345&&h_cnt<350&&(input_pos==2'd1||input_pos==2'd2)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=400&&h_cnt<405&&(input_pos==2'd2||input_pos==2'd3)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end


        end

        else if(v_cnt>=89&&v_cnt<145) begin//score

            if(h_cnt>=40&&h_cnt<80) begin
            mem_txt_addr=S;
            reg_h_cnt_compressed=(h_cnt-40)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=90&&h_cnt<130) begin
            reg_h_cnt_compressed=(h_cnt-90)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            mem_txt_addr=C;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=140&&h_cnt<180) begin
            mem_txt_addr=O;
            reg_h_cnt_compressed=(h_cnt-140)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=190&&h_cnt<230)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-190)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<280)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-240)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<400) begin
                mem_txt_addr=(score/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=410&&h_cnt<450) begin
                mem_txt_addr=(score/1000)%10;
                reg_h_cnt_compressed=(h_cnt-410)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=460&&h_cnt<500) begin
                mem_txt_addr=(score/100)%10;
                reg_h_cnt_compressed=(h_cnt-460)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=510&&h_cnt<550) begin
                mem_txt_addr=(score/10)%10;
                reg_h_cnt_compressed=(h_cnt-510)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=560&&h_cnt<600) begin
                mem_txt_addr=(score)%10;
                reg_h_cnt_compressed=(h_cnt-560)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end

        end

        else if(v_cnt>=8&&v_cnt<13) begin//upper bound

        if(h_cnt>=235&&h_cnt<295&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=290&&h_cnt<350&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=345&&h_cnt<405&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<405&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end

        end

        else if(v_cnt>=79&&v_cnt<84) begin//lower bound


            if(h_cnt>=235&&h_cnt<295&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=290&&h_cnt<350&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=345&&h_cnt<405&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<405&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end            
        end

        else if(v_cnt>=150&&v_cnt<178)begin//rank 1
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=1;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            mem_txt_addr=ch_record[0][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[0][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[0][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[0]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[0]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[0]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[0]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[0])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=183&&v_cnt<211)begin//rank 2
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=2;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            mem_txt_addr=ch_record[1][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[1][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[1][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[1]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[1]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[1]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[1]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[1])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=216&&v_cnt<244)begin//rank 3
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=3;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            mem_txt_addr=ch_record[2][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[2][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[2][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[2]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[2]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[2]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[2]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[2])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=249&&v_cnt<277)begin//rank 4
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=4;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            mem_txt_addr=ch_record[3][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[3][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[3][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[3]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[3]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[3]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[3]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[3])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=282&&v_cnt<310)begin//rank 5
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=5;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            mem_txt_addr=ch_record[4][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[4][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[4][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[4]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[4]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[4]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[4]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[4])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
        end
        end//scene end


end


memory_txt (
        .clk(clk),
        .txt_addr(mem_txt_addr),
        .h_point(reg_h_cnt_compressed),
        .v_point(reg_v_cnt_compressed),
        .pixel(pixel_out_ready)
    );
endmodule

module top_childboard(
    input [5:0] data_trans,
    input req,
    input clk,
    input rst,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    input ack,
    output hsync,
    output vsync
);

wire clk_recv, clk_db;
clock_divider_childboard #(.n(5))(clk, clk_recv);
clock_divider_childboard #(.n(1))(clk, clk_db);
logic [MESSAGE_SIZE-1:0] datagram;
async_oneway_receiver(
    .clk_receive(clk),
    .clk_db(clk_db),
    .transmit_ctrl(req),
    .packet_pulse(ack),
    .din(data_trans),
    .read_buffer(datagram)
);

output_interface(
    .clk(clk),
    .rst(rst),
    .datagram(datagram),
    .vgaRed(vgaRed),
    .vgaGreen(vgaGreen),
    .vgaBlue(vgaBlue),
    .hsync(hsync),
    .vsync(vsync)
);


endmodule

module clock_divider_childboard(clk, clk_div);   
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
        .score_cur(score_data),
        .rst(rst),
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
            if(txt_valid) begin
                rendered_pixel = txt_pixel_out;
            end
            else if(laser_layer_valid) begin
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

module mother_board(
    input clk,
    input rst,
    input RxD,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input ACK [0:3],
    output [5:0] DOUT [0:3],
    output REQ [0:3],
    output [15:0] led,
    output [3:0] DIGIT,
    output [6:0] DISPLAY,
    
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    
    );
    
    wire [MESSAGE_SIZE-1:0] datagram;
    wire sending_clk;
    control_core (
    .clk(clk),
    .rst(rst),
    .btnU(btnU),
    .btnD(btnD),
    .btnL(btnL),
    .btnR(btnR),
    .RxD(RxD),
    .sending_clk(sending_clk),
    .datagram(datagram),
    .led(led),
    .DIGIT(DIGIT),
    .DISPLAY(DISPLAY)
    );
    wire packet_valid = 1;
    
    generate
    for(genvar g = 0; g < 4; ++g) begin
        async_oneway_transmitter(
        .clk_sender(sending_clk),
        .packet_pulse(ACK[g]),
        .packet_out(DOUT[g]),
        .transmit_ctrl(REQ[g]),
        .async_load(sending_clk),
        .datagram_in(datagram)
        );
    end
    endgenerate
    
    /*
    wire [MESSAGE_SIZE-1:0] recv_data;
    receiver #(.n(MESSAGE_SIZE))
    (
    .clk_receiver(clk),
    .wire_req(ctrl_req),
    .wire_data_deliver(ctrl_out),
    .wire_data_out(recv_data),
    .reg_ack(interface_ack),
    .reg_valid(packet_valid)
    );
    
    
    reg [MESSAGE_SIZE-1:0] reg_datagram;
    always @(posedge clk) begin
        if(rst) reg_datagram <= 0;
        else if(packet_valid) reg_datagram <= datagram;
    end
    
    output_interface(
    .clk(clk),
    .rst(rst),
    .datagram(reg_datagram),
    .vgaRed(vgaRed),
    .vgaGreen(vgaGreen),
    .vgaBlue(vgaBlue),
    .hsync(hsync),
    .vsync(vsync)
    );
    
    */
endmodule

module memory_txt(
    input [5:0] txt_addr,
    input [9:0] h_point,
    input [9:0] v_point,
    input clk,
    output [11:0] pixel
    );
wire [10:0] pixel_addr;
assign pixel_addr=(h_point+v_point*5+txt_addr*40)%1440;
wire signal;
assign pixel =(signal==1)?12'hfff:12'h000;
blk_mem_txt(
.clka(clk),
.addra(pixel_addr),
.douta(signal)
);

endmodule


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
	parameter RENDER_LIMIT = 8;
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
	
	logic [3:0] init_select [0:RENDER_LIMIT-1];
	logic [3:0] init_select_buf [0:RENDER_LIMIT-1];
	always @* begin
	   init_select[0] = 0;
	   for(int i = 0; i < OBJ_LIMIT; ++i) begin
	       if(in_frame[i]) begin
	           init_select[0] = i;
	           break;
	       end
	   end
	   
	   for(int g = 1; g < RENDER_LIMIT; ++g) begin
	       init_select[g] = init_select[g-1];
	       for(int i = 0; i < OBJ_LIMIT; ++i) begin
	           if(in_frame[i] && i > init_select[g-1]) begin
	               init_select[g] = i;
	               break;
	           end
	       end
	   end
	end
	
	
	
	logic [3:0] alien_select [0:RENDER_LIMIT-1];
	
	always @* begin
	   alien_select = init_select_buf;
	end
	
	logic select_reset = 0;
	always @(posedge clk_50MHz) begin
	   if(h_cnt == VGA_XRES - 1 && v_cnt == VGA_YRES - 1) begin
           init_select_buf <= init_select;
       end
	end
	
	wire [RENDER_LIMIT-1:0] palette;
	wire [18:0] addr [0:RENDER_LIMIT-1];
	generate
	   for(genvar g = 0; g < RENDER_LIMIT; ++g) begin
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
	
	generate
	for(genvar g = 0; g < RENDER_LIMIT; g+= 2) begin
	   alien_block_mem(
	   .clka(clk_frame),
	   .addra(addr[g]),
	   .douta(palette[g]),
	   .clkb(clk_frame),
	   .addrb(addr[g+1]),
	   .doutb(palette[g+1])
	   );
	
	end
	endgenerate
	
	
	always @* begin
	    pixel_out = 0;
	    layer_valid = 0;
	    for(int i = 0; i < RENDER_LIMIT; ++i) begin
	       if(pixel_valid[alien_select[i]] && (((palette[i] && deriv_select[alien_select[i]] > 1 && alien_type[alien_select[i]] > 1) || (!palette[i] && deriv_select[alien_select[i]] <= 1 && alien_type[alien_select[i]] > 1))
	       || (palette[i] && alien_type[alien_select[i]] <= 1))) begin
	           layer_valid = 1;
	           if(frame_num[alien_select[i]] <= 1) 
                   case(alien_type[alien_select[i]])
                    0: pixel_out = { 4'h4 - (distance[i] >> 3), 4'h4 - (distance[i] >> 3), 4'hF - distance[i] };
                    1: pixel_out = { 4'h4 - (distance[i] >> 3), 4'hF - distance[i], 4'h4 - (distance[i] >> 3) };
                    2: pixel_out = { 4'hF - distance[i], 4'h4 - (distance[i] >> 3), 4'h4 - (distance[i] >> 3) };
                    3: pixel_out = { 4'hF - distance[i], 4'h4 - (distance[i] >> 3), 4'hF - distance[i] };
                   endcase
               else pixel_out = 12'h0_C_F;
               break;
	       end
	    end
	    
	end
endmodule

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
    logic in_beam;
    logic in_beam_center;
	always @* begin
	   if(in_beam_center) pixel_out = 12'h0_C_F;
	   else if(in_beam) pixel_out = 12'h2_8_F;
	   else pixel_out = 12'h2_4_F;
       in_beam_center = ((v_cnt >= laser_end_y && v_cnt <= laser_end_y + 40 - 2 * laser_r
	   && h_cnt <= VGA_XRES / 2 + v_cnt / 8 && h_cnt >= VGA_XRES / 2 - v_cnt / 8));
       in_beam = ((v_cnt >= laser_end_y && v_cnt <= laser_end_y + 40 - 2 * laser_r
	   && h_cnt <= VGA_XRES / 2 + v_cnt / 8 + 20 && h_cnt >= VGA_XRES / 2 - v_cnt / 8 - 20));
	end
	
	always @(*) begin
	   if(laser_quadrant == QUADRANT && laser_active && (in_beam ||
	   (h_cnt <= 20 - laser_r || h_cnt >= VGA_XRES - 20 + laser_r || v_cnt >= VGA_YRES - 20 + laser_r || v_cnt <= 20 - laser_r))) begin
	       // Set union of the laser itself and a square frame around the screen.
	       layer_valid = 1;
	   end
	   else layer_valid = 0;
	end
	
endmodule

module layer_background(
    input clk,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [11:0] pixel
    );
    
    // TODO: Instantiate a memory block for the (sparse?) background using its .coe form.
    
    // Default.
    wire [16:0] pixel_addr = (v_cnt >> 1) * 320 + (h_cnt >> 1);
    wire [3:0] palette_select;
    
    parameter [11:0] PALETTE_COLOR [0:15] = {
    12'h2_2_2, 12'h2_3_3, 12'h2_3_3, 12'hc_c_c,
    12'h2_2_3, 12'h2_3_3, 12'h2_3_3, 12'h1_1_3,
    12'h3_3_3, 12'h2_3_3, 12'h1_4_4, 12'h1_3_3,
    12'h2_3_3, 12'h3_2_3, 12'h4_4_4, 12'h1_3_3
    };
    assign pixel = PALETTE_COLOR[palette_select];
    background_block_mem(
    .clka(clk),
    .addra(pixel_addr[15:0]),
    .douta(palette_select)
    );
    
endmodule

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

module control_core(
    input clk, // 100MHz
    input rst, // btnC
    // pushbutton inputs for debug and for when no dancepad is available
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input RxD,
    output sending_clk,
    output loading_clk,
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
    wire clk_dsp;
    clock_divider_two_power #(.n(4))(
    .clk(clk),
    .clk_div(clk_dsp)
    );
    clock_divider_two_power #(.n(4))(
    .clk(clk),
    .clk_div(sending_clk)
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
    assign loading_clk = clk_frame;
    
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
        else if(packet_valid) event_buffer <= event_packet | { 4'b0000, btnR, btnL, btnD, btnU };
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
    else dir = RIGHT;
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
    .clk_dsp(clk_dsp),
    .clk_sort(clk_main),
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
    hex_decoder(frame_data[15:12], digit[0]);
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
    assign led[6] = frame_data[0];
    
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
        rand_deg = 45;//deg_distribution_2[random_num[3:0]];        
        end
        default: begin
        rand_type = type_distribution_5[random_num[2:0]];
        rand_deg = 45;//deg_distribution_2[random_num[3:0]];        
        end
        endcase
    end
    
    always @* begin
    new_alien._state = ACTIVE;
    new_alien._type = rand_type;
    new_alien._frame_num = 0;
    new_alien._r = (cur_level >> 1) + 8;
    new_alien._theta = rand_deg;
    new_alien._hp = { rand_type + 1 };
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

module async_oneway_transmitter(
input clk_send,
input rst,
input sync_load,
input [MESSAGE_SIZE-1:0] datagram_in,
output logic [5:0] packet_out,
output logic transmit_ctrl,
output logic packet_pulse
    );
    parameter state_idle = 0;
    parameter state_load = 1;
    parameter state_send = 2;
    parameter state_pulse = 3;
    logic [15:0] ptr;
    logic [1:0] state;
    logic [MESSAGE_SIZE-1:0] send_buffer;
    
    always @(posedge clk_send, posedge rst) begin
    if(rst) begin
        state <= state_idle;
        ptr <= 0;
    end
    else if(state == state_idle) begin
        state <= state_load;
        send_buffer <= datagram_in;
        packet_pulse <= 0;
        ptr <= 0;
        transmit_ctrl <= 0;
    end
    else begin
        if(state == state_load) begin
            state <= state_send;
        end
        else if(state == state_send) begin
            state <= state_pulse;
            packet_out <= send_buffer[5:0];
            ptr <= ptr + 6;
            send_buffer <= send_buffer >> 6;
            packet_pulse <= 1;
        end
        else if(state == state_pulse) begin
            packet_pulse <= 0;
            if(ptr >= MESSAGE_SIZE) begin
                state <= state_idle;
                send_buffer <= datagram_in;
                transmit_ctrl <= 1;
            end
            else state <= state_send;
        end
    end
    end
    
endmodule

module async_oneway_receiver(
input clk_receive,
input clk_db,
input transmit_ctrl,
input packet_pulse,
input [5:0] din,
output logic [MESSAGE_SIZE-1:0] read_buffer
    );
    
    logic [7:0] packet_pre;
    generate
    for(genvar g = 0; g < 6; ++g) begin
        debounce(packet_pre[g], din[g], clk_db);        
    end
    endgenerate
    debounce(packet_pre[6], packet_pulse, clk_db);
    debounce(packet_pre[7], transmit_ctrl, clk_db);
    logic [MESSAGE_SIZE-1+6:0] recv_buffer = 0;
    
	always @(posedge packet_pre[6]) begin
		recv_buffer <= { packet_pre[5:0], recv_buffer[MESSAGE_SIZE-1+6:6]};
	end
    
	always @(posedge packet_pre[7]) begin
        read_buffer <= recv_buffer[MESSAGE_SIZE-1+6:MESSAGE_SIZE%6];
	end
    
endmodule

module alien_renderer(
    input clk,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input AlienData obj_data,
    output logic [1:0] deriv_select,
    output logic [10:0] pixel_addr,
    output logic in_frame,
    output logic valid
    );
    parameter QUADRANT = 0;
    parameter [9:0] X_OVERFLOW_GUARD = 128;
    wire [9:0] h_cnt_guarded = h_cnt + X_OVERFLOW_GUARD;
    logic side;
    logic [9:0] halfwidth;
    logic [9:0] halfheight;
    logic [9:0] y_addr_buffer;
    logic [9:0] x_addr_buffer;
    logic [10:0] product_buffer;
    logic [10:0] pixel_addr_buffer;
    logic [9:0] halfwidth_buffer;
    logic [9:0] halfheight_buffer;
    always @* begin
        side = h_cnt_guarded < obj_data._x_pos;
        halfwidth = 32 - obj_data._r;
        halfheight = 32 - obj_data._r;
    end
    
    always @(posedge clk) begin
        if(!obj_data._active || obj_data._quadrant != QUADRANT) begin
             valid <= 0;
             in_frame <= 0;
        end
        else begin
            in_frame <= 1;
            if(v_cnt <= obj_data._y_pos - halfheight_buffer * 4 || v_cnt >= obj_data._y_pos + halfheight_buffer * 4) valid <= 0;
            else if(side == 0) begin // Right-side. No mirror.
                if(h_cnt_guarded - obj_data._x_pos >= halfwidth_buffer * 4) valid <= 0;
                else valid <= 1;
            end
            else begin // Left-side. Mirror.
                if(obj_data._x_pos - h_cnt_guarded >= halfwidth_buffer * 4 - 4) valid <= 0;
                else valid <= 1;
            end
        end
    end
    
    always @(posedge clk) begin
        halfwidth_buffer <= halfwidth;
        halfheight_buffer <= halfheight;
        y_addr_buffer <= (((v_cnt - (obj_data._y_pos - halfheight_buffer * 4))) / 4);
        pixel_addr <= pixel_addr_buffer;
        product_buffer <= y_addr_buffer * halfwidth_buffer;
        if(side == 0) begin // Right-side. No mirror.
            deriv_select <= obj_data._deriv_right;
            x_addr_buffer <= ((h_cnt_guarded - obj_data._x_pos) / 4);
            pixel_addr_buffer <= product_buffer + x_addr_buffer;
        
        end
        else begin // Left-side. Mirror.
            deriv_select <= obj_data._deriv_left;
            x_addr_buffer <= ((obj_data._x_pos - h_cnt_guarded) / 4);
            pixel_addr_buffer <= product_buffer + x_addr_buffer;
        
        end
    end
    
endmodule


module alien_pixel_reader(
    input clk,
    input [1:0] frame_num,
    input [1:0] alien_type,
    input [3:0] size_select,
    input [1:0] deriv_select,
    input [10:0] read_addr,
    output logic [18:0] addr_out
    );
    logic [18:0] pixel_addr;
    always @(posedge clk) addr_out <= pixel_addr;
    
parameter [18:0] address_0_0_0_0 = 0;
parameter [18:0] address_0_0_0_1 = 2048;
parameter [18:0] address_0_0_0_2 = 4096;
parameter [18:0] address_0_0_0_3 = 6144;
parameter [18:0] address_0_0_1_0 = 8192;
parameter [18:0] address_0_0_1_1 = 10240;
parameter [18:0] address_0_0_1_2 = 12288;
parameter [18:0] address_0_0_1_3 = 14336;
parameter [18:0] address_0_1_0_0 = 16384;
parameter [18:0] address_0_1_0_1 = 18432;
parameter [18:0] address_0_1_0_2 = 20480;
parameter [18:0] address_0_1_0_3 = 22528;
parameter [18:0] address_0_1_1_0 = 24576;
parameter [18:0] address_0_1_1_1 = 26624;
parameter [18:0] address_0_1_1_2 = 28672;
parameter [18:0] address_0_1_1_3 = 30720;
parameter [18:0] address_1_0_0_0 = 32768;
parameter [18:0] address_1_0_0_1 = 34690;
parameter [18:0] address_1_0_0_2 = 36612;
parameter [18:0] address_1_0_0_3 = 38534;
parameter [18:0] address_1_0_1_0 = 40456;
parameter [18:0] address_1_0_1_1 = 42378;
parameter [18:0] address_1_0_1_2 = 44300;
parameter [18:0] address_1_0_1_3 = 46222;
parameter [18:0] address_1_1_0_0 = 48144;
parameter [18:0] address_1_1_0_1 = 50066;
parameter [18:0] address_1_1_0_2 = 51988;
parameter [18:0] address_1_1_0_3 = 53910;
parameter [18:0] address_1_1_1_0 = 55832;
parameter [18:0] address_1_1_1_1 = 57754;
parameter [18:0] address_1_1_1_2 = 59676;
parameter [18:0] address_1_1_1_3 = 61598;
parameter [18:0] address_2_0_0_0 = 63520;
parameter [18:0] address_2_0_0_1 = 65320;
parameter [18:0] address_2_0_0_2 = 67120;
parameter [18:0] address_2_0_0_3 = 68920;
parameter [18:0] address_2_0_1_0 = 70720;
parameter [18:0] address_2_0_1_1 = 72520;
parameter [18:0] address_2_0_1_2 = 74320;
parameter [18:0] address_2_0_1_3 = 76120;
parameter [18:0] address_2_1_0_0 = 77920;
parameter [18:0] address_2_1_0_1 = 79720;
parameter [18:0] address_2_1_0_2 = 81520;
parameter [18:0] address_2_1_0_3 = 83320;
parameter [18:0] address_2_1_1_0 = 85120;
parameter [18:0] address_2_1_1_1 = 86920;
parameter [18:0] address_2_1_1_2 = 88720;
parameter [18:0] address_2_1_1_3 = 90520;
parameter [18:0] address_3_0_0_0 = 92320;
parameter [18:0] address_3_0_0_1 = 94002;
parameter [18:0] address_3_0_0_2 = 95684;
parameter [18:0] address_3_0_0_3 = 97366;
parameter [18:0] address_3_0_1_0 = 99048;
parameter [18:0] address_3_0_1_1 = 100730;
parameter [18:0] address_3_0_1_2 = 102412;
parameter [18:0] address_3_0_1_3 = 104094;
parameter [18:0] address_3_1_0_0 = 105776;
parameter [18:0] address_3_1_0_1 = 107458;
parameter [18:0] address_3_1_0_2 = 109140;
parameter [18:0] address_3_1_0_3 = 110822;
parameter [18:0] address_3_1_1_0 = 112504;
parameter [18:0] address_3_1_1_1 = 114186;
parameter [18:0] address_3_1_1_2 = 115868;
parameter [18:0] address_3_1_1_3 = 117550;
parameter [18:0] address_4_0_0_0 = 119232;
parameter [18:0] address_4_0_0_1 = 120800;
parameter [18:0] address_4_0_0_2 = 122368;
parameter [18:0] address_4_0_0_3 = 123936;
parameter [18:0] address_4_0_1_0 = 125504;
parameter [18:0] address_4_0_1_1 = 127072;
parameter [18:0] address_4_0_1_2 = 128640;
parameter [18:0] address_4_0_1_3 = 130208;
parameter [18:0] address_4_1_0_0 = 131776;
parameter [18:0] address_4_1_0_1 = 133344;
parameter [18:0] address_4_1_0_2 = 134912;
parameter [18:0] address_4_1_0_3 = 136480;
parameter [18:0] address_4_1_1_0 = 138048;
parameter [18:0] address_4_1_1_1 = 139616;
parameter [18:0] address_4_1_1_2 = 141184;
parameter [18:0] address_4_1_1_3 = 142752;
parameter [18:0] address_5_0_0_0 = 144320;
parameter [18:0] address_5_0_0_1 = 145778;
parameter [18:0] address_5_0_0_2 = 147236;
parameter [18:0] address_5_0_0_3 = 148694;
parameter [18:0] address_5_0_1_0 = 150152;
parameter [18:0] address_5_0_1_1 = 151610;
parameter [18:0] address_5_0_1_2 = 153068;
parameter [18:0] address_5_0_1_3 = 154526;
parameter [18:0] address_5_1_0_0 = 155984;
parameter [18:0] address_5_1_0_1 = 157442;
parameter [18:0] address_5_1_0_2 = 158900;
parameter [18:0] address_5_1_0_3 = 160358;
parameter [18:0] address_5_1_1_0 = 161816;
parameter [18:0] address_5_1_1_1 = 163274;
parameter [18:0] address_5_1_1_2 = 164732;
parameter [18:0] address_5_1_1_3 = 166190;
parameter [18:0] address_6_0_0_0 = 167648;
parameter [18:0] address_6_0_0_1 = 169000;
parameter [18:0] address_6_0_0_2 = 170352;
parameter [18:0] address_6_0_0_3 = 171704;
parameter [18:0] address_6_0_1_0 = 173056;
parameter [18:0] address_6_0_1_1 = 174408;
parameter [18:0] address_6_0_1_2 = 175760;
parameter [18:0] address_6_0_1_3 = 177112;
parameter [18:0] address_6_1_0_0 = 178464;
parameter [18:0] address_6_1_0_1 = 179816;
parameter [18:0] address_6_1_0_2 = 181168;
parameter [18:0] address_6_1_0_3 = 182520;
parameter [18:0] address_6_1_1_0 = 183872;
parameter [18:0] address_6_1_1_1 = 185224;
parameter [18:0] address_6_1_1_2 = 186576;
parameter [18:0] address_6_1_1_3 = 187928;
parameter [18:0] address_7_0_0_0 = 189280;
parameter [18:0] address_7_0_0_1 = 190530;
parameter [18:0] address_7_0_0_2 = 191780;
parameter [18:0] address_7_0_0_3 = 193030;
parameter [18:0] address_7_0_1_0 = 194280;
parameter [18:0] address_7_0_1_1 = 195530;
parameter [18:0] address_7_0_1_2 = 196780;
parameter [18:0] address_7_0_1_3 = 198030;
parameter [18:0] address_7_1_0_0 = 199280;
parameter [18:0] address_7_1_0_1 = 200530;
parameter [18:0] address_7_1_0_2 = 201780;
parameter [18:0] address_7_1_0_3 = 203030;
parameter [18:0] address_7_1_1_0 = 204280;
parameter [18:0] address_7_1_1_1 = 205530;
parameter [18:0] address_7_1_1_2 = 206780;
parameter [18:0] address_7_1_1_3 = 208030;
parameter [18:0] address_8_0_0_0 = 209280;
parameter [18:0] address_8_0_0_1 = 210432;
parameter [18:0] address_8_0_0_2 = 211584;
parameter [18:0] address_8_0_0_3 = 212736;
parameter [18:0] address_8_0_1_0 = 213888;
parameter [18:0] address_8_0_1_1 = 215040;
parameter [18:0] address_8_0_1_2 = 216192;
parameter [18:0] address_8_0_1_3 = 217344;
parameter [18:0] address_8_1_0_0 = 218496;
parameter [18:0] address_8_1_0_1 = 219648;
parameter [18:0] address_8_1_0_2 = 220800;
parameter [18:0] address_8_1_0_3 = 221952;
parameter [18:0] address_8_1_1_0 = 223104;
parameter [18:0] address_8_1_1_1 = 224256;
parameter [18:0] address_8_1_1_2 = 225408;
parameter [18:0] address_8_1_1_3 = 226560;
parameter [18:0] address_9_0_0_0 = 227712;
parameter [18:0] address_9_0_0_1 = 228770;
parameter [18:0] address_9_0_0_2 = 229828;
parameter [18:0] address_9_0_0_3 = 230886;
parameter [18:0] address_9_0_1_0 = 231944;
parameter [18:0] address_9_0_1_1 = 233002;
parameter [18:0] address_9_0_1_2 = 234060;
parameter [18:0] address_9_0_1_3 = 235118;
parameter [18:0] address_9_1_0_0 = 236176;
parameter [18:0] address_9_1_0_1 = 237234;
parameter [18:0] address_9_1_0_2 = 238292;
parameter [18:0] address_9_1_0_3 = 239350;
parameter [18:0] address_9_1_1_0 = 240408;
parameter [18:0] address_9_1_1_1 = 241466;
parameter [18:0] address_9_1_1_2 = 242524;
parameter [18:0] address_9_1_1_3 = 243582;
parameter [18:0] address_10_0_0_0 = 244640;
parameter [18:0] address_10_0_0_1 = 245608;
parameter [18:0] address_10_0_0_2 = 246576;
parameter [18:0] address_10_0_0_3 = 247544;
parameter [18:0] address_10_0_1_0 = 248512;
parameter [18:0] address_10_0_1_1 = 249480;
parameter [18:0] address_10_0_1_2 = 250448;
parameter [18:0] address_10_0_1_3 = 251416;
parameter [18:0] address_10_1_0_0 = 252384;
parameter [18:0] address_10_1_0_1 = 253352;
parameter [18:0] address_10_1_0_2 = 254320;
parameter [18:0] address_10_1_0_3 = 255288;
parameter [18:0] address_10_1_1_0 = 256256;
parameter [18:0] address_10_1_1_1 = 257224;
parameter [18:0] address_10_1_1_2 = 258192;
parameter [18:0] address_10_1_1_3 = 259160;
parameter [18:0] address_11_0_0_0 = 260128;
parameter [18:0] address_11_0_0_1 = 261010;
parameter [18:0] address_11_0_0_2 = 261892;
parameter [18:0] address_11_0_0_3 = 262774;
parameter [18:0] address_11_0_1_0 = 263656;
parameter [18:0] address_11_0_1_1 = 264538;
parameter [18:0] address_11_0_1_2 = 265420;
parameter [18:0] address_11_0_1_3 = 266302;
parameter [18:0] address_11_1_0_0 = 267184;
parameter [18:0] address_11_1_0_1 = 268066;
parameter [18:0] address_11_1_0_2 = 268948;
parameter [18:0] address_11_1_0_3 = 269830;
parameter [18:0] address_11_1_1_0 = 270712;
parameter [18:0] address_11_1_1_1 = 271594;
parameter [18:0] address_11_1_1_2 = 272476;
parameter [18:0] address_11_1_1_3 = 273358;
parameter [18:0] address_12_0_0_0 = 274240;
parameter [18:0] address_12_0_0_1 = 275040;
parameter [18:0] address_12_0_0_2 = 275840;
parameter [18:0] address_12_0_0_3 = 276640;
parameter [18:0] address_12_0_1_0 = 277440;
parameter [18:0] address_12_0_1_1 = 278240;
parameter [18:0] address_12_0_1_2 = 279040;
parameter [18:0] address_12_0_1_3 = 279840;
parameter [18:0] address_12_1_0_0 = 280640;
parameter [18:0] address_12_1_0_1 = 281440;
parameter [18:0] address_12_1_0_2 = 282240;
parameter [18:0] address_12_1_0_3 = 283040;
parameter [18:0] address_12_1_1_0 = 283840;
parameter [18:0] address_12_1_1_1 = 284640;
parameter [18:0] address_12_1_1_2 = 285440;
parameter [18:0] address_12_1_1_3 = 286240;
parameter [18:0] address_13_0_0_0 = 287040;
parameter [18:0] address_13_0_0_1 = 287762;
parameter [18:0] address_13_0_0_2 = 288484;
parameter [18:0] address_13_0_0_3 = 289206;
parameter [18:0] address_13_0_1_0 = 289928;
parameter [18:0] address_13_0_1_1 = 290650;
parameter [18:0] address_13_0_1_2 = 291372;
parameter [18:0] address_13_0_1_3 = 292094;
parameter [18:0] address_13_1_0_0 = 292816;
parameter [18:0] address_13_1_0_1 = 293538;
parameter [18:0] address_13_1_0_2 = 294260;
parameter [18:0] address_13_1_0_3 = 294982;
parameter [18:0] address_13_1_1_0 = 295704;
parameter [18:0] address_13_1_1_1 = 296426;
parameter [18:0] address_13_1_1_2 = 297148;
parameter [18:0] address_13_1_1_3 = 297870;
parameter [18:0] address_14_0_0_0 = 298592;
parameter [18:0] address_14_0_0_1 = 299240;
parameter [18:0] address_14_0_0_2 = 299888;
parameter [18:0] address_14_0_0_3 = 300536;
parameter [18:0] address_14_0_1_0 = 301184;
parameter [18:0] address_14_0_1_1 = 301832;
parameter [18:0] address_14_0_1_2 = 302480;
parameter [18:0] address_14_0_1_3 = 303128;
parameter [18:0] address_14_1_0_0 = 303776;
parameter [18:0] address_14_1_0_1 = 304424;
parameter [18:0] address_14_1_0_2 = 305072;
parameter [18:0] address_14_1_0_3 = 305720;
parameter [18:0] address_14_1_1_0 = 306368;
parameter [18:0] address_14_1_1_1 = 307016;
parameter [18:0] address_14_1_1_2 = 307664;
parameter [18:0] address_14_1_1_3 = 308312;
parameter [18:0] address_15_0_0_0 = 308960;
parameter [18:0] address_15_0_0_1 = 309538;
parameter [18:0] address_15_0_0_2 = 310116;
parameter [18:0] address_15_0_0_3 = 310694;
parameter [18:0] address_15_0_1_0 = 311272;
parameter [18:0] address_15_0_1_1 = 311850;
parameter [18:0] address_15_0_1_2 = 312428;
parameter [18:0] address_15_0_1_3 = 313006;
parameter [18:0] address_15_1_0_0 = 313584;
parameter [18:0] address_15_1_0_1 = 314162;
parameter [18:0] address_15_1_0_2 = 314740;
parameter [18:0] address_15_1_0_3 = 315318;
parameter [18:0] address_15_1_1_0 = 315896;
parameter [18:0] address_15_1_1_1 = 316474;
parameter [18:0] address_15_1_1_2 = 317052;
parameter [18:0] address_15_1_1_3 = 317630;

always @* begin
case({{size_select, alien_type[1], frame_num[0], deriv_select}})
8'b00000000: pixel_addr = address_0_0_0_0 + read_addr;
8'b00000001: pixel_addr = address_0_0_0_1 + read_addr;
8'b00000010: pixel_addr = address_0_0_0_2 + read_addr;
8'b00000011: pixel_addr = address_0_0_0_3 + read_addr;
8'b00000100: pixel_addr = address_0_0_1_0 + read_addr;
8'b00000101: pixel_addr = address_0_0_1_1 + read_addr;
8'b00000110: pixel_addr = address_0_0_1_2 + read_addr;
8'b00000111: pixel_addr = address_0_0_1_3 + read_addr;
8'b00001000: pixel_addr = address_0_1_0_0 + read_addr;
8'b00001001: pixel_addr = address_0_1_0_1 + read_addr;
8'b00001010: pixel_addr = address_0_1_0_2 + read_addr;
8'b00001011: pixel_addr = address_0_1_0_3 + read_addr;
8'b00001100: pixel_addr = address_0_1_1_0 + read_addr;
8'b00001101: pixel_addr = address_0_1_1_1 + read_addr;
8'b00001110: pixel_addr = address_0_1_1_2 + read_addr;
8'b00001111: pixel_addr = address_0_1_1_3 + read_addr;
8'b00010000: pixel_addr = address_1_0_0_0 + read_addr;
8'b00010001: pixel_addr = address_1_0_0_1 + read_addr;
8'b00010010: pixel_addr = address_1_0_0_2 + read_addr;
8'b00010011: pixel_addr = address_1_0_0_3 + read_addr;
8'b00010100: pixel_addr = address_1_0_1_0 + read_addr;
8'b00010101: pixel_addr = address_1_0_1_1 + read_addr;
8'b00010110: pixel_addr = address_1_0_1_2 + read_addr;
8'b00010111: pixel_addr = address_1_0_1_3 + read_addr;
8'b00011000: pixel_addr = address_1_1_0_0 + read_addr;
8'b00011001: pixel_addr = address_1_1_0_1 + read_addr;
8'b00011010: pixel_addr = address_1_1_0_2 + read_addr;
8'b00011011: pixel_addr = address_1_1_0_3 + read_addr;
8'b00011100: pixel_addr = address_1_1_1_0 + read_addr;
8'b00011101: pixel_addr = address_1_1_1_1 + read_addr;
8'b00011110: pixel_addr = address_1_1_1_2 + read_addr;
8'b00011111: pixel_addr = address_1_1_1_3 + read_addr;
8'b00100000: pixel_addr = address_2_0_0_0 + read_addr;
8'b00100001: pixel_addr = address_2_0_0_1 + read_addr;
8'b00100010: pixel_addr = address_2_0_0_2 + read_addr;
8'b00100011: pixel_addr = address_2_0_0_3 + read_addr;
8'b00100100: pixel_addr = address_2_0_1_0 + read_addr;
8'b00100101: pixel_addr = address_2_0_1_1 + read_addr;
8'b00100110: pixel_addr = address_2_0_1_2 + read_addr;
8'b00100111: pixel_addr = address_2_0_1_3 + read_addr;
8'b00101000: pixel_addr = address_2_1_0_0 + read_addr;
8'b00101001: pixel_addr = address_2_1_0_1 + read_addr;
8'b00101010: pixel_addr = address_2_1_0_2 + read_addr;
8'b00101011: pixel_addr = address_2_1_0_3 + read_addr;
8'b00101100: pixel_addr = address_2_1_1_0 + read_addr;
8'b00101101: pixel_addr = address_2_1_1_1 + read_addr;
8'b00101110: pixel_addr = address_2_1_1_2 + read_addr;
8'b00101111: pixel_addr = address_2_1_1_3 + read_addr;
8'b00110000: pixel_addr = address_3_0_0_0 + read_addr;
8'b00110001: pixel_addr = address_3_0_0_1 + read_addr;
8'b00110010: pixel_addr = address_3_0_0_2 + read_addr;
8'b00110011: pixel_addr = address_3_0_0_3 + read_addr;
8'b00110100: pixel_addr = address_3_0_1_0 + read_addr;
8'b00110101: pixel_addr = address_3_0_1_1 + read_addr;
8'b00110110: pixel_addr = address_3_0_1_2 + read_addr;
8'b00110111: pixel_addr = address_3_0_1_3 + read_addr;
8'b00111000: pixel_addr = address_3_1_0_0 + read_addr;
8'b00111001: pixel_addr = address_3_1_0_1 + read_addr;
8'b00111010: pixel_addr = address_3_1_0_2 + read_addr;
8'b00111011: pixel_addr = address_3_1_0_3 + read_addr;
8'b00111100: pixel_addr = address_3_1_1_0 + read_addr;
8'b00111101: pixel_addr = address_3_1_1_1 + read_addr;
8'b00111110: pixel_addr = address_3_1_1_2 + read_addr;
8'b00111111: pixel_addr = address_3_1_1_3 + read_addr;
8'b01000000: pixel_addr = address_4_0_0_0 + read_addr;
8'b01000001: pixel_addr = address_4_0_0_1 + read_addr;
8'b01000010: pixel_addr = address_4_0_0_2 + read_addr;
8'b01000011: pixel_addr = address_4_0_0_3 + read_addr;
8'b01000100: pixel_addr = address_4_0_1_0 + read_addr;
8'b01000101: pixel_addr = address_4_0_1_1 + read_addr;
8'b01000110: pixel_addr = address_4_0_1_2 + read_addr;
8'b01000111: pixel_addr = address_4_0_1_3 + read_addr;
8'b01001000: pixel_addr = address_4_1_0_0 + read_addr;
8'b01001001: pixel_addr = address_4_1_0_1 + read_addr;
8'b01001010: pixel_addr = address_4_1_0_2 + read_addr;
8'b01001011: pixel_addr = address_4_1_0_3 + read_addr;
8'b01001100: pixel_addr = address_4_1_1_0 + read_addr;
8'b01001101: pixel_addr = address_4_1_1_1 + read_addr;
8'b01001110: pixel_addr = address_4_1_1_2 + read_addr;
8'b01001111: pixel_addr = address_4_1_1_3 + read_addr;
8'b01010000: pixel_addr = address_5_0_0_0 + read_addr;
8'b01010001: pixel_addr = address_5_0_0_1 + read_addr;
8'b01010010: pixel_addr = address_5_0_0_2 + read_addr;
8'b01010011: pixel_addr = address_5_0_0_3 + read_addr;
8'b01010100: pixel_addr = address_5_0_1_0 + read_addr;
8'b01010101: pixel_addr = address_5_0_1_1 + read_addr;
8'b01010110: pixel_addr = address_5_0_1_2 + read_addr;
8'b01010111: pixel_addr = address_5_0_1_3 + read_addr;
8'b01011000: pixel_addr = address_5_1_0_0 + read_addr;
8'b01011001: pixel_addr = address_5_1_0_1 + read_addr;
8'b01011010: pixel_addr = address_5_1_0_2 + read_addr;
8'b01011011: pixel_addr = address_5_1_0_3 + read_addr;
8'b01011100: pixel_addr = address_5_1_1_0 + read_addr;
8'b01011101: pixel_addr = address_5_1_1_1 + read_addr;
8'b01011110: pixel_addr = address_5_1_1_2 + read_addr;
8'b01011111: pixel_addr = address_5_1_1_3 + read_addr;
8'b01100000: pixel_addr = address_6_0_0_0 + read_addr;
8'b01100001: pixel_addr = address_6_0_0_1 + read_addr;
8'b01100010: pixel_addr = address_6_0_0_2 + read_addr;
8'b01100011: pixel_addr = address_6_0_0_3 + read_addr;
8'b01100100: pixel_addr = address_6_0_1_0 + read_addr;
8'b01100101: pixel_addr = address_6_0_1_1 + read_addr;
8'b01100110: pixel_addr = address_6_0_1_2 + read_addr;
8'b01100111: pixel_addr = address_6_0_1_3 + read_addr;
8'b01101000: pixel_addr = address_6_1_0_0 + read_addr;
8'b01101001: pixel_addr = address_6_1_0_1 + read_addr;
8'b01101010: pixel_addr = address_6_1_0_2 + read_addr;
8'b01101011: pixel_addr = address_6_1_0_3 + read_addr;
8'b01101100: pixel_addr = address_6_1_1_0 + read_addr;
8'b01101101: pixel_addr = address_6_1_1_1 + read_addr;
8'b01101110: pixel_addr = address_6_1_1_2 + read_addr;
8'b01101111: pixel_addr = address_6_1_1_3 + read_addr;
8'b01110000: pixel_addr = address_7_0_0_0 + read_addr;
8'b01110001: pixel_addr = address_7_0_0_1 + read_addr;
8'b01110010: pixel_addr = address_7_0_0_2 + read_addr;
8'b01110011: pixel_addr = address_7_0_0_3 + read_addr;
8'b01110100: pixel_addr = address_7_0_1_0 + read_addr;
8'b01110101: pixel_addr = address_7_0_1_1 + read_addr;
8'b01110110: pixel_addr = address_7_0_1_2 + read_addr;
8'b01110111: pixel_addr = address_7_0_1_3 + read_addr;
8'b01111000: pixel_addr = address_7_1_0_0 + read_addr;
8'b01111001: pixel_addr = address_7_1_0_1 + read_addr;
8'b01111010: pixel_addr = address_7_1_0_2 + read_addr;
8'b01111011: pixel_addr = address_7_1_0_3 + read_addr;
8'b01111100: pixel_addr = address_7_1_1_0 + read_addr;
8'b01111101: pixel_addr = address_7_1_1_1 + read_addr;
8'b01111110: pixel_addr = address_7_1_1_2 + read_addr;
8'b01111111: pixel_addr = address_7_1_1_3 + read_addr;
8'b10000000: pixel_addr = address_8_0_0_0 + read_addr;
8'b10000001: pixel_addr = address_8_0_0_1 + read_addr;
8'b10000010: pixel_addr = address_8_0_0_2 + read_addr;
8'b10000011: pixel_addr = address_8_0_0_3 + read_addr;
8'b10000100: pixel_addr = address_8_0_1_0 + read_addr;
8'b10000101: pixel_addr = address_8_0_1_1 + read_addr;
8'b10000110: pixel_addr = address_8_0_1_2 + read_addr;
8'b10000111: pixel_addr = address_8_0_1_3 + read_addr;
8'b10001000: pixel_addr = address_8_1_0_0 + read_addr;
8'b10001001: pixel_addr = address_8_1_0_1 + read_addr;
8'b10001010: pixel_addr = address_8_1_0_2 + read_addr;
8'b10001011: pixel_addr = address_8_1_0_3 + read_addr;
8'b10001100: pixel_addr = address_8_1_1_0 + read_addr;
8'b10001101: pixel_addr = address_8_1_1_1 + read_addr;
8'b10001110: pixel_addr = address_8_1_1_2 + read_addr;
8'b10001111: pixel_addr = address_8_1_1_3 + read_addr;
8'b10010000: pixel_addr = address_9_0_0_0 + read_addr;
8'b10010001: pixel_addr = address_9_0_0_1 + read_addr;
8'b10010010: pixel_addr = address_9_0_0_2 + read_addr;
8'b10010011: pixel_addr = address_9_0_0_3 + read_addr;
8'b10010100: pixel_addr = address_9_0_1_0 + read_addr;
8'b10010101: pixel_addr = address_9_0_1_1 + read_addr;
8'b10010110: pixel_addr = address_9_0_1_2 + read_addr;
8'b10010111: pixel_addr = address_9_0_1_3 + read_addr;
8'b10011000: pixel_addr = address_9_1_0_0 + read_addr;
8'b10011001: pixel_addr = address_9_1_0_1 + read_addr;
8'b10011010: pixel_addr = address_9_1_0_2 + read_addr;
8'b10011011: pixel_addr = address_9_1_0_3 + read_addr;
8'b10011100: pixel_addr = address_9_1_1_0 + read_addr;
8'b10011101: pixel_addr = address_9_1_1_1 + read_addr;
8'b10011110: pixel_addr = address_9_1_1_2 + read_addr;
8'b10011111: pixel_addr = address_9_1_1_3 + read_addr;
8'b10100000: pixel_addr = address_10_0_0_0 + read_addr;
8'b10100001: pixel_addr = address_10_0_0_1 + read_addr;
8'b10100010: pixel_addr = address_10_0_0_2 + read_addr;
8'b10100011: pixel_addr = address_10_0_0_3 + read_addr;
8'b10100100: pixel_addr = address_10_0_1_0 + read_addr;
8'b10100101: pixel_addr = address_10_0_1_1 + read_addr;
8'b10100110: pixel_addr = address_10_0_1_2 + read_addr;
8'b10100111: pixel_addr = address_10_0_1_3 + read_addr;
8'b10101000: pixel_addr = address_10_1_0_0 + read_addr;
8'b10101001: pixel_addr = address_10_1_0_1 + read_addr;
8'b10101010: pixel_addr = address_10_1_0_2 + read_addr;
8'b10101011: pixel_addr = address_10_1_0_3 + read_addr;
8'b10101100: pixel_addr = address_10_1_1_0 + read_addr;
8'b10101101: pixel_addr = address_10_1_1_1 + read_addr;
8'b10101110: pixel_addr = address_10_1_1_2 + read_addr;
8'b10101111: pixel_addr = address_10_1_1_3 + read_addr;
8'b10110000: pixel_addr = address_11_0_0_0 + read_addr;
8'b10110001: pixel_addr = address_11_0_0_1 + read_addr;
8'b10110010: pixel_addr = address_11_0_0_2 + read_addr;
8'b10110011: pixel_addr = address_11_0_0_3 + read_addr;
8'b10110100: pixel_addr = address_11_0_1_0 + read_addr;
8'b10110101: pixel_addr = address_11_0_1_1 + read_addr;
8'b10110110: pixel_addr = address_11_0_1_2 + read_addr;
8'b10110111: pixel_addr = address_11_0_1_3 + read_addr;
8'b10111000: pixel_addr = address_11_1_0_0 + read_addr;
8'b10111001: pixel_addr = address_11_1_0_1 + read_addr;
8'b10111010: pixel_addr = address_11_1_0_2 + read_addr;
8'b10111011: pixel_addr = address_11_1_0_3 + read_addr;
8'b10111100: pixel_addr = address_11_1_1_0 + read_addr;
8'b10111101: pixel_addr = address_11_1_1_1 + read_addr;
8'b10111110: pixel_addr = address_11_1_1_2 + read_addr;
8'b10111111: pixel_addr = address_11_1_1_3 + read_addr;
8'b11000000: pixel_addr = address_12_0_0_0 + read_addr;
8'b11000001: pixel_addr = address_12_0_0_1 + read_addr;
8'b11000010: pixel_addr = address_12_0_0_2 + read_addr;
8'b11000011: pixel_addr = address_12_0_0_3 + read_addr;
8'b11000100: pixel_addr = address_12_0_1_0 + read_addr;
8'b11000101: pixel_addr = address_12_0_1_1 + read_addr;
8'b11000110: pixel_addr = address_12_0_1_2 + read_addr;
8'b11000111: pixel_addr = address_12_0_1_3 + read_addr;
8'b11001000: pixel_addr = address_12_1_0_0 + read_addr;
8'b11001001: pixel_addr = address_12_1_0_1 + read_addr;
8'b11001010: pixel_addr = address_12_1_0_2 + read_addr;
8'b11001011: pixel_addr = address_12_1_0_3 + read_addr;
8'b11001100: pixel_addr = address_12_1_1_0 + read_addr;
8'b11001101: pixel_addr = address_12_1_1_1 + read_addr;
8'b11001110: pixel_addr = address_12_1_1_2 + read_addr;
8'b11001111: pixel_addr = address_12_1_1_3 + read_addr;
8'b11010000: pixel_addr = address_13_0_0_0 + read_addr;
8'b11010001: pixel_addr = address_13_0_0_1 + read_addr;
8'b11010010: pixel_addr = address_13_0_0_2 + read_addr;
8'b11010011: pixel_addr = address_13_0_0_3 + read_addr;
8'b11010100: pixel_addr = address_13_0_1_0 + read_addr;
8'b11010101: pixel_addr = address_13_0_1_1 + read_addr;
8'b11010110: pixel_addr = address_13_0_1_2 + read_addr;
8'b11010111: pixel_addr = address_13_0_1_3 + read_addr;
8'b11011000: pixel_addr = address_13_1_0_0 + read_addr;
8'b11011001: pixel_addr = address_13_1_0_1 + read_addr;
8'b11011010: pixel_addr = address_13_1_0_2 + read_addr;
8'b11011011: pixel_addr = address_13_1_0_3 + read_addr;
8'b11011100: pixel_addr = address_13_1_1_0 + read_addr;
8'b11011101: pixel_addr = address_13_1_1_1 + read_addr;
8'b11011110: pixel_addr = address_13_1_1_2 + read_addr;
8'b11011111: pixel_addr = address_13_1_1_3 + read_addr;
8'b11100000: pixel_addr = address_14_0_0_0 + read_addr;
8'b11100001: pixel_addr = address_14_0_0_1 + read_addr;
8'b11100010: pixel_addr = address_14_0_0_2 + read_addr;
8'b11100011: pixel_addr = address_14_0_0_3 + read_addr;
8'b11100100: pixel_addr = address_14_0_1_0 + read_addr;
8'b11100101: pixel_addr = address_14_0_1_1 + read_addr;
8'b11100110: pixel_addr = address_14_0_1_2 + read_addr;
8'b11100111: pixel_addr = address_14_0_1_3 + read_addr;
8'b11101000: pixel_addr = address_14_1_0_0 + read_addr;
8'b11101001: pixel_addr = address_14_1_0_1 + read_addr;
8'b11101010: pixel_addr = address_14_1_0_2 + read_addr;
8'b11101011: pixel_addr = address_14_1_0_3 + read_addr;
8'b11101100: pixel_addr = address_14_1_1_0 + read_addr;
8'b11101101: pixel_addr = address_14_1_1_1 + read_addr;
8'b11101110: pixel_addr = address_14_1_1_2 + read_addr;
8'b11101111: pixel_addr = address_14_1_1_3 + read_addr;
8'b11110000: pixel_addr = address_15_0_0_0 + read_addr;
8'b11110001: pixel_addr = address_15_0_0_1 + read_addr;
8'b11110010: pixel_addr = address_15_0_0_2 + read_addr;
8'b11110011: pixel_addr = address_15_0_0_3 + read_addr;
8'b11110100: pixel_addr = address_15_0_1_0 + read_addr;
8'b11110101: pixel_addr = address_15_0_1_1 + read_addr;
8'b11110110: pixel_addr = address_15_0_1_2 + read_addr;
8'b11110111: pixel_addr = address_15_0_1_3 + read_addr;
8'b11111000: pixel_addr = address_15_1_0_0 + read_addr;
8'b11111001: pixel_addr = address_15_1_0_1 + read_addr;
8'b11111010: pixel_addr = address_15_1_0_2 + read_addr;
8'b11111011: pixel_addr = address_15_1_0_3 + read_addr;
8'b11111100: pixel_addr = address_15_1_1_0 + read_addr;
8'b11111101: pixel_addr = address_15_1_1_1 + read_addr;
8'b11111110: pixel_addr = address_15_1_1_2 + read_addr;
8'b11111111: pixel_addr = address_15_1_1_3 + read_addr;
default : pixel_addr = 0;
endcase
end


endmodule
