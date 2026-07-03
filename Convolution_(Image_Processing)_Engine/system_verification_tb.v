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

module system_verification_tb;

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

reg [7:0] proc_img_rd_addr;
reg proc_img_rd_valid;
wire [35:0] proc_img_rd_data;
wire proc_img_mem_full;

reg signed [35:0] exp_conv [0:195];
reg signed [35:0] exp_relu [0:195];
reg signed [35:0] exp_pool [0:48];
integer conv_idx;

integer conv_errors, relu_errors, pool_errors;

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
    $readmemb("expected_conv.mem", exp_conv);
    $readmemb("expected_relu.mem", exp_relu);
    $readmemb("expected_pool.mem", exp_pool);
    
    conv_idx = 0;
    conv_errors = 0;
    relu_errors = 0;
    pool_errors = 0;
    
    rst = 1; lb_st = 0;
    #25; rst = 'd0;
    #20; lb_st = 1;
    #10; lb_st = 0;

    $display("---------------------------------------------------");
    $display("   STARTING FULL PIPELINE HARDWARE VERIFICATION");
    $display("---------------------------------------------------");

    wait(proc_img_mem_full == 1'b1);
    #50; // Settle time
        
    $display("\nChecking Final Max-Pool Matrix (7x7) against Expected...");
    for (integer i = 0; i < 49; i = i + 1) begin
        if (tb_proc_img_mem.proc_img_arr[i] !== exp_pool[i]) begin
            $display("  [POOL ERROR] Index %0d: Expected = %0d, Got = %0d", i, exp_pool[i], tb_proc_img_mem.proc_img_arr[i]);
            pool_errors = pool_errors + 1;
        end
    end

    $display("\n===================================================");
    $display("               VERIFICATION SUMMARY                ");
    $display("===================================================");
    $display(" CONVOLUTION ERRORS : %0d / 196", conv_errors);
    $display(" RELU ERRORS        : %0d / 196", relu_errors);
    $display(" POOLING ERRORS     : %0d / 49", pool_errors);
        
    if (conv_errors == 0 && relu_errors == 0 && pool_errors == 0)
        $display("\n    STATUS: [ SUCCESS! ALL CLEAR ]");
    else
        $display("\n    STATUS: [ FAILED! CHECK MODULES ]");
    $display("===================================================\n");
    $finish;
end

always @(posedge clk) begin
    if (wr_valid) begin
        if (conv_sum !== exp_conv[conv_idx]) begin
            $display("  [CONV ERROR] Window %0d: Expected = %0d, Got = %0d", conv_idx, exp_conv[conv_idx], conv_sum);
            conv_errors = conv_errors + 1;
        end
           
        if (final_sum !== exp_relu[conv_idx]) begin
            $display("  [RELU ERROR] Window %0d: Expected = %0d, Got = %0d", conv_idx, exp_relu[conv_idx], final_sum);
            relu_errors = relu_errors + 1;
        end
            
        conv_idx = conv_idx + 1;
    end
end

initial begin
    #17500;
    $finish;
end

initial begin
    $dumpfile("system_verification.vcd");
    $dumpvars(0, system_verification_tb);
end
endmodule