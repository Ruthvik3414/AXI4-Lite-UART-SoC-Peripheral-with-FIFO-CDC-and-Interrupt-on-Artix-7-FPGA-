`timescale 1ns / 1ps

module axi_lite_slave(
    input clk,
    input rst,

    // Write Address Channel
    input [3:0] AWADDR,
    input AWVALID,
    output reg AWREADY,

    // Write Data Channel
    input [31:0] WDATA,
    input WVALID,
    output reg WREADY,

    // Write Response
    output reg BVALID,
    input BREADY,
    output [1:0] BRESP,

    // Read Address
    input [3:0] ARADDR,
    input ARVALID,
    output reg ARREADY,

    // Read Data
    output reg [31:0] RDATA,
    output reg RVALID,
    input RREADY,
    output [1:0] RRESP,

    // Connection to Register Bank
    output reg wr_en,
    output reg rd_en,
    output reg [3:0] addr,
    output reg [31:0] wdata,
    input [31:0] rdata
);

    assign BRESP = 2'b00; // OKAY
    assign RRESP = 2'b00; // OKAY

    // Separate address registers to avoid multi-driver issue
    reg [3:0] awaddr_reg;
    reg [3:0] araddr_reg;

    // ---------------- WRITE CHANNEL ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            AWREADY <= 0;
            WREADY  <= 0;
            BVALID  <= 0;
            wr_en   <= 0;
            awaddr_reg <= 0;
            wdata <= 0;
        end else begin
            if (AWVALID && WVALID && !AWREADY) begin
                AWREADY <= 1;
                WREADY  <= 1;
                awaddr_reg <= AWADDR;
                wdata   <= WDATA;
                wr_en   <= 1;
            end else begin
                AWREADY <= 0;
                WREADY  <= 0;
                wr_en   <= 0;
            end

            if (wr_en)
                BVALID <= 1;
            else if (BREADY && BVALID)
                BVALID <= 0;
        end
    end

    // ---------------- READ CHANNEL ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ARREADY <= 0;
            RVALID  <= 0;
            rd_en   <= 0;
            RDATA   <= 0;
            araddr_reg <= 0;
        end else begin
            if (ARVALID && !ARREADY && !RVALID) begin
                ARREADY <= 1;
                araddr_reg <= ARADDR;
                rd_en   <= 1;
            end else begin
                ARREADY <= 0;
                rd_en   <= 0;
            end

            if (rd_en) begin
                RDATA  <= rdata;
                RVALID <= 1;
            end
            else if (RVALID && RREADY) begin
                RVALID <= 0;
            end
        end
    end

    // ---------------- ADDRESS MUX ----------------
    always @(*) begin
        if (wr_en)
            addr = awaddr_reg;
        else if (rd_en)
            addr = araddr_reg;
        else
            addr = 4'd0;
    end

endmodule