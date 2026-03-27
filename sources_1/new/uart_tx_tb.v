`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 09:38:13
// Design Name: 
// Module Name: uart_tx_tb
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

`timescale 1ns/1ps

module uart_tx_tb;

reg clk = 0;
reg rst = 1;
reg tx_start = 0;
reg [7:0] data_in;
wire tx;
wire tx_busy;

uart_tx uut (
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .data_in(data_in),
    .tx(tx),
    .tx_busy(tx_busy)
);

always #10 clk = ~clk; // 50MHz clock

initial begin
    #100 rst = 0;

    // Send 0x55
    #100;
    data_in = 8'h55;
    tx_start = 1;
    #20 tx_start = 0;

    // Wait until transmission done
    wait(tx_busy == 0);

    // Send 0xAA
    #100;
    data_in = 8'hAA;
    tx_start = 1;
    #20 tx_start = 0;

    wait(tx_busy == 0);

    // Send 0x41
    #100;
    data_in = 8'h41;
    tx_start = 1;
    #20 tx_start = 0;

    #200000;
    $stop;
end
endmodule
