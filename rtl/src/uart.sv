// UART Peripheral Definition
// Wrap UART functionality in an AXI Stream interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module uart #(
    parameter TX_FIFO_DEPTH = 256,
    parameter RX_FIFO_DEPTH = 256,
    parameter BAUD_RATE = 9600
) (
    axis_interface.Sink tx_stream,
    axis_interface.Source rx_stream
);
    // do stuff here

endmodule

`default_nettype wire
