`timescale 1ns/1ps

module proc_img_mem (
    output reg signed [35:0] rd_data,
    output reg mem_full,

    input signed [35:0] wr_data,
    input wr_valid,

    input clk,
    input rst,

    input [7:0] rd_addr,
    input rd_valid
);

reg signed [35:0] proc_img_arr [7*7-1:0];
integer i;
reg [6:0] wr_addr;

initial begin
    wr_addr = 'd0;
    mem_full = 'd0;

    for (i=0; i<7*7; i=i+1) begin
        proc_img_arr[i] = 'd0;
    end
end

always @(posedge clk) begin

    if (rst) begin
        wr_addr <= 'd0;
        mem_full <= 'd0;
        
        for (i=0; i<7*7; i=i+1) begin
            proc_img_arr[i] <= 'd0;
        end
    end

    if(!(mem_full))begin

        if (wr_valid) begin
        proc_img_arr[wr_addr] <= wr_data;
        wr_addr <= wr_addr + 1;
            
        if (wr_addr == 7*7-1) mem_full <= 'd1;
        end
    end

    else if (rd_valid) rd_data <= proc_img_arr[rd_addr];

end
    
endmodule