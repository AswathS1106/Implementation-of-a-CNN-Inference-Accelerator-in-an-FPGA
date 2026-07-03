`timescale 1ns/1ps

module weight_memory #(parameter WT_FILE_NAME = "default_file.mem",
BIAS_FILE_NAME = "default_file.mem"
)(
    output reg [9*16-1:0] weights,
    output reg signed [16-1:0] bias
);

reg signed [15:0] weights_reg [8:0];
reg [15:0] bias_reg [0:0];

integer i;

    initial begin
        $readmemb(WT_FILE_NAME, weights_reg);
        for (i=0; i<9; i=i+1) weights[i*16+:16] = weights_reg[i];

        $readmemb(BIAS_FILE_NAME, bias_reg);
        bias = bias_reg[0];
    end
endmodule