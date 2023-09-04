`timescale 1ns / 1ps
`default_nettype none

module peripherals (
    input var logic clk_100,
    output var logic blinky,

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
        .clk(clk_100),
        .reset(system_reset)
    );

    uart arty_ftdi_bridge (
        .tx_stream(internal.Sink),
        .rx_stream(internal.Source),

        .txd(ftdi_uart_tx),
        .rxd(ftdi_uart_rx)
    ); 

    var logic[31:0] counter = 0;
    always_ff @(posedge clk_100) begin : blink_logic
        if (counter == 50_000_000) begin
            blinky <= ~blinky;
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    always_comb begin
        // temporary default values for SPI signals
        accel_pmod_cs = 1'b1;

        accel_pmod_mosi = 1'b0;
        accel_pmod_sck = 1'b0;
    end

endmodule
`default_nettype wire
