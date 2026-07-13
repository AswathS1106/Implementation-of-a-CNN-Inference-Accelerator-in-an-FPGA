`timescale 1ns/1ps
`include "window_gen.v"
`include "line_buffer.v"
`include "pixel_rdr.v"
`include "image_memory.v"
`include "mac3.v"
`include "ReLU_func.v"
`include "feature_mat_mem.v"
`include "pool_addr_gen.v"
`include "max_pool.v"
`include "proc_img_mem.v"
`include "neuron.v"
`include "arg_max_func.v"

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
wire win_set_done;
wire win_valid;
wire next_win_req;

wire signed [12-1:0] bias0;
wire [(9*12)-1:0] weights0;
wire signed [12-1:0] bias1;
wire [(9*12)-1:0] weights1;

wire signed [23:0] conv_sum0;
wire wr_valid_0;
wire signed [23:0] conv_sum1;
wire wr_valid_1;

wire signed [23:0] final_sum0;
wire [7:0] ft_rd_addr0;
wire ft_rd_valid0;
wire signed [23:0] ft_rd_data0;
wire ft_mem_full0;
wire signed [23:0] final_sum1;
wire [7:0] ft_rd_addr1;
wire ft_rd_valid1;
wire signed [23:0] ft_rd_data1;
wire ft_mem_full1;

wire pool_done0;
wire ft_rd_data_valid0;
wire pool_done1;
wire ft_rd_data_valid1;

wire [23:0] max_out0;
wire max_valid0;
wire [23:0] max_out1;
wire max_valid1;

wire [23:0] proc_img_rd_data0;
wire proc_img_mem_full0;
wire [23:0] proc_img_rd_data1;
wire proc_img_mem_full1;

reg signed [23:0] exp_conv0 [0:195];
reg signed [23:0] exp_relu0 [0:195];
reg signed [23:0] exp_pool0 [0:48];
integer conv_idx0;
reg signed [23:0] exp_conv1 [0:195];
reg signed [23:0] exp_relu1 [0:195];
reg signed [23:0] exp_pool1 [0:48];
integer conv_idx1;
integer conv_errors0, relu_errors0, pool_errors0;
integer conv_errors1, relu_errors1, pool_errors1;

wire nxt_rd_req, nxt_rd_req0, nxt_rd_req1, nxt_rd_req2;
assign nxt_rd_req = nxt_rd_req0 && nxt_rd_req1 && nxt_rd_req2;

wire nxt_rd_req_gated0;
wire nxt_rd_req_gated1;
assign nxt_rd_req_gated0 = nxt_rd_req && (tb_neuron_0.req_cnt <= 49);
assign nxt_rd_req_gated1 = nxt_rd_req && (tb_neuron_0.req_cnt > 49);

image_memory #(.FILE_NAME("../Complete Processor/mem_files/image.mem")) tb_mem (.clk(clk), .rst(rst), .rd_addr(img_rd_addr), .pixel_out(pixel_in));
pixel_rdr tb_rdr (.pixel_out(row_in_stream), .pixel_valid(pixel_valid), .rd_addr(img_rd_addr), .clk(clk), .rst(rst),
                    .pixel_in(pixel_in), .pixel_req(pixel_req));
line_buffer tb_lb (.clk(clk), .rst(rst), .lb_st(lb_st), .row_in_stream(row_in_stream),
                    .pixel_valid(pixel_valid), .win_set_done(win_set_done),
                    .row_a_reg(row_a_reg), .row_b_reg(row_b_reg), .row_c_reg(row_c_reg),
                    .rows_rdy(rows_rdy), .pixel_req(pixel_req));
window_gen tb_win_gen (.clk(clk), .rst(rst), .row_a_reg(row_a_reg), .row_b_reg(row_b_reg), .row_c_reg(row_c_reg),
                        .rows_rdy(rows_rdy), .next_win_req(next_win_req),
                        .window(window), .win_set_done(win_set_done), .win_valid(win_valid));
                        
mac_int #(.WT_FILE_NAME("../Complete Processor/mem_files/weights_c0.mem"), .BIAS_FILE_NAME("../Complete Processor/mem_files/bias_c0.mem")) tb_mac_0 (.clk(clk), .rst(rst), 
                    .pixel_win(window), .win_valid(win_valid),
                    .conv_sum(conv_sum0), .next_win_req(next_win_req), .wr_valid(wr_valid_0));
ReLU_func tb_ReLU_0 (.in(conv_sum0), .out(final_sum0));

feature_mat_mem tb_feature_mat_mem_0 (.clk(clk), .rst(rst), .wr_valid(wr_valid_0), .wr_data(final_sum0),
                                        .rd_addr(ft_rd_addr0), .rd_valid(ft_rd_valid0), .rd_data_valid(ft_rd_data_valid0),
                                        .rd_data(ft_rd_data0), .mem_full(ft_mem_full0));
pool_addr_gen tb_pool_addr_gen_0 (.clk(clk), .rst(rst), .ft_mem_full(ft_mem_full0),
                                .rd_addr(ft_rd_addr0), .rd_valid(ft_rd_valid0), .pool_done(pool_done0));
max_pool tb_max_pool_0 (.clk(clk), .rst(rst), .feature_data(ft_rd_data0), .feature_valid(ft_rd_data_valid0),
                        .max_out(max_out0), .max_valid(max_valid0));
proc_img_mem tb_proc_img_mem_0 (.clk(clk), .rst(rst),
                                .wr_data(max_out0), .wr_valid(max_valid0),
                                .rd_data(proc_img_rd_data0), .mem_full(proc_img_mem_full0), 
                                .nxt_rd_req(nxt_rd_req_gated0));


mac_int #(.WT_FILE_NAME("../Complete Processor/mem_files/weights_c1.mem"), .BIAS_FILE_NAME("../Complete Processor/mem_files/bias_c1.mem")) tb_mac_1 (.clk(clk), .rst(rst),
                    .pixel_win(window), .win_valid(win_valid),
                    .conv_sum(conv_sum1), .next_win_req(next_win_req), .wr_valid(wr_valid_1));
ReLU_func tb_ReLU_1 (.in(conv_sum1), .out(final_sum1));

feature_mat_mem tb_feature_mat_mem_1 (.clk(clk), .rst(rst), .wr_valid(wr_valid_1), .wr_data(final_sum1),
                                        .rd_addr(ft_rd_addr1), .rd_valid(ft_rd_valid1), .rd_data_valid(ft_rd_data_valid1),
                                        .rd_data(ft_rd_data1), .mem_full(ft_mem_full1));
pool_addr_gen tb_pool_addr_gen_1 (.clk(clk), .rst(rst), .ft_mem_full(ft_mem_full1),
                                .rd_addr(ft_rd_addr1), .rd_valid(ft_rd_valid1), .pool_done(pool_done1));
max_pool tb_max_pool_1 (.clk(clk), .rst(rst), .feature_data(ft_rd_data1), .feature_valid(ft_rd_data_valid1),
                        .max_out(max_out1), .max_valid(max_valid1));
proc_img_mem tb_proc_img_mem_1 (.clk(clk), .rst(rst),
                                .wr_data(max_out1), .wr_valid(max_valid1),
                                .rd_data(proc_img_rd_data1), .mem_full(proc_img_mem_full1), 
                                .nxt_rd_req(nxt_rd_req_gated1));

wire signed [43:0] nop0;
wire nop0_valid;
wire signed [43:0] nop1;
wire nop1_valid;
wire signed [43:0] nop2;
wire nop2_valid;

reg signed [43:0] exp_neu0 [0:0];
reg signed [43:0] exp_neu1 [0:0];
reg signed [43:0] exp_neu2 [0:0];

wire [23:0] neuron_input_mux;
assign neuron_input_mux = (tb_neuron_0.wt_addr < 49) ? proc_img_rd_data0 : proc_img_rd_data1;

neuron #(.WT_FILE_NAME("../Complete Processor/mem_files/weights_n0.mem"), .BIAS_FILE_NAME("../Complete Processor/mem_files/bias_n0.mem")) tb_neuron_0 (.clk(clk), .rst(rst),
                        .neuron_output(nop0), .output_valid(nop0_valid), .nxt_rd_req(nxt_rd_req0), 
                        .neuron_input(neuron_input_mux),
                        .start_mac((proc_img_mem_full0 && proc_img_mem_full1)));
neuron #(.WT_FILE_NAME("../Complete Processor/mem_files/weights_n1.mem"), .BIAS_FILE_NAME("../Complete Processor/mem_files/bias_n1.mem")) tb_neuron_1 (.clk(clk), .rst(rst),
                        .neuron_output(nop1), .output_valid(nop1_valid), .nxt_rd_req(nxt_rd_req1), 
                        .neuron_input(neuron_input_mux),
                        .start_mac((proc_img_mem_full0 && proc_img_mem_full1)));
neuron #(.WT_FILE_NAME("../Complete Processor/mem_files/weights_n2.mem"), .BIAS_FILE_NAME("../Complete Processor/mem_files/bias_n2.mem")) tb_neuron_2 (.clk(clk), .rst(rst),
                        .neuron_output(nop2), .output_valid(nop2_valid), .nxt_rd_req(nxt_rd_req2), 
                        .neuron_input(neuron_input_mux),
                        .start_mac((proc_img_mem_full0 && proc_img_mem_full1)));
                        
arg_max_func arg_max_0 (.score1(nop0), .score1_valid(nop0_valid),
                        .score2(nop1), .score2_valid(nop1_valid),
                        .score3(nop2), .score3_valid(nop2_valid), .rst(rst), .clk(clk));

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $readmemb("../Complete Processor/mem_files/conv0_expected.mem", exp_conv0);
    $readmemb("../Complete Processor/mem_files/relu0_expected.mem", exp_relu0);
    $readmemb("../Complete Processor/mem_files/pool0_expected.mem", exp_pool0);
    $readmemb("../Complete Processor/mem_files/conv1_expected.mem", exp_conv1);
    $readmemb("../Complete Processor/mem_files/relu1_expected.mem", exp_relu1);
    $readmemb("../Complete Processor/mem_files/pool1_expected.mem", exp_pool1);
    
    conv_idx0 = 0; conv_errors0 = 0; relu_errors0 = 0; pool_errors0 = 0;
    conv_idx1 = 0; conv_errors1 = 0; relu_errors1 = 0; pool_errors1 = 0;

    rst = 1;
    lb_st = 0;
    #25; rst = 'd0;
    #20;
    lb_st = 1;
    #10; lb_st = 0;

    $display("-----------------------------------------------------------");
    $display("   STARTING FULL PIPELINE HARDWARE VERIFICATION            ");
    $display("-----------------------------------------------------------");

    wait(proc_img_mem_full0 == 1'b1 && proc_img_mem_full1 == 1'b1);
    #50; 
        
    $display("\nChecking Final Max-Pool Matrix (7x7) against Expected for PATH 1...");
    for (integer i = 0; i < 49; i = i + 1) begin
        if (tb_proc_img_mem_0.proc_img_arr[i] !== exp_pool0[i]) begin
            $display("  [POOL ERROR for PATH 1] Index %0d: Expected = %0d, Got = %0d", i, exp_pool0[i], tb_proc_img_mem_0.proc_img_arr[i]);
            pool_errors0 = pool_errors0 + 1;
        end
    end

    $display("\nChecking Final Max-Pool Matrix (7x7) against Expected for PATH 2...");
    for (integer j = 0; j < 49; j = j + 1) begin
        if (tb_proc_img_mem_1.proc_img_arr[j] !== exp_pool1[j]) begin
            $display("  [POOL ERROR for PATH 2] Index %0d: Expected = %0d, Got = %0d", j, exp_pool1[j], tb_proc_img_mem_1.proc_img_arr[j]);
            pool_errors1 = pool_errors1 + 1;
        end
    end

    $display("\n===================================================");
    $display("               VERIFICATION SUMMARY                ");
    $display("===================================================");
    $display(" PATH 1 -> CONV ERRORS: %0d/196 | ReLU ERRORS: %0d/196 | POOL ERRORS: %0d/49", conv_errors0, relu_errors0, pool_errors0);
    $display(" PATH 2 -> CONV ERRORS: %0d/196 | ReLU ERRORS: %0d/196 | POOL ERRORS: %0d/49", conv_errors1, relu_errors1, pool_errors1);
    
    if (conv_errors0 == 0 &&  pool_errors0 == 0 && 
        conv_errors1 == 0 && pool_errors1 == 0) begin
        $display("\n    STATUS: [ SUCCESS! ALL CLEAR FOR BOTH PATHS ]");
    end
    
    else begin
        $display("\n    STATUS: [ FAILED! CHECK MODULES ]");
    end
    
    $display("=======================================================\n");

    $display("Waiting for neural network classification...");

    $readmemb("../Complete Processor/mem_files/neuron0_expected.mem", exp_neu0);
    $readmemb("../Complete Processor/mem_files/neuron1_expected.mem", exp_neu1);
    $readmemb("../Complete Processor/mem_files/neuron2_expected.mem", exp_neu2);
    wait(arg_max_0.score1_valid && arg_max_0.score2_valid && arg_max_0.score3_valid);
    if (nop0 == exp_neu0[0]) $display("Neuron 1 output valid.");
    else $display("Neuron 1 Output is INVALID.");
    if (nop1 == exp_neu1[0]) $display("Neuron 2 output valid.");
    else $display("Neuron 2 Output is INVALID.");
    if (nop2 == exp_neu2[0]) $display("Neuron 3 output valid.");
    else $display("Neuron 3 Output is INVALID.");
    #25; 
    
    $display("Simulation complete.");
    $finish;
end

always @(posedge clk) begin
    if (wr_valid_0) begin
        if (conv_sum0 !== exp_conv0[conv_idx0]) begin
            $display("  [CONV ERROR for Path 1] Window %0d: Expected = %0d, Got = %0d", conv_idx0, exp_conv0[conv_idx0], conv_sum0);
            conv_errors0 = conv_errors0 + 1;
        end
           
        if (final_sum0 !== exp_relu0[conv_idx0]) begin
            $display("  [RELU ERROR] Window %0d: Expected = %0d, Got = %0d", conv_idx0, exp_relu0[conv_idx0], final_sum0);
            relu_errors0 = relu_errors0 + 1;
        end
        
        conv_idx0 = conv_idx0 + 1;
    end

    if (wr_valid_1) begin
        if (conv_sum1 !== exp_conv1[conv_idx1]) begin
            $display("  [CONV ERROR for Path 2] Window %0d: Expected = %0d, Got = %0d", conv_idx1, exp_conv1[conv_idx1], conv_sum1);
            conv_errors1 = conv_errors1 + 1;
        end

        if (final_sum1 !== exp_relu1[conv_idx1]) begin
            $display("  [RELU ERROR] Window %0d: Expected = %0d, Got = %0d", conv_idx1, exp_relu1[conv_idx1], final_sum1);
            relu_errors1 = relu_errors1 + 1;
        end

        conv_idx1 = conv_idx1 + 1;
    end
end

initial begin
    #25000;
    $display("TIMEOUT REACHED: Simulation forcibly stopped.");
    $finish;
end

initial begin
    $dumpfile("system_verification.vcd");
    $dumpvars(0, system_verification_tb);
end
endmodule