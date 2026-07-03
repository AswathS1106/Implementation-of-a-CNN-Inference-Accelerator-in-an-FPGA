`timescale 1ns/1ps

module window_gen(
    output reg [9*8-1:0] window,
    output reg win_set_done,
    output reg win_valid,//Sends to MAC that next window has valid data

    input clk,
    input rst,

    input wire [8*16-1:0] row_a_reg,
    input wire [8*16-1:0] row_b_reg,
    input wire [8*16-1:0] row_c_reg,
    input rows_rdy,//Signal that rows are ready for use
    input next_win_req//Signal from MAC requesting next window
);

reg [3:0] i;
reg processing; // Captures the 1 clk cycle change of rows_rdy
reg wait_for_mac_req;

wire [3:0] current_i = rows_rdy ? 'd0 : i;
//Using comb. ckt. here to achieve 0 latency in case of i
//Otherwise it would cause the last value to miss

initial begin
    window = 'd0;
    win_set_done = 'd0;
    i = 0;
    processing = 'd0;
    wait_for_mac_req = 'd0;
end

always @(posedge clk) begin
    if (rst) begin
        window <= 'd0;
        win_set_done <= 'd0;
        i <= 'd0;
        processing <= 'd0;
        win_valid <= 'd0;
        wait_for_mac_req <= 'd0;
    end

    else begin

        win_valid <= 'd0;//always set it to 0
        win_set_done <= 'd0;

        if (rows_rdy) begin
            processing <= 'd1;
            i <= 'd0;
            wait_for_mac_req <= 'd0;
        end

        if (wait_for_mac_req && next_win_req) begin
            win_set_done <= 'd1;
            wait_for_mac_req <= 'd0;
        end

        //The if cond. such that ckt. starts the moment rows_rdy is high
        //i.e. Ensuring that delayed rising of processing signal compared to rows_rdy doesn't happen
        if (rows_rdy || (processing && next_win_req)) begin
        window[0+:8] <= row_a_reg[current_i*8+:8];
        window[8+:8] <= row_a_reg[(current_i+1)*8+:8];
        window[16+:8] <= row_a_reg[(current_i+2)*8+:8];

        window[24+:8] <= row_b_reg[current_i*8+:8];
        window[32+:8] <= row_b_reg[(current_i+1)*8+:8];
        window[40+:8] <= row_b_reg[(current_i+2)*8+:8];

        window[48+:8] <= row_c_reg[current_i*8+:8];
        window[56+:8] <= row_c_reg[(current_i+1)*8+:8];
        window[64+:8] <= row_c_reg[(current_i+2)*8+:8];

        win_valid <= 'd1;

        if (current_i == 13) begin
            wait_for_mac_req <= 'd1;
            processing <= 'd0;
        end

        else i <= current_i + 1;
        end
    end
end    

endmodule