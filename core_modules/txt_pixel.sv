`include "constants.svh"
module txt_pixel(
    input clk,
    input [LEVEL_SIZE-1:0] level,
    input [1:0] input_pos,
    input [STRING_SIZE-1:0] player_name,
    input [STRING_SIZE*5-1:0] player_name_record,
    input [SCORE_SIZE-1:0] score,
    input [SCORE_SIZE-1:0] score_cur,
    input [SCORE_SIZE*5-1:0] score_record,
    input [STATE_SIZE-1:0] state,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input rst,
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
parameter D = 13;
parameter N = 23;
parameter I = 18;
logic [CHAR_SIZE-1:0] ch[0:2];
logic [CHAR_SIZE-1:0] ch_record[4:0][0:2];
logic [SCORE_SIZE-1:0] score_rank[4:0];
wire [11:0] pixel_out_ready;
logic bound;
logic [5:0] mem_txt_addr;
reg [9:0] reg_h_cnt_compressed;
reg [9:0] reg_v_cnt_compressed;
assign {ch[0],ch[1],ch[2]}=player_name;
assign {ch_record[4][0],ch_record[4][1],ch_record[4][2],ch_record[3][0],ch_record[3][1],
        ch_record[3][2],ch_record[2][0],ch_record[2][1],ch_record[2][2],ch_record[1][0],
        ch_record[1][1],ch_record[1][2],ch_record[0][0],ch_record[0][1],ch_record[0][2]}=player_name_record;
assign {score_rank[4],score_rank[3],score_rank[2],score_rank[1],score_rank[0]}=score_record;
assign pixel_out=(bound)?12'hfff:pixel_out_ready;


logic [24:0] counter;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter <=0 ;
    end
    else begin
        if(counter<25'd25_000_000) begin
            counter<=counter+1;
        end
        else begin
           counter<=0; 
        end
    end
end




always @* begin
        valid=0;
        mem_txt_addr=0;
        reg_h_cnt_compressed=0;
        reg_v_cnt_compressed=0;
        bound=0;
        if(state==SCENE_GAME_START&&counter<25'd12_500_000) begin //scene begin
            if(v_cnt>=28&&v_cnt<140) begin
            if(h_cnt>=100&&h_cnt<180) begin
            mem_txt_addr=D;
            reg_h_cnt_compressed=(h_cnt-100)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=190&&h_cnt<270) begin
            reg_h_cnt_compressed=(h_cnt-190)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            mem_txt_addr=A;
            valid=1;
            end
            else if(h_cnt>=280&&h_cnt<360) begin
            mem_txt_addr=N;
            reg_h_cnt_compressed=(h_cnt-280)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=370&&h_cnt<450)begin
            mem_txt_addr=C;
            reg_h_cnt_compressed=(h_cnt-370)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
            else if(h_cnt>=460&&h_cnt<540)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-460)>>4;
            reg_v_cnt_compressed=(v_cnt-28)>>4;
            valid=1;
            end
        end
        else if(v_cnt>=160&&v_cnt<216) begin
            if(h_cnt>=125&&h_cnt<165) begin
                mem_txt_addr=I;
                reg_h_cnt_compressed=(h_cnt-125)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=175&&h_cnt<215) begin
                mem_txt_addr=N;
                reg_h_cnt_compressed=(h_cnt-175)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=225&&h_cnt<265) begin
                mem_txt_addr=V;
                reg_h_cnt_compressed=(h_cnt-225)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=275&&h_cnt<315) begin
                mem_txt_addr=A;
                reg_h_cnt_compressed=(h_cnt-275)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=325&&h_cnt<365) begin
                mem_txt_addr=D;
                reg_h_cnt_compressed=(h_cnt-325)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=375&&h_cnt<415) begin
                mem_txt_addr=E;
                reg_h_cnt_compressed=(h_cnt-375)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=425&&h_cnt<465) begin
                mem_txt_addr=R;
                reg_h_cnt_compressed=(h_cnt-425)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
                valid=1;
            end
            else if(h_cnt>=475&&h_cnt<515) begin
                mem_txt_addr=S;
                reg_h_cnt_compressed=(h_cnt-475)>>3;
                reg_v_cnt_compressed=(v_cnt-160)>>3;
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
        else if(state==SCENE_INGAME) begin//scene begin
            if(v_cnt>=18&&v_cnt<74) begin

        if(h_cnt>=200&&h_cnt<240) begin
            mem_txt_addr=(score_cur/10000)%10;
            reg_h_cnt_compressed=(h_cnt-200)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=250&&h_cnt<290) begin
            mem_txt_addr=(score_cur/1000)%10;
            reg_h_cnt_compressed=(h_cnt-250)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=300&&h_cnt<340) begin
            reg_h_cnt_compressed=(h_cnt-300)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            mem_txt_addr=(score_cur/100)%10;
            bound=0;
            valid=1;
        end
        else if(h_cnt>=350&&h_cnt<390) begin
            mem_txt_addr=(score_cur/10)%10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-350)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
        end
        else if(h_cnt>=400&&h_cnt<440) begin
            mem_txt_addr=(score_cur)%10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-400)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
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
        if(v_cnt>=18&&v_cnt<74) begin


        if(h_cnt>=245&&h_cnt<285) begin
            mem_txt_addr=ch[0]+10;
            reg_h_cnt_compressed=(h_cnt-245)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
            bound=0;
        end
        else if(h_cnt>=300&&h_cnt<340) begin
            reg_h_cnt_compressed=(h_cnt-300)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            mem_txt_addr=ch[1]+10;
            bound=0;
            valid=1;
        end
        else if(h_cnt>=355&&h_cnt<395) begin
            mem_txt_addr=ch[2]+10;
            bound=0;
            reg_h_cnt_compressed=(h_cnt-355)>>3;
            reg_v_cnt_compressed=(v_cnt-18)>>3;
            valid=1;
        end

        end

        if(v_cnt>=13&&v_cnt<79) begin//left right bound
        if(h_cnt>=235&&h_cnt<240&&(input_pos==2'd3||input_pos==2'd0)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=290&&h_cnt<295&&(input_pos==2'd0||input_pos==2'd1)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=345&&h_cnt<350&&(input_pos==2'd1||input_pos==2'd2)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=400&&h_cnt<405&&(input_pos==2'd2||input_pos==2'd3)) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end


        end

        else if(v_cnt>=89&&v_cnt<145) begin//score

            if(h_cnt>=40&&h_cnt<80) begin
            mem_txt_addr=S;
            reg_h_cnt_compressed=(h_cnt-40)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=90&&h_cnt<130) begin
            reg_h_cnt_compressed=(h_cnt-90)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            mem_txt_addr=C;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=140&&h_cnt<180) begin
            mem_txt_addr=O;
            reg_h_cnt_compressed=(h_cnt-140)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=190&&h_cnt<230)begin
            mem_txt_addr=R;
            reg_h_cnt_compressed=(h_cnt-190)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<280)begin
            mem_txt_addr=E;
            reg_h_cnt_compressed=(h_cnt-240)>>3;
            reg_v_cnt_compressed=(v_cnt-89)>>3;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<400) begin
                mem_txt_addr=(score/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=410&&h_cnt<450) begin
                mem_txt_addr=(score/1000)%10;
                reg_h_cnt_compressed=(h_cnt-410)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=460&&h_cnt<500) begin
                mem_txt_addr=(score/100)%10;
                reg_h_cnt_compressed=(h_cnt-460)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=510&&h_cnt<550) begin
                mem_txt_addr=(score/10)%10;
                reg_h_cnt_compressed=(h_cnt-510)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=560&&h_cnt<600) begin
                mem_txt_addr=(score)%10;
                reg_h_cnt_compressed=(h_cnt-560)>>3;
                reg_v_cnt_compressed=(v_cnt-89)>>3;
                valid=1;
                bound=0;
            end

        end

        else if(v_cnt>=8&&v_cnt<13) begin//upper bound

        if(h_cnt>=235&&h_cnt<295&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=290&&h_cnt<350&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=345&&h_cnt<405&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<405&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end

        end

        else if(v_cnt>=79&&v_cnt<84) begin//lower bound


            if(h_cnt>=235&&h_cnt<295&&input_pos==2'd0) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=290&&h_cnt<350&&input_pos==2'd1) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=345&&h_cnt<405&&input_pos==2'd2) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end
        else if(h_cnt>=235&&h_cnt<405&&input_pos==2'd3) begin
            mem_txt_addr=0;
            bound=1;
            reg_h_cnt_compressed=0;
            reg_v_cnt_compressed=0;
            valid=1;
        end            
        end

        else if(v_cnt>=150&&v_cnt<178)begin//rank 1
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=1;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            mem_txt_addr=ch_record[0][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[0][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[0][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-150)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[0]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[0]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[0]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[0]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[0])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-150)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=183&&v_cnt<211)begin//rank 2
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=2;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            mem_txt_addr=ch_record[1][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[1][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[1][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-183)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[1]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[1]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[1]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[1]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[1])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-183)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=216&&v_cnt<244)begin//rank 3
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=3;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            mem_txt_addr=ch_record[2][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[2][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[2][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-216)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[2]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[2]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[2]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[2]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[2])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-216)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=249&&v_cnt<277)begin//rank 4
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=4;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            mem_txt_addr=ch_record[3][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[3][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[3][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-249)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[3]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[3]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[3]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[3]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[3])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-249)>>2;
                valid=1;
                bound=0;
            end
        end
        else if(v_cnt>=282&&v_cnt<310)begin//rank 5
            if(h_cnt>=140&&h_cnt<160) begin
            mem_txt_addr=5;
            reg_h_cnt_compressed=(h_cnt-140)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=240&&h_cnt<260) begin
            reg_h_cnt_compressed=(h_cnt-240)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            mem_txt_addr=ch_record[4][0]+10;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=270&&h_cnt<290) begin
            mem_txt_addr=ch_record[4][1]+10;
            reg_h_cnt_compressed=(h_cnt-270)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=300&&h_cnt<320)begin
            mem_txt_addr=ch_record[4][2]+10;
            reg_h_cnt_compressed=(h_cnt-300)>>2;
            reg_v_cnt_compressed=(v_cnt-282)>>2;
            valid=1;
            bound=0;
            end
            else if(h_cnt>=360&&h_cnt<380) begin
                mem_txt_addr=(score_rank[4]/10000);
                reg_h_cnt_compressed=(h_cnt-360)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=390&&h_cnt<410) begin
                mem_txt_addr=(score_rank[4]/1000)%10;
                reg_h_cnt_compressed=(h_cnt-390)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=420&&h_cnt<440) begin
                mem_txt_addr=(score_rank[4]/100)%10;
                reg_h_cnt_compressed=(h_cnt-420)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=450&&h_cnt<470) begin
                mem_txt_addr=(score_rank[4]/10)%10;
                reg_h_cnt_compressed=(h_cnt-450)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
            end
            else if(h_cnt>=480&&h_cnt<500) begin
                mem_txt_addr=(score_rank[4])%10;
                reg_h_cnt_compressed=(h_cnt-480)>>2;
                reg_v_cnt_compressed=(v_cnt-282)>>2;
                valid=1;
                bound=0;
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