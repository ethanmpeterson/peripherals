`timescale 1ns / 1ps
`default_nettype none

module adxl345 (
    output var logic configured, // signal to indicate we configured the device successfully
    input var logic reset,

    spi_interface.Master spi_bus,

    axis_interface.Source accelerometer_data
);
    localparam TRANSFER_WIDTH = 16;
    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(1)
    ) command_stream (
        .clk(accelerometer_data.clk),
        .reset(reset)
    );

    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(1)
    ) response_stream (
        .clk(accelerometer_data.clk),
        .reset(reset)
    );

    spi_master #(
        .TRANSFER_WIDTH(16),
        .CLKS_PER_HALF_BIT(50), // for 100 MHz sys clock
        .CPOL(1),
        .CPHA(1)
    ) adxl345_spi_master (
        .spi_bus(spi_bus),

        .mosi_stream(command_stream.Sink),
        .miso_stream(response_stream.Source)
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
        REG_FIFO_CTL = 6'h38,
        REG_DATAX0 = 6'h32,
        REG_DATAX1 = 6'h33,
        REG_DATAY0 = 6'h34,
        REG_DATAY1 = 6'h35,
        REG_DATAZ0 = 6'h36,
        REG_DATAZ1 = 6'h37;

    // Define the command set
    localparam
        REG_WRITE = 1'b0,
        REG_READ = 1'b1;

    // See datasheet here for more info on data contents being written to
    // register
    localparam
        ADXL345_COMMAND_CONFIGURE_POWER_CTL = {REG_WRITE, 1'b0, REG_POWER_CTL, 8'b00001000},
        ADXL345_COMMAND_DEVID_READ = {REG_READ, 1'b0, REG_DEVID, {8{1'b0}}},
        ADXL345_COMMAND_CONFIGURE_DATA_FORMAT = {REG_WRITE, 1'b0, REG_DATA_FORMAT, 8'b0000_00_00},
        ADXL345_COMMAND_CONFIGURE_INT_ENABLE = {REG_WRITE, 1'b0, REG_INT_ENABLE, {8{1'b0}}},
        ADXL345_COMMAND_CONFIGURE_FIFO_CTL = {REG_WRITE, 1'b0, REG_FIFO_CTL, 8'b0000_0000};

        // TODO: configure offsets before reading actual data

    typedef enum int {
        ADXL345_IDLE, // assign defaults, set up signals
        ADXL345_SET_POWER_CTL, // put the part into measurement mode (chip powers up in standby)
        ADXL345_READ_DEVID, // Read and check the device ID after powering up
        ADXL345_VERIFY_DEVID, // exit and write an error signal if we cannot match device ID
        ADXL345_SET_4WIRE_SPI, // go from 3 wire to 4 wire SPI
        ADXL345_ENABLE_INTERRUPTS, // This will be configured so we ask for data only when new data is available
        ADXL345_CONFIGURE_FIFO_MODE, // Can put in bypass and read data continuously into the FIFO we have on the FPGA
        ADXL345_CONFIGURE_DATA_FORMAT,
        
        // Grab 3 axis accelerometer data
        ADXL345_READ_DATAX0,
        ADXL345_READ_DATAX1,
        ADXL345_READ_DATAY0,
        ADXL345_READ_DATAY1,

        ADXL345_WRITE_ACCEL_DATA_STREAM,

        ADXL345_CONFIGURATION_FAILED
    } adxl345_state_t;

    adxl345_state_t state = ADXL345_IDLE;

    // This register will be modified to command reads of different registers
    // for X,Y,Z accel
    var logic[15:0] ADXL345_COMMAND_ACCEL_READ;

    var logic[7:0] device_id;

    always_ff @(posedge accelerometer_data.clk) begin
        case(state)
            ADXL345_IDLE: begin
                // Init some stream signals
                command_stream.tvalid <= 1'b0;
                command_stream.tkeep <= 1'b1;
                command_stream.tlast <= 1'b1;
                command_stream.tuser <= 0;
                command_stream.tid <= 0;
                command_stream.tdest <= 0;

                response_stream.tready <= 1'b1;
                
                configured <= 1'b0;
                // Not sure what we will have hold us in this state but for now
                // we can go right into the setup sequence for the module
                
                // Start with powering up the module
                state <= ADXL345_SET_POWER_CTL;    
            end

            ADXL345_SET_POWER_CTL: begin
                command_stream.tdata <= ADXL345_COMMAND_CONFIGURE_POWER_CTL;
                command_stream.tvalid <= 1'b1;

                if (command_stream.tvalid && command_stream.tready) begin
                    // when the command is loaded into the FIFO, proceed to the
                    // next state
                    command_stream.tvalid <= 1'b0;

                    state <= ADXL345_READ_DEVID;
                end
            end
            
            ADXL345_READ_DEVID: begin
                command_stream.tdata <= ADXL345_COMMAND_DEVID_READ;
                command_stream.tvalid <= 1'b1;
                if (command_stream.tvalid && command_stream.tready) begin
                    // Now end the write operation
                    command_stream.tvalid <= 1'b0;

                    // say we are ready for the received data
                    response_stream.tready <= 1'b1;

                    // advance to the verification state
                    state <= ADXL345_VERIFY_DEVID;
                end
            end

            ADXL345_VERIFY_DEVID: begin
                if (response_stream.tvalid && response_stream.tready) begin
                    response_stream.tready <= 1'b0;

                    if ((response_stream.tdata & 16'h00_FF) == 8'b11100101) begin
                        // We validated that the device ID is good
                        // state <= ADXL345_ENABLE_INTERRUPTS;
                        device_id <= response_stream.tdata[7:0];
                        configured <= 1'b1;
                        state <= ADXL345_WRITE_ACCEL_DATA_STREAM;
                    end else begin
                        state <= ADXL345_CONFIGURATION_FAILED;
                    end
                end
            end

            ADXL345_ENABLE_INTERRUPTS: begin
                // enable configured signal to show device is operational and
                // that we suceeded in powering it on and reading the device ID

                // Right now, this command enables no interrupts but we will
                // change this later to pick up new samples only when they are
                // ready
                command_stream.tdata <= ADXL345_COMMAND_CONFIGURE_INT_ENABLE;
                command_stream.tvalid <= 1'b1;
                if (command_stream.tvalid && command_stream.tready) begin
                    command_stream.tvalid <= 1'b0;

                    state <= ADXL345_CONFIGURE_DATA_FORMAT;
                end
            end

            ADXL345_CONFIGURE_DATA_FORMAT: begin
                command_stream.tdata <= ADXL345_COMMAND_CONFIGURE_DATA_FORMAT;
                command_stream.tvalid <= 1'b1;
                if (command_stream.tvalid && command_stream.tready) begin
                    command_stream.tvalid <= 1'b0;

                    state <= ADXL345_CONFIGURE_FIFO_MODE;
                end
            end

            ADXL345_CONFIGURE_FIFO_MODE: begin
                command_stream.tdata <= ADXL345_COMMAND_CONFIGURE_FIFO_CTL;
                command_stream.tvalid <= 1'b1;
                if (command_stream.tvalid && command_stream.tready) begin
                    command_stream.tvalid <= 1'b0;

                    state <= ADXL345_READ_DATAX0;
                end
            end

            ADXL345_READ_DATAX0: begin
                // try a multi-byte read and write it out to the output stream

                // command_stream.tdata <= ADXL345_COMMAND_READ_DATAX0;
                // command_stream.tvalid <= 1'b1;
                // if (command_stream.tvalid && command_stream.tready) begin
                //     command_stream.tvalid <= 1'b0;

                //     state <= ADXL345_READ_DATAX1;
                // end
            end

            ADXL345_WRITE_ACCEL_DATA_STREAM: begin
                accelerometer_data.tdata <= device_id;
                accelerometer_data.tvalid <= 1'b1;
                if (accelerometer_data.tvalid && accelerometer_data.tready) begin
                    state <= ADXL345_READ_DATAX0;
                end
            end

            ADXL345_CONFIGURATION_FAILED: begin
                // can set the LED for debugging
                configured <= 1'b0;
            end
        endcase
    end

    always_comb begin
        // Assign unused AXI Stream signals
        accelerometer_data.tkeep = 1'b1;
        accelerometer_data.tlast = 1'b1;
        accelerometer_data.tid = 0;
        accelerometer_data.tdest = 0;
        accelerometer_data.tuser = 0;
    end

endmodule

`default_nettype wire
