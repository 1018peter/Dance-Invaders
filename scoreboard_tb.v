`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/01 21:10:06
// Design Name: 
// Module Name: scoreboard_tb
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
