`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

module mdio_writer_tb;
    localparam PHY_ADDRESS         = 5'h0c;

    var logic clk;
    var logic mdio_o;
    var logic mdio_t;

    var logic phy_mdio_o;
    var logic phy_mdio_t;

    var logic mdio = 1'bz;

    var logic mdc;

    // Handle tristate logic from both BFM and master


    always begin
        #10
        clk <= !clk;
    end


    mdio_writer #(
        .CLKS_PER_BIT(6)
    ) DUT (
        .clk(clk),
        .reset(0),

        .mdio_o(mdio_o),
        .mdio_i(mdio),
        .mdio_t(mdio_t),
        .mdc(mdc)
    );


    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;
        end

        `TEST_CASE("mdio_read_transaction") begin
            automatic int cycle_counter = 0;
            while (cycle_counter < 100) begin
                @(negedge mdc) cycle_counter = cycle_counter + 1;
            end

            `CHECK_EQUAL(0, 0);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
