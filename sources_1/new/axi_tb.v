`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 11:11:52
// Design Name: 
// Module Name: axi_tb
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

module axi_tb;

reg clk = 0;
reg rst;

reg [3:0] AWADDR;
reg AWVALID;
wire AWREADY;

reg [31:0] WDATA;
reg WVALID;
wire WREADY;

wire BVALID;
reg BREADY;

reg [3:0] ARADDR;
reg ARVALID;
wire ARREADY;

wire [31:0] RDATA;
wire RVALID;
reg RREADY;

wire wr_en;
wire rd_en;
wire [3:0] addr;
wire [31:0] wdata;

reg [31:0] rdata = 32'h12345678;

axi_lite_slave uut(
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
    .wr_en(wr_en),
    .rd_en(rd_en),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata)
);

always #5 clk = ~clk;

initial begin
    rst = 1;
    #20 rst = 0;

    // Write transaction
    @(posedge clk);
    AWADDR = 4'h0;
    WDATA = 32'hAA;
    AWVALID = 1;
    WVALID = 1;
    BREADY = 1;

    @(posedge clk);
    AWVALID = 0;
    WVALID = 0;

    // Read transaction
    @(posedge clk);
    ARADDR = 4'h1;
    ARVALID = 1;
    RREADY = 1;

    @(posedge clk);
    ARVALID = 0;

    #50;
    $stop;
end

endmodule
