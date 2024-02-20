`timescale 1ns / 1ps
`default_nettype none

module mdio_writer #(
    // Assumes we are provided a 125 MHz sys clk and gives an effective data rate of 1 Mbps
    parameter CLKS_PER_BIT = 125
) (
    input var  logic clk,
    input var  logic reset,

    // handle the tristate case as discrete signals. Will be hooked up at the top level
    input var logic mdio_i,
    output var logic mdio_o,
    output var logic mdio_t,

    output var logic mdc = 0
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
    var logic [4:0]  register_address;
    var logic [4:0]  phy_address;

    // Generate MDC clock line.
    localparam                                  CYCLE_COUNTER_REG_WIDTH = $clog2(CLKS_PER_BIT);
    var logic [CYCLE_COUNTER_REG_WIDTH:0]       cycle_counter = { CYCLE_COUNTER_REG_WIDTH{1'b0} };

    var logic                                   mdc_rising_edge = 1'b0;
    var logic                                   mdc_falling_edge = 1'b0;

    mdio_writer_state_t mdio_writer_state = MDIO_WRITER_STATE_INIT;

    // initial mdc = 0;
    always_ff @(posedge clk) begin
        if (cycle_counter == CLKS_PER_BIT) begin
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

    var logic [7:0] idle_cycle_counter;
    always_ff @(posedge clk) begin
        if (reset) begin
            mdio_writer_state <= MDIO_WRITER_STATE_INIT;
        end else begin
            if (mdc_falling_edge) begin
                case (mdio_writer_state)
                    MDIO_WRITER_STATE_INIT: begin
                        // Assign test write data to shut off both LEDs on the eth port
                        phy_address <= 5'b00001;
                        write_data <= 16'b0000000000_11_0_10_0;
                        register_address <= 5'h18;

                        idle_cycle_counter <= 0;

                        mdio_t <= 1'b1;
                        mdio_o <= 1'b0;

                        mdio_writer_state <= MDIO_WRITER_STATE_IDLE;
                    end

                    MDIO_WRITER_STATE_IDLE: begin
                        mdio_t <= 1'b1;
                        idle_cycle_counter <= idle_cycle_counter + 1;

                        if (idle_cycle_counter > 32) begin
                            idle_cycle_counter <= 0;

                            mdio_writer_state <= MDIO_WRITER_STATE_START1;
                        end
                    end

                    // START CONDITION
                    MDIO_WRITER_STATE_START1: begin
                        mdio_t <= 1'b0;
                        mdio_o <= 1'b0;

                        mdio_writer_state <= MDIO_WRITER_STATE_START0;
                    end
                    MDIO_WRITER_STATE_START0: begin
                        mdio_o <= 1'b1;

                        mdio_writer_state <= MDIO_WRITER_STATE_OPCODE1;
                    end

                    // OPCODE
                    MDIO_WRITER_STATE_OPCODE1: begin
                        mdio_o <= 1'b0;

                        mdio_writer_state <= MDIO_WRITER_STATE_OPCODE0;
                    end
                    MDIO_WRITER_STATE_OPCODE0: begin
                        mdio_o <= 1'b1;

                        mdio_writer_state <= MDIO_WRITER_STATE_PHY_ADDR4;
                    end

                    // PHY ADDRESS
                    MDIO_WRITER_STATE_PHY_ADDR4: begin
                        mdio_o <= phy_address[4];

                        mdio_writer_state <= MDIO_WRITER_STATE_PHY_ADDR3;
                    end
                    MDIO_WRITER_STATE_PHY_ADDR3: begin
                        mdio_o <= phy_address[3];

                        mdio_writer_state <= MDIO_WRITER_STATE_PHY_ADDR2;
                    end
                    MDIO_WRITER_STATE_PHY_ADDR2: begin
                        mdio_o <= phy_address[2];

                        mdio_writer_state <= MDIO_WRITER_STATE_PHY_ADDR1;
                    end
                    MDIO_WRITER_STATE_PHY_ADDR1: begin
                        mdio_o <= phy_address[1];

                        mdio_writer_state <= MDIO_WRITER_STATE_PHY_ADDR0;
                    end
                    MDIO_WRITER_STATE_PHY_ADDR0: begin
                        mdio_o <= phy_address[0];

                        mdio_writer_state <= MDIO_WRITER_STATE_REG_ADDR4;
                    end


                    // REGISTER ADDRESS
                    MDIO_WRITER_STATE_REG_ADDR4: begin
                        mdio_o <= register_address[4];

                        mdio_writer_state <= MDIO_WRITER_STATE_REG_ADDR3;
                    end
                    MDIO_WRITER_STATE_REG_ADDR3: begin
                        mdio_o <= register_address[3];

                        mdio_writer_state <= MDIO_WRITER_STATE_REG_ADDR2;
                    end
                    MDIO_WRITER_STATE_REG_ADDR2: begin
                        mdio_o <= register_address[2];

                        mdio_writer_state <= MDIO_WRITER_STATE_REG_ADDR1;
                    end
                    MDIO_WRITER_STATE_REG_ADDR1: begin
                        mdio_o <= register_address[1];

                        mdio_writer_state <= MDIO_WRITER_STATE_REG_ADDR0;
                    end
                    MDIO_WRITER_STATE_REG_ADDR0: begin
                        mdio_o <= register_address[0];

                        mdio_writer_state <= MDIO_WRITER_STATE_TA1;
                    end

                    // TURNAROUND BITS
                    MDIO_WRITER_STATE_TA1: begin
                        mdio_o <= 1'b1;

                        mdio_writer_state <= MDIO_WRITER_STATE_TA0;
                    end
                    MDIO_WRITER_STATE_TA0: begin
                        mdio_o <= 1'b0;

                        mdio_writer_state <= MDIO_WRITER_STATE_DATA15;
                    end

                    // REGISTER INPUT DATA
                    MDIO_WRITER_STATE_DATA15: begin
                        mdio_o <= write_data[15];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA14;
                    end
                    MDIO_WRITER_STATE_DATA14: begin
                        mdio_o <= write_data[14];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA13;
                    end
                    MDIO_WRITER_STATE_DATA13: begin
                        mdio_o <= write_data[13];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA12;
                    end
                    MDIO_WRITER_STATE_DATA12: begin
                        mdio_o <= write_data[12];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA11;
                    end
                    MDIO_WRITER_STATE_DATA11: begin
                        mdio_o <= write_data[11];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA10;
                    end
                    MDIO_WRITER_STATE_DATA10: begin
                        mdio_o <= write_data[10];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA9;
                    end
                    MDIO_WRITER_STATE_DATA9: begin
                        mdio_o <= write_data[9];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA8;
                    end
                    MDIO_WRITER_STATE_DATA8: begin
                        mdio_o <= write_data[8];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA7;
                    end
                    MDIO_WRITER_STATE_DATA7: begin
                        mdio_o <= write_data[7];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA6;
                    end
                    MDIO_WRITER_STATE_DATA6: begin
                        mdio_o <= write_data[6];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA5;
                    end
                    MDIO_WRITER_STATE_DATA5: begin
                        mdio_o <= write_data[5];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA4;
                    end
                    MDIO_WRITER_STATE_DATA4: begin
                        mdio_o <= write_data[4];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA3;
                    end
                    MDIO_WRITER_STATE_DATA3: begin
                        mdio_o <= write_data[3];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA2;
                    end
                    MDIO_WRITER_STATE_DATA2: begin
                        mdio_o <= write_data[2];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA1;
                    end
                    MDIO_WRITER_STATE_DATA1: begin
                        mdio_o <= write_data[1];
                        mdio_writer_state <= MDIO_WRITER_STATE_DATA0;
                    end
                    MDIO_WRITER_STATE_DATA0: begin
                        mdio_o <= write_data[0];

                        mdio_writer_state <= MDIO_WRITER_STATE_IDLE;
                    end

                    default: begin
                        mdio_writer_state <= MDIO_WRITER_STATE_INIT;
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
