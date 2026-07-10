`timescale 1ns/1ps

module feature_mat_mem (
    output reg signed [23:0] rd_data,
    output reg rd_data_valid,
    output reg mem_full,

    input signed [23:0] wr_data,
    input wr_valid,

    input clk,
    input rst,

    input [7:0] rd_addr,
    input rd_valid
);

reg signed [23:0] feature_mat_arr [0:14*14-1];
integer i;
reg [7:0] wr_addr;

initial begin
    wr_addr = 'd0;
    mem_full = 'd0;
    rd_data_valid = 'd0;
    rd_data = 'd0;

    for (i=0; i<14*14; i=i+1) begin
        feature_mat_arr[i] = 'd0;
    end
end

always @(posedge clk) begin
    rd_data_valid <= 0;

    if (rst) begin
        wr_addr <= 'd0;
        mem_full <= 'd0;
        rd_data_valid <= 'd0;
        rd_data <= 'd0;

        for (i=0; i<14*14; i=i+1) begin
            feature_mat_arr[i] <= 'd0;
        end
    end

    if(!(mem_full))begin

        if (wr_valid) begin
            feature_mat_arr[wr_addr] <= wr_data;
            wr_addr <= wr_addr + 1;
                
            if (wr_addr == 195) begin 
                    mem_full <= 'd1;
                    wr_addr <= 'd0;
            end
        end
    end

    else if (rd_valid) begin 
        rd_data <= feature_mat_arr[rd_addr];
        rd_data_valid <= 1;
    end

end
endmodule
