// Full UDP echoer module
// This will take whatever we receiver from the computer and echo it back.
// good example to be refactored into something useful at a later time
// taken from example github and wrapped in SV interfaces
// https://github.com/alexforencich/verilog-ethernet/blob/master/example/Arty/fpga/rtl/fpga_core.v

`default_nettype none
`timescale 1ns / 1ps

module eth_echo (
    input var logic clk,
    input var logic reset
);
endmodule

`default_nettype wire
