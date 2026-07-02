`timescale 1ns/1ps

module ReLU_func (
    output reg signed [35:0] out,
    input signed [35:0] in
);

always @ (*) begin
    if (in[35]) out = 'd0;
    else out = in;
end

endmodule