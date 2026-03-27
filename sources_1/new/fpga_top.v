`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.03.2026 12:54:41
// Design Name: 
// Module Name: fpga_top
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


module fpga_top(
    input clk,
    input rst,
    input rx,
    output tx,
    output interrupt
);

    // AXI internal wires
    wire [3:0] AWADDR;
    wire AWVALID;
    wire AWREADY;
    wire [31:0] WDATA;
    wire WVALID;
    wire WREADY;
    wire BVALID;
    wire BREADY;
    wire [3:0] ARADDR;
    wire ARVALID;
    wire ARREADY;
    wire [31:0] RDATA;
    wire RVALID;
    wire RREADY;

    // Tie-offs
    assign AWADDR = 0;
    assign AWVALID = 0;
    assign WDATA = 0;
    assign WVALID = 0;
    assign BREADY = 1;
    assign ARADDR = 0;
    assign ARVALID = 0;
    assign RREADY = 1;

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

endmodule