`timescale 1ns/1ps

module image_memory #( parameter FILE_NAME = "image_file.mem") (
    output reg [7:0] pixel_out,
    input wire clk,
    input wire rst,
    input wire [7:0] rd_addr
);

reg [7:0] image_memory [0:16*16-1];

//integer i;

initial begin    
    $readmemb(FILE_NAME, image_memory);//Can include file location instead of "image file.mem"
/*
    for (i = 0; i < 16*16; i = i + 1) begin
          $display("Address %0d: %b", i, image_memory[i]);
      end
*/
end

always @ (posedge clk) begin
    if (rst) pixel_out <= 'd0;
    else pixel_out <= image_memory[rd_addr];
end
endmodule
