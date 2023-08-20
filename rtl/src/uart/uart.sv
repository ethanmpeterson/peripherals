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


    // Receiver Hookup
    axis_interface rx (
        .clk(rx_stream.clk),
        .reset(rx_stream.reset)
    );

    axis_fifo_status_interface rx_fifo_status ();
    axis_fifo_wrapper #(
        .DEPTH(RX_FIFO_DEPTH)
    ) rx_fifo (
        .sink(rx),
        .source(rx_stream),

        // status signals not used
        .status(rx_fifo_status)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_receiver (
        .rxd(rxd),
        .stream(rx)
    );


    // Transmitter Hookup
    axis_interface tx (
        .clk(tx_stream.clk),
        .reset(tx_stream.reset)
    );

    axis_fifo_status_interface tx_fifo_status ();
    axis_fifo_wrapper #(
        .DEPTH(TX_FIFO_DEPTH)
    ) tx_fifo (
        .sink(tx_stream),
        .source(tx),

        // status signals unused
        .status(tx_fifo_status)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_transmitter (
        .txd(txd),
        .stream(tx)
    );

    always_comb begin : handle_unused_axis_signals
        // Drive all unused axi stream signals to default values here
        // rx.tlast = 1'b1;
        // rx.tuser = 1'b0;

        // tx.tuser = 1'b0;
    end

endmodule

`default_nettype wire
