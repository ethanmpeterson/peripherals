`timescale 1ns / 1ps
`default_nettype none

module mdio_master #(
    parameter CLKS_PER_BIT = 100
) (
    inout var logic mdio,
    output var logic mdc,

    axi_lite_interface.Slave axi_lite
);

endmodule

`default_nettype wire
