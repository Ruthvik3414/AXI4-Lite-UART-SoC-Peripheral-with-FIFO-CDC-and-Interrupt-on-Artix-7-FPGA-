`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 13:50:37
// Design Name: 
// Module Name: cdc_sync
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

module cdc_sync(
    input clk_dst,
    input rst,
    input signal_src,
    output reg signal_dst,
    output pulse_dst // Optional: Detects the rising edge
);

reg sync_ff1;

always @(posedge clk_dst or posedge rst) begin
    if (rst) begin
        sync_ff1   <= 0;
        signal_dst <= 0;
    end else begin
        sync_ff1   <= signal_src;
        signal_dst <= sync_ff1;
    end
end

// Rising Edge Detector: High for only 1 clk_dst cycle
assign pulse_dst = sync_ff1 & ~signal_dst;

endmodule