module sender #(parameter n = 1500)  //four phase handshaking sender,parameter means the total bits you may transfer.
               (input clk_sender, //clock domain of the sender.
                input wire_ack,   //acknowledge signal from receiver
                input[n-1:0] wire_data_in, //unit data you want to transfer.
                input rst,   //reset
                output reg [5:0] reg_data_out, //data to deliver
                output reg reg_req); //require signal from sender.
    reg [10:0] reg_pointer;//pointer of the beginning of where 4 bit data should transfer
    reg [n-1:0] reg_data_register;//buffer to store data until transmission finish.
    reg reg_ready;//ready to send?1:0;
    reg reg_header;//has header been sent?1:0;
    reg reg_xor;//just for xor operation for odd parity.
    reg reg_rst;//record rst signal to transfer to the receiver.
    reg [3:0] reg_xor_register;//just for xor operation for odd parity.
    integer i;
    always @* begin
        if(reg_header==1) begin
            for(i = 0;i<4;i = i+1) begin
                if (reg_pointer+i<n) 
                    reg_xor_register[i]      <= reg_data_register[reg_pointer+i];
                else reg_xor_register[i]    <= 0;
            end
        end
        else begin
            reg_xor_register[3:0]<=4'd0;
        end
        reg_xor=reg_xor_register[0]^reg_xor_register[1]^reg_xor_register[2]^reg_xor_register[3]^reg_rst^1;
    end
    always @(posedge clk_sender or posedge rst) begin
        if(rst) begin
            reg_req   <= 1'b0;
            reg_ready <= 1;
            reg_data_out <=6'b010000;
            reg_pointer <= 0;
            reg_header <=0;
            reg_rst <= 1;
        end
        else begin
            if (wire_ack == 1'b0) begin
                reg_req   <= 1;
                reg_ready <= 0;
                reg_rst <= reg_rst;
                reg_header <= reg_header;
                if(reg_header==1) begin
                for(i = 0;i<4;i = i+1) begin
                    if (reg_pointer+i<n) 
                        reg_data_out[i]      <= reg_data_register[reg_pointer+i];
                    else reg_data_out[i]    <= 0;
                end
                end
                else begin
                    reg_data_out[3:0]<=4'd0;
                end
                reg_data_out[4]<=reg_rst;
                reg_data_out[5] <= reg_xor;
                reg_pointer <= reg_pointer;
            end
            else begin
                reg_req <= 0;
                reg_rst <=0;
                if (reg_ready) begin
                reg_ready   <= 1;
                reg_pointer <= reg_pointer;
                reg_header <=reg_header;
                for(i = 0;i<6;i = i+1) begin
                    reg_data_out[i] <= reg_data_out[i];
                end
                end
                else begin
                reg_ready <= 1;
                for(i = 0;i<6;i = i+1) begin
                    reg_data_out[i] <= reg_data_out[i];
                end
                if (reg_pointer+4<n&&reg_header==1) begin
                    reg_pointer      <= reg_pointer+4;
                    reg_header <= 1;
                end
                else if(reg_header==0) begin
                    reg_header <= 1;
                    reg_pointer <= 0;
                end
                else begin
                    reg_header <= 0;
                    reg_pointer <= 0;
                end
                end
            end
        end
    end

    always @(posedge clk_sender or posedge rst) begin
        if(rst) begin
            reg_data_register <= 0;
        end
        else begin
        if(reg_pointer==0&&reg_header==0)begin
            reg_data_register <= wire_data_in;
        end
        else begin
            reg_data_register <= reg_data_register;
        end
        end
    end
                                
                                
                                
endmodule
