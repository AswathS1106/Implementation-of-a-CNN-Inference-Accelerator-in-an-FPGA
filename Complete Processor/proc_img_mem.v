`timescale 1ns/1ps

module proc_img_mem (
    output reg signed [23:0] rd_data,
    output reg mem_full,

    input signed [23:0] wr_data,
    input wr_valid,

    input clk,
    input rst,

    input nxt_rd_req
);

reg signed [23:0] proc_img_arr [0:7*7-1];
integer i;
reg [6:0] wr_addr;
reg [6:0] rd_addr;

initial begin
    wr_addr = 'd0;
    rd_addr = 'd0;
    mem_full = 'd0;

    for (i=0; i<7*7; i=i+1) proc_img_arr[i] = 'd0;
end

always @(posedge clk) begin

    if (rst) begin
        wr_addr <= 'd0;
        rd_addr <= 'd0;
        mem_full <= 'd0;
        
        for (i=0; i<7*7; i=i+1) proc_img_arr[i] <= 'd0;
    end

    else if(!(mem_full))begin
        if (wr_valid) begin
        proc_img_arr[wr_addr] <= wr_data;
        wr_addr <= wr_addr + 1;
            
        if (wr_addr == 7*7-1) mem_full <= 'd1;
        end
    end

    else if (nxt_rd_req) begin
        rd_data <= proc_img_arr[rd_addr];
        if (rd_addr < 7*7-1) rd_addr <= rd_addr +1;
    end
end
endmodule
