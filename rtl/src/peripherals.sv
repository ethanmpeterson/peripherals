`timescale 1ns / 1ps
`default_nettype none

module peripherals (
    input var logic clk_100,
    output var logic blinky
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
