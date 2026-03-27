module top_axi_uart(
    input clk,
    input rst,

    // AXI-Lite Interface
    input [3:0]   AWADDR,
    input         AWVALID,
    output        AWREADY,
    input [31:0]  WDATA,
    input         WVALID,
    output        WREADY,
    output        BVALID,
    input         BREADY,

    input [3:0]   ARADDR,
    input         ARVALID,
    output        ARREADY,
    output [31:0] RDATA,
    output        RVALID,
    input         RREADY,

    // UART Physical Interface
    output        tx,
    input         rx,
    
    // Optional: Interrupt signal to CPU
    output        interrupt
);

// --- Internal Wires ---
wire wr_en, rd_en;
wire [3:0] addr;
wire [31:0] wdata, rdata_from_regs;

// TX Path Wires
wire [7:0] tx_data_to_fifo;
wire       tx_fifo_wr_en;
wire       tx_fifo_full, tx_fifo_empty;
wire [7:0] tx_data_to_uart;
reg        tx_fifo_rd_en;
wire       uart_tx_busy;

// RX Path Wires
wire [7:0] rx_data_from_uart;
wire       rx_ready_raw;
wire       rx_pulse_sync;
wire [7:0] rx_data_from_fifo;
wire       rx_fifo_full, rx_fifo_empty;
wire       clr_rx_fifo_rd;

// 1. AXI-Lite Slave Interface
axi_lite_slave axi_inst (
    .clk(clk), .rst(rst),
    .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
    .WDATA(WDATA),   .WVALID(WVALID),   .WREADY(WREADY),
    .BVALID(BVALID), .BREADY(BREADY),   .BRESP(), 
    .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
    .RDATA(RDATA),   .RVALID(RVALID),   .RREADY(RREADY), .RRESP(),
    .wr_en(wr_en),   .rd_en(rd_en),     .addr(addr), 
    .wdata(wdata),   .rdata(rdata_from_regs)
);

// 2. Register Bank
reg_bank regs_inst (
    .clk(clk), .rst(rst),
    .wr_en(wr_en), .rd_en(rd_en),
    .addr(addr), .wdata(wdata), .rdata(rdata_from_regs),
    
    // TX Connections
    .tx_data(tx_data_to_fifo),
    .tx_write(tx_fifo_wr_en),
    .fifo_full(tx_fifo_full),
    .fifo_empty(tx_fifo_empty),

    // RX Connections
    .rx_data(rx_data_from_fifo),
    .rx_data_ready(!rx_fifo_empty), // Reg bank sees data ready if FIFO isn't empty
    .clr_rx_data_ready(clr_rx_fifo_rd),
    
    .interrupt(interrupt)
);

// 3. TX FIFO (AXI -> UART)
fifo #(.DEPTH(16), .ADDR_WIDTH(4)) tx_fifo (
    .clk(clk), .rst(rst),
    .wr_en(tx_fifo_wr_en),
    .rd_en(tx_fifo_rd_en),
    .data_in(tx_data_to_fifo),
    .data_out(tx_data_to_uart),
    .full(tx_fifo_full), .empty(tx_fifo_empty)
);

// 4. TX Control Logic (Single-cycle pulse to start UART)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_fifo_rd_en <= 0;
    end else begin
        // If there's data and UART is ready, pop a byte and start transmission
        if (!tx_fifo_empty && !uart_tx_busy && !tx_fifo_rd_en)
            tx_fifo_rd_en <= 1;
        else
            tx_fifo_rd_en <= 0;
    end
end

// 5. UART TX Physical Layer
uart_tx #(.CLKS_PER_BIT(5208)) uart_tx_module (
    .clk(clk), .rst(rst),
    .tx_start(tx_fifo_rd_en),
    .data_in(tx_data_to_uart),
    .tx(tx),
    .tx_busy(uart_tx_busy)
);

// 6. UART RX Physical Layer
uart_rx #(.CLKS_PER_BIT(5208)) uart_rx_module (
    .clk(clk), .rst(rst),
    .rx(rx),
    .clr_data_ready(1'b0), // Not used since we use FIFO
    .data_out(rx_data_from_uart),
    .data_ready(rx_ready_raw)
);

// 7. CDC for RX Data Ready (Synchronizing asynchronous RX pulse to AXI clock)
cdc_sync rx_cdc (
    .clk_dst(clk), .rst(rst),
    .signal_src(rx_ready_raw),
    .signal_dst(), // Level output not needed
    .pulse_dst(rx_pulse_sync) // Pulse output to trigger FIFO write
);

// 8. RX FIFO (UART -> AXI)
fifo #(.DEPTH(16), .ADDR_WIDTH(4)) rx_fifo (
    .clk(clk), .rst(rst),
    .wr_en(rx_pulse_sync),
    .rd_en(clr_rx_fifo_rd), // Reg bank triggers this when CPU reads RX register
    .data_in(rx_data_from_uart),
    .data_out(rx_data_from_fifo),
    .full(rx_fifo_full), .empty(rx_fifo_empty)
);

endmodule