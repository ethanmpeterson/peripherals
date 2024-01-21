`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

module mdio_master_tb;
    localparam REGISTER_TEST_VALUE = 16'b0000000000_11_0_11_0;
    var logic clk;
    var logic mdio_o;
    var logic mdio_t;
    var logic mdio;

    var logic mdc;

    assign mdio = mdio_t ? 1'bz : mdio_o;

    var logic[15:0] read_data;
    var logic       read_finished = 1'b0;

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
        .CLKS_PER_BIT(6)
    ) DUT (
        .clk(clk),
        .reset(0),

        .mdio_o(mdio_o),
        .mdio_i(0), // TODO: hook this up to a MDIO BFM
        .mdio_t(mdio_t),
        .mdc(mdc),

        .axi_lite(mdio_axil.Slave)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;

            // Initialize all AXI Lite master signals
            mdio_axil.awaddr = 0;
            mdio_axil.awprot = 0; // module does not care about this signal
            mdio_axil.awvalid = 1'b0;

            mdio_axil.wdata = 0;
            mdio_axil.wstrb = 0;
            mdio_axil.wvalid = 0;

            mdio_axil.bready = 1'b0;

            mdio_axil.araddr = 0;
            mdio_axil.arprot = 0;
            mdio_axil.arvalid = 0;

            mdio_axil.rready = 0;
        end

        `TEST_CASE("mdio_read_transaction") begin
            automatic int cycle_counter = 0;
            while (read_finished || cycle_counter < 200) begin
                cycle_counter = cycle_counter + 1;
                @(posedge clk) begin
                    // In the DP83848 PHY I am using, this is the LED control
                    // register. The BFM will respond to this as a valid address
                    // with fake data
                    mdio_axil.araddr <= 5'h18;
                    mdio_axil.arvalid <= 1'b1;
                    if (mdio_axil.arready && mdio_axil.arvalid) begin
                        // finish writing the address and proceed to wait for the register's data
                        mdio_axil.arvalid <= 1'b0;

                        // Indicate the master is ready to accept the read data
                        mdio_axil.rready <= 1'b1;
                    end

                    if (mdio_axil.rready && mdio_axil.rvalid) begin
                        read_data <= mdio_axil.rdata;
                        mdio_axil.rready <= 1'b0;

                        read_finished <= 1'b1;
                    end

                    if (read_finished) begin
                        // check against fixed test register value.
                        // `CHECK_EQUAL(read_data, REGISTER_TEST_VALUE);
                    end
                end
            end
            `CHECK_EQUAL(0, 0);
        end

        // `TEST_CASE("mdio_write_transaction") begin
        //     `CHECK_EQUAL(0, 0);
        // end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire

