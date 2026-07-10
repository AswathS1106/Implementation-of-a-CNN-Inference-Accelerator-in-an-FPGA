`timescale 1ns/1ps

module neuron #(parameter WT_FILE_NAME = "weights.mem", parameter BIAS_FILE_NAME = "bias.mem") (
    output reg signed [43:0] neuron_output,
    output reg output_valid,
    output reg nxt_rd_req, // data request receipts sent to memory module

    input clk,
    input rst,

    input signed [23:0] neuron_input,
    input start_mac //connects to mem_full in memory module
);

reg signed [12-1:0] weights [0:7*7*2-1];
reg signed [12-1:0] bias [0:0];
reg signed [43:0] acc;
reg clear;

reg [6:0] wt_addr;
reg [6:0] req_cnt; // Counts exactly how many read requests have been emitted
reg mac_en;

initial begin
    $readmemb(WT_FILE_NAME, weights);
    $readmemb(BIAS_FILE_NAME, bias);
    acc = $signed(bias[0]) << 8;
    nxt_rd_req = 'd0;
end

always @(posedge clk) begin
    if(rst | clear) begin
        acc <= $signed(bias[0]) << 8;
        nxt_rd_req <= 'd0;
        clear <= 'd0;
        neuron_output <= 'sd0;
        output_valid <= 'd0;
        wt_addr <= 'd0;
        req_cnt <= 'd0;
        mac_en <= 'd0;
    end
    else begin
        // Emitting 98 requests
        if (start_mac && (req_cnt < 'd98)) begin 
            nxt_rd_req <= 1'b1;
            req_cnt <= req_cnt + 1'b1;
        end else begin
            nxt_rd_req <= 1'b0;
        end

        mac_en <= nxt_rd_req; 

        if (mac_en) begin
            if (wt_addr == 7*7*2 - 1) begin // 97
                // Assign final calculation to neuron_output
                neuron_output <= acc + ($signed(weights[wt_addr]) * $signed(neuron_input));
                output_valid  <= 1'b1;
                clear         <= 1'b1; // This resets everything on the NEXT cycle
            end else begin
                acc     <= acc + ($signed(weights[wt_addr]) * $signed(neuron_input));
                wt_addr <= wt_addr + 1'b1;
            end
        end
    end
end
endmodule
