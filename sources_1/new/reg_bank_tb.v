`timescale 1ns/1ps

module reg_bank_tb;
    reg clk = 0;
    reg rst;
    reg rx;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [3:0] addr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;
    wire interrupt; // The new signal to monitor

    wire [7:0] rx_data_wire;
    wire rx_ready_wire;
    wire clr_rx_wire;

    // Instantiate UART RX
    uart_rx #(.CLKS_PER_BIT(20)) rx_inst (
        .clk(clk), .rst(rst), .rx(rx),
        .clr_data_ready(clr_rx_wire),
        .data_out(rx_data_wire), .data_ready(rx_ready_wire)
    );

    // Instantiate Reg Bank
    reg_bank uut (
        .clk(clk), .rst(rst),
        .wr_en(wr_en), .rd_en(rd_en),
        .addr(addr), .wdata(wdata), .rdata(rdata),
        .fifo_full(1'b0), .fifo_empty(1'b0), // Set empty to 0 so it doesn't mask RX interrupt
        .rx_data(rx_data_wire),
        .rx_data_ready(rx_ready_wire),
        .clr_rx_data_ready(clr_rx_wire),
        .interrupt(interrupt)
    );

    always #5 clk = ~clk;

    task send_byte(input [7:0] data);
        integer i;
        begin
            rx = 0; #(200);
            for (i=0; i<8; i=i+1) begin
                rx = data[i]; #(200);
            end
            rx = 1; #(200);
        end
    endtask

    initial begin
        // Reset
        rst = 1; rx = 1; #100; rst = 0; #50;

        // --- TEST 1: Interrupt Disabled ---
        $display("Testing: Byte sent with Interrupts DISABLED");
        wr_en = 1; addr = 4'hC; wdata = 32'h0; // Ensure IE is 0
        #10; wr_en = 0;
        
        send_byte(8'hAA);
        #50;
        if (interrupt == 0) $display("PASS: Interrupt stayed low.");
        else $display("FAIL: Interrupt fired while disabled!");

        // Clear the data to reset for next test
        rd_en = 1; addr = 4'h4; #10; rd_en = 0; #20;

        // --- TEST 2: Interrupt Enabled ---
        $display("Testing: Byte sent with Interrupts ENABLED");
        wr_en = 1; addr = 4'hC; wdata = 32'h1; // Set IE to 1
        #10; wr_en = 0;

        send_byte(8'hBB);
        #20;
        if (interrupt == 1) $display("PASS: Interrupt fired correctly!");
        else $display("FAIL: Interrupt failed to fire!");

        #500;
        $finish;
    end
endmodule