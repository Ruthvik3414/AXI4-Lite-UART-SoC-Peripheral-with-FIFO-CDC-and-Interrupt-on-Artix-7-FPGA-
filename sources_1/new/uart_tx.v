`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 09:34:22
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx #(
    parameter CLKS_PER_BIT = 5208
)(
    input clk,
    input rst,
    input tx_start,
    input [7:0] data_in,
    output reg tx,
    output reg tx_busy
);

    reg [12:0] clk_count;
    reg [3:0]  bit_index;
    reg [7:0]  tx_data_buffer;
    reg [1:0]  state;

    localparam IDLE  = 2'b00, START = 2'b01, DATA  = 2'b10, STOP  = 2'b11;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case(state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= 0;
                    if (tx_start) begin
                        tx_data_buffer <= data_in;
                        tx_busy <= 1'b1;
                        state <= START;
                    end
                end

                START: begin
                    tx <= 1'b0; // Start Bit
                    if (clk_count < CLKS_PER_BIT-1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        state <= DATA;
                        bit_index <= 0;
                    end
                end

                DATA: begin
                    tx <= tx_data_buffer[bit_index];
                    if (clk_count < CLKS_PER_BIT-1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        if (bit_index < 7)
                            bit_index <= bit_index + 1;
                        else
                            state <= STOP;
                    end
                end

                STOP: begin
                    tx <= 1'b1; // Stop Bit
                    if (clk_count < CLKS_PER_BIT-1)
                        clk_count <= clk_count + 1;
                    else begin
                        tx_busy <= 1'b0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule