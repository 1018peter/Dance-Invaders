`include "constants.svh"
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

