`default_nettype none
`timescale 1ns / 1ps

interface axis_interface ();
var logic mdc;
var logic mdio;

modport Master (
    output mdc,
    inout mdio
);

modport Slave (
    input mdc,
    inout mdio
);


endinterface // mdio_interface

`default_nettype wire
