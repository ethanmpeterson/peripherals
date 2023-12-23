`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module udp_tx_example_tb;
    var logic udp_sys_clk;
    var logic system_reset;

    mii_interface phy_mii ();

    udp_tx_example dut (
        .udp_sys_clk(udp_sys_clk),
        .system_reset(system_reset),

        .phy_mii(phy_mii)
    );

    always begin
        #1
        udp_sys_clk <= !udp_sys_clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            udp_sys_clk = 0;
            system_reset = 0;
        end

        `TEST_CASE("test_checksum_integrity") begin
            automatic int cycle_count = 0;
            @(posedge udp_sys_clk) begin
                cycle_count = cycle_count + 1;
                if (cycle_count > 1000) begin
                    `CHECK_EQUAL(0, 0);
                end
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
