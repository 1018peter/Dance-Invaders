

`include "typedefs.svh"
`ifndef CONSTANTS_SVH
`define CONSTANTS_SVH
// Global constants that can be referenced across the entire project.
parameter OBJ_LIMIT = 32;
parameter R_LIMIT = 15;
parameter LSR_WIDTH = 10;

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
     |             |            |          |            |
     |             -- - - <- - --          |            |
     ----------<----------<----------<---------<---------
*/
parameter SCENE_GAME_START = 3'd1;

parameter SCENE_LEVEL_START = 3'd2;

parameter SCENE_INGAME = 3'd3;

parameter SCENE_GAME_OVER = 3'd4;

parameter SCENE_SCOREBOARD = 3'd5;

parameter STATE_SIZE = 3;

parameter ALIEN_DATA_SIZE = $size(AlienData);

parameter LASER_DATA_SIZE = $size(Laser);

parameter FRAME_DATA_SIZE = ALIEN_DATA_SIZE * OBJ_LIMIT + LASER_DATA_SIZE;

parameter INGAME_DATA_SIZE = FRAME_DATA_SIZE + SCORE_SIZE + LEVEL_SIZE;

parameter SCOREBOARD_DATA_SIZE = SCORE_SIZE * 6 + STRING_SIZE * 6 + 1;

parameter MESSAGE_SIZE = INGAME_DATA_SIZE + STATE_SIZE;


`endif