// UART Peripheral Definition
// Wrap UART functionality in an AXI Stream interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module uart #(
    parameter TX_FIFO_DEPTH = 256,
    parameter RX_FIFO_DEPTH = 256,

    // Equates to a 115200 bps rate on 100 MHz clock.
    parameter CLKS_PER_BIT = 868
) (

    // asynchronous RX signal
    input var logic rxd,

    output var logic txd,

    axis_interface.Sink tx_stream,
    axis_interface.Source rx_stream
);

    axis_interface internal (
        .clk(tx_stream.clk),
        .reset(tx_stream.reset)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_receiver (
        .rxd(rxd),
        .rx_stream(internal.Source)
    );


    // Transmitter Hookup
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_transmitter (
        .txd(txd),
        .tx_stream(internal.Sink)
    );

endmodule

`default_nettype wire
