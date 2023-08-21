// UART RX Peripheral Definition
// Wrap UART functionality in an AXI Stream interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module uart_rx #(
    // Equates to a 115200 bps rate on 100 MHz clock.
    parameter CLKS_PER_BIT = 868
) (
    // asynchronous RX signal
    input var logic rxd,
    axis_interface.Source stream
);
    // create clock synchronized version of async rx signal.
    var logic rxd_sync;
    sync_slow_signal rxd_synchonrizer (
        .sync_clk(stream.clk),
        .signal(rxd),

        .synced_signal(rxd_sync)
    );

    typedef enum int {
        UART_RX_IDLE,
        UART_RX_START_BIT,
        UART_RX_DATA_BIT,
        UART_RX_STOP_BIT,
        UART_RX_PARITY_BIT // unused atm
    } uart_rx_state_t;

    uart_rx_state_t rx_state = UART_RX_IDLE;
    var logic [31:0] rx_clock_cycle_counter = 0;
    var logic [3:0] rx_bit_index = 0;
    always_ff @(posedge stream.clk) begin
        case (rx_state)
            UART_RX_IDLE: begin
                stream.tvalid <= 0;
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
                    stream.tdata[rx_bit_index] <= rxd_sync;

                    // advance the bit index so we can write the whole rx register
                    if (rx_bit_index < 7) begin
                        rx_bit_index <= rx_bit_index + 1;
                    end else begin
                        // if we have already written the whole byte to the
                        // stream register proceed to checking for a stop bit
                        rx_bit_index <= 0;

                        // Now that we have the data assert the valid bit
                        stream.tvalid <= 1'b1;

                        rx_state <= UART_RX_STOP_BIT;
                    end
                end
            end

            UART_RX_STOP_BIT: begin
                // deassert tvalid once we have written the value to the stream
                if (stream.tready && stream.tvalid) begin
                    stream.tvalid <= 1'b0;
                end

                if (rx_clock_cycle_counter < CLKS_PER_BIT - 1) begin
                    // wait in this state until the stop bit is received. We
                    // could have additional feedback here to ensure the bit
                    // remains set to 1 for the duration of our wait. Saved for
                    // future improvements.
                    rx_clock_cycle_counter <= rx_clock_cycle_counter + 1;
                end else if (stream.tvalid == 1'b0) begin
                    // ^ only proceed to the next state when we know we have written the rx byte back to the queue.

                    // we have the potential to get stuck here. Similarly to
                    // microcontroller peripherals, if you do not consume the
                    // data fast enough you lose it. Alternatively we could wait
                    // here until space in the queue becomes available
                    rx_clock_cycle_counter <= 0;

                    rx_state <= UART_RX_IDLE;
                end
            end
        endcase
    end
endmodule

`default_nettype wire
