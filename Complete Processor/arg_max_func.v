`timescale 1ns/1ps

module arg_max_func (
    input clk,
    input rst,

    input wire signed [43:0] score1,
    input score1_valid,

    input wire signed [43:0] score2,
    input score2_valid,

    input wire signed [43:0] score3,
    input score3_valid
);

reg signed [43:0] score1_latch;
reg score1_valid_latch;
reg signed [43:0] score2_latch;
reg score2_valid_latch;
reg signed [43:0] score3_latch;
reg score3_valid_latch;
reg clear;

always @(posedge clk) begin
    if (rst || clear) begin
        score1_valid_latch <= 0;
        score2_valid_latch <= 0;
        score3_valid_latch <= 0;
        clear <= 0;
    end

    if (score1_valid) begin 
        score1_valid_latch <= 'd1;
        score1_latch <= score1;
    end
    if (score2_valid) begin 
        score2_valid_latch <= 'd1;
        score2_latch <= score2;
    end
    if (score3_valid) begin 
        score3_valid_latch <= 'd1;
        score3_latch <= score3;
    end

    if (score1_valid_latch && score2_valid_latch && score3_valid_latch) begin
        if ((score1_latch > score2_latch) && (score1_latch > score3_latch)) $display ("Image is 0.");
        else if ((score2_latch > score1_latch) && (score2_latch > score3_latch)) $display ("Image is 1.");
        else  $display ("Image is neither 0 nor 1.");
        clear <= 1;
    end
end
endmodule
