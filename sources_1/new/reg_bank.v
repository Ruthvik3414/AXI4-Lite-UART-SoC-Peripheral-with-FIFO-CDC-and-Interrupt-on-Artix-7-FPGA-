module reg_bank(
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [3:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata,

    // TX
    output reg [7:0] tx_data,
    output reg tx_write,
    input fifo_full,
    input fifo_empty,

    // RX
    input [7:0] rx_data,
    input rx_data_ready,
    output reg clr_rx_data_ready,

    // Interrupt
    output interrupt
);

    reg [31:0] reg_baud;
    reg [31:0] reg_control;
    reg interrupt_en;

    wire [31:0] reg_status = {29'd0, rx_data_ready, fifo_full, fifo_empty};
    assign interrupt = interrupt_en & (rx_data_ready);

    // Write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_baud <= 32'd5208;
            reg_control <= 0;
            tx_data <= 0;
            tx_write <= 0;
            interrupt_en <= 0;
            clr_rx_data_ready <= 0;
        end else begin
            tx_write <= 0;
            clr_rx_data_ready <= 0;

            if (wr_en) begin
                case(addr)
                    4'h0: if (!fifo_full) begin
                        tx_data <= wdata[7:0];
                        tx_write <= 1;
                    end
                    4'h2: reg_baud <= wdata;
                    4'h3: reg_control <= wdata;
                    4'hC: interrupt_en <= wdata[0];
                endcase
            end

            if (rd_en && addr == 4'h4)
                clr_rx_data_ready <= 1;
        end
    end

    // COMBINATIONAL READ
    always @(*) begin
        case(addr)
            4'h0: rdata = {24'd0, tx_data};
            4'h1: rdata = reg_status;
            4'h2: rdata = reg_baud;
            4'h3: rdata = reg_control;
            4'h4: rdata = {24'd0, rx_data};
            4'hC: rdata = {31'd0, interrupt_en};
            default: rdata = 32'hDEADBEEF;
        endcase
    end

endmodule