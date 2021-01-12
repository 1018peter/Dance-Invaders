`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/01 19:45:39
// Design Name: Self-sorting Scoreboard
// Module Name: scoreboard
// Project Name: scoreboard
// Target Devices: Basys3
// Tool Versions: Vivado 2020.1.1
// Description: 
// A self-sorting scoreboard that can keep data arranged in sorted order according to 
// their key (integer).
// To insert a new value, assert "insert" for 1 clock cycle and at the same time, 
// set key_insert and string_insert to the desired data.
// Dependencies: 
// 
// Revision 0.01 - File Created
// Revision 0.10 - Passed testbench
// Revision 0.20 - Changed names of variables to be more generalized.
// Additional Comments:
// Schematic reference - https://www.angelfire.com/blog/ronz/Articles/sn2-13_16_horz_2.gif
//////////////////////////////////////////////////////////////////////////////////

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
