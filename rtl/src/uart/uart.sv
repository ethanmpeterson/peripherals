// UART Peripheral Definition
// Wrap UART functionality in an AXI Stream interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module uart #(
    parameter TX_FIFO_DEPTH = 32,
    parameter RX_FIFO_DEPTH = 32,

    // Equates to a 115200 bps rate on 100 MHz clock.
    parameter CLKS_PER_BIT = 868
) (

    // asynchronous RX signal
    input var logic rxd,

    output var logic txd,

    axis_interface.Sink tx_stream,
    axis_interface.Source rx_stream
);

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .FIFO_DEPTH(RX_FIFO_DEPTH)
    ) uart_receiver (
        .rxd(rxd),
        .rx_stream(rx_stream)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .FIFO_DEPTH(TX_FIFO_DEPTH)
    ) uart_transmitter (
        .txd(txd),
        .tx_stream(tx_stream)
    );

endmodule

`default_nettype wire
