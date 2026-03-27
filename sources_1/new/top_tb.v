`timescale 1ns/1ps

module top_tb;

    // Clock and Reset
    reg clk = 0;
    reg rst;

    // AXI Write Channels (Initialized to 0 to prevent 'X')
    reg [3:0]  AWADDR = 0;
    reg        AWVALID = 0;
    wire       AWREADY;
    reg [31:0] WDATA = 0;
    reg        WVALID = 0;
    wire       WREADY;
    wire       BVALID;
    reg        BREADY = 1;

    // AXI Read Channels (Initialized to 0 to prevent 'X')
    reg [3:0]  ARADDR = 0;
    reg        ARVALID = 0;
    wire       ARREADY;
    wire [31:0] RDATA;
    wire       RVALID;
    reg        RREADY = 1;

    // Physical UART Pins
    wire tx;
    reg  rx = 1; // Idle High
    wire interrupt;

    // Instantiate the Unit Under Test (UUT)
    top_axi_uart uut (
        .clk(clk),
        .rst(rst),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .tx(tx),
        .rx(rx),
        .interrupt(interrupt)
    );

    // Generate 50MHz Clock (20ns period)
    always #10 clk = ~clk; 

    // Task to simulate incoming UART data (Baud 9600)
    task send_uart_rx(input [7:0] data);
        integer i;
        begin
            rx = 0; // Start bit
            #(5208 * 20); 
            for (i=0; i<8; i=i+1) begin
                rx = data[i]; // Data bits (LSB first)
                #(5208 * 20);
            end
            rx = 1; // Stop bit
            #(5208 * 20);
        end
    endtask

    initial begin
        // 1. System Reset
        rst = 1;
        #100 rst = 0;
        #50;
        
        // Enable Interrupt (Write to Control Register)
        @(posedge clk);
        AWADDR = 4'hC; WDATA = 32'h1; AWVALID = 1; WVALID = 1;
        wait(AWREADY && WREADY);
        @(posedge clk);
        AWVALID = 0; WVALID = 0;
        $display("[%t] AXI Write: Interrupt Enabled", $time);

        // 2. AXI Write Operation (TX Test)
        @(posedge clk);
        AWADDR = 4'h0; WDATA = 32'h55; AWVALID = 1; WVALID = 1;
        wait(AWREADY && WREADY);
        @(posedge clk);
        AWVALID = 0; WVALID = 0;
        $display("[%t] AXI Write: 0x55 sent to TX FIFO", $time);

        // 3. Physical UART RX Operation
        $display("[%t] UART RX: Simulating incoming byte 0xBC...", $time);
        send_uart_rx(8'hBC);

        // 4. CRITICAL DELAY
        // We must wait for the UART hardware to finish and sync to AXI domain
        #2000000; 

        // 5. AXI Read Operation (RX Test)
        @(posedge clk);
        ARADDR = 4'h0; 
        ARVALID = 1;
        wait(ARREADY); // Wait for Address Handshake
        @(posedge clk);
        ARVALID = 0;
        
        // Wait for RVALID from the hardware before checking RDATA
        wait(RVALID); 
        $display("[%t] AXI Read SUCCESS: Captured RDATA = 0x%h", $time, RDATA[7:0]);
        @(posedge clk);

        // Let simulation run a bit longer to see the waveform clearly
        #500000; 
        $display("[%t] Simulation complete.", $time);
        $finish;
    end

endmodule