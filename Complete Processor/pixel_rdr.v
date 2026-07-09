`timescale 1ns/1ps

module pixel_rdr (
    output reg [7:0] pixel_out, //Gives output
    output reg pixel_valid, //Output saying pixel is valid
    output reg [7:0] rd_addr,//Goes to image_memory module

    input clk,
    input rst,
    input [7:0] pixel_in, //Comes from image_memory module
    input wire pixel_req //Request comes from line buffer
);

reg valid_pipe;

always @(posedge clk) begin
    if(rst) begin
        rd_addr     <= 0;
        pixel_out   <= 8'd0;
        pixel_valid <= 1'b0;
        valid_pipe <= 1'b0;
    end

    else begin
        // 1st cycle of delay from pixel_req
        valid_pipe  <= pixel_req;
        
        // 2nd cycle of delay to perfectly match pixel_out
        pixel_valid <= valid_pipe;
        
        // pixel_out directly captures pixel_in (which is already delayed 1 cycle by image_memory)
        pixel_out <= pixel_in;
        
        // Address only increments when an active request is made
        if(pixel_req) begin
            rd_addr <= rd_addr + 1;
        end
    end
end
/*
always @(posedge clk) begin
    if (rst || rd_addr == 8'd255) begin
        rd_addr <= 'd0;
        pixel_valid <= 'd0;
        pixel_out <= 'd0;
    end

    else if (pixel_req) begin 
        pixel_out <= pixel_in;
        pixel_valid <= 'd1;
        rd_addr <= rd_addr + 1;
    end

    else pixel_valid <= 'd0;
end
*/
endmodule