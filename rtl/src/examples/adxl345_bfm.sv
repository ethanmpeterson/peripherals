`timescale 1ns / 1ps
`default_nettype none

module adxl345_bfm (
    spi_interface.Slave spi_bus
);

    localparam ADXL345_SAMPLING_EDGE = 1;
    localparam ADXL345_UPDATE_EDGE = 0;

    // This BFM can be improved in the future. But for now it will strictly
    // include returning the device ID when the correct command is sent

    var logic[15:0] DEVID_RESPONSE = 16'b00000000_1110_0101;

    typedef enum int {
        WAIT_FOR_CS,
        SEND_DEV_ID
    } adxl345_bfm_state_t;    

    adxl345_bfm_state_t adxl345_bfm_state = SEND_DEV_ID;
    var logic[3:0] bit_idx = 15;
    always_ff @(spi_bus.sck) begin
        case (adxl345_bfm_state)
            SEND_DEV_ID: begin
                // if the next edge is an update make sure the next bit is ready on miso
                if (!spi_bus.cs && !spi_bus.sck == ADXL345_UPDATE_EDGE) begin
                    spi_bus.miso <= DEVID_RESPONSE[bit_idx];
                    bit_idx <= bit_idx - 1;
                end

                if (bit_idx == 0 && spi_bus.cs) begin
                    adxl345_bfm_state <= WAIT_FOR_CS;
                end
            end
        endcase
    end
endmodule

`default_nettype wire
