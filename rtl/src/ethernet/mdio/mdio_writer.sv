`timescale 1ns / 1ps
`default_nettype none

module mdio_writer #(
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

    typedef enum int {
        MDIO_WRITER_STATE_INIT,

        MDIO_WRITER_STATE_IDLE,

        MDIO_WRITER_STATE_START1,
        MDIO_WRITER_STATE_START0,

        MDIO_WRITER_STATE_OPCODE1,
        MDIO_WRITER_STATE_OPCODE0,

        MDIO_WRITER_STATE_PHY_ADDR4,
        MDIO_WRITER_STATE_PHY_ADDR3,
        MDIO_WRITER_STATE_PHY_ADDR2,
        MDIO_WRITER_STATE_PHY_ADDR1,
        MDIO_WRITER_STATE_PHY_ADDR0,

        MDIO_WRITER_STATE_REG_ADDR4,
        MDIO_WRITER_STATE_REG_ADDR3,
        MDIO_WRITER_STATE_REG_ADDR2,
        MDIO_WRITER_STATE_REG_ADDR1,
        MDIO_WRITER_STATE_REG_ADDR0,

        MDIO_WRITER_STATE_TA1,
        MDIO_WRITER_STATE_TA0,

        MDIO_WRITER_STATE_DATA15,
        MDIO_WRITER_STATE_DATA14,
        MDIO_WRITER_STATE_DATA13,
        MDIO_WRITER_STATE_DATA12,
        MDIO_WRITER_STATE_DATA11,
        MDIO_WRITER_STATE_DATA10,
        MDIO_WRITER_STATE_DATA9,
        MDIO_WRITER_STATE_DATA8,
        MDIO_WRITER_STATE_DATA7,
        MDIO_WRITER_STATE_DATA6,
        MDIO_WRITER_STATE_DATA5,
        MDIO_WRITER_STATE_DATA4,
        MDIO_WRITER_STATE_DATA3,
        MDIO_WRITER_STATE_DATA2,
        MDIO_WRITER_STATE_DATA1,
        MDIO_WRITER_STATE_DATA0
    } mdio_writer_state_t;

    var logic [15:0] write_data;

    // Generate MDC clock line.
    localparam                                  CYCLE_COUNTER_REG_WIDTH = $clog2(CLKS_PER_BIT);
    var logic [CYCLE_COUNTER_REG_WIDTH:0]       cycle_counter = { CYCLE_COUNTER_REG_WIDTH{1'b0} };

    var logic                                   mdc_rising_edge = 1'b0;
    var logic                                   mdc_falling_edge = 1'b0;

    mdio_writer_state_t mdio_master_state = MDIO_WRITER_STATE_INIT;

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

        if (reset) begin
            mdc <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            mdio_writer_state <= MDIO_WRITER_STATE_INIT;
        end else begin
            case (mdio_writer_state)
                mdio
                default: begin
                    mdio_master_state <= MDIO_WRITER_STATE_INIT;
                end
            endcase
        end
    end

endmodule

`default_nettype wire