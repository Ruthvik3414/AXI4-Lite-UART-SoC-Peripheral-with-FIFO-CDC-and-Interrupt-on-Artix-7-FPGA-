`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 10:28:27
// Design Name: 
// Module Name: fifo
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

module fifo #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [7:0] data_in,
    output reg [7:0] data_out,
    output full,
    output empty
);

reg [7:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;
reg [ADDR_WIDTH:0] count; // Extra bit to handle DEPTH value

assign full  = (count == DEPTH);
assign empty = (count == 0);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr   <= 0;
        rd_ptr   <= 0;
        count    <= 0;
        data_out <= 0;
    end else begin
        case ({wr_en, rd_en})
            2'b10: begin // Write only
                if (!full) begin
                    mem[wr_ptr] <= data_in;
                    wr_ptr      <= wr_ptr + 1;
                    count       <= count + 1;
                end
            end
            2'b01: begin // Read only
                if (!empty) begin
                    data_out <= mem[rd_ptr];
                    rd_ptr   <= rd_ptr + 1;
                    count    <= count - 1;
                end
            end
            2'b11: begin // Simultaneous Read and Write
                if (full) begin
                    // If full, we can only read
                    data_out <= mem[rd_ptr];
                    rd_ptr   <= rd_ptr + 1;
                    count    <= count - 1;
                end else if (empty) begin
                    // If empty, we can only write
                    mem[wr_ptr] <= data_in;
                    wr_ptr      <= wr_ptr + 1;
                    count       <= count + 1;
                end else begin
                    // Both happen, pointers move, count stays same
                    mem[wr_ptr] <= data_in;
                    data_out    <= mem[rd_ptr];
                    wr_ptr      <= wr_ptr + 1;
                    rd_ptr      <= rd_ptr + 1;
                end
            end
            default: ; // Do nothing
        endcase
    end
end

endmodule