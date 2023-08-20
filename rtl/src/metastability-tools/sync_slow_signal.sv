// Two Flip-Flop Synchronizer to go from a slow to fast clock
`timescale 1ns / 1ps
`default_nettype none

module sync_slow_signal (
    input var logic sync_clk,
    input var logic signal,

    output var logic synced_signal
);
    var logic metastable_reg = 0;
    var logic stable_reg = 0;
    always_ff @(posedge sync_clk) begin : sync_logic
        metastable_reg <= signal;
        stable_reg <= metastable_reg;
    end

    assign synced_signal = metastable_reg;
endmodule
`default_nettype wire
