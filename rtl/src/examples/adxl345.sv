`timescale 1ns / 1ps
`default_nettype none

module adxl345 (
    input var logic sys_clk, // main clock domain
    input var logic reset,

    input var logic spi_ref_clk, // low speed SPI clock

    spi_interface.Master spi_bus,

    axis_interface accelerometer_data
);
    localparam TRANSFER_WIDTH = 16;
    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH)
    ) command_stream (
        .clk(sys_clk),
        .reset(reset)
    );

    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH)
    ) response_stream (
        .clk(sys_clk),
        .reset(reset)
    );

    spi_master #(
        .TRANSFER_WIDTH(16),
        .FIFO_DEPTH(32),
        .CPOL(1),
        .CPHA(1)
    ) adxl345_spi_master (
        .spi_clk(spi_ref_clk),
        .spi_bus(spi_bus),

        .mosi_stream(command_stream),
        .miso_stream(response_stream)
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
        REG_DEVID = 6'h00,
        REG_POWER_CTL = 6'h2D,
        REG_DATA_FORMAT = 6'h31,
        REG_INT_ENABLE = 6'h2E,
        REG_FIFO_CTL = 6'38,
        REG_DATAX0 = 6'h32,
        REG_DATAX1 = 6'h33,
        REG_DATAY0 = 6'h34,
        REG_DATAY1 = 6'h35,
        REG_DATAZ0 = 6'h36,
        REG_DATAZ0 = 6'h37;

    // Define the command set
    localparam
        REG_WRITE = 1'b0,
        REG_READ = 1'b1;

    // See datasheet here for more info on data contents being written to
    // register
    localparam
        ADXL345_CONFIGURE_POWER_CTL = {REG_WRITE, 0, REG_POWER_CTL, 8'b00001000},
        ADXL345_DEVID_READ_COMMAND = {REG_READ, 0, REG_DEVID, 8{1'b0}};


    // A note about data format: set data to right justified so that we have
    // sign extension on the data. Should make it easier to do two's comp stuff.
    // Should make it easier to do two's comp stuff.

    // full res bit set to 0
    // +- 2 g range setting

    typedef enum int {
        ADXL345_IDLE, // assign defaults, set up signals
        ADXL345_SET_POWER_CTL, // put the part into measurement mode (chip powers up in standby)
        ADXL345_READ_DEVID, // Read and check the device ID after powering up
        ADXL345_VERIFY_DEVID,
        ADXL345_SET_4WIRE_SPI, // go from 3 wire to 4 wire SPI
        ADXL345_ENABLE_INTERRUPTS, // This will be configured so we ask for data only when new data is available
        ADXL345_CONFIGURE_FIFO_MODE, // Can put in bypass and read data continuously into the FIFO we have on the FPGA
        
        // Grab 3 axis accelerometer data
        ADXL345_READ_DATAX0,
        ADXL345_READ_DATAX1,
        ADXL345_READ_DATAY0,
        ADXL345_READ_DATAY1
    } adxl345_state_t;

    adxl345_state_t state = ADXL345_IDLE;

    always_ff @(posedge sys_clk) begin
        case(state)
            ADXL345_IDLE: begin
                // Not sure what we will have hold us in this state but for now
                // we can go right into the setup sequence for the module
                
                // Start with powering up the module
                state <= ADXL345_SET_POWER_CTL;
            end

            ADXL345_SET_POWER_CTL: begin

            end
        endcase
    end

endmodule

`default_nettype wire
