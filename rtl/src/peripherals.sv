`timescale 1ns / 1ps
`default_nettype none

module peripherals (
    input var logic clk_100,
    output var logic blinky
);
    // global reset signal propagated down into all submodules
    // assertion has the effect of resetting the entire design
    var logic system_reset = 0;

    // Dummy Instance of UART peripheral for compilation checks
    // This UART peripheral connects us to the FTDI 232H on the ARTY A7 Dev board

    // default width is 8 bits which works perfectly for a UART peripheral
    axis_interface arty_tx (
        .clk(clk_100),
        .reset(system_reset)
    );
    axis_interface arty_rx (
        .clk(clk_100),
        .reset(system_reset)
    );

    uart arty_ftdi_bridge (
        .tx_stream(arty_tx.Sink),
        .rx_stream(arty_rx.Source)
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

endmodule
`default_nettype wire
