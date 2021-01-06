

`include "typedefs.svh"
`ifndef CONSTANTS_SVH
`define CONSTANTS_SVH
// Global constants that can be referenced across the entire project.
parameter OBJ_LIMIT = 16;
parameter R_LIMIT = 15;
parameter LSR_WIDTH = 10;
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