`timescale 1ns/1ps

module ReLU_func (
    output reg signed [23:0] out,
    input signed [23:0] in
);

always @ (*) begin
    if (in[23]) out = 'd0;
    else out = in;
end

endmodule