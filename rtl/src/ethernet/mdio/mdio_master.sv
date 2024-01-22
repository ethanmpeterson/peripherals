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
    // Define MDIO transaction constants
    localparam MDIO_READ_OPCODE      = 2'b10;
    localparam MDIO_WRITE_OPCODE     = 2'b01;
    localparam MDIO_WRITE_TURNAROUND = 2'b10;

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
        MDIO_MASTER_STATE_PREAMBLE,

        // Not the full two bits, only handles the high Z differentiation case
        MDIO_MASTER_STATE_WRITE_TURNAROUND,
        MDIO_MASTER_STATE_READ_TURNAROUND,
        MDIO_MASTER_STATE_END_TURNAROUND,

        // Handles the leading zero prior to a register R/W operation
        MDIO_MASTER_STATE_LEADING_ZERO,

        // Clock out register bits in the write case
        MDIO_MASTER_STATE_WRITE_REGISTER_DATA,
        MDIO_MASTER_STATE_FINISH_WRITE,

        // Record returned register data in the read case
        MDIO_MASTER_STATE_READ_REGISTER_DATA,
        MDIO_MASTER_STATE_FINISH_READ
    } mdio_master_state_t;

    var logic [axi_lite.WRITE_DATA_WIDTH-1:0]    write_data;
    var logic [axi_lite.READ_DATA_WIDTH-1:0]     read_data;

    // Signal to tell us if the data is on the line when seeing the first rising
    // edge in an MDIO write transaction. Used in the
    // MDIO_MASTER_STATE_START_CONDITION
    var logic                                   wrote_first_bit = 1'b0;
    var logic [$clog2(CLKS_PER_BIT):0]          transfer_clock_cycle_count;

    // Generate MDC clock line.
    localparam                                  CYCLE_COUNTER_REG_WIDTH = $clog2(CLKS_PER_BIT);
    var logic [CYCLE_COUNTER_REG_WIDTH:0]       cycle_counter = { CYCLE_COUNTER_REG_WIDTH{1'b0} };
    var logic                                   mdc_rising_edge = 1'b0;
    var logic                                   mdc_falling_edge = 1'b0;
    var logic                                   is_read_transaction = 1'b0;

    mdio_master_state_t mdio_master_state = MDIO_MASTER_STATE_INIT;

    always_ff @(posedge clk) begin
        if (cycle_counter == CLKS_PER_BIT/2) begin
            // reset the counter
            cycle_counter <= 0;

            // If the next value is a rising edge
            if (!mdc) begin
                mdc_rising_edge <= 1'b1;
                mdc_falling_edge <= 1'b0;
            end else begin
                mdc_rising_edge <= 1'b0;
                mdc_falling_edge <= 1'b1;
            end

            // swap the state of MDC and register the rising / falling edge
            mdc <= !mdc;
        end else begin
            cycle_counter <= cycle_counter + 1;

            // Zero out the rising/falling edge registers for the intermediate clock cycles
            mdc_rising_edge <= 1'b0;
            mdc_falling_edge <= 1'b0;
        end

        if (reset || mdio_master_state == MDIO_MASTER_STATE_INIT) begin
            mdc <= 1'b0;
        end
    end

    var logic [11:0] preamble_reg;
    var logic [3:0]  preamble_bit_idx;

    var logic [$clog2(axi_lite.READ_DATA_WIDTH):0] register_bit_idx;
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

                    preamble_bit_idx <= 4'hb;
                    register_bit_idx <= axi_lite.READ_DATA_WIDTH - 1;

                    // Enter the read/write branch of the state machine

                    // NOTE: that if a valid read and write address arrive in
                    // the same clock cycle, the read will be prioritized per
                    // the ordering of the if/else below.
                    if (axi_lite.arready && axi_lite.arvalid) begin
                        // Latch the given register address on the PHY and start
                        // the MDIO read transaction.

                        // Indicate the Module is no longer accepting address data
                        axi_lite.arready <= 1'b0;
                        axi_lite.awready <= 1'b0;

                        // populate the preamble register for a read transaction
                        preamble_reg[11:10] <= MDIO_READ_OPCODE;
                        preamble_reg[9:5] <= PHY_ADDRESS;
                        preamble_reg[4:0] <= axi_lite.araddr;

                        // Mark the transaction as a read
                        is_read_transaction <= 1'b1;

                        mdio_master_state <= MDIO_MASTER_STATE_START_CONDITION;
                    end else if (axi_lite.awready && axi_lite.awvalid) begin
                        // Latch the register address for a MDIO write and

                        // Indicate the AXI Lite Slave is ready to accept data
                        axi_lite.wready <= 1'b1;

                        // populate the preamble register for a write transaction
                        preamble_reg[11:10] <= MDIO_WRITE_OPCODE;
                        preamble_reg[9:5] <= PHY_ADDRESS;
                        preamble_reg[4:0] <= axi_lite.awaddr;

                        // Mark the transaction as a write
                        is_read_transaction <= 1'b0;

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
                        mdio_master_state <= MDIO_MASTER_STATE_PREAMBLE;
                    end
                end

                MDIO_MASTER_STATE_START_CONDITION: begin
                    // queue up bits on the falling edge of mdc so that we
                    // always have the data ready for the rising edge.

                    // NOTE: this method depends on having a module clock higher
                    // than mdc frequency. The exact minimum ratio will depend
                    // on the setup and hold times of your specific PHY.

                    if (mdc_falling_edge) begin
                        wrote_first_bit <= 1'b1;

                        mdio_t <= 1'b0;
                        mdio_o <= 1'b0;
                    end

                    // Queue up the second bit of the start condition and
                    // advance to the next state
                    if (mdc_falling_edge && wrote_first_bit) begin
                        mdio_o <= 1'b1;
                        wrote_first_bit <= 1'b0;

                        mdio_master_state <= MDIO_MASTER_STATE_PREAMBLE;
                    end
                end

                MDIO_MASTER_STATE_PREAMBLE: begin
                    if (mdc_falling_edge) begin
                        mdio_o <= preamble_reg[preamble_bit_idx];

                        if (preamble_bit_idx == 0) begin
                            preamble_bit_idx <= 4'hb;

                            if (is_read_transaction) begin
                                mdio_master_state <= MDIO_MASTER_STATE_READ_TURNAROUND;
                            end else begin
                                mdio_master_state <= MDIO_MASTER_STATE_WRITE_TURNAROUND;
                            end
                        end else begin
                            preamble_bit_idx <= preamble_bit_idx - 1;
                        end
                    end
                end

                MDIO_MASTER_STATE_READ_TURNAROUND: begin
                    // TODO: Place the master MDIO line in tri-state check that
                    // we receive a leading zero before the register data.

                    if (mdc_falling_edge) begin
                        mdio_t <= 1'b1;
                    end

                    // Ensure the turn-around is two cycles before we start reading register data
                    if (mdc_falling_edge && mdio_t) begin
                        mdio_master_state <= MDIO_MASTER_STATE_END_TURNAROUND;
                    end

                    // Improvement: if we don't have a leading zero, add some
                    // cancellation behavior to wait 32 MDC cycles and re-init
                    // the state machine.
                end
                MDIO_MASTER_STATE_END_TURNAROUND: begin
                    if (mdc_falling_edge) begin
                        mdio_master_state <= MDIO_MASTER_STATE_READ_REGISTER_DATA;
                    end
                end

                MDIO_MASTER_STATE_WRITE_TURNAROUND: begin
                    // TODO: Needs a driven 10 binary pattern before proceeding to the write data
                end

                MDIO_MASTER_STATE_READ_REGISTER_DATA: begin
                    if (mdc_falling_edge) begin
                        axi_lite.rdata[register_bit_idx] <= mdio_i;
                        register_bit_idx <= register_bit_idx - 1;
                        if (register_bit_idx == 0) begin
                            register_bit_idx <= axi_lite.READ_DATA_WIDTH - 1;

                            mdio_master_state <= MDIO_MASTER_STATE_FINISH_READ;
                        end
                    end
                end

                MDIO_MASTER_STATE_WRITE_REGISTER_DATA: begin
                    // TODO: clock out the register contents on falling edges
                end

                MDIO_MASTER_STATE_FINISH_READ: begin
                    // Mark the data as valid and wait for the data to be consumed
                    axi_lite.rvalid <= 1'b1;
                    if (axi_lite.rready && axi_lite.rvalid) begin
                        mdio_master_state <= MDIO_MASTER_STATE_INIT;
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

