`timescale 1ns / 1ps
`default_nettype none

// Overrides and blinks the LEDs on the DP838x PHY
// Datasheet in the ethernet docs folder
module mdio_example (
    input var  logic clk,
    input var  logic reset,

    input var  logic mdio_i,
    output var logic mdio_o,
    output var logic mdio_t,

    output var logic mdc
);

    axi_lite_interface #(
        .READ_ADDRESS_WIDTH(5),
        .READ_DATA_WIDTH(16),

        .WRITE_ADDRESS_WIDTH(5),
        .WRITE_DATA_WIDTH(16)
    ) mdio_axil ();

    mdio_master mdio_master_inst (
        .clk(clk),
        .reset(reset),

        .mdio_i(mdio_i),
        .mdio_o(mdio_o),
        .mdio_t(mdio_t),

        .mdc(mdc),

        .axi_lite(mdio_axil.Slave)
    );

    always_ff @(posedge clk) begin
        // TODO: Blink both link light LEDs at 1Hz using MDIO register writes
    end
endmodule

`default_nettype wire

