`timescale 1ns/1ps

module fifo_tb;

reg clk = 0;
reg rst;
reg wr_en;
reg rd_en;
reg [7:0] data_in;
wire [7:0] data_out;
wire full;
wire empty;

fifo uut (
    .clk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);

always #5 clk = ~clk;

initial begin
    // 1. Initialize
    rst = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;
    #20;    
    
    // 2. Clear Reset
    @(negedge clk); rst = 0; 
    #10;

    // 3. Write data (using <= to avoid race conditions)
    @(posedge clk); wr_en <= 1; data_in <= 8'h11;
    @(posedge clk); data_in <= 8'h22;
    @(posedge clk); data_in <= 8'h33;
    @(posedge clk); data_in <= 8'h44;
    @(posedge clk); wr_en <= 0;

    // 4. Wait a bit
    #20;

    // 5. Read data
    @(posedge clk); rd_en <= 1;
    repeat(4) @(posedge clk); // Read 4 times
    @(posedge clk); rd_en <= 0;

    #100;
    $stop; // This will pause the sim and show you the wave
end
endmodule