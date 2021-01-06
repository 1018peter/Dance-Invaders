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