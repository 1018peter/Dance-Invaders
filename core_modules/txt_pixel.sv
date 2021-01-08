`include "constants.svh"
module txt_pixel(
    input clk,
    input [LEVEL_SIZE-1:0] level,
    input [1:0] input_pos,
    input [STRING_SIZE-1:0] player_name,
    input [STATE_SIZE-1:0] state,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output logic [11:0] pixel_out,
    output logic valid
    );
parameter G = 16;
parameter A = 10;
parameter M = 22;
parameter E = 14;
parameter S = 28;
parameter C = 12;
parameter O = 24;
parameter R = 27;
parameter T = 29;
parameter V = 31;
parameter L = 21;
logic [4:0] ch[0:2];
wire [11:0] pixel_out_ready;
logic bound;
logic [5:0] mem_txt_addr;
reg [9:0] reg_h_cnt_compressed;
reg [9:0] reg_v_cnt_compressed;
assign {ch[0],ch[1],ch[2]}=player_name;
assign pixel_out=(bound)?12'hfff:pixel_out_ready;
always @* begin
        valid=0;
        mem_txt_addr=0;
        reg_h_cnt_compressed=0;
        reg_v_cnt_compressed=0;
        bound=0;
        if(state==SCENE_GAME_START) begin //scene begin
            if(v_cnt>=28&&v_cnt<140) begin
        if(h_cnt>=145&&h_cnt<225) begin
            mem_txt_addr=G;
            reg_h_cnt_compressed=(h_cnt-145)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=A;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=M;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        else if(h_cnt>=415&&h_cnt<495)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-415)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        end

        else if(v_cnt>=160&&v_cnt<272) begin
            if(h_cnt>=100&&h_cnt<180) begin
            mem_txt_addr=S;
            reg_h_cnt_compressed=(h_cnt-100)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
            end
            else if(h_cnt>=190&&h_cnt<270) begin
            reg_h_cnt_compressed=(h_cnt-190)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            mem_txt_addr=T;
            valid=1;
            end
            else if(h_cnt>=280&&h_cnt<360) begin
            mem_txt_addr=A;
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
            end
            else if(h_cnt>=370&&h_cnt<450)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
            end
            else if(h_cnt>=460&&h_cnt<540)begin
            mem_txt_addr=T;
            reg_h_cnt_compressed=(h_cnt-460)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
            end
        end
        end//scene end

        else if(state==SCENE_LEVEL_START) begin//scene begin
            if(v_cnt>=28&&v_cnt<140) begin
            if(h_cnt>=100&&h_cnt<180) begin
            mem_txt_addr=L;
            reg_h_cnt_compressed=(h_cnt-100)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=190&&h_cnt<270) begin
            reg_h_cnt_compressed=(h_cnt-190)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=E;
            valid=1;
            end
            else if(h_cnt>=280&&h_cnt<360) begin
            mem_txt_addr=V;
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=370&&h_cnt<450)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=460&&h_cnt<540)begin
            mem_txt_addr=L;
            reg_h_cnt_compressed=(h_cnt-460)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
        end

        else if(v_cnt>=160&&v_cnt<272) begin
            if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            mem_txt_addr=level/10;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=level%10;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end

        end
        end//scene end

        else if(state==SCENE_GAME_OVER) begin //scene begin
            if(v_cnt>=28&&v_cnt<140) begin
        if(h_cnt>=145&&h_cnt<225) begin
            mem_txt_addr=G;
            reg_h_cnt_compressed=(h_cnt-145)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=A;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=M;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        else if(h_cnt>=415&&h_cnt<495)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-415)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
        end
        end



        else if(v_cnt>=160&&v_cnt<272) begin
            if(h_cnt>=145&&h_cnt<225) begin
            mem_txt_addr=O;
            reg_h_cnt_compressed=(h_cnt-145)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<315) begin
            reg_h_cnt_compressed=(h_cnt-235)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            mem_txt_addr=V;
            valid=1;
        end
        else if(h_cnt>=325&&h_cnt<405) begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-325)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end
        else if(h_cnt>=415&&h_cnt<495)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-415)>>4;
            reg_v_cnt_compressed=(v_cnt-160)>>4;
            valid=1;
        end
        end
        end//scene end

        else if(state==SCENE_SCOREBOARD) begin //scene begin
        if(v_cnt>=38&&v_cnt<150) begin


        if(h_cnt>=170&&h_cnt<250) begin
            mem_txt_addr=ch[0]+10;
            reg_h_cnt_compressed=(h_cnt-170)>>4;
            reg_v_cnt_compressed=(v_cnt-38)>>4;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=280&&h_cnt<360) begin
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-38)>>4;
            mem_txt_addr=ch[1]+10;
            bound=0;
            valid=1;
        end
        else if(h_cnt>=390&&h_cnt<470) begin
            mem_txt_addr=ch[2]+10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-390)>>4;
            reg_v_cnt_compressed=(v_cnt-38)>>4;
            valid=1;
        end

        end

        if(v_cnt>=28&&v_cnt<160) begin
        if(h_cnt>=150&&h_cnt<160&&(input_pos==2'd3||input_pos==2'd0)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=260&&h_cnt<270&&(input_pos==2'd0||input_pos==2'd1)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=370&&h_cnt<380&&(input_pos==2'd1||input_pos==2'd2)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=480&&h_cnt<490&&(input_pos==2'd2||input_pos==2'd3)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end


        end

        else if(v_cnt>=180&&v_cnt<292) begin

            if(h_cnt>=100&&h_cnt<180) begin
            mem_txt_addr=S;
            reg_h_cnt_compressed=(h_cnt-100)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=190&&h_cnt<270) begin
            reg_h_cnt_compressed=(h_cnt-190)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            mem_txt_addr=C;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=280&&h_cnt<360) begin
            mem_txt_addr=O;
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=370&&h_cnt<450)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=460&&h_cnt<540)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-460)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end

        end

        else if(v_cnt>=18&&v_cnt<28) begin

        if(h_cnt>=150&&h_cnt<270&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=260&&h_cnt<380&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=370&&h_cnt<490&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=150&&h_cnt<490&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end

        end

        else if(v_cnt>=160&&v_cnt<170) begin


            if(h_cnt>=150&&h_cnt<270&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=260&&h_cnt<380&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=370&&h_cnt<490&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=150&&h_cnt<490&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end            
        end
        end//scene end


end


memory_txt (
        .clk(clk),
        .txt_addr(mem_txt_addr),
        .h_point(reg_h_cnt_compressed),
        .v_point(reg_v_cnt_compressed),
        .pixel(pixel_out_ready)
    );
endmodule