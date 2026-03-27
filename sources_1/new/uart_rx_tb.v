`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 14:18:44
// Design Name: 
// Module Name: uart_rx_tb
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

module uart_rx_tb;
    reg clk = 0;
    reg rst;
    reg rx;
    reg clr_data_ready = 0;
    wire [7:0] data_out;
    wire data_ready;

    uart_rx uut (
        .clk(clk), .rst(rst), .rx(rx), 
        .clr_data_ready(clr_data_ready),
        .data_out(data_out), .data_ready(data_ready)
    );

    always #5 clk = ~clk;

    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 0; #(200); // Start
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i]; #(200);
            end
            rx = 1; #(200); // Stop
        end
    endtask

    initial begin
        rst = 1; rx = 1; #100; rst = 0; #50;

        // Send Byte
        send_uart_byte(8'hAC);

        // Wait for CPU to detect data_ready
        wait(data_ready == 1);
        #20;
        $display("CPU detected data: %h", data_out);
        
        // Simulate CPU Reading (Clearing the flag)
        clr_data_ready = 1;
        #10;
        clr_data_ready = 0;
        $display("Flag cleared.");

        #500;
        $finish;
    end
endmodule