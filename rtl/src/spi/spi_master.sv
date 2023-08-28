`timescale 1ns / 1ps
`default_nettype none

module spi_master (
    input var logic spi_clk,
    input var logic miso,

    output var logic cs,
    output var logic sck,
    output var logic mosi,

    axis_interface.Sink mosi_stream,
    axis_interface.Source miso_stream
);

    // Designer will provide the SPI clock so that no clock division needs to
    // happen inside the module. This should allow them to use clock dividers
    // and PLLs provided by their specific FPGA hardware.

    // Now that we have multiple clock domains we will use async fifos

endmodule

`default_nettype wire
