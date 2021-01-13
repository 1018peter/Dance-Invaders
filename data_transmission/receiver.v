module receiver#(parameter n = 1500)  //four phase handshaking receiver,parameter means the total bits  to transfer. 
               (input clk_receiver, //clock domain of the receiver.
                input wire_req,   //require signal from sender
                input [5:0] wire_data_deliver, //data of delivering
                output reg [n-1:0] wire_data_out, //unit data you want to transfer.
                output reg reg_ack, //acknowlege signal from receiver.
                output reg reg_valid); //Is the data enable to use? 1 means yes,0 means no.
    parameter m=n+4-n%4;
    reg [10:0] reg_pointer=0;//pointer of the beginning of where 4 bit data should transfer
    reg reg_ready=1;//ready to receive?1:0;
    reg [m-1:0] reg_data_result=0;//enough space to store output.
    reg reg_header_receive=0;//receive header?1:0;
    integer i;
    always @(posedge clk_receiver) begin
        if (wire_req == 1'b1) begin
            if(wire_data_deliver[0]^wire_data_deliver[1]^wire_data_deliver[2]^wire_data_deliver[3]^wire_data_deliver[4]^wire_data_deliver[5]==1) begin
            reg_ack   <= 1;
            reg_ready <=0;
            if(reg_header_receive==1'b1) begin
                for(i = 0;i<4;i = i+1) begin
                if (reg_pointer+i<n) 
                    reg_data_result[reg_pointer+i]      <= wire_data_deliver[i];
                else reg_data_result[reg_pointer+i] <= 0;
                end
                if(wire_data_deliver[4]==1'b1)  begin
                    reg_pointer <=0;
                    reg_header_receive <= 0;
                    reg_ready <= 0;
                end
                else begin
                    reg_pointer <= reg_pointer;
                    reg_header_receive<=reg_header_receive;
                    reg_ready <= 0;
                end
            end
            else begin
                    reg_pointer <= 0;
                    reg_header_receive<=0;
                    reg_ready <= 0;
                reg_data_result<=0;
            end
            reg_valid <= 0;
            end
            else begin
                reg_ack <=0;
                reg_ready <=0;
                reg_header_receive <=reg_header_receive;
                for(i = 0;i<4;i = i+1) begin
                if (reg_pointer+i<n) 
                    reg_data_result[reg_pointer+i]      <= wire_data_deliver[i];
                else reg_data_result[reg_pointer+i] <= 0;
                end
                reg_pointer <= reg_pointer;
                reg_valid <= 0;
            end
        end
        else begin
            reg_ack <= 0;
            if (reg_ready) begin
                reg_ready   <= 1;
                reg_valid <= reg_valid;
                reg_pointer <= reg_pointer;
                reg_data_result <=reg_data_result;
                reg_header_receive <= reg_header_receive;

            end
            else begin
            reg_ready <= 1;
            reg_data_result<=reg_data_result;
            if (reg_pointer+4<n&&reg_header_receive==1) begin
                reg_pointer      <= reg_pointer+4;
                reg_valid <= 0;
                reg_header_receive<=reg_header_receive;
            end
            else if(reg_header_receive==0)begin
                reg_pointer <= 0;
                reg_valid <=0;
                reg_header_receive<=1;
            end
            else begin
                reg_pointer <= 0;
                reg_valid <=1;
                reg_header_receive<=0;
            end
            end
        end
    end
    always @(posedge clk_receiver) begin
        if(reg_valid) begin
            wire_data_out <= reg_data_result[n-1:0];
        end
        else begin
            wire_data_out <= wire_data_out;
        end
    end              
                                
                                
endmodule
