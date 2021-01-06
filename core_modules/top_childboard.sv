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
logic [MESSAGE_SIZE-1:0] data_out;
logic valid;
receiver #(.n(MESSAGE_SIZE)) (
    .clk_receiver(clk),
    .wire_req(req),
    .wire_data_deliver(data_trans),
    .wire_data_out(data_out),
    .reg_ack(ack),
    .reg_valid(valid)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        datagram <=0;
    end 
    else if(valid)begin
        datagram <= data_out;
    end
    else begin
        datagram <=datagram;
    end
end
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