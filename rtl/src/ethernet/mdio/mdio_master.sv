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
        MDIO_MASTER_STATE_IDLE,

        // Includes the start condition, opcode, and PHY address for the R/W cases respectively
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


    typedef enum int {
        AXIL_MDIO_CONSUMER_STATE_INIT,

        AXIL_MDIO_CONSUMER_STATE_WAIT_FOR_READ_RESP,

        AXIL_MDIO_CONSUMER_STATE_LATCH_WRITE_TRANSACTION,
        AXIL_MDIO_CONSUMER_STATE_WAIT_FOR_WRITE_DATA,
        AXIL_MDIO_CONSUMER_STATE_WAIT_FOR_WRITE_RESP
    } axil_mdio_consumer_state_t;

    axil_mdio_consumer_state_t axil_mdio_consumer_state = AXIL_MDIO_CONSUMER_STATE_INIT;
    var logic [axi_lite.WRITE_ADDRESS_WIDTH-1:0] write_address;
    var logic [axi_lite.READ_ADDRESS_WIDTH-1:0] read_address;
    var logic                                   mdio_master_start_read;
    always_ff @(posedge clk) begin
        if (reset) begin
            axil_mdio_consumer_state <= AXIL_MDIO_CONSUMER_STATE_INIT;
        end else begin
            case (axil_mdio_consumer_state)
                AXIL_MDIO_CONSUMER_STATE_INIT: begin
                    // Provide initial values for the AXI Lite Signals

                    // Address Writes
                    axi_lite.awready <= 1'b1;

                    // Data Writes
                    axi_lite.wready <= 1'b0;

                    // Write Response
                    axi_lite.bresp <= 2'b00;
                    axi_lite.bvalid <= 1'b0;

                    // Address Reads
                    axi_lite.arready <= 1'b1;

                    // Data Reads
                    axi_lite.rdata <= { axi_lite.READ_DATA_WIDTH{1'b0} };
                    axi_lite.rresp <= 2'b00;
                    axi_lite.rvalid <= 1'b0;

                    // Signal to notify MDIO master state machine of read operation
                    mdio_master_start_read <= 1'b0;

                    // NOTE: The module does not support concurrent reads and writes.

                    // Reads will override writes and an attempted write
                    // transaction will be dropped if both arrive on the same
                    // cycle.

                    if (axi_lite.awready && axi_lite.awvalid) begin
                        write_address <= axi_lite.awaddr;

                        // axil_mdio_consumer_state <= AXIL_MDIO_CONSUMER_STATE_WAIT_FOR_READ_RESP;
                    end

                    // Prioritize Read over write transaction if both validity
                    // checks are true in the same clock cycle
                    if (axi_lite.arready && axi_lite.arvalid) begin
                        read_address <= axi_lite.araddr;

                        axil_mdio_consumer_state <= AXIL_MDIO_CONSUMER_STATE_WAIT_FOR_READ_RESP;
                    end
                end

                AXIL_MDIO_CONSUMER_STATE_WAIT_FOR_READ_RESP: begin
                    // Wait for the MDIO master state machine to tell us that a result is ready
                end

                default: begin
                    axil_mdio_consumer_state <= AXIL_MDIO_CONSUMER_STATE_INIT;
                end

            endcase
        end
    end


    // Generate MDC clock line.
    var logic[15:0] cycle_counter = 0;
    always_ff @(posedge clk) begin
        if (cycle_counter == CLKS_PER_BIT/2) begin
            mdc <= !mdc;
        end else begin
            cycle_counter <= 0;
        end

        if (reset) begin
            mdc <= 1'b0;
        end
    end

    mdio_master_state_t mdio_master_state = MDIO_MASTER_STATE_INIT;
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


                    mdio_o <= 1'b0;
                    mdio_t <= 1'b1;
                    mdc <= 1'b0;

                    // Provide initial values for the AXI Lite Signals

                    // Address Writes
                    axi_lite.awready <= 1'b1;

                    // Data Writes
                    axi_lite.wready <= 1'b0;

                    // Write Response
                    axi_lite.bresp <= 2'b00;
                    axi_lite.bvalid <= 1'b0;

                    // Address Reads
                    axi_lite.arready <= 1'b1;

                    // Data Reads
                    axi_lite.rdata <= { axi_lite.READ_DATA_WIDTH{1'b0} };
                    axi_lite.rresp <= 2'b00;
                    axi_lite.rvalid <= 1'b0;
                end

                default: begin
                    mdio_master_state <= MDIO_MASTER_STATE_INIT;
                end
            endcase
        end
    end
endmodule

`default_nettype wire
