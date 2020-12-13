module sender #(parameter n = 6)  //four phase handshaking sender,parameter means the number of total bits per unit data. 
               (input clk_sender, //clock domain of the sender.
                input wire_ack,   //acknowledge signal from receiver
                input[n-1:0] wire_data_in, //unit data you want to transfer.
                input wire_write_en,       //enable to transfer? 1 means yes,0 means no.
                input rst,   //reset
                output reg [5:0] reg_data_out, //data to deliver
                output reg reg_req); //require signal from sender.
    reg [7:0] reg_pointer;//pointer of the beginning of where 6 bit data should transfer
    reg [n-1:0] reg_data_register;//buffer to store data until transmission finish.
    reg reg_ready;//ready to send?1:0;
    integer i;
    always @(posedge clk_sender or posedge rst) begin
        if(rst) begin
            reg_req   <= 0;
            reg_ready <= 1;
            reg_data_out <=0;
            reg_pointer <= 0;
        end
        else begin
        if (wire_write_en) begin
            if (wire_ack == 0) begin
                reg_req   <= 1;
                reg_ready <= 0;
                for(i = 0;i<6;i = i+1) begin
                    if (reg_pointer+i<n) 
                        reg_data_out[i]      <= reg_data_register[reg_pointer+i];
                    else reg_data_out[i]    <= 0;
                end
                reg_pointer <= reg_pointer;
            end
            else begin
                reg_req <= 0;
                if (reg_ready) begin
                    reg_ready   <= 1;
                    reg_pointer <= reg_pointer;
                    for(i = 0;i<6;i = i+1) begin
                        if (reg_pointer+i<n)
                           reg_data_out[i]      <= reg_data_register[reg_pointer+i];
                        else reg_data_out[i]    <= 0;
                   end
                end
                else begin
                reg_ready <= 1;
                for(i = 0;i<6;i = i+1) begin
                    reg_data_out[i] <= reg_data_register[i];
                end
                if (reg_pointer+6<n)
                    reg_pointer      <= reg_pointer+6;
                else
                    reg_pointer <= 0;
                end
            end
        end
        else begin
            reg_req   <= 0;
            reg_ready   <= 1;
            reg_pointer <= 0;
            for(i = 0;i<6;i = i+1) begin
                reg_data_out[i] <= reg_data_register[i];
            end
        end
        end
    end

    always @(posedge clk_sender or posedge rst) begin
        if(rst) begin
            reg_data_register <= wire_data_in;
        end
        else begin
        if(reg_pointer+6>=n)begin
            reg_data_register <= wire_data_in;
        end
        else begin
            reg_data_register <= reg_data_register;
        end
        end
    end
                                
                                
                                
endmodule
