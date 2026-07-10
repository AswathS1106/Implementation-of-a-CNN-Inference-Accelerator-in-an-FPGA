`timescale 1ns/1ps

module max_pool(
    input clk,
    input rst,

    input signed [23:0] feature_data,
    input feature_valid,

    output reg signed [23:0] max_out,
    output reg max_valid
);

reg signed [23:0] current_max;
reg [2:0] sample_count;

wire signed [23:0] next_max;
assign next_max = (sample_count == 0) ? feature_data : 
                        ((feature_data > current_max) ? feature_data : current_max);

initial begin
    max_out = 'd0;
    max_valid = 'd0;

    current_max = 'd0;
    sample_count = 'd0;
end

always @(posedge clk) begin
    if (rst) begin
        current_max <= 'd0;
        sample_count <= 'd0;
        max_valid <= 'd0;
        max_out <= 'd0;
    end

    else if(feature_valid) begin

        current_max <= next_max;

        if(sample_count == 3) begin
            sample_count <= 0;
            max_out <= next_max;
            max_valid <= 'd1;
        end

        else begin
            sample_count <= sample_count + 1;
            max_valid <= 'd0;
        end
    end

    else max_valid <= 'd0;
end

endmodule
