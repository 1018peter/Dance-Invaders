`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/02 12:58:31
// Design Name: 
// Module Name: comparator_tb
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
