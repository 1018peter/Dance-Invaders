module receiver#(parameter n = 6)  //four phase handshaking receiver,parameter means the number of total bits per unit data. 
               (input clk_receiver, //clock domain of the receiver.
                input wire_req,   //require signal from sender
                input [5:0] wire_data_deliver, //data of delivering
                input rst,  //reset
                output [n-1:0] wire_data_out, //unit data you want to transfer.
                output reg reg_ack, //acknowlege signal from receiver.
                output reg reg_valid); //Is the data enable to use? 1 means yes,0 means no.
    parameter m=n+6-n%6;
    reg [7:0] reg_pointer;//pointer of the beginning of where 6 bit data should transfer
    reg reg_ready;//ready to receive?1:0;
    reg [m-1:0] reg_data_result;//enough space to store output.
    integer i;
    always @(posedge clk_receiver or posedge rst) begin
        if(rst) begin
            reg_ack   <= 0;
            reg_ready <= 1;
            reg_data_result <=0;
            reg_pointer <= 0;
            reg_valid <= 0;
        end 
        else begin   
        if (wire_req == 1) begin
            reg_ack   <= 1;
            reg_ready <= 0;
            for(i = 0;i<6;i = i+1) begin
                if (reg_pointer+i<n) 
                    reg_data_result[reg_pointer+i]      <= wire_data_deliver[i];
                else reg_data_result[reg_pointer+i] <= 0;
            end
            reg_pointer <= reg_pointer;
            reg_valid <= 0;
        end
        else begin
            reg_ack <= 0;
            if (reg_ready) begin
                reg_ready   <= 1;
                reg_valid <= reg_valid;
                reg_pointer <= reg_pointer;
                for(i = 0;i<6;i = i+1) begin
                    if (reg_pointer+i<n)
                       reg_data_result[reg_pointer+i] <= wire_data_deliver[i];
                    else reg_data_result[reg_pointer+i] <= 0;
                end
            end
            else begin
            reg_ready <= 1;
            for(i = 0;i<6;i = i+1) begin
                reg_data_result[i] <= wire_data_deliver[i];
            end
            if (reg_pointer+6<n) begin
                reg_pointer      <= reg_pointer+6;
                reg_valid <= 0;
            end
            else  begin
                reg_pointer <= 0;
                reg_valid <=1;
            end
            end
        end
        end
    end
    assign wire_data_out=reg_data_result[n-1:0];               
                                
                                
endmodule
