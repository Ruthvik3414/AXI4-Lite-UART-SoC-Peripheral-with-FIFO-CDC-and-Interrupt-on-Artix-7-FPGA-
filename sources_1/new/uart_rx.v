module uart_rx #(
    parameter CLKS_PER_BIT = 5208 // Match the TX baud
)(
    input            clk,
    input            rst,
    input            rx,
    input            clr_data_ready,
    output reg [7:0] data_out,
    output reg       data_ready
);

    localparam IDLE=2'b00, START=2'b01, DATA=2'b10, STOP=2'b11;
    reg [1:0]  state;
    reg [12:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift;
    reg        rx_sync_1, rx_sync_2;

    // Double Flop Synchronizer
    always @(posedge clk or posedge rst) begin
        if (rst) {rx_sync_1, rx_sync_2} <= 2'b11;
        else     {rx_sync_1, rx_sync_2} <= {rx, rx_sync_1};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE; data_ready <= 0; data_out <= 0; clk_count <= 0;
        end else begin
            if (clr_data_ready) data_ready <= 0;
            
            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (!rx_sync_2) state <= START; // Start bit detected (falling edge)
                end
                
                START: begin
                    if (clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (!rx_sync_2) begin 
                            clk_count <= 0; 
                            state <= DATA; 
                        end else state <= IDLE; // False start
                    end else clk_count <= clk_count + 1;
                end

                DATA: begin
                    if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        rx_shift[bit_index] <= rx_sync_2;
                        if (bit_index < 7) bit_index <= bit_index + 1;
                        else state <= STOP;
                    end
                end

                STOP: begin
                    if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                    else begin
                        data_out <= rx_shift;
                        data_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule