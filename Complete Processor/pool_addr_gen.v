`timescale 1ns/1ps

module pool_addr_gen(
    input clk,
    input rst,
    input ft_mem_full,

    output reg [7:0] rd_addr,
    output reg rd_valid,
    output reg pool_done
);

reg [3:0] pool_row;
reg [3:0] pool_col;
reg [3:0] phase;
wire [7:0] base_addr;

assign base_addr = pool_row * 14 + pool_col;

localparam PHASE0 = 'd0;
localparam PHASE1 = 'd1;
localparam PHASE2 = 'd2;
localparam PHASE3 = 'd3;
localparam WAIT_STATE = 'd4;

initial begin
    rd_addr = 'd0;
    rd_valid = 'd0;
    pool_done  = 'd0;

    pool_row = 'd0; pool_col = 'd0;
    phase = 'd0;
end

always @(posedge clk) begin
    if (rst)
        phase <= 0;
    else if (ft_mem_full) begin
        if (phase == 4)
            phase <= 0;
        else
            phase <= phase + 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        rd_addr <= 'd0;
        rd_valid <= 'd0;
        pool_done  <= 'd0;
        pool_row <= 'd0; pool_col <= 'd0;
    end

    else if (ft_mem_full && !(pool_done)) begin
        case(phase)
        PHASE0:
        begin 
            rd_valid <= 'd1;
            rd_addr <= base_addr;
        end

        PHASE1: rd_addr <= rd_addr + 1;
        
        PHASE2: rd_addr <= rd_addr + 13;//rd_addr = rd_addr -1 + 14
        
        PHASE3: rd_addr <= rd_addr + 1;//rd_addr = rd_addr-14+15

        WAIT_STATE:
        begin
            rd_valid <= 'd0;
            
            if(pool_col == 12) begin
                pool_col <= 0;

                if (pool_row == 12) begin
                    pool_done <= 'd1;
                    rd_valid <= 'd0;
                end
                else pool_row <= pool_row + 2;
            end
            else pool_col <= pool_col + 2;
        end

        default:; //do nothing
        endcase
    end
end

endmodule
