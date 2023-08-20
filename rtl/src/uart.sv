// UART Peripheral Definition
// Wrap UART functionality in an AXI Stream interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module uart #(
    parameter TX_FIFO_DEPTH = 256,
    parameter RX_FIFO_DEPTH = 256,

    parameter BAUD_RATE = 115200
) (

    // asynchronous RX signal
    input var logic rxd,

    // Tx signal is clock aligned but prescaled based off the baud RATE
    output var logic txd,

    axis_interface.Sink tx_stream,
    axis_interface.Source rx_stream
);
    // NOTE: I assume the clock frequency is 100MHz.
    // NEEDS to be updated to an actual scalable calc based off baud rate
    localparam CLKS_PER_BIT = 868;
    // Start by creating a synchronized version of the rx signal.
    var logic rxd_sync;

    // NOTE: we assume that both AXIS interfaces are using the same clock here
    sync_slow_signal rxd_synchonrizer (
        .sync_clk(tx_stream.clk),
        .signal(rxd),

        .synced_signal(rxd_sync)
    );

    typedef enum int {
        UART_RX_IDLE,
        UART_RX_START_BIT,
        UART_RX_DATA_BIT,
        UART_RX_STOP_BIT,
        UART_RX_WRITE_FIFO,
        UART_RX_PARITY_BIT // unused atm
    } uart_rx_state_t;

    uart_rx_state_t rx_state = UART_RX_IDLE;

    var logic [31:0] rx_clock_cycle_counter = 0;
    var logic [3:0] rx_bit_index = 0;
    always_ff @(posedge tx_stream.clk) begin
        case (rx_state)
            UART_RX_IDLE: begin
                // Initialize register values
                rx_bit_index <= 0;
                rx_clock_cycle_counter <= 0;

                // Look for falling edges to catch the start bit
                if (rxd_sync == 1'b0) begin
                    // after detecting a falling edge in rx from IDLE, advance
                    // to the start bit state.
                    rx_state <= UART_RX_START_BIT;
                end
            end

            UART_RX_START_BIT: begin
                // check for alignment. if we are halfway through the UART bit
                // cycle, check that the value of rx is still 0
                if (rx_clock_cycle_counter == (CLKS_PER_BIT - 1) / 2) begin
                    if (rxd_sync == 1'b0) begin
                        // Found the middle reset the counter and advance to
                        // receiving the subsequent data bits
                        rx_clock_cycle_counter <= 0;
                        rx_state <= UART_RX_DATA_BIT;

                        rx_stream.tvalid <= 0;
                    end else begin
                        // data is misaligned return to IDLE state to catch the next start bit
                        rx_state <= UART_RX_IDLE;
                    end
                end else begin
                    // increment the counter since our clock is much faster than UART
                    rx_clock_cycle_counter <= rx_clock_cycle_counter + 1;
                end
            end

            UART_RX_DATA_BIT: begin
                if (rx_clock_cycle_counter < CLKS_PER_BIT - 1) begin
                    rx_clock_cycle_counter <= rx_clock_cycle_counter + 1;
                end else begin
                    rx_clock_cycle_counter <= 0;
                    rx_stream.tdata[rx_bit_index] <= rxd_sync;

                    // advance the bit index so we can write the whole rx register
                    if (rx_bit_index < 7) begin
                        rx_bit_index <= rx_bit_index + 1;
                    end else begin
                        // if we have already written the whole byte to the
                        // rx_stream register proceed to checking for a stop bit
                        rx_bit_index <= 0;
                        rx_state <= UART_RX_STOP_BIT;

                    end
                end
            end

            UART_RX_STOP_BIT: begin
                if (rx_clock_cycle_counter < CLKS_PER_BIT - 1) begin
                    // wait in this state until the stop bit is received. We
                    // could have additional feedback here to ensure the bit
                    // remains set to 1 for the duration of our wait. Saved for
                    // future improvements.
                    rx_clock_cycle_counter <= rx_clock_cycle_counter + 1;
                end else begin
                    rx_clock_cycle_counter <= 0;
                    rx_state <= UART_RX_WRITE_FIFO;
                end
            end

            UART_RX_WRITE_FIFO: begin
                // at this point, we have the tdata register loaded.
                // assert tvalid to write this value to the queue
                rx_stream.tvalid <= 1;
                if (rx_stream.tvalid && rx_stream.tready) begin
                    // if the queue is ready and has accepted the data proceed to idle state
                    rx_state <= UART_RX_IDLE;
                end
            end
        endcase
    end

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
    always_ff @(posedge tx_stream.clk) begin
        case (tx_state)
            UART_TX_IDLE: begin
                txd <= 1'b1; // drive tx output high when in idle state
                tx_clock_cycle_counter <= 0;
                tx_bit_index <= 0;

                // for now just tx whatever is in a reg
                if (rx_stream.tvalid) begin
                    tx_data <= rx_stream.tdata;
                    // if we have valid data waiting on the queue, start txing
                    tx_state <= UART_TX_START_BIT;
                end
            end

            UART_TX_START_BIT: begin
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
                        // tx_data <= tx_data + 1;

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
