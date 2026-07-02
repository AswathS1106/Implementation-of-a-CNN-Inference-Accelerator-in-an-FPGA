`timescale 1ns/1ps

module mac(
    input clk,
    input rst,
    input clear,

    input signed [15:0] pixel,
    input signed [15:0] weight,

    input valid_in,

    output wire signed [35:0] sum
);
    
reg signed [35:0] sum_reg;
assign sum = sum_reg;

initial begin
    sum_reg = 'd0;
end

always @(posedge clk) begin

    if (rst || clear) sum_reg <= 'd0;

    else if (valid_in) sum_reg <= sum_reg + pixel*weight;
end
endmodule

module mac_int (
    output reg signed [35:0] conv_sum,//Sum goes to Relu
    output reg next_win_req,//Signal to Win. Gen. for new window. Current window consumed
    output reg wr_valid,//Signal saying valid data sent to feature matrix memory

    input clk,
    input rst,

    input wire signed [15:0] bias,
    input wire [16*9-1:0] weights,//Follows Q8.7 fixed point signed arithmatic
    input [16*9-1:0] pixel_win,//pixel window from the win. gen.
    input win_valid//signal saying window is valid and can be used
);

    integer i;

    wire signed [35:0] mac0_sum;
    reg signed [15:0] mac0_pixel;
    reg signed [15:0] mac0_weight;
    reg mac0_valid_in;

    wire signed [35:0] mac1_sum;
    reg signed [15:0] mac1_pixel;
    reg signed [15:0] mac1_weight;
    reg mac1_valid_in;
    
    wire signed [35:0] mac2_sum;
    reg signed [15:0] mac2_pixel;
    reg signed [15:0] mac2_weight;
    reg mac2_valid_in;

    reg clear;

    reg [2:0] state, next_state; 
    localparam IDLE = 'd0;
    localparam LOAD0 = 'd1;
    localparam LOAD1 = 'd2;
    localparam LOAD2 = 'd3;
    localparam WAIT = 'd4;
    localparam SUM = 'd5;
    localparam DONE = 'd6;

    mac mac0 (.clk(clk), .rst(rst), .clear(clear), .pixel(mac0_pixel), .weight(mac0_weight), .valid_in(mac0_valid_in), .sum(mac0_sum));
    mac mac1 (.clk(clk), .rst(rst), .clear(clear), .pixel(mac1_pixel), .weight(mac1_weight), .valid_in(mac1_valid_in), .sum(mac1_sum));
    mac mac2 (.clk(clk), .rst(rst), .clear(clear), .pixel(mac2_pixel), .weight(mac2_weight), .valid_in(mac2_valid_in), .sum(mac2_sum));

    initial begin
        mac0_pixel = 16'sd0;
        mac0_weight = 16'sd0;
        mac0_valid_in = 'd0;
        mac1_pixel = 16'sd0;
        mac1_weight = 16'sd0;
        mac1_valid_in = 'd0;
        mac2_pixel = 16'sd0;
        mac2_weight = 16'sd0;
        mac2_valid_in = 'd0;
        state = 'd0;
        next_state = 'd0;
        clear = 'd0;

    end

    always @(*) begin //Pixel/Weight Mux
        case(state)
        LOAD0:
        begin
            mac0_pixel  = pixel_win[0*16+:16];
            mac0_weight = weights[0*16+:16];

            mac1_pixel  = pixel_win[3*16+:16];
            mac1_weight = weights[3*16+:16];

            mac2_pixel  = pixel_win[6*16+:16];
            mac2_weight = weights[6*16+:16];
        end

        LOAD1:
        begin
            mac0_pixel  = pixel_win[1*16+:16];
            mac0_weight = weights[1*16+:16];

            mac1_pixel  = pixel_win[4*16+:16];
            mac1_weight = weights[4*16+:16];

            mac2_pixel  = pixel_win[7*16+:16];
            mac2_weight = weights[7*16+:16];
        end

        LOAD2:
        begin
            mac0_pixel  = pixel_win[2*16+:16];
            mac0_weight = weights[2*16+:16];

            mac1_pixel  = pixel_win[5*16+:16];
            mac1_weight = weights[5*16+:16];

            mac2_pixel  = pixel_win[8*16+:16];
            mac2_weight = weights[8*16+:16];
        end

        default:
        begin
            mac0_pixel  = 'sd0;
            mac0_weight = 'sd0;

            mac1_pixel  =  'sd0;
            mac1_weight =  'sd0;

            mac2_pixel  =  'sd0;
            mac2_weight =  'sd0;
        end
        endcase
    end

    always @(*) begin //Next State Logic
        next_state = state;
    
        case (state)

            IDLE:
            begin
                if (win_valid) 
                    next_state = LOAD0;

                else next_state = IDLE;
            end 

            LOAD0:
            begin
                next_state = LOAD1;
            end

            LOAD1:
            begin
                next_state = LOAD2;
            end

            LOAD2:
            begin
                next_state = WAIT;
            end

            WAIT:
            begin
                next_state = SUM;
            end

            SUM:
            begin
                next_state = DONE;
            end

            DONE:
            begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin //State updater
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(posedge clk) begin
        if(rst) conv_sum <= 'd0;
        else if (state == SUM) conv_sum <= mac0_sum + mac1_sum + mac2_sum + (bias<<7);
    end

    always @(*) begin //Control signal controller
    
    mac0_valid_in = 0;
    mac1_valid_in = 0;
    mac2_valid_in = 0;

    next_win_req = 0;
    clear = 0;
    wr_valid = 0;
    
    case(state)
        IDLE:
        begin
            if (win_valid) next_win_req = 'd0;
            clear = 'd0;
        end

        LOAD0, LOAD1, LOAD2:
        begin
            mac0_valid_in = 'd1;
            mac1_valid_in = 'd1;
            mac2_valid_in = 'd1;
        end

        DONE:
        begin
            clear = 'd1;
            wr_valid = 'd1;
            next_win_req = 'd1;
        end

        endcase
    end
endmodule