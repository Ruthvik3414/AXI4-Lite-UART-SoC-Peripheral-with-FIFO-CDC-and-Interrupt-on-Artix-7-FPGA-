`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 15:10:10
// Design Name: 
// Module Name: axi_uart_top
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

module axi_uart_top;

    // Parameters
    parameter CLK_PERIOD = 20; // 50MHz
    parameter CLKS_PER_BIT = 50; // Set low for fast simulation

    // Signals
    reg S_AXI_ACLK = 0;
    reg S_AXI_ARESETN;
    
    // Write Channels
    reg [31:0] S_AXI_AWADDR = 0;
    reg S_AXI_AWVALID = 0;
    wire S_AXI_AWREADY;
    reg [31:0] S_AXI_WDATA = 0;
    reg S_AXI_WVALID = 0;
    wire S_AXI_WREADY;
    wire [1:0] S_AXI_BRESP;
    wire S_AXI_BVALID;
    reg S_AXI_BREADY = 0;

    // Read Channels
    reg [31:0] S_AXI_ARADDR = 0;
    reg S_AXI_ARVALID = 0;
    wire S_AXI_ARREADY;
    wire [31:0] S_AXI_RDATA;
    wire [1:0] S_AXI_RRESP;
    wire S_AXI_RVALID;
    reg S_AXI_RREADY = 0;

    wire tx_pin;
    reg  rx_pin = 1;
    wire interrupt;

    // Instantiate UUT
    axi_uart_top #(.CLKS_PER_BIT(CLKS_PER_BIT)) uut (
        .* // Connects all matching port names automatically
    );

    // Clock Generation
    always #(CLK_PERIOD/2) S_AXI_ACLK = ~S_AXI_ACLK;

    // --- AXI Write Task ---
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge S_AXI_ACLK);
            S_AXI_AWADDR  <= addr;
            S_AXI_AWVALID <= 1;
            S_AXI_WDATA   <= data;
            S_AXI_WVALID  <= 1;
            S_AXI_BREADY  <= 1;

            wait(S_AXI_AWREADY && S_AXI_WREADY);
            @(posedge S_AXI_ACLK);
            S_AXI_AWVALID <= 0;
            S_AXI_WVALID  <= 0;
            
            wait(S_AXI_BVALID);
            @(posedge S_AXI_ACLK);
            S_AXI_BREADY  <= 0;
            $display("[WRITE] Addr: %h, Data: %h", addr, data);
        end
    endtask

    // --- AXI Read Task ---
    task axi_read(input [31:0] addr);
        begin
            @(posedge S_AXI_ACLK);
            S_AXI_ARADDR  <= addr;
            S_AXI_ARVALID <= 1;
            S_AXI_RREADY  <= 1;

            wait(S_AXI_ARREADY);
            @(posedge S_AXI_ACLK);
            S_AXI_ARVALID <= 0;

            wait(S_AXI_RVALID);
            @(posedge S_AXI_ACLK);
            S_AXI_RREADY <= 0;
            $display("[READ]  Addr: %h, Data: %h", addr, S_AXI_RDATA);
        end
    endtask

    // --- Main Test Procedure ---
    initial begin
        // Initialize
        S_AXI_ARESETN = 0;
        #100;
        S_AXI_ARESETN = 1;
        #50;

        $display("--- Starting UART TX Test ---");
        // 1. Check Status (Addr 4'h1)
        axi_read(32'h1); 

        // 2. Write 'A' (0x41) to TX Buffer (Addr 4'h0)
        axi_write(32'h0, 32'h41);

        // 3. Write 'B' (0x42)
        axi_write(32'h0, 32'h42);

        // 4. Wait for TX to finish (based on our low CLKS_PER_BIT)
        repeat (CLKS_PER_BIT * 25) @(posedge S_AXI_ACLK);

        $display("--- Starting UART RX Test ---");
        // Simulating an incoming byte (0xA5) manually on rx_pin
        // Start bit
        rx_pin = 0; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        // Data 0xA5 (10100101) -> LSB first: 1, 0, 1, 0, 0, 1, 0, 1
        rx_pin = 1; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 0; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 1; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 0; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 0; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 1; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 0; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        rx_pin = 1; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);
        // Stop bit
        rx_pin = 1; repeat(CLKS_PER_BIT) @(posedge S_AXI_ACLK);

        // 5. Read Status to see if Data Ready bit is high
        axi_read(32'h1);

        // 6. Read the RX Data Register (Addr 4'h4)
        axi_read(32'h4);

        #500;
        $display("Testbench Finished.");
        $finish;
    end

endmodule