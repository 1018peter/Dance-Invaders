module scoreboard_pixel(
    input clk,
    input [1:0] input_pos,
    input [14:0] player_name,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output logic [11:0] pixel_out,
    output logic valid
    );
parameter S = 28;
parameter C = 12;
parameter O = 24;
parameter R = 27;
parameter E = 14;
logic [4:0] ch[0:2];
wire pixel_out_ready;
logic bound;
logic [5:0] mem_txt_addr;
reg reg_h_cnt_compressed;
reg reg_v_cnt_compressed;
assign {ch[0],ch[1],ch[2]}=player_name;
assign pixel_out=(bound)?12'hfff:pixel_out_ready;
always @* begin
        valid=0;
        mem_txt_addr=0;
        reg_h_cnt_compressed=0;
        reg_v_cnt_compressed=0;
        bound=0;
        if(v_cnt>=38&&v_cnt<150) begin


        if(h_cnt>=190&&h_cnt<270) begin
            mem_txt_addr=ch[0]+10;
            reg_h_cnt_compressed=(h_cnt-190)>>4;
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
        else if(h_cnt>=370&&h_cnt<450) begin
            mem_txt_addr=ch[2]+10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-38)>>4;
            valid=1;
        end

        else if(h_cnt>=180&&h_cnt<190&&(input_pos==2'd3||input_pos==2'd0)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=270&&h_cnt<280&&(input_pos==2'd0||input_pos==2'd1)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=360&&h_cnt<370&&(input_pos==2'd1||input_pos==2'd2)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=450&&h_cnt<460&&(input_pos==2'd2||input_pos==2'd3)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end


        end

        else if(v_cnt>=180&&v_cnt<292) begin

            if(h_cnt>=120&&h_cnt<200) begin
            mem_txt_addr=S;
            reg_h_cnt_compressed=(h_cnt-120)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=200&&h_cnt<280) begin
            reg_h_cnt_compressed=(h_cnt-200)>>4;
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
            else if(h_cnt>=360&&h_cnt<440)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-360)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=440&&h_cnt<520)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-440)>>4;
            reg_v_cnt_compressed=(v_cnt-180)>>4;
            valid=1;
            bound=0;
            end

        end

        else if(v_cnt>=28&&v_cnt<38) begin

        if(h_cnt>=180&&h_cnt<280&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=270&&h_cnt<370&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=360&&h_cnt<460&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=180&&h_cnt<460&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end

        end


        else if(v_cnt>=292&&v_cnt<302) begin


            if(h_cnt>=180&&h_cnt<280&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=270&&h_cnt<370&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=360&&h_cnt<460&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=180&&h_cnt<460&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end            

        end


end


memory_txt score(
        .clk(clk),
        .txt_addr(mem_txt_addr),
        .h_point(wire_h_cnt_compressed),
        .v_point(wire_v_cnt_compressed),
        .pixel(pixel_out_ready)
    );
endmodule