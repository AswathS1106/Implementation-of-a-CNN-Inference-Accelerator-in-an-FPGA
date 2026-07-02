`timescale 1ns/1ps

module data_converter (
    output reg [9*16-1:0] converted_window,

    input wire [9*8-1:0] window
);

integer i;

initial begin
    converted_window = 'd0;
    i=0;
end

always @(*) begin

    for (i=0; i<9; i=i+1) begin
        converted_window[(i*16)+:16] = {1'd0, window[(i*8)+:8], 7'd0};
    end
end
endmodule