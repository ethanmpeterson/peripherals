// This BFM models an MDIO slave for MDIO master validation.

`timescale 1ns / 1ps
`default_nettype none

module mdio_slave_bfm #(
    parameter PHY_ADDRESS = 5'h0c,
    parameter TEST_REG_ADDRESS = 5'h18,
    parameter REGISTER_TEST_DATA = 16'haaa5
) (
    // handle the tristate case as discrete signals. Will be hooked up at the top level
    output var logic mdio_o,
    output var logic mdio_t,

    input var  logic mdio_i,
    input var  logic mdc,

    input var  logic reset,

    output var logic [1:0] opcode,
    output var logic [4:0] phy_addr,
    output var logic [4:0] reg_addr,
    output var logic [15:0] received_data,
    output var logic turnaround_valid
);

    typedef enum int {
        MDIO_SLAVE_BFM_STATE_INIT,
        MDIO_SLAVE_BFM_STATE_WAIT_FOR_START,

        MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE1,
        MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE0,

        MDIO_SLAVE_BFM_STATE_CHECK_OPCODE,

        MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR4,
        MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR3,
        MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR2,
        MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR1,
        MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR0,

        MDIO_SLAVE_BFM_STATE_CHECK_PHY_ADDR,

        MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR4,
        MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR3,
        MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR2,
        MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR1,
        MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR0,

        MDIO_SLAVE_BFM_STATE_TURNAROUND1,
        MDIO_SLAVE_BFM_STATE_TURNAROUND0,

        MDIO_SLAVE_BFM_STATE_SEND_READ_DATA,
        MDIO_SLAVE_BFM_STATE_FINISH_READ,

        MDIO_SLAVE_BFM_STATE_COLLECT_WRITE_DATA,
        MDIO_SLAVE_BFM_STATE_FINISH_WRITE
    } mdio_slave_bfm_state_t;

    mdio_slave_bfm_state_t mdio_slave_bfm_state = MDIO_SLAVE_BFM_STATE_INIT;

    var logic [15:0] register_data;
    var logic [3:0]  register_bit_idx;
    always @(posedge mdc) begin
        case (mdio_slave_bfm_state)
            MDIO_SLAVE_BFM_STATE_INIT: begin
                opcode <= 2'b00;
                phy_addr <= 5'b00000;
                reg_addr <= 5'b00000;

                // Hold the mdio line in high z
                mdio_t <= 1'b1;
                mdio_o <= 1'b0;

                register_data <= REGISTER_TEST_DATA;
                register_bit_idx <= 4'hF;

                if (!mdio_i && !(mdio_i === 1'bz)) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_WAIT_FOR_START;
                end
            end

            MDIO_SLAVE_BFM_STATE_WAIT_FOR_START: begin
                if (mdio_i) begin
                    // If mdio is asserted, the start condition is finished
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE1;
                end
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE1: begin
                opcode[1] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE0;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_OPCODE0: begin
                opcode[0] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR4;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR4: begin
                phy_addr[4] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR3;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR3: begin
                phy_addr[3] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR2;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR2: begin
                phy_addr[2] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR1;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR1: begin
                phy_addr[1] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR0;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_PHY_ADDR0: begin
                phy_addr[0] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR4;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR4: begin
                reg_addr[4] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR3;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR3: begin
                reg_addr[3] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR2;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR2: begin
                reg_addr[2] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR1;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR1: begin
                reg_addr[1] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR0;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_REG_ADDR0: begin
                reg_addr[0] <= mdio_i;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_TURNAROUND1;
            end

            MDIO_SLAVE_BFM_STATE_TURNAROUND1: begin
                // Only proceed if opcode and first turnaround bits are valid
                if ((mdio_i === 1'bz && opcode == 2'b10) || (mdio_i && opcode == 2'b01)) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_TURNAROUND0;
                end
            end

            MDIO_SLAVE_BFM_STATE_TURNAROUND0: begin
                // In the read case, we need to drive the line to 0
                if (opcode == 2'b10) begin
                    mdio_t <= 1'b0;
                    mdio_o <= 1'b0;

                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_SEND_READ_DATA;
                end else begin
                    mdio_t <= 1'b1;

                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_COLLECT_WRITE_DATA;
                end

                turnaround_valid <= 1'b1;
            end

            MDIO_SLAVE_BFM_STATE_SEND_READ_DATA: begin
                // Change the data on each rising edge of the clock until we have sent all 16 bits
                mdio_o <= register_data[register_bit_idx];
                register_bit_idx <= register_bit_idx - 1;
                if (register_bit_idx == 0) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_FINISH_READ;
                end
            end

            MDIO_SLAVE_BFM_STATE_FINISH_READ: begin
                mdio_t <= 1'b1;
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_INIT;
            end

            MDIO_SLAVE_BFM_STATE_COLLECT_WRITE_DATA: begin
                received_data[register_bit_idx] <= mdio_i;
                register_bit_idx <= register_bit_idx - 1;

                if (register_bit_idx == 0) begin
                    mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_FINISH_WRITE;
                end
            end

            MDIO_SLAVE_BFM_STATE_FINISH_WRITE: begin
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_INIT;
            end

            default: begin
                mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_INIT;
            end
        endcase

        if (reset) begin
            mdio_slave_bfm_state <= MDIO_SLAVE_BFM_STATE_INIT;
        end
    end

endmodule

`default_nettype wire

