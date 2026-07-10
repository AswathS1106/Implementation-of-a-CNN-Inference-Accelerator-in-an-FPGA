`timescale 1ns/1ps

module mac(
    input clk,
    input rst,
    input clear,

    input [7:0] pixel,
    input signed [12-1:0] weight,

    input valid_in,

    output wire signed [23:0] sum
);
    
reg signed [23:0] sum_reg;
assign sum = sum_reg;

wire signed [23:0] p_ext = {16'd0, pixel};
wire signed [23:0] w_ext = {{12{weight[11]}}, weight};


initial begin
    sum_reg = 'd0;
end

always @(posedge clk) begin

    if (rst || clear) sum_reg <= 'd0;

    else if (valid_in) sum_reg <= sum_reg + (p_ext * w_ext);
end
endmodule

module mac_int (
    output reg signed [23:0] conv_sum,//Sum goes to Relu
    output reg next_win_req,//Signal to Win. Gen. for new window. Current window consumed
    output reg wr_valid,//Signal saying valid data sent to feature matrix memory

    input clk,
    input rst,

    input wire signed [12-1:0] bias,
    input wire [12*9-1:0] weights,//Follows Q3.8 fixed point signed arithmatic
    input [8*9-1:0] pixel_win,//pixel window from the win. gen.
    input win_valid//signal saying window is valid and can be used
);


    wire signed [23:0] mac0_sum;
    reg [7:0] mac0_pixel;
    reg signed [12-1:0] mac0_weight;
    reg mac0_valid_in;

    wire signed [23:0] mac1_sum;
    reg [7:0] mac1_pixel;
    reg signed [12-1:0] mac1_weight;
    reg mac1_valid_in;
    
    wire signed [23:0] mac2_sum;
    reg [7:0] mac2_pixel;
    reg signed [12-1:0] mac2_weight;
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
        mac0_pixel = 'd0;
        mac0_weight = 'sd0;
        mac0_valid_in = 'd0;
        mac1_pixel = 'd0;
        mac1_weight = 'sd0;
        mac1_valid_in = 'd0;
        mac2_pixel = 'd0;
        mac2_weight = 'sd0;
        mac2_valid_in = 'd0;
        state = 'd0;
        next_state = 'd0;
        clear = 'd0;

    end

    always @(*) begin //Pixel/Weight Mux
        case(state)
        LOAD0:
        begin
            mac0_pixel  = pixel_win[0*8+:8];
            mac0_weight = $signed(weights[0*12+:12]);

            mac1_pixel  = pixel_win[3*8+:8];
            mac1_weight = $signed(weights[3*12+:12]);

            mac2_pixel  = pixel_win[6*8+:8];
            mac2_weight = $signed(weights[6*12+:12]);
        end

        LOAD1:
        begin
            mac0_pixel  = pixel_win[1*8+:8];
            mac0_weight = $signed(weights[1*12+:12]);

            mac1_pixel  = pixel_win[4*8+:8];
            mac1_weight = $signed(weights[4*12+:12]);

            mac2_pixel  = pixel_win[7*8+:8];
            mac2_weight = $signed(weights[7*12+:12]);
        end

        LOAD2:
        begin
            mac0_pixel  = pixel_win[2*8+:8];
            mac0_weight = $signed(weights[2*12+:12]);

            mac1_pixel  = pixel_win[5*8+:8];
            mac1_weight = $signed(weights[5*12+:12]);

            mac2_pixel  = pixel_win[8*8+:8];
            mac2_weight = $signed(weights[8*12+:12]);
        end

        default:
        begin
            mac0_pixel  = 'd0;
            mac0_weight = 'sd0;

            mac1_pixel  =  'd0;
            mac1_weight =  'sd0;

            mac2_pixel  =  'd0;
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
                next_state = LOAD1;

            LOAD1:
                next_state = LOAD2;

            LOAD2:
                next_state = WAIT;

            WAIT:
                next_state = SUM;

            SUM:
                next_state = DONE;

            DONE:
                next_state = IDLE;

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
        else if (state == SUM) conv_sum <= mac0_sum + mac1_sum + mac2_sum + bias;
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

        default:; //does nothing

        endcase
    end
endmodule
