`timescale 1ns / 1ps
`default_nettype none

module peripherals (
    input var logic ext_clk,
    output var logic blinky,
    output var logic accel_status_led,

    output var logic ftdi_uart_tx,
    input var logic ftdi_uart_rx,

    // SPI bus accelerometer
    output var logic accel_pmod_cs,
    output var logic accel_pmod_mosi,
    output var logic accel_pmod_sck,

    input var logic accel_pmod_miso
);

    // global reset signal propagated down into all submodules assertion has the
    // effect of resetting the entire design
    var logic system_reset = 0;

    axis_interface internal (
        .clk(ext_clk),
        .reset(system_reset)
    );

    uart arty_ftdi_bridge (
        // .tx_stream(internal.Sink),
        .tx_stream(accelerometer_data.Sink),
        .rx_stream(internal.Source),

        .txd(ftdi_uart_tx),
        .rxd(ftdi_uart_rx)
    ); 

    axis_interface #(
        .DATA_WIDTH(48),
        .KEEP_WIDTH(1)
    ) accelerometer_data (
        .clk(ext_clk),
        .reset(system_reset)
    );

    spi_interface #(
        .CS_COUNT(1)
    ) accel_spi_bus ();

    // connect the spi signals to FPGA I/O 
    assign accel_pmod_cs = accel_spi_bus.cs;
    assign accel_pmod_mosi = accel_spi_bus.mosi;
    assign accel_pmod_sck = accel_spi_bus.sck;

    assign accel_spi_bus.miso = accel_pmod_miso;
    adxl345 accelerometer (
        .configured(accel_status_led),
        .reset(system_reset),
        .spi_bus(accel_spi_bus.Master),
        .accelerometer_data(accelerometer_data)
    );

endmodule

`default_nettype wire
