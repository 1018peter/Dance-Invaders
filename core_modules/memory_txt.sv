module memory_txt(
    input [5:0] txt_addr,
    input [9:0] h_point,
    input [9:0] v_point,
    input clk,
    output [11:0] pixel
    );
wire [10:0] pixel_addr=h_point+v_point*5+txt_addr*40;
wire signal;
assign pixel =(signal==1)?12'hfff:12'h000;
blk_mem_txt(
.clka(clk),
.addra(pixel_addr),
.douta(signal)
);

endmodule