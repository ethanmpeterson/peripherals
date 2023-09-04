`timescale 1ns / 1ps
`default_nettype none

module adxl345 (
    input var logic sys_clk, // main clock domain
    input var logic spi_ref_clk, // low speed SPI clock

    spi_interface.Master spi_bus,

    axis_interface accelerometer_data
);
    // TODO

    // This device is SPI mode 3
    // 16 bit transfer size

    // NOTE: we may need to take cs control out of the spi_master module to deal
    // with longer transactions on this device. Probably a prudent design change
    // overall.

    // Set the device to 4-wire SPI mode using bit D6 in the DATA_FORMAT
    // register


    // Can optionally choose to run multiple byte transactions. The current
    // peripheral implementation does not support transfers of arbitrary length
    // so we will avoid this The current peripheral implementation does not
    // support transfers of arbitrary length so we will avoid this.

    // support the self test built into the device

    // Define register addresses using local parameters
    localparam
        REG_POWER_CTL = 8'h2D,
        REG_DATA_FORMAT = 8'h31,
        REG_INT_ENABLE = 8'h2E,
        REG_FIFO_CTL = 8'38,
        REG_DATAX0 = 8'h32,
        REG_DATAX1 = 8'h33,
        REG_DATAY0 = 8'h34,
        REG_DATAY1 = 8'h35,
        REG_DATAZ0 = 8'h36,
        REG_DATAZ0 = 8'h37;

    // A note about data format: set data to right justified so that we have
    // sign extension on the data. Should make it easier to do two's comp stuff.
    // Should make it easier to do two's comp stuff.

    // full res bit set to 0
    // +- 2 g range setting

    typedef enum int {
        ADXL345_IDLE, // assign defaults, set up signals
        ADXL345_SET_POWER_CTL, // put the part into measurement mode (chip powers up in standby)
        ADXL345_SET_4WIRE_SPI, // go from 3 wire to 4 wire SPI
        ADXL345_DISABLE_INTERRUPTS, // could enable in the future but we will stick to simple streaming interface
        ADXL345_CONFIGURE_FIFO_MODE, // Can put in bypass and read data continuously into the FIFO we have on the FPGA
        
        // Grab 3 axis accelerometer data
        ADXL345_READ_DATAX0,
        ADXL345_READ_DATAX1,
        ADXL345_READ_DATAY0,
        ADXL345_READ_DATAY1,

        // Collect the device ID as a basic register read test that the device
        // is alive
        ADXL345_READ_DEVID
    } adxl345_state_t;

    adxl345_state_t state = ADXL345_IDLE;

    always_ff @(posedge sys_clk) begin
        case(state)
            ADXL345_IDLE: begin
            end
        endcase
    end

endmodule

`default_nettype wire
