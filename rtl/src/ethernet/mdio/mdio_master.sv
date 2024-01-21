`timescale 1ns / 1ps
`default_nettype none

module mdio_master #(
    // Assumes we are provided a 125 MHz sys clk and gives an effective data rate of 1 Mbps
    parameter CLKS_PER_BIT = 125,
    parameter PHY_ADDRESS = 5'h0c
) (
    input var  logic clk,
    input var  logic reset,

    // handle the tristate case as discrete signals. Will be hooked up at the top level
    input var logic mdio_i,
    output var logic mdio_o,
    output var logic mdio_t,

    output var logic mdc,

    axi_lite_interface.Slave axi_lite
);

    // Design a state machine to consume MDIO R/W Commands and construct a
    // packet to send out the MDIO/MDC signal For background consult the timing
    // diagram in page 34 of the PHY datasheet in the docs folder.
    typedef enum int {
        MDIO_MASTER_STATE_INIT,

        MDIO_MASTER_STATE_WAIT_FOR_WRITE_DATA,

        // The following states match the definition in the PHY datasheet (pg.
        // 34, in the ethernet docs folder)

        // Includes the start condition, opcode, and PHY address for the R/W cases respectively
        MDIO_MASTER_STATE_START_CONDITION,
        MDIO_MASTER_STATE_WRITE_PREAMBLE,
        MDIO_MASTER_STATE_READ_PREAMBLE,

        // Not the full two bits, only handles the high Z differentiation case
        MDIO_MASTER_STATE_WRITE_TURNAROUND,
        MDIO_MASTER_STATE_READ_TURNAROUND,

        // Handles the leading zero prior to a register R/W operation
        MDIO_MASTER_STATE_LEADING_ZERO,

        // Clock out register bits in the write case
        MDIO_MASTER_STATE_WRITE_REGISTER_DATA,

        // Record returned register data in the read case
        MDIO_MASTER_STATE_READ_REGISTER_DATA
    } mdio_master_state_t;

    var logic [axi_lite.WRITE_ADDRESS_WIDTH-1:0] write_address;
    var logic [axi_lite.WRITE_DATA_WIDTH-1:0]    write_data;
    var logic [axi_lite.READ_ADDRESS_WIDTH-1:0]  read_address;

    // Signal to tell us if the data is on the line when seeing the first rising
    // edge in an MDIO write transaction. Used in the
    // MDIO_MASTER_STATE_START_CONDITION
    var logic                                   wrote_first_bit = 1'b0;
    var logic [$clog2(CLKS_PER_BIT):0]          transfer_clock_cycle_count;



    // Generate MDC clock line.
    localparam                                  CYCLE_COUNTER_REG_WIDTH = $clog2(CLKS_PER_BIT);
    var logic [CYCLE_COUNTER_REG_WIDTH:0]       cycle_counter = { CYCLE_COUNTER_REG_WIDTH{1'b0} };
    var logic                                   mdc_rising_edge = 1'b0;

    mdio_master_state_t mdio_master_state = MDIO_MASTER_STATE_INIT;

    always_ff @(posedge clk) begin
        if (cycle_counter == CLKS_PER_BIT/2) begin
            // reset the counter
            cycle_counter <= 0;

            // If the next value is a rising edge
            if (!mdc) begin
                mdc_rising_edge <= 1'b1;
            end else begin
                mdc_rising_edge <= 1'b0;
            end

            // swap the state of MDC and register the rising / falling edge
            mdc <= !mdc;
        end else begin
            cycle_counter <= cycle_counter + 1;
        end

        if (reset) begin
            mdc <= 1'b0;
        end

        if (mdio_master_state == MDIO_MASTER_STATE_INIT) begin
            mdc <= 1'b0;
        end
    end

    var logic [15:0] mdc_cycle_tracker;
    var logic        mdio_reg;
    always_ff @(posedge clk) begin
        if (reset) begin
            mdio_master_state <= MDIO_MASTER_STATE_INIT;
        end else begin
            case (mdio_master_state)
                MDIO_MASTER_STATE_INIT: begin
                    // NOTE: allow at least 32 MDC clock cycles between
                    // transactions in the case that an invalid command is
                    // provided to the PHY. This is the amount of time it takes
                    // to re-synchronize


                    // tristate the output while the module is initializing
                    mdio_o <= 1'b0;
                    mdio_t <= 1'b1;

                    // Provide initial values for the AXI Lite Signals

                    // Address Writes
                    axi_lite.awready <= 1'b1;

                    // Data Writes
                    axi_lite.wready <= 1'b0;

                    // Write Response
                    axi_lite.bresp <= 2'b00;
                    axi_lite.bvalid <= 1'b0;

                    // Address Reads

                    // NOTE: that we are marking the system as both ready for a
                    // read or a write. The parent module should not try a
                    // concurrent read/write in the same cycle
                    axi_lite.arready <= 1'b1;

                    // Data Reads
                    axi_lite.rdata <= { axi_lite.READ_DATA_WIDTH{1'b0} };
                    axi_lite.rresp <= 2'b00;
                    axi_lite.rvalid <= 1'b0;

                    // Enter the read/write branch of the state machine

                    // NOTE: that if a valid read and write address arrive in
                    // the same clock cycle, the read will be prioritized per
                    // the ordering of the if/else below.
                    if (axi_lite.arready && axi_lite.arvalid) begin
                        // Latch the given register address on the PHY and start
                        // the MDIO read transaction.
                        read_address <= axi_lite.araddr;

                        // Indicate the Module is no longer accepting address data
                        axi_lite.arready <= 1'b0;
                        axi_lite.awready <= 1'b0;

                        mdio_master_state <= MDIO_MASTER_STATE_START_CONDITION;
                    end else if (axi_lite.awready && axi_lite.awvalid) begin
                        // Latch the register address for a MDIO write and
                        // proceed to waiting the master to provide the data.
                        write_address <= axi_lite.awaddr;

                        // Indicate the AXI Lite Slave is ready to accept data
                        axi_lite.wready <= 1'b1;

                        // Indicate the Module is no longer accepting address data
                        axi_lite.arready <= 1'b0;
                        axi_lite.awready <= 1'b0;

                        mdio_master_state <= MDIO_MASTER_STATE_WAIT_FOR_WRITE_DATA;
                    end
                end

                MDIO_MASTER_STATE_WAIT_FOR_WRITE_DATA: begin
                    if (axi_lite.wready && axi_lite.wvalid) begin
                        // Latch the register write data and advance the state machine
                        write_data <= axi_lite.wdata;

                        // Mark the AXI Lite slave as no longer accepting data
                        axi_lite.wready <= 1'b0;

                        // Start the MDIO write now that we have all the information
                        mdio_master_state <= MDIO_MASTER_STATE_WRITE_PREAMBLE;
                    end
                end

                MDIO_MASTER_STATE_START_CONDITION: begin
                    // When it is a not a rising edge of MDC, queue up the first
                    // bit on the line. then advance through the rest of the
                    // preamble
                    if (!mdc_rising_edge && !wrote_first_bit) begin
                        mdio_o <= 1'b0;

                        // Don't tristate the bus, drive the data line directly
                        mdio_t <= 1'b0;

                        wrote_first_bit <= 1'b1;
                    end

                    if (mdc_rising_edge && wrote_first_bit) begin
                        // Since wrote_first_bit is asserted, we know that the
                        // first 0 we sent is on the line and clocked into the
                        // PHY. Now proceed to write the next value in the start
                        // condition and then start writing the preamble.
                        wrote_first_bit <= 1'b0;

                        mdio_o <= 1'b1;

                        mdio_master_state <= MDIO_MASTER_STATE_READ_PREAMBLE;
                    end
                end

                MDIO_MASTER_STATE_WRITE_PREAMBLE: begin
                end

                MDIO_MASTER_STATE_READ_PREAMBLE: begin
                    if (mdc_rising_edge) begin
                    end
                end

                default: begin
                    mdio_master_state <= MDIO_MASTER_STATE_INIT;
                end
            endcase
        end
    end

endmodule

`default_nettype wire

