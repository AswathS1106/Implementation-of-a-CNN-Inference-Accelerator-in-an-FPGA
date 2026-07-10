`timescale 1ns/1ps

module line_buffer (
    output reg [8*16-1:0] row_a_reg,
    output reg [8*16-1:0] row_b_reg,
    output reg [8*16-1:0] row_c_reg,

    output reg rows_rdy,//Conveys to win. gen. that rows are ready for use
    output reg pixel_req,//Asks for pixels from pixel_rdr

    input wire pixel_valid,//pixel_rdr says that data sent is valid
    input wire [7:0] row_in_stream,//pixel data from the pixel_rdr module
    input wire lb_st,//signal indicating start/initialization of the line buffer
    input wire win_set_done,//signal from win. gen. mod. saying current rows
    
    input wire clk,
    input wire rst 
);

reg [8*16-1:0] row_d_reg;
reg [1:0] state;
reg [1:0] next_state;
reg row_d_valid;
reg row_abc_valid;
reg img_done;
reg [5:0] req_cnt;
reg [5:0] recv_cnt;
reg [3:0] row_cnt;
reg win_done_latch;

integer i;

localparam WAIT_FOR_EVENT = 'd0;// Waits till there is trigger for loading D and/or shifting rows
localparam LOAD_ABC= 'd1;//Starting state where rows A, B, C are loaded
localparam LOAD_D= 'd2;//Row D is loaded as reqd.
localparam SHIFT_ROWS = 'd3;//Shifting of rows to load new rows into A, B, C rows
/*
initial begin
    row_a_reg = 'd0;
    row_b_reg = 'd0;
    row_c_reg = 'd0;
    row_d_reg = 'd0;
    row_abc_valid = 'd0;
    row_d_valid= 'd0;
    recv_cnt = 'd0;
    pixel_req = 'd0;
    rows_rdy = 'd0;
    row_cnt = 'd0;
    req_cnt <= 0;
    win_done_latch = 'd0;
end
*/

always @(posedge clk) begin
    if(rst || state == SHIFT_ROWS) win_done_latch <= 'd0;

    else if (win_set_done) win_done_latch <= 'd1;
end

always @ (posedge clk) begin
    if(rst)
        state <= WAIT_FOR_EVENT;

    else
        state <= next_state;
end

always @(posedge clk) begin
    if(rst) begin
        row_a_reg <= 0;
        row_b_reg <= 0;
        row_c_reg <= 0;
        row_d_reg <= 0;

        req_cnt <= 0;
        recv_cnt <= 0;
        row_cnt <= 0;

        pixel_req <= 0;
        rows_rdy <= 0;

        row_abc_valid <= 0;
        row_d_valid <= 0;

        img_done <= 0;
    end

    else begin
        rows_rdy <= 'd0;
        
        if (lb_st) img_done <= 'd0;

        if (img_done) begin
            row_abc_valid <= 0;
            row_d_valid <= 0;
        end

        else begin
            pixel_req <= 'd0;

            case(state)
            LOAD_ABC:
            begin
                // load rows a, b, c. then make win_gen_st=1 for 1 clk cycle.
                if (req_cnt < 48) begin
                    pixel_req <= 1;
                    req_cnt <= req_cnt + 1;
                end

                else pixel_req <= 0;

                if (pixel_valid && recv_cnt < 48) begin
                    recv_cnt <= recv_cnt + 1;

                    for (i=0; i<15; i=i+1) begin
                        row_a_reg[i*8+:8] <= row_a_reg[(i+1)*8+:8];
                        row_b_reg[i*8+:8] <= row_b_reg[(i+1)*8+:8];
                        row_c_reg[i*8+:8] <= row_c_reg[(i+1)*8+:8];
                    end
                    row_a_reg[8*15+:8] <= row_b_reg[0+:8];
                    row_b_reg[8*15+:8] <= row_c_reg[0+:8];
                    row_c_reg[8*15+:8] <= row_in_stream;

                    if (recv_cnt + 1 == 16*3) begin
                        req_cnt <= 'd0;
                        recv_cnt <= 'd0;
                        rows_rdy <= 'd1;
                        row_abc_valid <= 'd1;
                        row_cnt <= 'd3;
                    end
                end
            end

            LOAD_D:
            begin
                
                row_abc_valid <= 'd0;

                if (req_cnt < 16 && !row_d_valid) begin
                    pixel_req <= 1;
                    req_cnt <= req_cnt + 1;
                end

                else pixel_req <= 0;

                if(pixel_valid && !row_d_valid) begin

                    for (i=0; i<15; i=i+1) begin
                        row_d_reg[i*8+:8] <= row_d_reg[(i+1)*8+:8];
                    end
                    row_d_reg[8*15+:8] <= row_in_stream;
                    
                    recv_cnt <= recv_cnt + 1;

                    if (recv_cnt + 1== 16) begin
                        row_d_valid <= 'd1;
                    end
                end
            end

            SHIFT_ROWS:
            begin
                row_d_valid <= 'd0;
                row_a_reg <= row_b_reg;
                row_b_reg <= row_c_reg;
                row_c_reg <= row_d_reg;
                row_d_reg <= 'd0;
                rows_rdy <= 'd1;
                row_abc_valid <= 'd1;
                row_cnt <= row_cnt + 1;

                
                req_cnt <= 'd0;
                recv_cnt <= 'd0;

                if (row_cnt == 15) img_done <= 'd1;
            end

            default:; //do nothing
            endcase
        end
    end

end

always @(*) begin
    next_state = state;

    case(state)
        WAIT_FOR_EVENT:
        begin
            if(img_done)
                next_state = WAIT_FOR_EVENT;

            else if(lb_st)
                next_state = LOAD_ABC;

            else if (win_set_done)
                next_state = SHIFT_ROWS;
        end

        LOAD_ABC:
        begin
            if (img_done)
                next_state = WAIT_FOR_EVENT;

            else if (row_abc_valid)
                next_state = LOAD_D;
            
            else
                next_state = LOAD_ABC;
        end

        LOAD_D:
        begin
            if (img_done)
                next_state = WAIT_FOR_EVENT;
            
            else if (row_d_valid && (win_set_done||win_done_latch))
                next_state = SHIFT_ROWS;

            else next_state = LOAD_D;
        end

        SHIFT_ROWS:
        begin
            if (img_done)
                next_state = WAIT_FOR_EVENT;

            else next_state = LOAD_D;
        end

        default:
        next_state = WAIT_FOR_EVENT;
    endcase
end
endmodule
