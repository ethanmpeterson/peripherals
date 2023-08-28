// UART TX Peripheral Definition
// Wrap UART functionality in an AXI Stream interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module uart_tx #(
    // Equates to a 115200 bps rate on 100 MHz clock.
    parameter CLKS_PER_BIT = 868,
    parameter FIFO_DEPTH = 256
) (
    output var logic txd,

    axis_interface.Sink tx_stream
);

    // create stream an FIFO
    axis_interface stream (
        .clk(tx_stream.clk),
        .reset(tx_stream.reset)
    );

    axis_fifo_status_interface tx_fifo_status ();
    axis_fifo_wrapper #(
        .DEPTH(FIFO_DEPTH)
    ) tx_fifo (
        .sink(tx_stream),
        .source(stream.Source),

        .status(tx_fifo_status)
    );

    typedef enum int {
        UART_TX_IDLE,
        UART_TX_START_BIT,
        UART_TX_DATA_BIT,
        UART_TX_STOP_BIT,
        UART_TX_PARITY_BIT // unused atm
    } uart_tx_state_t;

    uart_tx_state_t tx_state = UART_TX_IDLE;
    var logic [31:0] tx_clock_cycle_counter = 0;
    var logic [3:0] tx_bit_index = 0;
    var logic [7:0] tx_data = 0;
    always_ff @(posedge stream.clk) begin
        case (tx_state)
            UART_TX_IDLE: begin
                txd <= 1'b1; // drive tx output high when in idle state
                tx_clock_cycle_counter <= 0;
                tx_bit_index <= 0;

                // assert tready to tell the queue that we are ready for new data
                stream.tready <= 1'b1;

                if (stream.tvalid && stream.tready) begin
                    // deassert tready. latest data should be available in tdata
                    // register
                    stream.tready <= 1'b0;

                    // latch the tx data
                    tx_data <= stream.tdata;

                    // if we have valid data waiting on the queue, start txing
                    tx_state <= UART_TX_START_BIT;
                end
            end

            UART_TX_START_BIT: begin
                // Drive low for the start bit
                txd <= 1'b0;

                // wait for clocks per bit cycles
                if (tx_clock_cycle_counter < CLKS_PER_BIT - 1) begin
                    tx_clock_cycle_counter <= tx_clock_cycle_counter + 1;
                end else begin
                    tx_clock_cycle_counter <= 0;
                    tx_state <= UART_TX_DATA_BIT;
                end
            end

            UART_TX_DATA_BIT: begin
                txd <= tx_data[tx_bit_index];

                if (tx_clock_cycle_counter < CLKS_PER_BIT - 1) begin
                    tx_clock_cycle_counter <= tx_clock_cycle_counter + 1;
                end else begin
                    tx_clock_cycle_counter <= 0;
                    if (tx_bit_index < 7) begin
                        tx_bit_index <= tx_bit_index + 1;
                    end else begin
                        tx_bit_index <= 0;                        

                        tx_state <= UART_TX_STOP_BIT;
                    end
                end
            end

            UART_TX_STOP_BIT: begin
                txd <= 1'b1;

                if (tx_clock_cycle_counter < CLKS_PER_BIT - 1) begin
                    tx_clock_cycle_counter <= tx_clock_cycle_counter + 1;
                end else begin
                    tx_clock_cycle_counter <= 0;

                    tx_state <= UART_TX_IDLE;
                end
            end
        endcase
    end
endmodule

`default_nettype wire
