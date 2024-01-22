`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

module mdio_master_tb;
    localparam MDIO_READ_OPCODE    = 2'b10;
    localparam MDIO_WRITE_OPCODE   = 2'b01;
    localparam PHY_ADDRESS         = 5'h0c;
    localparam REG_ADDRESS         = 5'h18;
    localparam REG_DATA            = 16'haaa5;

    var logic clk;
    var logic mdio_o;
    var logic mdio_t;

    var logic phy_mdio_o;
    var logic phy_mdio_t;

    var logic mdio = 1'bz;

    var logic mdc;

    // Handle tristate logic from both BFM and master
    always_comb begin
        if (mdio_t && !phy_mdio_t) begin
            mdio = phy_mdio_o;
        end else if (!mdio_t && phy_mdio_t) begin
            mdio = mdio_o;
        end else begin
            mdio = 1'bz;
        end
    end

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
        .CLKS_PER_BIT(6),
        .PHY_ADDRESS(PHY_ADDRESS)
    ) DUT (
        .clk(clk),
        .reset(0),

        .mdio_o(mdio_o),
        .mdio_i(mdio),
        .mdio_t(mdio_t),
        .mdc(mdc),

        .axi_lite(mdio_axil.Slave)
    );

    var logic [4:0] phy_addr;
    var logic [4:0] reg_addr;
    var logic [1:0] opcode;
    var logic       turnaround_valid;
    mdio_slave_bfm #(
        .PHY_ADDRESS(PHY_ADDRESS),
        .TEST_REG_ADDRESS(REG_ADDRESS),
        .REGISTER_TEST_DATA(REG_DATA)
    ) bfm (
        .mdio_i(mdio),
        .mdio_o(phy_mdio_o),
        .mdio_t(phy_mdio_t),

        .mdc(mdc),

        .opcode(opcode),
        .phy_addr(phy_addr),
        .reg_addr(reg_addr),
        .turnaround_valid(turnaround_valid)
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
            while (!read_finished) begin
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
                end
            end
            `CHECK_EQUAL(read_data, REG_DATA);
            `CHECK_EQUAL(turnaround_valid, 1'b1);
            `CHECK_EQUAL(opcode, MDIO_READ_OPCODE);
            `CHECK_EQUAL(phy_addr, PHY_ADDRESS);
            `CHECK_EQUAL(reg_addr, REG_ADDRESS);
            // TODO: Add an assertion that covers the bus being highZ after the transaction finishes.

            // Some changes were made to make the BFM validation pass. Do
            // another final scrub that this matches the timing diagram in the
            // datasheet.

            // Start work on the write path in the state machine.

            // Potential HW test: do an MDIO read of the LED register in the PHY
            // and map the link LEDs to LEDs on the dev board.
        end

        // `TEST_CASE("mdio_write_transaction") begin
        //     `CHECK_EQUAL(0, 0);
        // end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire

