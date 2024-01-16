`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

module mdio_master_tb;

    var logic clk;
    var logic mdio;
    var logic mdc;

    always begin
        #10
            clk <= !clk;
    end

    axi_lite_interface #(
        .READ_ADDRESS_WIDTH(5),
        .READ_DATA_WIDTH(16),

        .WRITE_ADDRESS_WIDTH(5),
        .WRITE_DATA_WIDTH(16)
        ) mdio_axil ();

    mdio_master #(
        .CLKS_PER_BIT(1)
    ) DUT (
        .clk(clk),
        .reset(0),

        .mdio_o(mdio),
        .mdio_i(0),
        .mdio_t(),
        .mdc(mdc),

        .axi_lite(mdio_axil.Slave)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;
        end

        `TEST_CASE("mdio_master_tb_placeholder") begin
            `CHECK_EQUAL(0, 0);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
