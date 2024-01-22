// This BFM models an MDIO slave for MDIO master validation.

`timescale 1ns / 1ps
`default_nettype none

module mdio_slave_bfm #(
    parameter PHY_ADDRESS = 5'h0c,
    parameter TEST_REG_ADDRESS = 5'h18
) (
    // handle the tristate case as discrete signals. Will be hooked up at the top level
    input var logic  mdio_i,
    output var logic  mdio_o,
    output var logic  mdio_t,

    input var  logic mdc
);

    var logic is_read_transaction;

    typedef enum int {
        MDIO_SLAVE_BFM_STATE_INIT,
        MDIO_SLAVE_BFM_STATE_WAIT_FOR_START,
        MDIO_SLAVE_BFM_STATE_CHECK_START_COND,
        MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE,
        MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR,
        MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR,
        MDIO_SLAVE_BFM_STATE_HANDLE_TURNAROUND,
        MDIO_SLAVE_BFM_STATE_SEND_READ_DATA,
        MDIO_SLAVE_BFM_STATE_COLLECT_WRITE_DATA
    } mdio_slave_bfm_state_t;

    mdio_slave_bfm_state_t mdio_slave_bfm_state = MDIO_SLAVE_BFM_STATE_INIT;

    always @(posedge mdc) begin
        case (mdio_slave_bfm_state)
            MDIO_SLAVE_BFM_STATE_INIT: begin
                // Hold the mdio line in high
                mdio_t <= 1'b1;
                mdio_o <= 1'b0;

                is_read_transaction <= 2'b00;

                if (!mdio_i) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_WAIT_FOR_START;
                end
            end

            MDIO_SLAVE_BFM_STATE_WAIT_FOR_START: begin

                // Temporary wait until line goes high Z for turnaround and start driving it to 0
                // This operator works for simulation only needs
                if (mdio_i === 1'bz) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_CHECK_START_COND;
                end

                // if (!mdio_i) begin
                //     // if MDIO is driven low by the master, a start condition has begun
                //     mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_CHECK_START_COND;
                // end
            end

            MDIO_SLAVE_BFM_STATE_CHECK_START_COND: begin
                mdio_t <= 1'b0;
                mdio_o <= 1'b1;

                // if (mdio_i) begin
                //     // If the line is asserted, we have received a valid start
                //     // condition and can proceed to collecting the opcode.
                //     mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE;
                // end
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE: begin
                if (mdio_i) begin
                    is_read_transaction <= 2'b11;
                end else if (!mdio_i) begin
                    // The transaction is a write
                    is_read_transaction <= 2'b10;
                end

                if (is_read_transaction == 2'b1x) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR;
                end
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR: begin
                //TODO: Check the PHY ADDRESS is correct here
            end
        endcase
    end

endmodule

`default_nettype wire

