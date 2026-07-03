`timescale 1ns/1ps
`include "window_gen.v"
`include "line_buffer.v"
`include "pixel_rdr.v"
`include "image_memory.v"
`include "data_converter.v"
`include "weight_memory.v"
`include "mac3.v"
`include "ReLU_func.v"
`include "feature_mat_mem.v"
`include "pool_addr_gen.v"
`include "max_pool.v"
`include "proc_img_mem.v"

module proc_img_mem_tb;

reg clk;
reg rst;

reg lb_st;


wire [7:0] row_in_stream;
wire pixel_valid;

wire [7:0] img_rd_addr;
wire [7:0] pixel_in;

wire [8*16-1:0] row_a_reg;
wire [8*16-1:0] row_b_reg;
wire [8*16-1:0] row_c_reg;
wire rows_rdy;
wire pixel_req;

wire [9*8-1:0] window;
wire [9*16-1:0] converted_window;
wire win_set_done;
wire win_valid;
wire next_win_req;

wire signed [16-1:0] bias;
wire [(16*9)-1:0] weights;

wire signed [35:0] conv_sum;
wire wr_valid;

wire signed [35:0] final_sum;
wire [7:0] ft_rd_addr;
wire ft_rd_valid;
wire signed [35:0] ft_rd_data;
wire ft_mem_full;

wire pool_done;
wire ft_rd_data_valid;

wire [35:0] max_out;
wire max_valid;
integer val_no;


reg [7:0] proc_img_rd_addr;
reg proc_img_rd_valid;
wire [35:0] proc_img_rd_data;
wire proc_img_mem_full;

image_memory #(.FILE_NAME("image_file.mem")) tb_mem (.clk(clk), .rst(rst), .rd_addr(img_rd_addr), .pixel_out(pixel_in));
pixel_rdr tb_rdr (.pixel_out(row_in_stream), .pixel_valid(pixel_valid), .rd_addr(img_rd_addr), .clk(clk), .rst(rst),
                    .pixel_in(pixel_in), .pixel_req(pixel_req));
line_buffer tb_lb (.clk(clk), .rst(rst), .lb_st(lb_st), .row_in_stream(row_in_stream),
                    .pixel_valid(pixel_valid), .win_set_done(win_set_done),
                    .row_a_reg(row_a_reg), .row_b_reg(row_b_reg), .row_c_reg(row_c_reg),
                    .rows_rdy(rows_rdy), .pixel_req(pixel_req));
window_gen tb_win_gen (.clk(clk), .rst(rst), .row_a_reg(row_a_reg), .row_b_reg(row_b_reg), .row_c_reg(row_c_reg),
                        .rows_rdy(rows_rdy), .next_win_req(next_win_req),
                        .window(window), .win_set_done(win_set_done), .win_valid(win_valid));
data_converter tb_data_converter (.window(window), .converted_window(converted_window));
weight_memory #(.WT_FILE_NAME("weights.mem"), .BIAS_FILE_NAME("bias.mem")) tb_weight_memory (.bias(bias), .weights(weights));
mac_int tb_mac (.clk(clk), .rst(rst), .bias(bias), .weights(weights), .pixel_win(converted_window), .win_valid(win_valid),
                    .conv_sum(conv_sum), .next_win_req(next_win_req), .wr_valid(wr_valid));
ReLU_func tb_ReLU (.in(conv_sum), .out(final_sum));
feature_mat_mem tb_feature_mat_mem (.clk(clk), .rst(rst), .wr_valid(wr_valid), .wr_data(final_sum),
                                        .rd_addr(ft_rd_addr), .rd_valid(ft_rd_valid), .rd_data_valid(ft_rd_data_valid),
                                        .rd_data(ft_rd_data), .mem_full(ft_mem_full));
pool_addr_gen tb_pool_addr_gen (.clk(clk), .rst(rst), .ft_mem_full(ft_mem_full),
                                .rd_addr(ft_rd_addr), .rd_valid(ft_rd_valid), .pool_done(pool_done));
max_pool tb_max_pool (.clk(clk), .rst(rst), .feature_data(ft_rd_data), .feature_valid(ft_rd_data_valid),
                        .max_out(max_out), .max_valid(max_valid));
proc_img_mem tb_proc_img_mem (.clk(clk), .rst(rst), .rd_addr(proc_img_rd_addr), .rd_valid(proc_img_rd_valid),
                                .wr_data(max_out), .wr_valid(max_valid),
                                .rd_data(proc_img_rd_data), .mem_full(proc_img_mem_full));

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1;
    lb_st = 0;
    val_no = 'd0;
    proc_img_rd_addr = 0;
    proc_img_rd_valid = 0;

    #25;

    rst = 0;

    #20;
    lb_st = 1;

    #10;
    lb_st = 0;
end

// 1. Remove your old "always @(posedge clk) begin if (proc_img_mem_full)..." block entirely

// 2. Replace your simulation control initial block with this:
initial begin
    rst = 1;
    lb_st = 0;
    val_no = 'd0;
    proc_img_rd_addr = 0;
    proc_img_rd_valid = 0;

    #25;
    rst = 0; 
    #20;
        
    lb_st = 1; // Trigger convolution pipe execution
    #10;
    lb_st = 0;

    // Wait until convolution completely populates the intermediate matrix
    wait(ft_mem_full == 1'b1);
    $display("\n[SYSTEM] Feature Matrix Memory is Full. Initializing Pool address stream...\n");
      
    // Wait until address generation sequences have completed scanning
    wait(pool_done == 1'b1);
    $display("[SYSTEM] Max-Pool address generator finished completely.");

    // Wait until the final processed image memory array flags full
    wait(proc_img_mem_full == 1'b1);
    #50; // Allow final signals to settle cleanly
    $display("\n=======================================================");
    $display(" IMAGE COMPLETELY PROCESSED & STORED SUCCESSFULLY");
    $display("=======================================================");
    
    // Clean, deterministic sequential array readout printing
    for (val_no = 0; val_no < 49; val_no = val_no + 1) begin
        $display("Time: %0t | Stored Pixel Index [%2d] = %d", 
                 $time, val_no, tb_proc_img_mem.proc_img_arr[val_no]);
    end
    $display("=======================================================\n");

    #100;
    $finish;
end



initial begin
    #17500;
    $finish;
end

initial begin
    $dumpfile("proc_img_mem.vcd");
    $dumpvars(0, proc_img_mem_tb);
end
endmodule