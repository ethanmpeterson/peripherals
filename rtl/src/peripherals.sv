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

    var logic locked;
    var logic spi_clk;
    var logic clk_100;
    peripheral_clk_div clk_splitter (
        .clk_100(clk_100),     // output clk_100
        .spi_clk(spi_clk),     // output spi_clk
        // Status and control signals
        .reset(system_reset), // input reset
        .locked(locked),       // output locked

        // Clock in ports
        .ext_clk(ext_clk)      // input ext_clk
    );

    axis_interface internal (
        .clk(clk_100),
        .reset(system_reset)
    );

    uart arty_ftdi_bridge (
        .tx_stream(internal.Sink),
        .rx_stream(internal.Source),

        .txd(ftdi_uart_tx),
        .rxd(ftdi_uart_rx)
    ); 

    axis_interface #(
        .DATA_WIDTH(64),
        .KEEP_WIDTH(1)
    ) accelerometer_data (
        .clk(clk_100),
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
        .sys_clk(clk_100),
        .reset(system_reset),
        .spi_ref_clk(spi_clk),
        .spi_bus(accel_spi_bus.Master),
        .accelerometer_data(accelerometer_data)
    );

endmodule

`default_nettype wire
