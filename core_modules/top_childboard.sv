`include "constants.svh"
module top_childboard(
    input [5:0] data_trans,
    input req,
    input clk,
    input rst,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output ack,
    output hsync,
    output vsync
);

logic [MESSAGE_SIZE-1:0] datagram;
async_oneway_receiver(
    .clk_receive(clk),
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