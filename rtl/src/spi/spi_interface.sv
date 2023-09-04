// SPI interface
`default_nettype none
`timescale 1ns / 1ps

interface spi_interface #(
    parameter CS_COUNT = 1
);
    var logic mosi;
    var logic miso;
    var logic sck;
    
    // typically active low
    var logic[CS_COUNT-1:0] cs;

    // Employ modports to establish master/slave variants
    modport Master (
        output sck, mosi, cs,
        input miso
    );

    modport Slave (
        output miso,
        input sck, mosi, cs
    );

endinterface // spi_interface

`default_nettype wire
